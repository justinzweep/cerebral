//
//  ResizableDivider.swift
//  cerebral
//
//  Created by Justin Zweep on 26/06/2025.
//

import SwiftUI

struct ResizableDivider: View {
    enum Orientation {
        case vertical, horizontal
    }
    
    let orientation: Orientation
    let onDrag: (CGFloat) -> Void
    
    @State private var isDragging = false
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Invisible drag area (larger for easier targeting)
            Rectangle()
                .fill(Color.clear)
                .frame(
                    width: orientation == .vertical ? 16 : nil,
                    height: orientation == .horizontal ? 16 : nil
                )
                .contentShape(Rectangle())
                .cursor(orientation == .vertical ? .resizeLeftRight : .resizeUpDown)
                .onHover { hovering in
                    isHovered = hovering
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                            }
                            let delta = orientation == .vertical ? value.translation.width : value.translation.height
                            onDrag(delta)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            
            // Visual divider line
            Rectangle()
                .fill(DesignSystem.Colors.border.opacity(0.3))
                .frame(
                    width: orientation == .vertical ? 1 : nil,
                    height: orientation == .horizontal ? 1 : nil
                )
            
            // Hover/drag indicator
            if isHovered || isDragging {
                Rectangle()
                    .fill(DesignSystem.Colors.accent.opacity(isDragging ? 0.4 : 0.2))
                    .frame(
                        width: orientation == .vertical ? 3 : nil,
                        height: orientation == .horizontal ? 3 : nil
                    )
                    .animation(DesignSystem.Animation.microInteraction, value: isDragging)
                    .animation(DesignSystem.Animation.microInteraction, value: isHovered)
            }
        }
    }
}

// MARK: - NSCursor Extension for Custom Cursors

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    HStack {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 200, height: 300)
        
        ResizableDivider(orientation: .vertical) { delta in
            print("Dragged by: \(delta)")
        }
        
        Rectangle()
            .fill(Color.red)
            .frame(width: 200, height: 300)
    }
    .frame(width: 500, height: 300)
} 