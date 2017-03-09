//
//  DemoViewController.swift
//  ANVideoPlayer-swift
//
//  Created by JasonZhang on 2017/3/9.
//  Copyright © 2017年 wscn. All rights reserved.
//

import UIKit
import Alamofire

class DemoViewController: UITableViewController {

    var dataSource: [Any] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "DemoTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        let path = Bundle.main.path(forResource: "videoData", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        
        let rootDict = try! JSONSerialization.jsonObject(with: data, options: .allowFragments)
        
        let dict = rootDict as! Dictionary<String, AnyObject>
        let videoList = dict["videoList"] as! [Dictionary<String, AnyObject>]
        
        for dict in videoList {
            let model = DemoModel()
            model.playUrl = dict["playUrl"] as? String
            model.coverImageUrl = dict["coverForFeed"] as? String
            model.title = dict["title"] as? String
            dataSource.append(model)
        }
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DemoTableViewCell
        let model = dataSource[indexPath.row] as! DemoModel
        
        cell.assginValue(model: model)
        cell.buttonBlock = {
            ANVideoPlayerUtil.shareInstance.playerVideo(streamURL: URL(string: model.playUrl!), isLive: false)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 240.0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
