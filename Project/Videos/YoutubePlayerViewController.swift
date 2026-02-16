//
//  YoutubePlayerViewController.swift
//  Universal
//
//  Created by Mark on 14/08/2021.
//  Copyright © 2021 Sherdle. All rights reserved.
//

import Foundation

import UIKit
import youtube_ios_player_helper


final class YoutubePlayerViewController: UIViewController, YTPlayerViewDelegate {
    
    public var videoId: String?

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var playerView: YTPlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.load(withVideoId: videoId!);
        playerView.delegate = self;
    }
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        loadingIndicator.stopAnimating()
        playerView.playVideo()
    }
    
}
