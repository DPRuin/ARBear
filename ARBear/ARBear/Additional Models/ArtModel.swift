//
//  ArtModel.swift
//  ARBear
//
//  Created by mac126 on 2018/5/4.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit

class ArtModel: NSObject {

    @objc var name: String = ""
    @objc var imageURL: String = ""
    @objc var downloadURL: String = ""
    var isDownloaded: Bool = true
    
    static let properties = ["name", "imageURL", "downloadURL"]
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        print("UndefinedKey-\(key)-\(value)")
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        super.setValue(value, forKey: key)
    }
    
    override var description: String {
        let dict = dictionaryWithValues(forKeys: ArtModel.properties)
        return ("\(dict)")
    }
    
    init(dict: [String : AnyObject]) {
        super.init()
        setValuesForKeys(dict)
    }
    
    /// 模型数组
    class func artModels(array: [[String : AnyObject]]) -> [ArtModel] {

        var artModelsArray = [ArtModel]()
        for dict in array {
            artModelsArray.append(ArtModel(dict: dict))

        }
        return artModelsArray
    }
}
