//
//  ArcadeGameState.swift
//  ElegaiterApp
//
//  Created on 2025-01-XX.
//

import Foundation

/// 아케이드 게임 상태
/// 
/// Android의 `ArcadeGameState` data class를 Swift로 변환
/// - 점수, 콤보, 스턴 시간 등을 관리
struct ArcadeGameState {
    /// 총 점수
    var score: Int = 0
    
    /// 현재 콤보 수
    var combo: Int = 0
    
    /// 남은 스턴 시간 (밀리초)
    var stunRemainingMs: Int64 = 0
    
    /// 배율 (콤보에 따라 결정)
    var multiplier: Float {
        switch combo {
        case 50...:
            return 3.0
        case 40..<50:
            return 2.5
        case 30..<40:
            return 2.0
        case 20..<30:
            return 1.6
        case 10..<20:
            return 1.3
        default:
            return 1.0
        }
    }
    
    /// 스턴 상태 여부
    var isStunned: Bool {
        stunRemainingMs > 0
    }
}

