//
//  LoginView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// Login 화면
///
/// Android의 `LogInScreen`을 SwiftUI로 변환
/// - 사용자 로그인 입력 폼
/// - 자동 로그인 옵션
/// - 네비게이션 링크 (아이디 찾기, 비밀번호 찾기, 회원가입)
struct LoginView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?
    
    /// 포커스 필드 열거형
    enum Field {
        case id
        case password
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 제목
                Text("login_title".localized())
                    .typography(ElegaiterTypography.Headline3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 70)
                    .padding(.bottom, 32)
                    .background(Color.white) // 제목 배경색 (흰색)
                
                // 스크롤 가능한 영역
                ScrollView {
                    VStack(spacing: 0) {
                        // 입력 필드 영역
                        VStack(spacing: 20) {
                            // 아이디 입력 필드
                            LabeledRoundedInputField(
                                labelText: "auth_id".localized(),
                                value: $viewModel.id,
                                placeholder: "auth_id_placeholder".localized(),
                                onValueChange: viewModel.onIdChange,
                                enabled: !viewModel.isLoading
                            )
                            .focused($focusedField, equals: .id)
                            
                            // 비밀번호 입력 필드
                            LabeledPasswordInputField(
                                labelText: "auth_password".localized(),
                                value: $viewModel.password,
                                placeholder: "auth_pw_placeholder".localized(),
                                onValueChange: viewModel.onPasswordChange,
                                enabled: !viewModel.isLoading
                            )
                            .focused($focusedField, equals: .password)
                            .padding(.bottom, 24)
                        }
                        .padding(.horizontal, 20)
                        
                        // 하단 옵션 영역
                        HStack(alignment: .center) {
                            // 자동 로그인 체크박스
                            HStack(spacing: 6) {
                                CustomCheckbox(
                                    checked: $viewModel.isAutoLogin,
                                    onCheckedChange: viewModel.onAutoLoginChange
                                )
                                Text("login_auto".localized())
                                    .typography(ElegaiterTypography.Label4)
                                    .foregroundColor(ElegaiterColors.Text.sub2)
                            }
                            
                            Spacer()
                            
                            // 아이디/비밀번호 찾기 링크
                            HStack(spacing: 12) {
                                Button(action: {
                                    viewModel.navigateToFindId()
                                }) {
                                    Text("auth_find_id".localized())
                                        .typography(ElegaiterTypography.Label4)
                                        .foregroundColor(ElegaiterColors.Text.sub2)
                                }
                                
                                Rectangle()
                                    .fill(ElegaiterColors.Stroke.medium)
                                    .frame(width: 2, height: 16)
                                
                                Button(action: {
                                    viewModel.navigateToFindPw()
                                }) {
                                    Text("auth_find_pw".localized())
                                        .typography(ElegaiterTypography.Label4)
                                        .foregroundColor(ElegaiterColors.Text.sub2)
                                }
                            }
                        }
                        .frame(height: 20)
                        .padding(.horizontal, 20)
                        
                        // 스크롤 가능한 공간 확보 (버튼 높이 + 패딩)
                        Spacer()
                            .frame(height: 120)
                    }
                }
            }
            .background(Color.white) // NavigationStack 배경색 명시
            .navigationBarHidden(true)
            
            // 하단 고정 로그인 버튼
            VStack {
                Spacer()
                PrimaryButton(
                    onClick: {
                        viewModel.onLoginClick()
                    },
                    enabled: viewModel.isLoginEnabled,
                    showBottomInfo: true,
                    bottomInfoText1: "login_no_account".localized(),
                    bottomInfoText2: "login_signup".localized(),
                    onBottomTextClick: {
                        viewModel.navigateToSignUp()
                    }
                ) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("login_title".localized())
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
            
            // 키보드 프리로드: 화면이 나타날 때 키보드를 미리 초기화하여 첫 터치 시 지연 방지
            // 약간의 지연을 두고 첫 번째 입력 필드에 포커스를 잠시 주었다가 해제
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focusedField = nil
                }
            }
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
    /// - 로그인 성공: Permission 화면으로 이동
    /// - 로그인 실패: 네트워크 상태에 따라 다른 에러 메시지를 토스트로 표시
    private func handleEvent(_ event: LoginEvent) {
        switch event {
        case .loginSuccess:
            viewModel.handleLoginSuccess()
            
        case .loginFailure(let message):
            // 네트워크 상태에 따라 다른 에러 메시지를 글로벌 토스트로 표시
            let errorMessage = viewModel.isOnline
                ? message
                : "error_network_connection".localized()
            ToastManager.shared.show(message: errorMessage)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppCoordinator())
}
