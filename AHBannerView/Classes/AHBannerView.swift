//
//  AHBannerView.swift
//  AHBannerView
//
//  Created by Andy Tong on 7/11/17.
//  Copyright © 2017 Andy Tong. All rights reserved.
//

import UIKit

private let AHBannerCellID = "AHBannerCellID"


public protocol AHBannerViewDelegate: class {
    func bannerView(_ bannerView: AHBannerView, didTapped atIndex: Int)
    func bannerView(_ bannerView: AHBannerView, didSwitch toIndex: Int)
    func bannerViewForImage(_ bannerView: AHBannerView, imageView: UIImageView, atIndex: Int)
}

public struct AHBannerStyle{
    public var timeInterval: TimeInterval = 5
    public var isAutoSlide = true
    public var placeholder: UIImage?
    /// should have infinite scrolling or not. If set false, autoSliding will be disable
    public var isInfinite = true
    
    /// if set false, autoSliding will be disable
    public var isPagingEnabled = true
    
    public var showIndicator = true
    public var indicatorColor = UIColor.yellow
    
    public var showPageControl = false
    // Is this pageControl separate from the items, which makes pageControl has its own space on the bottom. Or it should be embedded onto the items's bottom
    public var isPageControlSeparated = false
    public var pageControlColor: UIColor = UIColor.gray
    public var pageControlSelectedColor: UIColor = UIColor.yellow
    
    
    /// the height for indicator and/or pageControl
    public var bottomHeight:CGFloat = 8.0
    public init() {}
}


open class AHBannerView: UIView {
    public weak var delegate: AHBannerViewDelegate?
    public var bannerStyle: AHBannerStyle = AHBannerStyle()
    public fileprivate(set) var pageControl: UIPageControl!
    public fileprivate(set) var index: Int = -1
    
    fileprivate var imageCount: Int = 0
    
    fileprivate var didTappedCallback: ((_ atIndex: Int) -> Void)?
    fileprivate var didSwitchCallback: ((_ toIndex: Int) -> Void)?
    
    
    // sectionCount must be larger than 2. if set to 1, it it won't be able to perform infinite scrolling
    fileprivate var sectionCount = 4
    
    // a timer fires every self.timeInterval seconds in order to switch cell
    fileprivate var timer: Timer?
    
    // this indexPath only changes when the cell becomes static
    fileprivate var finalIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    // this indexPath changes constantly as scrolling to left or right
    fileprivate var currentIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    fileprivate var middleSection: Int {
        return Int(sectionCount/2)
    }
    
    fileprivate lazy var indicatorView: UIView = {
        let y = self.bounds.height - self.bannerStyle.bottomHeight
        // only x and width is uncertain at this point
        let frame = CGRect(x: 0, y: y, width: 0.0, height: self.bannerStyle.bottomHeight)
        let view = UIView(frame: frame)
        return view
    }()
    
    fileprivate lazy var pageView: UICollectionView =  {
        var frame: CGRect = self.bounds
        if self.bannerStyle.showPageControl && self.bannerStyle.isPageControlSeparated {
            frame.size.height = self.bounds.height - self.bannerStyle.bottomHeight
        }
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        let pageView = UICollectionView(frame: frame, collectionViewLayout: layout)
        layout.itemSize = pageView.frame.size
        pageView.delegate = self
        pageView.dataSource = self
        pageView.register(AHBannerCell.self, forCellWithReuseIdentifier: AHBannerCellID)
        pageView.showsHorizontalScrollIndicator = false
        pageView.bounces = false
        pageView.backgroundColor = UIColor.clear
        return pageView
    }()
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        var frame: CGRect = self.bounds
        if self.bannerStyle.showPageControl && self.bannerStyle.isPageControlSeparated {
            frame.size.height = self.bounds.height - self.bannerStyle.bottomHeight
        }
        pageView.frame = frame
        let layout = pageView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = pageView.frame.size
    }
    
}


public extension AHBannerView {
    func refresh() {
        pageView.reloadData()
        if bannerStyle.isInfinite {
            scrollToMiddleFirst()
        }
        delegate?.bannerView(self, didSwitch: 0)
        didSwitchCallback?(0)
        if bannerStyle.isAutoSlide {
            fireTimer()
        }
    }
    
    func setup(imageCount: Int, Style: AHBannerStyle) {
        self.bannerStyle = Style
        if self.bannerStyle.isInfinite == false || self.bannerStyle.isPagingEnabled == false {
            self.bannerStyle.isAutoSlide = false
        }
        pageView.isPagingEnabled = self.bannerStyle.isPagingEnabled
        self.imageCount = imageCount
        
        addSubview(pageView)
        addSubview(indicatorView)
        
        if bannerStyle.showIndicator {
            indicatorView.isHidden = false
            indicatorView.frame.size.height = bannerStyle.bottomHeight
            indicatorView.frame.size.width = bounds.width / CGFloat(imageCount)
            indicatorView.frame.origin.x = 0.0
            indicatorView.frame.origin.y = bounds.height - bannerStyle.bottomHeight
            indicatorView.backgroundColor = bannerStyle.indicatorColor
        }else{
            indicatorView.isHidden = true
        }
        
        // if user provides pageControl
        if bannerStyle.showPageControl {
            
            if pageControl == nil {
                pageControl = UIPageControl()
                addSubview(pageControl)
            }
            self.pageControl.numberOfPages = imageCount
            self.pageControl.currentPage = 0
            self.pageControl.frame.size.height = bannerStyle.bottomHeight
            self.pageControl.frame.size.width = self.bounds.width
            let y: CGFloat = self.bounds.height - bannerStyle.bottomHeight
            self.pageControl.frame.origin = .init(x: 0, y: y)
            self.pageControl.pageIndicatorTintColor = bannerStyle.pageControlColor
            self.pageControl.currentPageIndicatorTintColor = bannerStyle.pageControlSelectedColor
            self.pageControl.isUserInteractionEnabled = false
            
        }
        self.refresh()
        
    }
    
    func didSwitch(callBack: @escaping (_ toIndex: Int) -> Void) {
        self.didSwitchCallback = callBack
    }
    
    func didTapped(callback :@escaping (_ atIndex: Int) -> Void) {
        self.didTappedCallback = callback
    }
}


private extension AHBannerView {
    func fireTimer() {
        guard bannerStyle.isAutoSlide else {
            return
        }
        if timer != nil {
            timer?.invalidate()
        }
        timer = Timer(timeInterval: bannerStyle.timeInterval, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    @objc func updateTimer() {
        guard bannerStyle.isAutoSlide else {
            stopTimer()
            return
        }
        next()
    }
    
    func next() {
        let offsetX = pageView.contentOffset.x + pageView.bounds.width
        let point = CGPoint(x: offsetX, y: 0.0)
        pageView.setContentOffset(point, animated: true)
    }
}

extension AHBannerView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.bannerView(self, didTapped: indexPath.row)
        didTappedCallback?(indexPath.row)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? AHBannerCell {
            if cell.imageView.image == nil {
                // if there's no image yet, show placeholder
                cell.imageView.image = bannerStyle.placeholder
            }
        }
    }
    
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let point = scrollView.contentOffset
        guard let currentIndexPath = pageView.indexPathForItem(at: point) else {return}
        if self.currentIndexPath != currentIndexPath {
            indicatorView.frame.origin.x = CGFloat(currentIndexPath.row) * indicatorView.frame.width
        }
        if let pageControl = self.pageControl {
            pageControl.currentPage = currentIndexPath.row
        }
        self.currentIndexPath = currentIndexPath
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // triggerd when user finished actively dragging the scrollView
        resetPage(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // triggered when setting contentOffset programatically with animation
        resetPage(scrollView)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // remove timer
        stopTimer()
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            // scrollView is slowing down here
            // add timer
            if bannerStyle.isAutoSlide {
                fireTimer()
            }
        }
    }
    
    fileprivate func resetPage(_ scrollView: UIScrollView) {
        guard bannerStyle.isInfinite else {
            return
        }
        let point = scrollView.contentOffset
        guard let currentIndexPath = pageView.indexPathForItem(at: point) else {return}
        if currentIndexPath != finalIndexPath {
            finalIndexPath = currentIndexPath
            delegate?.bannerView(self, didSwitch: finalIndexPath.row)
            didSwitchCallback?(finalIndexPath.row)
        }
        
        if currentIndexPath.section == 0 && currentIndexPath.row == 0 {
            // first section, first row
            scrollToMiddleFirst()
        }else if currentIndexPath.section == (sectionCount - 1) && currentIndexPath.row == (imageCount - 1){
            // last section, last row
            scrollToMiddleLast()
        }
    }
    
    // scroll to middle section, last row
    fileprivate func scrollToMiddleLast() {
        let toIndexPath = IndexPath(item: imageCount - 1, section: middleSection)
        // turn off animation so that scrollViewDidEndDecelerating and scrollViewDidEndScrollingAnimation won't be triggered.
        pageView.scrollToItem(at: toIndexPath, at: .left, animated: false)
    }
    // scroll to middle section, first row
    fileprivate func scrollToMiddleFirst() {
        let toIndexPath = IndexPath(item: 0, section: middleSection)
        // turn off animation so that scrollViewDidEndDecelerating and scrollViewDidEndScrollingAnimation won't be triggered.
        pageView.scrollToItem(at: toIndexPath, at: .left, animated: false)
    }
    
}

extension AHBannerView: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        // if it's not infinite, then there's only 1 section to display
        return bannerStyle.isInfinite ? sectionCount : 1
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageCount
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AHBannerCellID, for: indexPath) as! AHBannerCell
        cell.backgroundColor = UIColor.clear
        cell.imageView.image = nil
        cell.imageView.contentMode = .scaleAspectFit
        cell.clipsToBounds = true
        self.index = indexPath.row
        delegate?.bannerViewForImage(self, imageView: cell.imageView, atIndex: indexPath.row)
        return cell
    }
}


fileprivate class AHBannerCell: UICollectionViewCell {
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    func initSubviews() {
        contentView.addSubview(imageView)
        //        contentView.addSubview(titleLabel)
    }
    
    func setup() {
        imageView.frame = self.bounds
        //        titleLabel.center = imageView.center
        //        titleLabel.textAlignment = .center
        //        titleLabel.backgroundColor = UIColor.red
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
}





