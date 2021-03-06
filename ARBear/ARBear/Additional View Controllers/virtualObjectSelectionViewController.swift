//
//  VirtualObjectSelectViewController.swift
//  ARBear
//
//  Created by mac126 on 2018/4/23.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import AFNetworking
import SSZipArchive

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
    weak var pageCollection: HFPageCollectionView!
    weak var delegate: VirtualObjectSelectionViewControllerDelegate?
    
    // var selectedVirtualObjectRows = IndexSet()
    
    // 下载block
    var downloadCompleteHandler: () -> Void = {}
    
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
        
        let dict = plist as! [String : Array<[String : AnyObject]>]
        artDict = dict
        titleArray = Array(dict.keys)
    }
    
    /// 设置选择界面
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
        self.pageCollection = pageCollection
        
        pageCollection.registerNib(UINib(nibName: "VirtualObjectCollectionViewCell", bundle: nil), reusableIdentify: "cellCollection")
        view.addSubview(pageCollection)
    }

}

// MARK: - HFPageCollectionViewDataSource

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

// MAKR: - HFPageCollectionViewDelegate

extension VirtualObjectSelectionViewController: HFPageCollectionViewDelegate {
    func pageCollectionView(_ pageCollectionView: HFPageCollectionView, _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // 先判断是否已下载，如果已下载从沙盒获取，加载模型到现实，
        // 若未下载，从网络开始下载模型存入沙盒
        let key = titleArray[indexPath.section]
        let array = artDict[key]!
        let artModels = ArtModel.artModels(array: array)
        let selectedArtModel = artModels[indexPath.item]
        if selectedArtModel.isDownloaded { // 已下载
            // let object = virtualObjects[indexPath.item]
            showVirtualObject(name: selectedArtModel.name)
        } else {
            // 开始下载模型
            // 发出通知开始动画
            let cell = collectionView.cellForItem(at: indexPath) as! VirtualObjectCollectionViewCell
            cell.startAnimating()
            
            downloadVirtualObject(downloadURL: selectedArtModel.downloadURL, downloadCompleteHandler: {
                cell.stopAnimating()
                self.pageCollection.reloadItems(at: [indexPath])
            })
            
        }
        
        
    }
    
    /// 展示模型
    private func showVirtualObject(name: String) {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let component = "\(name).scnassets/\(name).scn"
        let destinationURL = cachesDirectory.appendingPathComponent(component)
        let object = VirtualObject(url: destinationURL)
        delegate?.virtualObjectSelectionViewController(self, didSelectObject: object!)
        self.dismiss(animated: true, completion: nil)
    }
    
    /// 下载模型
    private func downloadVirtualObject(downloadURL: String, downloadCompleteHandler:@escaping ()->Void) {
        let configuration = URLSessionConfiguration.default
        let manager = AFURLSessionManager(sessionConfiguration: configuration)
        let url = URL(string: downloadURL)!
        let urlRequest = URLRequest(url: url)
        
        let downloadTask = manager.downloadTask(with: urlRequest, progress: { (progress) in
             print("download-progress-\(progress)")
        }, destination: { (targetPath, response) -> URL in
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            return cachesDirectory.appendingPathComponent(response.suggestedFilename!)
        }, completionHandler: { (response, filePath, error) in
            let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            let component = "/\(url.lastPathComponent)"
            let inputPath = cachesDirectory.appendingFormat(component)
            print("-inputPath-\(inputPath)")
            self.unZipVirtualObject(atPath: inputPath, toDestination: cachesDirectory, completeHandler: downloadCompleteHandler )
        })
        // 开始下载
        downloadTask.resume()
        
    }
    
    private func unZipVirtualObject(atPath path: String, toDestination destination:String, completeHandler:@escaping ()->Void) {
        // 下载完成，对文件解压
        SSZipArchive.unzipFile(atPath: path, toDestination: destination, overwrite: true, password: nil, progressHandler: { (entry, zipInfo, entryNumber, total) in
            print("-progressHandler-\(entry)--\(entryNumber)--\(total)")
        }, completionHandler: { (path, succeeded, error) in
            print("-completionHandler-\(path)--\(succeeded)--\(error)")
            if succeeded && error == nil {
                completeHandler()
            } else {
                // 解压失败
            }

        })
    }
    
    
}
