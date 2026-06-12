//
//  PhoneNumberFormatter.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import Foundation

/// 전화번호 포맷팅 유틸리티
/// 
/// 한국 전화번호 포맷팅 및 정규화 처리
/// - [현재 비활성화] 입력 중 자동 포맷팅: 01011112222 → 010-1111-2222
/// - [현재 비활성화] API 호출 시 정규화: 010-1111-2222 → 010-1111-2222 (하이픈 포함)
/// - 현재 API 호출 시: 숫자만 추출하여 전송 (하이픈 없음)
/// 
/// 주의: format() 메서드는 현재 PhoneNumberInputField와 normalize()에서 사용되지 않지만,
/// 나중에 다시 활성화할 수 있도록 코드는 유지됨
enum PhoneNumberFormatter {
    /// 전화번호를 포맷팅된 형태로 변환
    /// 
    /// - Parameter phone: 숫자만 포함된 전화번호 (예: "01011112222")
    /// - Returns: 하이픈이 포함된 전화번호 (예: "010-1111-2222")
    /// 
    /// 예시:
    /// - "01011112222" → "010-1111-2222"
    /// - "0101111222" → "010-111-1222"
    /// - "010111122" → "010-111-122"
    static func format(_ phone: String) -> String {
        // 숫자만 추출
        let numbers = phone.filter { $0.isNumber }
        
        // 길이에 따라 포맷팅
        switch numbers.count {
        case 0...2:
            return numbers
        case 3...6:
            // 010-111
            let areaCode = String(numbers.prefix(3))
            let middle = String(numbers.dropFirst(3))
            return "\(areaCode)-\(middle)"
        case 7...10:
            // 010-1111-2222
            let areaCode = String(numbers.prefix(3))
            let middle = String(numbers.dropFirst(3).prefix(4))
            let last = String(numbers.dropFirst(7))
            return "\(areaCode)-\(middle)-\(last)"
        default:
            // 11자리 이상: 010-1111-2222 형식 유지
            let areaCode = String(numbers.prefix(3))
            let middle = String(numbers.dropFirst(3).prefix(4))
            let last = String(numbers.dropFirst(7).prefix(4))
            return "\(areaCode)-\(middle)-\(last)"
        }
    }
    
    /// 전화번호를 정규화된 형태로 변환 (API 호출용)
    /// 
    /// - Parameter phone: 포맷팅된 또는 포맷팅되지 않은 전화번호
    /// - Returns: 숫자만 포함된 전화번호 (예: "01011112222")
    /// 
    /// 현재는 숫자만 추출하여 반환 (하이픈 없음)
    /// 사용자 입력대로 전송되어야 하므로 포맷팅하지 않음
    static func normalize(_ phone: String) -> String {
        // 숫자만 추출하여 반환 (하이픈 제거)
        return extractNumbers(phone)
        
        // ========== [주석 처리됨] 하이픈 포함 포맷팅 기능 ==========
        // 나중에 다시 활성화할 수 있도록 코드는 유지하되 주석 처리
        /*
        // 숫자만 추출 후 포맷팅
        return format(phone)
        */
    }
    
    /// 전화번호에서 숫자만 추출
    /// 
    /// - Parameter phone: 포맷팅된 또는 포맷팅되지 않은 전화번호
    /// - Returns: 숫자만 포함된 문자열
    static func extractNumbers(_ phone: String) -> String {
        return phone.filter { $0.isNumber }
    }
    
    /// 전화번호 유효성 검증
    /// 
    /// - Parameter phone: 검증할 전화번호
    /// - Returns: 유효한 전화번호인지 여부 (10~11자리 숫자)
    static func isValid(_ phone: String) -> Bool {
        let numbers = extractNumbers(phone)
        // 한국 전화번호는 10자리(지역번호 02) 또는 11자리(휴대폰 010 등)
        return numbers.count == 10 || numbers.count == 11
    }
}

