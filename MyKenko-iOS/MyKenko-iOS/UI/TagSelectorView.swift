//
//  TagSelectorView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 08/11/2025.
//

import SwiftUI
import MyKenkoCore

struct TagSelectorView: View {
    @Binding var selectedTags: [Recipe.Tag]

    let allTags = Recipe.Tag.allCases

    var body: some View {
        VStack(alignment: .leading) {
            Text("Tags")
                .font(.headline)
            WrapHStack(spacing: 8) {
                ForEach(allTags, id: \.self) { tag in
                    TagChip(tag: tag, isSelected: selectedTags.contains(tag)) {
                        toggle(tag)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func toggle(_ tag: Recipe.Tag) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

// MARK: - Reusable chip view
struct TagChip: View {
    let tag: Recipe.Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Horizontal wrap helper
struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        // Use a concrete custom Layout implementation that supports wrapping
        FlowLayout(spacing: spacing) {
            content()
        }
    }
}

// Simple flow layout that wraps subviews to new lines when they exceed the container width.
// Uses the Layout protocol (iOS 16+, macOS 13+).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity

        // If no subviews, return zero size
        guard !subviews.isEmpty else { return .zero }

        // If width is infinite, place everything in a single line
        if maxWidth == .infinity {
            var totalWidth: CGFloat = 0
            var maxHeight: CGFloat = 0
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                totalWidth += size.width
                if index > 0 { totalWidth += spacing }
                maxHeight = max(maxHeight, size.height)
            }
            return CGSize(width: totalWidth, height: maxHeight)
        }

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let itemWidth = size.width
            let itemHeight = size.height

            if currentX > 0 && (currentX + itemWidth) > maxWidth {
                // move to next line
                currentY += lineHeight + spacing
                currentX = 0
                lineHeight = 0
            }

            // place item
            currentX += (index > 0 && currentX > 0 ? spacing : 0) + itemWidth
            lineHeight = max(lineHeight, itemHeight)
        }

        return CGSize(width: maxWidth.isFinite ? maxWidth : currentX, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let itemWidth = size.width
            let itemHeight = size.height

            if currentX > bounds.minX && (currentX + itemWidth) > bounds.maxX {
                // wrap
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(width: itemWidth, height: itemHeight))

            currentX += itemWidth + spacing
            lineHeight = max(lineHeight, itemHeight)
        }
    }
}
