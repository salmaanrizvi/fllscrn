//
//  Deal.swift
//  ManestreamCamera
//
//  Created by Salmaan Rizvi on 7/23/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import FontAwesome_swift
import SCLAlertView

let width : CGFloat = 65
let height : CGFloat = 30

class Deal: UIView {

    var name : String
    var numberRedeemable : Int
    var numberRedeemed : Int
    var numberRemaining : Int { return self.numberRedeemable - self.numberRedeemed }
    @IBOutlet var button : UIButton?
    var isUser : Bool
    var redeemedBy : [String]
    override var description: String {
        return "Deal: \(name) \nNumber Redeemable: \(numberRedeemable)\nUser: \(isUser)\n Business:\(!isUser)"
    }
    
    weak var delegate : DealClaimDelegate?
    
    init(name : String, numberRedeemable : Int, numberRedeemed : Int, isUser : Bool, redeemedBy : [String]) {
        
        self.name = name
        self.numberRedeemable = numberRedeemable
        self.numberRedeemed = numberRedeemed
        self.isUser = isUser
        self.redeemedBy = redeemedBy
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))

        setUpButton()
        setUpDealAppearance()
        
    }
    
    override convenience init(frame: CGRect) {
        self.init(name: "", numberRedeemable: 0, numberRedeemed: 0, isUser: false, redeemedBy: [])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setUpButton () {
        self.button = UIButton(frame: CGRect(x: 10, y: 0, width: width / 3, height: height))
        self.button?.setImage(redGift, for: .normal)
//        self.button?.setFAIcon(.FAGift, forState: .Normal)
//        self.button?.setFATitleColor(UIColor.fllscrnRed())
        self.button?.addTarget(self, action: #selector(dealTapped(_:)), for: .touchUpInside)
        self.addSubview(button!)
    }
    
    fileprivate func setUpDealAppearance() {
        self.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        self.layer.cornerRadius = 5
        self.layer.shadowColor = UIColor.black.cgColor
        //self.layer.shadowOffset = CGSizeMake(-8, 8);
        self.layer.shadowRadius = 10;
        self.layer.shadowOpacity = 0.65;
    }
    
    func dealTapped(_ sender : UIButton) {
        
        if isUser {
            print("This is what happens when a user taps")
            Deal.dealAlert(self)
            
            if let delegate = delegate {
                delegate.dealTapped()
            } else { print("I think you may have forgotten to set the deal claimed delegate ;).") }
            
        }
        else {
            print("Business wants to edit the deal.")
            Deal.dealAlert(self)
        }
    }
    
    class func dealAlert(_ deal : Deal) {
        
        var appearance = SCLAlertView.SCLAppearance(kDefaultShadowOpacity: 0.7, kCircleTopPosition: -12.0, kCircleBackgroundTopPosition: -15.0, kCircleHeight: 56.0, kCircleIconHeight: 25.0, kTitleTop: 30.0, kTitleHeight: 25.0, kWindowWidth: 240.0, kWindowHeight: 178.0, kTextHeight: 90.0, kTextFieldHeight: 45.0, kTextViewdHeight: 80.0, kButtonHeight: 45.0, kTitleFont: UIFont.fllscrnFont(20), kTextFont: UIFont.fllscrnFont(14), kButtonFont: UIFont.fllscrnFont(16), showCloseButton: true, showCircularIcon: true, shouldAutoDismiss: true, contentViewCornerRadius: 5.0, fieldCornerRadius: 3.0, buttonCornerRadius: 3.0, hideWhenBackgroundViewIsTapped: false, contentViewColor: UIColor.white, contentViewBorderColor: UIColor.white, titleColor: UIColor.black)
        
/*        var appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont.fllscrnFont(20),
            kTextFont: UIFont.fllscrnFont(14),
            kButtonFont: UIFont.fllscrnFont(16),
            showCloseButton: true,
            showCircularIcon : true,
            kCircleIconHeight : 25
        ) */
        
        let whiteGift = UIImage.fontAwesomeIconWithName(.Gift, textColor: UIColor.white, size: CGSize(width: 375, height: 375), backgroundColor: UIColor.fllscrnRed())
        
        
        
        
        if deal.isUser { // user clicked to claim
            
            appearance = SCLAlertView.SCLAppearance( showCloseButton: false )
            let dealAlert = SCLAlertView(appearance : appearance)
            
            dealAlert.addButton("Claim!", action: { 
                print("Deal claimed!")
                
                if let delegate = deal.delegate { delegate.didTapClaim() }
                else { print("I think you might have forgot to set the deal claimed delegate ;).") }
            })
            
            dealAlert.addButton("Cancel", action: {
                print("Canceled")
                
                if let delegate = deal.delegate { delegate.didTapCancel() }
                else { print("I think you might have forgot to set the deal claimed delegate ;).") }
            
            })
            
            dealAlert.showCustom("Deal Special!", subTitle: "\n\(deal.name)\n\nRemaining: \(deal.numberRemaining)\n", color: UIColor.fllscrnRed(), icon: whiteGift, closeButtonTitle: "Default Cancel", duration: 0.0, colorStyle: UIColor.fllscrnRed().colorCode(), colorTextButton: UIColor.white.colorCode(), circleIconImage: whiteGift, animationStyle: .topToBottom)
        
        }
        else { // business wants to update
            
            let dealAlert = SCLAlertView(appearance : appearance)
            let dealNameTextField : UITextField
            let dealQuantityTextField : UITextField
            
            // update old deal
            dealNameTextField = dealAlert.addTextField("e.g. Buy One Get One Free")
            dealNameTextField.text = deal.name
            
            dealQuantityTextField = dealAlert.addTextField(title: "e.g. 25", identifier: "", keyboardType: UIKeyboardType.numberPad)
            dealQuantityTextField.text = "\(deal.numberRedeemable)"
            
            dealAlert.addButton("Update", action: {
                
                if Deal.checkDeal(dealNameTextField.text!, dealNumber: dealQuantityTextField.text!) {
                    print("Deal updated!")
                    deal.name = dealNameTextField.text!
                    deal.numberRedeemable = Int(dealQuantityTextField.text!)!
                    print(deal)
                }
                else {
                    SCLAlertView(appearance: appearance).showError("Invalid Input", subTitle: "\nDeal not updated.")
                }
            })
            
            dealAlert.showCustom("Add a Deal!\n", subTitle: "\nIndicate the deal and the number that can be redeemed below.\n", color: UIColor.fllscrnRed(), icon: whiteGift, closeButtonTitle: "Cancel", duration: 0.0, colorStyle: UIColor.fllscrnRed().colorCode(), colorTextButton: UIColor.white.colorCode(), circleIconImage: whiteGift, animationStyle: .topToBottom)
        }
    }
    
    class func checkDeal(_ dealName : String, dealNumber : String) -> Bool {
        if dealName == "" { return false }
        else if dealNumber == "" || dealNumber == "0" { return false }
        return true
    }
    
    func pulseAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = 0.35
        pulseAnimation.toValue = 1.0
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 3
        self.layer.add(pulseAnimation, forKey: nil)
    }
}

@objc protocol DealClaimDelegate : class {
    
    func dealTapped() // further customize what happens when someone taps the deal.
    func didTapClaim() // further customize what happens when a claim is tapped.
    func didTapCancel() // further customize what happens when a claim is canceled.
    
}
