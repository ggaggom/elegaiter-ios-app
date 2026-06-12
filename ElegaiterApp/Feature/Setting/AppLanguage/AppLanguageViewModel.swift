//
//  AppLanguageViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-12-XX.
//

import SwiftUI
import Combine

/// 언어 설정 화면 ViewModel
/// 
/// - 현재 언어 조회 및 변경
/// - 언어 변경 시 Bundle 업데이트
@MainActor
class AppLanguageViewModel: ObservableObject {
    // MARK: - Dependencies
    
    weak var coordinator: AppCoordinator?
    
    // MARK: - Published Properties
    
    /// UI 상태
    @Published var uiState = AppLanguageUiState()
    
    /// 이벤트 스트림
    private let eventSubject = PassthroughSubject<AppLanguageEvent, Never>()
    var events: AnyPublisher<AppLanguageEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init() {
        loadCurrentLanguage()
    }
    
    // MARK: - Data Loading
    
    /// 현재 언어 로드
    private func loadCurrentLanguage() {
        let currentLanguage = LanguageManager.shared.currentLanguage
        uiState.selectedLanguage = currentLanguage
        uiState.initialLanguage = currentLanguage
        uiState.isSaveButtonEnabled = false
    }
    
    // MARK: - Actions
    
    /// 언어 선택
    /// - Parameter languageCode: 선택할 언어 코드 ("ko" 또는 "en")
    func selectLanguage(_ languageCode: String) {
        let languageChanged = languageCode != uiState.initialLanguage
        
        uiState.selectedLanguage = languageCode
        uiState.isSaveButtonEnabled = languageChanged
    }
    
    /// 언어 저장
    func saveLanguage() {
        LanguageManager.shared.setLanguage(uiState.selectedLanguage)
        
        uiState.initialLanguage = uiState.selectedLanguage
        uiState.isSaveButtonEnabled = false
        
        eventSubject.send(.navigateBack)
    }
    
    // MARK: - Navigation
    
    func navigateBack() {
        guard let coordinator = coordinator else { return }
        coordinator.pop(in: Binding(
            get: { coordinator.settingPath },
            set: { coordinator.settingPath = $0 }
        ))
    }
}

// MARK: - UI State

/// 언어 설정 UI 상태
struct AppLanguageUiState {
    /// 선택된 언어 코드
    var selectedLanguage: String = "ko"
    /// 초기 언어 코드 (변경사항 비교용)
    var initialLanguage: String = "ko"
    /// 저장 버튼 활성화 여부
    var isSaveButtonEnabled: Bool = false
}

/// 언어 설정 이벤트
enum AppLanguageEvent {
    case navigateBack
}

