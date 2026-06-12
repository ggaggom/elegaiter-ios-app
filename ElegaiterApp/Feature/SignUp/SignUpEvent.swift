//
//  SignUpEvent.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import Foundation

/// SignUp 화면의 이벤트 정의
/// 
/// Android의 `SignUpUiEvent`를 Swift enum으로 변환
enum SignUpEvent {
    case navigateToSignUpInfo
    case navigateToLogin
    case showToast(message: String)
}
