//
//  FLSCNImagePicker.swift
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/7/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import Foundation
import UIKit

public class FLSCNImagePicker: UIViewController, FSAlbumViewDelegate, UIViewControllerTransitioningDelegate {
    
    var albumView = FSAlbumView.instance()
        
    @IBOutlet var photoLibraryViewerContainer: UIView!
    @IBOutlet var menuView: UIView!
    @IBOutlet var acceptButton: UIButton!
    
    let interactor = Interactor()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        albumView.delegate = self
        photoLibraryViewerContainer.addSubview(albumView)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        albumView.frame  = CGRect(origin: CGPointZero, size: photoLibraryViewerContainer.frame.size)
        albumView.layoutIfNeeded()
        albumView.initialize()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override public func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let image = albumView.imageCropView.image
        
        if segue.identifier == "cameraRollFLSCNSegue" {
            
            let imageViewController: FLSCNImageViewController = segue.destinationViewController as! FLSCNImageViewController
            
            print("Interactor in Image Picker: shouldFinish: \(interactor.shouldFinish) hasStarted \(interactor.hasStarted)")
            
            imageViewController.transitioningDelegate = self
            imageViewController.interactor = interactor;
            imageViewController.imageForViewing = image
            imageViewController.kMovementSmoothing = 0.85;
            imageViewController.kAnimationDuration = 0.05;
            imageViewController.kRotationMultiplier = 6.0;
            
        }
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
    }

    // MARK: UIViewControllerTransitionDelegate
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }

    public func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}