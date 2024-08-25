//
//  EmojiArtDocument.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/19.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    typealias Emoji = EmojiArt.Emoji
    @Published private var emojiArt = EmojiArt()
    
    init() {
        emojiArt.addEmoji("🤯", at: .init(x: -200, y: -150), size: 200)
        emojiArt.addEmoji("😈", at: .init(x: 200, y: 150), size: 80)
    }
    
    var emojis: [Emoji] {
        emojiArt.emojis
    }
    
    var background: URL? {
        emojiArt.background
    }
    
    // MARK: - Intent(s)
    
    func setBackground(_ url:URL?) {
        emojiArt.background = url
    }
    
    func addEmoji(_ emoji: String, at position: Emoji.Position, size: CGFloat) {
        emojiArt.addEmoji(emoji, at: position, size: Int(size))
    }
    
    func move(_ emoji: Emoji, by offset: CGOffset) {
        let currentPosition = emojiArt[emoji].position
        emojiArt[emoji].position = Emoji.Position(
            x: currentPosition.x + Int(offset.width),
            y: currentPosition.y - Int(offset.height)
        )
    }
    
    func move(emojiId: Emoji.ID, by offset: CGOffset) {
//        move(emojis[emojiId], by: offset)
        if let emoji = emojiArt[emojiId] {
            move(emoji, by: offset)
        }
    }
    
    func resize(_ emoji: Emoji, by scale: CGFloat) {
        let currentSize = CGFloat(emojiArt[emoji].size)
        emojiArt[emoji].size = Int(currentSize * scale)
    }
    
    func resize(emojiId: Emoji.ID, by scale: CGFloat) {
        if let emoji = emojiArt[emojiId] {
            resize(emoji, by: scale)
        }
    }
}

extension EmojiArt.Emoji {
    var font: Font {
        Font.system(size: CGFloat(size))
    }
}

extension EmojiArt.Emoji.Position {
    func `in`(_ geometry: GeometryProxy) -> CGPoint {
        let centerX = geometry.frame(in: .local).midX
        let centerY = geometry.frame(in: .local).midY
        return CGPoint(x: centerX + CGFloat(x), y: centerY - CGFloat(y))
    }
}
