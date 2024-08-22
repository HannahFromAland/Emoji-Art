//
//  EmojiArtDocumentView.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/19.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    typealias Emoji = EmojiArt.Emoji
    @ObservedObject var document: EmojiArtDocument
    
    private let emojis = "🥲🥪🍰🥞🧇🍕🧇🍍🍑🍓🍇🍌🍋‍🟩🍋🤍🍊🍐🍎🩷"
    
    private let paletteEmojiSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            ScrollingEmojis(emojis)
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
    
    private var documentBody: some View {
        GeometryReader{ geometry in
            ZStack {
                Color.white
                AsyncImage(url: document.background)
                 .position(Emoji.Position.zero.in(geometry))
                 .scaledToFill()
                ForEach(document.emojis) { emoji in
                    Text(emoji.string)
                        .font(emoji.font)
                        .position(emoji.position.in(geometry))
                }
            }
            .dropDestination(for: Sturldata.self) {sturldata, location in
                return drop(sturldata, at: location, in: geometry)
            }
        }

    }
    
    private func drop(_ sturldata: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        for sud in sturldata {
            switch sud {
            case .url(let url):
                document.setBackground(url)
                return true
            case .string(let emoji):
                document.addEmoji(
                    emoji,
                    at: emojiPosition(at: location, in: geometry),
                    size: paletteEmojiSize
                )
                return true
            default:
                break
            }
        }
        return false
    }
    
    private func emojiPosition(at location: CGPoint, in geometry: GeometryProxy) -> Emoji.Position {
        let centerX = geometry.frame(in: .local).midX
        let centerY = geometry.frame(in: .local).midY
        let x = Int(location.x - centerX)
        let y = Int(-(location.y - centerY))
        return Emoji.Position(x: x, y: y)
    }
}

struct ScrollingEmojis: View {
    let emojis: [String]
    
    init(_ emojis: String) {
        self.emojis = emojis.uniqued.map(String.init)
    }
    
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .draggable(emoji)
                }
            }
        }
    }
}
#Preview {
    EmojiArtDocumentView(document: EmojiArtDocument())
}
