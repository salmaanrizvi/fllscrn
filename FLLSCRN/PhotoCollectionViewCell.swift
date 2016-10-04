//
//  PhotoCollectionViewCell.swift
//  FLLSCRN
//
//  Created by Salmaan on 10/2/16.
//  Copyright © 2016 Rizvi Labs. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    lazy var imageView : UIImageView = UIImageView()
    lazy var activityIndicator : UIActivityIndicatorView
        = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func constrainViews() {
        
        self.contentView.addSubview(self.imageView)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.widthAnchor.constraint(equalTo: self.contentView.widthAnchor).isActive = true
        self.imageView.heightAnchor.constraint(equalTo: self.imageView.widthAnchor).isActive = true
        self.imageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        
        self.contentView.addSubview(self.activityIndicator)
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator.widthAnchor.constraint(equalTo: self.imageView.widthAnchor).isActive = true
        self.activityIndicator.heightAnchor.constraint(equalTo: self.imageView.heightAnchor).isActive = true
        self.activityIndicator.centerXAnchor.constraint(equalTo: self.imageView.centerXAnchor).isActive = true
        self.activityIndicator.centerYAnchor.constraint(equalTo: self.imageView.centerYAnchor).isActive = true
    }
    
    func setViewProperties() {
        
        self.contentView.clipsToBounds = true
        
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.isUserInteractionEnabled = false
        self.imageView.backgroundColor = UIColor.clear
        self.imageView.clipsToBounds = true
        self.imageView.image = nil
        
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()

    }

    
}
