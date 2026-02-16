//
//  WordpressSwiftViewController.swift
//  Universal
//
//  Created by Mark on 03/03/2018.
//  Copyright © 2018 Sherdle. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import AVFoundation
import LPSnackbar

final class VideoViewController: HideableCollectionViewController, UISearchBarDelegate{
    
    var params: [String]!
    var estimateWidth = 300.0
    var cellMarginSize = 1
    
    var isWordpress: Bool = false
    var isVimeo: Bool = false
    
    //options: PostCellImmersive.identifier, PostCellLarge.identifier, PostCellCompact.identifier
    let postType = PostCellImmersive.identifier
    
    var sizingHelper = SizingHelper.init()
    
    var nextPageToken: String?
    var page = 0
    var canLoadMore = true
    var query: String?
    
    var refresher: UIRefreshControl?
    
    var items = [Video]()
    
    var footerView: FooterView?
    var categorySlider: PostCategorySlider?
    var searchButton: UIBarButtonItem?
    var cancelButton: UIBarButtonItem?
    var searchBar: UISearchBar?
    
    var wordpressClient: WordpressSwift?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Navigation Drawer
        self.collectionView?.addGestureRecognizer(self.revealViewController()?.panGestureRecognizer() ?? UIGestureRecognizer())
        self.collectionView?.addGestureRecognizer(self.revealViewController()?.tapGestureRecognizer() ?? UITapGestureRecognizer())
        
        wordpressClient = WordpressSwift.init()
        
        setupSearch()
        setupRefresh()
        loadProducts()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupGridView()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        sizingHelper.clearCache()
        self.collectionViewLayout.invalidateLayout()
        
        //coordinator.animate(alongsideTransition: { (_) in
        // layout update
        //}, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {        
        performSegue(withIdentifier: "showVideo", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVideo" {
            if let nextViewController = segue.destination as? VideoDetailViewController{
                nextViewController.video = self.items[(self.collectionView?.indexPathsForSelectedItems![0].item)!]
                nextViewController.params = params
            }
        } 
    }
    
    func setupSearch() {
        if (params![1] == "playlist") { return }
        
        searchButton = UIBarButtonItem.init(barButtonSystemItem:UIBarButtonItem.SystemItem.search, target: self, action: #selector(searchClicked))
        
        self.navigationItem.titleView = nil
        self.navigationItem.rightBarButtonItems = [searchButton!]
        
        cancelButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(searchBarCancelButtonClicked))
        
        searchBar = UISearchBar.init()
        self.searchBar?.searchBarStyle = UISearchBar.Style.default
        self.searchBar?.placeholder = NSLocalizedString("search", comment: "")
        self.searchBar?.delegate = self
    }
    
    func setupGridView() {
        let flow = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        if #available(iOS 11.0, *) {
            flow.sectionInsetReference = .fromSafeArea
        }
        
        let nibCompact = UINib(nibName: PostCellCompact.identifier, bundle: nil)
        collectionView?.register(nibCompact, forCellWithReuseIdentifier: PostCellCompact.identifier)
        
        flow.minimumInteritemSpacing = CGFloat(self.cellMarginSize)
        flow.minimumLineSpacing = CGFloat(self.cellMarginSize)
    }
    
    func setupRefresh(){
        self.collectionView!.alwaysBounceVertical = true
        refresher = UIRefreshControl()
        refresher!.addTarget(self, action: #selector(refreshCalled), for: .valueChanged)
        collectionView!.refreshControl = refresher;
    }
    
    // tell the collection view how many cells to make
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    // make a cell for each cell index path
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.identifierForPath(indexPath: indexPath), for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        
        if indexPath.row == items.count - 1 && canLoadMore {
            loadProducts()
        }
        
        return cell
        
    }
    
    func configureCell(cell: UICollectionViewCell, indexPath: IndexPath) {
        if var annotateCell = cell as? PostCell {
            annotateCell.video = self.items[indexPath.item]
        }
    }
    
    func identifierForPath(indexPath: IndexPath) -> String {
        if (indexPath.item == 0){
            return PostCellImmersive.identifier
        }
        
        return self.postType
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                         withReuseIdentifier: "Footer", for: indexPath) as? FooterView
            footerView?.activityIndicator.startAnimating()
            return footerView!
        default:
            assert(false, "Unexpected element kind")
        }
        
        //Satisfy damn constraints
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    @objc func refreshCalled() {
        reset()
        self.collectionView?.reloadData()
        loadProducts()
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func loadProducts() {
        if (isWordpress) {
            self.page += 1
            
            let requestParams = RequestParams.init()
            requestParams.page = self.page
            if ((query) != nil) {
                requestParams.searchQuery = query!
            }
            if (params.count > 1 && !(params[1]).isEmpty){
                requestParams.category = params[1]
            }
            
            wordpressClient?.get(blogURL: params![0], params: requestParams, forType: WPPost.self, completionHandler: { (success, posts) in
                if (!success) {
                    
                    if (self.items.count == 0) {
                        self.handleNoResults()
                    }
                }
                
                var needsCompletionLater = false;
                
                if let results = posts {

                    for result in results {
                        let post = result as! WPPost
                        if (!post.attachmentsIncomplete) {
                            var videoAtt: WPAttachment?
                            for att in post.attachments {
                                if ((att.mime?.contains("video/"))!){
                                    videoAtt = att
                                    break
                                }
                            }
                            
                            if (videoAtt != nil){
                                self.items.append(self.parseVideoFromPost(post: post, videoAtt: videoAtt))
                            }
                        } else {
                            needsCompletionLater = true;
                            
                            post.completedAction = { value in
                                var videoAtt: WPAttachment?
                                for att in post.attachments {
                                    if ((att.mime?.contains("video/"))!){
                                        videoAtt = att
                                        break
                                    }
                                }
                                
                                if (videoAtt != nil){
                                    self.items.append(self.parseVideoFromPost(post: post, videoAtt: videoAtt))
                                    
                                    self.collectionView?.reloadData()
                                    self.collectionView?.layoutIfNeeded()
                                }
                            }
                        }
                    }
                    
                    
                    if (!needsCompletionLater){
                        self.collectionView?.reloadData()
                    }
                    self.handleResults(cantLoadMore: results.count == 0)
                }
                
                return
            })
        } else if isVimeo {
        
            if page == 0 {
                page = 1
            }
            
            var parameter: String?
            var type: VimeoClient.RequestType?
            if (params[1] == "user") {
                parameter = params![0]
                type = .user
            } else if (params[1] == "album") {
                parameter = params![0]
                type = .album
            }
            VimeoClient.getResults(parameter: parameter!, type: type!, search: query, page: page) { (success, hasNextPage, results) in
                if (!success) {
                    if (self.items.count == 0) {
                        self.handleNoResults()
                    }
                } else {
                    self.page = self.page + 1
                    self.items += results
               
                    self.handleResults(cantLoadMore: !hasNextPage)
                    
                }
            }
        } else {
            
            var parameter: String?
            var type: YoutubeClient.RequestType?
            if (query != nil) {
                parameter = params![0]
                type = .query
            } else if (params[1] == "playlist") {
                parameter =  params![0]
                type = .playlist
            } else if (params[1] == "channel") {
                parameter =  params![0]
                type = .channel
            } else if (params[1] == "live") {
                parameter =  params![0]
                type = .live
            }
            
            //Warn users with outdated configurations
            if (params.count < 3 || params[2].isEmpty) {
                let snack = LPSnackbar(title:"No API key in config.json, please update your config.json file", buttonTitle: "OK")
                snack.show(animated: true)
                
                return
            }
            
            YoutubeClient.getResults(identifier: parameter!, apiKey: params[2], type: type!, search: query, pageToken: nextPageToken) { (success, nextPageToken, results) in
                if (!success) {
                    if (self.items.count == 0) {
                        self.handleNoResults()
                    }
                } else {
                    self.nextPageToken = nextPageToken
                    self.items += results
               
                    self.handleResults(cantLoadMore: nextPageToken == nil)
                    
                }
            }
        }
    }
    
    func handleNoResults() {
        let alertController = UIAlertController.init(title: NSLocalizedString("error", comment: ""), message: AppDelegate.NO_CONNECTION_TEXT, preferredStyle: UIAlertController.Style.alert)
        
        let ok = UIAlertAction.init(title: NSLocalizedString("ok", comment: ""), style: UIAlertAction.Style.default, handler: nil)
        alertController.addAction(ok)
        self.present(alertController, animated: true, completion: nil)
        
        self.footerView?.isHidden = true
    }
    
    func handleResults(cantLoadMore: Bool){
         if (cantLoadMore) {
             self.canLoadMore = false
             self.footerView?.isHidden = true
         }
         
         self.collectionView?.reloadData()
         self.refresher?.endRefreshing()
    }
    
    
    @objc func searchClicked() {
        //[self setPullToRefreshEnabled:false];
        searchBar?.resignFirstResponder()
        searchButton?.isEnabled = false
        searchButton?.tintColor = UIColor.clear
        
        self.navigationItem.rightBarButtonItems = [cancelButton!]
        cancelButton?.tintColor = nil
        
        self.navigationItem.titleView = searchBar
        searchBar?.alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            self.searchBar?.alpha = 1.0
        }
        searchBar?.becomeFirstResponder()
    }
    
    @objc func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //[self setPullToRefreshEnabled:true];
        
        UIView.animate(withDuration: 0.2, animations: {
            self.searchBar?.alpha = 0.0
            self.cancelButton?.tintColor = UIColor.clear
        }, completion:{ _ in
            self.navigationItem.titleView = nil
            self.navigationItem.rightBarButtonItems = [self.searchButton!]
            UIView.animate(withDuration: 0.2, animations: {
                self.searchButton?.isEnabled = true
                self.searchButton?.tintColor = nil
            })
        })
        
        //Reset
        reset()
        
        query = nil
        loadProducts()
        self.collectionView?.reloadData()
    }
    
    @objc func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        reset()
        
        searchBar.endEditing(true)
        query = searchBar.text
        loadProducts()
        self.collectionView?.reloadData()
    }
    
    func reset(){
        items.removeAll()
        nextPageToken = nil
        canLoadMore = true
        self.page = 0
        footerView?.isHidden = false
    }
    
    func parseVideoFromPost(post: WPPost, videoAtt: WPAttachment?) -> Video {
        let video = Video.init()
        video.title = post.title!
        if let medium = post.thumbnail.url, medium.count > 0  {
            video.thumbnails.medium.url = medium
        }
        if let high = post.featured_media.url, high.count > 0  {
            video.thumbnails.high.url = high
        }
        video.authorTitle = post.author.name!
        video.description = post.content
        video.publishedAt = post.date
        video.directUrl = (videoAtt?.url)!
        video.link = post.link
        
        return video
    }
    
    static func getThumbnailImageFromVideoUrl(url: String, completion: @escaping ((_ image: UIImage?)->Void)) {
        DispatchQueue.global().async { //1
            let asset = AVAsset(url:URL(string:  url)!) //2
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset) //3
            avAssetImageGenerator.appliesPreferredTrackTransform = true //4
            let thumnailTime = CMTimeMake(value: 2, timescale: 1) //5
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) //6
                let thumbImage = UIImage(cgImage: cgThumbImage) //7
                DispatchQueue.main.async { //8
                    completion(thumbImage) //9
                }
            } catch {
                print(error.localizedDescription) //10
                DispatchQueue.main.async {
                    completion(nil) //11
                }
            }
        }
    }
    
}

extension VideoViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if (identifierForPath(indexPath: indexPath) == PostCategorySlider.identifierX) {
            let width = CGFloat(self.collectionView!.frame.size.width)
            return CGSize(width: width, height: 45.0)
        } else if (identifierForPath(indexPath: indexPath) == PostCellLarge.identifier) {
            let width = self.calculateWith()
            return CGSize(width: width, height: width * CGFloat(PostCellLarge.widthHeightRatio))
        } else if (identifierForPath(indexPath: indexPath) == PostCellImmersive.identifier) {
            //For header immersive items, we use full width
            if (indexPath.item == 0) {
                let width = CGFloat(self.collectionView!.frame.size.width)
                return CGSize(width: width, height: width * (9/16))
            }
            
            let width = self.calculateWith()
            return CGSize(width: width, height: width * 9/16)
        } else {
            return sizingHelper.getSize(indexPath: indexPath, identifier: identifierForPath(indexPath: indexPath), forWidth: self.calculateWith(), with: configureCell(cell:indexPath:))
        }
    }
    
    public func calculateWith() -> CGFloat {
        let estimatedWidth = CGFloat(estimateWidth)
        let cellCount = floor(CGFloat(self.collectionView!.frame.size.width / estimatedWidth))
        
        let width = (self.view.safeAreaLayoutGuide.layoutFrame.width - CGFloat(cellMarginSize * 2) * (cellCount - 1)) / cellCount
        
        return width
    }
}

