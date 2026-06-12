//
//  FindPwView.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI

/// FindPw 화면
/// 
/// Android의 `FindPwScreen`을 SwiftUI로 변환
/// - 아이디와 비밀번호 힌트로 본인 인증
/// - 힌트 인증 성공 시 ResetPw 화면으로 이동
struct FindPwView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = FindPwViewModel()
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    
    /// 포커스 필드 열거형
    enum Field {
        case id
        case answer
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "auth_find_pw".localized(),
                    onBackClick: {
                        // ViewModel 정리 (뒤로가기 시)
                        coordinator.clearFindPwViewModel()
                        // 안드로이드와 동일: popUpTo<FindPwNavRoute.FindPwGraph> { inclusive = true }
                        // FindPwGraph 전체를 백스택에서 제거하고 Login으로 이동
                        // iOS에서는 mainPath에서 findPw를 제거하여 자연스러운 뒤로가기 트랜지션
                        coordinator.pop(in: Binding(
                            get: { coordinator.mainPath },
                            set: { coordinator.mainPath = $0 }
                        ))
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
                            
                            // 아이디 입력 필드
                            LabeledRoundedInputField(
                                labelText: "auth_id".localized(),
                                value: $viewModel.id,
                                placeholder: "auth_id_placeholder".localized(),
                                onValueChange: viewModel.onIdChange,
                                enabled: !viewModel.isLoading
                            )
                            .focused($focusedField, equals: .id)
                            
                            // 비밀번호 분실시 라벨
                            Text("auth_pw_lost".localized())
                                .typography(ElegaiterTypography.Label3)
                                .foregroundColor(ElegaiterColors.Text.sub1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 40)
                                .padding(.bottom, 6)
                            
                            // 비밀번호 힌트 선택 (라벨 없음)
                            HintDropdownField(
                                selectedHint: $viewModel.selectedHint,
                                onHintSelected: viewModel.onHintChange,
                                labelText: "" // 라벨 숨김
                            )
                            
                            // 힌트 답변 입력 필드
                            VStack(alignment: .leading, spacing: 0) {
                                RoundedInputField(
                                    value: $viewModel.answer,
                                    placeholder: "auth_pw_answer".localized(),
                                    onValueChange: viewModel.onAnswerChange,
                                    enabled: !viewModel.isLoading,
                                    eventBorderColor: viewModel.hintError ? ElegaiterColors.Status.error : nil
                                )
                                .focused($focusedField, equals: .answer)
                                .padding(.top, 16)
                                
                                // 에러 메시지 표시
                                if viewModel.hintError {
                                    Text("find_pw_answer_retry".localized())
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
            
            // 하단 고정 확인 버튼
            VStack {
                Spacer()
                PrimaryButton(
                    onClick: {
                        viewModel.onNextClick()
                    },
                    enabled: viewModel.isNextEnabled
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
        }
        .onTapGesture {
            // 화면 탭 시 키보드 닫기
            focusedField = nil
        }
        .onAppear {
            viewModel.coordinator = coordinator
            viewModel.clearVerificationAnswer()
            // ResetPwView로 전달하기 위해 ViewModel 저장
            coordinator.setFindPwViewModel(viewModel)
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
            ToastManager.shared.show(message: message)
            
        case .navigateToResetPw:
            viewModel.navigateToResetPw(requiresCurrentPassword: false)

        case .navigateToVerifyHint:
            break

        case .navigateToLogin:
            viewModel.navigateToLogin()
            
        case .navigateToSetting:
            viewModel.navigateToSetting()
        }
    }
}

#Preview {
    NavigationStack {
        FindPwView()
            .environmentObject(AppCoordinator())
    }
}

