//
//  SignUpView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 회원가입 화면 (기본 정보 입력)
/// 
/// Android의 `SignUpScreen`을 SwiftUI로 변환
/// - 아이디 입력 및 중복 확인
/// - 비밀번호 입력 및 확인
/// - 비밀번호 힌트 선택 및 답변
/// - 다음 버튼 (모든 항목 입력 및 검증 완료 시 활성화)
struct SignUpView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    /// 포커스 필드 열거형
    enum Field {
        case id
        case password
        case passwordConfirm
        case hintAnswer
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "sign_up_title".localized(),
                    onBackClick: {
                        // 회원가입 플로우를 완전히 나가는 경우 ViewModel 정리
                        coordinator.clearSignUpViewModel()
                        dismiss()
                    },
                    showProgress: true,
                    currentStep: 2,
                    totalStep: 3
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 입력 필드 영역
                        VStack(spacing: 20) {
                            // 아이디 입력 및 중복 확인
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 6) {
                                    LabeledRoundedInputField(
                                        labelText: "auth_id".localized(),
                                        value: $viewModel.id,
                                        placeholder: "auth_id_placeholder".localized(),
                                        onValueChange: viewModel.onIdChange,
                                        enabled: !viewModel.isCheckingId,
                                        eventBorderColor: {
                                            if !viewModel.isIdValid && !viewModel.id.trimmingCharacters(in: .whitespaces).isEmpty {
                                                return .red
                                            } else if viewModel.lastCheckedId.isEmpty {
                                                return nil
                                            } else if viewModel.isIdChecked {
                                                return .green
                                            } else {
                                                return .red
                                            }
                                        }(),
                                        maxLength: 12
                                    )
                                    .focused($focusedField, equals: .id)
                                    
                                    PrimaryButton(
                                        onClick: {
                                            viewModel.onCheckIdDuplication()
                                        },
                                        enabled: !viewModel.id.trimmingCharacters(in: .whitespaces).isEmpty && !viewModel.isCheckingId && viewModel.isIdValid
                                    ) {
                                        if viewModel.isCheckingId {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.white)
                                        } else {
                                            Text("sign_up_check_duplicate".localized())
                                                .typography(ElegaiterTypography.Label3)
                                        }
                                    }
                                    .frame(width: 100, height: 58)
                                    .padding(.top, 24) // 라벨 높이(약 20pt) + 라벨과 입력 필드 사이 간격(6pt) = 26pt
                                }
                                
                                // 아이디 유효성 검사 오류 메시지
                                if !viewModel.isIdValid && !viewModel.id.trimmingCharacters(in: .whitespaces).isEmpty {
                                    Text("sign_up_id_rule".localized())
                                        .typography(ElegaiterTypography.Caption1)
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                                
                                // 중복 확인 결과 표시 (유효성 검사 통과 시에만 표시)
                                if viewModel.isIdValid && !viewModel.lastCheckedId.isEmpty {
                                    Text(viewModel.isIdChecked ? "sign_up_id_available".localized() : "sign_up_id_unavailable".localized())
                                        .typography(ElegaiterTypography.Caption1)
                                        .foregroundColor(viewModel.isIdChecked ? .green : .red)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            // 비밀번호 입력
                            VStack(alignment: .leading, spacing: 8) {
                                LabeledPasswordInputField(
                                    labelText: "auth_password".localized(),
                                    value: $viewModel.pw,
                                    placeholder: "auth_pw_placeholder".localized(),
                                    onValueChange: viewModel.onPasswordChange,
                                    enabled: !viewModel.isCheckingId,
                                    maxLength: 20,
                                    eventBorderColor: (!viewModel.isPasswordValid && !viewModel.pw.isEmpty) ? ElegaiterColors.Status.error : nil
                                )
                                .focused($focusedField, equals: .password)
                                
                                // 비밀번호 유효성 검사 오류 메시지
                                if !viewModel.isPasswordValid && !viewModel.pw.isEmpty {
                                    Text("auth_pw_rule".localized())
                                        .typography(ElegaiterTypography.Caption1)
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            // 비밀번호 확인
                            VStack(alignment: .leading, spacing: 8) {
                                PasswordInputField(
                                    value: $viewModel.pwConfirm,
                                    placeholder: "sign_up_pw_confirm_placeholder".localized(),
                                    onValueChange: viewModel.onPasswordConfirmChange,
                                    enabled: !viewModel.isCheckingId,
                                    maxLength: 20,
                                    eventBorderColor: (!viewModel.isPasswordConfirm && !viewModel.pwConfirm.isEmpty) ? ElegaiterColors.Status.error : nil
                                )
                                .focused($focusedField, equals: .passwordConfirm)
                                
                                // 비밀번호 불일치 메시지
                                if !viewModel.isPasswordConfirm && !viewModel.pwConfirm.isEmpty {
                                    Text("auth_password_confirm_error".localized())
                                        .typography(ElegaiterTypography.Caption1)
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            // 비밀번호 힌트
                            HintDropdownField(
                                selectedHint: $viewModel.pwHint,
                                onHintSelected: viewModel.onPasswordHintSelected
                            )
                            
                            // 비밀번호 힌트 답변
                            RoundedInputField(
                                value: $viewModel.pwHintAnswer,
                                placeholder: "auth_pw_answer".localized(),
                                onValueChange: viewModel.onPasswordHintAnswerChange,
                                enabled: !viewModel.isCheckingId
                            )
                            .focused($focusedField, equals: .hintAnswer)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                        
                        // 하단 고정 버튼을 위한 여유 공간
                        Spacer()
                            .frame(height: 150)
                    }
                }
                .onTapGesture {
                    // 화면 탭 시 키보드 닫기
                    focusedField = nil
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white) // NavigationStack 배경색 명시
            
            // 하단 고정 다음 버튼
            VStack(spacing: 0) {
                PrimaryButton(
                    onClick: {
                        viewModel.onNextClick()
                    },
                    enabled: viewModel.isNextEnabled,
                    showBottomInfo: true,
                    bottomInfoText1: "sign_up_already_have_account".localized(),
                    bottomInfoText2: "auth_login".localized(),
                    onBottomTextClick: {
                        // 회원가입 플로우를 완전히 나가고 로그인 화면으로 이동
                        coordinator.clearSignUpViewModel()
                        viewModel.navigateToLogin()
                    }
                ) {
                    Text("btn_next".localized())
                        .typography(ElegaiterTypography.Label1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.coordinator = coordinator
            // SignUpInfoView로 전달하기 위해 ViewModel 저장
            coordinator.setSignUpViewModel(viewModel)
            
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
    private func handleEvent(_ event: SignUpEvent) {
        switch event {
        case .navigateToSignUpInfo:
            viewModel.navigateToSignUpInfo()
            
        case .navigateToLogin:
            viewModel.navigateToLogin()
            
        case .showToast(let message):
            // 글로벌 토스트로 메시지 표시
            ToastManager.shared.show(message: message)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AppCoordinator())
    }
}
