# AHBannerView
#### 1. Show a bar indicator at the bottom
![](https://github.com/ivsall2012/AHBannerView/blob/master/indicator_demo.gif)

#### 2. Show a page control at the bottom
![](https://github.com/ivsall2012/AHBannerView/blob/master/pageControl_demo.gif)

## Usage
### Setps:
1. Create a AHBannerView instance with a frame and a AHBannerStyle with your desired configurations.
2. Setup the AHBannerView with an imageCount and the AHBannerStyle you just created
3. Add the AHBannerView to a view.
4. Assign and implement the delegate.

### Example Codes
#### 1. Basic Code
```Swift
/// Create a AHBannerView
let bannerFrame = CGRect(x: 0, y: 64.0, width: self.view.bounds.width, height: 200.0)
        bannerView = AHBannerView(frame: bannerFrame)

/// Create a style
var style = AHBannerStyle()
   /// NOTE: This placeholder only appears when you haven't assigned a image for a imageView passed in the delegate method.
style.placeholder = UIImage(named: "placeholder")
style.isAutoSlide = true
//        style.isInfinite = false
//        style.isPagingEnabled = false
style.timeInterval = 1

/// Assigning delegate and add the bannerView to a view
bannerView.delegate = self
self.view.addSubview(bannerView)
```

#### 2.1 Style A: Show the bar indicator
```Swift
style.bottomHeight = 5.0

style.showIndicator = true
style.showPageControl = false
style.indicatorColor = UIColor.red
        
style.showPageControl = false
```

#### 2.2 Style B: Show the page control
```Swift
style.bottomHeight = 25.0

style.showIndicator = false

style.showPageControl = true
style.showIndicator = false
style.pageControlColor = UIColor.gray
style.pageControlSelectedColor = UIColor.red
```

#### 3. Implement the delegate in order to tell AHBannerView what to disdplay for each banner
```Swift
/// NOTE: The this/that URL guard statement in the following, is for preventing images being mismatched and assigned to the wrong imageView, when the inital imageView being recyled before the initial image request callback gets called. It's the same idea applied when you deal with tableView/collectionView cells. 
func bannerViewForImage(_ bannerView: AHBannerView, imageView: UIImageView, atIndex: Int) {
  let thisURL = URL(string: self.images[atIndex])
  imageView.contentMode = .scaleAspectFill
  imageView.sd_setImage(with: thisURL) {[weak self] (image, _, _, thatURL) in
    guard self != self else {return}
    /// See the note above
    guard thisURL == thatURL else {return}
    guard let image = image else {return}
    imageView.image = image
        }
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

AHBannerView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AHBannerView"
```

## Author

Andy Tong, ivsall2012@gmail.com

## License

AHBannerView is available under the MIT license. See the LICENSE file for more info.
