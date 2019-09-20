//
//  ChatInputContainerView.swift
//  chat
//
//  Created by Lyub Chibukhchian on 9/19/19.
//  Copyright © 2019 Lyub Chibukhchian. All rights reserved.
//
import UIKit

class ChatInputContainerView: UIView, UITextFieldDelegate {
    
    var chatCotroller: ChatViewController? {
        didSet {
            sendButton.addTarget(ChatViewController(), action: #selector(ChatViewController.handleSend), for: .touchUpInside)
            
            uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: chatCotroller, action: #selector(ChatViewController.handleUploadTap)))
        }
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.placeholder = "Enter your message..."
        textField.backgroundColor = .white
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let uploadImageView = UIImageView()
    let sendButton = UIButton(type: .system)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        uploadImageView.image = UIImage(named: "pickAnImage")
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(uploadImageView)
        
        // uploadImageView constraints
        
        uploadImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.contentHorizontalAlignment = .center
        sendButton.translatesAutoresizingMaskIntoConstraints = false
      
        addSubview(sendButton)
        
        // send button constraints
        sendButton.rightAnchor.constraint(equalTo: rightAnchor, constant: 25).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        sendButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1/4).isActive = true
        
        
        
        addSubview(inputTextField)
        // inputTextField constraints
        inputTextField.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        inputTextField.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 3/4).isActive = true
        
        let seperatorLineView = UIView()
        seperatorLineView.translatesAutoresizingMaskIntoConstraints = false
        seperatorLineView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        addSubview(seperatorLineView)
        
        // seperatorLineView constraints
        seperatorLineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        seperatorLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        seperatorLineView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        seperatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        chatCotroller?.handleSend()
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
