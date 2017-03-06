//
//  ANVideoPlayer.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/6.
//  Copyright © 2017年 wscn. All rights reserved.
//

import UIKit
import AVFoundation

enum ANVideoPlayerState {
    case ANVideoPlayerStateUnknown // 未知状态
    case ANVideoPlayerStateContentLoading // 正在加载
    case ANVideoPlayerStateContentPlaying // 正在播放
    case ANVideoPlayerStateContentPaused // 暂停
    case ANVideoPlayerStateSuspend // 挂起
    case ANVideoPlayerStateDismissed // 销毁
    case ANVideoPlayerStateError // 错误
}

enum ANVideoPlayerError: Error {
    case InvalidStreamUrl //无效的链接
}


class ANVideoPlayer: NSObject {
    
    @IBOutlet var playerView: ANVideoPlayerView!
    
    var player: AVPlayer? {
        willSet {
            player?.removeObserver(self, forKeyPath: "status")
            timeObserver = nil
        }
        
        didSet {
            player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: DispatchQueue.main, using: { [unowned self] time in
                self.periodicTimeObserver(time: time)
            })
        }
    }
    
    var playerItem: AVPlayerItem? {
        willSet {
            removeOldPlayerItemObserver()
        }
        didSet {
            addNewPlayerItemObserver()
        }
    }
    
    var state: ANVideoPlayerState = .ANVideoPlayerStateUnknown {
        willSet {
        }
        
        didSet {
            
        }
    }
    
    private var steamUrl: URL?
    
    static let portraitFrame = CGRect(x: 0, y: 0, width: min(ScreenBounds.size.width, ScreenBounds.size.height), height: max(ScreenBounds.size.width, ScreenBounds.size.height))
    
    static let landscapeFrame = CGRect(x: 0, y: 0, width: max(ScreenBounds.size.width, ScreenBounds.size.height), height: min(ScreenBounds.size.width, ScreenBounds.size.height))
    
    var visibleInterfaceOrientation: UIInterfaceOrientation?
    
    let supportedOrientations: UIInterfaceOrientationMask = .allButUpsideDown
    
    var isFullScreen = false
    
    var isLive = false {
        didSet {
            playerView.isLive = isLive
        }
    }
    
    private var timeObserver: Any? {
        willSet {
            if let observer = timeObserver {
                player?.removeTimeObserver(observer)
            }
        }
    }
    
    override init() {
        super.init()
        Bundle.main.loadNibNamed("ANVideoPlayer", owner: self, options: nil)
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSessionCategoryPlayback)
        
        let notificaitonCenter = NotificationCenter.default
        // AVPlayer状态
        notificaitonCenter.addObserver(self, selector: #selector(playerItemReadyToPlay), name: ANVideoPlayerItemReadyToPlay, object: nil)
        notificaitonCenter.addObserver(self, selector: #selector(orientationChanged(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: UIDevice.current)
    }
    
    deinit {
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        player?.removeObserver(self, forKeyPath: "status")
        playerItem = nil
        player = nil
        timeObserver = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadVideo(streamURL: URL?) throws {
        if let url = streamURL {
            self.steamUrl = url
        } else {
            throw ANVideoPlayerError.InvalidStreamUrl
        }
        state = .ANVideoPlayerStateContentLoading
        self.playerView.state = .ANVideoPlayerViewStatePortrait
        playVideo()
    }
    
    private func playVideo() {
        clearPlayer()
        
        let asset = AVURLAsset.init(url: steamUrl!)
        playerItem = AVPlayerItem.init(asset: asset)
        player = AVPlayer.init(playerItem: playerItem)
        playerView.playerLayerView.player = player
    }
    
    private func clearPlayer() {
        player = nil
        playerItem = nil
    }
    
    private func removeOldPlayerItemObserver() {
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    private func addNewPlayerItemObserver() {
        playerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidPlayToEnd(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    private func periodicTimeObserver(time: CMTime) {
        let timeInSeconds = Float(CMTimeGetSeconds(time))
        if timeInSeconds <= 0 {
            return;
        }
        
        if player!.currentItemDuration() > 1.0 {
            let info = ["scrubberValue" : timeInSeconds]
            NotificationCenter.default.post(name: ANVideoPlayerScrubberValueUpdated, object: self, userInfo: info)
        }
    }
    
    @objc private func playerItemReadyToPlay() {
        let durationInfo = ["duration" : player?.currentItemDuration()]
        NotificationCenter.default.post(name: ANVideoPlayerDurationDidLoad, object: self, userInfo: durationInfo)
        
        switch state {
        case .ANVideoPlayerStateContentPaused:
            print("")
        case .ANVideoPlayerStateContentLoading:
            print("")
        case .ANVideoPlayerStateError:
            print("")
        default:
            print("")
        }
    }
    
    private func playContent() {
//        if state == .ANVideoPlayerStateContentPaused {
//            
//        }
//        
//        if state {
//            <#code#>
//        }
        seekToZeroDuration()
    }
    
    private func seekToZeroDuration() {
        player?.an_seek(to: 0, completionHandler: { [weak self] (finished) in
            if finished {
                self?.playContent()
            }
        })
    }
    
    @objc private func playerDidPlayToEnd(_ notification: Notification) {
        
    }
    
    @objc private func orientationChanged(_ notification: Notification) {
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let newObject = object as? AVPlayer {
            if newObject == player {
                let status = player!.status
                switch status {
                case .readyToPlay:
                    if playerItem!.status == AVPlayerItemStatus.readyToPlay {
                        NotificationCenter.default.post(name: ANVideoPlayerItemReadyToPlay, object: nil)
                    }
                case .failed:
                    NotificationCenter.default.post(name: ANVideoPlayerItemStatusFailed, object: nil)
                    state = .ANVideoPlayerStateError
                default:
                    print("")
                }
            }
        }
        
        if let newObject = object as? AVPlayerItem {
            if newObject == playerItem {
                if keyPath == "status" {
                    let status = playerItem!.status
                    switch status {
                    case .readyToPlay:
                        if player!.status == .readyToPlay{
                            NotificationCenter.default.post(name: ANVideoPlayerItemReadyToPlay, object: nil)
                        }
                    case .failed:
                        NotificationCenter.default.post(name: ANVideoPlayerItemStatusFailed, object: nil)
                        state = .ANVideoPlayerStateError
                    default:
                        print("")
                    }
                }
                if keyPath == "loadedTimeRanges" {
                    
                }
                if keyPath == "playbackBufferEmpty" {
                    
                }
                if keyPath == "playbackLikelyToKeepUp" {
                    if playerItem!.isPlaybackLikelyToKeepUp && state == .ANVideoPlayerStateContentLoading {
                        playContent()
                    }
                }
            }
        }
    }

}
