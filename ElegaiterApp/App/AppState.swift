//
//  AppState.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine

/// 앱 전역 상태 관리
/// 
/// Android의 `ElegaiterAppState`를 Swift로 변환
@MainActor
class AppState: ObservableObject {
    /// 네트워크 상태
    @Published var isOnline: Bool = false
    
    /// 현재 로그인한 사용자 ID
    @Published var currentUserId: String?
    
    init() {
        // 초기화
    }
}

