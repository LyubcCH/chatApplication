//
//  Extensions.swift
//  chat
//
//  Created by Lyub Chibukhchian on 9/15/19.
//  Copyright © 2019 Lyub Chibukhchian. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    func loadImageUsingCache(urlString: String) {
        self.image = nil
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                    self.image = UIImage(data: data!)
                }
                
            }
            
            }.resume()
        
    }
    
}
