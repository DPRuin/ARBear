//
//  ArtModel.swift
//  ARBear
//
//  Created by mac126 on 2018/5/4.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit

class ArtModel: NSObject {

    var name = ""
    var imageURL = ""
    var downloadURL = ""
    // static let properties = ["name", "imageURL", "downloadURL"]
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        return;
    }
    init(dict: [String : String]) {
        super.init()
//        for key in ArtModel.properties {
//            if dict[key] != nil {
//                //setValue(dict[key], forKey: key)
//                set
//            }
//        }
        setValuesForKeys(dict)
        // super.init()
    }
    
    /// 模型数组
    class func artModels(array: Array<[String : String]>) -> [ArtModel] {
        
        var artModelsArray = [ArtModel]()
        for dict in array {
            artModelsArray.append(ArtModel(dict: dict))
            
        }
        return artModelsArray
    }
}
