//
//  ToastManager.swift
//  ElegaiterApp
//
//  Created on 2025-12-05.
//

import SwiftUI
import Combine

/// 전역 토스트 메시지 관리자
/// 
/// 화면 이동과 관계없이 토스트 메시지를 표시하고 관리합니다.
/// - 싱글톤 패턴으로 전역에서 접근 가능
/// - 화면 이동 시에도 토스트가 유지됨
@MainActor
class ToastManager: ObservableObject {
    /// 싱글톤 인스턴스
    static let shared = ToastManager()
    
    /// 현재 표시 중인 토스트 메시지
    @Published var currentMessage: String? = nil
    
    /// 토스트 표시 여부
    @Published var isShowing: Bool = false
    
    /// 토스트 표시 시간 (초)
    var displayDuration: TimeInterval = 2.5
    
    /// 자동 숨김 작업
    private var hideTask: Task<Void, Never>?
    
    private init() {}
    
    /// 토스트 메시지 표시
    /// 
    /// - Parameter message: 표시할 메시지
    func show(message: String, duration: TimeInterval? = nil) {
        // 기존 숨김 작업 취소
        hideTask?.cancel()
        
        // 애니메이션과 함께 새 메시지 설정
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentMessage = message
            isShowing = true
        }
        
        // 지정된 시간 후 자동으로 숨김
        let durationToUse = duration ?? displayDuration
        hideTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(durationToUse * 1_000_000_000))
            
            // Task가 취소되지 않았고, 같은 메시지가 여전히 표시 중인 경우에만 숨김
            if !Task.isCancelled && currentMessage == message {
                await MainActor.run {
                    // 애니메이션과 함께 숨김
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isShowing = false
                    }
                    
                    // 애니메이션 완료 후 메시지 초기화 (애니메이션 시간 고려)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.currentMessage = nil
                    }
                }
            }
        }
    }
    
    /// 토스트 메시지 즉시 숨김
    func hide() {
        hideTask?.cancel()
        
        // 애니메이션과 함께 숨김
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isShowing = false
        }
        
        // 애니메이션 완료 후 메시지 초기화
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.currentMessage = nil
        }
    }
}
