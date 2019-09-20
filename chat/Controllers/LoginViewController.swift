//
//  LoginViewController.swift
//  chat
//
//  Created by Lyub Chibukhchian on 9/4/19.
//  Copyright © 2019 Lyub Chibukhchian. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var messagesController: MessagesViewController?
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()

    let loginRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = #colorLiteral(red: 0.3137254902, green: 0.3960784314, blue: 0.631372549, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Register", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        return button
    }()
    @objc func handleLoginRegister() {
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            handleLogin()
        } else {
            handleRegister()
        }
    }
    func handleLogin() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            self.messagesController?.fetchUserAndSetupNavBarTitle()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    

    
    
    @objc func handleRegister() {
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let uid = user?.user.uid else {
                return
            }
            var profileImageURL: String!
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
          
            if let uploadData = self.resize(image: self.profileImageView.image!, size: CGSize(width: 100, height: 100))?.pngData() {
               
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    storageRef.downloadURL(completion: { (url, err) in
                        if err != nil {
                            print(err!.localizedDescription)
                            return
                        }
                        profileImageURL = url!.absoluteString
                        let ref = Database.database().reference()
                        let usersRef = ref.child("users").child((uid))
                        let values = ["name": name, "email": email, "profileImageURL": profileImageURL!]
                        usersRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
                            if err != nil {
                                print(err!.localizedDescription)
                                return
                            }
                            let user = User()
                            user.name = name
                            user.email = email
                            user.profileImageURL = profileImageURL
                            self.messagesController?.setupNavBarWithUser(user: user)
                            self.dismiss(animated: true, completion: nil)
                            
                        })
                    })
                    
                })
               
            }
        }
    }
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "name"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    let nameSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "email"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    let emailSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "password"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.isSecureTextEntry = true
        return textField
    }()
    let passwordSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "b")
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
   
    
    lazy var loginRegisterSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Login", "Register"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 1
        sc.tintColor = .white
        sc.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        return sc
    }()
    @objc func handleLoginRegisterChange() {
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        inputContainerViewHeight?.constant = (loginRegisterSegmentedControl.selectedSegmentIndex == 0) ? 100 : 150
        nameTextFieldHeight.isActive = false
        nameTextFieldHeight = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeight.isActive = true
        
        emailTextFieldHeight.isActive = false
        emailTextFieldHeight = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeight.isActive = true
        
        passwordTextFieldHeight.isActive = false
        passwordTextFieldHeight = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeight.isActive = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.2392156863, green: 0.3568627451, blue: 0.5921568627, alpha: 1)
       
       
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(loginRegisterSegmentedControl)
        setupInputsContainerView()
        setupLoginRegisterButton()
        setupProfileImageView()
        setupLoginRegisterSegmentedControl()
        
    }
    func setupLoginRegisterSegmentedControl() {
        //x, y, width and height constraints for loginRegisterSegmentedControl
        loginRegisterSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, multiplier: 1).isActive = true
        loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 36)
    }
    func setupProfileImageView() {
        //x, y, width and height constraints for profileImageView
        profileImageView.centerXAnchor.constraint(equalTo: inputsContainerView.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentedControl.topAnchor, constant: -12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
    var inputContainerViewHeight: NSLayoutConstraint!
    var nameTextFieldHeight: NSLayoutConstraint!
    var emailTextFieldHeight: NSLayoutConstraint!
    var passwordTextFieldHeight: NSLayoutConstraint!
    
    func setupInputsContainerView() {
        //x, y, width and height constraints for inputsContainerView
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputContainerViewHeight = inputsContainerView.heightAnchor.constraint(equalToConstant: 150)
        inputContainerViewHeight.isActive = true
        
        inputsContainerView.addSubview(nameTextField)
        inputsContainerView.addSubview(nameSeperatorView)
        inputsContainerView.addSubview(emailTextField)
        inputsContainerView.addSubview(emailSeperatorView)
        inputsContainerView.addSubview(passwordTextField)
        inputsContainerView.addSubview(passwordSeperatorView)
        view.addSubview(profileImageView)
        
        //x, y, width and height constraints for nameTextField
        nameTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        nameTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameTextFieldHeight = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        nameTextFieldHeight.isActive = true
        
        
        //x, y, width and height constraints for nameSeperatorView
        nameSeperatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        nameSeperatorView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeperatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameSeperatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        //x, y, width and height constraints for emailTextField
        emailTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        emailTextField.topAnchor.constraint(equalTo: nameSeperatorView.topAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailTextFieldHeight = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        emailTextFieldHeight.isActive = true
        
        
        //x, y, width and height constraints for emailSeperatorView
        emailSeperatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        emailSeperatorView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeperatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailSeperatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        //x, y, width and height constraints for passwordTextField
        passwordTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: emailSeperatorView.topAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        passwordTextFieldHeight =  passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        passwordTextFieldHeight.isActive = true
        
        
    }
    func setupLoginRegisterButton() {
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    




}

extension LoginViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @objc func handleSelectProfileImageView() {
       
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
       
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
            
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func resize(image: UIImage, size: CGSize) -> UIImage? {
        
        let scale = size.width / image.size.width
        let height = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: size.width, height: height))
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
}
