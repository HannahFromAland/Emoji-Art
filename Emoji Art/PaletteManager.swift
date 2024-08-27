//
//  PaletteManager.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/26.
//

import SwiftUI

struct PaletteManager: View {
    let stores: [PaletteStore]
    
    @State private var selectedStore: PaletteStore?
    
    var body: some View {
        NavigationSplitView {
            List(stores, selection: $selectedStore) { store in
                Text(store.name) // BAD!!!!
                    .tag(store)
            }
        } content: {
            if let selectedStore {
                EditablePaletteList(store: selectedStore)
            }
        } detail: {
            
        }
    }
}

//#Preview {
//    PaletteManager()
//}
