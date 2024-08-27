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
    @StateObject var paletteStore2 = PaletteStore(named: "Alternate")
    @StateObject var paletteStore3 = PaletteStore(named: "Special")
    @StateObject var defaultDocument = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            PaletteManager(stores: [paletteStore, paletteStore2, paletteStore3])
//            EmojiArtDocumentView(document: defaultDocument)
                .environmentObject(paletteStore)
        }
    }
}
