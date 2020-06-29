//
//  GoogleCloudDetection.swift
//  StockLens
//
//  Created by Anirudh Naidu on 3/3/19.
//  Copyright © 2019 Anirudh Naidu. All rights reserved.
//

import Foundation
import Alamofire

class GoogleCloudDetection {
    private let apiKey = ""
    private var apiURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)")!
    }

    
    func detect(from image: UIImage, completion: @escaping (LogoResult?) -> Void) {
        guard let base64Image = base64EncodeImage(image) else {
            print("Error while base64 encoding image")
            completion(nil)
            return
        }
        callGoogleVisionAPI(with: base64Image, completion: completion)
    }
    
    private func callGoogleVisionAPI(with base64EncodedImage: String, completion: @escaping (LogoResult?) -> Void) {
        let parameters: Parameters = [
            "requests": [
                [
                    "image": [
                        "content": base64EncodedImage
                    ],
                    "features": [
                        [
                            "type": "LOGO_DETECTION"
                        ]
                    ]
                ]
            ]
        ]
        let headers: HTTPHeaders = [
            "X-Ios-Bundle-Identifier": Bundle.main.bundleIdentifier ?? "",
            ]
        Alamofire.request(
            apiURL,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers)
        
            .responseData { response in
                if response.result.isFailure {
                    completion(nil)
                    return
                }
                guard let data = response.result.value else {
                    completion(nil)
                    return
                }
                
                // Decode the JSON data into a `GoogleCloudLogoResponse` object.
                let logoResponse = try? JSONDecoder().decode(GoogleCloudLogoResponse.self, from: data)
                completion(logoResponse?.responses[0])
 
                
        }
    }
    
    private func base64EncodeImage(_ image: UIImage) -> String? {
        return image.pngData()?.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
}
