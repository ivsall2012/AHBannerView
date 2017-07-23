//
//  AHDataTaskManager.swift
//  AHDownloadTool
//
//  Created by Andy Tong on 6/22/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import UIKit

class AHDataTaskManager: NSObject {
    static let shared = AHDataTaskManager()
    fileprivate var dataTaskDict = [String: AHDataTask]()
}

extension AHDataTaskManager {
    func donwload(url: String, fileSizeCallback: ((_ fileSize: UInt64) -> Void)?, progressCallback: ((_ progress: Double) -> Void)?, successCallback: ((_ filePath: String) -> Void)?, failureCallback: (() -> Void)?) {
        
        var dataTask = dataTaskDict[url]
    
        if dataTask == nil {
            dataTask = AHDataTask()
            dataTaskDict[url] = dataTask
        }

        
        dataTask?.donwload(url: url, fileSizeCallback: fileSizeCallback, progressCallback: progressCallback, successCallback: { (path) in
            self.dataTaskDict.removeValue(forKey: url)
            successCallback?(path)
            
        }, failureCallback: { 
            self.dataTaskDict.removeValue(forKey: url)
            failureCallback?()
        })
    }
    
    func resume(url: String) {
        if let dataTask = dataTaskDict[url] {
            dataTask.resume()
        }
    }
    
    func pause(url: String) {
        if let dataTask = dataTaskDict[url] {
            dataTask.pause()
        }
    }
    
    func cancel(url: String) {
        if let dataTask = dataTaskDict[url] {
            dataTask.cancel()
            dataTaskDict.removeValue(forKey: url)
        }
    }
    
    func cancelAll() {
        let allKeys = dataTaskDict.keys
        for url in allKeys {
            let dataTask = dataTaskDict[url]!
            dataTask.cancel()
            dataTaskDict.removeValue(forKey: url)
        }
    }
    
}







