//
//  VirtualObjectCollectionViewCell.swift
//  PresentBottomVC
//
//  Created by mac126 on 2018/4/21.
//  Copyright © 2018年 WHX. All rights reserved.
//

import UIKit

class VirtualObjectCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    static let reuseIdentifier = "ObjectCell"
    
    var modelName = "" {
        didSet {
            label.text = modelName.capitalized
            imageView.image = UIImage(named: "Images.bundle/\(modelName)")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        label.textColor = UIColor(r: 220, g: 220, b: 220)
        label.font = UIFont.systemFont(ofSize: 14)
    }
    
    
}
