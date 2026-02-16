import UIKit
import SDWebImage
import FeedKit

class PostCellImmersive: UICollectionViewCell, PostCell {
    
    public static var widthHeightRatio = 0.50
    public static let identifier = "PostCellImmersive"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.masksToBounds = true
    }
    
    var post: WPPost? {
        didSet {
            if let post = post {
                if let image = post.featured_media.url {
                    imageView.sd_setImage(with: URL(string: image))
                }
                captionLabel.text = String(htmlEncodedString: post.title!)
                dateLabel.text = post.date
            }
        }
    }
    
    var item: RSSFeedItem? {
        didSet {
            if let item = item {
                if let image = item.getImageUrl() {
                    imageView.sd_setImage(with: URL(string: image))
                }
                captionLabel.text = String(htmlEncodedString: item.title!)
                dateLabel.text = item.pubDate!.toString()
            }
        }
    }
    
    var video: Video? {
        didSet {
            if let item = video {
                if let thumbnail = item.thumbnails.high.url {
                    imageView.sd_setImage(with: URL(string: thumbnail))
                } else if let videoUrl = item.directUrl {
                    VideoViewController.getThumbnailImageFromVideoUrl(url: videoUrl) { (thumbImage) in
                        self.imageView.image = thumbImage
                    }
                }
                captionLabel.text = String(htmlEncodedString: (item.title)!)
                dateLabel.text = item.publishedAt
            }
        }
    }
    
    var audio: SoundCloudSong? {
        didSet { }
        //STUB
    }
    
    var tab: Tab? {
        didSet {
            if let tab = tab {
                imageView.sd_setImage(with: URL(string: (tab.icon)!))
                captionLabel.text = tab.name
                dateLabel.text = ""
            }
        }
    }
    
}
