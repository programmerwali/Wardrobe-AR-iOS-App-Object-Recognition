//
//  TrendingResponse.swift
//  clothesObjectWithUIKit
//
//  Created by Wali Faisal on 27/12/2024.
//

import Foundation

// MARK: - Model to parse the response data
struct TrendingResponse: Codable {
    let products: [Product]
}

struct Product: Codable {
    let id: Int
    let name: String
    let price: Price
    let colour: String
    let brandName: String
    let imageUrl: String
    let url: String
}

struct Price: Codable {
    let current: CurrentPrice
}

struct CurrentPrice: Codable {
    let value: Double
    let text: String
}
