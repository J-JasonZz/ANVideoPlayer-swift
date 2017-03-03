//
//  ANVideoPlayerLayerView.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/3.
//  Copyright © 2017年 wscn. All rights reserved.
//

import UIKit
import AVFoundation

class ANVideoPlayerLayerView: UIView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var player: AVPlayer? {
        didSet {
            if let playerLayer = self.layer as? AVPlayerLayer {
                playerLayer.player = player
            }
        }
    }
    
}
