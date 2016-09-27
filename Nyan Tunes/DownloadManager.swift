//
//  DownloadManager.swift
//  Nyan Tunes
//
//  Created by Pushkar Sharma on 27/09/2016.
//  Copyright © 2016 thePsguy. All rights reserved.
//

import Foundation
import VKSdkFramework

class DownloadManager:NSObject {

    var activeDownloads = [String: Download]()
    var audioManager = AudioManager.sharedInstance
    
    var downloadDelegate: URLSessionDownloadDelegate?
    
    lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session =  URLSession(configuration: configuration, delegate: {return self.downloadDelegate}(), delegateQueue: nil) // Must set delegate manually
        return session
    }()

    class func sharedInstance() -> DownloadManager {
        struct Singleton {
            static var sharedInstance = DownloadManager()
        }
        return Singleton.sharedInstance
    }
}

protocol DownloadManagerDelegate: class {
    func didWriteBytes()
    func didFinishDownload()
}