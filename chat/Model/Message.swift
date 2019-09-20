//
//  Message.swift
//  chat
//
//  Created by Lyub Chibukhchian on 9/15/19.
//  Copyright © 2019 Lyub Chibukhchian. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var fromId: String?
    var toId: String?
    var text: String?
    var timestamp: NSNumber?
    var imageURL: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    var videoURL: String?
    
    func chatPartnerId() -> String? {
        if fromId == Auth.auth().currentUser?.uid {
            return toId
        } else {
            return fromId
        }
    }
    init(dictionary: [String: Any]) {
        super.init()
        fromId = dictionary["fromId"] as? String
        toId = dictionary["toId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        imageURL = dictionary["imageURL"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        videoURL = dictionary["videoURL"] as? String
    }
    
}
