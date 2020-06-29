//
//  StockDetection.swift
//  StockLens
//
//  Created by Anirudh Naidu on 6/12/19.
//  Copyright © 2019 Anirudh Naidu. All rights reserved.
//


// Both nameToTicker and fetchPrice return JSON responses that must be parsed. The @escaping completion handler must be changed to String?
// from of [String:Any]? once the parsing code is added.

import Foundation

class StockDetection {
    private let apiKey = ""
    
    
    func buildBaseURL(name:String, param: String, function: String) -> NSURLComponents {
        let urlComponents = NSURLComponents()
        if (name != ""){
            urlComponents.scheme = "https"
            urlComponents.host = "www.alphavantage.co"
            urlComponents.path = "/query"
            urlComponents.queryItems = [
                URLQueryItem(name: "function", value: function),
                URLQueryItem(name: param, value: name),
                URLQueryItem(name: "apikey", value: apiKey)
            ]
        }
        //SOMETIMES WILL BE EMPTY NSURL...
        return urlComponents
    }
    
    func nameToTicker(myURL:URL, completion: @escaping(String?)->()) {
        let session = URLSession.shared
        let request = URLRequest(url: myURL)
        //from https://stackoverflow.com/questions/24016142/how-to-make-an-http-request-in-swift
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            guard error == nil else {
                completion("")
                return
            }
            guard let data = data else {
                completion("")
                return
            }
            //do branch is from https://gist.github.com/jbfbell/e011c5e4c3869584723d79927b7c4b68
            do {
                guard let results = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    print("Cannot unwrap JSON response")
                    completion("")
                    return
                }
                if results["Note"] != nil{ // completion becomes limit when the limit for the API calls is reached
                    completion("limit")
                }
                // Parse JSON and return the ticker
                if let Matches = results["bestMatches"] as? NSArray  {
                    if (Matches.count != 0){
                        if let best = Matches[0] as? NSDictionary {
                            if let ticker = best["1. symbol"] as? String{
                                completion(ticker)
                            }
                        }
                    }
                    else {
                        completion("")
                    }
                }
            }
            catch {
                print("Cannot decode JSON response")
                completion("")
                return
            }
        }
        task.resume()
    }
    
    func fetchPrice(myURL:URL, completion: @escaping(Array<String>?)->()) {
        let notFound = ["", ""]
        let session = URLSession.shared
        let request = URLRequest(url: myURL)
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            guard error == nil else {
                completion(notFound)
                return
            }
            guard let data = data else {
                completion(notFound)
                return
            }
            do {
                guard let results = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    print("Cannot unwrap JSON response")
                    completion(notFound)
                    return
                }
                if results["Note"] != nil{ // completion becomes limit when the limit for the API calls is reached
                    completion(["limit"])
                }

                // parse JSON and return an array with the price and percent change (to be used later for the UI, we want to display the current price and its % change)
                var returnArray = [String]()
                if let Quote = results["Global Quote"] as? NSDictionary  {
                    if let CloseStockData = Quote["05. price"] as? String {
                        returnArray.append(CloseStockData)
                    }
                    if let PercentageChange = Quote["10. change percent"] as? String {
                        returnArray.append(PercentageChange)
                    }
                    if let Ticker = Quote["01. symbol"] as? String {
                        returnArray.append(Ticker)
                    }
                    completion(returnArray)
                }
            }
            catch {
                print("Cannot decode JSON response")
                completion(notFound)
                return
            }
        }
        task.resume()
    }
    
}

