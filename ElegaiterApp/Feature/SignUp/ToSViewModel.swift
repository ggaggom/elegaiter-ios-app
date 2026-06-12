//
//  ToSViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine

/// 약관 항목 모델
struct TermItem: Identifiable {
    let id: String
    let title: String
    let content: String
    let fileName: String
}

/// ToS 화면의 ViewModel
/// 
/// Android의 `ToSViewModel`을 Swift로 변환
/// - 약관 동의 상태 관리
/// - 약관 텍스트 파일 로드
/// - 전체 동의 / 개별 동의 처리
/// - 약관 상세보기 상태 관리
@MainActor
class ToSViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 이용약관 동의 여부
    @Published var agreedTerms: Bool = false
    
    /// 개인정보 처리방침 동의 여부
    @Published var agreedPrivacy: Bool = false
    
    /// 위치정보 서비스 이용 동의 여부
    @Published var agreedLocation: Bool = false
    
    /// 민감정보 수집 및 이용 동의 여부
    @Published var agreedSPI: Bool = false
    
    /// 약관 항목 목록
    @Published var termItems: [TermItem] = []
    
    /// 현재 선택된 약관 (상세보기용)
    @Published var selectedTerm: TermItem? = nil
    
    /// 모든 약관 동의 여부 (계산 속성)
    var agreedAll: Bool {
        agreedTerms && agreedPrivacy && agreedLocation && agreedSPI
    }
    
    /// 다음 버튼 활성화 여부 (모든 약관 동의 시)
    var allAgreed: Bool {
        agreedAll
    }
    
    // MARK: - Properties
    
    weak var coordinator: AppCoordinator?
    
    // MARK: - Initialization
    
    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator
        loadTerms()
    }
    
    // MARK: - Private Methods
    
    /// 약관 텍스트 파일 로드
    /// 
    /// Android의 `loadRawTextFile()` 로직을 Swift로 변환
    /// Bundle의 Raw 리소스에서 약관 텍스트를 읽어옵니다.
    private func loadTerms() {
        termItems = [
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
            )
        ]
    }
    
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
    
    // MARK: - Public Methods
    
    /// 전체 동의 상태 변경
    /// 
    /// Android의 `OnAgreeAllChanged` 이벤트 처리
    /// - Parameter checked: 전체 동의 여부
    func onAgreeAllChanged(_ checked: Bool) {
        agreedTerms = checked
        agreedPrivacy = checked
        agreedLocation = checked
        agreedSPI = checked
    }
    
    /// 이용약관 동의 상태 변경
    /// 
    /// Android의 `OnTermsChanged` 이벤트 처리
    /// - Parameter checked: 동의 여부
    func onTermsChanged(_ checked: Bool) {
        agreedTerms = checked
    }
    
    /// 개인정보 처리방침 동의 상태 변경
    /// 
    /// Android의 `OnPrivacyChanged` 이벤트 처리
    /// - Parameter checked: 동의 여부
    func onPrivacyChanged(_ checked: Bool) {
        agreedPrivacy = checked
    }
    
    /// 위치정보 서비스 이용 동의 상태 변경
    /// 
    /// Android의 `OnLocationChanged` 이벤트 처리
    /// - Parameter checked: 동의 여부
    func onLocationChanged(_ checked: Bool) {
        agreedLocation = checked
    }
    
    /// 민감정보 수집 및 이용 동의 상태 변경
    /// 
    /// Android의 `OnSPIChanged` 이벤트 처리
    /// - Parameter checked: 동의 여부
    func onSPIChanged(_ checked: Bool) {
        agreedSPI = checked
    }
    
    /// 약관 상세보기 클릭
    /// 
    /// Android의 `OnViewDetailClicked` 이벤트 처리
    /// - Parameter fileName: 약관 파일명
    func onViewDetailClicked(fileName: String) {
        selectedTerm = termItems.first { $0.fileName == fileName }
    }
    
    /// 약관 상세보기 닫기
    /// 
    /// Android의 `OnDismissDetail` 이벤트 처리
    func onDismissDetail() {
        selectedTerm = nil
    }
    
    // MARK: - Navigation
    
    /// 다음 화면 (회원가입)으로 이동
    /// 
    /// Android의 `onAgree()` 로직을 Swift로 변환
    /// 모든 약관에 동의한 경우에만 다음 화면으로 이동합니다.
    func navigateToSignUp() {
        guard allAgreed else {
            return
        }
        coordinator?.navigateInMain(to: .signUp)
    }
}

