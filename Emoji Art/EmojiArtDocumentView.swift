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
            PaletteChooser()
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
    
    private var documentBody: some View {
        GeometryReader{ geometry in
            ZStack {
                Color.white
                documentContents(in: geometry)
                    .scaleEffect(zoom * gestureZoom)
                    .offset(pan + gesturePan)
            }
            .dropDestination(for: Sturldata.self) {sturldata, location in
                return drop(sturldata, at: location, in: geometry)
            }
            .gesture(panGesture.simultaneously(with: zoomGesture))
        }
    }
    
    @State private var selection = Set<Emoji.ID>()
    
    @State private var zoom: CGFloat = 1
    @State private var pan: CGOffset = .zero
    
    @GestureState private var gestureZoom: CGFloat = 1
    @GestureState private var gesturePan: CGOffset = .zero
    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { inMotionPinchScale, gestureZoom, _ in
                gestureZoom = inMotionPinchScale
            }
            .onEnded { endingPinchScale in
                zoom *= endingPinchScale
            }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePan) { value, gesturePan, _ in
                gesturePan  = value.translation
            }
            .onEnded { value in
                pan += value.translation
            }
    }
    
    @State private var zoomEmoji: CGFloat = 1
    @State private var panEmoji: CGOffset = .zero
    
    @GestureState private var gestureZoomEmoji: CGFloat = 1
    @GestureState private var gesturePanEmoji: CGOffset = .zero

    @ViewBuilder
    private func documentContents(in geometry: GeometryProxy) -> some View {
        AsyncImage(url: document.background)
            .position(Emoji.Position.zero.in(geometry))
            .onTapGesture {
                selection = Set<Emoji.ID>()
            }
        ForEach(document.emojis) { emoji in
            Text(emoji.string)
                .font(emoji.font)
            //                .shadow(color: .gray, radius:  !isDragging && selection.contains(emoji.id) ? 25 : 0, x: 1, y: 1)
                .border(selection.contains(emoji.id) ? Color.purple: Color.clear, width: 4)
                .offset(selection.contains(emoji.id) ? panEmoji + gesturePan : .zero)
                .onTapGesture {
                    toggleSelection(emoji)
                }
                .gesture(selection.contains(emoji.id) ? dragGesture(emoji) : nil)
                .position(emoji.position.in(geometry))
        }
    }
    
    private func dragGesture(_ emoji: Emoji) -> some Gesture {
        DragGesture()
            .onChanged { value in
                for emoji in document.emojis where selection.contains(emoji.id) {
                    document.move(emoji, by: value.translation)
                }
            }
            .onEnded { value in
                for emoji in document.emojis where selection.contains(emoji.id) {
                    document.move(emoji, by: value.translation)
                }
                panEmoji += value.translation
            }
    }
    
    private func toggleSelection(_ emoji: Emoji) {
        if selection.contains(emoji.id) {
            selection.remove(emoji.id)
        } else {
            selection.insert(emoji.id)
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
                    size: paletteEmojiSize / zoom
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
        let x = Int((location.x - centerX - pan.width) / zoom)
        let y = Int((-(location.y - centerY - pan.height) / zoom))
        return Emoji.Position(x: x, y: y)
    }
}

#Preview {
    EmojiArtDocumentView(document: EmojiArtDocument())
        .environmentObject(PaletteStore(named: "Preview"))
}
