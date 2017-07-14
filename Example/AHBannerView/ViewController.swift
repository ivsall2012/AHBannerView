//
//  ViewController.swift
//  AHBannerView
//
//  Created by Andy Tong on 07/13/2017.
//  Copyright (c) 2017 Andy Tong. All rights reserved.
//

import UIKit
import AHBannerView

class ViewController: UIViewController {
    var bannerView: AHBannerView!
    fileprivate var images: [UIImage] = {
        var imgs = [UIImage]()
        imgs.append(UIImage(named: "01")!)
        imgs.append(UIImage(named: "02")!)
        imgs.append(UIImage(named: "03")!)
        return imgs
    }()
    let placeholder = UIImage(named: "placeholder")
    override func viewDidLoad() {
        super.viewDidLoad()
        let bannerFrame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 200.0)
        bannerView = AHBannerView(frame: bannerFrame)
        bannerView.delegate = self
        bannerView.didSwitch { (index) in
            //            print("closure -> didSwitch:\(index)")
        }
        bannerView.didTapped { (index) in
            //            print("close -> didTapped:\(index)")
        }
        bannerView.placeholder = self.placeholder
        bannerView.timeInterval = 1
        bannerView.showIndicator = true
        bannerView.indicatorColor = UIColor.blue
        self.view.addSubview(bannerView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bannerView.setup(imageCount: 5) {[weak self] (imageView, index) in
            guard let count = self?.images.count else {return}
            if index < count {
                imageView.image = self?.images[index]
            }
        }
        bannerView.refresh()
    }
    
    
}

extension ViewController: AHBannerViewDelegate {
    func bannerView(_ bannerView: AHBannerView, didSwitch toIndex: Int) {
        //        print("delegate -> didSwitch:\(toIndex)")
    }
    func bannerView(_ bannerView: AHBannerView, didTapped atIndex: Int) {
        //        print("delegate -> didTapped:\(atIndex)")
    }
}

