//
//  Video.swift
//  Universal
//
//  Created by Mark on 04/07/2020.
//  Copyright © 2020 Sherdle. All rights reserved.
//

import Foundation

public class Video {
    public var vimeoId: String?
    public var youtubeId: String?
    public var directUrl: String?
    
    public var link: String?
    
    public var duration: String?
    public var description: String?
    public var channelID: String?
    public var categoryID: String?
    public var authorTitle: String?
    public var tags: [String]?
    public var publishedAt: String?
    public var thumbnails = Thumbnails()
    public var title: String?
}



public class Thumbnails {
    public var  high = Default()
    public var  `default` = Default()
    public var  medium = Default()
    
    public struct Default {
        public var  url: String?
        public var  height: Int?
        public var  width: Int?
    }
    
    public init() {
    }
}
