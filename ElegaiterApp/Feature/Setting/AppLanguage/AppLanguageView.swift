//
//  AppLanguageView.swift
//  ElegaiterApp
//
//  Created on 2025-12-XX.
//

import SwiftUI

/// 언어 설정 화면
///
/// - 한글과 영어 중 선택 가능
/// - 선택한 언어로 앱 언어 변경
struct AppLanguageView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = AppLanguageViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "setting_menu_language_title".localized(),
                    onBackClick: {
                        viewModel.navigateBack()
                    }
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 언어 선택 영역
                        VStack(spacing: 0) {
                            // 제목
                            Text("app_language_select_label".localized())
                                .typography(ElegaiterTypography.Label3)
                                .foregroundColor(ElegaiterColors.Text.sub1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                            
                            // 언어 선택 버튼들
                            VStack(spacing: 12) {
                                // 한글 선택 버튼
                                CustomRadioButton(
                                    text: "app_language_korean".localized(),
                                    selected: viewModel.uiState.selectedLanguage == "ko",
                                    onClick: {
                                        viewModel.selectLanguage("ko")
                                    }
                                )
                                
                                // 영어 선택 버튼
                                CustomRadioButton(
                                    text: "app_language_english".localized(),
                                    selected: viewModel.uiState.selectedLanguage == "en",
                                    onClick: {
                                        viewModel.selectLanguage("en")
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 스크롤 가능한 공간 확보 (버튼 높이 + 패딩)
                        Spacer()
                            .frame(height: 120)
                    }
                }
            }
            .background(Color.white) // NavigationStack 배경색 명시
            .navigationBarBackButtonHidden(true)
            
            // 하단 고정 저장하기 버튼
            VStack {
                Spacer()
                PrimaryButton(
                    onClick: {
                        viewModel.saveLanguage()
                    },
                    enabled: viewModel.uiState.isSaveButtonEnabled
                ) {
                    Text("btn_save".localized())
                        .typography(ElegaiterTypography.Label1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            viewModel.coordinator = coordinator
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .navigateBack:
                ToastManager.shared.show(message: "toast_save_success".localized())
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.navigateBack()
                }
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
}

#Preview {
    AppLanguageView()
        .environmentObject(AppCoordinator())
}

