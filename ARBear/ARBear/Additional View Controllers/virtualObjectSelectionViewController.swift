//
//  VirtualObjectSelectViewController.swift
//  ARBear
//
//  Created by mac126 on 2018/4/23.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit

// MARK: - VirtualObjectSelectionViewControllerDelegate

/// 协议
protocol VirtualObjectSelectionViewControllerDelegate: class {
    func virtualObjectSelectionViewController(_ selectionViewController: VirtualObjectSelectionViewController, didSelectObject: VirtualObject)
}

class VirtualObjectSelectionViewController: UIViewController, PresentBottomType {

    var contentHeight: CGFloat {
        return 300
    }
    
    var canPanDown: Bool {
        return true
    }
    
    /// 3d模型数据
    var virtualObjects = [VirtualObject]()
    
    weak var delegate: VirtualObjectSelectionViewControllerDelegate?
    
    // var selectedVirtualObjectRows = IndexSet()
    
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
        let titles = ["小熊", "小兔"]
        
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

extension VirtualObjectSelectionViewController : HFPageCollectionViewDataSource{
    
    func numberOfSectionsInPageCollectionView(_ pageCollectionView: HFPageCollectionView) -> Int {
        return 2
    }
    
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, numberOfItemsIn section: Int) -> Int {
        return virtualObjects.count
    }
    
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCollection", for: indexPath) as! VirtualObjectCollectionViewCell
        cell.modelName = virtualObjects[indexPath.item].modelName
        // cell.backgroundColor = UIColor.randomColor()
        return cell
    }
}

extension VirtualObjectSelectionViewController: HFPageCollectionViewDelegate {
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("-----")
        print("index-\(indexPath)")
        
        let object = virtualObjects[indexPath.item]
        
        delegate?.virtualObjectSelectionViewController(self, didSelectObject: object)

        self.dismiss(animated: true, completion: nil)
        // TODO: 下载选中的模型
        // 先判断是否已下载，如果已下载从沙盒获取，若未下载，从网络下载存入沙盒
    }
}
