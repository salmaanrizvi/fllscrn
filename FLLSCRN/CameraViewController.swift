//
//  CameraViewController.swift
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/14/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit
import Foundation
import CoreMedia
import AVFoundation
import AssetsLibrary
import MediaPlayer
import CoreAudio
import CoreFoundation
import MobileCoreServices
import AVKit
import KCFloatingActionButton
import SCLAlertView
import FontAwesome_swift
import IQKeyboardManagerSwift

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate {

    
    // Video Camera Capturing properties
    var captureSession: AVCaptureSession?
    var videoCaptureDevice: AVCaptureDevice?
    var videoInputDevice: AVCaptureDeviceInput?
    
    var backCameraDevice : AVCaptureDevice?
    var frontCameraDevice : AVCaptureDevice?
    
    var frontCamera : AVCaptureInput?
    var backCamera : AVCaptureInput?
    
    // Videa saving and displaying properties
    var videoOutputData : AVCaptureVideoDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var totalSeconds: CGFloat = 10.00
    var framesPerSecond:Int32 = 30
    var maxDuration: CMTime?
    
    var audioCaptureDevice: AVCaptureDevice?
    var audioInputDevice: AVCaptureDeviceInput?
    
    var movieFileOutput: AVCaptureMovieFileOutput?
    var outputPath = NSTemporaryDirectory() as String
    
    var videoPlayer : AVPlayer = AVPlayer()
    var avPlayerLayer : AVPlayerLayer?

    var hasFrontCamera = false
    var hasBackCamera = false
    
    var needsMerge : Bool = false
    var mergedURL : URL?
    var compressedURL : URL?
    var videoAssets = [AVAsset]()
    var assetURLs = [String]()
    var progressBarTimer: Timer?
    var incInterval: CGFloat = 0.05
    var isCurrentlyRecording = false

    var appendix: Int32 = 1
    var totalTimeElapsed : CGFloat = 0.0
    
    var deal : Deal?
    var hasDeal : Bool = false
    var hasText = false
    var closeButtonState : ButtonState = .exit
    
    // IBOutlets and view related properties
//    @IBOutlet var cameraView: UIView!
//    @IBOutlet var toggleCameraSwitch: UIButton!
//    @IBOutlet var recordButton: UIButton!
//    @IBOutlet var closeButton: UIButton!
//    @IBOutlet var flashButton: UIButton!
//    @IBOutlet var contextField: UITextField!
    var buttonCollection : KCFloatingActionButton!
    var progressBarLayer : CAShapeLayer?
    var progressBarPath : UIBezierPath?
    var textInputFieldCenterYConstraint : NSLayoutConstraint?
    var textInputFieldConstraintToKeyboard : NSLayoutConstraint?
    var textInputFieldConstraintToRecordButton : NSLayoutConstraint?
    let keyboardAnimationTime : TimeInterval = 0.15
    var focusSquare : CameraFocusSquare?
    
    lazy var cameraView : UIView = UIView()
    let recordBtn = UIButton(type: .custom)
    let closeBtn = UIButton(type: .custom)
    let flashBtn = UIButton(type: .custom)
    let toggleCameraBtn = UIButton(type: .custom)
    var textInputField : UITextField!
    lazy var backBtn = UIButton(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        self.layoutViews()
        self.loadVideoCamera()
        self.addAudioInputs()
        self.addVideoCameraPreviewLayer()
        self.addProgressBarLayer()
        self.setupTapGesture()
        self.captureSession?.startRunning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
        IQKeyboardManager.sharedManager().enable = false
    }
    
    override var shouldAutorotate : Bool { return false }
    
    override var prefersStatusBarHidden : Bool { return true }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTapGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action:#selector(toggleCameraTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false
        doubleTap.delegate = self
        self.view.addGestureRecognizer(doubleTap)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

/*
 * AVFoundation protocols (add audio / video) / record video button
 * Display / implememt video recording progress bar
 */
extension CameraViewController: AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBAction func recordButtonTapped(_ recognizer : UILongPressGestureRecognizer) {
            
        if recognizer.state == UIGestureRecognizerState.began {
            
            self.closeBtn.setImage(trashIcon, for: .normal)
            self.closeButtonState = .trash
            self.closeBtn.isHidden = false
            
            if(self.totalTimeElapsed < 10.0) { // if total time hasn't elapsed
                
                self.recordBtn.showsTouchWhenHighlighted = true
                let outputFilePath = self.recordVideoToFile()

                print("Recording to file: \(outputFilePath) ")
                self.isCurrentlyRecording = true
                self.needsMerge = true
                print("Need to merge.")
           }
            
        } else if recognizer.state == UIGestureRecognizerState.ended {

            if self.isCurrentlyRecording {
                //print("Button stopped recording state: \(self.recordButton.state)")
                print("Button stopped recording state: \(self.recordBtn.state)")
                progressBarTimer?.invalidate()
                movieFileOutput?.stopRecording()
                self.isCurrentlyRecording = false
            }
        }
    }
    
    fileprivate func recordVideoToFile() -> URL {
        
        let outputFilePath = self.outputPath + "output-\(self.appendix).mp4"
        self.appendix += 1
        let outputURL = URL(fileURLWithPath: outputFilePath)
        let fileManager = FileManager.default
        
        if(fileManager.fileExists(atPath: outputFilePath)) {
            
            do { try fileManager.removeItem(atPath: outputFilePath) }
            catch _ { }
        }
        movieFileOutput?.startRecording(toOutputFileURL: outputURL, recordingDelegate: self)
        
        return outputURL
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if videoPlayer.rate == 1 {
            print("Video is playing, touches shouldn't do anything")
            return
        }
        
        var xPos : CGFloat = 0
        var yPos : CGFloat = 0
        
        if let focusLocation = touches.first?.location(in: self.cameraView) {
            xPos = focusLocation.x
            yPos = focusLocation.y
        }
        
        let focusPoint = CGPoint(x: xPos, y: yPos)
        
        let point = self.previewLayer?.captureDevicePointOfInterest(for: focusPoint)
        
        // if focus is available for camera, animate
        if focusAtPoint(point!) { animateFocusAtPoint(focusPoint) }
        
    }
    
    func focusAtPoint(_ touchPoint : CGPoint) -> Bool {
        
        if let videoCD = self.videoCaptureDevice {
        
            if videoCD.position == .front { return false } // can't focus front camera.
            
            do {
                try videoCD.lockForConfiguration()
                
                if videoCD.isFocusPointOfInterestSupported {
                    videoCD.focusPointOfInterest = touchPoint
                    videoCD.focusMode = .autoFocus
                }
                if videoCD.isExposurePointOfInterestSupported { videoCD.exposurePointOfInterest = touchPoint }
                
                print("ISO: \(videoCD.iso)")
            }
            catch let error as NSError {
                print("Couldn't lock device for configuration to focus on touched location.")
                print(error)
            }
            videoCD.unlockForConfiguration()
        }
        
        return true
    }
    
    func animateFocusAtPoint(_ touchPoint : CGPoint) {
        
        if let fsquare = self.focusSquare {
            fsquare.updatePoint(touchPoint)
        }
        else {
            self.focusSquare = CameraFocusSquare(touchPoint: touchPoint)
            self.cameraView.addSubview(focusSquare!)
            focusSquare?.setNeedsDisplay()
        }
        
        focusSquare?.animateFocusingAction()
    }
    
    func loadVideoCamera() {
    
        self.captureSession = AVCaptureSession()
        self.captureSession?.automaticallyConfiguresApplicationAudioSession = false
        self.captureSession?.sessionPreset = AVCaptureSessionPresetHigh
        
        self.videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        print("Number of devices available: \(AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).count)")
        
        for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice] {
            if device.position == .back {
                self.hasBackCamera = true
                self.backCameraDevice = device
            }
            else if device.position == .front {
                self.hasFrontCamera = true
                self.frontCameraDevice = device
            }
        }
        
        do {
            self.videoInputDevice = try AVCaptureDeviceInput(device: self.videoCaptureDevice)
            self.captureSession?.addInput(self.videoInputDevice)
            
            self.movieFileOutput = AVCaptureMovieFileOutput()
            self.maxDuration = CMTimeMakeWithSeconds(Float64(totalSeconds), framesPerSecond)
            self.movieFileOutput?.maxRecordedDuration = maxDuration!
            
            self.captureSession?.addOutput(movieFileOutput)
            
            if let connection = self.movieFileOutput?.connection(withMediaType: AVMediaTypeVideo) {
                connection.videoOrientation = .portrait
            }
            
            self.captureSession?.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.manestream.business.videoCapture", attributes: [])
            self.videoOutputData?.setSampleBufferDelegate(self, queue: queue)
        }
        catch let error as NSError {
            print("\(error), \(error.localizedDescription)")
        }
        
        let recognizer = UILongPressGestureRecognizer(target: self, action:#selector(recordButtonTapped(_:)))
        recognizer.minimumPressDuration = 0.25
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        self.recordBtn.addGestureRecognizer(recognizer)
    }

    func addAudioInputs() {
        
        audioCaptureDevice = AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio)[0] as? AVCaptureDevice
        audioInputDevice =  try? AVCaptureDeviceInput(device: audioCaptureDevice)
        captureSession?.addInput(audioInputDevice)
        print("audio device is \(audioCaptureDevice!.description)")
        print("has audio \(self.captureSession?.usesApplicationAudioSession)")
    }
    
    fileprivate func addVideoCameraPreviewLayer() {
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        self.previewLayer?.frame = self.cameraView.frame
        self.previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(self.previewLayer!)
        
        self.view.sendSubview(toBack: self.cameraView)
        self.bringSubviewsToFront()
    }
    
    fileprivate func bringSubviewsToFront() {
        self.view.bringSubview(toFront: self.buttonCollection)
        self.view.bringSubview(toFront: self.recordBtn)
        self.view.bringSubview(toFront: self.flashBtn)
        self.view.bringSubview(toFront: self.closeBtn)
        self.view.bringSubview(toFront: self.backBtn)
        self.view.bringSubview(toFront: self.toggleCameraBtn)
        self.view.bringSubview(toFront: self.textInputField)
    }
    
    fileprivate func addProgressBarLayer() {
        
        self.progressBarPath = UIBezierPath()
        self.progressBarPath?.move(to: CGPoint(x: 0, y: self.view.bounds.height))
        self.progressBarPath?.addLine(to: CGPoint(x: self.view.bounds.width, y: self.view.bounds.height))
        
        self.progressBarLayer = CAShapeLayer()
        self.progressBarLayer?.path = self.progressBarPath?.cgPath
        self.progressBarLayer?.lineWidth = 10.0
        self.progressBarLayer?.strokeColor = UIColor.fllscrnGreen().cgColor
        self.progressBarLayer?.fillColor = UIColor.clear.cgColor
        self.progressBarLayer?.actions = ["strokeStart" : NSNull(), "strokeEnd" : NSNull()]
        self.progressBarLayer?.strokeEnd = 0
        self.view.layer.addSublayer(self.progressBarLayer!)
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
        print("Capturing output. Starting progress bar timer.")
        startProgressBarTimer()
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        if let error = error {
            if (error as NSError).code == AVError.Code.diskFull.rawValue {
                let alert = Constants.displayAlert("Disk full", message: "Free up space on your phone before recording videos.")
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        let asset : AVURLAsset = AVURLAsset(url: outputFileURL, options: nil)
        print("Segment finished recording. Video asset is \(asset)")
        videoAssets.append(asset)
        assetURLs.append(outputFileURL.path)
        
        if self.totalTimeElapsed >= self.totalSeconds {
            self.playButtonTapped()
            self.isCurrentlyRecording = false
        }
    }
    
    func startProgressBarTimer() {
        self.progressBarTimer = Timer(timeInterval: TimeInterval(self.incInterval), target: self, selector: #selector(updateProgressBar), userInfo: nil, repeats: true)
        RunLoop.current.add(self.progressBarTimer!, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func updateProgressBar() {
        
        if self.totalTimeElapsed >= self.totalSeconds {
            self.movieFileOutput?.stopRecording()
            print("10 seconds up. Video recording stopped.")
            progressBarTimer?.invalidate()
        }
        else {
            self.totalTimeElapsed = self.totalTimeElapsed + self.incInterval
            self.progressBarLayer?.strokeStart = 0
            self.progressBarLayer?.strokeEnd = totalTimeElapsed / self.totalSeconds
        }
    }
}

/*
 * Camera button actions / merge video / play video recorded
 */

extension CameraViewController {
    
    func playButtonTapped() {
        
        if self.totalTimeElapsed > 0 { // only if there is something to play
            
            self.turnOffFlash()
            
            if self.needsMerge { // if needs to merge, merge the video
                self.mergeVideos({
                    
                    self.playVideoWithURL(self.mergedURL!)
                    self.checkButton(atPosition: 2)
                    
                })
            }
            else if let mergedURL = self.mergedURL { // if already merged, just play that video
                self.playVideoWithURL(mergedURL)
            }
            else {
                print("Couldn't unwrap mergedURL or was nil. Force merging.")
                self.mergeVideos( {
                    self.playVideoWithURL(self.mergedURL!)
                    self.checkButton(atPosition: 2)
                })
            }
        }
    }
    
    fileprivate func compressVideo(_ url : URL, completion: @escaping (Bool)->()) {
        
        if let mergedURL = self.mergedURL {
            let asset = AVAsset(url: mergedURL)
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
                    print("Couldn't establish exporter")
                    return
            }
            
            let mergedURLPath = mergedURL.path.replacingOccurrences(of: ".mp4", with: "-compressed.mp4")
            
            let saveURL = URL(fileURLWithPath: mergedURLPath)
            
            exportSession.outputURL = saveURL
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.outputFileType = AVFileTypeMPEG4
            
            exportSession.exportAsynchronously(completionHandler: {
                DispatchQueue.main.async(execute: { 
                    print("Completed compressing video.")
                    print("Merged to: \(exportSession.outputURL!.absoluteString)")
                    self.compressedURL = exportSession.outputURL
                    
                    switch exportSession.status {
                    case .completed:
                        let data = try? Data(contentsOf: self.compressedURL!)
                        print("File size after compressing to medium: \(Double(data!.count / 1048576)) mb")
                    case .failed:
                        if let error = exportSession.error {
                            print(error.localizedDescription)
                        }
                    case .cancelled:
                        if let error = exportSession.error {
                            print(error.localizedDescription)
                        }
                    default: break
                    }
                    
                    completion(true)
                })
            })
        }
        else {
            // HANDLE NON MERGED VIDEO LATER
        }
        
    }
    
    fileprivate func mergeVideos(_ completion : @escaping () -> ()) {
        let composition = AVMutableComposition()

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        var startTime = kCMTimeZero
        
        for videoAsset in self.videoAssets {
            do {
                
                if let videoTrackofAsset = videoAsset.tracks(withMediaType: AVMediaTypeVideo).first {
                    
                    try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), of: videoTrackofAsset, at: startTime)
                    
                    compositionVideoTrack.preferredTransform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
                }
                
            }
            catch { print("Could not insert video track: \(videoAsset)") }
            
            do {
                if let audioTrackOfAsset = videoAsset.tracks(withMediaType: AVMediaTypeAudio).first {
                    try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), of: audioTrackOfAsset, at: startTime)
                }
            }
            catch { print("Could not insert audio track: \(videoAsset) ") }
            
            startTime = CMTimeAdd(startTime, videoAsset.duration)
        }
        
        compositionVideoTrack.preferredTransform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
        
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let date = Constants.dateFormatter().string(from: Date())
        
        var formattedDate = date.replacingOccurrences(of: "/", with: "_")
        formattedDate = formattedDate.replacingOccurrences(of: ", ", with: "-")
        formattedDate = formattedDate.replacingOccurrences(of: ":", with: "_")
        
        print("Date from date formatter: \(formattedDate)")
        
        let savePath = "\(directory)/merged-video-\(formattedDate).mp4"
        let saveURL = URL(fileURLWithPath: savePath)
        
        print("Save path: \(savePath)")
        
        if let videoExporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
            
            videoExporter.outputURL = saveURL
            videoExporter.shouldOptimizeForNetworkUse = true
            videoExporter.outputFileType = AVFileTypeMPEG4
            
            videoExporter.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(Float64(startTime.seconds), self.framesPerSecond))
            
            videoExporter.exportAsynchronously(completionHandler: {
                DispatchQueue.main.async(execute: { () -> Void in
                    print("Save URL: \(saveURL)")
                    print("NO need to merge.")
                    self.needsMerge = false
                    self.mergedURL = saveURL
                    
                    switch videoExporter.status {
                    case .completed:
                        let data = try? Data(contentsOf: self.mergedURL!)
                        print("File size after Highest quality merge: \(Double(data!.count / 1048576)) mb")
                    case .failed:
                        break
                    case .cancelled:
                        break
                    default: break
                    }
                    
                    completion()
                })
            })
        }
    }
    
    fileprivate func playVideoWithURL(_ url : URL) {
        print("Playing button with URL")
        
        let avPlayerItem = AVPlayerItem(url: url)
        self.videoPlayer = AVPlayer(playerItem: avPlayerItem)
        self.avPlayerLayer = AVPlayerLayer(player: self.videoPlayer)
        
        if let avPlayerLayer = self.avPlayerLayer {
            
            //avPlayerLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI_2)))
            avPlayerLayer.frame = self.view.frame
            
            self.view.layer.addSublayer(avPlayerLayer)
            self.view.bringSubview(toFront: self.textInputField)
            
            self.closeButtonState = .back
            self.closeBtn.setImage(leftBackIcon, for: .normal)
            self.closeBtn.isHidden = true
//            self.backBtn.hidden = false
            self.view.bringSubview(toFront: self.backBtn)
            self.view.bringSubview(toFront: self.closeBtn)
            self.view.bringSubview(toFront: self.buttonCollection)
            if self.hasDeal { self.view.bringSubview(toFront: self.deal!) }
            
            avPlayerLayer.backgroundColor = UIColor.clear.cgColor
        }
        
        self.videoPlayer.seek(to: kCMTimeZero)
        self.videoPlayer.play()
        
        self.videoPlayer.actionAtItemEnd = .none;
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer.currentItem)
    }
    
    func playerItemDidReachEnd(_ notification : Notification) {
        let item = notification.object as! AVPlayerItem
        item.seek(to: kCMTimeZero)
    }
    
    @IBAction func toggleCameraTapped(_ sender: UIButton) {
        
        // was recording before switching camera, stop recording.
        if self.isCurrentlyRecording {
            self.movieFileOutput?.stopRecording()
            self.progressBarTimer?.invalidate()
        }
        
        // first assign new video AVCapture devices for front and back cameras
        if let validFrontVideoDevice = self.frontCameraDevice {
            do {
                try self.frontCamera = AVCaptureDeviceInput(device: validFrontVideoDevice)
                print("Front camera: \(self.frontCamera)")
            } catch { print("Not valid front video device.") }
        }
        
        if let validBackVideoDevice = self.backCameraDevice {
            do {
                try self.backCamera = AVCaptureDeviceInput(device: validBackVideoDevice)
                print("Back camera: \(self.backCamera)")
            } catch { print("Not valid back video device.") }
        }
        
        // Unwrap current capture sesssion
        if let captureSession = self.captureSession {
            
            captureSession.beginConfiguration()
            
            // Removes ALL input devices from the current capture session, both audio and video
            for input in captureSession.inputs as! [AVCaptureInput] {
                
                let inputPort = input.ports[0] as! AVCaptureInputPort
                
                if inputPort.mediaType! == AVMediaTypeVideo {
                    captureSession.removeInput(input)
                }
            }
            
            let newCamera : AVCaptureDevice?
            
            // If current camera state is back device, switch to front
            if self.videoCaptureDevice?.position == .back {
                print("Setting camera to front")
                newCamera = self.frontCameraDevice
                
                if self.hasFrontCamera {
                    
                    if let validFrontDevice = self.frontCamera {
                        if captureSession.canAddInput(validFrontDevice) {
                            print("Adding valid front device")
                            captureSession.addInput(validFrontDevice)
//                            self.flashButton.hidden = true
                            self.flashBtn.isHidden = true
                        }
                    }
                }
            }
            else { // camera is facing front
                
                print("Setting camera to back")
                newCamera = self.backCameraDevice
                
                if let validBackDevice = self.backCamera {
                    if captureSession.canAddInput(validBackDevice) {
                        captureSession.addInput(validBackDevice)
                        print("Add valid back device.")
                        //self.flashButton.hidden = false
                        self.flashBtn.isHidden = false
                    }
                }
            }
            captureSession.commitConfiguration()
            self.videoCaptureDevice = newCamera
        }
        
        if self.isCurrentlyRecording { // was recording before switching camera, start recording again.
            self.recordVideoToFile()
        }
    }
    
    
    @IBAction func flashButtonTapped(_ sender: UIButton) {

        if let videoCaptureDevice = self.videoCaptureDevice {
            
            if videoCaptureDevice.hasTorch {
                do {
                    try videoCaptureDevice.lockForConfiguration()
                    if videoCaptureDevice.torchMode == .on {
                        videoCaptureDevice.torchMode = .off
                        self.flashBtn.setImage(flashOffIcon, for: .normal)
                    }
                    else {
                        do {
                            try videoCaptureDevice.setTorchModeOnWithLevel(1.0)
                            self.flashBtn.setImage(flashOnIcon, for: .normal)
                        }
                        catch { print("Could not set torch mode on with level 1.0") }
                    }
                    videoCaptureDevice.unlockForConfiguration()
                }
                catch {
                    print("Could not unlock for configuration.")
                }
            }
        }
    }

    @IBAction func closeTrashButtonTapped(_ sender: UIButton) {
        
        // Trash the current video files and reset.
        if self.closeButtonState == .trash {
            
            self.videoAssets.removeAll()
            self.mergedURL = nil
            
            let fileManager = FileManager()
            
            for path in assetURLs {
                do {
                    try fileManager.removeItem(atPath: path)
                    print("Removed file at path: \(path)")
                }
                catch { print("Could not remove item at path: \(path)") }
            }
            
            self.assetURLs.removeAll()
            self.progressBarTimer?.invalidate()
            self.totalTimeElapsed = 0.0
            self.closeBtn.setImage(closeIcon, for: .normal)
            self.closeButtonState = .exit
            self.closeBtn.isHidden = true
            self.appendix = 1
            self.progressBarLayer?.strokeEnd = 0
            
            if self.hasDeal {
                self.deal?.removeFromSuperview()
                self.hasDeal = false
                self.deal = nil
            }
            
            if self.hasText { // if has text, user wants to remove
                self.textInputField.isHidden = true
                self.textInputField.text = ""
                self.hasText = false
            }
            
        }
        
        self.checkButton(atPosition: 0)
        self.checkButton(atPosition: 1)
        self.checkButton(atPosition: 2)
    }
    
    
    func backButtonTapped(_ sender : AnyObject) {
        if closeButtonState == .back {
            self.pauseVideo()
        }
        else {
//            if let businessPageVC = self.parentViewController as? BusinessPageViewController {
//                businessPageVC.navigateToViewController(.BusinessProfileDisplay, direction: .Reverse)
//            }
        }
    }
    
    
    func pauseVideo() {
        if videoPlayer.rate == 1 {
            self.videoPlayer.pause()
            self.avPlayerLayer?.removeFromSuperlayer()
            self.checkButton(atPosition: 2)
            self.closeButtonState = .trash
            self.closeBtn.setImage(trashIcon, for: .normal)
//            self.backBtn.hidden = true
            self.closeBtn.isHidden = false
        }
        self.turnOffFlash()
    }
}

// private views helper methods

extension CameraViewController {

    fileprivate func layoutViews() {
        
        self.cameraView.backgroundColor = UIColor.clear
        
        self.view.addSubview(self.cameraView)
        self.cameraView.translatesAutoresizingMaskIntoConstraints = false
        self.cameraView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.cameraView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
        self.cameraView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.cameraView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        let cameraSwitchRatio : CGFloat = 33.0/30.0 // 33 pixels wide x 30 pixels tall
        
        // Record Button Programmatic Setup
        recordBtn.setImage(cameraRecordButtonImage, for: .normal)
        cameraView.addSubview(recordBtn)

        recordBtn.translatesAutoresizingMaskIntoConstraints = false
        recordBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        recordBtn.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -12.0).isActive = true
        recordBtn.widthAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: recordButtonSize).isActive = true
        recordBtn.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: recordButtonSize).isActive = true
        
        
        // Flash Button Programatic Setup
        flashBtn.setImage(flashOffIcon, for: .normal)
        flashBtn.layer.shadowColor = UIColor.black.cgColor
        flashBtn.layer.shadowRadius = 2;
        flashBtn.layer.shadowOpacity = 0.70;
        cameraView.addSubview(flashBtn)
        
        flashBtn.translatesAutoresizingMaskIntoConstraints = false
        flashBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        flashBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 12.0).isActive = true
        flashBtn.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.04).isActive = true
        flashBtn.widthAnchor.constraint(equalTo: self.flashBtn.heightAnchor, multiplier: 1.0).isActive = true
        
        flashBtn.addTarget(self, action: #selector(flashButtonTapped(_:)), for: .touchUpInside)
        
        
        // Close Button Programatic Setup
        closeBtn.setImage(closeIcon, for: .normal)
        closeBtn.layer.shadowColor = UIColor.black.cgColor
        closeBtn.layer.shadowRadius = 2;
        closeBtn.layer.shadowOpacity = 0.70;
        cameraView.addSubview(closeBtn)
        
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.centerYAnchor.constraint(equalTo: self.flashBtn.centerYAnchor).isActive = true
        closeBtn.leftAnchor.constraint(equalTo: self.cameraView.leftAnchor, constant: 10.0).isActive = true
        closeBtn.heightAnchor.constraint(equalTo: self.flashBtn.heightAnchor, multiplier: 1.1).isActive = true
        closeBtn.widthAnchor.constraint(equalTo: self.closeBtn.heightAnchor, multiplier: 1.0).isActive = true
        closeBtn.isHidden = true
        
        closeBtn.addTarget(self, action: #selector(closeTrashButtonTapped(_:)), for: .touchUpInside)
        
        
        // Back button on playing video
        backBtn.setImage(leftBackIcon, for: .normal)
        
        backBtn.layer.shadowColor = UIColor.black.cgColor
        backBtn.layer.shadowRadius = 2;
        backBtn.layer.shadowOpacity = 0.70;
        cameraView.addSubview(self.backBtn)
        
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.bottomAnchor.constraint(equalTo: self.cameraView.bottomAnchor, constant: -15).isActive = true
        backBtn.leadingAnchor.constraint(equalTo: self.cameraView.leadingAnchor, constant: 10.0).isActive = true
        backBtn.heightAnchor.constraint(equalTo: self.cameraView.heightAnchor, multiplier: 0.05).isActive = true
        backBtn.widthAnchor.constraint(equalTo: self.backBtn.heightAnchor, multiplier: 1.0).isActive = true
//        backBtn.hidden = false
        
        backBtn.addTarget(self, action: #selector(backButtonTapped(_:)), for: .touchUpInside)
        
        
        // Toggle Camera Programatic Setup
        toggleCameraBtn.setImage(toggleCameraIcon, for: .normal)
        toggleCameraBtn.layer.shadowColor = UIColor.black.cgColor
        toggleCameraBtn.layer.shadowRadius = 2;
        toggleCameraBtn.layer.shadowOpacity = 0.70;
        cameraView.addSubview(toggleCameraBtn)
        
        toggleCameraBtn.translatesAutoresizingMaskIntoConstraints = false
        toggleCameraBtn.centerYAnchor.constraint(equalTo: self.flashBtn.centerYAnchor).isActive = true
        toggleCameraBtn.rightAnchor.constraint(equalTo: self.cameraView.rightAnchor, constant: -10.0).isActive = true
        toggleCameraBtn.heightAnchor.constraint(equalTo: self.flashBtn.heightAnchor, multiplier: 1.1).isActive = true
        toggleCameraBtn.widthAnchor.constraint(equalTo: self.toggleCameraBtn.heightAnchor, multiplier: cameraSwitchRatio).isActive = true
       
        toggleCameraBtn.addTarget(self, action: #selector(toggleCameraTapped(_:)), for: .touchUpInside)
    
        self.setUpContextTextField()
        
        setupButtonCollection()
    }
    
    fileprivate func setupButtonCollection() {
        
        self.buttonCollection = KCFloatingActionButton(size: 55.0)
        
        self.buttonCollection.buttonColor = UIColor.fllscrnGreen()
        
        self.buttonCollection.plusColor = UIColor.white
        
        self.buttonCollection.addItem("Text", icon: blackTextIconSmall, handler: { _ in
            
            if self.hasText { // if has text, user wants to remove
                self.textInputField.isHidden = true
                self.textInputField.text = ""
                self.hasText = false
            } else {
                self.textInputField.becomeFirstResponder()
                self.hasText = true
            }
            self.checkButton(atPosition: 0)
        })
        
        self.buttonCollection.addItem("Deal", icon: blackGift, handler: { _ in
            
            var dealAlert : SCLAlertView
            
            if self.hasDeal {
                self.deal?.removeFromSuperview()
                self.hasDeal = false
            }
            else {
                
                dealAlert = self.setUpDeal()
                
                dealAlert.showCustom("Add a Deal!\n", subTitle: "\nIndicate the deal and the number that can be redeemed below.\n", color: UIColor.fllscrnGreen(), icon: whiteGift, closeButtonTitle: "Cancel", duration: 0.0, colorStyle: UIColor.fllscrnGreen().colorCode(), colorTextButton: UIColor.white.colorCode(), circleIconImage: whiteGift, animationStyle: .topToBottom)
            }
            self.checkButton(atPosition: 1)

        })
        
        self.buttonCollection.addItem("Play", icon: blackPlay, handler: { _ in
            
            if self.videoPlayer.rate == 0 {
                self.playButtonTapped()
            }

            self.checkButton(atPosition: 2)
            
        })
        
        self.buttonCollection.addItem("Publish", icon: blackSend, handler: { _ in
            
            let uploadAlert = SCLAlertView()

            if self.needsMerge {
                
                uploadAlert.showNotice("Uploading", subTitle: "Please wait.")
                
                self.mergeVideos({
                  
                    self.compressVideo(self.mergedURL!, completion: { (completed) in
                        
                        let date = Constants.dateFormatter().string(from: NSDate(timeIntervalSinceNow: 0) as Date)
                        
                        let text : String? = self.hasText ? self.textInputField.text! : nil
                        
                        let video = VideoAsset(withSavedPathURL: self.compressedURL!, deal: self.deal, text: text, dateCreated: date, roarCount: 0, viewCount: 0)
                        
//                        video.uploadVideo({ 
//                            self.pauseVideo()
//                            self.closeTrashButtonTapped(self.closeBtn)
//                            uploadAlert.hideView()
//                        })
                    })
        
                })
            }
            
            else if let url = self.mergedURL {
                
                uploadAlert.showNotice("Uploading", subTitle: "Please wait.")
                
                self.compressVideo(url, completion: { (completed) in
                    
                    let date = Constants.dateFormatter().string(from: NSDate(timeIntervalSinceNow: 0) as Date)
                    
                    let text : String? = self.hasText ? self.textInputField.text! : nil
                    
                    let video = VideoAsset(withSavedPathURL: self.compressedURL!, deal: self.deal, text: text, dateCreated: date, roarCount: 0, viewCount: 0)
                    
//                    video.uploadVideo({ 
//                        self.pauseVideo()
//                        self.closeTrashButtonTapped(self.closeBtn)
//                        uploadAlert.hideView()
//                    })
                })
            }
            
            self.checkButton(atPosition: 3)
            
        })
        
        self.view.addSubview(self.buttonCollection)
    }
    
    fileprivate func checkButton(atPosition position : Int) {
        
        if position >= self.buttonCollection.items.count || position < 0 {
            print("Not a valid button position. Index out of bounds.")
            return
        }
        
        let button = self.buttonCollection.items[position]
        
        switch button.title! {
        case "Text":
            print("setting text")
            if self.hasText { button.icon = orangeTextIcon }
            else { button.icon = blackTextIconSmall }
            
        case "Deal" :
            print("setting deal")
            if self.hasDeal { button.icon = redGift }
            else { button.icon = blackGift }
            
        case "Play" :
            print("setting play")
            if self.videoPlayer.rate > 0 { button.icon = redPlay }
            else { button.icon = blackPlay }
            
        case "Publish" :
            print("Nothing to check for publish icon.")
            
        default:
            print("default")
        }
        
    }

    fileprivate func setUpDeal() -> SCLAlertView {
        
        let appearance = SCLAlertView.SCLAppearance(kDefaultShadowOpacity: 0.7, kCircleTopPosition: -12.0, kCircleBackgroundTopPosition: -15.0, kCircleHeight: 56.0, kCircleIconHeight: 25.0, kTitleTop: 30.0, kTitleHeight: 25.0, kWindowWidth: 240.0, kWindowHeight: 178.0, kTextHeight: 90.0, kTextFieldHeight: 45.0, kTextViewdHeight: 80.0, kButtonHeight: 45.0, kTitleFont: UIFont.fllscrnFont(20), kTextFont: UIFont.fllscrnFont(14), kButtonFont: UIFont.fllscrnFont(16), showCloseButton: true, showCircularIcon: true, shouldAutoDismiss: true, contentViewCornerRadius: 5.0, fieldCornerRadius: 3.0, buttonCornerRadius: 3.0, hideWhenBackgroundViewIsTapped: false, contentViewColor: UIColor.white, contentViewBorderColor: UIColor.white, titleColor: UIColor.black)
        
/*       let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont.fllscrnFont(20),
            kTextFont: UIFont.fllscrnFont(14),
            kButtonFont: UIFont.fllscrnFont(16),
            showCloseButton: true,
            showCircularIcon : true,
            kCircleIconHeight : 25
        ) */
        
        let alert = SCLAlertView(appearance : appearance)
        
        let dealNameTextField = alert.addTextField("e.g. Buy One Drink Get One Free")
        
        let dealQuantityTextField = alert.addTextField(title: "e.g. 25", identifier: "", keyboardType: UIKeyboardType.numberPad)
        
        alert.addButton("Add!", action: {
            
            if Deal.checkDeal(dealNameTextField.text!, dealNumber: dealQuantityTextField.text!) {
                print("Deal saved!")
                
                let numberRedeemable = Int(dealQuantityTextField.text!)!
                
                self.deal = Deal(name: dealNameTextField.text!, numberRedeemable: numberRedeemable, numberRedeemed: 0, isUser: false, redeemedBy: [""])
                
                if let deal = self.deal {
                    self.cameraView.addSubview(deal)
                    
                    deal.frame.origin.x = self.toggleCameraBtn.frame.origin.x - 5
                    deal.frame.origin.y = self.toggleCameraBtn.frame.origin.y + self.toggleCameraBtn.frame.height + 50
                    
                    self.cameraView.bringSubview(toFront: deal)
//                    deal.pulseAnimation()
                }
                self.hasDeal = true
                print(self.deal!)
            }
            else {
                print("Not valid deal input.")
                
                SCLAlertView(appearance: appearance).showError("Invalid Input", subTitle: "\nTry again.")
                
            }
            self.checkButton(atPosition: 1)
        })
        
        return alert
    }
    
    fileprivate func turnOffFlash() {
    
        guard let videoCD = self.videoCaptureDevice else { return }
        
        if videoCD.torchMode == .on {
            do {
                try videoCD.lockForConfiguration()
                videoCD.torchMode = .off
                self.flashBtn.setImage(flashOffIcon, for: .normal)
                
            } catch let error as NSError {
                Constants.displayAlert("Error", message: error.localizedDescription)
                print("Error")
            }
        }
        
    }
}

/*
 * Context Text Field setup and implementation / animation
 */

extension CameraViewController : UITextFieldDelegate {
    
    func setUpContextTextField() {
        
        self.textInputField = UITextField(frame: self.cameraView.frame)

        self.textInputField.accessibilityIdentifier = "context textfield"
        self.cameraView.addSubview(self.textInputField)
        
        self.textInputField.translatesAutoresizingMaskIntoConstraints = false
        self.textInputField.centerXAnchor.constraint(equalTo: self.cameraView.centerXAnchor).isActive = true
        self.textInputField.widthAnchor.constraint(equalTo: self.cameraView.widthAnchor).isActive = true
        self.textInputField.heightAnchor.constraint(equalTo: self.cameraView.heightAnchor, multiplier: 0.05).isActive = true
        
        self.textInputFieldCenterYConstraint = self.textInputField.centerYAnchor.constraint(equalTo: self.cameraView.centerYAnchor)
        self.textInputFieldCenterYConstraint?.isActive = true

        self.textInputField.isOpaque = true
        self.textInputField.autocapitalizationType = .sentences
        self.textInputField.borderStyle = .none
        self.textInputField.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.textInputField.textColor = UIColor.white
        self.textInputField.returnKeyType = .done
        self.textInputField.font = UIFont.fllscrnFont(18)
        self.textInputField.textAlignment = .center
        
        let paddingView : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 2.5, height: self.textInputField.frame.height))
        self.textInputField.leftView = paddingView
        self.textInputField.rightView = paddingView
        self.textInputField.leftViewMode = .always
        self.textInputField.rightViewMode = .always

        self.textInputField.delegate = self
        self.textInputField.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown(_:)),
                                                         name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    func keyboardShown(_ notification: Notification) {
        
        let info  = (notification as NSNotification).userInfo!
        let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]! as AnyObject
        
        let rawFrame = value.cgRectValue
        let keyboardFrame = view.convert(rawFrame!, from: nil)
        
        if self.textInputField.isEditing { //self.contextField.editing {
            
            self.buttonCollection.isHidden = true // always hide button collection when keyboard is out
            
            self.textInputFieldConstraintToKeyboard = self.textInputField.bottomAnchor.constraint(equalTo: self.cameraView.centerYAnchor, constant: self.view.frame.height / 2 - keyboardFrame.height)
            
            UIView.animate(withDuration: keyboardAnimationTime, delay: 0.0, options: [.curveEaseIn], animations: {
                
                self.textInputField.isHidden = false
                
                self.textInputFieldConstraintToRecordButton?.isActive = false
                self.textInputFieldCenterYConstraint?.isActive = false
                self.textInputFieldConstraintToKeyboard?.isActive = true
                
                self.view.layoutIfNeeded()
                
            }) { (completed) in
                
                self.textInputField.becomeFirstResponder()
                self.hasText = true
                self.checkButton(atPosition: 0)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.accessibilityIdentifier == "context textfield" {
            
            if textField.text! == "" {
                
                UIView.animate(withDuration: self.keyboardAnimationTime, delay: 0.0, options: [.curveEaseIn], animations: {
                    
                    self.textInputFieldConstraintToRecordButton?.isActive = false
                    self.textInputFieldConstraintToKeyboard?.isActive = false
                    self.textInputFieldCenterYConstraint?.isActive = true
                    
                    self.view.layoutIfNeeded()
                    
                    }, completion: { (completed) in
                        
                        self.buttonCollection.isHidden = false
                })
                
                self.textInputField.isHidden = true
                self.hasText = false
            }
            else {

                self.textInputFieldConstraintToRecordButton = self.textInputField.bottomAnchor.constraint(equalTo: self.recordBtn.topAnchor, constant: -10)
                
                UIView.animate(withDuration: self.keyboardAnimationTime, delay: 0.0, options: [.curveEaseIn], animations: {
                    
                    self.textInputFieldConstraintToKeyboard?.isActive = false
                    self.textInputFieldCenterYConstraint?.isActive = false
                    self.textInputFieldConstraintToRecordButton?.isActive = true
                    
                    self.view.layoutIfNeeded()
                    
                    }, completion: { (completed) in
                        
                        self.buttonCollection.isHidden = false
                        self.hasText = true
                })
            }
        }
        
        self.view.endEditing(true)
        self.checkButton(atPosition: 0)
        return false
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
            var text = textField.text! as NSString
            text = text.replacingCharacters(in: range, with: string) as NSString
            
            let textSize = text.size(attributes: [NSFontAttributeName : textField.font!])
            
            return (textSize.width < textField.bounds.size.width - 12) ? true : false

    }
}

enum ButtonState {
    case exit
    case trash
    case back
}
