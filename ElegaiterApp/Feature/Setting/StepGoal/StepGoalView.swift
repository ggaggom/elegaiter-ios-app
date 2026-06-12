//
//  StepGoalView.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI

/// 목표 걸음 수 설정 화면
///
/// Android의 `StepGoalScreen`을 SwiftUI로 변환
/// - 일일 목표 걸음 수 설정
/// - 증가/감소 버튼으로 조절 (1000걸음 단위)
/// - 직접 입력 가능
struct StepGoalView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = StepGoalViewModel()
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "setting_menu_step_goal".localized(),
                    onBackClick: {
                        viewModel.navigateBack()
                    }
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 입력 필드 영역
                        VStack(spacing: 0) {
                            // 제목
                            Text("step_goal_daily".localized())
                                .typography(ElegaiterTypography.Label3)
                                .foregroundColor(ElegaiterColors.Text.sub1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                            
                            // 걸음 수 입력 영역
                            HStack(spacing: 20) {
                                // 감소 버튼
                                GradientIconButton(
                                    iconName: "minus",
                                    onClick: { viewModel.decrementStepGoal() }
                                )
                                
                                // 입력 필드 (RoundedInputField 스타일 적용)
                                HStack(spacing: 8) {
                                    ZStack(alignment: .center) {
                                        // 포커스되지 않았을 때 포맷된 텍스트 표시
                                        if !isInputFocused {
                                            Text(viewModel.uiState.stepGoal.toKoreanStepString())
                                                .typography(ElegaiterTypography.Body3)
                                                .foregroundColor(ElegaiterColors.Text.main)
                                        }
                                        
                                        // 입력 필드
                                        TextField("", text: Binding(
                                            get: {
                                                String(viewModel.uiState.stepGoal)
                                            },
                                            set: { newValue in
                                                let cleanValue = newValue.filter { $0.isNumber }
                                                if let newGoal = Int(cleanValue) {
                                                    viewModel.onStepGoalChange(newGoal)
                                                }
                                            }
                                        ))
                                        .typography(ElegaiterTypography.Body3)
                                        .foregroundColor(ElegaiterColors.Text.main)
                                        .multilineTextAlignment(.center)
                                        .keyboardType(.numberPad)
                                        .focused($isInputFocused)
                                        .opacity(isInputFocused ? 1 : 0)
                                    }
                                }
                                .frame(height: 56)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(isInputFocused ? ElegaiterColors.Green.green400 : ElegaiterColors.Stroke.weak, lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // 입력 필드 영역 터치 시 포커스 주기
                                    isInputFocused = true
                                }
                                
                                // 증가 버튼
                                GradientIconButton(
                                    iconName: "plus",
                                    onClick: { viewModel.incrementStepGoal() }
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
                        viewModel.saveStepGoal()
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
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // 입력 필드가 아닌 영역을 터치했을 때만 키보드 숨기기
                    if isInputFocused {
                        isInputFocused = false
                    }
                }
        )
    }
}

// MARK: - Gradient Icon Button

struct GradientIconButton: View {
    let iconName: String
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            Image(systemName: iconName == "plus" ? "plus" : "minus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(
                        colors: [ElegaiterColors.Green.green300, ElegaiterColors.Green.green400],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(8)
        }
    }
}

// MARK: - Int Extension

extension Int {
    /// 로컬라이즈된 형식으로 걸음 수 문자열 변환
    /// 예: 10000 -> "10,000 걸음" (한국어) / "10,000 steps" (영어)
    func toKoreanStepString() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        
        let formattedNumber = formatter.string(from: NSNumber(value: self)) ?? String(self)
        return "\(formattedNumber) \("exercise_steps".localized())"
    }
}

#Preview {
    StepGoalView()
        .environmentObject(AppCoordinator())
}
