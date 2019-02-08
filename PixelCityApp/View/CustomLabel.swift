//
//  CustomLabel.swift
//  PixelCityApp
//
//  Created by MOAMEN on 11/19/1397 AP.
//  Copyright © 1397 MacOS. All rights reserved.
//

import UIKit

class CustomView: UIView {
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
    }
    

}
