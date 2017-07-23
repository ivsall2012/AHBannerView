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
}

open class AHBannerView: UIView {
    public weak var delegate: AHBannerViewDelegate?
    
    public var timeInterval: TimeInterval = 5
    
    public var showIndicator = true
    public var indicatorColor = UIColor.red
    public var indicatorHeight: CGFloat = 3.0
    public var placeholder: UIImage?
    public var isAutoSlide = true
    public var pageControl: UIPageControl
    
    
    fileprivate var imageCount: Int = 0
    fileprivate lazy var indicatorView: UIView = {
        let y = self.bounds.height - self.indicatorHeight
        // only x and width is uncertain at this point
        let frame = CGRect(x: 0, y: y, width: 0.0, height: self.indicatorHeight)
        let view = UIView(frame: frame)
        view.backgroundColor = self.indicatorColor
        return view
    }()
    fileprivate var didTappedCallback: ((_ atIndex: Int) -> Void)?
    fileprivate var didSwitchCallback: ((_ toIndex: Int) -> Void)?
    
    fileprivate var imageViewCallback: ((_ imageView: UIImageView, _ atIndex: Int) -> Void)?
    
    // sectionCount must be larger than 2.
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
    fileprivate lazy var pageView: UICollectionView =  {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = self.bounds.size
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        let pageView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        pageView.delegate = self
        pageView.dataSource = self
        pageView.register(AHBannerCell.self, forCellWithReuseIdentifier: AHBannerCellID)
        pageView.showsHorizontalScrollIndicator = false
        pageView.isPagingEnabled = true
        pageView.bounces = false
        return pageView
    }()
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(pageView)
        addSubview(indicatorView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(pageView)
        addSubview(indicatorView)
    }

}


public extension AHBannerView {
    func refresh() {
        
        
        pageView.reloadData()
        scrollToMiddleFirst()
        delegate?.bannerView(self, didSwitch: 0)
        didSwitchCallback?(0)
        fireTimer()
    }
    
    func setup(imageCount: Int,imageCallback : @escaping ((_ imageView: UIImageView, _ atIndex: Int) -> Void)) {
        self.imageCount = imageCount
        imageViewCallback = imageCallback
        
        if showIndicator {
            indicatorView.isHidden = false
            indicatorView.frame.size.width = bounds.width / CGFloat(imageCount)
        }else{
            indicatorView.isHidden = true
        }
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
        guard isAutoSlide else {
            return
        }
        timer = Timer(timeInterval: timeInterval, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .defaultRunLoopMode)
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    @objc func updateTimer() {
        guard isAutoSlide else {
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
                cell.imageView.image = self.placeholder
            }
        }
    }
    
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let point = scrollView.contentOffset
        guard let currentIndexPath = pageView.indexPathForItem(at: point) else {return}
        if self.currentIndexPath != currentIndexPath {
            indicatorView.frame.origin.x = CGFloat(currentIndexPath.row) * indicatorView.frame.width
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
            if isAutoSlide {
                fireTimer()
            }
        }
    }
    
    fileprivate func resetPage(_ scrollView: UIScrollView) {
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
        return sectionCount
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageCount
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AHBannerCellID, for: indexPath) as! AHBannerCell
        cell.backgroundColor = UIColor.clear
        cell.imageView.contentMode = .scaleAspectFit
        cell.clipsToBounds = true
        imageViewCallback?(cell.imageView, indexPath.row)
        return cell
    }
}


fileprivate class AHBannerCell: UICollectionViewCell {
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()


//    var titleLabel: UILabel = {
//        let titleLabel = UILabel()
//        titleLabel.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
//        return titleLabel
//    }()
    
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





