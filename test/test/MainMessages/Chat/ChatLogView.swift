//
//  ChatLogView.swift
//  test
//
//  Created by Jhanavi Thakkar on 11/6/23.
//

import SwiftUI
import Firebase


class ChatLogViewModel: ObservableObject{
    
    @Published var chatText = ""
    @Published var chatMessages = [ChatMessage]()
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    private func fetchMessages(){
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        
        //recepient
        guard let toId = chatUser?.uid else {return}
        
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error{
                    print("Failed to listen for messages: \(error)")
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added{
                        let data = change.document.data()
                        self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
            }
    }
    
    func handleSend(){
        print(chatText)
        //user you are sending from, ie current user
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        
        //recepient
        guard let toId = chatUser?.uid else {return}
        
        //save message to firestore
        let document =
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: chatText, "timestamp": Timestamp()] as [String: Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print("Failed to save message into Firestore: \(error)")
                return
            }
            
            print("Successfully saved current user sending message")
            
            self.persistRecentMessage()
            
            self.chatText = ""
        }
        
        //need to save same message on recipient side
        let recipientMessageDocument =
        FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                print("Failed to save message into Firestore: \(error)")
                return
            }
            
            print("Recipient saved message too")
        }
    }
    
    private func persistRecentMessage() {
        
        guard let chatUser = chatUser else {return}
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        
        guard let toId = self.chatUser?.uid else {return}
        
        let document = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.email: chatUser.email
        ] as [String : Any]
        
        document.setData(data) { error in
            if let error = error {
                print("Failed to save recent message: \(error)")
                return
            }
        }
        
        //NEED TO DO AGAIN FOR RECIPIENT ^
        
    }
}

struct ChatLogView: View {
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    @ObservedObject var vm : ChatLogViewModel
    
    var body: some View{
        
        VStack{
            messagesView
            
            chatBottomBar
        }
        
        .navigationTitle(chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    private var messagesView: some View{
        ScrollView{
            ForEach(vm.chatMessages){ message in
                VStack{
                    if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                        HStack{
                            Spacer()
                            HStack{
                                Text(message.text)
                                    .foregroundColor(Color.white)
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    } else {
                        HStack{
                            HStack{
                                Text(message.text)
                                    .foregroundColor(Color.black)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                             
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
            }
            
            HStack{
                Spacer()
            }
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16){
            Image(systemName: "photo.on.rectangle") //from sfsymbols
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            TextField("Description", text: $vm.chatText)
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(Color.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(4)

        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        
    }
}

#Preview {
    NavigationView{
//        ChatLogView(chatUser: .init(data: ["uid": "IiaTxhiQ7MORPqtX6blzrSApCZm1", "email": "vikash.k.singh@vanderbilt.edu"]))
        MainMessagesView()
    }
}
