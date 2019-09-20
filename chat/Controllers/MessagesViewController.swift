//
//  ViewController.swift
//  chat
//
//  Created by Lyub Chibukhchian on 9/4/19.
//  Copyright © 2019 Lyub Chibukhchian. All rights reserved.
//

import UIKit
import Firebase
class MessagesViewController: UITableViewController {

    let cellId = "cellId"
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsMultipleSelectionDuringEditing = true

        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(handleNewMessage))
        ckeckIfTheUserIsLoggedIn()
    
       
        
        
        
        
    }
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let userId = snapshot.key
            
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId: messageId)
            }, withCancel: nil)
            
        }, withCancel: nil)
        ref.observe(.childRemoved, with: { (snapshot) in
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.handleReloadTable()
        }, withCancel: nil)
        
        
        
        
    }
    private func fetchMessageWithMessageId(messageId: String) {
        let messagesReference = Database.database().reference().child("messages").child(messageId)
        messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let message = Message(dictionary: dictionary)
               
                
                
                if let chatPartnerId = message.chatPartnerId() {
                    self.messagesDictionary[chatPartnerId] = message
                    
                }
                
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
                
            }
        }, withCancel: nil)
    }
    
    var timer: Timer?
   
    @objc func handleReloadTable() {
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            return message1.timestamp!.intValue > message2.timestamp!.intValue
        })
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        cell.message = message
        
        
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard let charPartnerId = message.chatPartnerId() else { return }
        let ref = Database.database().reference().child("users").child(charPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
           
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let user = User()
            user.id = charPartnerId
            user.name = dictionary["name"] as? String
            user.profileImageURL = dictionary["profileImageURL"] as? String
            user.email = dictionary["email"] as? String
//            user.setValuesForKeys(dictionary)
            self.showChatControllerForUser(user: user)
        }, withCancel: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let message = messages[indexPath.row]
        if let chatPartnerId = message.chatPartnerId() { Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue { (error, ref) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            self.messagesDictionary.removeValue(forKey: chatPartnerId)
            self.handleReloadTable()
            }
        }
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    func ckeckIfTheUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            handleLogout()
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    @objc func fetchUserAndSetupNavBarTitle() {
        let uid = Auth.auth().currentUser!.uid
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {

                let user = User()
                user.name = dictionary["name"] as? String
                user.email = dictionary["email"] as? String
                user.profileImageURL = dictionary["profileImageURL"] as? String
                self.setupNavBarWithUser(user: user)
                
                
            }
        }, withCancel: nil)
    }
    func setupNavBarWithUser(user: User) {
        
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        observeUserMessages()
        
        let titleView = UIView()
        
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let profileImageView = UIImageView()
        titleView.addSubview(profileImageView)
        
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.masksToBounds = true
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        if let profileImageURL = user.profileImageURL {
            profileImageView.loadImageUsingCache(urlString: profileImageURL)
        }
        
        // x, y, width and height anchors for profileImageView
        profileImageView.leftAnchor.constraint(equalTo: titleView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
       
        let nameLabel = UILabel()
        titleView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // x, y, width, height anchors for nameLabel
        nameLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: titleView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        titleView.addSubview(nameLabel)

        self.navigationItem.titleView = titleView

        self.navigationController?.navigationBar.isUserInteractionEnabled = true
        
    }
    @objc func showChatControllerForUser(user: User) {
     
        let chatController = ChatViewController(collectionViewLayout: UICollectionViewFlowLayout())
        chatController.user = user
        navigationController?.pushViewController(chatController, animated: true)
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginController = LoginViewController()
        loginController.messagesController = self
        present(loginController, animated: true, completion:  nil)
    }

}

