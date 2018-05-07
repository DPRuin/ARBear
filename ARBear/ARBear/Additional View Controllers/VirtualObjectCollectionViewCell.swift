//
//  VirtualObjectCollectionViewCell.swift
//  PresentBottomVC
//
//  Created by mac126 on 2018/4/21.
//  Copyright © 2018年 WHX. All rights reserved.
//

import UIKit
import SDWebImage

class VirtualObjectCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var downloadBtn: UIButton!
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var artMondel: ArtModel! {
        didSet {
            label.text = artMondel.name
            let placeholderImage = UIImage(named: "Images.bundle/panda")
            let imageURL = URL(string: artMondel.imageURL)
            imageView.sd_setImage(with: imageURL, placeholderImage: placeholderImage, options: .allowInvalidSSLCertificates, completed: nil)
            downloadBtn.isHidden = artMondel.isDownloaded
        }
    }
    
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
        downloadBtn.isHidden = false
        // downloadBtn.setBackgroundImage(UIImage(named: "Images.bundle/downloadbg"), for: .normal)
        downloadBtn.setImage(UIImage(named: "Images.bundle/download"), for: .normal)
    }
    
    open func stopAnimating() {
        indicator.stopAnimating()
    }
    open func startAnimating() {
        indicator.startAnimating()
    }
    
}
