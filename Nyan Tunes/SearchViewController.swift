//
//  SearchViewController.swift
//  Nyan Tunes
//
//  Created by Pushkar Sharma on 27/09/2016.
//  Copyright © 2016 thePsguy. All rights reserved.
//

import UIKit
import VK_ios_sdk
import Toast

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var audioTableView: UITableView!
    @IBOutlet weak var miniPlayer: MiniPlayerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var audioManager = AudioManager.sharedInstance
    let vkManager = VKClient.sharedInstance
    
    var searchItems = [VKAudio]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioManager.delegate = self
        searchBar.delegate = self
        miniPlayer.delegate = self
        audioTableView.dataSource = self
        audioTableView.delegate = self
        miniPlayer.makeTranslucent()
        // Do any additional setup after loading the view.
    }
    

    override func viewDidAppear(_ animated: Bool) {
        miniPlayer.refreshStatus()
        audioManager.delegate = self
        if let nowPlaying = audioManager.playingObject {
            self.miniPlayer.slider.maximumValue = Float(nowPlaying.duration!)
        }
        let topInset = (self.navigationController?.navigationBar.frame.height)! + self.searchBar.frame.height + UIApplication.shared.statusBarFrame.height
        let bottomInset = self.miniPlayer.frame.height + (self.tabBarController?.tabBar.frame.height)!
        self.audioTableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
    }
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        activityIndicator.startAnimating()
        let searchText = searchBar.text!
        let params = ["q": searchText, "auto_complete": "0", "sort": "2", "search_own": "1"]
        vkManager.getSearchResults(withParams: params) { (error, resultItems) in
            if error != nil {
                self.activityIndicator.stopAnimating()
                self.showAlert(text: error!)
            }else{
                self.activityIndicator.stopAnimating()
                self.searchItems = resultItems!
                self.audioTableView.reloadData()
            }
        }
        self.audioTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
    }
}

extension SearchViewController: MiniPlayerViewDelegate{
    func togglePlay() {
        if audioManager.isPlaying {
            audioManager.pausePlay()
        }else{
            audioManager.resumePlay()
        }
        miniPlayer.refreshStatus()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource{

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "audioCell") as! AudioTableViewCell
        let audioItem = self.searchItems[indexPath.row]
        cell.title.text = audioItem.title
        cell.artist.text = audioItem.artist
        cell.duration = Int(audioItem.duration)
        cell.url = URL(string: audioItem.url)
        cell.trackDelegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        self.searchBar.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var actions: [UITableViewRowAction] = []
        
        let download = UITableViewRowAction(style: .default, title: "Add to Profile") { (action, actionIndex) in
            self.rowActionHandler(action: action, indexPath: indexPath)
        }
        download.backgroundColor = UIColor.orange
        actions.append(download)
        
        return actions
    }
    
    func rowActionHandler(action: UITableViewRowAction, indexPath: IndexPath) {
        if action.title == "Add to Profile" {
            let audioItem = searchItems[indexPath.row]
            if audioItem.url != nil{
                vkManager.addUserAudio(audioID: audioItem.id.stringValue, owner_id: audioItem.owner_id.stringValue, completion: { (error, res) in
                    if error != nil {
                        DispatchQueue.main.async {
                            self.showAlert(text: error!)
                        }
                    }
                })
            } else {
                self.tabBarController?.view.makeToast("Track not available in your region.", duration: 2.0, position: CSToastPositionBottom)
            }
        }
        audioTableView.setEditing(false, animated: true)
    }
}

extension SearchViewController: AudioTableViewCellDelegate, AudioManagerDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
    
    func trackChanged() {
        self.miniPlayer.refreshStatus()
    }
    
    func playPreviewTapped(onCell: AudioTableViewCell) {
        if onCell.url != nil {
            audioManager.playNow(obj: onCell)
            self.miniPlayer.slider.maximumValue = Float(onCell.duration!)
            miniPlayer.refreshStatus()
        } else {
                self.tabBarController?.view.makeToast("Track not available in your region.", duration: 2.0, position: CSToastPositionBottom)
        }
    }
    
    func playDidProgress(toSeconds: Float?) {
        if toSeconds != nil{
            self.miniPlayer.slider.setValue(toSeconds!, animated: false)
            if audioManager.networkStream {
                self.miniPlayer.bufferProgress.progress = audioManager.availableDuration()
            } else {
                self.miniPlayer.bufferProgress.progress = 0
            }
        }
    }
}
