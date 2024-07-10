//
//  Utils.swift
//  OTPless
//
//  Created by Anubhav Mathur on 18/05/23.
//

import Foundation

class Utils {
    
    class func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                
            }
        }
        return nil
    }
    class func appendQueryParameters(from sourceURL: URL, to destinationURL: URL) -> URL? {
        // Create URL components from the destination URL
        guard var destinationComponents = URLComponents(url: destinationURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        // Get the query parameters from the source URL
        guard let sourceComponents = URLComponents(url: sourceURL, resolvingAgainstBaseURL: false),
              let queryItems = sourceComponents.queryItems else {
            return nil
        }

        // Append the query parameters to the destination URL
        if destinationComponents.queryItems != nil {
            destinationComponents.queryItems?.append(contentsOf: queryItems)
        } else {
            destinationComponents.queryItems = queryItems
        }

        // Reconstruct the URL with the appended query parameters
        if let updatedURL = destinationComponents.url {
            return updatedURL
        } else {
            return destinationURL
        }
    }
    class func containsJavaScriptInjection(url: URL) -> Bool {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems else {
            return false
        }
        
        for item in queryItems {
            if let value = item.value, containsJavaScriptCode(value) {
                return true
            }
        }
        
        return false
    }

    class func containsJavaScriptCode(_ value: String) -> Bool {
        let javascriptRegex = try! NSRegularExpression(pattern: "<script\\b[^>]*>(.*?)</script>", options: .caseInsensitive)
        return javascriptRegex.matches(in: value, options: [], range: NSRange(location: 0, length: value.utf16.count)).count > 0
    }
    
    class func createErrorDictionary(error: String, errorDescription: String) -> [String: String] {
        return [
            "error": error,
            "error_description": errorDescription
        ]
    }
    
    class func convertDictionaryToString(_ dictionary: [String: Any], options: JSONSerialization.WritingOptions) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: options)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            return ("Error converting dictionary to JSON string: \(error)")
        }
        
        return ""
    }
    
    class func createUnsupportedIOSVersionError(supportedFrom: String, forFeature feature: String) -> [String: String] {
        return [
            "error": "\(feature.replacingOccurrences(of: " ", with: "_").lowercased()) not supported",
            "error_description": "\(feature) requires iOS version \(supportedFrom) and above."
        ]
    }
}
