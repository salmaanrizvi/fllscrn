//
//  FSPhotoPickerViewController.swift
//  FLLSCRN
//
//  Created by Salmaan on 10/2/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit
import Photos

class FSPhotoPickerViewController: UIViewController {
    
    let photoCellIdentifier     : String = "photoCell"
    
    lazy var collectionView     : UICollectionView
                                = UICollectionView(frame: CGRect.zero,
                                                   collectionViewLayout: self.collectionViewLayout)
    
    var collectionViewLayout : UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = layoutPadding / 2
        layout.minimumLineSpacing = layoutPadding
        layout.scrollDirection = .vertical
//        layout.sectionHeadersPinToVisibleBounds = true
//        layout.headerReferenceSize = CGSize(width: self.view.bounds.width * widthMultiple,
//                                            height: textFieldSize)
        
        let cellWidth = self.view.bounds.width * widthMultiple / cellsPerRow - layoutPadding
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        return layout
    }
    
    lazy var photos         : [UIImage]     = []
    
    lazy var fsPhotoAlbum   : FSPhotoAlbum  = FSPhotoAlbum.sharedInstance
    var photoAssets         : PHFetchResult<PHAssetCollection>!
    lazy var interactor     : Interactor    = Interactor()
    
    lazy var photoSize      : CGSize =
                              CGSize(width: self.view.bounds.height,
                                     height: self.view.bounds.height)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNavigationControllerProperties()
        self.setViewProperties()
        self.createViewConstraints()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadImages(count: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    func createViewConstraints() {
        
        self.view.addSubview(self.collectionView)

        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        self.collectionView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.collectionView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: widthMultiple).isActive = true
        self.collectionView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
    }
    
    func setViewProperties() {
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.allowsSelection = true
        self.collectionView.backgroundColor = UIColor.black
        
        self.collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: photoCellIdentifier)
    }
    
    func setNavigationControllerProperties() {
        
        self.title = "FLLSCRN"
        
        if let navController = self.navigationController {
    
            navController.navigationBar.barTintColor = UIColor.black
            navController.navigationBar.isTranslucent = false
            navController.navigationBar.titleTextAttributes =
                [NSForegroundColorAttributeName : UIColor.white]
            
            let leftButton = UIButton(type: .custom)
            leftButton.setImage(whiteCamera, for: .normal)
            leftButton.setImage(purpleCamera, for: .highlighted)
            leftButton.frame = CGRect(origin: .zero, size: faIconSize)
            leftButton.addTarget(self, action: #selector(leftBarButtonTapped), for: .touchUpInside)
            
            let leftBarButtonItem = UIBarButtonItem(customView: leftButton)
            self.navigationItem.leftBarButtonItem = leftBarButtonItem
        }
    }
    
    func loadImages(count: Int) {
        
        self.fsPhotoAlbum.getImages(count: count, size: photoSize, videos: false) { (photos) in // count of zero returns all photos
            DispatchQueue.main.async {
                self.photos = photos.flatMap({ return $0 })
                self.collectionView.reloadData()
            }
        }
    }
}

extension FSPhotoPickerViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photoCell = self.collectionView.dequeueReusableCell(withReuseIdentifier: photoCellIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        photoCell.constrainViews()
        photoCell.setViewProperties()
        photoCell.imageView.image = self.photos[indexPath.row]
        photoCell.activityIndicator.stopAnimating()
        
        return photoCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        print("Item selected at: \(indexPath.row)")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let imageVC = storyboard.instantiateViewController(withIdentifier: "imageController") as? FLSCNImageViewController {
            
            imageVC.transitioningDelegate = self
            imageVC.interactor = interactor
            imageVC.imageForViewing = self.photos[indexPath.row]
            imageVC.kMovementSmoothing = 0.85
            imageVC.kAnimationDuration = 0.05
            imageVC.kRotationMultiplier = 6.0
            
            self.present(imageVC, animated: true, completion: { 
                print("Gooooo FLLSCRN!")
            })
        }
    }
}

//extension FSPhotoPickerViewController : PHPhotoLibraryChangeObserver {
//    
//    func photoLibraryDidChange(_ changeInstance: PHChange) {
//        
//        if let details = changeInstance.changeDetails(for: self.photoAssets) {
//            
//            print("Loading new image.")
//            
//            self.photoAssets = details.fetchResultAfterChanges
//            
////            self.loadImages(count: details.fetchResultAfterChanges.count)
////            DispatchQueue.main.async {
////                self.fsPhotoAlbum.fsCollection = details.fetchResultAfterChanges
////                self.collectionView.reloadData()
////            }
//        }
//    }
//}


extension FSPhotoPickerViewController {
    
    func leftBarButtonTapped() {
        
        if let pageVC = self.parent?.parent as? MainPageViewController {
            print("Left tapped")
            pageVC.navigateTo(fsViewController: .camera, direction: .reverse)
        }
    }
    
}

extension FSPhotoPickerViewController : UIViewControllerTransitioningDelegate {
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        return interactor.hasStarted ? interactor : nil
    }
}

extension UINavigationController {
    override open var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
