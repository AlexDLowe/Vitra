//
//  ProgressRing.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//


import SwiftUI

struct ProgressRing: View {
    var progress: Double // 0...1
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.15)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.title3).bold()
        }
        .padding(8)
        .background(.thinMaterial, in: Circle())
    }
}
