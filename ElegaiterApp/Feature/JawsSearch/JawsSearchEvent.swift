//
//  JawsSearchEvent.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import Foundation

/// JawsSearch 화면의 이벤트 정의
/// 
/// Android의 `JawsSearchEvent` sealed interface를 Swift enum으로 변환
enum JawsSearchEvent {
    /// Threshold 설정 화면으로 이동
    case navigateToThreshold
    /// 운동 화면으로 이동
    case navigateToMain
    /// BLE 에러 메시지 표시
    case showBleError
}

