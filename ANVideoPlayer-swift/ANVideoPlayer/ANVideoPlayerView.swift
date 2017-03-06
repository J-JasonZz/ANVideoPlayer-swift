//
//  ANVideoPlayerView.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/3.
//  Copyright © 2017年 wscn. All rights reserved.
//

import UIKit

enum ANVideoPlayerViewState {
    case ANVideoPlayerViewStatePortrait // 竖屏播放
    case ANVideoPlayerViewStateLandscape // 横屏播放
    case ANVideoPlayerViewStateWindow // 小窗播放
}

@objc
protocol ANVideoPlayerViewDelegate {
    @objc optional func closeButtonTapped() // 关闭按钮点击
    @objc optional func windowCloseButtonTapped() // 小窗状态关闭按钮点击
    @objc optional func fullScreenButtonTapped() // 全屏按钮点击
    @objc optional func bigPlayButtonTapped() // 大播放按钮点击
    @objc optional func playButtonTapped() // 小播放按钮点击
    @objc optional func playViewTapped() // 播放器点击
    @objc optional func scrubberBegin() // 进度条拖动开始
    @objc optional func scrubberEnd() // 进度条拖动结束
}

class ANVideoPlayerView: UIView {

    // 播放器展示状态(默认竖屏)
    var state = ANVideoPlayerViewState.ANVideoPlayerViewStatePortrait
    // 是否是直播
    var isLive = false
    // 播放器单击手势
    var playerViewTap = UITapGestureRecognizer(target: self, action: #selector(playerViewTapHandle(_:)))
    // 播放器拖动手势
    var panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(swipePanGestureHandler(_:)))
    
    @IBOutlet weak var playerLayerView: ANVideoPlayerLayerView!
    
    
    func playerViewTapHandle(_ playerViewTap: UITapGestureRecognizer) {
        
    }

    func swipePanGestureHandler(_ panGesture: UIPanGestureRecognizer) {
        
    }
    
}
