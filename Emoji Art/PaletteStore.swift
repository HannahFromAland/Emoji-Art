//
//  PaletteStore.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/22.
//

import SwiftUI

class PaletteStore: ObservableObject {
    let name: String
    @Published var palettes: [Palette] {
        didSet {
            if palettes.isEmpty, !oldValue.isEmpty {
                palettes = oldValue
            }
        }
    }
    
    init(named name: String) {
        self.name = name
        palettes = Palette.builtins
        if palettes.isEmpty {
            palettes = [Palette(name: "Warning", emojis: "⚠️")]
        }
    }
    
    @Published private var _cursorIndex = 0
    
    var cursorIndex: Int {
        get { boundsCheckedPaletteIndex(_cursorIndex) }
        set { _cursorIndex = boundsCheckedPaletteIndex(newValue) }
    }
    
    private func boundsCheckedPaletteIndex(_ index: Int) -> Int {
        var index = index % palettes.count
        if index < 0 {
            index += palettes.count
        }
        return index
    }
    
    // MARK: - Adding Palettes
    
    // add a new palette at the end of current collection
    func append(_ palette: Palette) {
        // first try to check if there is exsiting similar palette being added already
        // if yes, then remove the existing one and add it at the end
        if let index = palettes.firstIndex(where:  {
            $0.id == palette.id
        }) {
            palettes.remove(at: index)
            palettes.append(palette)
        } else {
            palettes.append(palette)
        }
    }
    
    // wrapper function for creating a Palette first
    func append(name: String, emojis: String) {
        append(Palette(name: name, emojis: emojis))
    }
    
    // insert a new palette at a given index, if not specify the index then insert at the current _cursorIndex
    func insert(_ palette: Palette, at insertionIndex: Int? = nil) {
        // make sure index is eligible
        let insertionIndex = boundsCheckedPaletteIndex(insertionIndex ?? cursorIndex)
        if let index = palettes.firstIndex(where: {$0.id == palette.id}) {
            palettes.move(fromOffsets: IndexSet([index]), toOffset: insertionIndex)
        } else {
            palettes.insert(palette, at: insertionIndex)
        }
    }
    
    // wrapper for creating a Palette
    func insert(name: String, emojis: String, at index: Int? = nil) {
        insert(Palette(name: name, emojis: emojis), at: index)
    }
}
