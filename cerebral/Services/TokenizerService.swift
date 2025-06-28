//
//  TokenizerService.swift
//  cerebral
//
//  Created on 26/06/2025.
//

import Foundation

/// Service for accurate token counting and text processing
@MainActor
final class TokenizerService {
    static let shared = TokenizerService()
    
    // Approximate token/character ratio for Claude models
    private let averageCharactersPerToken: Double = 4.0
    
    // Token limits for different Claude models
    enum ModelTokenLimits {
        static let claude3Opus = 200_000
        static let claude3Sonnet = 200_000
        static let claude3Haiku = 200_000
        static let defaultLimit = 100_000
    }
    
    private init() {}
    
    /// Estimates token count for a given text
    /// Uses a simple character-based approximation suitable for Claude models
    func estimateTokenCount(for text: String) -> Int {
        // Remove excessive whitespace
        let cleanedText = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Estimate based on character count
        // This is a simplified estimation - in production, you'd use a proper tokenizer
        let characterCount = cleanedText.count
        let estimatedTokens = Int(ceil(Double(characterCount) / averageCharactersPerToken))
        
        // Add a small buffer for safety
        return Int(Double(estimatedTokens) * 1.1)
    }
    
    /// Estimates token count for multiple texts
    func estimateTokenCount(for texts: [String]) -> Int {
        texts.reduce(0) { $0 + estimateTokenCount(for: $1) }
    }
    
    /// Truncates text to fit within a token limit
    func truncateToTokenLimit(_ text: String, limit: Int) -> String {
        let estimatedTokens = estimateTokenCount(for: text)
        
        if estimatedTokens <= limit {
            return text
        }
        
        // Calculate approximate character limit
        let targetCharacters = Int(Double(limit) * averageCharactersPerToken * 0.9) // 90% to be safe
        
        if text.count <= targetCharacters {
            return text
        }
        
        // Truncate and add ellipsis
        let index = text.index(text.startIndex, offsetBy: targetCharacters - 3)
        return String(text[..<index]) + "..."
    }
    
    /// Splits text into chunks that fit within a token limit
    func splitIntoChunks(_ text: String, maxTokensPerChunk: Int) -> [String] {
        let targetCharactersPerChunk = Int(Double(maxTokensPerChunk) * averageCharactersPerToken * 0.9)
        
        var chunks: [String] = []
        var currentChunk = ""
        
        // Split by paragraphs first
        let paragraphs = text.components(separatedBy: "\n\n")
        
        for paragraph in paragraphs {
            let paragraphWithSeparator = paragraph + "\n\n"
            
            if (currentChunk.count + paragraphWithSeparator.count) <= targetCharactersPerChunk {
                currentChunk += paragraphWithSeparator
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                
                // If the paragraph itself is too long, split it further
                if paragraphWithSeparator.count > targetCharactersPerChunk {
                    let subChunks = splitLongText(paragraphWithSeparator, maxCharacters: targetCharactersPerChunk)
                    chunks.append(contentsOf: subChunks)
                    currentChunk = ""
                } else {
                    currentChunk = paragraphWithSeparator
                }
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return chunks
    }
    
    /// Splits a long text into smaller chunks at sentence boundaries
    private func splitLongText(_ text: String, maxCharacters: Int) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""
        
        // Try to split by sentences
        let sentences = text.components(separatedBy: ". ")
        
        for (index, sentence) in sentences.enumerated() {
            let sentenceWithPeriod = sentence + (index < sentences.count - 1 ? ". " : "")
            
            if (currentChunk.count + sentenceWithPeriod.count) <= maxCharacters {
                currentChunk += sentenceWithPeriod
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                }
                
                // If a single sentence is too long, we have to break it
                if sentenceWithPeriod.count > maxCharacters {
                    let hardSplit = hardSplitText(sentenceWithPeriod, maxCharacters: maxCharacters)
                    chunks.append(contentsOf: hardSplit)
                    currentChunk = ""
                } else {
                    currentChunk = sentenceWithPeriod
                }
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
    
    /// Hard splits text at character boundaries when no better option exists
    private func hardSplitText(_ text: String, maxCharacters: Int) -> [String] {
        var chunks: [String] = []
        var startIndex = text.startIndex
        
        while startIndex < text.endIndex {
            let remainingCharacters = text.distance(from: startIndex, to: text.endIndex)
            let chunkSize = min(maxCharacters - 3, remainingCharacters) // Leave room for ellipsis
            let endIndex = text.index(startIndex, offsetBy: chunkSize)
            
            var chunk = String(text[startIndex..<endIndex])
            if endIndex < text.endIndex {
                chunk += "..."
            }
            
            chunks.append(chunk)
            startIndex = endIndex
        }
        
        return chunks
    }
    
    /// Calculates a checksum for text content (for caching)
    func calculateChecksum(for text: String) -> String {
        let data = text.data(using: .utf8) ?? Data()
        let hash = data.base64EncodedString()
        
        // Return first 16 characters of the hash
        return String(hash.prefix(16))
    }
} 