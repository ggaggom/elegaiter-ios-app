//
//  ThresholdView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// Threshold 설정 화면
///
/// Android의 `ThresholdScreen`을 SwiftUI로 변환
/// - 현재 설정값 확인 (확장/축소 가능한 카드)
/// - 임계값 자동 설정
/// - 임계값 수동 설정 (드롭다운)
/// - 저장 및 다음 단계로 이동
struct ThresholdView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = ThresholdViewModel()
    
    @State private var expanded = false
    @State private var showNextBtn = false
    
    /// 키보드 숨기기
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "threshold_title".localized(),
                    onBackClick: {
                        // 진입 경로에 따라 올바른 경로로 돌아가기
                        // Setting(마이페이지)에서 진입한 경우: JawsSearch·Threshold 모두 제거하여 마이페이지로
                        // JawsSearch에서 진입한 경우: 운동하기 홈(ExerciseReady)으로 이동
                        if !coordinator.settingPath.isEmpty {
                            coordinator.settingPath = NavigationPath()
                        } else {
                            // JawsSearch → Threshold 플로우: 로그인 완료 처리 후 운동 홈으로
                            coordinator.isLoggedIn = true
                            coordinator.switchTab(to: .exercise)
                            coordinator.exercisePath = NavigationPath()
                        }
                    }
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 12)
                        
                        // 현재 설정값 확인 카드 (첫 번째 카드)
                        Button(action: {
                            viewModel.checkCurrentThreshold()
                            expanded.toggle()
                        }) {
                            HStack(alignment: .center, spacing: 0) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("threshold_check_title".localized())
                                        .typography(ElegaiterTypography.Headline6)
                                        .foregroundColor(ElegaiterColors.Text.sub2)
                                    
                                    Text("threshold_check_subtitle".localized())
                                        .typography(ElegaiterTypography.Body4)
                                        .foregroundColor(ElegaiterColors.Text.sub1)
                                        .padding(.top, 4)
                                }
                                
                                Spacer()
                                
                                Image(expanded ? "IcDropUp" : "IcDropDown")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color.white)
                        .clipShape(
                            RoundedCorner(
                                radius: 20,
                                corners: expanded ? [.topLeft, .topRight] : .allCorners
                            )
                        )
                        .overlay(
                            RoundedCorner(
                                radius: 20,
                                corners: expanded ? [.topLeft, .topRight] : .allCorners
                            )
                            .stroke(ElegaiterColors.Stroke.medium, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // 현재 설정값 확인 카드 (확장된 부분 - 두 번째 카드)
                        if expanded {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("threshold".localized())
                                        .typography(ElegaiterTypography.Body4)
                                        .foregroundColor(ElegaiterColors.Text.sub1)
                                    
                                    Spacer()
                                    
                                    Text(viewModel.uiState.currentThreshold)
                                        .typography(ElegaiterTypography.Label1)
                                        .foregroundColor(ElegaiterColors.Text.main)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                            }
                            .background(ElegaiterColors.Background.light)
                            .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // 임계값 자동 설정 카드
                        VStack(alignment: .leading, spacing: 0) {
                            Text("threshold_auto_setting".localized())
                                .typography(ElegaiterTypography.Headline6)
                                .foregroundColor(ElegaiterColors.Text.sub2)
                                .padding(.bottom, 4)
                            
                            Text("threshold_auto_description".localized())
                                .typography(ElegaiterTypography.Body4)
                                .foregroundColor(ElegaiterColors.Text.sub1)
                                .padding(.bottom, 20)
                            
                            PrimaryButton(
                                onClick: {
                                    viewModel.setAutoThreshold()
                                    expanded = true
                                    showNextBtn = true
                                },
                                enabled: !viewModel.uiState.isLoading
                            ) {
                                Text("threshold_auto_btn".localized())
                                    .typography(ElegaiterTypography.Label1)
                            }
                            .frame(height: 45)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ElegaiterColors.Green.green50)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(ElegaiterColors.Green.green400, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // 구분선 ("또는")
                        HStack(alignment: .center, spacing: 0) {
                            Rectangle()
                                .fill(ElegaiterColors.Stroke.medium)
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                            
                            Text("threshold_or".localized())
                                .typography(ElegaiterTypography.Label3)
                                .foregroundColor(ElegaiterColors.Text.sub1)
                                .padding(.horizontal, 8)
                            
                            Rectangle()
                                .fill(ElegaiterColors.Stroke.medium)
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // 임계값 수동 설정 카드
                        WhiteGrayCard {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("threshold_manual_setting".localized())
                                    .typography(ElegaiterTypography.Headline6)
                                    .foregroundColor(ElegaiterColors.Text.sub2)
                                    .padding(.bottom, 4)
                                
                                Text("threshold_manual_description".localized())
                                    .typography(ElegaiterTypography.Body4)
                                    .foregroundColor(ElegaiterColors.Text.sub1)
                                
                                RoundedInputField(
                                    value: $viewModel.uiState.selectedThreshold,
                                    placeholder: "threshold_manual_placeholder".localized(),
                                    onValueChange: { newValue in
                                        viewModel.onThresholdSelected(newValue)
                                    }
                                )
                                .keyboardType(.numberPad)
                                .padding(.top, 20)
                                
                                // 안내 메시지
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(ElegaiterColors.Status.info)
                                    
                                    Text("threshold_manual_warning".localized())
                                        .typography(ElegaiterTypography.Caption1)
                                        .foregroundColor(ElegaiterColors.Status.info)
                                }
                                .padding(.top, 20)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        
                        // 구분선 (BackgroundLight 배경)
                        Rectangle()
                            .fill(ElegaiterColors.Background.light)
                            .frame(height: 8)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        
                        // 임계값 재설정 안내 팝업 설정
                        HStack(alignment: .center, spacing: 0) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("threshold_reset_popup_title".localized())
                                    .typography(ElegaiterTypography.Headline5)
                                    .foregroundColor(ElegaiterColors.Text.main)
                                
                                Text("threshold_reset_popup_message".localized())
                                    .typography(ElegaiterTypography.Caption2)
                                    .foregroundColor(ElegaiterColors.Text.sub1)
                                    .padding(.top, 8)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { viewModel.uiState.shouldShowThresholdPrompt },
                                set: { _ in viewModel.toggleShouldShowThresholdPrompt() }
                            ))
                            .toggleStyle(CustomToggleStyle())
                            .frame(width: 40, height: 24)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20) // 하단 여백 추가
                        
                        // 하단 고정 버튼을 위한 여유 공간
                        Spacer()
                            .frame(height: 150)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    // 화면 탭 시 키보드 닫기
                    hideKeyboard()
                }
            }
            .background(Color.white) // NavigationStack 배경색 명시
            
            // BottomBar (고정)
            VStack(spacing: 10) {
                // 저장하기 버튼 (수동 설정용)
                PrimaryButton(
                    onClick: {
                        // 버튼 클릭 시 키보드 닫기
                        hideKeyboard()
                        viewModel.setManualThreshold()
                        expanded = true
                        showNextBtn = true
                    },
                    enabled: !viewModel.uiState.selectedThreshold.isEmpty && !viewModel.uiState.isLoading
                ) {
                    Text("btn_save".localized())
                        .typography(ElegaiterTypography.Label1)
                }
                
                // 다음 버튼 (설정 완료 후 표시)
                if showNextBtn {
                    PrimaryButton(
                        onClick: {
                            // 버튼 클릭 시 키보드 닫기
                            hideKeyboard()
                            viewModel.completeThresholdSetup()
                        },
                        enabled: true
                    ) {
                        Text("btn_next".localized())
                            .typography(ElegaiterTypography.Label1)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .padding(.bottom, 20)
            .background(Color.white)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.coordinator = coordinator
            // Threshold 화면 진입 시 탭바 즉시 숨김 (애니메이션 없음)
            // Setting에서 진입한 경우에만 탭바가 있으므로 숨김
            // JawsSearch 이후 진입한 경우는 이미 탭바가 없으므로 영향 없음
            if coordinator.isLoggedIn {
                coordinator.shouldShowTabBar = false
            }
        }
        .onDisappear {
            // Threshold 화면에서 나갈 때 탭바 표시 여부 결정
            // Setting에서 진입한 경우: Setting으로 돌아가므로 탭바 표시 필요 (애니메이션으로)
            // JawsSearch 이후 진입한 경우: JawsSearch로 돌아가므로 탭바 없어야 함
            if coordinator.isLoggedIn {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    coordinator.shouldShowTabBar = true
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
    /// - 토스트 메시지를 글로벌 토스트로 표시
    private func handleEvent(_ event: ThresholdEvent) {
        switch event {
        case .showToast(let message):
            ToastManager.shared.show(message: message)
        }
    }
}

// MARK: - Custom Toggle Style

/// 커스텀 토글 스타일
///
/// Android의 Switch 디자인을 SwiftUI로 변환
/// - 활성화: Green400 배경, 흰색 thumb
/// - 비활성화: StrokeWeak 배경, 흰색 thumb
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                // 배경
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isOn ? ElegaiterColors.Green.green400 : ElegaiterColors.Stroke.weak)
                    .frame(width: 40, height: 24)
                
                // Thumb (흰색 원)
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .padding(2)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThresholdView()
        .environmentObject(AppCoordinator())
}
