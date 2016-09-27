//
//  FLSCNPhotoAlbum.swift
//  FLLSCRN
//
//  Created by Salmaan on 9/27/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import Foundation

import Photos

class FSPhotoAlbum: NSObject {
    static let albumName = "FLLSCRN"
    static let sharedInstance = FSPhotoAlbum()
    
    var assetCollection: PHAssetCollection!
    
    override init() {
        super.init()
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
        
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
                status
            })
        }
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            self.createAlbum()
        } else {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    func requestAuthorizationHandler(status: PHAuthorizationStatus) {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            // ideally this ensures the creation of the photo album even if authorization wasn't prompted till after init was done
            print("trying again to create the album")
            self.createAlbum()
        } else {
            print("should really prompt the user to let them know it's failed")
        }
    }
    
    func createAlbum() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: FSPhotoAlbum.albumName)   // create an asset collection with the album name
        }) { success, error in
            if success {
                self.assetCollection = self.fetchAssetCollectionForAlbum()
            } else {
                print("error \(error)")
            }
        }
    }
    
    func fetchAssetCollectionForAlbum() -> PHAssetCollection! {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", FSPhotoAlbum.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject as PHAssetCollection!
        }
        return nil
    }
    
    func saveImage(image: UIImage, metadata: NSDictionary, completion: @escaping (Bool, Error?)->()) {
        if assetCollection == nil {
            return                          // if there was an error upstream, skip the save
        }
        
        PHPhotoLibrary.shared().performChanges({
            
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            let array = NSArray(array: [assetPlaceHolder!])
            albumChangeRequest!.addAssets(array)
        
        }) { (isComplete, error) in
            
            completion(isComplete, error)
        }
    }
    
    func saveVideo(videoPathURL: URL, completion: @escaping (Bool, Error?)->()) {
        
        if assetCollection == nil {
            return                          // if there was an error upstream, skip the save
        }
        
        PHPhotoLibrary.shared().performChanges({
            
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoPathURL)
            let assetPlaceHolder = assetChangeRequest?.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            let array = NSArray(array: [assetPlaceHolder!])
            albumChangeRequest!.addAssets(array)
            
        }) { (isComplete, error) in
            
            completion(isComplete, error)
        }
    }
}
