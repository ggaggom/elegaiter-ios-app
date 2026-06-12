//
//  AppConstants.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import Foundation
import ElegaiterSDK

enum AppConstants {
    /// 비밀번호 힌트 목록 (PasswordHint enum 배열)
    /// 
    /// 회원가입 및 비밀번호 찾기에서 사용하는 힌트 목록
    static var passwordHints: [PasswordHint] {
        PasswordHint.allCases
    }
    
    /// 비밀번호 힌트의 로컬라이즈된 텍스트 목록
    /// 
    /// UI에 표시할 힌트 텍스트 목록 (현재 언어에 맞게 반환)
    static var passwordHintTexts: [String] {
        PasswordHint.allCases.map { $0.localizationKey.localized() }
    }
    
    /// PasswordHint를 로컬라이즈된 텍스트로 변환
    /// 
    /// - Parameter hint: PasswordHint enum
    /// - Returns: 현재 언어의 힌트 텍스트
    static func localizedText(for hint: PasswordHint) -> String {
        return hint.localizationKey.localized()
    }
    
    /// 비밀번호 힌트 인덱스를 PasswordHint로 변환
    /// 
    /// 서버에서 받은 인덱스나 저장된 인덱스를 PasswordHint로 변환
    /// - Parameter index: 힌트 인덱스 (1-7)
    /// - Returns: 해당하는 PasswordHint (없으면 nil)
    static func passwordHint(at index: Int) -> PasswordHint? {
        return PasswordHint.from(index: index)
    }
    
    /// 비밀번호 힌트 인덱스를 힌트 텍스트로 변환
    /// 
    /// 서버에서 받은 인덱스나 저장된 인덱스를 현재 언어의 힌트 텍스트로 변환
    /// - Parameter index: 힌트 인덱스 (1-7)
    /// - Returns: 현재 언어의 힌트 텍스트
    static func passwordHintText(at index: Int) -> String {
        guard let hint = PasswordHint.from(index: index) else {
            return ""
        }
        return hint.localizationKey.localized()
    }
}

