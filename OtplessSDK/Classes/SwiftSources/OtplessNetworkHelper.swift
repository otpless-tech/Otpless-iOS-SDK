//
//  OtplessNetworkHelper.swift
//  OtplessSDK
//
//  Created by Otpless on 06/02/23.
//

import Foundation
import Network

 class OtplessNetworkHelper {
    var baseurl : String = ""
     var apiRoute = "metaverse"
  typealias NetworkCompletion = (Data?, URLResponse?, Error?) -> Void
  
  static let shared = OtplessNetworkHelper()
  
  func fetchData(method: String , headers: [String: String]? = nil, bodyParams: [String: Any]? = nil, completion: @escaping NetworkCompletion) {
      var request = URLRequest(url:URL(string:baseurl + apiRoute)!)
    request.httpMethod = method
    
      if let headers = headers {
         for (key, value) in headers {
           request.setValue(value, forHTTPHeaderField: key)
         }
       }
       
       if let bodyParams = bodyParams {
         let bodyData = try? JSONSerialization.data(withJSONObject: bodyParams)
         request.httpBody = bodyData
       }
       
       let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
         completion(data, response, error)
       }
       task.resume()
  }
    func setBaseUrl(url: String){
        let urlComponents = URLComponents(string: url)
        if let scheme = urlComponents?.scheme, let host = urlComponents?.host {
            let combinedString = "\(scheme)://\(host)/"
            baseurl = combinedString
        }
    }
    
     
     func fetchDataWithGET(apiRoute: String, params: [String: String]? = nil, headers: [String: String]? = nil, completion: @escaping NetworkCompletion) {
         var components = URLComponents(string:apiRoute)
         
         if let params = params {
             components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
         }
         
         guard let url = components?.url else {
             completion(nil, nil, NSError(domain: "InvalidURL", code: 0, userInfo: nil))
             return
         }
         
         var request = URLRequest(url: url)
         request.httpMethod = "GET"
         
         if let headers = headers {
             for (key, value) in headers {
                 request.setValue(value, forHTTPHeaderField: key)
             }
         }
         
         let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
             completion(data, response, error)
         }
         task.resume()
     }
     
     @available(iOS 12.0, *)
     func warmupURLCache(forURLs urls: [String], shouldRequireMobileDataEnabled: Bool, areURLsFromWeb: Bool, onComplete: @escaping (() -> Void)) {
         if !shouldRequireMobileDataEnabled {
             for url in urls {
                 self.fetchDataWithGET(apiRoute: url, completion: { _, _, _  in
                     OtplessLogger.log(string: "Warmup complete for url: \(url)", type: "URL CACHE WARMUP")
                 })
             }
             return
         }
         
         // Only make request if mobile data is enabled and `shouldRequireMobileDataEnabled` is also true
         let networkMonitor = NWPathMonitor(requiredInterfaceType: .cellular)
         networkMonitor.pathUpdateHandler = { [weak self] path in
             guard let self = self else { return }
             
             DispatchQueue.main.async {
                 if path.status == .satisfied {
                     var urlsToPing: [String] = []
                     
                     if areURLsFromWeb {
                         urlsToPing.append(contentsOf: urls)
                     } else {
                         let providedPreLoadingURLs = Bundle.main.object(forInfoDictionaryKey: "OtplessSNAPreLoadingURLs") as? [String]
                         urlsToPing.append(contentsOf: providedPreLoadingURLs ?? urls)
                     }
                     
                     for url in urlsToPing {
                         self.fetchDataWithGET(apiRoute: url, completion: { _, _, _  in
                             OtplessLogger.log(string: "Warmup complete for url: \(url)", type: "URL CACHE WARMUP")
                             if url == urlsToPing.last {
                                 DispatchQueue.main.async {
                                     onComplete()
                                 }
                             }
                         })
                     }
                 }
                 // Stop monitoring after receiving the result
                 networkMonitor.cancel()
             }
         }
         
         networkMonitor.start(queue: .main)
     }
}



