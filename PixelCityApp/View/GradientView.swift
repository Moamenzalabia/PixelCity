//  GradientView.swift
//  PixelCityApp
//  Created by MOAMEN on 11/19/1397 AP.
//  Copyright © 1397 MacOS. All rights reserved.

import UIKit

class GradientView: UIView {
    
    let gradient = CAGradientLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupGradientView()
    }
    
    fileprivate func setupGradientView(){
        gradient.frame = self.layer.bounds
        gradient.colors = [UIColor.init(white: 1.0, alpha: 0.0).cgColor,UIColor.white.cgColor] //first and second color
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.locations = [0.95,1.0] //take end of first color and end of second  color
        self.layer.insertSublayer(gradient, at: 0)
    }
    
}
