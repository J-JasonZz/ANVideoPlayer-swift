//
//  DemoTableViewCell.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/9.
//  Copyright © 2017年 wscn. All rights reserved.
//

import UIKit
import Kingfisher

typealias PlayButtonClickBlock = () -> Void

class DemoTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var playerImageView: UIImageView!
    
    @IBOutlet weak var playButton: UIButton!
    
    var buttonBlock: PlayButtonClickBlock?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func playButtonClick(_ sender: Any) {
        if let block = buttonBlock {
            block()
        }
    }
    
    public func assginValue(model: DemoModel) {
        titleLabel.text = model.title
        if let url = model.coverImageUrl {
            playerImageView.kf.setImage(with: URL(string: url))
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
