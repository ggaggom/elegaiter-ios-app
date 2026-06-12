//
//  FindIdEvent.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import Foundation

/// FindId 화면의 이벤트 정의
/// 
/// Android의 `FindIdEvent` sealed interface를 Swift enum으로 변환
enum FindIdEvent {
    /// 토스트 메시지 표시
    /// - Parameter message: 표시할 메시지
    case showToast(message: String)
    /// 로그인 화면으로 이동
    case navigateToLogin
    /// 비밀번호 찾기 화면으로 이동
    case navigateToFindPassword
}

