//
//  MainPageViewController.swift
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 9/14/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit

enum FLLSCRNViewControllers : Int {
    case camera = 0
    case photos = 1
}

class MainPageViewController: UIPageViewController {

    lazy var viewsArray : [UIViewController] = {
        let gestureCamera = GestureCameraViewController(nibName: nil, bundle: nil)
        let photoViewer = FSPhotoPickerViewController(nibName: nil, bundle: nil)
        let photoViewerNavController = UINavigationController(rootViewController: photoViewer)
        return [gestureCamera, photoViewerNavController]
    }()
    
    lazy var currentIndex : FLLSCRNViewControllers = .camera
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.accessibilityLabel = "Main Page View Controller"
        self.delegate = self
        
        self.setViewControllers([self.viewsArray[currentIndex.rawValue]], direction: .forward, animated: true, completion: { isComplete in
//            self.setNeedsStatusBarAppearanceUpdate()
            
            self.updateCurrentIndex()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var childViewControllerForStatusBarHidden: UIViewController? {
        return self.viewsArray[currentIndex.rawValue]
    }

    override var childViewControllerForStatusBarStyle: UIViewController? {
        return self.viewsArray[currentIndex.rawValue]
    }
}

extension MainPageViewController : UIPageViewControllerDelegate {
    
    func navigateTo(fsViewController : FLLSCRNViewControllers, direction : UIPageViewControllerNavigationDirection) {
        
        let viewController = self.viewsArray[fsViewController.rawValue]
        
        self.setViewControllers([viewController], direction: direction, animated: true) { (isCompleted) in
            
            if isCompleted { self.updateCurrentIndex() }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed { self.updateCurrentIndex() }
    }
    
    func updateCurrentIndex() {
        DispatchQueue.main.async {
            if let currentVC = self.viewControllers?.first {
                
                if currentVC.isKind(of: GestureCameraViewController.self) {
                    self.currentIndex = .camera
                    self.dataSource = nil
                }
                else {
                    self.currentIndex = .photos
                    self.dataSource = self
                }
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

extension MainPageViewController : UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        return currentIndex == .photos ? self.viewsArray[currentIndex.rawValue - 1] : nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        return currentIndex == .camera ? self.viewsArray[currentIndex.rawValue + 1] : nil
    }
}
