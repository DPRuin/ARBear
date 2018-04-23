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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        // imageView.isUserInteractionEnabled =
//        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.imageDidClick(_:)))
//        imageView.addGestureRecognizer(gesture)
    }
    
    @objc func imageDidClick(_ gesture: UITapGestureRecognizer) {
        print("imageDidClick")
    }
    
}
