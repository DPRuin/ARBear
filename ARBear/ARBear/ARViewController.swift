/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit
import Photos

class ARViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    @IBOutlet weak var addObjectButton: UIButton!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    @IBOutlet weak var imageView: UIImageView!
    
    /// 录制相关
    var recorder:RecordAR?
    let recordingQueue = DispatchQueue(label: "recordingThread", attributes: .concurrent)
    @IBOutlet weak var squishButton: SquishButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    /// 录制时间
    var count: Float!
    /// 定时器
    var timer: Timer!
    /// 最大录制时间
    let maxVideoTime: Float = 10.0
    
    // MARK: - UI Elements
    
    var focusSquare = FocusSquare()
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
    
    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// 队列，用于协调添加或删除场景中的节点。
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    let configuration = ARWorldTrackingConfiguration()
    
    private var nowImage: UIImage!
    private var nowVedioUrl: URL!
    private var isVedio: Bool!
    
    /// 播放器
    fileprivate var player = Player()
    private weak var bgImageView: UIImageView!
    
    /// 微博消息体
    var messageObject: WBMessageObject!
    var ummessageObject: AnyObject!
    
    deinit {
        self.player.willMove(toParentViewController: self)
        self.player.view.removeFromSuperview()
        self.player.removeFromParentViewController()
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 设置播放器
        setupPlayer()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Set up scene content.
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)

        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        // 关闭
        statusViewController.closeBtnClickHandler = {
            self.dismiss(animated: true, completion: nil)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self
        sceneView.addGestureRecognizer(tapGesture)
        
        // 录制设置
        setupRecorder()
        setupRecordUI()

        // 单击block
        virtualObjectInteraction.oneTapGestureHandler = {
            // self.showVirtualObjectSelectionViewController()
            self.tapToShowVirtualObject()
        }
        
        addObjectButton.setImage(UIImage(named: "Images.bundle/add"), for: [])
        addObjectButton.setImage(UIImage(named: "Images.bundle/addPressed"), for: [.highlighted])
        
        // 分享面板设置
        setPreDefinePlatforms()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 录制
        recorder?.prepare(configuration)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("设备不支持")
        }
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true

        // Start the `ARSession`.
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        session.pause()
        
        // 录制
        if recorder?.status == .recording {
            recorder?.stopAndExport()
        }
        recorder?.onlyRenderWhileRecording = true
        recorder?.prepare(ARWorldTrackingConfiguration())
        
        // Switch off the orientation lock for UIViewControllers with AR Scenes
        recorder?.rest()
    }
    
    /// 单击切换已下载的动画
    func tapToShowVirtualObject() {
        guard let beforeObject = self.virtualObjectLoader.loadedObjects.first  else {
            return
        }
        let cachesObjects = VirtualObject.availableCachesObjects()
        if cachesObjects.count <= 0 {return}
        
        // 获取下一个
        let cachesObject = cachesObjects.filter({ (object) -> Bool in
            print("--\(object.modelName)--\(beforeObject.modelName)")
            return object.modelName == beforeObject.modelName
        }).first!
        
        let index = cachesObjects.index(of: cachesObject)
        print("--index\(index)")
        var nowIndex = 0
        if index == cachesObjects.count - 1 {
            nowIndex = 0
        } else {
            nowIndex = index! + 1
        }
        let showObject = cachesObjects[nowIndex]
        print("-b-\(self.virtualObjectLoader.loadedObjects.count)")
        // 删除原来的模型
        self.virtualObjectLoader.removeAllVirtualObjects()
        print("-n-\(self.virtualObjectLoader.loadedObjects.count)")
        
        // 放置选中的模型
        self.virtualObjectLoader.loadVirtualObject(showObject, loadedHandler: { [unowned self] loadedObject in
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                self.placeVirtualObject(loadedObject)
            }
        })
        
        self.displayObjectLoadingUI()
    }
    
    /// 设置播放器
    private func setupPlayer() {
        self.player.view.frame = self.view.bounds
        self.addChildViewController(self.player)
        self.view.addSubview(self.player.view)
        self.player.didMove(toParentViewController: self)
        
        self.player.playbackLoops = true
        self.player.playbackResumesWhenEnteringForeground = false
        self.player.playbackResumesWhenBecameActive = false
        
        let bgImageView = UIImageView(frame: self.view.bounds)
        bgImageView.isHidden = true
        self.bgImageView = bgImageView
        
        self.player.view.addSubview(bgImageView)
        
        // 取消按钮
        let cancelBtn = UIButton(type: .custom)
        cancelBtn.setImage(UIImage(named: "Images.bundle/btn_cancel"), for: UIControlState.normal)
        cancelBtn.addTarget(self, action: #selector(self.btnAfreshDidClick(_:)), for: .touchUpInside)
        
        let insert:CGFloat = 50.0
        let y = self.view.bounds.height - 44/2 - insert
        cancelBtn.frame = CGRect(x: insert - 44/2, y: y, width: 44, height: 44)
        self.player.view.addSubview(cancelBtn)
        
        // 确认按钮
        let confirmBtn = UIButton(type: .custom)
        confirmBtn.setImage(UIImage(named: "Images.bundle/btn_confirm"), for: UIControlState.normal)
        confirmBtn.addTarget(self, action: #selector(self.btnEnsureDidClick(_:)), for: .touchUpInside)
        
        let x = self.view.bounds.width - 44/2 - insert
        confirmBtn.frame = CGRect(x: x, y: y, width: 44, height: 44)
        self.player.view.addSubview(confirmBtn)
        
        // 分享按钮
        let shareButton = UIButton(type: .custom)
        let shareX = self.view.bounds.width / 2 - 44/2
        shareButton.frame = CGRect(x: shareX, y: y, width: 44, height: 44)
        shareButton.setImage(UIImage(named: "Images.bundle/btn_share"), for: UIControlState.normal)
        shareButton.addTarget(self, action: #selector(self.btnShareDidClick(_:)), for: .touchUpInside)
        self.player.view.addSubview(shareButton)
        
        
        
    }
    
    // MARK: - 录制按钮点击
    
    @objc func squishButtonTouchUpInside(sender: UIButton) {
        print("squishButtonTouchUpInside")
        // 拍照
        squishButton.type = ButtonType.camera
        
        isVedio = false
        
        nowImage = self.recorder?.photo()
        self.player.url = Bundle.main.url(forResource: "playerneed", withExtension: "mp4")
        self.player.playFromBeginning()
        self.player.pause()
        bgImageView.isHidden = false
        bgImageView.image = nowImage
        
    }
    
    @objc func squishButtonLongPress(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began { // 开始录制视频
            print("longpressbegan")
            squishButton.type = ButtonType.video
            
            progressView.isHidden = false
            // 计时
            count = 0
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleTimer(sender:)), userInfo: nil, repeats: true)
            timer.fire()
            
            isVedio = true
            
            // Record
            if recorder?.status == .readyToRecord { // 开始录制
                
                recordingQueue.async {
                    self.recorder?.record()
                }
            }
            
        } else if gesture.state == .ended { // 结束录制视频
            print("longpressended")
            squishButton.type = ButtonType.camera
            
            timer.invalidate()
            print("-count-\(count)")
            progressView.isHidden = true
            
            // recorder
            if recorder?.status == .recording { // 停止录制
                
                recorder?.stop({ (url) in
                    DispatchQueue.main.async {
                        self.bgImageView.isHidden = true
                    }
                    
                    self.nowVedioUrl = url
                    self.player.url = url
                    self.player.playFromBeginning()
                })
            }
        }
        
    }
    
    @objc func handleTimer(sender: Timer) {
        count = count + 0.1
        if maxVideoTime > count { // 继续录制视频
            progressView.progress = count / maxVideoTime
            
        } else { // 停止录制视频
            let gesture = squishButton.gestureRecognizers?.filter({ (gesture) -> Bool in
                return gesture is UILongPressGestureRecognizer
            }).first as! UILongPressGestureRecognizer
            
            gesture.state = .ended
            print("到时间了")
        }
    }
    
    @objc func btnAfreshDidClick(_ sender: UIButton) {
        self.player.pause()
        self.player.view.isHidden = true
    }
    
    @objc func btnEnsureDidClick(_ sender: UIButton) {
        self.player.pause()
        self.player.view.isHidden = true
        
        if isVedio {
            recorder?.export(video: nowVedioUrl, { (saved, status) in
                DispatchQueue.main.sync {
                    self.exportMessage(success: saved, status: status)
                }
            })
            
        } else {
            self.recorder?.export(UIImage: nowImage) { saved, status in
                if saved {
                    self.exportMessage(success: saved, status: status)
                }
            }
        }
    }
    
    /// 分享
    @objc func btnShareDidClick(_ sender: UIButton) {
//        if isVedio {
//            messageObject = weiboVideoMessage(videoUrl: nowVedioUrl)
//        } else {
//            messageObject = weiboImageMessage(images: [nowImage])
//        }
        
        // UIActivityIndicatorView 设置指示器
        
        if isVedio {
            ummessageObject = nowVedioUrl as AnyObject
        } else {
            ummessageObject = nowImage
        }
        // 展示友盟分享面板
        showUM()
        
    }
    
    // MARK: - Exported UIAlert present method
    func exportMessage(success: Bool, status:PHAuthorizationStatus) {
        if success {
            let alert = UIAlertController(title: "导出", message: "导出相册成功", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else if status == .denied || status == .restricted || status == .notDetermined {
            let errorView = UIAlertController(title: "😅", message: "相册权限", preferredStyle: .alert)
            let settingsBtn = UIAlertAction(title: "OpenSettings", style: .cancel) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        })
                    } else {
                        UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
                    }
                }
            }
            errorView.addAction(UIAlertAction(title: "Later", style: UIAlertActionStyle.default, handler: {
                (UIAlertAction)in
            }))
            errorView.addAction(settingsBtn)
            self.present(errorView, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Exporting Failed", message: "There was an error while exporting your media file.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /// MARK: - ARVideoKit
    func setupRecorder() {
        // Initialize ARVideoKit recorder
        recorder = RecordAR(ARSceneKit: sceneView)
        
        /*----👇---- ARVideoKit Configuration ----👇----*/
        
        // Set the recorder's delegate
        recorder?.delegate = self
        
        // Set the renderer's delegate
        recorder?.renderAR = self
        
        // Configure the renderer to perform additional image & video processing 👁
        recorder?.onlyRenderWhileRecording = false
        
        // Configure ARKit content mode. Default is .auto
        recorder?.contentMode = .aspectFill
        
        // Set the UIViewController orientations
        recorder?.inputViewOrientations = [.landscapeLeft, .landscapeRight, .portrait]
        // Configure RecordAR to store media files in local app directory
        recorder?.deleteCacheWhenExported = false
    }
    
    /// 设置录制UI
    func setupRecordUI() {
        progressView.progress = 0
        progressView.isHidden = true
        progressView.progressTintColor = UIColor.red
        
        squishButton.addTarget(self, action: #selector(self.squishButtonTouchUpInside(sender:)), for: UIControlEvents.touchUpInside)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(squishButtonLongPress(gesture:)))
        // 定义长按0.8时间触发
        longPress.minimumPressDuration = 0.8
        squishButton.addGestureRecognizer(longPress)
        
    }
    
    // MARK: - Scene content setup

    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }

        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }

    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
    func resetTracking() {
        
        configuration.planeDetection = .horizontal
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("寻找平面去放置物体", inSeconds: 7.5, messageType: .planeEstimation)
    }

    // MARK: - Focus Square

    func updateFocusSquare() {
        let isObjectVisible = virtualObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("尝试左右移动手机", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // We should always have a valid world position unless the sceen is just being initialized.
        // 除非屏幕初始化， 否则我们应该拥有一个有效的世界位置
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            addObjectButton.isHidden = true
            return
        }
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
            let camera = self.session.currentFrame?.camera
            
            if let planeAnchor = planeAnchor {
                self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
            } else {
                self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
            }
        }
        addObjectButton.isHidden = false
        statusViewController.cancelScheduledMessage(for: .focusSquare)
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "重新启动会话", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }

}

//MARK: - ARVideoKit Delegate Methods
extension ARViewController: RecordARDelegate, RenderARDelegate {
    func frame(didRender buffer: CVPixelBuffer, with time: CMTime, using rawBuffer: CVPixelBuffer) {
        // Do some image/video processing.
    }
    
    func recorder(didEndRecording path: URL, with noError: Bool) {
        if noError {
            // Do something with the video path.
        }
    }
    
    func recorder(didFailRecording error: Error?, and status: String) {
        // Inform user an error occurred while recording.
    }
    
    func recorder(willEnterBackground status: RecordARStatus) {
        // Use this method to pause or stop video recording. Check [applicationWillResignActive(_:)](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622950-applicationwillresignactive) for more information.
        if status == .recording {
            recorder?.stopAndExport()
        }
    }
}
