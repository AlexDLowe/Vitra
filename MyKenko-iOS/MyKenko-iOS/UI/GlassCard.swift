//
//  GlassCard.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//


import SwiftUI

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.15))
            )
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}
