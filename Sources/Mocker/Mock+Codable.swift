//
//  File.swift
//  Mocker
//
//  Created by Alex Buga on 17.09.2025.
//

import Foundation

extension Mock: Codable {
    enum CodingKeys: String, CodingKey {
        case url
        case ignoreQuery
        case cacheStoragePolicy
        case contentType
        case statusCode
        case requestError
        case data
        case additionalHeaders
        case fileExtensions
        case matchingQueryParameters
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var dataToEncode: [String: Data] = [:]
        data.forEach { element in
            dataToEncode[element.key.rawValue] = element.value
        }
        
        try container.encode(url, forKey: .url)
        try container.encode(ignoreQuery, forKey: .ignoreQuery)
        try container.encode(cacheStoragePolicy.rawValue, forKey: .cacheStoragePolicy)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(statusCode, forKey: .statusCode)
        // TODO: Need to find a way to encode/decode Error
        try container.encode(dataToEncode, forKey: .data)
        try container.encode(headers, forKey: .additionalHeaders)
        try container.encode(fileExtensions, forKey: .fileExtensions)
        try container.encode(matchingQueryParameters, forKey: .matchingQueryParameters)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let url = try container.decodeIfPresent(URL.self, forKey: .url)
        let ignoreQuery = try container.decodeIfPresent(Bool.self, forKey: .ignoreQuery) ?? false
        
        let cacheStoragePolicyRaw = try container.decodeIfPresent(Int.self, forKey: .cacheStoragePolicy)
        let cacheStoragePolicyDecoded: URLCache.StoragePolicy = cacheStoragePolicyRaw != nil ? (URLCache.StoragePolicy(rawValue: UInt(cacheStoragePolicyRaw!)) ?? .notAllowed) : .notAllowed
        
        let contentType = try container.decodeIfPresent(DataType.self, forKey: .contentType)
        let statusCode = try container.decode(Int.self, forKey: .statusCode)

        var data: [HTTPMethod: Data] = [:]
        let dataToDecode = try container.decode([String: Data].self, forKey: .data)
        dataToDecode.forEach { element in
            guard let httpMethod = HTTPMethod(rawValue: element.key) else {
                return
            }
            data[httpMethod] = element.value
        }
        
        let additionalHeaders = try container.decode([String: String].self, forKey: .additionalHeaders)
        let fileExtensions = try container.decodeIfPresent([String].self, forKey: .fileExtensions)
        let matchingQueryParameters = try container.decodeIfPresent([String].self, forKey: .matchingQueryParameters)
        
        
        self.init(
            url: url,
            ignoreQuery: ignoreQuery,
            cacheStoragePolicy: cacheStoragePolicyDecoded,
            contentType: contentType,
            statusCode: statusCode,
            data: data,
            requestError: nil, // TODO: Need to find a way to encode/decode Error
            additionalHeaders: additionalHeaders,
            fileExtensions: fileExtensions,
            matchingQueryParameters: matchingQueryParameters
        )
    }
    
    
}

extension URLRequest: Codable {
    
    enum CodingKeys: String, CodingKey {
        case url
        case cachePolicy
        case timeoutInterval
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(cachePolicy.rawValue, forKey: .cachePolicy)
        try container.encode(timeoutInterval, forKey: .timeoutInterval)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL?.self, forKey: .url)
        let cachePolicyRaw = try container.decode(Int.self, forKey: .cachePolicy)
        let timeoutInterval = try container.decode(TimeInterval.self, forKey: .timeoutInterval)
        self.init(
            url: url!,
            cachePolicy: URLRequest.CachePolicy(
                rawValue: UInt(cachePolicyRaw)
            ) ?? .useProtocolCachePolicy,
            timeoutInterval: timeoutInterval
        )
    }
    
    
}
