//
//  EmojiArtDocument.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/19.
//

import SwiftUI
import UniformTypeIdentifiers

class EmojiArtDocument: ReferenceFileDocument {
    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json()
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    static var readableContentTypes: [UTType] {
        [.emojiart]
    }
    
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojiArt = try EmojiArt(json: data)
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    typealias Emoji = EmojiArt.Emoji
    @Published private var emojiArt = EmojiArt() {
        didSet {
            if emojiArt.background != oldValue.background {
                Task {
                    await fetchBackgroundImage() // run the state machine
                }
            }
        }
    }
    
    init() {
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
    
    private func undoablyPerform(_ action: String, with undoManager: UndoManager? = nil, doit: () -> Void) {
        let oldEmojiArt = emojiArt
        doit()
        undoManager?.registerUndo(withTarget: self) { myself in
            // adding a redo
            myself.undoablyPerform(action, with: undoManager) {
                myself.emojiArt = oldEmojiArt
            }
        }
        undoManager?.setActionName(action)
    }
    
    func setBackground(_ url:URL?, undowith undoManager: UndoManager? = nil) {
        undoablyPerform("Set Background", with: undoManager) {
            emojiArt.background = url
        }
    }
    
    func addEmoji(_ emoji: String, at position: Emoji.Position, size: CGFloat, undowith undoManager: UndoManager? = nil) {
        undoablyPerform("Add Emoji", with: undoManager) {
            emojiArt.addEmoji(emoji, at: position, size: Int(size))
        }
        
    }
    
    func removeEmoji(_ emoji: Emoji, undowith undoManager: UndoManager? = nil) {
        undoablyPerform("Add \(emoji.string)", with: undoManager) {
            
        }
        emojiArt.removeEmoji(emoji)
    }
    
    func removeAll(undowith undoManager: UndoManager? = nil) {
        undoablyPerform("Remove All Emojis", with: undoManager) {
            emojiArt.removeAll()
        }
    }
    
    func move(_ emoji: Emoji, by offset: CGOffset, undowith undoManager: UndoManager? = nil) {
        undoablyPerform("Move \(emoji.string)", with: undoManager) {
            let currentPosition = emojiArt[emoji].position
            emojiArt[emoji].position = Emoji.Position(
                x: currentPosition.x + Int(offset.width),
                y: currentPosition.y - Int(offset.height)
            )
        }
    }
    
    func move(emojiId: Emoji.ID, by offset: CGOffset, undowith undoManager: UndoManager? = nil) {
        undoablyPerform("Move Emoji", with: undoManager) {
            //        move(emojis[emojiId], by: offset)
            if let emoji = emojiArt[emojiId] {
                move(emoji, by: offset, undowith: undoManager)
            }
        }
    }
    
    func resize(_ emoji: Emoji, by scale: CGFloat, undowith undoManager: UndoManager? = nil) {
        undoablyPerform("Resize \(emoji.string)", with: undoManager) {
            let currentSize = CGFloat(emojiArt[emoji].size)
            emojiArt[emoji].size = Int(currentSize * scale)
        }
    }
    
    func resize(emojiId: Emoji.ID, by scale: CGFloat, undowith undoManager: UndoManager? = nil) {
        undoablyPerform("Resize Emoji", with: undoManager) {
            if let emoji = emojiArt[emojiId] {
                resize(emoji, by: scale, undowith: undoManager)
            }
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

extension UTType {
    static let emojiart = UTType(exportedAs: "com.hannahfromaland.emojiart")
}
