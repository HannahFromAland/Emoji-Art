//
//  PaletteStore.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/22.
//

import SwiftUI

extension UserDefaults {
    func palettes(forKey key: String) -> [Palette] {
        if let jsonData = data(forKey: key),
           let decodedPalettes = try? JSONDecoder().decode([Palette].self, from: jsonData) {
            return decodedPalettes
        } else {
            return []
        }
    }
    func set(_ palettes: [Palette], forKey key: String) {
        let data = try? JSONEncoder().encode(palettes)
        set(data, forKey: key)
    }
}

extension PaletteStore: Hashable {
    static func == (lhs: PaletteStore, rhs: PaletteStore) -> Bool {
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

class PaletteStore: ObservableObject, Identifiable {
    let name: String
    
    var id: String { name }
    
    private var userDefaultsKey: String { "PaletteStore:" + name }
    
    var palettes: [Palette] {
        get {
            UserDefaults.standard.palettes(forKey: userDefaultsKey)
        }
        set {
            if !newValue.isEmpty {
                // avoid empty palette
                UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
                objectWillChange.send() // substitution to remove @Published
            }

        }
    }
    
    @Published private var _cursorIndex = 0
    
    init(named name: String) {
        self.name = name
        if palettes.isEmpty {
            palettes = Palette.builtins
            if palettes.isEmpty {
                palettes = [Palette(name: "Warning", emojis: "⚠️")]
            }
        }
        observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
    }
    
    @State private var observer: NSObjectProtocol?
    
    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
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
