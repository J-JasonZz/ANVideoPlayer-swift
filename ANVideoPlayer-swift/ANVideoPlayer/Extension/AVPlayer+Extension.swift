//
//  AVPlayer+Extension.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/6.
//  Copyright © 2017年 wscn. All rights reserved.
//

import AVFoundation

extension AVPlayer {
    func an_seek(to time: TimeInterval, completionHandler: @escaping (Bool) -> Void) {
        if self.responds(to: #selector(seek(to:toleranceBefore:toleranceAfter:completionHandler:))) {
            seek(to: CMTimeMakeWithSeconds(time, 1), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: completionHandler)
        } else {
            seek(to: CMTimeMakeWithSeconds(time, 1), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            completionHandler(true)
        }
    }
    
    func currentItemDuration() -> Double {
        if let duration = currentItem?.duration {
            return CMTimeGetSeconds(duration)
        } else {
            return 0
        }
    }
}
