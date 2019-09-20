//
//  ChatViewController.swift
//  chat
//
//  Created by Lyub Chibukhchian on 9/15/19.
//  Copyright © 2019 Lyub Chibukhchian. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatViewController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var messages = [Message]()
    let cellId = "cellId"
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid , let toId  = user?.id else { return }
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: Any] else { return }
              
                
                    self.messages.append(Message(dictionary: dictionary))
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                        self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                    }
                
                
                
            }, withCancel: nil)
        }, withCancel: nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKeyboardObservers()
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView.backgroundColor = .white
        collectionView.keyboardDismissMode = .interactive
        collectionView.alwaysBounceVertical = true
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
    }
    lazy var inputContainerView: ChatInputContainerView =  {
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatCotroller = self
        return chatInputContainerView
    }()
    
    @objc func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        present(imagePickerController, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            let filename = NSUUID().uuidString + ".mov"
            let uploadTask = Storage.storage().reference().child("message-videos").child(filename).putFile(from: videoURL, metadata: nil) { (metadata, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                Storage.storage().reference().child(filename).downloadURL(completion: { (url, err) in
                    if err != nil {
                        print(err!.localizedDescription)
                        return
                    }
                    let storageURL = url!.absoluteString
                    if let thumbnailImage = self.thumbnailImageForFileURL(fileURL: videoURL) {
                        self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: { (imageURL) in
                            let properties: [String: Any] = ["imageURL": imageURL, "videoURL": storageURL, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height]
                            self.sendMessageWithProperties(properties: properties)
                        })
                        
                    }
                    
                })
              
            }
            
            uploadTask.observe(.progress) { (snapshot) in
                if let completedUnitCount = snapshot.progress?.completedUnitCount, let totalUnitCount = snapshot.progress?.totalUnitCount {
                    let uploadPercentage : Float64 = Float64(completedUnitCount) * 100 / Float64(totalUnitCount)
                    
                    self.navigationItem.title = String(format: "%.0f", uploadPercentage) + " %"
                }
            }
            
            uploadTask.observe(.success) { (snapshot) in
                self.navigationItem.title = self.user?.name
            }
  
        } else {
            var selectedImageFromPicker: UIImage?
            
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImageFromPicker = editedImage
                
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImageFromPicker = originalImage
            }
            
            if let selectedImage = selectedImageFromPicker {
                uploadToFirebaseStorageUsingImage(image: selectedImage) { (imageURL) in
                    self.sendMessageWithImageURL(imageURL: imageURL, image: selectedImage)
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    private func thumbnailImageForFileURL(fileURL: URL) -> UIImage? {
        let asset = AVAsset(url: fileURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do  {
            let thumnailCGImage = try imageGenerator.copyCGImage(at: CMTime(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumnailCGImage)
        } catch let err {
            print(err)
        }
        return nil
    }
    
    
   
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completion: @escaping (_ imageURL: String) -> ()) {
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child("\(imageName).jpg")
        if let uploadData = self.resize(image: image, size: CGSize(width: 100, height: 100))?.pngData() {
            ref.putData(uploadData, metadata: nil) { (metadata, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }

                ref.downloadURL(completion: { (url, err) in
                    if err != nil {
                        print(err!.localizedDescription)
                        return
                    }
                    let imageURL = url!.absoluteString
                    completion(imageURL)
                    //self.sendMessageWithImageURL(imageURL: imageURL, image: image)
                })

            }
        }
    }
    

    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
    }
    
    @objc func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    @objc func handleKeyboardWillShow(notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardDuration = (notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double)!
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleKeyboardWillHide(notification: Notification) {
       
        let keyboardDuration = (notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double)!
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
        
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatViewController = self
        
        let message = messages[indexPath.row]
        cell.message = message
        cell.textView.text = message.text
        setUpCell(cell: cell, message: message)
        if let text = message.text {
            cell.textView.isHidden = false
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
        } else if message.imageURL != nil {
            cell.textView.isHidden = true
            cell.bubbleWidthAnchor?.constant = 200
        }
        
        
        cell.playButton.isHidden = message.videoURL == nil
        
        
        return cell
    }
    
    private func setUpCell(cell: ChatMessageCell, message: Message) {
        
        
        if let profileImageURL = user?.profileImageURL {
            cell.profileImageView.loadImageUsingCache(urlString: profileImageURL)
        }
        
     
        
        if message.fromId == Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            cell.textView.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            cell.profileImageView.isHidden = true
            cell.bubbleLeftAnchor?.isActive = false
            cell.bubbleRightAnchor?.isActive = true
        } else {
            cell.profileImageView.isHidden = false
            cell.bubbleView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            cell.textView.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            cell.bubbleLeftAnchor?.isActive = true
            cell.bubbleRightAnchor?.isActive = false
        }
        
        if let messageImageURL = message.imageURL {
            cell.messageImageView.loadImageUsingCache(urlString: messageImageURL)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        let message = messages[indexPath.row]
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        return CGSize(width: view.bounds.width, height: height)
    }
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    


   @objc func handleSend() {
        let properties = ["text": inputContainerView.inputTextField.text!] as [String : Any]
        sendMessageWithProperties(properties: properties)
    }
    
   private func sendMessageWithImageURL(imageURL : String, image: UIImage) {
        let properties: [String: Any] = ["imageURL": imageURL, "imageWidth": image.size.width, "imageHeight": image.size.height]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithProperties(properties: [String: Any]) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let fromId = Auth.auth().currentUser!.uid
        let timestamp = Int(Date().timeIntervalSince1970)
        let toId = user!.id!
        var values = ["toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : Any]
        //childRef.updateChildValues(values)
        properties.forEach({values[$0] = $1})
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            self.inputContainerView.inputTextField.text = nil
            
            let messageId = childRef.key
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(messageId!)
            userMessagesRef.setValue(1)
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId).child(messageId!)
            recipientUserMessagesRef.setValue(1)
            
            
        }
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
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    func performZoomInForImageView(imageView: UIImageView) {
        startingFrame = imageView.superview?.convert(imageView.frame, to: nil)
        let zoomImageView = UIImageView(frame: startingFrame!)
        
        zoomImageView.image = imageView.image
        zoomImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        zoomImageView.isUserInteractionEnabled = true
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = .black
            blackBackgroundView?.alpha = 0
            keyWindow.addSubview(blackBackgroundView!)
            keyWindow.addSubview(zoomImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                zoomImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomImageView.center = keyWindow.center
                
            }) { (completed) in
                
            }
        
        }
    }
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }) { (completed) in
                zoomOutImageView.removeFromSuperview()
                
            }
        }
    }
    
}
