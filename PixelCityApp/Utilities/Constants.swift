
import Foundation

// this my custom url for my flicker api that i use it to request and download  number of images for location(DroppablePin that i detrmine it in my  map) that i select it

let apikey = "bc8b00e9035741530b509088d962017c"
func flickerUrl(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String{
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apikey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    return url
    
}
