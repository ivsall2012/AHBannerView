//
//  AHFileTool.swift
//  AHDownloadTool
//
//  Created by Andy Tong on 6/22/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import UIKit

struct AHFileTool {
    static func doesFileExist(filePath: String) -> Bool {
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    static func fileSize(filePath: String) -> UInt64 {
        guard doesFileExist(filePath: filePath) else {
            return 0
        }
        
        guard let infoDict = try? FileManager.default.attributesOfItem(atPath: filePath) else {
            return 0
        }

        guard let fileSize = infoDict[FileAttributeKey.size] as? UInt64 else{
            return 0
        }

        return fileSize
    }
    
    
    @discardableResult
    static func moveItem(atPath: String, toPath: String) -> Bool{
        guard doesFileExist(filePath: atPath) else {
            return false
        }
        
        
        do {
           try FileManager.default.moveItem(atPath: atPath, toPath: toPath)
        } catch _ {
            return false
        }
        
        return true
        
    }
    
    @discardableResult
    static func remove(filePath: String) -> Bool {
        guard doesFileExist(filePath: filePath) else {
            return false
        }
        
        
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch {
            return false
        }
        
        return true
    }
    
    
}









