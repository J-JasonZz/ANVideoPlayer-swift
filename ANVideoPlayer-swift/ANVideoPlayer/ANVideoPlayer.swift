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
    case unknown // 未知状态
    case loading // 正在加载
    case contentPlaying // 正在播放
    case contentPaused // 暂停
    case suspend // 挂起
    case dismissed // 销毁
    case error // 错误
}

enum ANVideoPlayerError: Error {
    case InvalidStreamUrl //无效的链接
}

protocol ANVideoPlayerDelegate: NSObjectProtocol {
    func videoPlayer(_ videoPlayer: ANVideoPlayer, closeButtonClick closeButton: UIButton)
}


class ANVideoPlayer: NSObject, ANVideoPlayerViewDelegate {
    
    @IBOutlet var playerView: ANVideoPlayerView!
    
    weak var delegate: ANVideoPlayerDelegate?
    
    
    var player: AVPlayer? {
        willSet {
            player?.removeObserver(self, forKeyPath: "status")
            timeObserver = nil
        }
        
        didSet {
            player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: DispatchQueue.main, using: { [weak self] time in
                self?.periodicTimeObserver(time: time)
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
    
    var state: ANVideoPlayerState = .unknown {
        willSet {
            switch state {
            case .unknown:
                print("")
            case .loading:
                setLoading(false)
                print("")
            case .contentPlaying:
                print("")
            case .contentPaused:
                playerView.bigPlayButton.isHidden = true
                print("")
            case .suspend:
                print("")
            case .dismissed:
                print("")
            case .error:
                print("")
            }
        }
        
        didSet {
            print(state)
            switch state {
            case .unknown:
                print("")
            case .loading:
                setLoading(true)
                playerView.playButton.isEnabled = false
                playerView.loadedTimeRangesProgress.isHidden = true
                print("")
            case .contentPlaying:
                playerView.playButton.isSelected = false
                playerView.bigPlayButton.isSelected = false
                playerView.playButton.isEnabled = true
                playerView.scrubber.isEnabled = true
                playerView.loadedTimeRangesProgress.isHidden = isLive
                player?.play()
            case .contentPaused:
                playerView.playButton.isSelected = true
                playerView.bigPlayButton.isSelected = true
                playerView.bigPlayButton.isHidden = false
                player?.pause()
            case .suspend:
                print("")
            case .dismissed:
                print("")
            case .error:
                playerView.playButton.isEnabled = false
                playerView.scrubber.isEnabled = false
                player?.pause()
            }
        }
    }
    
    private var steamUrl: URL?
    
    let portraitFrame = CGRect(x: 0, y: 0, width: min(ScreenBounds.size.width, ScreenBounds.size.height), height: max(ScreenBounds.size.width, ScreenBounds.size.height))
    
    let landscapeFrame = CGRect(x: 0, y: 0, width: max(ScreenBounds.size.width, ScreenBounds.size.height), height: min(ScreenBounds.size.width, ScreenBounds.size.height))
    
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
        playerView.delegate = self
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSessionCategoryPlayback)
        
        let notificaitonCenter = NotificationCenter.default
        // AVPlayer状态
        notificaitonCenter.addObserver(self, selector: #selector(playerItemReadyToPlay), name: ANVideoPlayerItemReadyToPlay, object: nil)
        notificaitonCenter.addObserver(self, selector: #selector(orientationChanged(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: UIDevice.current)
    }
    
    deinit {
        timeObserver = nil
        NotificationCenter.default.removeObserver(self)
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        player?.removeObserver(self, forKeyPath: "status")
        pauseContent {
            
        }
        playerItem = nil
        player = nil
        print(self)
    }
    
    func loadVideo(streamURL: URL?) throws {
        if let url = streamURL {
            self.steamUrl = url
        } else {
            throw ANVideoPlayerError.InvalidStreamUrl
        }
        state = .loading
        self.playerView.state = .portrait
        playVideo()
    }
    
    private func playVideo() {
        clearPlayer()
        
        let asset = AVURLAsset.init(url: steamUrl!)
        playerItem = AVPlayerItem.init(asset: asset)
        player = AVPlayer.init(playerItem: playerItem)
        playerView.playerLayerView.player = player
    }
    
    private func setLoading(_ loading: Bool) {
        if loading {
            playerView.activityIndicator.startAnimating()
        } else {
            playerView.activityIndicator.stopAnimating()
        }
    }
    
    private func pauseContent(completionHandler: @escaping () -> Void) {
        switch playerItem!.status {
        case .failed:
            state = .error
            return
        case .unknown:
            state = .loading
            return
        default:
            print("")
        }
        
        switch player!.status {
        case .failed:
            state = .error
            return
        case .unknown:
            state = .loading
            return
        default:
            print("")
        }
        
        switch state {
        case .loading, .contentPlaying, .contentPaused, .suspend, .error:
            state = .contentPaused
            completionHandler()
        default:
            print("")
        }
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
        case .contentPaused:
            print("")
        case .loading, .error:
            pauseContent(completionHandler: { [weak self] in
                self?.seekToZeroDuration()
            })
            print("")
        default:
            print("")
        }
    }
    
    private func playContent() {
        if state == .contentPaused {
            if playerView.scrubber.value >= playerView.scrubber.maximumValue {
               seekToZeroDuration()
            }
            state = .contentPlaying
        }
        
        if state == .loading {
            if playerView.scrubber.value >= playerView.scrubber.maximumValue {
                seekToZeroDuration()
            }
            state = .contentPlaying
        }
    }
    
    private func seekToZeroDuration() {
        player?.an_seek(to: 0, completionHandler: { [weak self] (finished) in
            if finished {
                self?.playContent()
            }
        })
    }
    
    @objc private func playerDidPlayToEnd(_ notification: Notification) {
        pauseContent {
        }
    }
    
    @objc private func orientationChanged(_ notification: Notification) {
        if playerView.state == .window {
            return;
        }
        let device = notification.object as! UIDevice
        
        var rotateToOrientation: UIInterfaceOrientation?

        switch device.orientation {
        case .portrait:
            rotateToOrientation = UIInterfaceOrientation.portrait
            playerView.state = .portrait
        case .portraitUpsideDown:
            rotateToOrientation = UIInterfaceOrientation.portraitUpsideDown
        case .landscapeLeft:
            rotateToOrientation = UIInterfaceOrientation.landscapeRight
            playerView.state = .landscape
        case .landscapeRight:
            rotateToOrientation = UIInterfaceOrientation.landscapeLeft
            playerView.state = .landscape
        default:
            print("")
        }
        if let rotate = rotateToOrientation {
            if rotate == UIInterfaceOrientation.portrait || rotate == UIInterfaceOrientation.landscapeLeft || rotate == UIInterfaceOrientation.landscapeRight {
                performOrientationChange(deviceOrientation: rotate)
            }
        }
    }
    
    private func performOrientationChange(deviceOrientation: UIInterfaceOrientation){
        let degrees = degreesForOrientation(deviceOrientation: deviceOrientation)
        UIView.animate(withDuration: 0.3) {
            var viewBounds: CGRect?
            if deviceOrientation.isLandscape {
                viewBounds = CGRect(x: 0, y: 0, width: self.landscapeFrame.size.width, height: self.landscapeFrame.size.height)
            } else {
                viewBounds = CGRect(x: 0, y: 0, width: self.portraitFrame.size.width, height: self.portraitFrame.size.height)
            }

            self.playerView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * Double(degrees)) / 180.0)
            self.playerView.bounds = viewBounds!
            self.playerView.setFrameOriginX(0.0)
            self.playerView.setFrameOriginY(0.0)
            
            let wvFrame = self.playerView.superview?.frame
            if var frame = wvFrame {
                if frame.origin.y > 0{
                    frame.size.height = ScreenBounds.size.height
                    frame.origin.y = 0.0
                    self.playerView.frame = frame
                }
            }
        }
        playerView.fullScreenButton.isSelected = deviceOrientation.isLandscape
        isFullScreen = deviceOrientation.isLandscape
    }
    
    private func degreesForOrientation(deviceOrientation: UIInterfaceOrientation) -> CGFloat {
        switch deviceOrientation {
        case .portrait:
            return 0.0;
        case .landscapeRight:
            return 90.0
        case .landscapeLeft:
            return -90.0
        case .portraitUpsideDown:
            return 180.0
        default:
            print("")
        }
        return 0.0
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
                        state = .error
                    default:
                        print("")
                    }
                }
                if keyPath == "loadedTimeRanges" {
                    let timeInterval = availableDuration()
                    let info = ["loadedTimeRanges" : timeInterval]
                    NotificationCenter.default.post(name: ANVideoPlayerItemLoadedTimeRanges, object: nil, userInfo: info)
                    
                }
                if keyPath == "playbackBufferEmpty" {
                    if playerItem!.isPlaybackBufferEmpty {
                        state = .loading
                    }
                }
                if keyPath == "playbackLikelyToKeepUp" {
                    if playerItem!.isPlaybackLikelyToKeepUp && state == .loading {
                        playContent()
                    }
                }
            }
        }

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
                    state = .error
                default:
                    print("")
                }
            }
        }
    }
    
    private func availableDuration() -> TimeInterval {
        let loadedTimeRanges = playerItem!.loadedTimeRanges
        let timeRange = loadedTimeRanges.first!.timeRangeValue
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        let result = startSeconds + durationSeconds
        return result
    }
    
    func closeButtonTapped() {
        delegate?.videoPlayer(self, closeButtonClick: playerView.closeButton)
    }
    
    func windowCloseButtonTapped() {
        delegate?.videoPlayer(self, closeButtonClick: playerView.windowCloseButton)
    }
    
    func fullScreenButtonTapped() {
        isFullScreen = playerView.fullScreenButton.isSelected
        if isFullScreen {
            performOrientationChange(deviceOrientation: .landscapeRight)
            playerView.state = .landscape
        } else {
            performOrientationChange(deviceOrientation: .portrait)
            playerView.state = .portrait
        }
    }
    
    func bigPlayButtonTapped() {
        if !playerView.bigPlayButton.isSelected {
            playContent()
        } else {
            if state == .contentPlaying {
                pauseContent {
                    
                }
            }
        }
    }
    
    func playButtonTapped()
    {
        if !playerView.bigPlayButton.isSelected {
            playContent()
        } else {
            if state == .contentPlaying {
                pauseContent {
                    
                }
            }
        }
    }
    
    func playViewTapped() {
        
    }
    
    func scrubberBegin() {
        pauseContent {
            
        }
    }
    
    func scrubberEnd() {
        state = .loading
        player?.an_seek(to: Double(playerView.scrubber.value), completionHandler: { [weak self] finished in
            if finished {
                self?.playContent()
            }
        })
    }

    
}
