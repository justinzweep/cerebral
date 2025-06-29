//
//  APIResponseModels.swift
//  cerebral
//
//  Created on 27/11/2024.
//

import Foundation

// Helper for decoding unknown JSON values
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = ()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode value"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let anyArray = array.map { AnyCodable($0) }
            try container.encode(anyArray)
        case let dictionary as [String: Any]:
            let anyDict = dictionary.mapValues { AnyCodable($0) }
            try container.encode(anyDict)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value"))
        }
    }
}

struct ProcessedDocumentResponse: Codable {
    let success: Bool
    let message: String
    let originalUuid: String
    let documentTitle: String?
    let totalChunks: Int
    let chunks: [DocumentChunkResponse]
    
    enum CodingKeys: String, CodingKey {
        case success, message, chunks
        case originalUuid = "original_uuid"
        case documentTitle = "document_title"
        case totalChunks = "total_chunks"
    }
    

}

struct DocumentChunkResponse: Codable {
    let text: String
    let uuid: String
    let chunkId: String
    let pageNumber: Int?
    let boundingBoxes: [BoundingBoxResponse]
    let metadata: ChunkMetadata
    let embedding: [Float]
    
    enum CodingKeys: String, CodingKey {
        case text, uuid, metadata, embedding
        case chunkId = "chunk_id"
        case pageNumber = "page_number"
        case boundingBoxes = "bounding_boxes"
    }
    

}

struct ChunkMetadata: Codable {
    let docItems: [DocItem]
    let origin: OriginInfo
    
    enum CodingKeys: String, CodingKey {
        case docItems = "doc_items"
        case origin
    }
}

struct DocItem: Codable {
    let selfRef: String
    let parent: ParentRef?
    let children: [String]
    let contentLayer: String
    let label: String
    let prov: [ProvenanceInfo]
    
    enum CodingKeys: String, CodingKey {
        case children, label, prov
        case selfRef = "self_ref"
        case parent
        case contentLayer = "content_layer"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        selfRef = try container.decode(String.self, forKey: .selfRef)
        parent = try container.decodeIfPresent(ParentRef.self, forKey: .parent)
        contentLayer = try container.decode(String.self, forKey: .contentLayer)
        label = try container.decode(String.self, forKey: .label)
        prov = try container.decode([ProvenanceInfo].self, forKey: .prov)
        
        // Handle children - can be strings or objects with references
        var childrenArray: [String] = []
        
        if let childrenContainer = try? container.nestedUnkeyedContainer(forKey: .children) {
            var tempChildren = childrenContainer
            
            while !tempChildren.isAtEnd {
                do {
                    // Try to decode as string first
                    let child = try tempChildren.decode(String.self)
                    childrenArray.append(child)
                } catch {
                    // If that fails, try to decode as object with reference
                    do {
                        let childRef = try tempChildren.decode(ParentRef.self)
                        childrenArray.append(childRef.ref)
                    } catch {
                        // Skip this child and continue
                        _ = try tempChildren.decode(AnyCodable.self)
                    }
                }
            }
        }
        
        children = childrenArray
    }
}

struct ParentRef: Codable {
    let ref: String
    
    enum CodingKeys: String, CodingKey {
        case cref = "cref"
        case dollarRef = "$ref"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try cref first, then $ref
        if let crefValue = try container.decodeIfPresent(String.self, forKey: .cref) {
            ref = crefValue
        } else if let dollarRefValue = try container.decodeIfPresent(String.self, forKey: .dollarRef) {
            ref = dollarRefValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.cref, 
                DecodingError.Context(codingPath: decoder.codingPath, 
                                    debugDescription: "Neither 'cref' nor '$ref' key found"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode as cref by default
        try container.encode(ref, forKey: .cref)
    }
}

struct ProvenanceInfo: Codable {
    let pageNo: Int
    let bbox: BoundingBoxResponse
    let charspan: [Int]
    
    enum CodingKeys: String, CodingKey {
        case bbox, charspan
        case pageNo = "page_no"
    }
}

struct BoundingBoxResponse: Codable {
    let l: Double  // left
    let t: Double  // top
    let coordOrigin: String?
    
    // Computed properties to provide consistent interface
    var right: Double {
        return l + width
    }
    
    var bottom: Double {
        return t + height
    }
    
    var width: Double {
        return _width ?? (_right.map { $0 - l } ?? 0)
    }
    
    var height: Double {
        return _height ?? (_bottom.map { $0 - t } ?? 0)
    }
    
    // Private storage for the actual values from JSON
    private let _width: Double?
    private let _height: Double?
    private let _right: Double?
    private let _bottom: Double?
    
    enum CodingKeys: String, CodingKey {
        case l, t, w, h, r, b
        case coordOrigin = "coord_origin"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        l = try container.decode(Double.self, forKey: .l)
        t = try container.decode(Double.self, forKey: .t)
        coordOrigin = try container.decodeIfPresent(String.self, forKey: .coordOrigin)
        
        // Try to decode width/height format first
        _width = try container.decodeIfPresent(Double.self, forKey: .w)
        _height = try container.decodeIfPresent(Double.self, forKey: .h)
        
        // Try to decode right/bottom format if width/height not available
        _right = try container.decodeIfPresent(Double.self, forKey: .r)
        _bottom = try container.decodeIfPresent(Double.self, forKey: .b)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(l, forKey: .l)
        try container.encode(t, forKey: .t)
        try container.encodeIfPresent(coordOrigin, forKey: .coordOrigin)
        
        // Encode in width/height format by default
        try container.encode(width, forKey: .w)
        try container.encode(height, forKey: .h)
    }
}

struct OriginInfo: Codable {
    let mimetype: String
    let binaryHash: UInt64  // Changed to UInt64 to handle very large positive hash values
    let filename: String
    let uri: String?
    
    enum CodingKeys: String, CodingKey {
        case mimetype, filename, uri
        case binaryHash = "binary_hash"
    }
}

// MARK: - Text Embedding API Models

struct EmbeddingRequest: Codable {
    let text: String
    let inputType: String // "query" or "document"
    
    enum CodingKeys: String, CodingKey {
        case text
        case inputType = "input_type"
    }
}

struct EmbeddingResponse: Codable {
    let success: Bool
    let embedding: [Float]
    let modelInfo: ModelInfo
    let textLength: Int
    
    enum CodingKeys: String, CodingKey {
        case success, embedding
        case modelInfo = "model_info"
        case textLength = "text_length"
    }
}

struct ModelInfo: Codable {
    let model: String
    let outputDimension: Int
    let maxContextLength: Int
    
    enum CodingKeys: String, CodingKey {
        case model
        case outputDimension = "output_dimension"
        case maxContextLength = "max_context_length"
    }
} 