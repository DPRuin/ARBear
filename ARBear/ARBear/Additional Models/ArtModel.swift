//
//  ArtModel.swift
//  ARBear
//
//  Created by mac126 on 2018/5/4.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit

class ArtModel: NSObject {

    var name: String?
    var imageURL: String?
    var downloadURL: String?
    
    static let properties = ["name", "imageURL", "downloadURL"]
    
    init(dict: [String : Any]) {
        super.init()
        for key in ArtModel.properties {
            if dict[key] != nil {
                setValue(dict[key], forKey: key)
            }
        }
    }
    
    /// 模型数组
    class func artModels(array: Array<[String : Any]>) -> [ArtModel] {
        
        var artModelsArray = [ArtModel]()
        for dict in array {
            artModelsArray.append(ArtModel(dict: dict))
        }
        return artModelsArray
    }
}
