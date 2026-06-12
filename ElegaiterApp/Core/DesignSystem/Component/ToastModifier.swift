//
//  ToastModifier.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI

/// 토스트 메시지 표시를 위한 View Modifier
/// 
/// Android의 Toast를 SwiftUI로 변환
/// - 하단에 메시지 표시
/// - 2초 후 자동으로 사라짐
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented {
                        VStack {
                            Spacer()
                            
                            Text(message)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(8)
                                .padding(.bottom, 100)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: isPresented)
                        .onAppear {
                            // 2초 후 자동으로 사라짐
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isPresented = false
                            }
                        }
                    }
                }
            )
    }
}

// MARK: - View Extension

extension View {
    /// 토스트 메시지 표시
    /// 
    /// - Parameters:
    ///   - isPresented: 표시 여부
    ///   - message: 메시지 텍스트
    /// - Returns: 토스트가 적용된 View
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}

