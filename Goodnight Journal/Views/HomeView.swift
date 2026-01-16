//
//  HomeView.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/13/26.
//

import SwiftUI

struct Quote: Codable {
    let text: String
}

struct HomeView: View {
    let namespace: Namespace.ID
    let onStart: () -> Void
    let onLogout: () -> Void
    @State private var currentQuote: String = "You are not alone."
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with menu button
                HStack {
                    Spacer()
                    Menu {
                        Button(action: {
                            soundManager.toggleSound()
                        }) {
                            Label(
                                soundManager.isSoundEnabled ? "Turn off sound" : "Turn on sound",
                                systemImage: soundManager.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
                            )
                        }
                        
                        Button(role: .destructive, action: onLogout) {
                            Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Small circle with matched geometry
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .matchedGeometryEffect(id: "breatheCircle", in: namespace)
                
                // Quote text
                Text(currentQuote)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Start button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        onStart()
                    }
                }) {
                    Text("Start")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 44)
                        .background(Color(white: 0.16))
                        .clipShape(Capsule())
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Today's date
                Text(formattedDate())
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            loadRandomQuote()
        }
    }
    
    private func loadRandomQuote() {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data),
              let randomQuote = quotes.randomElement() else {
            return
        }
        currentQuote = randomQuote.text
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
}

#Preview {
    @Previewable @Namespace var namespace
    HomeView(namespace: namespace, onStart: {}, onLogout: {})
}
