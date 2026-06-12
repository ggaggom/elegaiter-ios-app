//
//  LocalizedTextModifier.swift
//  ElegaiterApp
//
//  Created on 2025-12-XX.
//

import SwiftUI
import Combine

/// 언어 변경 시 뷰를 자동으로 업데이트하는 ViewModifier
/// 
/// 모든 뷰에 반복적으로 추가해야 하는 .id()와 onReceive를 
/// ViewModifier로 캡슐화하여 재사용성을 높입니다.
/// 
/// **사용 예시**:
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         Text("welcome_message".localized())
///             .localized()
///     }
/// }
/// ```
struct LocalizedTextModifier: ViewModifier {
    /// 언어 변경 시 뷰를 강제로 업데이트하기 위한 ID
    @State private var languageUpdateId = UUID()
    
    func body(content: Content) -> some View {
        content
            .id(languageUpdateId)
            .onReceive(LanguageManager.shared.languageChanged) { _ in
                // 언어 변경 시 뷰 ID를 변경하여 강제로 업데이트
                languageUpdateId = UUID()
            }
    }
}

// MARK: - View Extension

extension View {
    /// 언어 변경 시 자동으로 업데이트되도록 하는 modifier
    /// 
    /// 이 modifier를 적용하면 언어 변경 시 뷰가 자동으로 재렌더링됩니다.
    /// 로컬라이즈된 텍스트를 사용하는 모든 뷰에 적용하는 것을 권장합니다.
    /// 
    /// **사용 예시**:
    /// ```swift
    /// VStack {
    ///     Text("welcome_message".localized())
    ///     Text("login_title".localized())
    /// }
    /// .localized()
    /// ```
    /// 
    /// - Returns: 언어 변경 감지가 적용된 View
    func localized() -> some View {
        modifier(LocalizedTextModifier())
    }
}

