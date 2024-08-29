//
//  EmojiArt.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/19.
//

import Foundation

struct EmojiArt: Codable {
    var background: URL?
    private(set) var emojis = [Emoji]()
    private var uniqueEmojiId = 0
    
    func json() throws -> Data {
        let encoded = try JSONEncoder().encode(self)
//        print("EmojiArt = \(String(data: encoded, encoding: .utf8) ?? "nil")")
        return encoded
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArt.self, from: json)
    }
    
    init() {}
    
    mutating func addEmoji(_ emoji: String, at position: Emoji.Position, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(
            string: emoji,
            position: position,
            size: size,
            id: uniqueEmojiId
        ))
    }
    
    mutating func removeAll() {
        emojis = []
    }
    
    mutating func removeEmoji(_ emoji: Emoji) {
        if let index = index(of: emoji.id) {
            emojis.remove(at: index)
        }
    }
    
    private func index(of emojiID: Emoji.ID) -> Int? {
        emojis.firstIndex(where: {$0.id == emojiID})
    }
    
    subscript(_ emojiId: Emoji.ID) -> Emoji? {
        if let index = index(of: emojiId) {
            return emojis[index]
        } else {
            return nil
        }
    }
    
    subscript(_ emoji: Emoji) -> Emoji {
        get {
            if let index = index(of: emoji.id) {
                return emojis[index]
            } else {
                return emoji // should be substitute with error handling
            }
        }
        set {
            if let index = index(of: emoji.id) {
                emojis[index] = newValue
            }
        }
    }

    struct Emoji: Identifiable, Codable {
        let string: String
        var position: Position
        var size: Int
        var id: Int
        var isSelected: Bool = false
        
        struct Position: Codable {
            var x: Int
            var y: Int
            
            // Self means the structure it is in, equals to Position here
            static let zero = Self(x:0, y: 0)
        }
    }
}
