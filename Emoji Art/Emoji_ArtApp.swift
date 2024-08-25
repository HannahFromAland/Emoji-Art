//
//  Emoji_ArtApp.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/19.
//

import SwiftUI

@main
struct Emoji_ArtApp: App {
    @StateObject var paletteStore = PaletteStore(named: "Main")
    @StateObject var defaultDocument = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: defaultDocument)
                .environmentObject(paletteStore)
        }
    }
}
