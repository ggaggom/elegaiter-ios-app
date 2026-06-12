//
//  DisplayStepType.swift
//  ElegaiterApp
//
//  Created on 2025-01-XX.
//

import Foundation

/// 캐릭터 표시 타입
/// 
/// Android의 `DisplayStepType` enum을 Swift로 변환
/// - `walk`: 걷기 상태
/// - `fly`: 뛰기 상태
/// - `transition`: 전환 중 (현재 미사용)
enum DisplayStepType {
    case walk
    case fly
    case transition
}

