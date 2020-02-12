//
//  extension.swift
//  coolAnimation
//
//  Created by Andrew on 7/12/17.
//  Copyright © 2017 Andrew. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView{
    
    @objc func loadImageUsingCacheString(urlString: String){
        
        self.image = nil ///ca sa nu mai faca flash.. sa nu mai apara pozele cache uie
        
        ///vede daca au fost cache uite pozele sau nu
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
             self.image = cachedImage
            return
        }
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            if error != nil {
                print(error ?? "")
                return
            }
            
            DispatchQueue.main.async(execute: {
                
                if let downloadedImage = UIImage(data: data!){
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    self.image = downloadedImage
                }
                
            })
            
        }).resume()
        
    }
}
