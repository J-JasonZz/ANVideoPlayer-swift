//
//  UIColor+Extension.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/3.
//  Copyright © 2017年 wscn. All rights reserved.
//

import UIKit

extension UIColor {
    
    class func colorFromRGB(rgbValue: uint) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    class func colorWithRed(_ red: Int, green: Int, blue: Int) -> UIColor {
        return UIColor(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: 1.0)
    }
}
