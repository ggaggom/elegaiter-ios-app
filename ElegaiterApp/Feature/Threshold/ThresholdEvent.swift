//
//  ThresholdEvent.swift
//  ElegaiterApp
//
//  Created on 2025-01-XX.
//

import Foundation

/// Threshold 화면의 이벤트 정의
/// 
/// Android의 `ThresholdEvent` sealed interface를 Swift enum으로 변환
enum ThresholdEvent {
    /// 토스트 메시지 표시
    /// - Parameter message: 표시할 메시지
    case showToast(message: String)
}

