//
//  MainPageViewController.swift
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 9/14/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit

class MainPageViewController: UIPageViewController {

    lazy var viewsArray : [UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.accessibilityLabel = "Main Page View Controller"
        self.delegate = self
        
        self.createViewControllers()
        
        self.setViewControllers([self.viewsArray[0]], direction: .forward, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createViewControllers() {
        let gestureCamera = GestureCameraViewController(nibName: nil, bundle: nil)
        
        self.viewsArray = [gestureCamera]
    }
}

extension MainPageViewController : UIPageViewControllerDelegate {
    
}
