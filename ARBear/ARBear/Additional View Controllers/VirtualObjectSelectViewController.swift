//
//  VirtualObjectSelectViewController.swift
//  ARBear
//
//  Created by mac126 on 2018/4/23.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit

class VirtualObjectSelectViewController: UIViewController, PresentBottomType {

    var contentHeight: CGFloat {
        return 300
    }
    
    var canPanDown: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = false
        setupPageCollection()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupPageCollection()  {
        let titles = ["我的", "小熊"]
        
        var style = HFPageStyle()
        style.isShowBottomLine = true
        
        let layout = HFPageCollectionLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.colMargin = 8
        layout.rowMargin = 8
        
        let frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)
        let pageCollection = HFPageCollectionView(frame: frame, titles: titles, isTop: true, style: style, layout: layout)
        pageCollection.dataSource = self
        pageCollection.delegate = self
        
        pageCollection.registerNib(UINib(nibName: "VirtualObjectCollectionViewCell", bundle: nil), reusableIdentify: "cellCollection")
        view.addSubview(pageCollection)
    }

}

extension VirtualObjectSelectViewController : HFPageCollectionViewDataSource{
    
    func numberOfSectionsInPageCollectionView(_ pageCollectionView: HFPageCollectionView) -> Int {
        return 2
    }
    
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, numberOfItemsIn section: Int) -> Int {
        return Int(arc4random_uniform(16) + 6)
    }
    
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCollection", for: indexPath)
        // cell.backgroundColor = UIColor.randomColor()
        return cell
    }
}

extension VirtualObjectSelectViewController: HFPageCollectionViewDelegate {
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("-----")
        print("index-\(indexPath)")
    }
}
