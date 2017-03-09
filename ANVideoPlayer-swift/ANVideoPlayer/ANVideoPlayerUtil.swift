//
//  ANVideoPlayerUtil.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/9.
//  Copyright © 2017年 wscn. All rights reserved.
//

import UIKit

class ANVideoPlayerUtil: NSObject, ANVideoPlayerDelegate {
    
    static let shareInstance = ANVideoPlayerUtil()
    
    var currentPlayer: ANVideoPlayer?
    
    
    func playerVideo(streamURL: URL?, isLive: Bool) {
        currentPlayer?.playerView.removeFromSuperview()
        currentPlayer = nil
        
        currentPlayer = ANVideoPlayer()
        currentPlayer?.playerView.frame = ScreenBounds
        currentPlayer?.delegate = self
        currentPlayer?.isLive = isLive
        currentPlayer?.playerView.alpha = 0.0
        UIApplication.shared.keyWindow?.addSubview(currentPlayer!.playerView)
        UIView.animate(withDuration: 0.3, animations: { 
            self.currentPlayer?.playerView.alpha = 1.0
        }) { finished in
                try? self.currentPlayer?.loadVideo(streamURL: streamURL)
        }
    }
    
    func videoPlayer(_ videoPlayer: ANVideoPlayer, closeButtonClick closeButton: UIButton) {
        UIView.animate(withDuration: 0.3, animations: { 
            self.currentPlayer?.playerView.alpha = 0.0
        }) { (finished) in
            self.currentPlayer?.playerView.removeFromSuperview()
            self.currentPlayer = nil
        }
    }
}
