//
//  MainMessagesView.swift
//  test
//
//  Created by Jhanavi Thakkar on 10/22/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase


class MainMessagesViewModel: ObservableObject{
    
    @Published var errorMessage = ""
    @Published var chatUser : ChatUser?
    
    
    init(){
        fetchCurrentUser()
        fetchRecentMessages()
    }
    
    @Published var recentMessages = [RecentMessage]()
    
    private func fetchRecentMessages(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else{return}
        
        FirebaseManager.shared.firestore.collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Failed to listen for recent messages: \(error)")
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    
                    let docId = change.document.documentID
                    
                    if let index = 
                        self.recentMessages.firstIndex(where: { rm in
                        return rm.documentId == docId
                        }){
                        self.recentMessages.remove(at:index)
                    }
                    
                    self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
                        
//                    self.recentMessages.append(.init(documentId: docId, data: change.document.data()))
                    
                })
            }
    }
    
    private func fetchCurrentUser(){
        self.errorMessage = "Fetching Current user"
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid 
        else {
            self.errorMessage = "Could not find firebase uid"
            return
        }
        
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error{
                
                self.errorMessage = "Failed to fetch current user: \(error)"
                print("Failed to fetch current user:", error)
                return
            }
            
            //data dictionary to exract exact info from database
            guard let data = snapshot?.data() else {return}

            let uid = data["uid"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let profileImageUrl = data["profileImageUrl"] as? String ?? ""
            self.chatUser = ChatUser(data: data)
//            self.chatUser = .init(data: data)
            self.chatUser = ChatUser(data: ["uid": uid, "email": email, "profileImageUrl": profileImageUrl])
            FirebaseManager.shared.currentUser = self.chatUser
        }
    }
}

struct MainMessagesView: View {
    
    @State var shouldShowLogOutOptions = false;
    
    @State var shouldNavigateToChatLogView = false;
    
    //creating an instance of the viewmodel
    @ObservedObject private var vm = MainMessagesViewModel()
    
    var body: some View {
        NavigationView{
            VStack{
                
                //Text("CURRENT USER ID: \(vm.chatUser?.uid ?? "")")
                customNavBar
                messagesView
                
                NavigationLink("", isActive: $shouldNavigateToChatLogView){
                    ChatLogView(chatUser: self.chatUser)
                }
                
            }
            .overlay(newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
            
            //.navigationTitle("Main Message View")
        }
    }
    
    private var customNavBar: some View {
        
        HStack(spacing: 16){
            
            //current user profile image
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(50)
                        .overlay(RoundedRectangle(cornerRadius: 44)
                            .stroke(Color(.label), lineWidth: 1)
                        )
                        .shadow(radius: 5)
                case .failure(_):
                    // Handle image loading failure here, e.g., display a placeholder or error message
                    Image(systemName: "person.fill").font(.system(size: 34, weight: .heavy))
                case .empty:
                        ProgressView()
                }
            }

            //Image(systemName: "person.fill").font(.system(size: 34, weight: .heavy))
            
            VStack(alignment: .leading, spacing: 4){
                Text("\(vm.chatUser?.email ?? "")").font(.system(size: 15, weight: .bold))
                HStack{
                    Circle().foregroundColor(.green).frame(width: 14, height: 14)
                    Text("online").font(.system(size: 14)).foregroundColor(Color(.lightGray))
                }
            }
            Spacer()
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [.default(Text("Default Button")), .cancel()])
        }
    }
    
    
    private var messagesView: some View {
        ScrollView{
            ForEach(vm.recentMessages){recentMessage in
                VStack{
                    NavigationLink {
                        Text("Chat History will go here, navigate to +New Message")
                    } label: {
                        HStack(spacing: 16){
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 44)
                                    .stroke(Color.black, lineWidth: /*@START_MENU_TOKEN@*/1.0/*@END_MENU_TOKEN@*/))
                            
                            VStack(alignment: .leading, spacing: 8){
                                Text(recentMessage.email).font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(.label))
                                Text(recentMessage.text).font(.system(size: 14)).foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                            }
                            
                            Spacer()
                            
                            Text("22d").font(.system(size: 14, weight: .semibold))
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
                
            }.padding(.bottom, 50)
            
        }
    }
    
    @State var shouldShowNewMessageScreen = false
    
    private var newMessageButton: some View {
        Button{
            shouldShowNewMessageScreen.toggle()
        }label: {
            HStack{
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
                .background(Color.blue)
                .cornerRadius(32)
                .padding(.horizontal)
                .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen){
            CreateNewMessageView(didSelectNewUser: {
                user in
                print(user.email)
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
            })
        }
    }
    
    @State var chatUser: ChatUser?
}


#Preview {
    MainMessagesView()
}
