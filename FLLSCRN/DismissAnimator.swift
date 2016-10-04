//
//  DismissAnimator.swift
//  FLLSCRN
//
//  Created by Salmaan Rizvi on 7/7/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import Foundation
import UIKit

class DismissAnimator : NSObject {
}

extension DismissAnimator : UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
//            let containerView = transitionContext.containerView
            else {
                return
        }
        
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        let screenBounds = UIScreen.main.bounds
        let bottomLeftCorner = CGPoint(x: 0, y: screenBounds.height)
        let finalFrame = CGRect(origin: bottomLeftCorner, size: screenBounds.size)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                fromVC.view.frame = finalFrame
            },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
