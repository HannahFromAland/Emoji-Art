//
//  Emoji_ArtApp.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/19.
//

import SwiftUI

@main
struct Emoji_ArtApp: App {
    
    var body: some Scene {
        DocumentGroup(newDocument: { EmojiArtDocument() }) { config in
            EmojiArtDocumentView(document: config.document)
        }
    }
}
