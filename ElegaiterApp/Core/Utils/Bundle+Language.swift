//
//  Bundle+Language.swift
//  ElegaiterApp
//
//  Created on 2025-12-XX.
//

import Foundation
import ObjectiveC
import os.log

private let bundleLanguageLogger = Logger(subsystem: "com.elegaiter.app", category: "Bundle+Language")

/// Bundle Extension for 다국어 처리
/// 
/// 런타임에 Bundle.main의 클래스를 변경하여 언어별 .lproj 리소스를 동적으로 로드합니다.
/// 이 Extension을 통해 NSLocalizedString과 SwiftUI의 LocalizedStringKey가
/// LanguageManager에서 설정한 언어를 사용하도록 합니다.
/// 
/// **주의사항**:
/// - 런타임 클래스 변경을 사용하므로 주의가 필요합니다.
/// - 앱 시작 시 한 번만 호출하는 것을 권장합니다.
/// 
/// **사용 예시**:
/// ```swift
/// // 앱 시작 시 (예: ElegaiterApp의 init)
/// Bundle.setLanguage(LanguageManager.shared.currentLanguage)
/// 
/// // 언어 변경 시
/// LanguageManager.shared.setLanguage("en")
/// Bundle.setLanguage("en")
/// ```
extension Bundle {
    /// Associated Object를 위한 키
    /// 
    /// 같은 파일 내의 CustomBundle 클래스에서도 접근해야 하므로 fileprivate로 선언
    fileprivate static var bundleKey: UInt8 = 0
    
    /// 언어별 Bundle을 설정합니다.
    /// 
    /// 이 메서드는 Bundle.main의 클래스를 런타임에 CustomBundle로 변경하여
    /// localizedString 메서드가 지정된 언어의 .lproj 리소스를 사용하도록 합니다.
    /// 
    /// - Parameter language: 언어 코드 (예: "ko", "en")
    /// 
    /// **주의**: 
    /// - Bundle.main의 클래스를 변경하므로 앱 시작 시 한 번만 호출하는 것을 권장합니다.
    /// - 언어 변경 시에는 다시 호출해야 합니다.
    class func setLanguage(_ language: String) {
        bundleLanguageLogger.debug("🌐 [Bundle+Language] 언어 설정 시도: \(language)")

        // 언어별 .lproj Bundle 경로 찾기
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else {
            bundleLanguageLogger.debug("⚠️ [Bundle+Language] .lproj 경로를 찾을 수 없습니다: \(language)")
            if let resourcePath = Bundle.main.resourcePath {
                let fileManager = FileManager.default
                if let contents = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                    let lprojFolders = contents.filter { $0.hasSuffix(".lproj") }
                    bundleLanguageLogger.debug("📁 [Bundle+Language] 사용 가능한 .lproj 폴더: \(lprojFolders)")
                }
            }
            return
        }

        bundleLanguageLogger.debug("✅ [Bundle+Language] .lproj 경로 찾음: \(path)")

        guard let languageBundle = Bundle(path: path) else {
            bundleLanguageLogger.debug("⚠️ [Bundle+Language] Bundle 생성 실패: \(path)")
            return
        }

        bundleLanguageLogger.debug("✅ [Bundle+Language] Bundle 생성 성공")

        // Associated Object에 언어별 Bundle 저장
        objc_setAssociatedObject(
            Bundle.main,
            &Bundle.bundleKey,
            languageBundle,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // Bundle.main의 클래스를 CustomBundle로 변경
        // 이렇게 하면 localizedString 메서드가 오버라이드된 버전을 사용합니다.
        object_setClass(Bundle.main, CustomBundle.self)

        bundleLanguageLogger.debug("✅ [Bundle+Language] 언어 설정 완료: \(language)")
    }
    
}

/// Bundle.main의 클래스를 런타임에 변경하기 위한 커스텀 Bundle 클래스
/// 
/// 이 클래스는 localizedString 메서드를 오버라이드하여
/// Associated Object에 저장된 언어별 Bundle을 사용하도록 합니다.
/// 
/// **주의**: 이 클래스는 런타임 클래스 변경을 위해 사용되므로 직접 인스턴스화하지 않습니다.
private class CustomBundle: Bundle {
    /// 로컬라이즈된 문자열을 가져옵니다.
    /// 
    /// Associated Object에 저장된 언어별 Bundle을 사용하여 문자열을 가져옵니다.
    /// 
    /// - Parameters:
    ///   - key: 로컬라이즈 키
    ///   - value: 기본값 (키를 찾을 수 없을 때 사용)
    ///   - tableName: 문자열 테이블 이름 (nil이면 Localizable.strings 사용)
    /// - Returns: 로컬라이즈된 문자열
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        // Associated Object에서 언어별 Bundle 가져오기
        guard let bundle = objc_getAssociatedObject(self, &Bundle.bundleKey) as? Bundle else {
            // 언어별 Bundle이 없으면 기본 동작 사용
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        
        // 언어별 Bundle에서 문자열 가져오기
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

