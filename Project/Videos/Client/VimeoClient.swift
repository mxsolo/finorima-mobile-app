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

class VimeoClient: NSObject {
    
    private static var API_BASE = "https://api.vimeo.com"
    private static var API_TYPE_ALBUM = "/albums/"
    private static var API_TYPE_USER = "/users/"
    private static var PER_PAGE = 20;
    
    public enum RequestType {
        case album
        case user
    }
    
    static func getResults(parameter : String, type : RequestType, search: String?, page : Int, completion:@escaping (_ success: Bool, _ hasNextPage: Bool, _ items : [Video]) -> Void){

        var url: String?
        if (type == .album) {
            
            url = "\(API_BASE + API_TYPE_ALBUM  + parameter)/videos?per_page=\(PER_PAGE)&page=\(page)&access_token=\(AppDelegate.VIMEO_API)"

            //url = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&channelId=\(parameter)&q=\(queryReady!)&maxResults=20&key=\(AppDelegate.YOUTUBE_CONTENT_KEY)&pageToken=\(pageToken ?? "")"
        } else if (type == .user) {
            url = "\(API_BASE + API_TYPE_USER  + parameter)/videos?per_page=\(PER_PAGE)&page=\(page)&access_token=\(AppDelegate.VIMEO_API)"
        }
        
        if let query = search {
            let queryReady = query.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
            url! += "&query=" + queryReady!;
        }
        
        print("Requesting: ", url ?? "(null)")
        
        Alamofire.request(url!).validate().responseJSON { response in
            switch response.result {
            case .success(_):
                if let value = response.result.value {
                    let json = JSON(value)
                    //print("Response JSON: \(json)")
                    
                    if let array = json["data"].array{
                        parseSearch(objects: array, completion: { (items) -> Void in
                            let nextPage = json["paging"]["next"].string != nil
                            completion(true, nextPage, items)
                        })
                        
                    }
                }
            case .failure(let error):
                print(error)
                completion(false, false, [])
            }
        }
    }
    
    static func parseSearch(objects : [JSON], completion : (_ items : [Video]) -> Void){
        var items = [Video]()
        for object in objects{
            items.append(parseVideo(object: object))
        }
        
        completion(items)
    }
    
    static func parseVideo(object : JSON) -> Video {
        
        let video = Video()
        video.vimeoId  = object["uri"].string?.replacingOccurrences(of: "/videos/", with: "")
        video.description = object["description"].string
        
        video.thumbnails.high.url = object["snippet"]["thumbnails"]["high"]["url"].string
        video.thumbnails.medium.url = object["snippet"]["thumbnails"]["medium"]["url"].string
        video.thumbnails.default.url = object["snippet"]["thumbnails"]["default"]["url"].string
        
        for size in object["pictures"]["sizes"].arrayValue {
            if (size["width"].intValue == 200 ){
                video.thumbnails.medium.url = size["link"].string
            } else if(size["width"].intValue == 1920 ){
                video.thumbnails.high.url = size["link"].string
            }
        }
        
        video.publishedAt = object["created_time"].date
        video.authorTitle = object["user"]["name"].string
        video.title = object["name"].string
        video.link = object["link"].string
        
        return video
    }
    
}
