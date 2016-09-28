//
//  GestureCameraViewController.swift
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 9/14/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

let kCThumbnailSize     : CGSize        = CGSize(width: kCBottomBarHeight - padding, height: kCBottomBarHeight - padding)
let kCTimeInterval      : TimeInterval  = 1 // second
let kCBottomBarHeight   : CGFloat       = 100
let padding             : CGFloat       = 15

class GestureCameraViewController: UIViewController {

    lazy var captureDevice: AVCaptureDevice = AVCaptureDevice()
    lazy var inputDevice: AVCaptureDeviceInput = AVCaptureDeviceInput()
    
    lazy var outputData    : AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    lazy var movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    
    lazy var audioCaptureDevice : AVCaptureDevice = AVCaptureDevice()
    lazy var audioInputDevice: AVCaptureDeviceInput = AVCaptureDeviceInput()
    
    lazy var outputPath = NSTemporaryDirectory()
    
    lazy var isVideo : Bool = true
    lazy var appendix : Int = 0
    lazy var isRecording : Bool = false
    
    lazy var captureSession : AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = self.isVideo ? AVCaptureSessionPreset1280x720 : AVCaptureSessionPresetPhoto
        return s
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview?.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - kCBottomBarHeight)
        preview?.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY - kCBottomBarHeight / 2)
        preview?.videoGravity = AVLayerVideoGravityResizeAspectFill //AVLayerVideoGravityResize
        return preview!
    }()
    
    // Side elastic constants
    lazy var minimumWidth   : CGFloat       = 0.0
    lazy var maxBaseWidth   : CGFloat       = 10.0
    lazy var maxWaveHeight  : CGFloat       = 125.0
    lazy var leftShapeLayer : CAShapeLayer  = CAShapeLayer()
    
    lazy var l3ControlPointView = UIView()
    lazy var l2ControlPointView = UIView()
    lazy var l1ControlPointView = UIView()
    lazy var cControlPointView  = UIView()
    lazy var r1ControlPointView = UIView()
    lazy var r2ControlPointView = UIView()
    lazy var r3ControlPointView = UIView()
    
    lazy var displayLink : CADisplayLink = CADisplayLink(target: self, selector: #selector(updateShapeLayer))
    var timer : Timer = Timer(timeInterval: kCTimeInterval, target: self, selector: #selector(updateLabels), userInfo: nil, repeats: true)
    
    var animating = false {
        didSet {
            self.view.isUserInteractionEnabled = !self.animating
            self.displayLink.isPaused = !self.animating
        }
    }
    
    var height          : CGFloat { return self.view.bounds.height - kCBottomBarHeight }
    var width           : CGFloat { return self.view.bounds.width }
    var currentZoom     : CGFloat { return self.captureDevice.videoZoomFactor }
    lazy var maxZoom    : CGFloat = self.captureDevice.activeFormat.videoMaxZoomFactor
    lazy var videoDuration      : Int       = 0
    var zoomText           : String { return NSString(format: "%0.1f", self.currentZoom) as String }    
    
    // UI
    lazy var videoDurationLabel : UILabel   = UILabel()
    lazy var zoomLabel          : UILabel   = UILabel()
    lazy var fsAlbumImageView   : UIImageView = UIImageView()
    lazy var imageView          : UIImageView = UIImageView(frame: self.previewLayer.frame)
    var thumbnail               : UIImage?
    
    lazy var fsPhotoAlbum : FSPhotoAlbum = FSPhotoAlbum.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.addGestures()
        self.loadVideoCamera()
        self.addAudioInputs()
        self.addAlbumView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.view.layer.addSublayer(self.previewLayer)
        self.setupGestureViews()
        
        self.captureSession.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool { return true }

    func loadVideoCamera() {
        
        self.captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            self.inputDevice = try AVCaptureDeviceInput(device: self.captureDevice)
            
            self.captureSession.beginConfiguration()
            
            if self.captureSession.canAddInput(self.inputDevice) {
                self.captureSession.addInput(self.inputDevice)
            }
            
            self.outputData.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]

            self.outputData.alwaysDiscardsLateVideoFrames = true
            
            if self.captureSession.canAddOutput(self.outputData) {
                self.captureSession.addOutput(self.outputData)
            }
            
            if self.captureSession.canAddOutput(self.movieFileOutput) {
                self.captureSession.addOutput(self.movieFileOutput)
            }
            
            self.movieFileOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
//            self.movieFileOutput.movieFragmentInterval = kCMTimeInvalid
            
            self.captureSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.fllscrn.videoCapture", attributes: [])
            self.outputData.setSampleBufferDelegate(self, queue: queue)
        }
        catch let error as NSError {
            print("\(error), \(error.localizedDescription)")
        }
    }
    
    func addAudioInputs() {
        
        self.audioCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        
        do {
            self.audioInputDevice = try AVCaptureDeviceInput(device: self.audioCaptureDevice)
            
            self.captureSession.beginConfiguration()
            
            if self.captureSession.canAddInput(self.audioInputDevice) {
                self.captureSession.addInput(self.audioInputDevice)
            }
            
            self.captureSession.commitConfiguration()
        }
        catch let error as NSError {
            print("Could not configure audio: \(error.localizedDescription)")
        }
        
        print("Has audio \(self.captureSession.usesApplicationAudioSession)")
    }
    
    func addAlbumView() {
        
        self.fsAlbumImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.fsAlbumImageView)
        
        self.fsAlbumImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -padding).isActive = true
        self.fsAlbumImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.fsAlbumImageView.heightAnchor.constraint(equalToConstant: kCBottomBarHeight - 2 * padding).isActive = true
        self.fsAlbumImageView.widthAnchor.constraint(equalTo: self.fsAlbumImageView.heightAnchor).isActive = true
        
        self.fsAlbumImageView.backgroundColor = UIColor.darkGray
        self.fsAlbumImageView.contentMode = .scaleAspectFill
        
        print("Album view frame: \(fsAlbumImageView.frame)")
        
        self.fsPhotoAlbum.getImages(count: 1) { (imageArray) in
            
            let croppedImage = self.fsPhotoAlbum.cropToBounds(image: imageArray.first!!, width: kCBottomBarHeight, height: kCBottomBarHeight)
            
            DispatchQueue.main.async { self.fsAlbumImageView.image = croppedImage }
            
        }
    }
}

extension GestureCameraViewController : AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
        self.startTimer()
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        self.fsPhotoAlbum.saveVideo(videoPathURL: outputFileURL) { (isComplete, error) in
            
            if let error = error { print(error.localizedDescription) }
            else if isComplete {
                
                print("Saved video.")
                
                DispatchQueue.main.async {
                    self.thumbnail = self.fsPhotoAlbum.generateThumbnailFrom(filePath: outputFileURL)
                    self.animate(thumbnail: self.thumbnail)
                }
            }
        }
        
        self.timer.invalidate()
        self.isRecording = false
        self.videoDuration = 0
        self.videoDurationLabel.text = "0s"
        self.zoomLabel.text = "1.0x"
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
    }
}

extension GestureCameraViewController : UIGestureRecognizerDelegate {
    
    func setupGestureViews() {
        self.leftShapeLayer.frame = CGRect(x: 0.0, y: 0.0, width: self.minimumWidth, height: self.view.bounds.height)
        self.leftShapeLayer.fillColor = UIColor.fllscrnRed().cgColor
        self.leftShapeLayer.actions = ["position" : NSNull(), "bounds" : NSNull(), "path" : NSNull()]
        
        self.view.layer.addSublayer(self.leftShapeLayer)
        
        self.l3ControlPointView.frame = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.l2ControlPointView.frame = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.l1ControlPointView.frame = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.cControlPointView.frame  = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.r1ControlPointView.frame = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.r2ControlPointView.frame = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.r3ControlPointView.frame = CGRect(x: 0.0, y: 0.0, width: 3.0, height: 3.0)
        self.videoDurationLabel.frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 25.0)
        self.zoomLabel.frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 25.0)
        
        self.l3ControlPointView.backgroundColor = .red
        self.l2ControlPointView.backgroundColor = .red
        self.l1ControlPointView.backgroundColor = .red
        self.cControlPointView.backgroundColor = .red
        self.r1ControlPointView.backgroundColor = .red
        self.r2ControlPointView.backgroundColor = .red
        self.r3ControlPointView.backgroundColor = .red
        
        self.videoDurationLabel.adjustsFontSizeToFitWidth = true
        self.videoDurationLabel.text = "0s"
        self.videoDurationLabel.textColor = UIColor.white
        self.videoDurationLabel.font = UIFont.fllscrnFont(20.0)
        self.videoDurationLabel.textAlignment = .right
        
        self.zoomLabel.adjustsFontSizeToFitWidth = true
        self.zoomLabel.text = "1.0x"
        self.zoomLabel.textColor = UIColor.white
        self.zoomLabel.font = UIFont.fllscrnFont(16.0)
        self.zoomLabel.textAlignment = .right
        
        self.view.addSubview(self.l3ControlPointView)
        self.view.addSubview(self.l2ControlPointView)
        self.view.addSubview(self.l1ControlPointView)
        self.view.addSubview(self.cControlPointView)
        self.view.addSubview(self.r1ControlPointView)
        self.view.addSubview(self.r2ControlPointView)
        self.view.addSubview(self.r3ControlPointView)
        self.view.addSubview(self.videoDurationLabel)
        self.view.addSubview(self.zoomLabel)
        
        self.layoutControlPoints(baseWidth: self.minimumWidth, waveWidth: 0.0, locationY: self.height / 2.0)
        
        self.videoDurationLabel.center.x = self.minimumWidth - self.videoDurationLabel.right.x
        self.zoomLabel.center.x = self.minimumWidth - self.zoomLabel.right.x
        
        self.updateShapeLayer()
        
        self.displayLink.add(to: .main, forMode: .defaultRunLoopMode)
        displayLink.isPaused = true
    }
    
    func addGestures() {
        
        let videoSwipeGesture = UIScreenEdgePanGestureRecognizer()
        videoSwipeGesture.accessibilityLabel = "video"
        videoSwipeGesture.edges = .left
        videoSwipeGesture.delegate = self
        videoSwipeGesture.maximumNumberOfTouches = 2
        videoSwipeGesture.addTarget(self, action: #selector(recordFrom))
        self.view.addGestureRecognizer(videoSwipeGesture)
        
        let photoSwipeGesture = UIScreenEdgePanGestureRecognizer()
        photoSwipeGesture.accessibilityLabel = "photo"
        photoSwipeGesture.edges = .right
        photoSwipeGesture.delegate = self
        photoSwipeGesture.maximumNumberOfTouches = 2
        photoSwipeGesture.addTarget(self, action: #selector(recordFrom))
        self.view.addGestureRecognizer(photoSwipeGesture)
    }
    
    func recordFrom(gesture : UIScreenEdgePanGestureRecognizer) {
        
        if gesture.accessibilityLabel == "video" {

            if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
                
                if self.isRecording { self.movieFileOutput.stopRecording() }
                self.zoom(to: 1.0, withRate: 75.0)
                self.captureDevice.unlockForConfiguration()
                self.animating = true
                
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: { 
            
                    self.l3ControlPointView.center.x = self.minimumWidth
                    self.l2ControlPointView.center.x = self.minimumWidth
                    self.l1ControlPointView.center.x = self.minimumWidth
                    self.cControlPointView.center.x  = self.minimumWidth
                    self.r1ControlPointView.center.x = self.minimumWidth
                    self.r2ControlPointView.center.x = self.minimumWidth
                    self.r3ControlPointView.center.x = self.minimumWidth
                    self.videoDurationLabel.center.x = self.minimumWidth - self.videoDurationLabel.right.x
                    self.zoomLabel.center.x = self.minimumWidth - self.zoomLabel.right.x
                    
                    }, completion: { (completed) in
                        
                        self.animating = false
                        self.leftShapeLayer.fillColor = UIColor.fllscrnRed().cgColor
                })
            }
            else {
                
//                if !self.isRecording {
//                    _ = self.recordVideoToFile()
//                    self.isRecording = true
//                    self.lockDevice()
//                }
                self.lockDevice()
                
                let additionalHeight = max(gesture.translation(in: view).x, 0)
                
                let waveWidth = min(additionalHeight * 0.95, self.maxWaveHeight)
                let baseWidth = min(self.minimumWidth + additionalHeight - waveWidth, self.maxBaseWidth)
                
                let locationY = gesture.location(in: gesture.view).y
                
                if baseWidth == self.maxBaseWidth && !self.isRecording {
                    _ = self.recordVideoToFile()
                    self.isRecording = true
                    self.leftShapeLayer.fillColor = UIColor.fllscrnRed(alpha: 0.2).cgColor
                }
                else if !self.isRecording { self.updateAlpha(to: baseWidth / self.maxBaseWidth) }
                
                self.layoutControlPoints(baseWidth: baseWidth, waveWidth: waveWidth, locationY: locationY)
                self.updateShapeLayer()
//                self.updateAlpha(to: baseWidth/self.maxBaseWidth)
                
                let zoomFactor = gesture.translation(in: view).y/self.height

                if abs(zoomFactor) > 0.035 {
                    self.zoom(to: zoomFactor, withRate: 3.5)
                }
                else {
                    self.zoom(to: 1.0, withRate: 3.5)
                }
            }
        }
    }
    
    fileprivate func recordVideoToFile() -> URL {
        
        let outputFilePath = self.outputPath + "output-\(self.appendix).mov"
        self.appendix += 1
        let outputURL = URL(fileURLWithPath: outputFilePath)
        let fileManager = FileManager.default
        
        if(fileManager.fileExists(atPath: outputFilePath)) {
            
            do { try fileManager.removeItem(atPath: outputFilePath) }
            catch _ { }
        }
        
        self.movieFileOutput.startRecording(toOutputFileURL: outputURL, recordingDelegate: self)
        
        return outputURL
    }
    
    fileprivate func currentPath() -> CGPath {
        
        let bezierPath = UIBezierPath()
        
        bezierPath.move(to: CGPoint(x: 0.0, y: 0.0))
        
        bezierPath.addLine(to: CGPoint(x: l3ControlPointView.dg_center(usePresentationLayerIfPossible: self.animating).x, y: 0.0))
        
        bezierPath.addCurve(to: l1ControlPointView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint1: l3ControlPointView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint2: l2ControlPointView.dg_center(usePresentationLayerIfPossible: self.animating))
        
        bezierPath.addCurve(to: r1ControlPointView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint1: cControlPointView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint2: r1ControlPointView.dg_center(usePresentationLayerIfPossible: self.animating))
        
        bezierPath.addCurve(to: r3ControlPointView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint1: r1ControlPointView.dg_center(usePresentationLayerIfPossible: self.animating), controlPoint2: r2ControlPointView.dg_center(usePresentationLayerIfPossible: self.animating))
        
        bezierPath.addLine(to: CGPoint(x: 0.0, y: height))
        
        bezierPath.close()
        
        return bezierPath.cgPath
    }
    
    func updateShapeLayer() {
        self.leftShapeLayer.path = self.currentPath()
        self.zoomLabel.text = "\(self.zoomText)x"
    }
    
    func startTimer() {
        self.timer = Timer(timeInterval: kCTimeInterval, target: self, selector: #selector(updateLabels), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer, forMode: .defaultRunLoopMode)
    }
    
    func updateLabels() {
        self.videoDuration += Int(kCTimeInterval)
        self.videoDurationLabel.text = "\(self.videoDuration)s"
    }
    
    func updateAlpha(to percent: CGFloat) {
        self.leftShapeLayer.fillColor = UIColor.fllscrnRed(alpha: max(1 - percent, 0.6)).cgColor
    }
    
    func lockDevice() {
        do {
            try self.captureDevice.lockForConfiguration()
        }
        catch let error as NSError {
            print("Error locking device: \(error.localizedDescription))")
        }
    }
    
    fileprivate func layoutControlPoints(baseWidth: CGFloat, waveWidth: CGFloat, locationY: CGFloat) {
        
        let minTopY = min((locationY - height / 2.0) * 0.28, 0.0)
        let maxBottomY = height // max(height + (locationY - height / 2.0) * 0.28, height)
        
        let topPartWidth = locationY - minTopY
        let bottomPartWidth = maxBottomY - locationY
        
//        print("minTopY: \(minTopY)")
//        print("maxBottomY: \(maxBottomY)")
//        print("topPartWidth: \(topPartWidth)")
//        print("bottomPartWidth: \(bottomPartWidth)")
        
        self.l3ControlPointView.center = CGPoint(x: baseWidth, y: minTopY)
        self.l2ControlPointView.center = CGPoint(x: baseWidth, y: minTopY + topPartWidth * 0.44)
        self.l1ControlPointView.center = CGPoint(x: baseWidth + waveWidth * 0.64, y: minTopY + topPartWidth * 0.71)
        self.cControlPointView.center  = CGPoint(x: baseWidth + waveWidth * 1.36, y: locationY)
        self.r1ControlPointView.center = CGPoint(x: baseWidth + waveWidth * 0.64, y: maxBottomY - bottomPartWidth * 0.71)
        self.r2ControlPointView.center = CGPoint(x: baseWidth, y: maxBottomY - (bottomPartWidth * 0.44))
        self.r3ControlPointView.center = CGPoint(x: baseWidth, y: maxBottomY)
        
        self.videoDurationLabel.center = CGPoint(x: baseWidth + waveWidth * 0.6, y: locationY - self.videoDurationLabel.bounds.height)
        self.zoomLabel.center = CGPoint(x: self.videoDurationLabel.center.x, y: self.videoDurationLabel.center.y + self.zoomLabel.bounds.height)
    }
    
    // zoom to percent of total zoom capable for device.
    fileprivate func zoom(to zoomFactor: CGFloat, withRate rate: Float) {
        
        let zoom = min(self.maxZoom, max(1, 1 - 10 * zoomFactor))
        self.captureDevice.ramp(toVideoZoomFactor: zoom, withRate: rate)
    }
}

// Animations
extension GestureCameraViewController : CAAnimationDelegate {
    
    func animate(thumbnail: UIImage?) {
        
        self.imageView.image = thumbnail
        self.imageView.frame = self.previewLayer.frame
        self.imageView.contentMode = .scaleAspectFill
        
        self.view.addSubview(imageView)
        
        UIView.animate(withDuration: 0.75, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            
            self.imageView.frame = self.fsAlbumImageView.frame
            
        }) { (isCompleted) in
            
            self.fsAlbumImageView.image = thumbnail
            self.imageView.removeFromSuperview()
        }
    }
}
