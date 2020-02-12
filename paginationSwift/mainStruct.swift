//
//  mainStruct.swift
//  paginationSwift
//
//  Created by Andrew on 2/9/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit

struct mainStruct: Decodable {
    
    var name: String?
    var profileImage: String?
    
    init(dict: [String: Any]) {
        self.name = dict["name"] as? String
        self.profileImage = dict["profileImage"] as? String
    }
}
