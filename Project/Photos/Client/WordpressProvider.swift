//
//  WordpressProvider.swift
//  Universal
//
//  Created by Mark on 05/07/2020.
//  Copyright © 2020 Sherdle. All rights reserved.
//

import Foundation

class WordpressProvider: PhotosProvider {
    
    func parseRequest(params: [String], page: Int, completionHandler: @escaping (Bool, [Photo]?) -> Void) {
        let requestParams = RequestParams.init()
        requestParams.page = page
        if (params.count > 1 && !(params[1]).isEmpty){
            requestParams.category = params[1]
        }
        
        let wordpressClient = WordpressSwift.init()
        wordpressClient.get(blogURL: params[0] , params: requestParams, forType: WPPost.self, completionHandler: { (success, posts) in
            if (!success) {
            
                completionHandler(false, nil);
            }
            
            var results = [Photo]()
            if let wp_posts = posts {

                for wp_post in wp_posts {
                    let post = wp_post as! WPPost
                    
                    let result = Photo(fullUrl: post.featured_media.url!, thumbnailUrl: post.featured_media.sizes.thumbnail ?? post.featured_media.url!)
                    results.append(result)
                }
            
            }
            
            completionHandler(true, results)
        })
        
    }
    
    //-- Stub to conform to protocol
    
    func getRequestUrl(params: [String], page: Int) -> String? {
        return String()
    }
    
    func parseRequest(params: [String], json: String) -> [Photo]? {
        return []
    }
}
