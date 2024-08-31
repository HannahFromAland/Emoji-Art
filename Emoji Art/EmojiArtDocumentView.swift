//
//  EmojiArtDocumentView.swift
//  Emoji Art
//
//  Created by HannPC on 2024/8/19.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @Environment(\.undoManager) var undoManager
    
    @StateObject var paletteStore = PaletteStore(named: "Shared")
    
    typealias Emoji = EmojiArt.Emoji
    @ObservedObject var document: EmojiArtDocument
    
    private let emojis = "🥲🥪🍰🥞🧇🍕🧇🍍🍑🍓🍇🍌🍋‍🟩🍋🤍🍊🍐🍎🩷"
    
    @ScaledMetric private var paletteEmojiSize: CGFloat = 40

    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser()
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
        .environmentObject(paletteStore)
    }
    
    private var documentBody: some View {
        GeometryReader{ geometry in
            ZStack {
                Color.white
                if document.background.isFetching {
                    ProgressView()
                        .tint(.blue)
                        .position(Emoji.Position.zero.in(geometry))
                }
                documentContents(in: geometry)
                    .scaleEffect(zoom * gestureZoom)
                    .offset(pan + gesturePan)
            }
            .gesture(panGesture.simultaneously(with: zoomGesture))
            .dropDestination(for: Sturldata.self) {sturldata, location in
                return drop(sturldata, at: location, in: geometry)
            }
            .onChange(of: document.background.failureReason) {
                showBackgroundFailureAlert = (document.background.failureReason != nil)
            }
            .onChange(of: document.background.uiImage) {
//                document.removeAll(undowith: undoManager)
                zoomToFit(document.background.uiImage?.size, in: geometry)
            }
            .alert(
                "Set Background",
                isPresented: $showBackgroundFailureAlert,
                presenting: document.background.failureReason,
                actions: { reason in
                    Button("OK", role: .cancel) { }
                },
                message: { reason in
                    Text(reason)
                }
            )
        }
    }
    
    private func zoomToFit(_ size: CGSize?, in geometry: GeometryProxy) {
        if let size {
            withAnimation {
                let zoomRect = CGRect(center: .zero, size: size)
                if zoomRect.width > 0, zoomRect.height > 0, geometry.size.width > 0, geometry.size.height > 0 {
                    let heightZoom = geometry.size.height / zoomRect.size.height
                    let widthZoom = geometry.size.width / zoomRect.size.width
//                    print("heightzoom \(heightZoom), widthzoom \(widthZoom)")
                    zoom = min(heightZoom, widthZoom)
                    pan = CGOffset(
                        width: -zoomRect.midX * zoom,
                        height: -zoomRect.midY * zoom
                    )
            }

            }
        }
    }
    
    @State private var showBackgroundFailureAlert = false
    @State private var selection = Set<Emoji.ID>()
    
    @State private var zoom: CGFloat = 1
    @State private var pan: CGOffset = .zero
    
    @GestureState private var gestureZoom: CGFloat = 1
    @GestureState private var gestureZoomEmoji: CGFloat = 1
    @GestureState private var gesturePan: CGOffset = .zero
    
    private var zoomGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.1)
            .updating($gestureZoom) { inMotionPinchScale, gestureZoom, _ in
                if selection.isEmpty {
                    gestureZoom = inMotionPinchScale.magnification
                }
            }
            .updating($gestureZoomEmoji) { value, gestureZoomEmoji, _ in
                if !selection.isEmpty {
                   gestureZoomEmoji = value.magnification
               }
            }
            .onEnded { endingPinchScale in
                if selection.isEmpty {
                    zoom *= endingPinchScale.magnification
                } else {
                    for emoji in document.emojis where selection.contains(emoji.id) {
                        document.resize(emoji, by: endingPinchScale.magnification, undowith: undoManager)
                    }
                }
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
    
    @State private var panEmoji: CGOffset = .zero
    
    
    // can also use border to identify selected emoji as follows:
    // .border(selection.contains(emoji.id) ? Color.purple: Color.clear, width: 4)
    @ViewBuilder
    private func documentContents(in geometry: GeometryProxy) -> some View {
        if let uiImage = document.background.uiImage {
            Image(uiImage: uiImage)
                .position(Emoji.Position.zero.in(geometry))
                .onTapGesture {
                    selection = Set<Emoji.ID>()
                }
        }
        ForEach(document.emojis) { emoji in
            emojiView(emoji, geometry: geometry)
        }
    }
    
    private func emojiView(_ emoji: Emoji, geometry: GeometryProxy) -> some View {
        Text(emoji.string)
            .font(emoji.font)
            .shadow(color: selection.contains(emoji.id) ? .gray : .clear, radius: 10, x: 1, y: 1)
            .onTapGesture {
                toggleSelection(emoji)
            }
//            .overlay(selection.contains(emoji.id) ? deleteButton(emoji) : nil)
            .scaleEffect(selection.contains(emoji.id) ? CGFloat(1) * gestureZoomEmoji :  CGFloat(1))
            .gesture(dragGesture(emoji))
            .frame(width: CGFloat(emoji.size + 10), height: CGFloat(emoji.size + 10))
            .zIndex(2.0)
            .contextMenu{
                Button(role:.destructive) {
                    document.removeEmoji(emoji, undowith: undoManager)
                } label: {
                    Label("Delete", systemImage: "minus.circle")
                }
            }
            .position(emoji.position.in(geometry))
    }
    
    private func deleteButton(_ emoji: Emoji) -> some View {
        GeometryReader { geometry in
            Image(systemName: "minus.circle")
                .foregroundColor(.orange)
                .font(.system(size: CGFloat(emoji.size / 4)))
                .position(CGPoint(x: geometry.frame(in: .local).width + 8, y:geometry.frame(in: .local).height + 8))
                .onTapGesture {
                    document.removeEmoji(emoji, undowith: undoManager)
                }
        }

    }
    
    private func dragGesture(_ emoji: Emoji) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // onChanged will update the @State as it changes, while updating shows transient UI state during the gest
                if selection.contains(emoji.id) {
                    for emoji in document.emojis where selection.contains(emoji.id) {
                        document.move(emoji, by: value.translation, undowith: undoManager)
                    }
                    
                } else{
                    document.move(emoji, by: value.translation, undowith: undoManager)
                }
            }
            .onEnded { value in
                if selection.contains(emoji.id) {
                    for emoji in document.emojis where selection.contains(emoji.id) {
                        document.move(emoji, by: value.translation, undowith: undoManager)
                    }
                } else {
                    document.move(emoji, by: value.translation, undowith: undoManager)
                }
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
                document.setBackground(url, undowith: undoManager)
                return true
            case .string(let emoji):
                document.addEmoji(
                    emoji,
                    at: emojiPosition(at: location, in: geometry),
                    size: paletteEmojiSize / zoom,
                    undowith: undoManager
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
