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
import FRadioPlayer
import MediaPlayer

final class RadioSwiftViewController: UIViewController, FRadioPlayerDelegate{

    var params: [String]!
    let player = FRadioPlayer.shared
    
    static var meta: (URL?, String?, String?)?
    
    @IBOutlet weak var imageView: UIImageView!
    var realImageView: UIImageView?
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var playButtonImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    
    @IBAction func playPauseClicked(_ sender: Any) {
        if (player.isPlaying) {
            player.pause()
        } else {
            player.play()
        }
        updatePlayImage()
    }
    
    func updatePlayImage(){
        if (player.isPlaying){
            playButtonImage.image = UIImage(named: "pause.png")
        } else {
            playButtonImage.image = UIImage(named: "play.png")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //navigationController?.navigationBar.prefersLargeTitles = true
        
        // Navigation Drawer
        self.view.addGestureRecognizer((self.revealViewController()?.panGestureRecognizer())!)
        self.view.addGestureRecognizer((self.revealViewController()?.tapGestureRecognizer())!)
        
        player.delegate = self
        player.enableArtwork = true
        player.artworkSize = 500
        
        styleImageView()
        
        //Only set url if it is not already playing the same url
        if !(player.radioURL == URL(string: params![0])) || !player.isPlaying {
            player.radioURL = URL(string: params![0])
        } else {
            //Else, resume playback
            self.radioPlayer(player, playerStateDidChange: FRadioPlayerState.loadingFinished)
            
            
            self.radioPlayer(player, metadataDidChange: RadioSwiftViewController.meta?.1, trackName: RadioSwiftViewController.meta?.2)
            self.radioPlayer(player, artworkDidChange: RadioSwiftViewController.meta?.0)
        }
        
        playButton.round()
        setupAVAudioSession()
    }
    
    func styleImageView() {
        //Make elevation
        imageView.image = nil
        imageView.clipsToBounds = false
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.24
        imageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        imageView.layer.shadowRadius = CGFloat(10)
        imageView.layer.shadowPath = UIBezierPath(roundedRect: imageView.bounds, cornerRadius: 10).cgPath
        
        realImageView = UIImageView(frame: imageView.bounds)
        realImageView!.clipsToBounds = true
        realImageView!.layer.cornerRadius = 25
        
        imageView.addSubview(realImageView!)
    }
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayerState) {
        if (state == FRadioPlayerState.loading) {
            loadingIndicator.startAnimating()
            loadingIndicator.isHidden = false
        } else if (state == FRadioPlayerState.loadingFinished || state == FRadioPlayerState.readyToPlay) {
            loadingIndicator.stopAnimating()
            loadingIndicator.isHidden = true
        }
    }
    
    private func setupAVAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)))
            try AVAudioSession.sharedInstance().setActive(true)
            debugPrint("AVAudioSession is Active and Category Playback is set")
            
            //Do we ever need to unregister? I.e. when clicking pause
            UIApplication.shared.beginReceivingRemoteControlEvents()
            setupCommandCenter()
        } catch {
            debugPrint("Error: \(error)")
        }
    }
    
    func setupCommandCenter() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [self] event in
            if self.player.rate == 0.0 {
                self.player.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [self] event in
            if self.player.rate == 1.0 {
                self.player.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlaybackState) {
        updatePlayImage()
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange artistName: String?, trackName: String?) {
        
        RadioSwiftViewController.meta = (RadioSwiftViewController.meta?.0, artistName, trackName)
        
        if (UIScreen.main.nativeBounds.height > 1136) {
            self.artist.text = artistName
        } else {
            self.artist.text = ""
        }
        self.trackName.text = trackName
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: trackName ?? NSLocalizedString("radio_live", comment: ""), MPMediaItemPropertyArtist: artistName ?? ""]
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        
        RadioSwiftViewController.meta = (artworkURL, RadioSwiftViewController.meta?.1, RadioSwiftViewController.meta?.2)
        
        if (artworkURL != nil) {
            realImageView!.sd_setImage(with: artworkURL, completed: nil)
        } else {
            realImageView!.image = UIImage(named: "album_placeholder.png")
        }
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        realImageView?.frame = imageView.bounds
        imageView.layer.shadowPath = UIBezierPath(roundedRect: imageView.bounds, cornerRadius: 10).cgPath
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
    return input.rawValue
}
