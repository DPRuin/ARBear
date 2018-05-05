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
    /// 模型titles
    var titleArray = [String]()
    /// 每页的模型数组
    // var artModels = [ArtModel]()
    var artDict = [String : Array<[String : AnyObject]>]()
    
    weak var delegate: VirtualObjectSelectionViewControllerDelegate?
    
    // var selectedVirtualObjectRows = IndexSet()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = false
        loadArtModels()
        setupPageCollection()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Initial method
    private func loadArtModels() {
        // plist
        let path = Bundle.main.path(forResource: "datadic", ofType: "plist")
        let url  = URL(fileURLWithPath: path!)
        let data = try! Data(contentsOf: url)
        let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
        
        
//        let dictArray = plist as! [[String : Any]]
//        for dict in dictArray {
//            titleArray.append(dict["artName"] as! String)
//        }
        
        let dict = plist as! [String : Array<[String : AnyObject]>]
        artDict = dict
        titleArray = Array(dict.keys)
    }
    private func setupPageCollection()  {
        // let titles = ["小熊", "小兔"]
        
        var style = HFPageStyle()
        style.isShowBottomLine = true
        
        let layout = HFPageCollectionLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.colMargin = 8
        layout.rowMargin = 8
        
        let frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)
        let pageCollection = HFPageCollectionView(frame: frame, titles: titleArray, isTop: true, style: style, layout: layout)
        pageCollection.dataSource = self
        pageCollection.delegate = self
        
        pageCollection.registerNib(UINib(nibName: "VirtualObjectCollectionViewCell", bundle: nil), reusableIdentify: "cellCollection")
        view.addSubview(pageCollection)
    }

}

extension VirtualObjectSelectionViewController : HFPageCollectionViewDataSource{
    
    func numberOfSectionsInPageCollectionView(_ pageCollectionView: HFPageCollectionView) -> Int {
        return titleArray.count
    }
    
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, numberOfItemsIn section: Int) -> Int {
        let key = titleArray[section]
        let array = artDict[key]!
        return array.count
    }
    
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCollection", for: indexPath) as! VirtualObjectCollectionViewCell
        // cell.modelName = virtualObjects[indexPath.item].modelName
        // cell.backgroundColor = UIColor.randomColor()
        
        let key = titleArray[indexPath.section]
        let array = artDict[key]!
        let artModels = ArtModel.artModels(array: array)
        cell.artMondel = artModels[indexPath.item]
        return cell
    }
}

extension VirtualObjectSelectionViewController: HFPageCollectionViewDelegate {
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // 先判断是否已下载，如果已下载从沙盒获取，加载模型到现实，
        // 若未下载，从网络开始下载模型存入沙盒
        let key = titleArray[indexPath.section]
        let array = artDict[key]!
        let artModels = ArtModel.artModels(array: array)
        let selectedArtModel = artModels[indexPath.item]
        if selectedArtModel.isDownloaded { // 已下载
            // TODO: 需要修改
            let object = virtualObjects[indexPath.item]
            delegate?.virtualObjectSelectionViewController(self, didSelectObject: object)
            self.dismiss(animated: true, completion: nil)
            
        } else {
            // 开始下载模型
            
        }
        
    }
    
    
}
