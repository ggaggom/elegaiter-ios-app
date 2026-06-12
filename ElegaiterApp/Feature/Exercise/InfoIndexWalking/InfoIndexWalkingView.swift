//
//  InfoIndexWalkingView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

/// 인덱스 워킹 안내 화면
///
/// Android의 `InfoIndexWalkingScreen`을 SwiftUI로 변환
/// - 인덱스 워킹 방법 안내
/// - 5초 카운트다운 후 운동 세션 초기화 및 IndexWalking 화면으로 이동
struct InfoIndexWalkingView: View {
    @ObservedObject var router: ExerciseRouter
    @ObservedObject var viewModel: ExerciseSessionViewModel
    
    @State private var showDisconnectionDialog = false
    @State private var previousBleConnectionState: BleConnectionState = .disconnected
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // 헤더 (고정)
                ElegaiterTopBar(
                    title: "exercise_setup_title".localized(),
                    onBackClick: {
                        // 뒤로가기: NavigationStack의 pop 사용
                        if let coordinator = router.coordinator {
                            coordinator.pop(in: Binding(
                                get: { coordinator.exercisePath },
                                set: { coordinator.exercisePath = $0 }
                            ))
                        }
                    },
                    showProgress: true,
                    currentStep: 2,
                    totalStep: 2
                )
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 상단 여백
                        Spacer()
                            .frame(height: 12)
                        
                        // 안내 텍스트
                        Text("exercise_index_walking_guide_title1".localized())
                            .typography(ElegaiterTypography.Headline5)
                            .foregroundColor(ElegaiterColors.Text.main)
                        
                        Text("index_walking_description".localized())
                            .typography(ElegaiterTypography.Body3)
                            .foregroundColor(ElegaiterColors.Text.sub1)
                            .padding(.top, 4)
                        
                        // 안내 카드
                        IndexWalkingGuideCard()
                            .padding(.top, 28)
                        
                        // 하단 여백 (버튼 공간 확보)
                        Spacer()
                            .frame(height: 150)
                    }
                    .padding(.horizontal, 20)
                }
                .id("infoIndexWalkingScrollView") // 고유 ID로 스크롤 상태 분리
            }
            
            // 하단 버튼 (고정)
            VStack(spacing: 10) {
                PrimaryButton(
                    onClick: {
                        viewModel.onCountDownToNavigateIndexWalking()
                    },
                    enabled: viewModel.uiState.isFormValid
                ) {
                    Text("exercise_index_walking_confirm".localized())
                        .typography(ElegaiterTypography.Label1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .padding(.bottom, 20)
            .background(Color(.systemBackground))
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            // 카운트다운 오버레이
            if viewModel.uiState.isCountingDown {
                CountdownOverlay(
                    totalSeconds: 5,
                    remainingTime: viewModel.uiState.remainingCountdownTime,
                    titleText: "exercise_treadmill_start".localized()
                )
            }
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            previousBleConnectionState = viewModel.bleConnectionState
        }
        .onChange(of: viewModel.bleConnectionState) { newValue in
            // 연결 상태가 CONNECTED가 아닌 상태로 변경되면 다이얼로그 표시
            // 안드로이드: bleConnectionState.ordinal > BleConnectionState.CONNECTED.ordinal
            if newValue != .connected {
                showDisconnectionDialog = true
            }
            previousBleConnectionState = newValue
        }
        .overlay {
            // 블루투스 연결 필요 다이얼로그
            if showDisconnectionDialog {
                StyledAlertDialog(
                    isPresented: $showDisconnectionDialog,
                    title: "exercise_device_connection_required".localized(),
                    message: "exercise_device_connection_required_message".localized(),
                    content: { EmptyView() },
                    confirmText: "btn_confirm".localized(),
                    onConfirm: {
                        showDisconnectionDialog = false
                        navigateToJawsSearch()
                    },
                    dismissText: nil,
                    onDismiss: {}
                )
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    /// JawsSearch 화면으로 이동
    private func navigateToJawsSearch() {
        if let coordinator = router.coordinator {
            coordinator.exercisePath = NavigationPath()
            coordinator.navigateInExercise(to: .jawsSearch)
        }
    }
}

/// 인덱스 워킹 안내 카드
///
/// Android의 안내 카드를 SwiftUI로 변환
/// - 초록색 배경 및 테두리
/// - 체크 아이콘과 함께 3가지 안내 사항
private struct IndexWalkingGuideCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 제목
            Text("exercise_index_walking_how_to".localized())
                .typography(ElegaiterTypography.Headline6)
                .foregroundColor(ElegaiterColors.Text.main)
                .padding(.bottom, 10)
            
            // 안내 사항 1
            GuideItem(
                text: "exercise_index_walking_step1".localized()
            )
            
            Spacer()
                .frame(height: 6)
            
            // 안내 사항 2
            GuideItem(
                text: "exercise_index_walking_step2".localized()
            )
            
            Spacer()
                .frame(height: 6)
            
            // 안내 사항 3
            GuideItem(
                text: "exercise_index_walking_step3".localized()
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ElegaiterColors.Green.green50)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ElegaiterColors.Green.green400, lineWidth: 1)
                )
        )
        .localized() // 언어 변경 시 자동 업데이트
    }
}

/// 안내 항목 컴포넌트
private struct GuideItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // 체크 아이콘
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ElegaiterColors.Green.green400)
                .frame(width: 20, height: 20)
            
            // 텍스트
            Text(text)
                .typography(ElegaiterTypography.Body4)
                .foregroundColor(ElegaiterColors.Text.main)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    let coordinator = AppCoordinator()
    let router = ExerciseRouter(coordinator: coordinator)
    return InfoIndexWalkingView(router: router, viewModel: router.sessionViewModel)
}
