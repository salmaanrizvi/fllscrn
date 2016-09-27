//
//  VideoAsset.swift
//  ManestreamCamera
//
//  Created by Salmaan Rizvi on 7/28/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import Foundation
import AVFoundation
import SCLAlertView

class VideoAsset: CustomStringConvertible, Equatable {
    
//    let storage : FIRStorage
//    let storageRef : FIRStorageReference
//    let databaseRef : FIRDatabaseReference
    let savedPathURL : URL
    let uploadAlert : SCLAlertView
    let deal : Deal?
    let displayText : String?
    let dateCreated : String
    var viewCount : Int
    var roarCount : Int
    
    var hasDeal : Bool
    var hasText : Bool
    
    var description: String {
        
        var descr = "Video URL: \(self.savedPathURL.absoluteString)\n"
        
        if hasDeal {
            descr += "Deal: \(self.deal!)\n"
        }
        if hasText {
            descr += "Text: \(self.displayText!)\n"
        }
        
        descr += "Views: \(self.viewCount)\n"
        descr += "Roars: \(self.roarCount)"
        
        return descr
    }
    
    init(withSavedPathURL url : URL, deal : Deal?, text : String?, dateCreated : String, roarCount : Int, viewCount : Int) {
        
//        self.storage = FIRStorage.storage()
//        self.storageRef = storage.referenceForURL(databaseStorageURL)
//        self.databaseRef = FIRDatabase.database().reference()
        self.savedPathURL = url
        self.uploadAlert = SCLAlertView()
        self.dateCreated = dateCreated
        
        if deal != nil {
            self.hasDeal = true
            self.deal = deal
        } else {
            self.hasDeal = false
            self.deal = nil
        }
        
        if text != nil {
            self.hasText = true
            self.displayText = text
        } else {
            self.hasText = false
            self.displayText = nil
        }
        
        self.roarCount = roarCount
        self.viewCount = viewCount
    }
    
//    func uploadVideo(completion: ()->()) {
//        
////        self.uploadAlert.showNotice("Uploading", subTitle: "Please wait.")
//        
//        if let user = FIRAuth.auth()?.currentUser {
//            
//            let encodedDate = self.dateCreated.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
//
//            self.storageRef.child("\(user.uid)/videos/\(encodedDate!)").putFile(self.savedPathURL, metadata: nil, completion: { (returnedMetadata, error) in
//                
//                
//                if let error = error {
//                    
//                    print(error)
//                    
//                    
//                    /* 
//                        HANDLE UPLOAD ERRORS AND SEND ALERT TO USER.
//                     */
//                    
//                } else {
//                    
//                    print("finished uploading to firebase.")
//                    
//                    print("Size of data uploaded: \(returnedMetadata?.size)")
//                    self.uploadVideoMetadata(returnedMetadata?.downloadURL())
//                    
////                    self.uploadAlert.hideView()
//                    completion()
//                }
//            })
//        }
//    }
//    
//    func uploadVideoMetadata(databaseVideoURL : NSURL?) {
//        
//        guard let user = FIRAuth.auth()?.currentUser else {
//            print("User does not exist.")
//            return
//        }
//        
//        let databaseVideoDictionary = self.videoDictionary(databaseVideoURL)
//    
//        self.databaseRef.child("businesses/\(user.uid)/latest video").setValue(databaseVideoDictionary)
//        
//        self.databaseRef.child("businesses/\(user.uid)/videos").observeSingleEventOfType(.Value, withBlock: { (videoSnapshot) in
//            
//            if var videosArray = videoSnapshot.value as? [[String : AnyObject]] {
//                print(videosArray)
//                
//                videosArray.append(databaseVideoDictionary)
//                
//                self.databaseRef.child("businesses/\(user.uid)/videos").setValue(videosArray)
//
//            }
//            
//            }) { (error) in
//                print(error)
//        }
//        
//    }
    
    fileprivate func videoDictionary(_ databaseVideoURL : URL? ) -> [String : AnyObject] {
        
        guard let databaseVideoURL = databaseVideoURL else {
            print("Problem fetching URL of video on Storage database.")
            return ["url":"" as AnyObject]
        }
        
        let dealName = self.deal != nil ? self.deal!.name : ""
        let numRedeemable = self.deal != nil ? self.deal!.numberRedeemable : 0
        let text = self.displayText != nil ? self.displayText! : ""
        
        return ["url" : databaseVideoURL.absoluteString as AnyObject, "dealName" : dealName as AnyObject, "numRedeemable": numRedeemable as AnyObject, "numRedeemed" : 0 as AnyObject, "text" : text as AnyObject, "dateCreated" : Constants.dateFormatter().string(from: Date()) as AnyObject, "views" : 0 as AnyObject, "roars" : 0 as AnyObject]
    }
    
    class func videoAssetFromDictionary(_ dictionary : [String : AnyObject]) -> VideoAsset? {
        
        var deal : Deal? = nil
        var videoURL : URL? = nil
        var text : String? = nil
        
        if dictionary["url"] as! String != "" { // contains a video
            
            if let urlString = dictionary["url"] as? String {
                videoURL = URL(string: urlString)!
            } else { print("Error getting video URL string to create Video Asset.") }
        }
        else { return nil }
        
        if dictionary["dealName"] as! String != "" { // containts a deal
            
            let dealName = dictionary["dealName"] as? String
            let numRedeemable = dictionary["numRedeemable"] as? Int
            let numRedeemed = dictionary["numRedeemed"] as? Int
            let redeemedBy = dictionary["redeemed by"] as? [String] ?? [""]
            
            if let dealName = dealName, let numRedeemable = numRedeemable, let numRedeemed = numRedeemed {
                
                deal = Deal(name: dealName, numberRedeemable: numRedeemable, numberRedeemed: numRedeemed, isUser: true, redeemedBy: redeemedBy)
            }
        }
        
        if dictionary["text"] as! String != "" { // containts text
            
            text = dictionary["text"] as! String!
        }
        
        var date = ""
        if dictionary["dateCreated"] as! String != "" {
            if let createdDate = dictionary["dateCreated"] as? String {
                date = createdDate
            }
        }
        
        let roarCount = dictionary["roars"] as! Int
        let viewCount = dictionary["views"] as! Int
        
        return VideoAsset(withSavedPathURL: videoURL!, deal: deal, text: text, dateCreated: date, roarCount: roarCount, viewCount: viewCount)
    }
    
    func needsUpdate(_ updatedVideoAsset : VideoAsset) -> Bool {
        
        if self.description == updatedVideoAsset.description { return false }
        else { return true }
        
    }

    class func sortByMostRecentlyCreated(_ arrayOfVideos : [VideoAsset]) -> [VideoAsset] {
        
        var videos = arrayOfVideos
        videos.sort(by: { return $0 > $1 })
        return videos
    }
}

func ==(lhs: VideoAsset, rhs: VideoAsset) -> Bool {
    return lhs.savedPathURL == rhs.savedPathURL
}

func >(lhs: VideoAsset, rhs: VideoAsset) -> Bool {
    
    let lhsVideo = Constants.dateFormatter().date(from: lhs.dateCreated)
    let rhsVideo = Constants.dateFormatter().date(from: rhs.dateCreated)
    
    return lhsVideo?.compare(rhsVideo!) == .orderedDescending ? true : false
}

func <(lhs: VideoAsset, rhs: VideoAsset) -> Bool {
    
    let lhsVideo = Constants.dateFormatter().date(from: lhs.dateCreated)
    let rhsVideo = Constants.dateFormatter().date(from: rhs.dateCreated)
    
    return lhsVideo?.compare(rhsVideo!) == .orderedDescending ? false : true
}
