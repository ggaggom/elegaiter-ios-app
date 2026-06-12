//
//  HistoryView.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import ElegaiterSDK

/// History 화면
///
/// Android의 `HistoryScreen`을 SwiftUI로 변환
/// - 주간/월간 뷰 전환
/// - 캘린더 및 통계 표시
/// - 최근 운동 목록
struct HistoryView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel: HistoryViewModel
    
    @State private var selectedPeriod: String = "record_weekly".localized()
    // @State private var showDeleteDialog: Bool = false
    
    init(viewModel: HistoryViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: HistoryViewModel())
        }
    }
    
    var body: some View {
        ZStack {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                Text("record_title".localized())
                    .typography(ElegaiterTypography.Headline4)
                    .foregroundColor(ElegaiterColors.Text.main)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8) // status bar 영역 여백
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 월간 성취 요약 (안드로이드: totalExerciseDaysThisMonth > 0일 때만 표시)
                        if viewModel.uiState.totalExerciseDaysThisMonth > 0 {
                            MonthlyAchievementSummary(
                                currentStreak: viewModel.uiState.currentStreak,
                                totalExerciseDaysThisMonth: viewModel.uiState.totalExerciseDaysThisMonth
                            )
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                        }
                        
                        // 주간/월간 토글 버튼 (안드로이드: 전체 높이 53.dp)
                        ToggleButton(
                            options: ["record_weekly".localized(), "record_monthly".localized()],
                            selectedOption: selectedPeriod,
                            onOptionSelected: { newSelection in
                                selectedPeriod = newSelection
                            }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                        
                        // 캘린더
                        CustomToggleCalendar(
                            isWeeklyView: selectedPeriod == "record_weekly".localized(),
                            dailyGoalProgressMap: viewModel.uiState.dailyGoalProgressMap,
                            onVisibleDateRangeChanged: { startDate, endDate in
                                viewModel.loadDailyStepsAndCalculateProgress(startDate: startDate, endDate: endDate)
                                viewModel.loadAggregatedStats(startDate: startDate, endDate: endDate)
                                viewModel.loadDailyElapsedTime(
                                    startDate: startDate,
                                    endDate: endDate,
                                    isWeeklyView: selectedPeriod == "record_weekly".localized()
                                )
                            },
                            onDaySelected: { date in
                                viewModel.loadSessionForSpecificDay(date: date)
                            }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                        
                        // 운동 시간 통계 (안드로이드: StatCard, padding(top = 10.dp, start = 16.dp, end = 16.dp))
                        if !viewModel.uiState.dailyElapsedTimeMap.isEmpty {
                            StatCard(
                                iconName: "IcTime",
                                title: "exercise_time".localized(),
                                value: formatSecondsToHourMin(
                                    selectedPeriod == "record_weekly".localized()
                                    ? viewModel.uiState.weeklyTotalElapsedTime
                                    : viewModel.uiState.monthlyTotalElapsedTime
                                ),
                                contentSpacerHeight: 24
                            ) {
                                ElapsedTimeBarGraph(
                                    weeklyTimes: viewModel.uiState.weeklyElapsedTimes,
                                    monthlyWeeklyTimes: viewModel.uiState.monthlyWeeklyElapsedTimes,
                                    isWeeklyView: selectedPeriod == "record_weekly".localized()
                                )
                            }
                        }
                        
                        // 걸음 통계 (안드로이드: StatCard, padding(top = 10.dp, start = 16.dp, end = 16.dp))
                        if viewModel.uiState.rangeTotalSteps > 0 {
                            StatCard(
                                iconName: "IcStep",
                                title: "record_total_steps".localized(),
                                value: formatNumber(viewModel.uiState.rangeTotalSteps),
                                contentSpacerHeight: 20
                            ) {
                                if let stepTypeStats = viewModel.uiState.rangeStepTypeStats {
                                    StepSummary3(
                                        items: [
                                            StepItem(
                                                label: "exercise_walk".localized(),
                                                percentage: stepTypeStats.walking.ratio,
                                                color: ElegaiterColors.Green.green400
                                            ),
                                            StepItem(
                                                label: "exercise_unknown".localized(),
                                                percentage: stepTypeStats.limping.ratio,
                                                color: ElegaiterColors.Status.warning
                                            ),
                                            StepItem(
                                                label: "exercise_run".localized(),
                                                percentage: stepTypeStats.running.ratio,
                                                color: ElegaiterColors.Additional.orange
                                            )
                                        ]
                                    )
                                }
                            }
                        }
                        
                        // 최근 운동 섹션 (안드로이드: Text만 사용, fillMaxWidth, padding(bottom = 16.dp, top = 60.dp, start = 16.dp))
                        Text("record_recent_exercise".localized())
                            .typography(ElegaiterTypography.Headline5)
                            .foregroundColor(ElegaiterColors.Text.main)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                            .padding(.top, 60)
                            .padding(.bottom, 16)
                        
                        // 기록 목록 (안드로이드: modifier.padding(horizontal = 16.dp).padding(bottom = 120.dp))
                        if viewModel.uiState.isLoading {
                            ProgressView()
                                .padding(.vertical, 40)
                        } else {
                            HistoryList(
                                uiState: viewModel.uiState,
                                onRecordClick: { fileName in
                                    handleRecordClick(fileName: fileName)
                                },
                                navigateToExerciseInfo: {
                                    // Exercise 탭으로 이동하고 ExerciseInfoView로 직접 네비게이션
                                    // exercisePath에 route를 추가하여 네비게이션
                                    coordinator.selectedTab = .exercise
                                    // 탭 전환 후 exercisePath에 route 추가 (ExerciseReadyView의 운동 시작하기 버튼과 동일하게 동작)
                                    DispatchQueue.main.async {
                                        coordinator.exerciseRouter.navigate(to: .info)
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 120)
                        }
                    }
                }
            }
            .background(Color.white) // NavigationStack 배경색 명시
        }
        .onAppear {
            viewModel.coordinator = coordinator
            // 화면이 나타날 때마다 최근 운동 목록 갱신
            viewModel.loadRecords()
        }
        .onChange(of: coordinator.selectedTab) { newTab in
            // 기록 탭이 선택되고 historyPath가 비어있을 때(HistoryView가 루트일 때) 기록 새로고침
            // 탭 전환 시 기록 목록이 갱신되도록 함 (운동 결과 저장 후 기록 탭으로 이동할 때)
            if newTab == .history && coordinator.historyPath.isEmpty {
                viewModel.loadRecords()
            }
        }
        .onChange(of: coordinator.historyPath) { newPath in
            // historyPath가 비어있으면 HistoryView로 돌아온 것
            // DailySessionView에서 back으로 돌아올 때 navigateToDailySession 초기화
            // 이렇게 하면 동일한 날짜를 다시 터치할 수 있음
            if newPath.isEmpty {
                viewModel.navigateToDailySession = nil
                // HistoryView로 돌아올 때도 기록 새로고침
                viewModel.loadRecords()
            }
        }
        .onChange(of: viewModel.navigateToDailySession) { sessions in
            if let sessions = sessions, let selectedDate = viewModel.uiState.selectedDate {
                coordinator.historyRouter.navigate(to: .dailySession(selectedDate: selectedDate))
                // 네비게이션 후 nil로 리셋하여 동일한 날짜를 다시 터치할 수 있도록 함
                DispatchQueue.main.async {
                    viewModel.navigateToDailySession = nil
                }
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
        /*
         .alert("운동 기록 삭제", isPresented: $showDeleteDialog) {
         Button("취소", role: .cancel) {
         showDeleteDialog = false
         }
         Button("삭제", role: .destructive) {
         Task {
         await viewModel.deleteSelectedRecords()
         showDeleteDialog = false
         }
         }
         } message: {
         Text("운동 기록을 정말 삭제하시겠습니까?")
         }
         */
    }
    
    // MARK: - Private Methods
    
    /// 기록 클릭 처리
    private func handleRecordClick(fileName: String) {
        Task { @MainActor in
            guard let metrics = await viewModel.getRecordDetails(fileName: fileName) else {
                // 보행 분석 결과를 불러올 수 없을 때 토스트 표시
                ToastManager.shared.show(message: "record_error_get_analysis".localized())
                return
            }
            
            guard let recordDto = await viewModel.getRecordMetaData(fileName: fileName) else {
                // 보행 분석 결과를 불러올 수 없을 때 토스트 표시
                ToastManager.shared.show(message: "record_error_get_analysis".localized())
                return
            }
            
            // ExerciseResult로 이동하기 전의 탭 저장 (뒤로가기 시 History로 돌아가기 위해)
            coordinator.exerciseResultSourceTab = .history
            
            // Exercise 탭으로 전환
            coordinator.selectedTab = .exercise
            
            // ExerciseResult 화면으로 이동
            coordinator.exerciseRouter.navigateToResult(metrics: metrics, record: recordDto)
        }
    }
    
    /// 초를 시간:분 형식으로 변환
    private func formatSecondsToHourMin(_ seconds: Int64) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)" + "history_hour".localized() + " \(minutes)" + "exercise_minutes_unit".localized()
        } else {
            return "\(minutes)" + "exercise_minutes_unit".localized()
        }
    }
    
    /// 숫자를 천 단위 구분자로 포맷팅
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Stat Card

/// 통계 카드 컴포넌트 (안드로이드: WhiteGrayCard, padding(vertical = 16.dp, horizontal = 12.dp))
private struct StatCard<Content: View>: View {
    let iconName: String
    let title: String
    let value: String
    let contentSpacerHeight: CGFloat
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        WhiteGrayCard {
            VStack(alignment: .leading, spacing: 0) {
                // 안드로이드: Row(horizontalArrangement = spacedBy(10.dp), verticalAlignment = CenterVertically)
                HStack(alignment: .center, spacing: 10) {
                    // 아이콘 (안드로이드: Box(size = 44.dp), Icon(size = 24.dp), BackgroundLight, cornerRadius = 12.dp)
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ElegaiterColors.Background.light)
                            .frame(width: 44, height: 44)
                        
                        Image(iconName)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    
                    // 제목 및 값 (안드로이드: Column, spacing = 4.dp)
                    VStack(alignment: .leading, spacing: 4) {
                        // 제목 (안드로이드: Caption3, TextSub1)
                        Text(title)
                            .typography(ElegaiterTypography.Caption3)
                            .foregroundColor(ElegaiterColors.Text.sub1)
                        
                        // 값 (안드로이드: Headline4, TextMain)
                        Text(value)
                            .typography(ElegaiterTypography.Headline4)
                            .foregroundColor(ElegaiterColors.Text.main)
                    }
                    
                    Spacer()
                }
                
                // 콘텐츠 간격 (안드로이드: Spacer(height = contentSpacerHeight))
                Spacer()
                    .frame(height: contentSpacerHeight)
                
                content()
            }
            // 안드로이드: padding(vertical = 16.dp, horizontal = 12.dp)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
        }
        // 안드로이드: modifier.padding(top = 10.dp, start = 16.dp, end = 16.dp)
        .padding(.top, 10)
        .padding(.horizontal, 16)
    }
}

// MARK: - History List

/// 기록 목록 컴포넌트
private struct HistoryList: View {
    let uiState: HistoryUiState
    let onRecordClick: (String) -> Void
    let navigateToExerciseInfo: () -> Void
    
    var body: some View {
        if uiState.records.isEmpty {
            // 기록이 없을 때 (안드로이드: WhiteGrayCard, modifier.padding(top = 4.dp))
            WhiteGrayCard {
                VStack(spacing: 0) {
                    Text("record_no_recent_exercise".localized())
                        .typography(ElegaiterTypography.Body3)
                        .foregroundColor(ElegaiterColors.Text.sub2)
                        .padding(.bottom, 15)
                    
                    PrimaryButton(
                        onClick: navigateToExerciseInfo,
                        height: 45
                    ) {
                        Text("record_to_go_exercise".localized())
                            .typography(ElegaiterTypography.Label3)
                            .foregroundColor(ElegaiterColors.Text.main)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 4)
            
        } else {
            // 기록 목록 (안드로이드: Column, Spacer(height = 8.dp) between items)
            VStack(spacing: 8) {
                ForEach(Array(uiState.records.enumerated()), id: \.element.fileName) { index, record in
                    HistoryListItem(
                        record: record,
                        onRecordClick: {
                            onRecordClick(record.fileName)
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppCoordinator())
}
