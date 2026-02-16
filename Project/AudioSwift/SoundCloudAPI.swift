//
//  SoundCloudAPI.swift
//  Universal
//
//  Created by Mark on 06/01/2019.
//  Copyright © 2019 Sherdle. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class SoundCloudAPI {
    
    var sessionManager = SessionManager()
    
    //Singleton Instance
    static let sharedInstanceVar: SoundCloudAPI? = {
        var sharedInstance = SoundCloudAPI.init()
        return sharedInstance
    }()
    
    class func sharedInstance() -> SoundCloudAPI? {
        // `dispatch_once()` call was converted to a static variable initializer
        return sharedInstanceVar
        
    }
    
    //Instantiating Session
    init() {
        
    }
    
    func searchSoundCloudSongs(_ searchTerm: String?, completionHandler: @escaping (_ resultArray: [AnyHashable]?, _ error: String?) -> Void) {
        
        let apiURL = "https://api.soundcloud.com/tracks?client_id=\(AppDelegate.SOUNDCLOUD_CLIENT)&q=\(searchTerm ?? "")&format=json&linked_partitioning=1"
        
        self.getAccessToken { token, result in
            print("Token: ", "Bearer " + token!)
            
            self.sessionManager.adapter = AccessTokenAdapter(accessToken: token!)
            self.sessionManager.request(apiURL, method: .get).responseJSON { response in
                //print("Request: \(String(describing: response.request))")   // original url request
                debugPrint(response)
                
                switch response.result {
                case .success(_):
                    if let value = response.data {
                        let resultArray = SoundCloudSong.parseJSONData(value)
                        OperationQueue.main.addOperation({
                            completionHandler(resultArray, nil)
                        })
                    }
                case .failure(let error):
                    print(error)
                    completionHandler(nil, "no connection")
                }
            }
        }
        
    }
    
    func soundCloudSongs(_ param: String?, type: String?, offset: Int, limit: Int, completionHandler: @escaping (_ resultArray: [AnyHashable]?, _ error: String?) -> Void) {
        
        var apiURL: String
        if type?.isEqual("user") ?? false {
            apiURL = String(format: "https://api.soundcloud.com/users/%@/tracks?offset=%i&limit=%i&format=json&linked_partitioning=1", param ?? "", offset, limit)
        } else {
            apiURL = String(format: "https://api.soundcloud.com/playlists/%@/tracks?offset=%i&limit=%i&format=json&linked_partitioning=1", param ?? "", offset, limit)
        }
        
        self.getAccessToken { token, result in
            print("Token: ", "Bearer " + token!)
            
            self.sessionManager.adapter = AccessTokenAdapter(accessToken: token!)
            self.sessionManager.request(apiURL, method: .get).responseJSON { response in
                //print("Request: \(String(describing: response.request))")   // original url request
                debugPrint(response)
                
                switch response.result {
                case .success(_):
                    if let value = response.data {
                        let resultArray = SoundCloudSong.parseJSONData(value)
                        OperationQueue.main.addOperation({
                            completionHandler(resultArray, nil)
                        })
                    }
                case .failure(let error):
                    print(error)
                    completionHandler(nil, "no connection")
                }
            }
        }
        
       
        
    }
    
    func getAccessToken(completion: @escaping (String?, Bool) -> Void){
            
        let parameters: Parameters = ["grant_type": "client_credentials", "client_id": AppDelegate.SOUNDCLOUD_CLIENT, "client_secret": AppDelegate.SOUNDCLOUD_CLIENT_SECRET]

            
            Alamofire.request("https://api.soundcloud.com/oauth2/token", method: .post, parameters: parameters).responseJSON { response in
                
                 if (response.response?.statusCode == 200){
                    let data = response.result.value as! NSDictionary
                    let accessToken = data.object(forKey: "access_token") as! String
                        
                    print(accessToken)
                    completion(accessToken, true)
                    
                 }
                 else {
                    print("Error")
                    completion(nil, false)
                }
            }
        }
}

extension Int {
    
    func makeMilisecondsRedeable () -> String {
        let totalDurationSeconds = self / 1000
        let min = totalDurationSeconds / 60
        let sec = totalDurationSeconds % 60
        
        return String(format: "%i:%02i",min,sec )
    }
}

class AccessTokenAdapter: RequestAdapter {
    private let accessToken: String

    init(accessToken: String) {
        self.accessToken = accessToken
    }

    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest

        urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        dump(urlRequest.allHTTPHeaderFields)

        return urlRequest
    }
}
