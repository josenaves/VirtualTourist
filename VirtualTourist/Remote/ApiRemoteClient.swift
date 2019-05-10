//
//  ApiRemoteClient.swift
//  VirtualTourist
//
//  Created by José Naves Moura Neto on 06/05/19.
//  Copyright © 2019 José Naves Moura Neto. All rights reserved.
//

import Foundation

class ApiRemoteClient {
    
    static let shared = ApiRemoteClient()

    let session = URLSession.shared

    private func buildUrlWithParam(parameters: [String: AnyObject]) -> URL {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = Constants.Flickr.APIScheme
        urlComponents.host = Constants.Flickr.APIHost
        urlComponents.path = Constants.Flickr.APIBaseURL
        urlComponents.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            urlComponents.queryItems!.append(queryItem)
        }
        return urlComponents.url!
    }
    
    private func getParamPair(pin: Pin) -> Dictionary<String, Any> {
        return [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.PhotosSearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.SafeSearch,
            Constants.FlickrParameterKeys.BoundingBox: getbbox(pin: pin)
        ]
    }
    
    private func getbbox(pin: Pin) -> String {
        let minLong = max(pin.longitude - Constants.Flickr.SearchBoxWidth, Constants.Flickr.SearchLongitudeRange.0)
        let minLat =  max(pin.latitude - Constants.Flickr.SearchBoxHeight, Constants.Flickr.SearchLatitudeRange.0)
        let maxLong = min(pin.longitude + Constants.Flickr.SearchBoxWidth, Constants.Flickr.SearchLongitudeRange.1)
        let maxLat = min(pin.latitude + Constants.Flickr.SearchBoxHeight, Constants.Flickr.SearchLatitudeRange.1)
        
        return "\(minLong),\(minLat),\(maxLong),\(maxLat)"
    }
    
    func createRequest(pin: Pin) -> URLRequest {
        return URLRequest(url: buildUrlWithParam(parameters: getParamPair(pin: pin) as [String : AnyObject]))
    }
    
    func makeRequest(request: URLRequest, completionHandler: @escaping (_ result: NSArray?, _ error: String?) -> Void) {
        
        let task = session.dataTask(with: request) {
            (data, response, error) in

            guard(error == nil) else {
                completionHandler(nil, "Connection Error")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(nil, "Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                completionHandler(nil, "No data was returned by the API")
                return
            }
            
            let parsedResult: [String: AnyObject]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject]
            } catch {
                completionHandler(nil, "Could not parse data as JSON: '\(data)'")
                return
            }
            
            guard let photosDictionary = parsedResult?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                completionHandler(nil, "Cannot find keys : \(Constants.FlickrResponseKeys.Photos) in \(parsedResult!)")
                return
            }
            
            guard (photoArray.count > 0) else {
                completionHandler(nil, "No photos found! Search again")
                return
            }
            
            completionHandler(photoArray as NSArray, nil)
        }
        
        task.resume()
    }
    
    func downloadImage(imageUrl: String, completionHandler: @escaping (_ image: Data?,_ error: String?) -> Void ) {
        
        let task = session.dataTask(with: URL(string: imageUrl)!) {
            (data, response, error) in
            
            guard (error == nil) else {
                completionHandler(nil, "Connection Error")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(nil, "The request returned a status code diferent than 2XX!")
                return
            }
            
            completionHandler(data, nil)
        }
        task.resume()
    }
}
