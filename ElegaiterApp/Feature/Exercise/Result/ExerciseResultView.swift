//
//  ExerciseResultView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Charts
import Combine
import UIKit
import ElegaiterSDK

struct ExerciseResultView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    let fileName: String?
    let metrics: GaitMetrics?
    let record: GaitRecordDto?
    
    @StateObject private var viewModel: ExerciseResultViewModel
    @State private var selectedGraphType: String = "exercise_graph_overlay_view".localized()
    
    /// fileName으로 초기화 (데이터 로드 필요)
    init(fileName: String, coordinator: AppCoordinator? = nil) {
        self.fileName = fileName
        self.metrics = nil
        self.record = nil
        self._viewModel = StateObject(wrappedValue: ExerciseResultViewModel(fileName: fileName, coordinator: coordinator))
    }
    
    /// metrics와 record로 직접 초기화 (데이터 로드 불필요)
    init(metrics: GaitMetrics, record: GaitRecordDto, coordinator: AppCoordinator? = nil) {
        self.fileName = nil
        self.metrics = metrics
        self.record = record
        self._viewModel = StateObject(wrappedValue: ExerciseResultViewModel(metrics: metrics, record: record, coordinator: coordinator))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("exercise_result_loading".localized())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 20) {
                    Text("exercise_result_error".localized())
                        .font(.headline)
                    Text(errorMessage)
                        .foregroundColor(.red)
                    Button("exercise_result_back".localized()) {
                        viewModel.navigateBack()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let metrics = viewModel.metrics, let record = viewModel.record {
                contentView(metrics: metrics, record: record)
            } else {
                Text("exercise_result_data_not_found".localized())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true) // 기본 back 버튼 숨김 (커스텀 back 버튼 사용)
        .onAppear {
            viewModel.coordinator = coordinator
            // TabBar 표시/숨김은 AppNavigation의 onChange에서 경로 기반으로 자동 처리
        }
        .onReceive(viewModel.eventSubject) { event in
            handleEvent(event)
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    @ViewBuilder
    private func contentView(metrics: GaitMetrics, record: GaitRecordDto) -> some View {
        ZStack {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterHeader(
                    title: "exercise_result_title".localized(),
                    onBackClick: {
                        viewModel.navigateBack()
                    },
                    showBackIcon: viewModel.showDeleteButton,
                    actions: {
                        AnyView(trailingActionButton)
                    }
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 날짜 및 컨텐츠 영역 (안드로이드: Column with padding(vertical = 20.dp, horizontal = 16.dp))
                        VStack(spacing: 0) {
                            // 날짜 표시
                            dateSection(record: record)
                            
                            // 운동 시간 및 목표 달성률
                            exerciseTimeSection(record: record)
                            
                            // 보행 유형 통계
                            stepTypeStatsSection(metrics: metrics)
                            
                            // 운동 정보 그리드
                            exerciseInfoGridSection(metrics: metrics, record: record)
                            
                            // 좌우 강도 분석 그래프
                            intensityGraphSection(metrics: metrics)
                            
                            // 스텝 시간 분석
                            stepDurationSection(metrics: metrics)
                            
                            // 보폭 시간 분석
                            strideDurationSection(metrics: metrics)
                            
                            // 웹 리포트 확인
                            webReportLinkSection
                            
                            // 하단 여백
                            Spacer()
                                .frame(height: 40)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.white) // NavigationStack 배경색 명시
            
            // 삭제 다이얼로그
            if viewModel.showDeleteDialog {
                StyledAlertDialog(
                    isPresented: Binding(
                        get: { viewModel.showDeleteDialog },
                        set: { if !$0 { viewModel.dismissDeleteDialog() } }
                    ),
                    title: "exercise_record_delete_title".localized(),
                    message: "exercise_record_delete_message".localized(),
                    content: {
                        EmptyView()
                    },
                    confirmText: "exercise_record_delete_confirm".localized(),
                    onConfirm: {
                        viewModel.deleteRecord()
                    },
                    dismissText: "btn_cancel".localized(),
                    onDismiss: {
                        viewModel.dismissDeleteDialog()
                    }
                )
            }
        }
    }
    
    // MARK: - Trailing Action Button
    
    /// 우측 액션 버튼 (닫기 또는 삭제)
    private var trailingActionButton: some View {
        Group {
            if viewModel.showDeleteButton {
                // 삭제 버튼
                Button(action: {
                    viewModel.presentDeleteDialog()
                }) {
                    Image("IcDelete")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(ElegaiterColors.Text.main)
                        .frame(width: 24, height: 24)
                }
                .padding(.trailing, 12)
            } else {
                // 닫기 버튼
                Button(action: {
                    viewModel.navigateBack()
                }) {
                    Image("IcClose")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(ElegaiterColors.Text.main)
                        .frame(width: 24, height: 24)
                }
                .padding(.trailing, 12)
            }
        }
    }
    
    // MARK: - Date Section
    
    @ViewBuilder
    private func dateSection(record: GaitRecordDto) -> some View {
        if let date = parseDate(from: record.date) {
            Text(formatDate(date))
                .typography(ElegaiterTypography.Headline5)
                .foregroundColor(ElegaiterColors.Text.main)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            EmptyView()
        }
    }
    
    private func parseDate(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        
        // 먼저 "yyyy-MM-dd HH:mm:ss" 형식 시도 (저장 시점의 시간 정보 포함)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        // "yyyy-MM-dd" 형식 시도 (날짜만 있는 경우)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        // 둘 다 실패하면 nil 반환
        return nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy.MM.dd (E)"
        // 현재 언어에 따라 로케일 설정
        let currentLanguage = LanguageManager.shared.currentLanguage
        displayFormatter.locale = Locale(identifier: currentLanguage == "ko" ? "ko_KR" : "en_US")
        return displayFormatter.string(from: date)
    }
    
    // MARK: - Exercise Time Section
    
    @ViewBuilder
    private func exerciseTimeSection(record: GaitRecordDto) -> some View {
        let elapsedTime = record.elapsedTime
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        
        let targetDurationMin = record.exerciseInfo.duration
        let targetDurationSec = targetDurationMin * 60
        
        // 목표 대비 실제 진행률 계산
        let progress: Float = targetDurationSec > 0
        ? min(Float(elapsedTime) / Float(targetDurationSec), 1.0)
        : 0.0
        let progressPercent = Int(progress * 100)
        
        // 안드로이드: BackgroundLightCard(topPadding = 20.dp, internalVerticalPadding = 15.dp)
        // 카드 높이: 84
        BackgroundLightCard {
            HStack(alignment: .center, spacing: 0) {
                // 왼쪽: 운동 시간 정보 (안드로이드: Column)
                VStack(alignment: .leading, spacing: 0) {
                    // "운동 시간" 텍스트 (안드로이드: Caption3, TextSub1)
                    Text("exercise_time".localized())
                        .typography(ElegaiterTypography.Caption3)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                    
                    // 시간 값들 (안드로이드: Row)
                    HStack(alignment: .bottom, spacing: 0) {
                        if minutes > 0 {
                            timeValueView(number: minutes, unit: "exercise_minutes_unit".localized())
                        }
                        timeValueView(number: seconds, unit: "exercise_seconds_unit".localized())
                    }
                }
                
                Spacer()
                
                // 오른쪽: 반원형 프로그레스 바와 퍼센트 (안드로이드: Box)
                ZStack(alignment: .bottom) {
                    // SemiCircularProgressBar (안드로이드: width = 100.dp, height = 60.dp, strokeWidth = 8.dp, solidBrush = #00000099)
                    SemiCircularProgressBar(
                        progress: progress,
                        strokeWidth: 8,
                        backgroundColor: Color(red: 0, green: 0, blue: 0, opacity: 0.6) // #00000099 (153/255 = 0.6)
                    )
                    .frame(width: 100, height: 60)
                    
                    // 퍼센트 텍스트 (안드로이드: Headline6, TextMain, align(BottomCenter))
                    Text("\(progressPercent)%")
                        .typography(ElegaiterTypography.Headline6)
                        .foregroundColor(ElegaiterColors.Text.main)
                        .offset(y: -8) // 위치를 위로 조정
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 84) // 카드 높이 고정
        .padding(.top, 20)
        .padding(.bottom, 8)
        
    }
    
    @ViewBuilder
    private func timeValueView(number: Int, unit: String) -> some View {
        // 안드로이드: TimeValue - Headline2 (숫자), Caption3 (단위), TextSub1
        HStack(alignment: .bottom, spacing: 0) {
            Text("\(number)")
                .typography(ElegaiterTypography.Headline2)
                .foregroundColor(ElegaiterColors.Text.main)
            Text(unit)
                .typography(ElegaiterTypography.Caption3)
                .foregroundColor(ElegaiterColors.Text.sub1)
                .padding(.trailing, 6)
        }
    }
    
    // MARK: - Step Type Stats Section
    
    @ViewBuilder
    private func stepTypeStatsSection(metrics: GaitMetrics) -> some View {
        let stepTypeStats = metrics.stepTypeStats
        let walkingStats = stepTypeStats.walking
        let runningStats = stepTypeStats.running
        let unknownStats = stepTypeStats.limping
        
        // 안드로이드: BackgroundLightCard(topPadding = 8.dp)
        BackgroundLightCard {
            StepSummary2(
                totalSteps: metrics.totalSteps,
                items: [
                    StepItem(
                        label: "exercise_walk".localized(),
                        percentage: walkingStats.ratio,
                        color: ElegaiterColors.Green.green400,
                        steps: formatSteps(walkingStats.count),
                        duration: formatDurationS(walkingStats.totalDurationS)
                    ),
                    StepItem(
                        label: "exercise_unknown".localized(),
                        percentage: unknownStats.ratio,
                        color: ElegaiterColors.Status.warning,
                        steps: formatSteps(unknownStats.count),
                        duration: formatDurationS(unknownStats.totalDurationS)
                    ),
                    StepItem(
                        label: "exercise_run".localized(),
                        percentage: runningStats.ratio,
                        color: ElegaiterColors.Additional.orange,
                        steps: formatSteps(runningStats.count),
                        duration: formatDurationS(runningStats.totalDurationS)
                    )
                ]
            )
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions
    
    /// 걸음 수를 포맷팅 (안드로이드: NumberFormat.getNumberInstance().format())
    private func formatSteps(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedCount = formatter.string(from: NSNumber(value: count)) ?? "\(count)"
        return "\(formattedCount) " + "exercise_steps".localized()
    }
    
    /// 초를 "X분 X초" 형식으로 변환 (안드로이드: formatDurationMs)
    private func formatDurationS(_ durationS: Double) -> String {
        let totalSeconds = Int(durationS)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        var result = ""
        if minutes > 0 {
            result += "\(minutes)" + "exercise_minutes_unit".localized() + " "
        }
        result += "\(seconds)" + "exercise_seconds_unit".localized()
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Exercise Info Grid Section
    
    @ViewBuilder
    private func exerciseInfoGridSection(metrics: GaitMetrics, record: GaitRecordDto) -> some View {
        let footIntensityStats = metrics.footIntensity
        let leftMedian = footIntensityStats.left.median
        let rightMedian = footIntensityStats.right.median
        
        let total = leftMedian + rightMedian
        let leftPercent = total > 0 ? Int((leftMedian / total) * 100) : 0
        let rightPercent = total > 0 ? Int((rightMedian / total) * 100) : 0
        
        // 컨디션 데이터 (안드로이드: IcMoodGood, IcMoodSoso, IcMoodTired)
        let moodData: (String, String) = {
            switch record.exerciseInfo.mood {
            case "GOOD":
                return ("exercise_condition_good".localized(), "IcMoodGood")
            case "SOSO":
                return ("exercise_condition_soso".localized(), "IcMoodSoso")
            case "TIRED":
                return ("exercise_condition_tired".localized(), "IcMoodTired")
            default:
                return ("exercise_condition_good".localized(), "IcMoodGood")
            }
        }()
        
        StepCardGrid(
            items: [
                ("exercise_left_intensity".localized(), "\(leftPercent)%", "IcFootLeft"),
                ("exercise_right_intensity".localized(), "\(rightPercent)%", "IcFootRight"),
                ("exercise_condition".localized(), moodData.0, moodData.1),
                ("exercise_cadence".localized(), "\(metrics.cadence)/m", "IcWalking")
            ]
        )
        .padding(.top, 8) // 안드로이드: padding(top = 8.dp)
    }
    
    // MARK: - Intensity Graph Section
    
    @ViewBuilder
    private func intensityGraphSection(metrics: GaitMetrics) -> some View {
        // 안드로이드: 타이틀 (Headline5, TextMain, padding(top = 60.dp))
        Text("exercise_left_right_intensity_analysis".localized())
            .typography(ElegaiterTypography.Headline5)
            .foregroundColor(ElegaiterColors.Text.main)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 60)
        
        // 안드로이드: WhiteGrayCard with padding(top = 20.dp)
        WhiteGrayCard {
            // 안드로이드: Column with padding(vertical = 16.dp, horizontal = 12.dp)
            VStack(spacing: 0) {
                // 안드로이드: ToggleButton with padding(horizontal = 4.dp).height(45.dp), backgroundRadius = 24.dp, boxRadius = 20.dp
                ToggleButton(
                    options: ["exercise_graph_overlay_view".localized(), "exercise_graph_split_view".localized()],
                    selectedOption: selectedGraphType,
                    onOptionSelected: { selectedString in
                        selectedGraphType = selectedString
                    },
                    backgroundRadius: 24,
                    boxRadius: 20
                )
                .frame(height: 45)
                .padding(.horizontal, 4)
                
                // 안드로이드: DataKeyItem Row with padding(top = 4.dp, bottom = 16.dp)
                HStack(alignment: .center) {
                    DataKeyItem(
                        label: "exercise_left_foot".localized(),
                        color: ElegaiterColors.Green.green500
                    )
                    .frame(maxWidth: .infinity)
                    
                    DataKeyItem(
                        label: "exercise_right_foot".localized(),
                        color: ElegaiterColors.Status.error
                    )
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 29)
                .padding(.top, 4)
                .padding(.bottom, 16)
                
                // 그래프 영역
                if selectedGraphType == "exercise_graph_overlay_view".localized() {
                    // 안드로이드와 동일하게 한 번에 모든 값 계산
                    let leftStats = getMaxDataAndIndexWithIqr(
                        medianData: metrics.leftMedianData,
                        iqrData: metrics.leftIqrData.isEmpty ? [] : metrics.leftIqrData
                    )
                    let rightStats = getMaxDataAndIndexWithIqr(
                        medianData: metrics.rightMedianData,
                        iqrData: metrics.rightIqrData.isEmpty ? [] : metrics.rightIqrData
                    )
                    
                    // 안드로이드: FixedDataLineGraphV2
                    // 왼발과 오른발을 하나의 그래프에 겹쳐서 표시
                    GaitDataGraphOverlayWithCharts(
                        leftMedianData: metrics.leftMedianData,
                        leftIqrData: metrics.leftIqrData.isEmpty ? nil : metrics.leftIqrData,
                        rightMedianData: metrics.rightMedianData,
                        rightIqrData: metrics.rightIqrData.isEmpty ? nil : metrics.rightIqrData,
                        leftColor: ElegaiterColors.Green.green500,
                        rightColor: ElegaiterColors.Status.error
                    )
                    .frame(height: 150)
                    
                    // 안드로이드: 통계 정보 Column with padding(top = 16.dp)
                    HStack(alignment: .top, spacing: 0) {
                        // 첫 번째 열: 레이블 (왼쪽 정렬)
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                                .frame(height: 4) // 헤더 행과의 간격
                            (Text("exercise_median_label".localized() + " ") + Text("exercise_max_label".localized())
                                .foregroundColor(ElegaiterColors.Text.sub1))
                            .typography(ElegaiterTypography.Caption3)
                            .foregroundColor(ElegaiterColors.Text.main)
                            Text("exercise_iqr_label".localized())
                                .typography(ElegaiterTypography.Caption3)
                                .foregroundColor(ElegaiterColors.Text.main)
                        }
                        .frame(width: 75, alignment: .leading)
                        
                        // 두 번째 열: 왼발 (중앙 정렬)
                        VStack(alignment: .center, spacing: 0) {
                            Text("exercise_left_foot".localized())
                                .typography(ElegaiterTypography.Caption3)
                                .foregroundColor(ElegaiterColors.Text.main)
                                .padding(.bottom, 4)
                            
                            if let leftMaxVal = leftStats.maxValue {
                                Text("\(leftMaxVal)")
                                    .typography(ElegaiterTypography.Label2)
                                    .foregroundColor(ElegaiterColors.Green.green500)
                            }
                            
                            if let leftIqrVal = leftStats.iqrValue {
                                Text("\(leftIqrVal)")
                                    .typography(ElegaiterTypography.Label2)
                                    .foregroundColor(ElegaiterColors.Green.green500)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // 세 번째 열: 오른발 (중앙 정렬)
                        VStack(alignment: .center, spacing: 0) {
                            Text("exercise_right_foot".localized())
                                .typography(ElegaiterTypography.Caption3)
                                .foregroundColor(ElegaiterColors.Text.main)
                                .padding(.bottom, 4)
                            
                            if let rightMaxVal = rightStats.maxValue {
                                Text("\(rightMaxVal)")
                                    .typography(ElegaiterTypography.Label2)
                                    .foregroundColor(ElegaiterColors.Status.error)
                            }
                            
                            if let rightIqrVal = rightStats.iqrValue {
                                Text("\(rightIqrVal)")
                                    .typography(ElegaiterTypography.Label2)
                                    .foregroundColor(ElegaiterColors.Status.error)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 16)
                } else {
                    // 나눠 보기 모드 (안드로이드의 GaitGraphAndStatsItem과 동일한 구조)
                    // 안드로이드와 동일하게 한 번에 모든 값 계산
                    let leftStats = getMaxDataAndIndexWithIqr(
                        medianData: metrics.leftMedianData,
                        iqrData: metrics.leftIqrData.isEmpty ? [] : metrics.leftIqrData
                    )
                    let rightStats = getMaxDataAndIndexWithIqr(
                        medianData: metrics.rightMedianData,
                        iqrData: metrics.rightIqrData.isEmpty ? [] : metrics.rightIqrData
                    )
                    
                    HStack(spacing: 0) {
                        // 왼발 그래프 및 통계
                        gaitGraphAndStatsItem(
                            medianData: metrics.leftMedianData,
                            anotherMedianData: metrics.rightMedianData,
                            iqrData: metrics.leftIqrData.isEmpty ? nil : metrics.leftIqrData,
                            graphColor: ElegaiterColors.Green.green500,
                            maxMedianVal: leftStats.maxValue,
                            iqrValAtMaxIndex: leftStats.iqrValue
                        )
                        .frame(maxWidth: .infinity)
                        
                        // 오른발 그래프 및 통계
                        gaitGraphAndStatsItem(
                            medianData: metrics.rightMedianData,
                            anotherMedianData: metrics.leftMedianData,
                            iqrData: metrics.rightIqrData.isEmpty ? nil : metrics.rightIqrData,
                            graphColor: ElegaiterColors.Status.error,
                            maxMedianVal: rightStats.maxValue,
                            iqrValAtMaxIndex: rightStats.iqrValue
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Step Duration Section
    
    @ViewBuilder
    private func stepDurationSection(metrics: GaitMetrics) -> some View {
        let stepDurationStats = metrics.stepDuration
        
        // 안드로이드: Text (Headline5, TextMain, padding(top = 60.dp))
        Text("exercise_step_time_analysis".localized())
            .typography(ElegaiterTypography.Headline5)
            .foregroundColor(ElegaiterColors.Text.main)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 60)
        
        // 안드로이드: Row (fillMaxWidth, padding(top = 20.dp), horizontalArrangement = spacedBy(8.dp))
        HStack(spacing: 8) {
            // 좌 → 우 (오른발로 가는 스텝)
            StepTimeCard(
                title: "exercise_left_to_right".localized(),
                value1: String(format: "%.1f", stepDurationStats.right.medianS),
                value2: String(format: "%.1f", stepDurationStats.right.iqrS)
            )
            .frame(maxWidth: .infinity)
            
            // 우 → 좌 (왼발로 가는 스텝)
            StepTimeCard(
                title: "exercise_right_to_left".localized(),
                value1: String(format: "%.1f", stepDurationStats.left.medianS),
                value2: String(format: "%.1f", stepDurationStats.left.iqrS)
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Stride Duration Section
    
    @ViewBuilder
    private func strideDurationSection(metrics: GaitMetrics) -> some View {
        let strideDurationStats = metrics.strideDuration
        
        // 안드로이드: Text (Headline5, TextMain, padding(top = 60.dp))
        Text("exercise_stride_time_analysis".localized())
            .typography(ElegaiterTypography.Headline5)
            .foregroundColor(ElegaiterColors.Text.main)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 60)
        
        // 안드로이드: Row (fillMaxWidth, padding(top = 20.dp), horizontalArrangement = spacedBy(8.dp))
        HStack(spacing: 8) {
            // 좌 → 좌 (왼발에서 왼발로 가는 활보)
            StepTimeCard(
                title: "exercise_left_to_left".localized(),
                value1: String(format: "%.1f", strideDurationStats.left.medianS),
                value2: String(format: "%.1f", strideDurationStats.left.iqrS)
            )
            .frame(maxWidth: .infinity)
            
            // 우 → 우 (오른발에서 오른발로 가는 활보)
            StepTimeCard(
                title: "exercise_right_to_right".localized(),
                value1: String(format: "%.1f", strideDurationStats.right.medianS),
                value2: String(format: "%.1f", strideDurationStats.right.iqrS)
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Web Report Link Section
    
    @ViewBuilder
    private var webReportLinkSection: some View {
        BackgroundLightCard {
            HStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "info.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(ElegaiterColors.Green.green500)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("exercise_report_detail_title".localized())
                            .typography(ElegaiterTypography.Label1)
                            .foregroundColor(ElegaiterColors.Text.main)
                        
                        Text("exercise_report_detail_desc".localized())
                            .typography(ElegaiterTypography.Caption3)
                            .foregroundColor(ElegaiterColors.Text.sub1)
                    }
                }
                
                Spacer()
                
                Image("IcArrowRight")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.openWebReport()
            }
        }
        .opacity(viewModel.isWebReportLoading ? 0.6 : 1.0)
        .disabled(viewModel.isWebReportLoading)
        .padding(.top, 20)
    }
    
    // MARK: - Event Handling
    
    /// 이벤트 처리
    private func handleEvent(_ event: ExerciseResultEvent) {
        switch event {
        case .deleteSuccess:
            // 운동 기록이 삭제되었습니다.
            ToastManager.shared.show(message: "exercise_record_delete_success".localized())
            
        case .showDeleteFailedToast:
            // 운동 기록 삭제에 실패했습니다.
            ToastManager.shared.show(message: "exercise_record_delete_fail".localized())
            
        case .openWebReport(let urlString):
            guard let url = URL(string: urlString) else { return }
            UIApplication.shared.open(url)
            
        case .showWebReportError(let error):
            let message: String
            if error as? GaitException == .notSynced {
                message = "exercise_report_no_synced".localized()
            } else if !viewModel.isOnline {
                message = "exercise_report_no_online".localized()
            } else {
                message = "exercise_report_error".localized()
            }
            ToastManager.shared.show(message: message)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 안드로이드의 DataKeyItem과 동일한 구조
    @ViewBuilder
    private func DataKeyItem(label: String, color: Color) -> some View {
        HStack(alignment: .center, spacing: 0) {
            // 안드로이드: Box (width = 24.dp, height = 2.dp) with color background
            Rectangle()
                .fill(color)
                .frame(width: 24, height: 2)
            
            // 안드로이드: Text (Caption3, TextSub2) with padding(start = 8.dp)
            Text(label)
                .typography(ElegaiterTypography.Caption3)
                .foregroundColor(ElegaiterColors.Text.sub2)
                .padding(.leading, 8)
        }
        .padding(.vertical, 6)
    }
    
    /// 안드로이드의 GaitGraphAndStatsItem과 동일한 구조의 그래프 및 통계 아이템
    @ViewBuilder
    private func gaitGraphAndStatsItem(
        medianData: [Float],
        anotherMedianData: [Float],
        iqrData: [Float]?,
        graphColor: Color,
        maxMedianVal: Int?,
        iqrValAtMaxIndex: Int?
    ) -> some View {
        // 안드로이드: GaitGraphAndStatsItem은 BackgroundLightCard 없이 직접 구현
        VStack(spacing: 0) {
            // 그래프
            GaitDataGraphWithCharts(
                rawData: medianData,
                optionalRawData: iqrData,
                anotherData: anotherMedianData,
                lineColor: graphColor,
                optionalColor: graphColor
            )
            .frame(height: 150)
            
            // 안드로이드: Spacer(height = 14.dp)
            Spacer()
                .frame(height: 14)
            
            // 통계 정보 (안드로이드와 동일한 레이아웃)
            VStack(spacing: 0) {
                // Median (max) - 안드로이드: padding(horizontal = 4.dp, vertical = 1.dp)
                HStack {
                    (Text("exercise_median_label".localized() + " ") + Text("exercise_max_label".localized())
                        .foregroundColor(ElegaiterColors.Text.sub1))
                    .typography(ElegaiterTypography.Caption3)
                    .foregroundColor(ElegaiterColors.Text.main)
                    Spacer()
                    if let maxVal = maxMedianVal {
                        Text("\(maxVal)")
                            .typography(ElegaiterTypography.Caption1)
                            .foregroundColor(graphColor)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                
                // IQR - 안드로이드: padding(top = 4.dp, horizontal = 4.dp, vertical = 1.dp)
                HStack {
                    Text("exercise_iqr_label".localized())
                        .typography(ElegaiterTypography.Caption3)
                        .foregroundColor(ElegaiterColors.Text.main)
                    Spacer()
                    if let iqrVal = iqrValAtMaxIndex {
                        Text("\(iqrVal)")
                            .typography(ElegaiterTypography.Caption1)
                            .foregroundColor(graphColor)
                    }
                }
                .padding(.top, 4)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 6) // 안드로이드: modifier.padding(horizontal = 6.dp)
    }
    
    /// 최대 Median 값, 인덱스, 그리고 해당 인덱스의 IQR 값을 계산
    /// 안드로이드의 `getMaxDataAndIndexWithIqr`와 동일한 로직
    private func getMaxDataAndIndexWithIqr(medianData: [Float], iqrData: [Float]) -> (maxValue: Int?, maxIndex: Int?, iqrValue: Int?) {
        guard !medianData.isEmpty else {
            return (nil, nil, nil)
        }
        
        // median에서의 최대값
        guard let maxValue = medianData.max() else {
            return (nil, nil, nil)
        }
        
        // 최대값이 있다면, 그 값의 인덱스를 찾음 (첫 번째 최대값)
        guard let maxIndex = medianData.firstIndex(of: maxValue) else {
            return (nil, nil, nil)
        }
        
        // 해당 인덱스에서의 IQR 값
        let iqrValue: Int?
        if maxIndex < iqrData.count {
            iqrValue = Int(iqrData[maxIndex].rounded())
        } else {
            iqrValue = nil
        }
        
        return (Int(maxValue.rounded()), maxIndex, iqrValue)
    }
    
    /// 최대 Median 값 계산 (기존 호환성 유지)
    private func getMaxMedianValue(_ medianData: [Float]) -> Int? {
        guard !medianData.isEmpty else { return nil }
        let maxValue = medianData.max() ?? 0.0
        return Int(maxValue.rounded())
    }
    
    /// 최대 Median 인덱스에서의 IQR 값 계산 (기존 호환성 유지)
    private func getIqrAtMaxIndex(medianData: [Float], iqrData: [Float]) -> Int? {
        return getMaxDataAndIndexWithIqr(medianData: medianData, iqrData: iqrData).iqrValue
    }
    
}

#Preview {
    ExerciseResultView(fileName: "test_preview_file")
        .environmentObject(AppCoordinator())
}
