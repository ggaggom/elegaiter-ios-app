//
//  LanguageManager.swift
//  ElegaiterApp
//
//  Created on 2025-12-XX.
//

import Foundation
import Combine

/// 앱 내 독립적인 언어 설정을 관리하는 싱글톤 클래스
/// 
/// 한글(ko)과 영어(en) 2가지만 지원합니다.
/// 최초 실행 시 시스템 언어를 확인하여 한글이 아니면 모두 영어로 설정합니다.
/// 
/// **사용 예시**:
/// ```swift
/// // 현재 언어 확인
/// let currentLang = LanguageManager.shared.currentLanguage
/// 
/// // 언어 변경
/// LanguageManager.shared.setLanguage("en")
/// ```
final class LanguageManager: ObservableObject {
    /// 싱글톤 인스턴스
    static let shared = LanguageManager()
    
    /// UserDefaults에 저장할 키
    private let languageKey = "AppLanguage"
    
    /// 지원하는 언어 코드
    private let supportedLanguages = ["ko", "en"]
    
    /// 기본 언어 (한글이 아닌 경우)
    private let defaultLanguage = "en"
    
    /// 언어 변경 알림을 위한 Publisher
    /// 언어가 변경되면 이 Publisher가 값을 방출하여 뷰를 업데이트할 수 있습니다.
    let languageChanged = PassthroughSubject<String, Never>()
    
    private init() {}
    
    /// 현재 앱 언어 가져오기
    /// 
    /// 저장된 언어가 있으면 반환하고, 없으면 시스템 언어를 확인합니다.
    /// 시스템 언어가 한글(ko)이 아니면 모두 영어(en)로 반환합니다.
    var currentLanguage: String {
        get {
            // 저장된 언어가 있으면 반환
            if let savedLanguage = UserDefaults.standard.string(forKey: languageKey) {
                // 저장된 언어가 지원하는 언어인지 확인
                return supportedLanguages.contains(savedLanguage) ? savedLanguage : defaultLanguage
            }
            
            // 최초 실행: 시스템 언어 확인
            let systemLanguage = getSystemLanguage()
            
            // 한글이면 "ko", 아니면 모두 "en"
            return systemLanguage == "ko" ? "ko" : defaultLanguage
        }
        set {
            // 지원하는 언어만 저장
            if supportedLanguages.contains(newValue) {
                UserDefaults.standard.set(newValue, forKey: languageKey)
                UserDefaults.standard.synchronize()
            } else {
                // 지원하지 않는 언어는 기본 언어로 설정
                UserDefaults.standard.set(defaultLanguage, forKey: languageKey)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    /// 언어 변경
    /// 
    /// - Parameter languageCode: 변경할 언어 코드 ("ko" 또는 "en")
    /// 
    /// 지원하지 않는 언어 코드를 전달하면 기본 언어(en)로 설정됩니다.
    /// 언어 변경 시 Bundle도 자동으로 업데이트됩니다.
    func setLanguage(_ languageCode: String) {
        let validLanguage = supportedLanguages.contains(languageCode) ? languageCode : defaultLanguage
        
        currentLanguage = validLanguage
        
        // Bundle의 언어도 업데이트
        Bundle.setLanguage(validLanguage)
        
        // 언어 변경 알림 발행 (뷰 업데이트용)
        languageChanged.send(validLanguage)
    }
    
    /// 저장된 언어 설정 확인
    /// 
    /// - Returns: 사용자가 언어를 설정했는지 여부
    var hasLanguagePreference: Bool {
        return UserDefaults.standard.string(forKey: languageKey) != nil
    }
    
    /// 시스템 언어 가져오기
    /// 
    /// Locale.preferredLanguages의 첫 번째 언어 코드를 반환합니다.
    /// 예: "ko-KR" -> "ko", "en-US" -> "en"
    /// 
    /// - Returns: 언어 코드 (예: "ko", "en")
    private func getSystemLanguage() -> String {
        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return defaultLanguage
        }
        
        // 언어 코드 추출 (예: "ko-KR" -> "ko", "en-US" -> "en")
        let languageCode = String(preferredLanguage.prefix(2))
        
        return languageCode
    }
}

