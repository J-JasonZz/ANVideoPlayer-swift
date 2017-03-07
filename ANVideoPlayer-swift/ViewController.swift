//
//  ViewController.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/3.
//  Copyright © 2017年 wscn. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ANVideoPlayerDelegate {

    var player: ANVideoPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonClick(_ sender: Any) {
        player = ANVideoPlayer()
        player!.playerView.frame = ScreenBounds
        player!.isLive = false
        player?.delegate = self
        UIApplication.shared.keyWindow?.addSubview(player!.playerView)
        try? player!.loadVideo(streamURL: URL.init(string: "http://baobab.wdjcdn.com/14573563182394.mp4"))
    }
    
    func videoPlayer(_ videoPlayer: ANVideoPlayer, closeButtonClick closeButton: UIButton) {
        player?.playerView.removeFromSuperview()
        player = nil
    }

}

