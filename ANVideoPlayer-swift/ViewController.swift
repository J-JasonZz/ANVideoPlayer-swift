//
//  ViewController.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/3.
//  Copyright © 2017年 wscn. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonClick(_ sender: Any) {
//        ANVideoPlayerUtil.shareInstance.playerVideo(streamURL: URL(string: "http://baobab.wdjcdn.com/14573563182394.mp4"), isLive:false)
        let controller = DemoViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

}

