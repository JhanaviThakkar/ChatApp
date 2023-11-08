//
//  ContentView.swift
//  test
//
//  Created by Jhanavi Thakkar on 10/15/23.
//

import SwiftUI

struct ContentView: View {
    
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
    @State var shouldShowImagePicker = false
    
    var body: some View {
        NavigationView{
            ScrollView{
                
                VStack(spacing: 16){
                    Picker(selection: $isLoginMode, label:
                            Text("Picker here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode{
                        Button{
                            shouldShowImagePicker.toggle()
                        } label: {
                            
                            VStack{
                                
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                }else{
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                }
                            }
                            
                            
                        }
                    }
                    
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                    SecureField("Password", text: $password)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack{
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                            Spacer()
                        } .background(Color.blue)
                    }

                    
                }.padding()
                
                
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
            ImagePicker(image: $image)
        }
    }
    
    @State var image: UIImage?
    
    private func handleAction(){
        if isLoginMode{
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    private func createNewAccount(){
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password){
            result, err in
            if let err = err {
                print("Fail to create user:", err)
                return
            }
            
            print("Successfully created user: \(result?.user.uid ?? "")")
            
            self.persistImageToStorage()
        }
    }
    
    //adding image to firestorage
    private func persistImageToStorage(){

        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
            else{return}
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else {return}
        ref.putData(imageData, metadata: nil) { metdata, err in
            if let err = err {
                print("Failed to push image to storage: \(err)")
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    print("Failed to retreive downloadURL: \(err)")
                    return
                }
                
                print("Successfully stored image to url: \(url?.absoluteString ?? "")")
                
                guard let url = url else {return}
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    //adding the user to firestore with email, url to profile pic, and uid
    private func storeUserInformation(imageProfileUrl: URL){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print("Failed: \(err)")
                    return
                }
                
                print("Success!")
            }
    }
    
    private func loginUser(){
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print("Fail to log in:", err)
                return
            }
            
            print("Successfully logged in user: \(result?.user.uid ?? "")")
        }
    }
}

#Preview {
    ContentView()
}
