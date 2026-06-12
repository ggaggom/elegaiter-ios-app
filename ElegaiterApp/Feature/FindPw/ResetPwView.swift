//
//  ResetPwView.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI

/// ResetPw 화면
///
/// Android의 `ResetPwScreen`을 SwiftUI로 변환
/// - 새 비밀번호 입력 및 재설정
/// - 두 가지 모드 지원:
///   1. 비밀번호 찾기 모드 (`requiresCurrentPassword = false`): 힌트 인증 후 재설정
///   2. 마이페이지 변경 모드 (`requiresCurrentPassword = true`): 현재 비밀번호 확인 후 변경
struct ResetPwView: View {
    let requiresCurrentPassword: Bool
    @EnvironmentObject var coordinator: AppCoordinator
    @ObservedObject var viewModel: FindPwViewModel
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    
    /// 포커스 필드 열거형
    enum Field {
        case currentPassword
        case newPassword
        case confirmPassword
    }
    
    /// 초기화
    ///
    /// - Parameters:
    ///   - requiresCurrentPassword: 현재 비밀번호 필요 여부
    ///   - viewModel: 공유할 ViewModel (비밀번호 찾기 모드일 때만 전달)
    init(requiresCurrentPassword: Bool, viewModel: FindPwViewModel? = nil) {
        self.requiresCurrentPassword = requiresCurrentPassword
        // 비밀번호 찾기 모드이고 ViewModel이 전달된 경우 사용, 아니면 새로 생성
        self._viewModel = ObservedObject(wrappedValue: viewModel ?? FindPwViewModel())
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "auth_password_reset".localized(),
                    onBackClick: {
                        // 비밀번호 찾기 모드: ViewModel 정리 (뒤로가기 시)
                        // 마이페이지 모드: ViewModel 정리 불필요 (독립적인 ViewModel)
                        if !requiresCurrentPassword {
                            coordinator.clearFindPwViewModel()
                        }
                        // NavigationStack에서 pop하여 이전 화면으로 돌아감
                        // 비밀번호 찾기 모드: FindPw 화면으로
                        // 마이페이지 모드: Setting 화면으로
                        dismiss()
                    }
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 입력 필드 영역
                        VStack(spacing: 0) {
                            // 상단 여백 (안드로이드와 동일: 12dp)
                            Spacer()
                                .frame(height: 12)
                            
                            // 현재 비밀번호 입력 (마이페이지 모드일 때만 표시)
                            if requiresCurrentPassword {
                                LabeledPasswordInputField(
                                    labelText: "find_pw_current_pw".localized(),
                                    value: $viewModel.currentPassword,
                                    placeholder: "find_pw_current_pw_placeholder".localized(),
                                    onValueChange: viewModel.onCurrentPasswordChange,
                                    enabled: !viewModel.isLoading,
                                    maxLength: 20
                                )
                                .focused($focusedField, equals: .currentPassword)
                                .padding(.bottom, 40)
                            }
                            
                            // 새 비밀번호 입력
                            VStack(alignment: .leading, spacing: 8) {
                                LabeledPasswordInputField(
                                    labelText: "find_pw_new_pw".localized(),
                                    value: $viewModel.newPassword,
                                    placeholder: "find_pw_new_pw_placeholder".localized(),
                                    onValueChange: viewModel.onNewPasswordChange,
                                    enabled: !viewModel.isLoading,
                                    maxLength: 20,
                                    eventBorderColor: (!viewModel.isNewPasswordValid && !viewModel.newPassword.isEmpty) ? ElegaiterColors.Status.error : nil
                                )
                                .focused($focusedField, equals: .newPassword)
                                
                                // 비밀번호 유효성 검사 오류 메시지
                                if !viewModel.isNewPasswordValid && !viewModel.newPassword.isEmpty {
                                    Text("auth_pw_rule".localized())
                                        .typography(ElegaiterTypography.Caption1)
                                        .foregroundColor(ElegaiterColors.Status.error)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            // 새 비밀번호 확인
                            VStack(alignment: .leading, spacing: 0) {
                                PasswordInputField(
                                    value: $viewModel.confirmPassword,
                                    placeholder: "find_pw_new_pw_confirm_placeholder".localized(),
                                    onValueChange: viewModel.onConfirmPasswordChange,
                                    enabled: !viewModel.isLoading,
                                    maxLength: 20,
                                    eventBorderColor: (!viewModel.isPasswordConfirm && !viewModel.confirmPassword.isEmpty) ? ElegaiterColors.Status.error : nil
                                )
                                .focused($focusedField, equals: .confirmPassword)
                                .padding(.top, 16)
                                
                                // 비밀번호 불일치 에러 메시지
                                if !viewModel.isPasswordConfirm && !viewModel.confirmPassword.isEmpty {
                                    Text("auth_password_confirm_error".localized())
                                        .typography(ElegaiterTypography.Caption1)
                                        .foregroundColor(ElegaiterColors.Status.error)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 6)
                                }
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
            
            // 하단 고정 비밀번호 재설정 버튼
            VStack {
                Spacer()
                PrimaryButton(
                    onClick: {
                        viewModel.onResetClick()
                    },
                    enabled: viewModel.isResetEnabled
                ) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("auth_password_reset".localized())
                            .typography(ElegaiterTypography.Label1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onTapGesture {
            // 화면 탭 시 키보드 닫기
            focusedField = nil
        }
        .onAppear {
            viewModel.coordinator = coordinator
            // 현재 비밀번호 필요 여부 초기화
            viewModel.initializeRequireCurrentPw(requiresCurrentPassword)
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
    private func handleEvent(_ event: FindPwEvent) {
        switch event {
        case .showToast(let message):
            // 글로벌 토스트로 메시지 표시
            ToastManager.shared.show(message: message)
            
        case .navigateToResetPw:
            // ResetPw 화면에서 ResetPw로 이동하는 경우는 없음
            break

        case .navigateToVerifyHint:
            dismiss()

        case .navigateToLogin:
            // 비밀번호 찾기 모드: ViewModel 정리 후 로그인 화면으로 이동
            if !requiresCurrentPassword {
                coordinator.clearFindPwViewModel()
            }
            viewModel.navigateToLogin()
            
        case .navigateToSetting:
            // 마이페이지 모드: ViewModel 정리 후 설정 화면으로 이동
            if requiresCurrentPassword {
                coordinator.clearFindPwViewModel()
                // SettingRouter를 통해 들어온 경우 dismiss()로 이전 화면(SettingView)으로 돌아감
                dismiss()
            } else {
                viewModel.navigateToSetting()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResetPwView(requiresCurrentPassword: false)
            .environmentObject(AppCoordinator())
    }
}

#Preview("마이페이지 모드") {
    NavigationStack {
        ResetPwView(requiresCurrentPassword: true)
            .environmentObject(AppCoordinator())
    }
}

