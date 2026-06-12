//
//  FindIdView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// FindId 화면
/// 
/// Android의 `FindIdScreen`을 SwiftUI로 변환
/// - 이름과 전화번호 입력 폼
/// - 아이디 찾기 기능
/// - 결과 다이얼로그 표시
struct FindIdView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = FindIdViewModel()
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    
    /// 포커스 필드 열거형
    enum Field {
        case name
        case phone
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "auth_find_id".localized(),
                    onBackClick: {
                        dismiss()
                    }
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 입력 필드 영역
                        VStack(spacing: 20) {
                            // 이름 입력 필드
                            LabeledRoundedInputField(
                                labelText: "auth_name".localized(),
                                value: $viewModel.name,
                                placeholder: "auth_name_placeholder".localized(),
                                onValueChange: viewModel.onNameChange,
                                enabled: !viewModel.isLoading
                            )
                            .focused($focusedField, equals: .name)
                            
                            // 전화번호 입력 필드 (전용 컴포넌트 사용)
                            PhoneNumberInputField(
                                labelText: "auth_phone".localized(),
                                value: $viewModel.phone,
                                placeholder: "auth_phone_placeholder".localized(),
                                onValueChange: viewModel.onPhoneChange,
                                enabled: !viewModel.isLoading
                            )
                            .focused($focusedField, equals: .phone)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        
                        // 스크롤 가능한 공간 확보 (버튼 높이 + 패딩)
                        Spacer()
                            .frame(height: 120)
                    }
                }
            }
            .background(Color.white) // NavigationStack 배경색 명시
            .navigationBarBackButtonHidden(true)
            
            // 하단 고정 확인 버튼
            VStack {
                Spacer()
                PrimaryButton(
                    onClick: {
                        viewModel.onFindIdClick()
                    },
                    enabled: viewModel.isFindIdEnabled
                ) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("btn_confirm".localized())
                            .typography(ElegaiterTypography.Label1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            // 아이디 찾기 결과 다이얼로그
            if viewModel.foundId != nil {
                StyledAlertDialog(
                    isPresented: Binding(
                        get: { viewModel.foundId != nil },
                        set: { if !$0 { viewModel.foundId = nil } }
                    ),
                    title: "find_id_complete_title".localized(),
                    message: "find_id_complete_description".localized(),
                    content: {
                        LabeledRoundedInputField(
                            labelText: "auth_id".localized(),
                            value: Binding(
                                get: { viewModel.foundId ?? "" },
                                set: { _ in }
                            ),
                            placeholder: "",
                            onValueChange: { _ in },
                            enabled: false
                        )
                        .padding(.bottom, 24)
                    },
                    confirmText: "login_title".localized(),
                    onConfirm: {
                        viewModel.onDialogConfirm()
                    },
                    showBottomText: true,
                    bottomText: "auth_find_pw".localized(),
                    onBottomTextClick: {
                        viewModel.onDialogNavigateToFindPassword()
                    }
                )
            }
        }
        .onTapGesture {
            // 화면 탭 시 키보드 닫기
            focusedField = nil
        }
        .onAppear {
            viewModel.coordinator = coordinator
        }
        .onReceive(viewModel.eventSubject) { event in
            handleEvent(event)
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    // MARK: - Private Methods
    
    /// 이벤트 처리
    /// 
    /// Android의 `LaunchedEffect` + `repeatOnLifecycle` 로직을 SwiftUI로 변환
    /// - 토스트 메시지를 글로벌 토스트로 표시
    /// - 네비게이션 처리
    private func handleEvent(_ event: FindIdEvent) {
        switch event {
        case .showToast(let message):
            ToastManager.shared.show(message: message)
            
        case .navigateToLogin:
            viewModel.navigateToLogin()
            
        case .navigateToFindPassword:
            viewModel.navigateToFindPassword()
        }
    }
}

#Preview {
    FindIdView()
        .environmentObject(AppCoordinator())
}
