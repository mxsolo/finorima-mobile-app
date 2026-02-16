import UIKit
import SDWebImage
import Cosmos
import WebKit
import LPSnackbar
import AVKit
import AVFoundation
import KVOController

final class VideoDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, WKNavigationDelegate {
    
    // MARK: Properties
    
    static private let hideRelated = false

    var video: Video!
    var params:  [String]!
    
    var related = [Video]()
    
    @IBOutlet weak var contentWebView: WKWebView!
    @IBOutlet weak var contentWebViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var relatedLabel: UILabel!
    @IBOutlet weak var relatedCollection: UICollectionView!
    @IBOutlet weak var relatedCollectionHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var nameLabel: UILabel!

    @IBOutlet private weak var subTitleLabel: UILabel!

    @IBOutlet private weak var imageView: ImageView!
    
    @IBOutlet private weak var postActionButton: UIButton!
    
    func playVideo() {
        
        if let videoIdentifier = video.youtubeId {
            
            let vc = (storyboard?.instantiateViewController(withIdentifier: "YoutubePlayerViewController"))! as? YoutubePlayerViewController
            vc!.videoId = videoIdentifier;
                    //vc.modalPresentationStyle = .fullScreen
            present(vc!, animated: true, completion: nil)
            
        } else {
            let playerViewController = AVPlayerViewController()
            self.present(playerViewController, animated: true, completion: nil)
            
            if let vimeoId = video.vimeoId {
            HCVimeoVideoExtractor.fetchVideoURLFrom(id: vimeoId, completion: { [weak playerViewController]  ( video:HCVimeoVideo?, error:Error?) -> Void in
                if let err = error {
                    print("Error = \(err.localizedDescription)")
                    return
                }
                
                guard let vid = video else {
                    print("Invalid video object")
                    return
                }
                                
                DispatchQueue.main.async {
                
                    if let videoURL = vid.videoURL[.Quality1080p] {
                        let player = AVPlayer(url: videoURL)
                        playerViewController!.player = player
                        player.play()
                    }
                }
            })
            } else {
                playerViewController.player = AVPlayer(url: URL(string: video.directUrl!)!)
                playerViewController.player?.play()
            }
        }
    }
    
    @IBAction func postActionButtonTapped(_ sender: Any) {
        playVideo()
    }

    @objc private func shareButtonTapped() {
        let objectsToShare = [video.link!]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        if let wPPC = activityVC.popoverPresentationController {
            wPPC.barButtonItem = navigationItem.rightBarButtonItems![0]
        }
        
        self.present(activityVC, animated: true, completion: nil)
    }

    // MARK: View Life Cycle
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let nc = self.navigationController as! TabNavigationController
        nc.turnTransparency(on: false, animated: true);
        //nc.getGradientView().turnTransparency(on: false, animated: true, tabController: self.navigationController)
    }
    
    func initWebView(withBody: String) {
        let path = Bundle.main.path(forResource: "style", ofType: "css")
        if let style = try? String(contentsOfFile: path!, encoding: String.Encoding.utf8){
        
            let htmlStyling = String(format: "<html>" +
                "<head>" +
                "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=0\" />" +
                "<style type=\"text/css\">" +
                "%@" +
                "</style>" +
                "</head>" +
                "<body>" +
                "<p>%@</p>" +
                "</body></html>", style, withBody);
    
            contentWebView.loadHTMLString(htmlStyling, baseURL: nil)
            contentWebView.scrollView.isScrollEnabled = false
            contentWebView.navigationDelegate = self
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.contentWebView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
            if complete != nil {
                self.contentWebView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
                    self.contentWebViewHeight.constant = height as! CGFloat
                })
            }
            
        })
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        if (VideoDetailViewController.hideRelated){
            hideRelated()
        } else {
            setupRelated()
        }
        self.scrollView.delegate = self
        
        // Customize the navigation bar.
        if (hasHeaderImage()){
            let nc = self.navigationController as! TabNavigationController
            nc.turnTransparency(on: true, animated: true);
            //nc.getGradientView().turnTransparency(on: true, animated: true, tabController: self.navigationController)
        }

        let shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(VideoDetailViewController.shareButtonTapped))
        let rightItems = [shareButton]
        navigationItem.rightBarButtonItems = rightItems

        nameLabel.text = String(htmlEncodedString: (video.title)!)
        
        //WebView
        initWebView(withBody: (video.description)!)
        
        subTitleLabel.text = String(format: NSLocalizedString("date_author", comment: ""), (video.authorTitle)!, (video.publishedAt)!)

        // Load the image from the network and give it the correct aspect ratio.
        if (hasHeaderImage()) {
            imageView.sd_imageTransition = SDWebImageTransition.fade;
            if let thumbnail = video.thumbnails.high.url {
                imageView.sd_setImage(with: URL(string: thumbnail), placeholderImage: UIImage(named: "default_placeholder"), options: [], completed: { (image, error, cache, url) in
                    //self.imageView.updateAspectRatio()
                })
            } else if let videoUrl = video.directUrl {
                VideoViewController.getThumbnailImageFromVideoUrl(url: videoUrl) { (thumbImage) in
                    self.imageView.image = thumbImage
                }
            }
            
        } else {
            imageView.isHidden = true
            postActionButton.isHidden = true
        }

        // Decorate the button.
        postActionButton.round()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func hasHeaderImage() -> Bool {
        return true
    }
    
    func setupRelated() {
        relatedCollection.delegate = self
        relatedCollection.dataSource = self
        let flow = relatedCollection.collectionViewLayout as! UICollectionViewFlowLayout
        flow.scrollDirection = UICollectionView.ScrollDirection.horizontal
        relatedCollection.collectionViewLayout = flow
        if #available(iOS 11.0, *) {
            flow.sectionInsetReference = .fromSafeArea
        }
        loadRelatedposts()
    }
    
    func loadRelatedposts() {
        
        if let videoId = video.youtubeId {
        
            //GET https://www.googleapis.com/youtube/v3/search?part=snippet&relatedToVideoId=5rOiW_xY-kc&type=video&key={YOUR_API_KEY}

            YoutubeClient.getResults(identifier: videoId, apiKey: params[2], type: YoutubeClient.RequestType.related, search: nil, pageToken: nil) { (success, nextPageToken, results) in
                if (!success) {
                    self.hideRelated()
                    return
                } else {
                    self.related += results
                    self.relatedCollection.reloadData()
                    
                }
            }
        } else {
            self.hideRelated()
        }
    }
    
    func hideRelated(){
        self.relatedCollection.isHidden = true
        self.relatedLabel.isHidden = true
        self.relatedCollectionHeight.constant = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVideo"{
            if let nextViewController = segue.destination as? VideoDetailViewController{
                nextViewController.video = self.related[(self.relatedCollection?.indexPathsForSelectedItems![0].item)!]
                nextViewController.params = self.params
            }
        }
    }
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.related.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath)
        if let annotateCell = cell as? PostCellLarge {
            annotateCell.video = self.related[indexPath.item]
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = self.relatedCollection.frame.size.height - 20
        let widthHeightRatio = PostCellLarge.widthHeightRatioRelatedVideo
        return CGSize(width: height / CGFloat(widthHeightRatio), height: height)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if ((navigationAction.request.url?.absoluteString.contains("http"))! && (navigationAction.targetFrame?.isMainFrame)!){
            AppDelegate.openUrl(url: navigationAction.request.url?.absoluteString, withNavigationController: self.navigationController)
            decisionHandler(WKNavigationActionPolicy.cancel);
        } else {
            decisionHandler(WKNavigationActionPolicy.allow);
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == relatedCollection) { return }
        if (!hasHeaderImage()){ return }
        
        let nc = self.navigationController as? TabNavigationController
        let transparent = scrollView.contentOffset.y < self.imageView.frame.size.height - ((nc?.getNavigationBarHeight() != nil) ? (nc?.getNavigationBarHeight())! : 0);
        nc?.turnTransparency(on: transparent, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}
