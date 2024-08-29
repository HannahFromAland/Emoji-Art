//
//  EmojiArtDocument.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/19.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    typealias Emoji = EmojiArt.Emoji
    @Published private var emojiArt = EmojiArt() {
        didSet {
            autosave()
            if emojiArt.background != oldValue.background {
                Task {
                    await fetchBackgroundImage() // run the state machine
                }
            }
        }
    }
    
    private let autosaveURL: URL = URL.documentsDirectory.appendingPathComponent("Autosaved.emojiart")
    
    private func autosave() {
        save(to: autosaveURL)
//        print("autosaved to \(autosaveURL)")
    }
    
    private func save(to url: URL) {
        do {
            let data = try emojiArt.json()
            try data.write(to: url)
        } catch let error {
            print("EmojiArtDocument: error while saving \(error.localizedDescription)")
        }
    }
    
    init() {
        if let data = try? Data(contentsOf: autosaveURL),
           let autosavedEmojiArt = try? EmojiArt(json: data) {
            emojiArt = autosavedEmojiArt
        }
    }
    
    var emojis: [Emoji] {
        emojiArt.emojis
    }
    
//    var background: URL? {
//        emojiArt.background
//    }
    @Published var background: Background = .none
    
    // MARK: - Background Image
    @MainActor
    private func fetchBackgroundImage() async {
        if let url = emojiArt.background {
            background = .fetching(url)
            do {
                let image = try await fetchUIImage(from: url)
                if url == emojiArt.background {
                    // the check is for a previous (slow) fetch finally succeeded after a following fetch has already finished and displayed
                    // so once the async fetch is back with the result, needs to check if there is already a working one
                    background = .found(image)
                }
            } catch {
                background = .failed("Couldn't set background: \(error.localizedDescription)")
            }
        } else {
            background = .none
        }
    }
    
    private func fetchUIImage(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let uiImage = UIImage(data: data) {
            return uiImage
        } else {
            throw FetchError.badImageData
        }
    }
    
    enum FetchError: Error {
        case badImageData
    }
    
    enum Background {
        case none
        case fetching(URL)
        case found(UIImage)
        case failed(String)
        
        var uiImage: UIImage? {
            switch self {
            case .found(let uiImage): return uiImage
            default: return nil
            }
        }
        
        var urlBeingFetched: URL? {
            switch self {
            case .fetching(let url): return url
            default: return nil
            }
        }
        
        var isFetching: Bool {
            urlBeingFetched != nil
        }
        
        var failureReason: String? {
            switch self {
            case .failed(let reason): return reason
            default: return nil
            }
        }
    }
    
    // MARK: - Intent(s)
    
    func setBackground(_ url:URL?) {
        emojiArt.background = url
    }
    
    func addEmoji(_ emoji: String, at position: Emoji.Position, size: CGFloat) {
        emojiArt.addEmoji(emoji, at: position, size: Int(size))
    }
    
    func removeEmoji(_ emoji: Emoji) {
        emojiArt.removeEmoji(emoji)
    }
    
    func removeAll() {
        emojiArt.removeAll()
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
