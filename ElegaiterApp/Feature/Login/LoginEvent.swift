//
//  LoginEvent.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import Foundation

/// Login 화면의 이벤트 정의
/// 
/// Android의 `LoginEvent` sealed interface를 Swift enum으로 변환
enum LoginEvent {
    /// 로그인 성공
    case loginSuccess
    /// 로그인 실패
    /// - Parameter message: 에러 메시지
    case loginFailure(message: String)
}
