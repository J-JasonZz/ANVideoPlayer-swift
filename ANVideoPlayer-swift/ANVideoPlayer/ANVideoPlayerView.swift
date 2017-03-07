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

protocol ANVideoPlayerViewDelegate {
    func closeButtonTapped() // 关闭按钮点击
    func windowCloseButtonTapped() // 小窗状态关闭按钮点击
    func fullScreenButtonTapped() // 全屏按钮点击
    func bigPlayButtonTapped() // 大播放按钮点击
    func playButtonTapped() // 小播放按钮点击
    func playViewTapped() // 播放器点击
    func scrubberBegin() // 进度条拖动开始
    func scrubberEnd() // 进度条拖动结束
}

class ANVideoPlayerView: UIView {

    let windowDisplayWidth: CGFloat = 170.0
    let windowDisplayHeigth: CGFloat = 170.0 / (16.0 / 9.0)
    // 播放器展示状态(默认竖屏)
    var state = ANVideoPlayerViewState.ANVideoPlayerViewStatePortrait {
        willSet {
            switch newValue {
            case .ANVideoPlayerViewStatePortrait:
                windowCloseButton.isHidden = true
                if state == .ANVideoPlayerViewStateWindow {
                    controlView.isHidden = false
                    isControlsHidden = false
                }
                windowButton.isHidden = false
                UIApplication.shared.isStatusBarHidden = true
                startControlsTimer()
            case .ANVideoPlayerViewStateLandscape:
                windowButton.isHidden = true
            case .ANVideoPlayerViewStateWindow:
                windowCloseButton.isHidden = false
                controlView.isHidden = true
                isControlsHidden = true
                UIApplication.shared.isStatusBarHidden = false
                stopControlsTimer()
            }
        }
    }
    // 是否是直播
    var isLive = false {
        didSet {
            if isLive {
                setPlayerViewOnLive()
            } else {
                setPlayerViewOnDemand()
            }
        }
    }
    // 播放器单击手势
    var playerViewTap = UITapGestureRecognizer()
    // 播放器拖动手势
    var panGesture = UIPanGestureRecognizer()
    // 播放视图
    @IBOutlet weak var playerLayerView: ANVideoPlayerLayerView!
    // 控制视图
    @IBOutlet weak var controlView: UIView!
    // 顶部控制层
    @IBOutlet weak var topControlOverlay: UIView!
    // 关闭播放按钮
    @IBOutlet weak var closeButton: UIButton!
    // 窗口播放按钮
    @IBOutlet weak var windowButton: UIButton!
    // 底部控制层
    @IBOutlet weak var bottomControlOverlay: UIView!
    // 播放按钮
    @IBOutlet weak var playButton: UIButton!
    // 播放进度条
    @IBOutlet weak var scrubber: UISlider!
    // 缓冲进度条
    @IBOutlet weak var loadedTimeRangesProgress: UIProgressView!
    // 当前时间/总时间
    @IBOutlet weak var timeLabel: UILabel!
    // 全屏按钮
    @IBOutlet weak var fullScreenButton: UIButton!
    // 直播间隔view
    @IBOutlet weak var onLiveSpaceView: UIView!
    // 直播中按钮
    @IBOutlet weak var onLiveButton: UIButton!
    // 大播放按钮
    @IBOutlet weak var bigPlayButton: UIButton!
    // 菊花
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    // 窗口播放模式关闭
    @IBOutlet weak var windowCloseButton: UIButton!
    
    var delegate: ANVideoPlayerViewDelegate?
    
    
    var isControlsHidden = false
    var controlsTimer: Timer?
    var isSwiping = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 播放进度条
        scrubber.setThumbImage(UIImage(named: "ANScrubber_thumb"), for: .normal)
        scrubber.maximumTrackTintColor = UIColor.gray
        scrubber.minimumTrackTintColor = UIColor.colorFromRGB(rgbValue: 0x00f5ff)
        
        // 缓冲进度条
        loadedTimeRangesProgress.progressTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
        loadedTimeRangesProgress.trackTintColor = .clear
        loadedTimeRangesProgress.isUserInteractionEnabled = false
        
        // 顶部控制视图阴影
        let topOverlay = UIView(frame: topControlOverlay.frame)
        topOverlay.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        topOverlay.backgroundColor = UIColor.black
        topOverlay.alpha = 0.6
        topControlOverlay.addSubview(topOverlay)
        topControlOverlay.sendSubview(toBack: topOverlay)
        
        // 底部控制视图阴影
        let bottomOverlay = UIView(frame: CGRect(x: 0, y: 0, width: bottomControlOverlay.frame.size.width, height: bottomControlOverlay.frame.size.height))
        bottomOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin]
        bottomOverlay.backgroundColor = UIColor.black
        bottomOverlay.alpha = 0.6
        bottomControlOverlay.addSubview(bottomOverlay)
        bottomControlOverlay.sendSubview(toBack: bottomOverlay)
        
        // 视图单击手势
        playerViewTap.addTarget(self, action: #selector(playerViewTapHandle(_:)))
        addGestureRecognizer(playerViewTap)
        // 视图右拖动手势
        panGesture.addTarget(self, action: #selector(swipePanGestureHandler(_:)))
        addGestureRecognizer(panGesture)
        
        // 播放进度条拖动
        scrubber.addTarget(self, action: #selector(scrubberDragBegin), for: .touchDown)
        scrubber.addTarget(self, action: #selector(scrubberDragEnd), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        scrubber.addTarget(self, action: #selector(scrubberValueChanged), for: .valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(durationDidLoad(_:)), name: ANVideoPlayerDurationDidLoad, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scrubberValueUpdated(_:)), name: ANVideoPlayerScrubberValueUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadedTimeRangesUpdate(_:)), name: ANVideoPlayerItemLoadedTimeRanges, object: nil)
    }
    
    private func startControlsTimer() {
        stopControlsTimer()
        if #available(iOS 10.0, *) {
            controlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { [weak self] timer in
                self?.controlsTimerHandle()
            })
        } else {
            controlsTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(controlsTimerHandle), userInfo: nil, repeats: false)
        }
    }
    
    private func stopControlsTimer() {
        if let timer = controlsTimer {
            if timer.isValid {
                timer.invalidate()
                controlsTimer = nil
            }
        }
    }
    
    @objc func controlsTimerHandle() {
        if !isControlsHidden {
            controlView.isHidden = true
            isControlsHidden = true
        }
    }
    
    // 点播
    private func setPlayerViewOnDemand() {
        onLiveSpaceView.isHidden = true
        onLiveButton.isHidden = true
    }
    
    // 直播
    private func setPlayerViewOnLive() {
        scrubber.isHidden = true
        loadedTimeRangesProgress.isHidden = true
        timeLabel.isHidden = true
    }
    
    func playerViewTapHandle(_ playerViewTap: UITapGestureRecognizer) {
        if state == .ANVideoPlayerViewStateWindow {
            UIView.animate(withDuration: 0.3, animations: { 
                self.frame = ScreenBounds
            }, completion: { finished in
                self.state = .ANVideoPlayerViewStatePortrait
            })
        } else {
            controlView.isHidden = !controlView.isHidden
            isControlsHidden ? startControlsTimer() : stopControlsTimer()
            isControlsHidden = !isControlsHidden
        }
    }

    func swipePanGestureHandler(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: self)
        if panGesture.state == .began {
            if state == .ANVideoPlayerViewStatePortrait || state == .ANVideoPlayerViewStateWindow {
                startPanPlayerView()
            }
        } else if (panGesture.state == .cancelled || panGesture.state == .ended) {
            if state == .ANVideoPlayerViewStatePortrait {
                endPanPlayerViewWhenPortrait()
            }
            if state == .ANVideoPlayerViewStateWindow {
                endPanPlayerViewWhenWindow()
            }
        } else if (panGesture.state == .changed) {
            if state == .ANVideoPlayerViewStatePortrait {
                panPlayerViewWhenPortraitWithPanGestureDistance(translation.x)
            }
            if state == .ANVideoPlayerViewStateWindow {
                panPlayerViewWhenWindowWithPanGestureTranslation(translation)
            }
        }
    }
    
    private func startPanPlayerView() {
        if isSwiping {
            return;
        }
        if state == .ANVideoPlayerViewStatePortrait {
            UIApplication.shared.isStatusBarHidden = false
        }
        isSwiping = true
    }
    
    private func endPanPlayerViewWhenPortrait() {
        if !isSwiping {
            return;
        }
        
        if frame.origin.x >= 50.0 {
            state = .ANVideoPlayerViewStateWindow
            UIView.animate(withDuration: 0.3, animations: { 
                self.frame = CGRect.init(x: ScreenBounds.size.width - 15.0 - self.windowDisplayWidth, y: ScreenBounds.size.height - 45.0 - self.windowDisplayHeigth, width: self.windowDisplayWidth, height: self.windowDisplayHeigth)
            }, completion: { finished in
                self.isSwiping = false
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: { 
                self.frame = ScreenBounds
            }, completion: { finished in
                self.isSwiping = false
                UIApplication.shared.isStatusBarHidden = true
            })
        }
    }
    
    private func endPanPlayerViewWhenWindow() {
        if center.x <= ScreenBounds.size.width / 2.0 {
            UIView.animate(withDuration: 0.3, animations: {
                var center = self.center
                center.x = 15.0 + self.windowDisplayWidth / 2.0
                if self.center.y < 15.0 + self.windowDisplayHeigth / 2.0 {
                    center.y = 15.0 + self.windowDisplayHeigth / 2.0
                } else if (self.center.y > ScreenBounds.size.height - 15.0 - self.windowDisplayHeigth / 2.0) {
                    center.y = ScreenBounds.size.height - 15.0 - self.windowDisplayHeigth / 2.0
                }
                self.center = center
            }, completion: { finished in
                
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                var center = self.center
                center.x = ScreenBounds.size.width - 15.0 - self.windowDisplayWidth / 2.0
                if self.center.y < 15.0 + self.windowDisplayHeigth / 2.0 {
                    center.y = 15.0 + self.windowDisplayHeigth / 2.0
                } else if(self.center.y > ScreenBounds.size.height - 15.0 - self.windowDisplayHeigth / 2.0) {
                    center.y = ScreenBounds.size.height - 15.0 - self.windowDisplayHeigth / 2.0
                }
                self.center = center
            })
        }
    }
    
    private func panPlayerViewWhenPortraitWithPanGestureDistance(_ distance: CGFloat) {
        if distance <= 0 {
            return;
        }
        if !isSwiping {
            return;
        }
        let rate = distance / (ScreenBounds.size.width * 2)
        
        let widthPadding: CGFloat = 15.0
        let heightPadding: CGFloat = 45.0
        
        setFrameOriginX((ScreenBounds.size.width - widthPadding - windowDisplayWidth) * rate)
        setFrameOriginY((ScreenBounds.size.height - heightPadding - windowDisplayHeigth) * rate)
        
        setFrameWidth(ScreenBounds.size.width - frame.origin.x - (widthPadding * rate))
        setFrameHeight(ScreenBounds.size.height - frame.origin.y - (heightPadding * rate))
    }
    
    private func panPlayerViewWhenWindowWithPanGestureTranslation(_ translation: CGPoint) {
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        panGesture.setTranslation(CGPoint.zero, in: UIApplication.shared.keyWindow)
    }
    
    @IBAction func closeButtonClick(_ sender: Any) {
        stopControlsTimer()
        UIApplication.shared.isStatusBarHidden = false
        delegate?.closeButtonTapped()
    }
    
    @IBAction func windowButtonClick(_ sender: Any) {
        isSwiping = true
        state = .ANVideoPlayerViewStateWindow
        UIView.animate(withDuration: 0.3, animations: { 
            self.frame = CGRect(x: ScreenBounds.size.width - 15.0 - self.windowDisplayWidth, y: ScreenBounds.size.height - self.windowDisplayHeigth - 45.0, width: self.windowDisplayWidth, height: self.windowDisplayHeigth)
        }) { finished in
            self.isSwiping = false
        }
    }
    
    @IBAction func windowCloseButtonClick(_ sender: Any) {
        stopControlsTimer()
        delegate?.windowCloseButtonTapped()
    }
    
    @IBAction func playButtonClick(_ sender: Any) {
        playButton.isSelected = !playButton.isSelected
        playButton.isSelected ? stopControlsTimer() : startControlsTimer()
        delegate?.playButtonTapped()
    }
    
    @IBAction func bigPlayButtonClick(_ sender: Any) {
        bigPlayButton.isSelected = !bigPlayButton.isSelected
        bigPlayButton.isSelected ? stopControlsTimer() : startControlsTimer()
        delegate?.bigPlayButtonTapped()
    }
    
    @IBAction func fullScreenButtonClick(_ sender: Any) {
        fullScreenButton.isSelected = !fullScreenButton.isSelected
        startControlsTimer()
        delegate?.fullScreenButtonTapped()
    }
    
    @objc private func scrubberDragBegin() {
        stopControlsTimer()
        delegate?.scrubberBegin()
    }
    
    @objc private func scrubberDragEnd() {
        startControlsTimer()
        delegate?.scrubberEnd()
    }
    
    @objc private func scrubberValueChanged() {
        updateTimeLabel()
    }
    
    func durationDidLoad(_ notification: Notification) {
        let info = notification.userInfo
        let duration = info?["duration"]
        
        if let newDuration = duration as? Double {
            if !(newDuration > 0) {
                return;
            }
            scrubber.maximumValue = Float(newDuration)
        }
    }
    
    func scrubberValueUpdated(_ notification: Notification) {
        let info = notification.userInfo
        
        if let value = info?["scrubberValue"] as? Float {
            if value <= 0.0 {
                return;
            }
            scrubber.setValue(value, animated: true)
            updateTimeLabel()
            
        }
        
    }
    
    func loadedTimeRangesUpdate(_ notification: Notification) {
        if scrubber.maximumValue <= 1.0 {
            return;
        }
        let info = notification.userInfo
        
        if let value = info?["loadedTimeRanges"] as? Double {
            loadedTimeRangesProgress.progress = Float(value) / scrubber.maximumValue
        }
    }
    
    private func updateTimeLabel() {
        timeLabel.text = String.init(format: "%@/%@", time(from: Int(self.scrubber.value)), time(from: Int(self.scrubber.maximumValue)))
    }
    
    private func time(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds / 60) % 60
        let secs = seconds % 60
        if hours > 0 {
            return String.init(format: "%01d:%02d:%02d", hours, minutes, secs)
        } else {
            return String.init(format: "%02d:%02d", minutes, secs)
        }
    }
}
