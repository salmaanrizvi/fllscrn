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
//    var collection : PHFetchResult<PHAssetCollection>!
    
    override init() {
        super.init()
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
        
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
            PHPhotoLibrary.requestAuthorization({ (status : PHAuthorizationStatus) -> Void in
                
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
            // create an asset collection with the album name
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: FSPhotoAlbum.albumName)
        }) { success, error in
            if success {
                print("Successfully created asset collection.")
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
    
    func fetchAssetCollectionsForAlbum() -> PHFetchResult<PHAssetCollection> {
        
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.predicate = NSPredicate(format: "title = %@", FSPhotoAlbum.albumName)

        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
    }
    
    func fetchAssets(limit : Int, videos: Bool) -> PHFetchResult<PHAsset> {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = limit
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        if videos == false {
            fetchOptions.predicate = NSPredicate(format: "mediaType = %li", PHAssetMediaType.image.rawValue)
        }
        
        return PHAsset.fetchAssets(in: self.assetCollection, options: fetchOptions)
    }
    
    func getImages(count: Int, size: CGSize, videos: Bool, completion: @escaping ([UIImage?])->()) {
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
            completion([])
            return
        }
        
        var imageArray : [UIImage?] = []
        let imageSize = size
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = true
        
        let fsImages = self.fetchAssets(limit: count, videos: videos)
        
        if count == 1 {

            if let firstImageAsset = fsImages.firstObject {
                
//                print("Date created: \(firstImageAsset.creationDate!)")
                
                imageManager.requestImage(for: firstImageAsset, targetSize: imageSize, contentMode: .aspectFill, options: requestOptions, resultHandler: { (image, info) in
                    
//                    if let isImageDegraded = info?[PHImageResultIsDegradedKey] as? Bool {
//                        if !isImageDegraded {

                    imageArray.append(image)
                    completion(imageArray)
//                        }
//                    }
                })
            }
        }
        else {
            
            let dispatchGroup = DispatchGroup()
            
            fsImages.enumerateObjects({ (imageAsset, index, pointer) in
                
//                print("Date created: \(imageAsset.creationDate!)")
                
                dispatchGroup.enter()
                
                imageManager.requestImage(for: imageAsset, targetSize: imageSize, contentMode: .aspectFill, options: requestOptions, resultHandler: { (image, info) in
                    
//                    if let isImageDegraded = info?[PHImageResultIsDegradedKey] as? Bool {
//                        if !isImageDegraded {
                    
                    imageArray.append(image)
                    dispatchGroup.leave()
//                        }
//                    }
                })
            })
            
            dispatchGroup.notify(queue: .main, execute: { 
                completion(imageArray)
            })
        }
    }
    
    func saveImage(image: UIImage, metadata: NSDictionary?, completion: @escaping (Bool, Error?)->()) {
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
    
    func generateThumbnailFrom(filePath: URL) -> UIImage? {
        
        let asset = AVURLAsset(url: filePath)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime(value: 0, timescale: 1), actualTime: nil)
            
            return self.cropToBounds(image: UIImage(cgImage: cgImage), width: kCBottomBarHeight, height: kCBottomBarHeight)
        }
        catch let error as NSError {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    func cropToBounds(image: UIImage, size: CGSize) -> UIImage {
        return self.cropToBounds(image: image, width: size.width, height: size.height)
    }
    
    func cropToBounds(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
}
