//
//  Constants.swift
//  VirtualTourist
//
//  Created by José Naves Moura Neto on 06/05/19.
//  Copyright © 2019 José Naves Moura Neto. All rights reserved.
//
struct Constants {
    
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIBaseURL = "/services/rest"
        
        static let SearchBoxHeight = 1.0
        static let SearchBoxWidth = 1.0

        static let SearchLatitudeRange = (-90.0, 90.0)
        static let SearchLongitudeRange = (-180.0, 180.0)
    }
    
    struct FlickrParameterKeys {
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let BoundingBox = "bbox"
        static let Format = "format"
        static let Method = "method"
        static let NoJSONCallback = "nojsoncallback"
        static let page = "page"
        static let pages = "pages"
        static let SafeSearch = "safe_search"
        static let Text = "text"
    }
    
    struct FlickrParameterValues {
        static let APIKey = "98820bfbe67f91a14d1e899e482a0c57"
        static let DisableJSONCallback = "nojsoncallback"
        static let MediumURL = "url_m"
        static let PhotosSearchMethod = "flickr.photos.search"
        static let ResponseFormat = "json"
        static let SafeSearch = "1"
    }
    
    struct FlickrResponseKeys {
        static let ImageUrl = "url_m"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Status = "status"
        static let Title = "title"
    }
}
