import AHBannerView
import SDWebImage


let imageURL_1 = "https://images.unsplash.com/photo-1505461560638-05d8740c0a73?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1242&h=540&fit=crop&s=f697ba12e9959ab92a785bdd792788f1"
let imageURL_2 = "https://images.unsplash.com/photo-1507138451611-3001135909fa?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1242&h=540&fit=crop&s=f0da2b0cbf8dd3ac1feb26da4af57a97"
let imageURL_3 = "https://images.unsplash.com/photo-1506475018410-16e2665d1a90?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1242&h=540&fit=crop&s=455e0b5aadd709080cfdd28fe699dfa4"

let imageURL_4 = "https://images.unsplash.com/photo-1507317688543-678604fef4a0?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1242&h=540&fit=crop&s=a1e2900cd21a406e1b86ffd06d71dbbc"

class ViewController: UIViewController {
    var bannerView: AHBannerView!
    let images = [imageURL_1,imageURL_2,imageURL_3,imageURL_4]
    var style = AHBannerStyle()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "AHBannerView"
        
        let bannerFrame = CGRect(x: 0, y: 64.0, width: self.view.bounds.width, height: 200.0)
        bannerView = AHBannerView(frame: bannerFrame)
        
        style.placeholder = UIImage(named: "placeholder")
        style.isAutoSlide = true
        //        style.isInfinite = false
        //        style.isPagingEnabled = false
        style.timeInterval = 1
        
//        showIndicatorSettings()
        showPageControlSettings()
        
        
        bannerView.setup(imageCount: self.images.count, Style: style)
        bannerView.delegate = self
        
        self.view.addSubview(bannerView)
    }
    
    func showIndicatorSettings() {
        style.bottomHeight = 5.0
        style.showIndicator = true
        style.showPageControl = false
        style.indicatorColor = UIColor.red
        
        
        style.showPageControl = false
    }
    
    func showPageControlSettings() {
        style.bottomHeight = 25.0
        
        style.showIndicator = false
        
        style.showPageControl = true
        style.showIndicator = false
        style.pageControlColor = UIColor.gray
        style.pageControlSelectedColor = UIColor.red
        
    }
    
    
}

extension ViewController: AHBannerViewDelegate {
    func bannerViewForImage(_ bannerView: AHBannerView, imageView: UIImageView, atIndex: Int) {
        let thisURL = URL(string: self.images[atIndex])
        imageView.contentMode = .scaleAspectFill
        imageView.sd_setImage(with: thisURL) {[weak self] (image, _, _, thatURL) in
            guard self != self else {return}
            /// NOTE: The folowing guard statement is for preventing images being mismatched and assigned to the wrong imageView, when the inital imageView being recyled before the initial image request callback gets called.
            /// It's the same idea applied when you deal with tableView/collectionView cells.
            guard thisURL == thatURL else {return}
            guard let image = image else {return}
            imageView.image = image
        }
    }
    func bannerView(_ bannerView: AHBannerView, didSwitch toIndex: Int) {
                print("bannerView -> didSwitch:\(toIndex)")
    }
    func bannerView(_ bannerView: AHBannerView, didTapped atIndex: Int) {
                print("bannerView -> didTapped:\(atIndex)")
    }
}
