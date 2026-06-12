//
//  FindPwEvent.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import Foundation

/// FindPw 화면의 이벤트 정의
/// 
/// Android의 `FindPwEvent` sealed interface를 Swift enum으로 변환
enum FindPwEvent {
    /// 토스트 메시지 표시
    /// - Parameter message: 표시할 메시지
    case showToast(message: String)
    /// 비밀번호 재설정 화면으로 이동
    case navigateToResetPw
    /// 힌트 인증 화면으로 복귀 (ResetToken 만료 시)
    case navigateToVerifyHint
    /// 로그인 화면으로 이동
    case navigateToLogin
    /// 설정 화면으로 이동 (마이페이지 비밀번호 변경 완료 시)
    case navigateToSetting
}

