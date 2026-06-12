//
//  String+Extensions.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import Foundation

extension String {
    /// 로컬라이즈된 문자열을 가져옵니다.
    /// 
    /// LanguageManager에서 설정한 언어를 사용하여 로컬라이즈된 문자열을 반환합니다.
    /// 
    /// - Parameter comment: 주석 (선택적)
    /// - Returns: 로컬라이즈된 문자열
    /// 
    /// **사용 예시**:
    /// ```swift
    /// let text = "welcome_message".localized()
    /// Text("welcome_message".localized())
    /// ```
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
    
    /// 포맷 문자열을 사용하여 로컬라이즈된 문자열을 가져옵니다 (정수 인자).
    /// 
    /// - Parameter value: 포맷 문자열에 전달할 정수 값
    /// - Returns: 포맷이 적용된 로컬라이즈된 문자열
    /// 
    /// **사용 예시**:
    /// ```swift
    /// "login_server_error_with_code".localized(format: 500)
    /// ```
    func localized(format value: Int) -> String {
        let formatString = NSLocalizedString(self, comment: "")
        return String(format: formatString, value)
    }
    
    /// 포맷 문자열을 사용하여 로컬라이즈된 문자열을 가져옵니다 (문자열 인자).
    /// 
    /// - Parameter value: 포맷 문자열에 전달할 문자열 값
    /// - Returns: 포맷이 적용된 로컬라이즈된 문자열
    /// 
    /// **사용 예시**:
    /// ```swift
    /// "login_server_error_with_message".localized(format: "Connection timeout")
    /// ```
    func localized(format value: String) -> String {
        let formatString = NSLocalizedString(self, comment: "")
        return String(format: formatString, value)
    }
}

