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
    @State private var lastDragValue: CGFloat = 0
    
    private let dragAreaSize: CGFloat = 8
    private let visualLineThickness: CGFloat = 0.5
    private let activeLineThickness: CGFloat = 2
    
    var body: some View {
        ZStack {
            // Invisible drag area (larger for easier targeting)
            Rectangle()
                .fill(Color.clear)
                .frame(
                    width: orientation == .vertical ? dragAreaSize : nil,
                    height: orientation == .horizontal ? dragAreaSize : nil
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                    isHovered = hovering
                    
                    // Better cursor management
                    if hovering {
                        DispatchQueue.main.async {
                            if orientation == .vertical {
                                NSCursor.resizeLeftRight.set()
                            } else {
                                NSCursor.resizeUpDown.set()
                            }
                        }
                    } else if !isDragging {
                        DispatchQueue.main.async {
                            NSCursor.arrow.set()
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                lastDragValue = orientation == .vertical ? value.translation.width : value.translation.height
                                
                                // Notify that layout is about to change
                                NotificationCenter.default.post(name: NSNotification.Name("PDFLayoutWillChange"), object: nil)
                            }
                            
                            let currentValue = orientation == .vertical ? value.translation.width : value.translation.height
                            let delta = currentValue - lastDragValue
                            lastDragValue = currentValue
                            
                            onDrag(delta)
                        }
                        .onEnded { _ in
                            let wasDragging = isDragging
                            isDragging = false
                            lastDragValue = 0
                            
                            // Notify that layout has changed
                            if wasDragging {
                                NotificationCenter.default.post(name: NSNotification.Name("PDFLayoutDidChange"), object: nil)
                            }
                            
                            // Reset cursor if not hovering
                            if !isHovered {
                                DispatchQueue.main.async {
                                    NSCursor.arrow.set()
                                }
                            }
                        }
                )
            
            // Visual divider line
            Rectangle()
                .fill(dividerColor)
                .frame(
                    width: orientation == .vertical ? (isActive ? activeLineThickness : visualLineThickness) : nil,
                    height: orientation == .horizontal ? (isActive ? activeLineThickness : visualLineThickness) : nil
                )

        }
    }
    
    private var isActive: Bool {
        isHovered || isDragging
    }
    
    private var dividerColor: Color {
        if isDragging {
            return DesignSystem.Colors.accent.opacity(0.6)
        } else if isHovered {
            return DesignSystem.Colors.accent.opacity(0.3)
        } else {
            return DesignSystem.Colors.border.opacity(0.3)
        }
    }
}

#Preview {
    HStack {
        Rectangle()
            .fill(DesignSystem.Colors.accent)
            .frame(width: 200, height: 300)
        
        ResizableDivider(orientation: .vertical) { delta in
            print("Dragged by: \(delta)")
        }
        
        Rectangle()
            .fill(DesignSystem.Colors.secondaryAccent)
            .frame(width: 200, height: 300)
    }
    .frame(width: 500, height: 300)
} 