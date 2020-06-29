//
//  GoogleCloudDetectionModel.swift
//  StockLens
//
//  Created by Anirudh Naidu on 3/3/19.
//  Copyright © 2019 Anirudh Naidu. All rights reserved.
//

import Foundation
import UIKit

struct Vertex: Codable {
    let x: Int?
    let y: Int?
    enum CodingKeys: String, CodingKey {
        case x = "x", y = "y"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decodeIfPresent(Int.self, forKey: .x)
        y = try container.decodeIfPresent(Int.self, forKey: .y)
    }
    
    func toCGPoint() -> CGPoint {
        return CGPoint(x: x ?? 0, y: y ?? 0)
    }
}

struct BoundingBox: Codable {
    let vertices: [Vertex]
    enum CodingKeys: String, CodingKey {
        case vertices = "vertices"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vertices = try container.decode([Vertex].self, forKey: .vertices)
    }
}

struct Annotation: Codable {
    //let boundingBox: BoundingBox
    let description: String
    enum CodingKeys: String, CodingKey {
        //case boundingBox = "boundingPoly"
        case description = "description"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //boundingBox = try container.decode(BoundingBox.self, forKey: .boundingBox)
        description = try container.decode(String.self, forKey: .description)
    }
}

struct LogoResult: Codable {
    let annotations: [Annotation]
    enum CodingKeys: String, CodingKey {
        case annotations = "logoAnnotations"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        annotations = try container.decode([Annotation].self, forKey: .annotations)
    }
}

struct GoogleCloudLogoResponse: Codable {
    let responses: [LogoResult]
    enum CodingKeys: String, CodingKey {
        case responses = "responses"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        responses = try container.decode([LogoResult].self, forKey: .responses)
    }
}

