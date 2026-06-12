//
//  GlobalToastView.swift
//  ElegaiterApp
//
//  Created on 2025-12-05.
//

import SwiftUI

/// 전역 토스트 뷰
/// 
/// 루트 뷰에 오버레이되어 표시되는 토스트 메시지
/// - 화면 이동과 관계없이 유지됨
/// - 디자인: 배경 #00000099, 라디어스 12, 상하좌우 여백 16, Body3 폰트, 흰색 텍스트
struct GlobalToastView: View {
    @ObservedObject var toastManager: ToastManager
    
    var body: some View {
        VStack {
            Spacer()
            
            if toastManager.isShowing, let message = toastManager.currentMessage {
                Text(message)
                    .typography(ElegaiterTypography.Body3)
                    .foregroundColor(.white)
                    .padding(16) // 상하좌우 여백 16
                    .background(
                        Color(red: 0, green: 0, blue: 0, opacity: 153.0 / 255.0) // #00000099 (alpha: 153/255)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 16) // 외부 좌우 여백 16
                    .padding(.bottom, 100)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8),
                        value: toastManager.isShowing
                    )
            }
        }
        .allowsHitTesting(false) // 터치 이벤트 차단 (뒤의 뷰와 상호작용 가능)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        
        VStack {
            Button("토스트 표시") {
                ToastManager.shared.show(message: "토스트 메시지 예시입니다.")
            }
        }
        
        GlobalToastView(toastManager: ToastManager.shared)
    }
}
