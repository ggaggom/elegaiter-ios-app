//
//  RealTimeExerciseView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK
import UIKit

/// 실시간 운동 화면
///
/// Android의 `RealTimeExerciseScreen`을 SwiftUI로 변환
/// - 실시간 보행 데이터 수집 및 분석
/// - 실시간 그래프 표시 (보행 시계열, Median-IQR)
/// - 실시간 통계 표시 (걸음 수, 케이던스, 보행 유형 등)
/// - 목표 시간 달성률 표시
/// - 그래프 제어 (타입 전환, 크기 조절, 초기화)
/// - 운동 종료 및 데이터 저장
struct RealTimeExerciseView: View {
    @ObservedObject var router: ExerciseRouter
    @ObservedObject var viewModel: ExerciseSessionViewModel
    
    @State private var showDisconnectionDialog = false
    
    // CountdownOverlay 표시 여부 계산
    private var showCountdownOverlay: Bool {
        let totalDurationSeconds = Int64((viewModel.uiState.exerciseInfo?.duration ?? 0) * 60)
        return (totalDurationSeconds > 0)
        && (viewModel.uiState.remainingTime >= 1 && viewModel.uiState.remainingTime <= 10)
        && (!viewModel.uiState.isSessionExtended)
    }
    
    var body: some View {
        ZStack {
            if !viewModel.showFinishOverlay {
                exerciseMainContent
            }
            
            if viewModel.showFinishOverlay {
                ExerciseEndFlowOverlay(viewModel: viewModel)
            }
            
            // BLE 연결 끊김 다이얼로그
            if showDisconnectionDialog {
                StyledAlertDialog(
                    isPresented: $showDisconnectionDialog,
                    title: "exercise_bluetooth_connection_lost_title".localized(),
                    message: "realtime_exercise_bluetooth_disconnected_message".localized(),
                    content: { EmptyView() },
                    confirmText: "btn_confirm".localized(),
                    onConfirm: {
                        showDisconnectionDialog = false
                        viewModel.onStopExerciseClick(gotoJawsSearch: true)
                    },
                    dismissText: "exercise_end".localized(),
                    onDismiss: {
                        showDisconnectionDialog = false
                        viewModel.onStopExerciseClick(gotoJawsSearch: false)
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            viewModel.switchSegment(newMode: .static)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: viewModel.bleConnectionState) { state in
            if state != .connected {
                showDisconnectionDialog = true
            }
        }
        .localized()
    }
    
    private var exerciseMainContent: some View {
        ZStack {
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
                // 헤더 영역 (고정) (안드로이드: Box + ElegaiterHeader + 게임 모드 버튼)
                ZStack(alignment: .trailing) {
                    // 헤더 (안드로이드: ElegaiterHeader, showBackIcon = false)
                    ElegaiterHeader(
                        title: "exercise_realtime_title".localized(),
                        onBackClick: {},
                        showBackIcon: false
                    )
                    .padding(.top, 8)
                    
                    // 게임 모드 버튼 (안드로이드: Button, Green500, Label3, RoundedCornerShape(20.dp))
                    Button(action: {
                        router.navigate(to: .arcade)
                    }) {
                        Text("exercise_game_mode".localized())
                            .typography(ElegaiterTypography.Label3)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(ElegaiterColors.Green.green500)
                            .cornerRadius(20)
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 8)
                }
                
                // 그래프 콘텐츠 영역 (고정 레이아웃)
                VStack(spacing: 0) {
                    // 그래프 타입 전환 버튼 (상단 고정)
                    HStack(spacing: 12) {
                        // 보행 시계열
                        Text("exercise_graph_envelope".localized())
                            .typography(
                                viewModel.uiState.showMedianIqrGraph
                                ? ElegaiterTypography.Body4
                                : ElegaiterTypography.Label3
                            )
                            .foregroundColor(
                                viewModel.uiState.showMedianIqrGraph
                                ? ElegaiterColors.Text.disabled
                                : ElegaiterColors.Text.main
                            )
                            .padding(8)
                            .onTapGesture {
                                viewModel.onGraphTypeChange(false)
                            }
                        
                        // 구분선 (안드로이드: Spacer, width = 1.dp, height = 16.dp, StrokeMedium)
                        Rectangle()
                            .fill(ElegaiterColors.Stroke.medium)
                            .frame(width: 1, height: 16)
                        
                        // Median-IQR
                        Text("exercise_graph_median_iqr".localized())
                            .typography(
                                viewModel.uiState.showMedianIqrGraph
                                ? ElegaiterTypography.Label3
                                : ElegaiterTypography.Body4
                            )
                            .foregroundColor(
                                viewModel.uiState.showMedianIqrGraph
                                ? ElegaiterColors.Text.main
                                : ElegaiterColors.Text.disabled
                            )
                            .padding(8)
                            .onTapGesture {
                                viewModel.onGraphTypeChange(true)
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // 그래프 영역 (전체 공간 사용, 하단 운동 정보와 여백 16)
                    graphSection
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 16)
                
                // 운동 정보 영역 (하단 고정)
                exerciseInfoSection
            }
            
            if showCountdownOverlay {
                CountdownOverlay(
                    totalSeconds: 10,
                    remainingTime: Int(viewModel.uiState.remainingTime),
                    titleText: "exercise_target_time_complete_message".localized(),
                    buttonText: "exercise_btn_yes".localized(),
                    onButtonClick: {
                        viewModel.extendExerciseSession()
                    }
                )
            }
        }
    }
    
    // MARK: - Graph Section
    
    private var graphSection: some View {
        let graphHeight = CGFloat(160 * viewModel.uiState.graphSizePercent)
        
        return VStack(spacing: 0) {
            if viewModel.uiState.showMedianIqrGraph {
                // Median-IQR 그래프
                // 그래프를 수직 중앙에 배치하고 왼발/오른발 표기는 하단에 고정
                // globalMax 계산 (안드로이드: maxOf(leftMedianStream.maxOrNull() ?: 0f, rightMedianStream.maxOrNull() ?: 0f, 0f))
                let globalMax = max(
                    viewModel.uiState.leftMedianStream.max() ?? 0.0,
                    viewModel.uiState.rightMedianStream.max() ?? 0.0,
                    0.0
                )
                
                GeometryReader { geometry in
                    let availableHeight = geometry.size.height
                    let labelHeight: CGFloat = 24 + 24 // padding.top + 텍스트 높이 추정
                    let remainingHeight = availableHeight - labelHeight
                    let graphHeight = remainingHeight * 7 / 10 // 남은 영역의 7/10
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        HStack(spacing: 30) {
                            // 왼발 그래프
                            VStack(spacing: 0) {
                                GaitDataGraph(
                                    rawData: viewModel.uiState.leftMedianStream,
                                    optionalRawData: viewModel.uiState.leftIqrStream,
                                    lineColor: .green,
                                    optionalColor: .green,
                                    fixedMaxValue: globalMax, // 안드로이드: fixedMaxValue = globalMax
                                    fixedMinValue: 0.0 // 안드로이드: fixedMinValue = 0f
                                )
                                .frame(height: graphHeight)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // 오른발 그래프
                            VStack(spacing: 0) {
                                GaitDataGraph(
                                    rawData: viewModel.uiState.rightMedianStream,
                                    optionalRawData: viewModel.uiState.rightIqrStream,
                                    lineColor: .red,
                                    optionalColor: .red,
                                    fixedMaxValue: globalMax, // 안드로이드: fixedMaxValue = globalMax
                                    fixedMinValue: 0.0 // 안드로이드: fixedMinValue = 0f
                                )
                                .frame(height: graphHeight)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        // 왼발/오른발 표기부 (하단 고정)
                        HStack(spacing: 30) {
                            Text("exercise_left_foot".localized())
                                .typography(ElegaiterTypography.Label4) // 안드로이드: Label4
                                .foregroundColor(ElegaiterColors.Text.sub1) // 안드로이드: TextSub1
                                .frame(maxWidth: .infinity)
                            
                            Text("exercise_right_foot".localized())
                                .typography(ElegaiterTypography.Label4) // 안드로이드: Label4
                                .foregroundColor(ElegaiterColors.Text.sub1) // 안드로이드: TextSub1
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24) // 안드로이드: top = 24.dp
                    }
                }
            } else {
                // 보행 시계열 그래프 (Envelope)
                // 그래프를 중앙에 배치하고 컨트롤러는 하단에 고정
                Spacer()
                
                let widthSize = viewModel.uiState.rawGaitStream.count * viewModel.uiState.graphCount / 10
                GaitDataGraph(
                    rawData: viewModel.uiState.rawGaitStream,
                    lineColor: .green,
                    widthSize: widthSize
                )
                .frame(height: graphHeight)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // 그래프 제어 (하단 고정)
                graphControlsSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Graph Controls Section
    
    private var graphControlsSection: some View {
        let heightPercentText = String(format: "%.0f%%", viewModel.uiState.graphSizePercent * 100)
        let widthPercentText = String(format: "%.0f%%", 100 - Float((viewModel.uiState.graphCount - 5) * 10))
        
        // 안드로이드: Row의 horizontalArrangement = Arrangement.SpaceBetween
        return HStack(spacing: 0) {
            // 그래프 높낮이 제어
            GraphControlRow(
                title: "exercise_graph_height".localized(),
                currentValue: heightPercentText,
                onIncreaseClick: viewModel.increaseGraphHeight,
                onDecreaseClick: viewModel.decreaseGraphHeight
            )
            .frame(maxWidth: .infinity)
            
            // 그래프 폭 제어
            GraphControlRow(
                title: "exercise_graph_width".localized(),
                currentValue: widthPercentText,
                onIncreaseClick: viewModel.increaseGraphWidth,
                onDecreaseClick: viewModel.decreaseGraphWidth
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12) // 안드로이드: top = 12.dp
        .padding(.bottom, 8) // 안드로이드: bottom = 8.dp
    }
    
    // MARK: - Exercise Info Section
    
    private var exerciseInfoSection: some View {
        let uiState = viewModel.uiState
        let metrics = uiState.gaitMetrics
        
        // 경과 시간 계산 (안드로이드: displayTimeSeconds)
        // isSessionExtended일 때는 경과 시간을 그대로 표시, 아닐 때는 목표 시간까지만 표시
        let totalDurationSeconds = Int64((uiState.exerciseInfo?.duration ?? 0) * 60)
        let displayTimeSeconds = if uiState.isSessionExtended {
            uiState.elapsedTime
        } else {
            min(uiState.elapsedTime, totalDurationSeconds)
        }
        let elapsedMinutes = Int(displayTimeSeconds / 60)
        let elapsedSeconds = Int(displayTimeSeconds % 60)
        let elapsedTimeFormatted = String(format: "%02d:%02d", elapsedMinutes, elapsedSeconds)
        
        // 현재 보행 상태
        let lastStepType = metrics?.lastStepType ?? .none
        let (circleColor, stepText) = stepTypeInfo(for: lastStepType)
        
        // 보행 유형 통계
        let stats = metrics?.stepTypeStats
        let walkingStats = stats?.walking
        let runningStats = stats?.running
        let unknownStats = stats?.limping
        
        return VStack(spacing: 0) {
            // 운동 정보 영역 (안드로이드: Column with padding(12.dp), clip(RoundedCornerShape(20.dp)), background(Color.White))
            // 안드로이드 순서: padding(12.dp) → clip → background → 내부 padding
            VStack(spacing: 0) {
                // 경과 시간 및 보행 상태
                // 안드로이드: Row with SpaceBetween
                HStack {
                    // 안드로이드: Display3, TextMain
                    Text(elapsedTimeFormatted)
                        .typography(ElegaiterTypography.Display3)
                        .foregroundColor(ElegaiterColors.Text.main)
                    
                    Spacer()
                    
                    // 보행 상태 배지 (안드로이드: BackgroundTransparent, Caption1, White)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(circleColor)
                            .frame(width: 8, height: 8)
                        
                        Text(stepText)
                            .typography(ElegaiterTypography.Caption1) // 안드로이드: Caption1
                            .foregroundColor(.white) // 안드로이드: White
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(ElegaiterColors.Background.transparent) // 안드로이드: BackgroundTransparent
                    )
                }
                
                // 목표 시간 달성률
                // 안드로이드: Row with Absolute.SpaceBetween
                HStack {
                    // 안드로이드: Caption1, TextSub1
                    Text("exercise_target_time_progress".localized())
                        .typography(ElegaiterTypography.Caption1) // 안드로이드: Caption1
                        .foregroundColor(ElegaiterColors.Text.sub1) // 안드로이드: TextSub1
                    
                    Spacer()
                    
                    // 안드로이드: Label1, TextMain
                    Text("\(Int(uiState.progress * 100))%")
                        .typography(ElegaiterTypography.Label1) // 안드로이드: Label1
                        .foregroundColor(ElegaiterColors.Text.main) // 안드로이드: TextMain
                }
                .padding(.top, 12)
                .padding(.bottom, 9)
                
                SimpleGradientProgressBar(progress: uiState.progress)
                
                // 운동 통계 그리드
                ExerciseMetricsRow(
                    exerciseInfo: uiState.exerciseInfo,
                    metrics: metrics
                )
                
                // 보행 유형 비율
                // 안드로이드: Row with SpaceAround
                HStack(spacing: 0) {
                    Spacer()
                    
                    ActivityRatioItem(
                        activityName: "exercise_walk".localized(),
                        ratio: walkingStats?.ratio ?? 0.0,
                        backgroundColor: ElegaiterColors.Green.green400, // 안드로이드: Green400
                        labelTextColor: .white
                    )
                    
                    Spacer()
                    
                    ActivityRatioItem(
                        activityName: "exercise_run".localized(),
                        ratio: runningStats?.ratio ?? 0.0,
                        backgroundColor: ElegaiterColors.Additional.orange, // 안드로이드: Orange
                        labelTextColor: .white
                    )
                    
                    Spacer()
                    
                    ActivityRatioItem(
                        activityName: "exercise_unknown".localized(),
                        ratio: unknownStats?.ratio ?? 0.0,
                        backgroundColor: ElegaiterColors.Status.warning, // 안드로이드: StatusWarning
                        labelTextColor: ElegaiterColors.Text.main // 안드로이드: TextMain
                    )
                    
                    Spacer()
                }
                .padding(.top, 16)
            }
            .padding(12) // 안드로이드: 외부 padding(12.dp) - 상하좌우 12 여백
            .background(Color.white) // 안드로이드: background(Color.White)
            .clipShape(RoundedRectangle(cornerRadius: 20)) // 안드로이드: clip(RoundedCornerShape(20.dp)) - 라디어스 20
            .padding(.horizontal, 20) // 안드로이드: 내부 padding(horizontal = 20.dp)
            .padding(.top, 16) // 안드로이드: 내부 padding(top = 16.dp)
            .padding(.bottom, 10) // 안드로이드: 내부 padding(bottom = 10.dp)
            
            // 버튼 영역 (안드로이드: 운동 정보 영역 밖에 별도 Row)
            // 안드로이드: padding(top = 10.dp, bottom = 20.dp).padding(horizontal = 20.dp)
            HStack(spacing: 8) {
                // 그래프 초기화 버튼
                // 안드로이드: RoundedCornerShape(32.dp), StrokeWeak, White, Label1
                Button(action: viewModel.onResetExerciseClick) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .medium)) // 안드로이드: size(20.dp)
                            .foregroundColor(
                                uiState.showMedianIqrGraph
                                ? ElegaiterColors.Text.main
                                : ElegaiterColors.Text.disabled
                            )
                        
                        Text("exercise_graph_reset".localized())
                            .typography(ElegaiterTypography.Label1) // 안드로이드: Label1
                            .foregroundColor(
                                uiState.showMedianIqrGraph
                                ? ElegaiterColors.Text.main
                                : ElegaiterColors.Text.disabled
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50) // 안드로이드: contentPadding(vertical = 16.dp)이지만 실제 높이는 50으로 유지
                    .background(Color.white) // 안드로이드: White
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(ElegaiterColors.Stroke.weak, lineWidth: 1) // 안드로이드: StrokeWeak
                    )
                    .cornerRadius(32)
                }
                .disabled(!uiState.showMedianIqrGraph)
                
                // 운동 끝내기 버튼
                // 안드로이드: RoundedCornerShape(32.dp), BackgroundDark, StrokeMedium, Label1
                Button(action: { viewModel.onStopExerciseClick() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20, weight: .medium)) // 안드로이드: size(20.dp)
                            .foregroundColor(.white)
                        
                        Text("exercise_finish".localized())
                            .typography(ElegaiterTypography.Label1) // 안드로이드: Label1
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ElegaiterColors.Background.dark) // 안드로이드: BackgroundDark
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(ElegaiterColors.Stroke.medium, lineWidth: 1) // 안드로이드: StrokeMedium
                    )
                    .cornerRadius(32)
                }
                .disabled(viewModel.uiState.isAwaitingSave)
            }
            .padding(.top, 10) // 안드로이드: padding(top = 10.dp)
            .padding(.bottom, 20) // 안드로이드: padding(bottom = 20.dp)
            .padding(.horizontal, 20) // 안드로이드: padding(horizontal = 20.dp)
        }
    }
    
    // MARK: - Helper Methods
    
    private func stepTypeInfo(for stepType: StepType) -> (Color, String) {
        // 안드로이드 색상과 일치: Green400, Orange, StatusWarning
        switch stepType {
        case .walk:
            return (ElegaiterColors.Green.green400, "exercise_status_walking".localized()) // 안드로이드: Green400
        case .run:
            return (ElegaiterColors.Additional.orange, "exercise_status_running".localized()) // 안드로이드: Orange
        case .unknown, .none:
            return (ElegaiterColors.Status.warning, "exercise_unknown".localized()) // 안드로이드: StatusWarning
        }
    }
}

// MARK: - Graph Control Row

private struct GraphControlRow: View {
    let title: String
    let currentValue: String
    let onIncreaseClick: () -> Void
    let onDecreaseClick: () -> Void
    
    var body: some View {
        // 안드로이드: Row의 horizontalArrangement = Arrangement.spacedBy(8.dp)
        HStack(spacing: 8) {
            GraphButton(
                onClick: onIncreaseClick,
                iconName: "plus"
            )
            
            // 안드로이드: Column(horizontalAlignment = Alignment.CenterHorizontally)
            VStack(spacing: 0) {
                // 안드로이드: Caption3, Neutral500
                Text(title)
                    .typography(ElegaiterTypography.Caption3)
                    .foregroundColor(ElegaiterColors.Neutral.neutral500)
                
                // 안드로이드: Label1, TextMain
                Text(currentValue)
                    .typography(ElegaiterTypography.Label1)
                    .foregroundColor(ElegaiterColors.Text.main)
            }
            
            GraphButton(
                onClick: onDecreaseClick,
                iconName: "minus"
            )
        }
    }
}

// MARK: - Exercise Metrics Row

private struct ExerciseMetricsRow: View {
    let exerciseInfo: ExerciseInfo?
    let metrics: GaitMetrics?
    
    var body: some View {
        let metricItems: [(String, String)] = [
            ("exercise_target_speed".localized(), "\(exerciseInfo?.speed ?? 0)km/h"),
            ("exercise_setup_incline".localized(), "\(exerciseInfo?.incline ?? 0)%"),
            ("exercise_cadence".localized(), "\(metrics?.cadence ?? 0)/m"),
            ("exercise_total_steps".localized(), formatNumber(metrics?.totalSteps ?? 0))
        ]
        
        // 안드로이드: Row with padding(top = 20.dp)
        HStack(spacing: 0) {
            ForEach(Array(metricItems.enumerated()), id: \.offset) { index, item in
                MetricItem(
                    title: item.0,
                    value: item.1
                )
                .frame(maxWidth: .infinity)
                
                if index < metricItems.count - 1 {
                    // 안드로이드: width(1.dp), height(16.dp), StrokeMedium
                    Rectangle()
                        .fill(ElegaiterColors.Stroke.medium) // 안드로이드: StrokeMedium
                        .frame(width: 1, height: 16)
                }
            }
        }
        .padding(.top, 20) // 안드로이드: padding(top = 20.dp)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Metric Item

private struct MetricItem: View {
    let title: String
    let value: String
    
    var body: some View {
        // 안드로이드: Column with padding(vertical = 6.dp), CenterHorizontally
        VStack(spacing: 0) {
            // 안드로이드: Caption3, TextSub1
            Text(title)
                .typography(ElegaiterTypography.Caption3)
                .foregroundColor(ElegaiterColors.Text.sub1) // 안드로이드: TextSub1
            
            // 안드로이드: Label2, TextMain
            Text(value)
                .typography(ElegaiterTypography.Label2) // 안드로이드: Label2
                .foregroundColor(ElegaiterColors.Text.main) // 안드로이드: TextMain
        }
        .padding(.vertical, 6) // 안드로이드: padding(vertical = 6.dp)
    }
}

// MARK: - Activity Ratio Item

private struct ActivityRatioItem: View {
    let activityName: String
    let ratio: Double
    let backgroundColor: Color
    let labelTextColor: Color
    
    var body: some View {
        // 안드로이드: Row with padding(vertical = 7.dp), spacedBy(8.dp)
        HStack(spacing: 8) {
            Text(activityName)
                .typography(ElegaiterTypography.Caption3)
                .foregroundColor(labelTextColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(backgroundColor)
                )
            
            // 안드로이드: Label2, TextMain
            Text(String(format: "%.1f %%", ratio * 100))
                .typography(ElegaiterTypography.Label2) // 안드로이드: Label2
                .foregroundColor(ElegaiterColors.Text.main) // 안드로이드: TextMain
        }
        .padding(.vertical, 7) // 안드로이드: padding(vertical = 7.dp)
    }
}

#Preview {
    let coordinator = AppCoordinator()
    let router = ExerciseRouter(coordinator: coordinator)
    return RealTimeExerciseView(router: router, viewModel: router.sessionViewModel)
}
