//
//  API.swift
//  VirtualTourist
//
//  Created by Shahad on 22/04/1441 AH.
//  Copyright © 1441 Udacity. All rights reserved.
//

import Foundation
import MapKit


struct FlickrAPI {
    
    static func getPhotosUrls(with coordinate: CLLocationCoordinate2D, pageNumber: Int, completion: @escaping ([URL]?, Error?, String?) -> ()) {
        let methodParameters = [
            Constant.FlickrParameterKeys.Method: Constant.FlickrParameterValues.SearchMethod,
            Constant.FlickrParameterKeys.APIKey: Constant.FlickrParameterValues.APIKey,
            Constant.FlickrParameterKeys.BoundingBox: bboxString(for: coordinate),
            Constant.FlickrParameterKeys.SafeSearch: Constant.FlickrParameterValues.UseSafeSearch,
            Constant.FlickrParameterKeys.Extras: Constant.FlickrParameterValues.MediumURL,
            Constant.FlickrParameterKeys.Format: Constant.FlickrParameterValues.ResponseFormat,
            Constant.FlickrParameterKeys.NoJSONCallback: Constant.FlickrParameterValues.DisableJSONCallback,
            Constant.FlickrParameterKeys.Page: pageNumber,
            Constant.FlickrParameterKeys.PerPage: Constant.FlickrParameterValues.PerPage,
            ] as [String:Any]
        
        
        let request = URLRequest(url: getURL(from: methodParameters))
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard (error == nil) else {
                completion(nil, error, nil)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completion(nil, nil, "Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                completion(nil, nil, "No data was returned by the request!")
                return
            }
            
            guard let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else {
                completion(nil, nil, "Could not parse the data as JSON.")
                return
            }
            
            guard let stat = result["stat"] as? String, stat == "ok" else {
                completion(nil, nil, "Flickr API returned an error. See error code and message in \(result)")
                return
            }
            
            guard let photosDictionary = result["photos"] as? [String:Any] else {
                completion(nil, nil, "Cannot find key 'photos' in \(result)")
                return
            }
            
            guard let photosArray = photosDictionary["photo"] as? [[String:Any]] else {
                completion(nil, nil, "Cannot find key 'photo' in \(photosDictionary)")
                return
            }
            
            
            var photosURLs = [URL]()
            for photoDictionary in photosArray {
                guard let urlString = photoDictionary["url_m"] as? String else {
                    return
                }
                let url = URL(string: urlString)
                photosURLs.append(url!)
            }
            
            completion(photosURLs, nil, nil)
        }
        
        task.resume()
    }
    
    static func bboxString(for coordinate: CLLocationCoordinate2D) -> String {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        let minimumLon = max(longitude - Constant.Flickr.SearchBBoxHalfWidth, -180)
        let minimumLat = max(latitude - Constant.Flickr.SearchBBoxHalfHeight, -90)
        let maximumLon = min(longitude + Constant.Flickr.SearchBBoxHalfWidth, 180)
        let maximumLat = min(latitude + Constant.Flickr.SearchBBoxHalfHeight, 90)
        
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    static func getURL(from parameters: [String:Any]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constant.Flickr.APIScheme
        components.host = Constant.Flickr.APIHost
        components.path = Constant.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
