//
//  AuthenticationView.swift
//  Goodnight Journal
//
//  Created by Hiroo Aoyama on 1/15/26.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isLoading = false
    @State private var showError = false
    @State private var breatheScale: CGFloat = 1.0
    @State private var breatheOpacity: Double = 0.6
    let namespace: Namespace.ID?
    
    init(namespace: Namespace.ID? = nil) {
        self.namespace = namespace
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // White circle with breathing animation
                Group {
                    let circle = Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .scaleEffect(breatheScale)
                        .opacity(breatheOpacity)
                        .onAppear {
                            startBreathingAnimation()
                        }
                    
                    if let namespace = namespace {
                        circle.matchedGeometryEffect(id: "breatheCircle", in: namespace)
                    } else {
                        circle
                    }
                }
                
                // App name and tagline
                VStack(spacing: 8) {
                    Text("Goodnight Journal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Your private space for reflection")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Sign in buttons
                VStack(spacing: 16) {
                    // Apple Sign In Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            let nonce = authManager.startSignInWithAppleFlow()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = nonce
                        },
                        onCompletion: { result in
                            Task {
                                isLoading = true
                                switch result {
                                case .success(let authorization):
                                    do {
                                        try await authManager.signInWithApple(authorization: authorization)
                                    } catch {
                                        showError = true
                                    }
                                case .failure(let error):
                                    print("Sign in with Apple failed: \(error)")
                                    showError = true
                                }
                                isLoading = false
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 44)
                    .cornerRadius(22)
                    
                    // Google Sign In Button
                    Button(action: {
                        Task {
                            isLoading = true
                            do {
                                try await authManager.signInWithGoogle()
                            } catch {
                                showError = true
                            }
                            isLoading = false
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 18))
                            Text("Continue with Google")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(white: 0.16))
                        .cornerRadius(22)
                    }
                }
                .padding(.horizontal, 40)
                
                // Terms and privacy note
                Text("By continuing, you agree to Terms of Service and Privacy Policy around your private and secure journal.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 60)
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .alert("Sign in error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "An error occurred during sign in. Please try again.")
        }
    }
    
    // 3-4 breathing animation: 3 seconds inhale, 4 seconds exhale
    private func startBreathingAnimation() {
        Task {
            while true {
                // Inhale - 3 seconds (expand and brighten)
                withAnimation(.easeInOut(duration: 3.0)) {
                    breatheScale = 1.35
                    breatheOpacity = 1.0
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                
                // Exhale - 4 seconds (contract and dim)
                withAnimation(.easeInOut(duration: 4.0)) {
                    breatheScale = 1.0
                    breatheOpacity = 0.6
                }
                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    AuthenticationView(namespace: namespace)
}
