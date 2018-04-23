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
            imageView.image = UIImage(named: modelName)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    
}
