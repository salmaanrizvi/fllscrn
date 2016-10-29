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
import CircleSlider

let kCThumbnailSize     : CGSize        = CGSize(width: kCBottomBarHeight - kCDefaultPadding,
                                                 height: kCBottomBarHeight - kCDefaultPadding)
let kCTimeInterval      : TimeInterval  = 1 // second
let kCBottomBarHeight   : CGFloat       = 100
let kCDefaultPadding    : CGFloat       = 15

let kCDefaultZoomRate   : Float         = 3.5
let kCResetZoomRate     : Float         = 75.0

class GestureCameraViewController: UIViewController {

    lazy var captureDevice: AVCaptureDevice = AVCaptureDevice()
    lazy var inputDevice: AVCaptureDeviceInput = AVCaptureDeviceInput()
    
    lazy var outputData         : AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    lazy var movieFileOutput    : AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    lazy var photoOutputData    : AVCapturePhotoOutput = AVCapturePhotoOutput()
    
    lazy var audioCaptureDevice : AVCaptureDevice = AVCaptureDevice()
    lazy var audioInputDevice: AVCaptureDeviceInput = AVCaptureDeviceInput()
    
    lazy var outputPath = NSTemporaryDirectory()
    
    lazy var isLocked : Bool = false
    lazy var isVideo : Bool = false
    lazy var appendix : Int = 0
    lazy var isRecording : Bool = false
    lazy var hasCapturedOne : Bool = false
    lazy var photoCapture : Bool = false
    
    lazy var captureSession : AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = !self.photoVideoSwitch.isOn ? AVCaptureSessionPreset1280x720 : AVCaptureSessionPresetPhoto
        return s
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.captureSession)
//        let topLayoutGuide = UIApplication.shared.statusBarFrame.height
        preview?.bounds = CGRect(x: 0, y: 0, width: self.width, height: self.width)//self.height - topLayoutGuide * 2)
        preview?.position = CGPoint(x: self.view.bounds.midX, y: self.width / 2 + self.statusBarHeight)
        preview?.videoGravity = AVLayerVideoGravityResizeAspectFill //AVLayerVideoGravityResize
        print("Bounds: \(preview!.bounds)")
        print("Position: \(preview?.position)")
        return preview!
    }()
    
    var gestureView: BezierGestureView!

    var videoTimer : Timer = Timer(timeInterval: kCTimeInterval, target: self, selector: #selector(updateVideoLabels), userInfo: nil, repeats: true)
    
    var height             : CGFloat { return self.view.bounds.height - kCBottomBarHeight }
    var width              : CGFloat { return self.view.bounds.width }
    lazy var statusBarHeight : CGFloat = UIApplication.shared.statusBarFrame.height
    var currentZoom        : CGFloat { return self.captureDevice.videoZoomFactor }
    lazy var maxZoom       : CGFloat = self.captureDevice.activeFormat.videoMaxZoomFactor
    var zoomText           : String  { return NSString(format: "%0.1f", self.currentZoom) as String }
    lazy var videoDuration : Int     = 0
    
    // UI
    lazy var videoDurationLabel : UILabel       = UILabel()
    lazy var zoomLabel          : UILabel       = UILabel()
    lazy var fsAlbumImageView   : UIImageView   = UIImageView()
    lazy var animatedImageView  : UIImageView   = UIImageView()
    var thumbnail               : UIImage?
    
    lazy var photoVideoSwitch   : UISwitch      = UISwitch()
    lazy var flipCameraButton   : UIButton      = UIButton(type: .custom)
    lazy var flashButton        : UIButton      = UIButton(type: .custom)
    lazy var cameraButton       : UIButton      = UIButton(type: .custom)
    lazy var videoButton        : UIButton      = UIButton(type: .custom)
    
    lazy var fsPhotoAlbum       : FSPhotoAlbum = FSPhotoAlbum.sharedInstance
    
    lazy var isoPicker          : AKPickerView = AKPickerView(frame: .zero)
    lazy var shutterPicker      : AKPickerView = AKPickerView(frame: .zero)
    lazy var isoLabel           : UILabel = UILabel()
    lazy var shutterLabel       : UILabel = UILabel()
    
    var maxISO            : Float  { return self.captureDevice.activeFormat.maxISO }
    var minISO            : Float  { return self.captureDevice.activeFormat.minISO }
    var maxShutterSpeed   : CMTime { return self.captureDevice.activeFormat.maxExposureDuration }
    var minShutterSpeed   : CMTime { return self.captureDevice.activeFormat.minExposureDuration }
    
    lazy var isoRange     : [Float]     = []
    lazy var shutterRange : [CMTime]    = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.loadVideoCamera()
        self.addAudioInputs()
        self.view.layer.addSublayer(self.previewLayer)
        
        self.gestureView = BezierGestureView(frame: self.view.frame)
        self.view.addSubview(self.gestureView)
        self.gestureView.delegate = self
        
        self.addAlbumView()
        self.addCameraButtons()
        
        self.setupISOPicker()
        self.setupShutterSpeedPicker()
        self.didSwitch()
        
        self.captureSession.startRunning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.fsPhotoAlbum.getImages(count: 1, size: kCThumbnailSize, videos: true) { (imageArray) in
            
            let images = imageArray.flatMap({ $0 })
            
            guard let firstImage = images.first else {
                print("No pictures to load.")
                return
            }
            
            let croppedImage = self.fsPhotoAlbum.cropToBounds(image: firstImage, width: kCBottomBarHeight, height: kCBottomBarHeight)
            
            DispatchQueue.main.async {
                self.fsAlbumImageView.image = croppedImage
                print("Set initial thumbnail image.")
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("Not unlocking yet.")
        
        if !UserDefaults.standard.bool(forKey: hasLaunchedOnce) {
            UserDefaults.standard.set(true, forKey: hasLaunchedOnce)
            let saved = UserDefaults.standard.synchronize()
            if saved {
                print("First launch saved.")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override var prefersStatusBarHidden : Bool { return true }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    func loadVideoCamera() {
        
        self.captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            self.inputDevice = try AVCaptureDeviceInput(device: self.captureDevice)
            
            self.captureSession.beginConfiguration()
            
            if self.captureSession.canAddInput(self.inputDevice) {
                self.captureSession.addInput(self.inputDevice)
            }
            
            self.outputData.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            
            self.outputData.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString)
                                          : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]

            self.outputData.alwaysDiscardsLateVideoFrames = true
            
            if self.captureSession.canAddOutput(self.outputData) {
                self.captureSession.addOutput(self.outputData)
                self.outputData.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
            }

//            if self.captureSession.canAddOutput(self.photoOutputData) {
//                self.captureSession.addOutput(self.photoOutputData)
//                self.photoOutputData.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
//                
//                print("Available Photo Pixel Format Types: \(self.photoOutputData.availablePhotoPixelFormatTypes)")
//                
//                for formatType in self.photoOutputData.availablePhotoPixelFormatTypes {
//                    print(formats[formatType])
//                }
//            }
            
//            if self.captureSession.canAddOutput(self.movieFileOutput) {
//                self.captureSession.addOutput(self.movieFileOutput)
//                self.movieFileOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
//                print("Added movie file output")
//            }
            
            
            self.captureSession.commitConfiguration()
            
            let videoQueue = DispatchQueue(label: "com.fllscrn.videoCapture", attributes: [])
            self.outputData.setSampleBufferDelegate(self, queue: videoQueue)
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
        
        self.fsAlbumImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -kCDefaultPadding).isActive = true
        self.fsAlbumImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.fsAlbumImageView.heightAnchor.constraint(equalToConstant: kCBottomBarHeight - 2 * kCDefaultPadding).isActive = true
        self.fsAlbumImageView.widthAnchor.constraint(equalTo: self.fsAlbumImageView.heightAnchor).isActive = true
        
        self.fsAlbumImageView.backgroundColor = UIColor.darkGray
        self.fsAlbumImageView.contentMode = .scaleAspectFill
        self.fsAlbumImageView.isUserInteractionEnabled = true
        
        let albumTap = UITapGestureRecognizer()
        albumTap.delegate = self
        albumTap.numberOfTapsRequired = 1
        albumTap.addTarget(self, action: #selector(imageViewTapped))
        self.fsAlbumImageView.addGestureRecognizer(albumTap)
    }
    
    func addCameraButtons() {
        
        self.view.addSubview(self.photoVideoSwitch)
        self.photoVideoSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        self.photoVideoSwitch.centerYAnchor.constraint(equalTo: self.fsAlbumImageView.centerYAnchor).isActive = true
        self.photoVideoSwitch.widthAnchor.constraint(equalTo: self.fsAlbumImageView.widthAnchor).isActive = true
        self.photoVideoSwitch.centerXAnchor.constraint(equalTo: self.fsAlbumImageView.centerXAnchor, constant: self.width / 3).isActive = true
        
        self.photoVideoSwitch.isOn = true
        self.photoVideoSwitch.tintColor = UIColor.fllscrnGreen()
        self.photoVideoSwitch.onTintColor = UIColor.fllscrnPurple()
        self.photoVideoSwitch.addTarget(self, action: #selector(didSwitch), for: .valueChanged)
        
        
        self.view.addSubview(self.videoButton)
        self.videoButton.translatesAutoresizingMaskIntoConstraints = false
        self.videoButton.leadingAnchor.constraint(equalTo: self.fsAlbumImageView.trailingAnchor).isActive = true
        self.videoButton.trailingAnchor.constraint(equalTo: self.photoVideoSwitch.leadingAnchor).isActive = true
        self.videoButton.centerYAnchor.constraint(equalTo: self.fsAlbumImageView.centerYAnchor).isActive = true
        self.videoButton.heightAnchor.constraint(equalTo: self.photoVideoSwitch.heightAnchor).isActive = true
        
        self.videoButton.setImage(whiteVideoCamera, for: .normal)
        self.videoButton.setImage(greenVideoCamera, for: .disabled)
        self.videoButton.isUserInteractionEnabled = false
        self.videoButton.isEnabled = self.photoVideoSwitch.isOn
        
        
        self.view.addSubview(self.cameraButton)
        self.cameraButton.translatesAutoresizingMaskIntoConstraints = false
        self.cameraButton.leadingAnchor.constraint(equalTo: self.photoVideoSwitch.trailingAnchor, constant: -10.0).isActive = true
        self.cameraButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.cameraButton.centerYAnchor.constraint(equalTo: self.fsAlbumImageView.centerYAnchor).isActive = true
        self.cameraButton.heightAnchor.constraint(equalTo: self.photoVideoSwitch.heightAnchor).isActive = true
        
        self.cameraButton.setImage(whiteCamera, for: .normal)
        self.cameraButton.setImage(purpleCamera, for: .disabled)
        self.cameraButton.isUserInteractionEnabled = false
        self.cameraButton.isEnabled = !self.photoVideoSwitch.isOn
    }
    
    func didSwitch() {
        
        self.cameraButton.isEnabled = !self.photoVideoSwitch.isOn
        self.videoButton.isEnabled = self.photoVideoSwitch.isOn
        
        self.lockFor(device: self.photoVideoSwitch.isOn ? .photo : .video)
        self.gestureView.rightEdgeGesture.isEnabled = self.photoVideoSwitch.isOn
        self.gestureView.leftEdgeGesture.isEnabled = !self.photoVideoSwitch.isOn
        
        print("Min ISO: \(self.minISO)")
        print("Max ISO: \(self.maxISO)")
        print("Min Shutter Speed: \(self.minShutterSpeed)")
        print("Max Shutter Speed: \(self.maxShutterSpeed)")
        
        self.updateAvailableISOs()
        self.updateAvailableShutterSpeeds()
        
        self.isoPicker.selectItem(0, animated: true)
        self.shutterPicker.selectItem(0, animated: true)

        if self.photoVideoSwitch.isOn {
            self.isoPicker.highlightedTextColor = .fllscrnPurple()
            self.shutterPicker.highlightedTextColor = .fllscrnPurple()
            
            self.isoLabel.textColor = .fllscrnPurple()
            self.shutterLabel.textColor = .fllscrnPurple()
        }
        else {
            self.isoPicker.highlightedTextColor = .fllscrnGreen()
            self.shutterPicker.highlightedTextColor = .fllscrnGreen()
            
            self.isoLabel.textColor = .fllscrnGreen()
            self.shutterLabel.textColor = .fllscrnGreen()
        }
        
        self.isoPicker.reloadData()
        self.shutterPicker.reloadData()
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
                
                self.thumbnail = self.fsPhotoAlbum.generateThumbnailFrom(filePath: outputFileURL)
                
                self.animate(thumbnail: self.thumbnail)
            }
        }
        
        self.videoTimer.invalidate()
        self.isRecording = false
        self.videoDuration = 0
        self.gestureView.videoDurationLabel.text = "0s"
        self.gestureView.videoZoomLabel.text = "1.0x"
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        if isRecording == true && hasCapturedOne == false {
            
            guard let resultUIImage = self.imageFromSampleBuffer(sampleBuffer) else {
                print("Couldn't unwrap resulting UIImage from sample buffer.")
                return
            }
            
            let square = self.fsPhotoAlbum.cropToBounds(image: resultUIImage, size: kCThumbnailSize)

            self.hasCapturedOne = true
            
            self.fsPhotoAlbum.saveImage(image: square, metadata: nil, completion: { (isComplete, error) in
                
                if let error = error { print(error.localizedDescription) }
                else if isComplete {
                    
                    print("Saved photo.")
                    self.hasCapturedOne = false
                    self.animate(thumbnail: square)
                }
            })
        }
    }
    
    func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            
            CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            print("Image Buffer Width: \(width) & Height: \(height)")
            
            guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8,bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
                print("Couldn't create context for image.")
                return nil
            }

            let quartzImage = context.makeImage()
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            
            if let quartzImage = quartzImage {
                let image = UIImage(cgImage: quartzImage)
                return image
            }
        }
        return nil
    }
}

extension GestureCameraViewController : AVCapturePhotoCaptureDelegate {

    func capture(_ captureOutput: AVCapturePhotoOutput, willBeginCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("will begin CaptureForResolvedSettings")
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("will capture PhotoForResolvedSettings")
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("did capture PhotoForResolvedSettings")
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("Error in capturing output. \(error.localizedDescription)")
            self.photoCapture = false
            return
        }
        
        print("did finish ProcessPhotoSampleBuffer")
        
        guard let photoSampleBuffer = photoSampleBuffer, let resultUIImage = self.imageFromSampleBuffer(photoSampleBuffer) else {
            print("Couldn't unwrap resulting UIImage from sample buffer.")
            self.photoCapture = false
            return
        }
        
        self.photoCapture = false
        
        self.fsPhotoAlbum.saveImage(image: resultUIImage, metadata: nil, completion: { (isComplete, error) in
            
            if let error = error { print(error.localizedDescription) }
            else if isComplete {
                
                print("Saved photo.")
                let thumbnail = self.fsPhotoAlbum.cropToBounds(image: resultUIImage, size: kCThumbnailSize)
                self.animate(thumbnail: thumbnail)
            }
        })
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        print("did finish CaptureForResolvedSettings")
        print("Settings: \(resolvedSettings)")
    }
}


// Image and Video Recording Functions 

extension GestureCameraViewController : UIGestureRecognizerDelegate {

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
    
    func startTimer() {
        self.videoTimer = Timer(timeInterval: kCTimeInterval, target: self, selector: #selector(updateVideoLabels), userInfo: nil, repeats: true)
        RunLoop.current.add(self.videoTimer, forMode: .defaultRunLoopMode)
    }
    
    func updateVideoLabels() {
        self.videoDuration += Int(kCTimeInterval)
        self.gestureView.videoDurationLabel.text = "\(self.videoDuration)s"
    }
    
//    func updateAlpha(to percent: CGFloat) {
//        self.leftShapeLayer.fillColor = UIColor.fllscrnGreen(alpha: max(1 - percent, 0.6)).cgColor
//    }
    
    func lockFor(device: BezierGestureViewStyle) {
        
        if self.isLocked == false {
            
            do {
                try self.captureDevice.lockForConfiguration()
                self.isLocked = true
            }
            catch let error as NSError {
                print("Error locking device: \(error.localizedDescription))")
                return
            }
        }
        
        self.captureSession.beginConfiguration()
        
        switch device {
        case .photo:
//            print("Locking for photo.")
            self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
            
            self.captureSession.removeOutput(self.movieFileOutput)
            
            if self.captureSession.canAddOutput(self.outputData) {
                self.captureSession.addOutput(self.outputData)
                self.outputData.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
                print("Added photo output data.")
            }
            
        case .video:
//            print("Locking for video.")
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720
            
            self.captureSession.removeOutput(self.outputData)
            
            if self.captureSession.canAddOutput(self.movieFileOutput) {
                self.captureSession.addOutput(self.movieFileOutput)
                self.movieFileOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
                print("Added movie file output.")
            }
        }
        
        self.captureSession.commitConfiguration()
    }

    // zoom to percent of total zoom capable for device.
    fileprivate func zoom(to zoomFactor: CGFloat, withRate rate: Float) {
        
        let zoomScale = zoomFactor/self.height
        let zoom : CGFloat
        
        if abs(zoomScale) > 0.035 {
            zoom = min(self.maxZoom, max(1, 1 - 10 * zoomScale))
        }
        else {
            zoom = 1.0
        }
        
        self.captureDevice.ramp(toVideoZoomFactor: zoom, withRate: rate)
    }
    
    func imageViewTapped() {
        if let parentVC = self.parent as? MainPageViewController {
            parentVC.navigateTo(fsViewController: .photos, direction: .forward)
        }
    }
}

// Animations
extension GestureCameraViewController {
    
    /*
     *  Dispatched on the main queue asynchronously
     */
    func animate(thumbnail: UIImage?) {
        
        DispatchQueue.main.async {
            
            self.animatedImageView.image = thumbnail
            let albumViewOrigin = CGPoint(x: self.fsAlbumImageView.frame.midX, y: self.fsAlbumImageView.frame.midY)
            self.animatedImageView.frame = CGRect(origin: albumViewOrigin, size: CGSize.zero)
            self.animatedImageView.contentMode = .scaleAspectFill
            
            self.view.addSubview(self.animatedImageView)
            
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                
                self.animatedImageView.frame = self.fsAlbumImageView.frame
                
            }) { (isCompleted) in
                
                self.fsAlbumImageView.image = thumbnail
                self.animatedImageView.removeFromSuperview()
            }
        }
    }
}

extension GestureCameraViewController : BezierGestureViewDelegate {
    
    func gestureViewTarget(gesture: UIScreenEdgePanGestureRecognizer, baseWidth : CGFloat) {
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            
            if gesture == self.gestureView.leftEdgeGesture {
                
                // call video end functions
                self.videoGestureFinished()
            }
            else {
                
                // call photo end functions
                self.photoGestureFinished()
            }
        }
        else {
            
            if gesture == self.gestureView.leftEdgeGesture {
                
                // call video start functions
                self.videoGesture(gesture: gesture, baseWidth: baseWidth)
            }
            else {
                
                // call photo start functions
                self.photoGesture(gesture: gesture, baseWidth: baseWidth)
            }
        }
    }
    
    func videoGestureFinished() {
        
        if self.isRecording { self.movieFileOutput.stopRecording() }
        
        self.zoom(to: 1.0, withRate: kCResetZoomRate)
//        self.captureDevice.unlockForConfiguration()
//        self.isLocked = false
    }
    
    func videoGesture(gesture: UIScreenEdgePanGestureRecognizer, baseWidth : CGFloat) {
        
//        self.lockFor(device: .video)
        
        if baseWidth == kCMaxBaseWidth && !self.isRecording {
//            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720
            _ = self.recordVideoToFile()
            self.isRecording = true
        }
        
        let zoomFactor = gesture.translation(in: view).y
        self.zoom(to: zoomFactor, withRate: kCDefaultZoomRate)
        self.gestureView.videoZoomLabel.text = "\(self.zoomText)x"
    }
    
    func photoGestureFinished() {
        self.zoom(to: 1.0, withRate: kCResetZoomRate)
//        self.captureDevice.unlockForConfiguration()
//        self.isLocked = false
        self.isRecording = false
        self.hasCapturedOne = false
    }
    
    func photoGesture(gesture: UIScreenEdgePanGestureRecognizer, baseWidth: CGFloat) {

//        self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
//
//        self.lockFor(device: .photo)
        
        if baseWidth == kCMaxBaseWidth && self.isRecording == false {
            // begin taking photos
            self.isRecording = true
        }
        else if baseWidth < kCMaxBaseWidth {
            self.isRecording = false
            let zoomFactor = gesture.translation(in: view).y
            self.zoom(to: zoomFactor, withRate: kCDefaultZoomRate)
            self.gestureView.photoZoomLabel.text = "\(self.zoomText)x"
        }
        
//        if baseWidth == kCMaxBaseWidth && self.photoCapture == false {
//            let previewFormat = [(kCVPixelBufferPixelFormatTypeKey as String)
//                                : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
//            let photoCaptureSettings = AVCapturePhotoSettings(format: previewFormat)
//            
//            self.photoOutputData.capturePhoto(with: photoCaptureSettings, delegate: self)
//            self.photoCapture = true
//        }
    }
}

extension GestureCameraViewController : AKPickerViewDelegate, AKPickerViewDataSource {
    
    func updateAvailableISOs() {
        
        let roundedMinISO = 50.0 * ceil((self.minISO / 50.0))
        let roundedMaxISO = 50.0 * floor((self.maxISO / 50.0))
        let sections = (roundedMaxISO - roundedMinISO) / 100
        var isoArray : [Float] = []
        var i : Float = 0.0
        
        while i <= sections {
            isoArray.append(roundedMinISO + 100*i)
            i += 1
        }
        self.isoRange = isoArray
    }
    
    func updateAvailableShutterSpeeds() {

        let minTimeScale : CMTimeScale = CMTimeScale(ceil(1.0/self.minShutterSpeed.seconds))
        print("Min time scale: \(minTimeScale)")
        
        var shutterArray : [CMTime] = []
        let one : CMTimeValue = 1
        
        var timeScale : CMTimeScale = minTimeScale
        
        while timeScale >= self.maxShutterSpeed.timescale {
            
            if timeScale % 2 != 0 {
                timeScale = Int32(5.0 * ceil((Double(timeScale) / 5.0)))
            }
//            else if timeScale <= 10 {
//                timeScale = Int32(2.0 * ceil(Double(timeScale) / 2.0))
//            }
//            
            let shutterSpeed = CMTime(value: one, timescale: timeScale)
            shutterArray.append(shutterSpeed)
            timeScale /= 2
        }
        
        self.shutterRange = shutterArray
    }
    
    func setupISOPicker() {
        
        self.isoLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.isoLabel)
        
        self.isoLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: labelWidthMultiple).isActive = true
        self.isoLabel.heightAnchor.constraint(equalToConstant: kCBottomBarHeight / 2).isActive = true
        self.isoLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.isoLabel.bottomAnchor.constraint(equalTo: self.fsAlbumImageView.topAnchor).isActive = true
        
        self.isoLabel.text = "ISO"
        self.isoLabel.font = UIFont.fllscrnFontBold(16.0)
        self.isoLabel.textAlignment = .center
        self.isoLabel.textColor = self.photoVideoSwitch.isOn
                           ? .fllscrnPurple() : .fllscrnGreen()
        
        self.isoPicker.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.isoPicker)
        
        self.isoPicker.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.isoPicker.heightAnchor.constraint(equalTo: self.isoLabel.heightAnchor).isActive = true
        self.isoPicker.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: pickerWidthMultiple).isActive = true
        self.isoPicker.bottomAnchor.constraint(equalTo: self.isoLabel.bottomAnchor).isActive = true
        
        self.isoPicker.delegate = self
        self.isoPicker.dataSource = self
        self.isoPicker.font = UIFont.fllscrnFont(14.0)
        self.isoPicker.pickerViewStyle = .wheel
        self.isoPicker.textColor = UIColor.white
        self.isoPicker.highlightedTextColor = self.photoVideoSwitch.isOn
                                            ? .fllscrnPurple() : .fllscrnGreen()
        self.isoPicker.interitemSpacing = 15.0
        self.isoPicker.maskDisabled = false
        self.isoPicker.reloadData()
        
        self.isoPicker.isHidden = true
    }
    
    func setupShutterSpeedPicker() {
        
        self.shutterLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.shutterLabel)
        
        self.shutterLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: labelWidthMultiple).isActive = true
        self.shutterLabel.heightAnchor.constraint(equalToConstant: kCBottomBarHeight / 2).isActive = true
        self.shutterLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.shutterLabel.bottomAnchor.constraint(equalTo: self.isoPicker.topAnchor).isActive = true
        
        self.shutterLabel.text = "Tv"
        self.shutterLabel.font = UIFont.fllscrnFontBold(16.0)
        self.shutterLabel.textAlignment = .center
        self.shutterLabel.textColor = self.photoVideoSwitch.isOn
                               ? .fllscrnPurple() : .fllscrnGreen()
        
        self.shutterPicker.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.shutterPicker)
        
        self.shutterPicker.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.shutterPicker.heightAnchor.constraint(equalTo: self.shutterLabel.heightAnchor).isActive = true
        self.shutterPicker.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: pickerWidthMultiple).isActive = true
        self.shutterPicker.bottomAnchor.constraint(equalTo: self.shutterLabel.bottomAnchor).isActive = true
        
        self.shutterPicker.delegate = self
        self.shutterPicker.dataSource = self
        self.shutterPicker.font = UIFont.fllscrnFont(14.0)
        self.shutterPicker.pickerViewStyle = .wheel
        self.shutterPicker.textColor = UIColor.white
        self.shutterPicker.highlightedTextColor = self.photoVideoSwitch.isOn
                                                ? .fllscrnPurple() : .fllscrnGreen()
        self.shutterPicker.interitemSpacing = 10.0
        self.shutterPicker.maskDisabled = false
        self.shutterPicker.reloadData()
        
        self.shutterPicker.isHidden = true
        
        let sliderRect = CGRect(x: 0, y: self.view.frame.midY * 1.5 - 2*statusBarHeight, width: self.width/2, height: self.width/2)
        
        let options : [CircleSliderOption] = [
            CircleSliderOption.barColor(.lightGray),
            CircleSliderOption.thumbColor(.darkGray),
            CircleSliderOption.trackingColor(.fllscrnGreen()),
            CircleSliderOption.thumbImage(sliderImg),
            CircleSliderOption.thumbWidth(10),
            CircleSliderOption.barWidth(10),
            CircleSliderOption.startAngle(0),
            CircleSliderOption.maxValue(150),
            CircleSliderOption.minValue(0)
        ]
        
        let circleSlider = CircleSlider(frame: sliderRect, options: options)
        circleSlider.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        self.view.addSubview(circleSlider)
    }
    
    func valueChanged(sender : CircleSlider) {
        print("Value: \(sender.value)")
    }
    
    func numberOfItemsInPickerView(_ pickerView: AKPickerView) -> Int {
        return pickerView == self.isoPicker ? isoRange.count : shutterRange.count
    }
    
    func pickerView(_ pickerView: AKPickerView, titleForItem item: Int) -> String {
        
        if pickerView == self.isoPicker {
            return "\(Int(self.isoRange[item]))"
        }
        else {
            let shutterSpeed = self.shutterRange[item]
            return "\(Int(shutterSpeed.value)) / \(shutterSpeed.timescale)"
        }
    }
    
    func pickerView(_ pickerView: AKPickerView, didSelectItem item: Int) {
        
        let shutterSpeed : CMTime = self.shutterRange[self.shutterPicker.selectedItem]
        let iso          : Float = self.isoRange[self.isoPicker.selectedItem]
        
        self.captureDevice.setExposureModeCustomWithDuration(shutterSpeed, iso: iso, completionHandler: { (time) -> Void in
            
            print("Set shutter speed: \(Int(shutterSpeed.value)) / \(shutterSpeed.timescale)\nISO: \(iso)")
        })
    }
}
