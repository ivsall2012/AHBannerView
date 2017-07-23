//
//  AHDataTask.swift
//  AHDownloadTool
//
//  Created by Andy Tong on 6/22/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import Foundation

enum AHDataTaskState {
    case notStarted
    case pausing
    case downloading
    case succeeded
    case failed
}


class AHDataTask: NSObject {
    fileprivate var session: URLSession?
    fileprivate weak var task: URLSessionDataTask?
    
    fileprivate var tempPath: String?
    fileprivate var cachePath: String?

    // only for the file in cache, and this size is the current size of the file
    fileprivate var offsetSize: UInt64 = 0
    fileprivate var totalSize: UInt64 = 0
    fileprivate var outputStream: OutputStream?
    
    // Callbacks
    fileprivate var fileSizeCallback: ((_ fileSize: UInt64) -> Void)?
    fileprivate var progressCallback: ((_ progress: Double) -> Void)?
    fileprivate var successCallback: ((_ filePath: String) -> Void)?
    fileprivate var failureCallback: (() -> Void)?
    
    
    fileprivate(set) var progress: Double = 0.0 {
        didSet {
            // should not call progressCallback here because when reset(), the callback will be called too, we don't want that. We need a stream line of progresses.
        }
    }
    fileprivate(set) var state = AHDataTaskState.notStarted {
        didSet {
            switch state {
            case .succeeded:
                guard let cachePath = self.cachePath else {return}
                self.successCallback?(cachePath)
            case .failed:
                self.failureCallback?()
            default:
                break
            }
        }
    }
    
    
    
    
}

extension AHDataTask {
    func donwload(url: String, fileSizeCallback: ((_ fileSize: UInt64) -> Void)?, progressCallback: ((_ progress: Double) -> Void)?, successCallback: ((_ filePath: String) -> Void)?, failureCallback: (() -> Void)?) {
        self.fileSizeCallback = fileSizeCallback
        self.progressCallback = progressCallback
        self.successCallback = successCallback
        self.failureCallback = failureCallback
        
        download(url: url)
    }
    
    
    func download(url: String){
        guard state != .downloading && state != .pausing else {
            print("startDownload state is still in either downloading or pausing")
            return
        }
        
        state = .notStarted
        
        let fileName = getName(url: url)
        cachePath = getCachePath(fileName: fileName)
        
        
        // A. file is already downloaded in cache dir
            // 1. notify outside info(localPath, fileSize)
        if AHFileTool.doesFileExist(filePath: cachePath!) {
            state = .succeeded
            return
        }

        
        tempPath = getTempPath(fileName: fileName)
        
        // B. check tempPath
        //    1. file is in tempPath, start download from fileSize
        //    2. file is not in tempPath, start download from 0
        if AHFileTool.doesFileExist(filePath: tempPath!) {
            offsetSize = AHFileTool.fileSize(filePath: tempPath!)
        }else{
            print("start download from 0")
            offsetSize = 0
            
        }
        
        download(url, offsetSize)
        
        // C. check current file size agaist total size
        //  * implmeneted in urlSeesion(didReceived response) since you can only get the file's real size in http response
    }
    
    func resume() {
        guard state == .notStarted || state == .pausing else {
            print("resume state is not notStarted or pausing")
            return
        }
        
        // if it's current pausing, delegate method urlSeesion(didReceived response) won't be called and state won't be changed to downloading, so change state here
        if state == .pausing {
            state = .downloading
        }
        
        // state will be determined in delegate methods
        task?.resume()
    }
    
    func pause() {
        guard state == .downloading else {
            print("pause state is not downloading")
            return
        }
        state = .pausing
        task?.suspend()
    }
    
    func cancel() {
        guard state == .downloading || state == .pausing else {
            print("cancel state is not in downloading or pausing")
            return
        }
        // state will be set to failed in delegate method for canceling, as well as reset()
        task?.cancel()
        session?.invalidateAndCancel()
        session = nil
    }
    
}

//MARK:- Private Methods
extension AHDataTask {
    fileprivate func getTotalSize(response: HTTPURLResponse) -> UInt64? {
        
        let allFields = response.allHeaderFields
        
        guard let contentLengthStr = allFields[AHHttpHeader.contentLength] as? String else {
            print("no contentLength, something wrong, STOP!!")
            return nil
        }
        // Content-Length is guaranteed to exist
        guard let contentLength = UInt64(contentLengthStr) else {
            print("contentLengthStr transform failed, STOP!!")
            return nil
        }
        
        totalSize = contentLength
        
        // if content-range(lowercase) exists, take this over Content-Length
        if let contentRange = allFields[AHHttpHeader.contentRange] as? String {
            // "Content-Range" = "bytes 100-4880328/4880329"
            if let sizeStr = contentRange.components(separatedBy: "/").last,
                let size = UInt64(sizeStr) {
                totalSize = size
            }else{
                // can't extract total size from contentRange, STOP!
                return nil
            }
        }
        
        return totalSize
    }
    
    fileprivate func download(_ url: String, _ offsetSize: UInt64) {
        guard let url = URL(string: url) else {
            print("download error url is nil")
            return
        }
        
        if session == nil {
            let config = URLSessionConfiguration.ephemeral
            session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        }
        
        // use var to delare mutable tyepe, instead of using NSMutableURLRequest
        var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 0)
        // if offset is 0, "Content-Range" would not appear in the response
        request.setValue("bytes=\(offsetSize)-", forHTTPHeaderField: "Range")

        task = session?.dataTask(with: request)
        
        resume()
        
    }
    
    /// Called every time in urlSession delegate method didCompleteWithError
    fileprivate func reset() {
        outputStream = nil
        cachePath = nil
        tempPath = nil
        task = nil
        progress = 0.0
        
        fileSizeCallback = nil
        progressCallback = nil
        successCallback = nil
        failureCallback = nil
        
    }
    
    /// This method's logic should be reconsidered!!!
    fileprivate func getName(url: String) -> String {
        return (url as NSString).lastPathComponent
    }
    
    fileprivate func getTempPath(fileName: String) -> String{
        let temp = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        return temp
    }
    
    fileprivate func getCachePath(fileName: String) -> String {
        let caceh = (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent(fileName)
        return caceh
    }
    
}



//MARK:- URLSession DataDelegate
extension AHDataTask: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        // C. file is in cache
        
        // *** 1. file size(offsetSize) == real size --> This case would casuse status code: 416 which means the offsetSize is not satisfied.
        //  (ignored) 1.1 move file from cache to temp
        //  (ignored) 1.2 cancel current request
        //  (ignored) 1.3 notify outside info(localPath, fileSize)
        
        guard let response = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        
        
        guard response.statusCode < 400 else {
            print("response.statusCode >= 400 !!!")
            return
        }
        
        guard let totalSize = getTotalSize(response: response) else {
            completionHandler(.cancel)
            return
        }
        
        
        
        
        // 4.2 file size > real size when fail to move file from cachePath to tempPath
        //  4.2.1 remove the file and restart download
        //  4.2.2 start new download request
        
        
        // 4.3 file size < real size
        //  4.3.1 create and open OutputStream
        //  4.3.2 resume download from currentSize
        
        guard let cachePath = self.cachePath,
              let tempPath = self.tempPath else {
            print("didReceive response: no cachePath or tempPath")
            completionHandler(.cancel)
            return
        }
        
        
        if offsetSize == totalSize  { // this case is less likely to happen -- status code: 416
            AHFileTool.moveItem(atPath: tempPath, toPath: cachePath)
            completionHandler(.cancel)
        } else if offsetSize > totalSize {
            AHFileTool.remove(filePath: tempPath)
            completionHandler(.cancel)
            download(url: response.url!.absoluteString)
        }else{
            let url = URL(fileURLWithPath: tempPath)
            outputStream = OutputStream(url: url, append: true)
            outputStream?.open()
            state = .downloading
            fileSizeCallback?(totalSize)
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        var values = [UInt8](repeating:0, count:data.count)
        data.copyBytes(to: &values, count: data.count)
        
        outputStream?.write(values, maxLength: data.count)
        offsetSize = offsetSize + UInt64(data.count)
        
        progress = Double(offsetSize) / Double(totalSize)
        self.progressCallback?(progress)
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        guard let cachePath = self.cachePath,
            let tempPath = self.tempPath else {
                state = .failed
                return
        }
        
        if error == nil {
            AHFileTool.moveItem(atPath: tempPath, toPath: cachePath)
            state = .succeeded
        }else{
            state = .failed
            AHFileTool.remove(filePath: tempPath)
        }
        outputStream?.close()
        reset()
    }
    
}










