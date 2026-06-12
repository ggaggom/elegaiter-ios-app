//
//  TermsView.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI

/// 약관 및 정책 화면
/// 
/// Android의 `TermsScreen`을 SwiftUI로 변환
/// - 약관 및 정책 문서 조회
/// - 모달 바텀 시트로 상세 내용 표시
struct TermsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    @State private var selectedTerm: TermItem? = nil
    
    /// 약관 항목 리스트
    private var termItems: [TermItem] {
        [
            TermItem(
                id: "terms",
                title: "terms_title_service".localized(),
                content: loadRawTextFile(fileName: "terms_of_service"),
                fileName: "terms_of_service.txt"
            ),
            TermItem(
                id: "privacy",
                title: "terms_title_privacy".localized(),
                content: loadRawTextFile(fileName: "privacy_policy"),
                fileName: "privacy_policy.txt"
            ),
            TermItem(
                id: "location",
                title: "terms_title_location".localized(),
                content: loadRawTextFile(fileName: "location_terms"),
                fileName: "location_terms.txt"
            ),
            TermItem(
                id: "spi",
                title: "terms_title_sensitive".localized(),
                content: loadRawTextFile(fileName: "sensitive_info"),
                fileName: "sensitive_info.txt"
            ),
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // TopBar (뒤로가기 버튼 + 제목)
            ElegaiterTopBar(
                title: "setting_menu_terms_policy".localized(),
                onBackClick: {
                    coordinator.pop(in: Binding(
                        get: { coordinator.settingPath },
                        set: { coordinator.settingPath = $0 }
                    ))
                }
            )
            .padding(.bottom, 20)
            
            // 약관 목록
            MyPageSection(
                title: "",
                menuItems: termItems.map { item in
                    MyPageMenuItem(item.title) {
                        selectedTerm = item
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationBarHidden(true)
        .sheet(item: $selectedTerm) { termItem in
            TermsBottomSheet(
                termItem: termItem,
                onDismissClick: {
                    selectedTerm = nil
                }
            )
            .presentationDetents([.large, .medium])
            .presentationDragIndicator(.hidden)
            .modifier(CornerRadiusModifier(radius: 20))
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    // MARK: - Helper Functions
    
    /// Raw 리소스 파일에서 텍스트 로드 (언어별)
    /// 
    /// Android의 `loadRawTextFile(@RawRes resourceId: Int)` 로직을 Swift로 변환
    /// 현재 설정된 언어에 따라 .lproj 폴더에서 파일을 로드합니다.
    /// - Parameter fileName: 파일명 (확장자 제외)
    /// - Returns: 약관 텍스트 내용 (실패 시 기본 메시지)
    private func loadRawTextFile(fileName: String) -> String {
        // 현재 언어 코드 가져오기
        let currentLanguage = LanguageManager.shared.currentLanguage
        
        // 언어별 .lproj 폴더에서 파일 로드 시도
        if let languageBundlePath = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let languageBundle = Bundle(path: languageBundlePath),
           let path = languageBundle.path(forResource: fileName, ofType: "txt"),
           let text = try? String(contentsOfFile: path, encoding: .utf8) {
            return text
        }
        
        // 언어별 파일이 없으면 기본 경로에서 로드 시도
        if let path = Bundle.main.path(forResource: fileName, ofType: "txt"),
           let text = try? String(contentsOfFile: path, encoding: .utf8) {
            return text
        }
        
        // 모두 실패한 경우 에러 메시지 반환
        return "terms_load_error".localized()
    }
}

#Preview {
    TermsView()
        .environmentObject(AppCoordinator())
}
