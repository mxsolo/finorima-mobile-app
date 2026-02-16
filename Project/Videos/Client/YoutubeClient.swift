//
//  YoutubeClient.swift
//  Universal
//
//  Created by Mark on 02/01/2019.
//  Copyright © 2019 Sherdle. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class YoutubeClient: NSObject {
    
    public enum RequestType {
        case playlist
        case live
        case channel
        case query
        case related
    }
    
    static func getResults(identifier: String, apiKey: String, type : RequestType, search: String?, pageToken : String?, completion:@escaping (_ success: Bool, _ nextPageToken : String?, _ items : [Video]) -> Void){
        
        var url: String?
        if (type == .query) {
            let queryReady = search!.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
            url = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&channelId=\(identifier)&q=\(queryReady!)&maxResults=20&key=\(apiKey)&pageToken=\(pageToken ?? "")"
        } else if (type == .playlist) {
            url = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(identifier)&maxResults=20&key=\(apiKey)&pageToken=\(pageToken ?? "")"
        } else if (type == .live) {
            url = "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=\(identifier)&type=video&eventType=live&maxResults=20&key=\(apiKey)&pageToken=\(pageToken ?? "")"
        } else if (type == .channel) {
            url = "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=\(identifier)&type=video&order=date&maxResults=20&key=\(apiKey)&pageToken=\(pageToken ?? "")"
        } else if (type == .related) {
            url = "https://www.googleapis.com/youtube/v3/search?part=snippet&relatedToVideoId=\(identifier)&type=video&key=\(apiKey)"
        }
        print("Requesting: ", url ?? "(null)")
        
        Alamofire.request(url!).validate().responseJSON { response in
            switch response.result {
            case .success(_):
                if let value = response.result.value {
                    let json = JSON(value)
                    //print("Response JSON: \(json)")
                    
                    if let array = json["items"].array{
                        parseSearch(objects: array, completion: { (items) -> Void in
                            let nextpagetoken = json["nextPageToken"].string
                            completion(true, nextpagetoken, items)
                        })
                        
                    }
                }
            case .failure(let error):
                print(error)
                completion(false, nil, [])
            }
        }
    }
    
    static func parseSearch(objects : [JSON], completion : (_ items : [Video]) -> Void){
        var items = [Video]()
        for object in objects{
            //Only add non-private videos (-> with a thumbnail)
            if (object["snippet"]["thumbnails"]["high"]["url"].string != nil) {
                items.append(parseVideo(object: object))
            }
        }
        
        completion(items)
    }
    
    static func parseVideo(object : JSON) -> Video {
        
        let video = Video()
        video.youtubeId  = object["id"]["videoId"].string
        if (video.youtubeId  == nil) {
            video.youtubeId = object["snippet"]["resourceId"]["videoId"].string
        }
        video.description = object["snippet"]["description"].string
        
        video.thumbnails.high.url = object["snippet"]["thumbnails"]["high"]["url"].string
        video.thumbnails.medium.url = object["snippet"]["thumbnails"]["medium"]["url"].string
        video.thumbnails.default.url = object["snippet"]["thumbnails"]["default"]["url"].string
        
        video.publishedAt = object["snippet"]["publishedAt"].date
        video.authorTitle = object["snippet"]["channelTitle"].string
        video.channelID = object["snippet"]["channelId"].string
        video.title = object["snippet"]["title"].string
        video.link = "https://www.youtube.com/watch?v=\(video.youtubeId!)"
        
        return video
    }
    
}
