//
//  AHHttpHeaderFileds.swift
//  AHDownloadTool
//
//  Created by Andy Tong on 6/22/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import UIKit

struct AHHttpHeader {
    static let contentLength = "Content-Length"
    
    // for Google Firebase Storage, it use "content-range" for range
    static let contentRange = "Content-Range"
}
