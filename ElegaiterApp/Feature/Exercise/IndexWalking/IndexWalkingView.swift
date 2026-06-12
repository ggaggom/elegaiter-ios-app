//
//  IndexWalkingView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK
import os.log

/// 인덱스 워킹 화면
/// 
/// Android의 `IndexWalkingScreen`을 SwiftUI로 변환
/// - 좌/우 발 구분을 위한 초기 학습 단계 (10걸음)
/// - 10초 준비 시간 카운트다운
/// - 실시간 그래프 표시
/// - 인덱싱 진행 상황 표시
struct IndexWalkingView: View {

    private static let logger = Logger(subsystem: "com.elegaiter.app", category: "IndexWalkingView")

    @ObservedObject var router: ExerciseRouter
    @ObservedObject var viewModel: ExerciseSessionViewModel
    
    @State private var showReadyOverlay = false
    @State private var showDisconnectionDialog = false
    @State private var previousBleConnectionState: BleConnectionState = .disconnected
    
    var body: some View {
        ZStack {
            // 배경 그라데이션 (안드로이드: Brush.verticalGradient(Green50 -> BackgroundLight))
            LinearGradient(
                colors: [
                    ElegaiterColors.Green.green50,
                    ElegaiterColors.Background.light
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더 (고정)
                ElegaiterHeader(
                    title: "exercise_index_walking_title".localized(),
                    onBackClick: handleBackNavigation
                )
                .padding(.top, 8) // status bar 영역
                
                // 스크롤 가능한 콘텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 40)
                        
                        // 실시간 그래프
                        GaitDataGraph(rawData: viewModel.uiState.rawGaitStream)
                            .frame(height: 200)
                            .padding(.horizontal, 23)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
                
                // 하단 컨텐츠 영역 (안드로이드: RoundedCornerShape(topStart = 40.dp, topEnd = 40.dp), weight(1f))
                // 높이 360으로 고정
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 40)
                    
                    // 안내 메시지 (안드로이드: TextMain)
                    Text(guideMessage)
                        .typography(ElegaiterTypography.Headline5)
                        .foregroundColor(ElegaiterColors.Text.main)
                        .padding(.bottom, uiState.remainingCountdownTime > 0 ? 40 : 48)
                    
                    // 카운트다운 또는 인덱싱 진행 상황
                    if uiState.remainingCountdownTime > 0 {
                        // 10초 카운트다운 (안드로이드: textColor = TextMain)
                        CountdownProgressBar(
                            totalSeconds: 10,
                            remainingTime: uiState.remainingCountdownTime,
                            progressColor: ElegaiterColors.Green.green300,
                            textColor: ElegaiterColors.Text.main
                        )
                    } else if !uiState.isShowExtensionGuide {
                        // 인덱싱 진행 상황 (안드로이드: Display1)
                        // 가이드가 표시되는 동안에는 인덱싱 진행 상황을 표시하지 않음
                        let displayStep = max(((uiState.indexingProgress + 1) / 2), 1)
                        let totalSteps = uiState.requiredIndexingSteps / 2
                        
                        Text("\(displayStep) / \(totalSteps)")
                            .typography(ElegaiterTypography.Display1)
                            .foregroundColor(ElegaiterColors.Text.main)
                            .padding(.bottom, 48)
                        
                        CircularStepIndicator(currentStep: displayStep)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .background(
                    // 안드로이드: RoundedCornerShape(topStart = 40.dp, topEnd = 40.dp), background(Color.White)
                    // 상단 좌우만 40 라디어스, 하단은 라디어스 없음
                    // 배경은 화면 하단까지 확장
                    VStack(spacing: 0) {
                        RoundedCorner(radius: 40, corners: [.topLeft, .topRight])
                            .fill(Color.white)
                            .frame(height: 360)
                        
                        Rectangle()
                            .fill(Color.white)
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                )
            }
            
            // 재시도 메시지 오버레이 (안드로이드: uiState.showRetryMessage)
            if uiState.showRetryMessage {
                StatusOverlay(
                    title: "exercise_index_walking_fail".localized(),
                    iconName: "IcIndexWalking",
                    iconSize: 100,
                    titleStyle: ElegaiterTypography.Headline5
                )
            }
            
            // 발 뻗기 가이드 오버레이 (안드로이드: uiState.isShowExtensionGuide)
            if uiState.isShowExtensionGuide {
                StatusOverlay(
                    title: "exercise_index_walking_prepare_step".localized(),
                    iconName: "IcIndexWalking",
                    iconSize: 100,
                    titleStyle: ElegaiterTypography.Headline5
                )
            }
            
            // 준비 완료 오버레이
            if showReadyOverlay {
                StatusOverlay(
                    title: "exercise_index_walking_success1".localized(),
                    bodyText: "exercise_index_walking_success2".localized()
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            let bleState = viewModel.bleConnectionState
            let indexing = uiState.isIndexing
            Self.logger.debug("📱 [IndexWalkingView] 화면 진입 (onAppear) - BLE: \(String(describing: bleState)), 인덱싱: \(indexing)")
            
            // 화면 꺼짐 방지 활성화
            UIApplication.shared.isIdleTimerDisabled = true
            
            // 초기 상태 저장
            previousBleConnectionState = viewModel.bleConnectionState
            
            // 화면 진입 시 자동으로 카운트다운 시작
            viewModel.onCountDownToStartIndexWalking()
        }
        .onDisappear {
            let bleState = viewModel.bleConnectionState
            Self.logger.debug("📱 [IndexWalkingView] 화면 이탈 (onDisappear) - BLE: \(String(describing: bleState))")
            
            // 화면 꺼짐 방지 해제
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: uiState.isIndexingSuccess) { isSuccess in
            // 인덱싱 "성공" 시 오버레이 표시 후 RealTimeExercise로 이동
            // 주의: 걸음 수만으로 전환하면 타이머가 시작되지 않아 00:00 고정이 발생할 수 있으므로
            // SDK의 indexingSuccessEvent 기반 상태(isIndexingSuccess)를 기준으로 전환합니다.
            if isSuccess {
                showReadyOverlay = true
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
                    await MainActor.run {
                        showReadyOverlay = false
                        viewModel.navigateToRealTime()
                    }
                }
            }
        }
        .onChange(of: bleConnectionState) { newState in
            // 안드로이드: bleConnectionState.ordinal > BleConnectionState.CONNECTED.ordinal
            // 연결 상태가 CONNECTED보다 나쁜 상태로 변경되면 다이얼로그 표시
            if newState != .connected {
                showDisconnectionDialog = true
            }
            previousBleConnectionState = newState
        }
        .overlay {
            // 블루투스 연결 끊김 다이얼로그 (안드로이드: StyledAlertDialog)
            if showDisconnectionDialog {
                StyledAlertDialog(
                    isPresented: $showDisconnectionDialog,
                    title: "exercise_bluetooth_connection_lost_title".localized(),
                    message: "exercise_bluetooth_connection_lost_message1".localized(),
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
    
    // MARK: - Computed Properties
    
    private var uiState: ExerciseSessionUiState {
        viewModel.uiState
    }
    
    private var bleConnectionState: BleConnectionState {
        viewModel.bleConnectionState
    }
    
    /// 안내 메시지
    /// 
    /// 카운트다운 중이면 준비 메시지, 인덱싱 중이면 발 선택 메시지
    private var guideMessage: String {
        if uiState.remainingCountdownTime > 0 {
            return "exercise_index_walking_walk_naturally".localized()
        } else {
            return uiState.selectedFoot == "left"
                ? "exercise_index_walking_left_step".localized()
                : "exercise_index_walking_right_step".localized()
        }
    }
    
    /// JawsSearch 화면으로 이동
    private func navigateToJawsSearch() {
        if let coordinator = router.coordinator {
            coordinator.exercisePath = NavigationPath()
            coordinator.navigateInExercise(to: .jawsSearch)
        }
    }
    
    /// 뒤로가기 시 세션 정리 후 이전 화면으로 이동 (Android: handleBackNavigation)
    private func handleBackNavigation() {
        viewModel.onCancelIndexWalking()
        if let coordinator = router.coordinator {
            coordinator.pop(in: Binding(
                get: { coordinator.exercisePath },
                set: { coordinator.exercisePath = $0 }
            ))
        }
    }
}

#Preview {
    let coordinator = AppCoordinator()
    let router = ExerciseRouter(coordinator: coordinator)
    return IndexWalkingView(router: router, viewModel: router.sessionViewModel)
}
