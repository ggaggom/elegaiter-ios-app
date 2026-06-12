//
//  ExerciseReadyView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

struct ExerciseReadyView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = ExerciseReadyViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - background/light
            ElegaiterColors.Background.light
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 영역 (사용자 인사말)
                Text(String(format: "exercise_ready_greeting".localized(), viewModel.uiState.userName))
                    .typography(ElegaiterTypography.Headline5)
                    .foregroundColor(ElegaiterColors.Text.main)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ElegaiterColors.Background.light)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 최근 7일 캘린더 및 주간 요약 카드
                        scrollableHeaderSection
                        
                        // 메인 콘텐츠 영역 (카드가 나타날 때 부드럽게 아래로 이동)
                        mainContentSection
                            .animation(.easeInOut(duration: 0.3), value: viewModel.uiState.weeklyTotalSteps)
                    }
                }
            }
            .background(ElegaiterColors.Background.light)
        }
        .onAppear {
            viewModel.coordinator = coordinator
            // TabBar 표시/숨김은 AppNavigation의 onChange에서 경로 기반으로 자동 처리
        }
        .onChange(of: coordinator.shouldRefreshExerciseReady) { shouldRefresh in
            if shouldRefresh {
                viewModel.loadHasTodayRecord()
                viewModel.loadWeeklyStats()
                viewModel.loadStreakProgress()
                coordinator.shouldRefreshExerciseReady = false
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    // MARK: - Scrollable Header Section
    
    private var scrollableHeaderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 최근 7일 캘린더 (안드로이드와 동일: horizontal = 16.dp)
            RecentWeekCalendar(
                weeklyRecordExistence: viewModel.uiState.weeklyRecordExistence
            )
            .padding(.horizontal, 16)
            
            // 주간 요약 카드 (페이드 인 애니메이션 적용)
            if viewModel.uiState.weeklyTotalSteps > 0 {
                WeeklySummaryCard(
                    weeklyTotalSteps: viewModel.uiState.weeklyTotalSteps,
                    weeklyStepTypeStats: viewModel.uiState.weeklyStepTypeStats
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.3), value: viewModel.uiState.weeklyTotalSteps)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Main Content Section
    
    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 흰색 배경 영역
            VStack(alignment: .leading, spacing: 0) {
                // 오늘의 기록 제목
                Text("exercise_ready_today_record".localized())
                    .typography(ElegaiterTypography.Headline5)
                    .foregroundColor(.primary)
                    .padding(.top, 32)
                
                if viewModel.uiState.hasTodayRecord {
                    // 오늘 기록이 있는 경우
                    todayRecordContent
                } else {
                    // 오늘 기록이 없는 경우
                    noRecordContent
                }
            }
            .padding(.horizontal, 20)
            .background(Color(.systemBackground))
            .cornerRadius(40)
        }
    }
    
    // MARK: - Today Record Content
    
    private var todayRecordContent: some View {
        VStack(spacing: 0) {
            // 반원형 프로그레스 바 (안드로이드: Box(padding(top = 32.dp)), SemiCircularProgressBar)
            ZStack(alignment: .bottom) {
                // 프로그레스 바 (안드로이드: fillMaxWidth(), strokeWidth = 20.dp)
                SemiCircularProgressBar(
                    progress: viewModel.uiState.dailyProgress,
                    strokeWidth: 20,
                    radiusPadding: 20
                )
                .padding(.top, 32)
                
                // 텍스트 오버레이 (안드로이드: Column(horizontalAlignment = CenterHorizontally, align(BottomCenter)))
                VStack(alignment: .center, spacing: 0) {
                    // 목표 달성률 (안드로이드: Body3, TextSub1)
                    Text(String(format: "exercise_ready_daily_goal".localized(), Int(viewModel.uiState.dailyProgress * 100)))
                        .typography(ElegaiterTypography.Body3)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                    
                    // 걸음 수 (안드로이드: Row(spacedBy(3.dp), Bottom), Display2 + Body3, "걸음" padding(bottom = 14.dp))
                    HStack(alignment: .bottom, spacing: 3) {
                        Text(viewModel.uiState.todayTotalSteps)
                            .typography(ElegaiterTypography.Display2)
                            .foregroundColor(ElegaiterColors.Text.main)
                        
                        Text("exercise_steps".localized())
                            .typography(ElegaiterTypography.Body3)
                            .foregroundColor(ElegaiterColors.Text.sub1)
                            .padding(.bottom, 14)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // 이어서 운동하기 버튼 (안드로이드: Column(fillMaxWidth, CenterHorizontally, padding(top = 22.dp)), width = 180.dp, height = 45.dp, BackgroundDark)
            VStack(alignment: .center, spacing: 0) {
                Button(action: {
                    viewModel.resetExerciseInfo()
                    viewModel.navigateToExerciseInfo()
                }) {
                    Text("exercise_ready_continue".localized())
                        .typography(ElegaiterTypography.Label3)
                        .foregroundColor(.white)
                        .frame(width: 165, height: 45)
                        .background(ElegaiterColors.Background.dark)
                        .cornerRadius(48)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 22)
            
            // 가장 최근 운동 분석
            if let metrics = viewModel.uiState.gaitMetrics,
               let recordDto = viewModel.uiState.recordDto {
                recentExerciseAnalysis(metrics: metrics, recordDto: recordDto)
            }
            
            Spacer()
                .frame(height: 112)
        }
    }
    
    // MARK: - No Record Content
    
    private var noRecordContent: some View {
        VStack(spacing: 0) {
            // 운동 시작 안내 이미지 (안드로이드: top = 12.dp, size = 280.dp, CenterHorizontally)
            Image("IcHomeCharacter")
                .resizable()
                .renderingMode(.original)
                .frame(width: 280, height: 280)
                .padding(.top, 12)
            
            // 텍스트 및 버튼 영역 (안드로이드: horizontalAlignment = CenterHorizontally, fillMaxWidth)
            VStack(alignment: .center, spacing: 0) {
                Text("exercise_ready_start_prompt".localized())
                    .typography(ElegaiterTypography.Headline5)
                    .foregroundColor(ElegaiterColors.Text.main)
                    .padding(.top, 20)
                    .padding(.bottom, 4)
                
                Text("exercise_ready_start_motivation".localized())
                    .typography(ElegaiterTypography.Body4)
                    .foregroundColor(ElegaiterColors.Text.sub1)
                    .padding(.bottom, 24)
                
                // 운동 시작하기 버튼 (안드로이드: height = 45.dp, width = 180.dp, Label3, TextMain)
                PrimaryButton(
                    onClick: {
                        viewModel.resetExerciseInfo()
                        viewModel.navigateToExerciseInfo()
                    }
                ) {
                    Text("exercise_ready_start".localized())
                        .typography(ElegaiterTypography.Label3)
                        .foregroundColor(ElegaiterColors.Text.main)
                }
                .frame(width: 180, height: 45)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
                .frame(height: 112)
        }
    }
    
    // MARK: - Recent Exercise Analysis
    
    @ViewBuilder
    private func recentExerciseAnalysis(metrics: GaitMetrics, recordDto: GaitRecordDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("exercise_ready_recent_analysis".localized())
                .typography(ElegaiterTypography.Headline5)
                .foregroundColor(.primary)
                .padding(.top, 40)
                .padding(.bottom, 20)
            
            // 보행 유형 통계 (안드로이드: Green400, StatusWarning, Orange)
            BackgroundLightCard {
                StepSummary(
                    totalSteps: metrics.totalSteps,
                    items: [
                        StepItem(
                            label: "exercise_walk".localized(),
                            percentage: metrics.stepTypeStats.walking.ratio,
                            color: ElegaiterColors.Green.green400,
                            durationS: metrics.stepTypeStats.walking.totalDurationS
                        ),
                        StepItem(
                            label: "exercise_unknown".localized(),
                            percentage: metrics.stepTypeStats.limping.ratio,
                            color: ElegaiterColors.Status.warning,
                            durationS: metrics.stepTypeStats.limping.totalDurationS
                        ),
                        StepItem(
                            label: "exercise_run".localized(),
                            percentage: metrics.stepTypeStats.running.ratio,
                            color: ElegaiterColors.Additional.orange,
                            durationS: metrics.stepTypeStats.running.totalDurationS
                        )
                    ]
                )
            }
            .padding(.bottom, 8)
            
            // 발 강도, 컨디션, 케이던스 그리드
            let footIntensityStats = metrics.footIntensity
            let leftMedian = footIntensityStats.left.median
            let rightMedian = footIntensityStats.right.median
            
            // 두 발 합이 0이면 0% 처리
            let total = leftMedian + rightMedian
            let leftPercent = total > 0 ? Int((leftMedian / total) * 100) : 0
            let rightPercent = total > 0 ? Int((rightMedian / total) * 100) : 0
            
            // 컨디션 데이터 (안드로이드: IcMoodGood, IcMoodSoso, IcMoodTired)
            let moodData: (String, String, String) = {
                switch recordDto.exerciseInfo.mood {
                case "GOOD":
                    return ("exercise_condition".localized(), "exercise_condition_good".localized(), "IcMoodGood")
                case "SOSO":
                    return ("exercise_condition".localized(), "exercise_condition_soso".localized(), "IcMoodSoso")
                case "TIRED":
                    return ("exercise_condition".localized(), "exercise_condition_tired".localized(), "IcMoodTired")
                default:
                    return ("exercise_condition".localized(), "exercise_condition_good".localized(), "IcMoodGood")
                }
            }()
            
            StepCardGrid(
                items: [
                    ("exercise_left_intensity".localized(), "\(leftPercent)%", "IcFootLeft"),
                    ("exercise_right_intensity".localized(), "\(rightPercent)%", "IcFootRight"),
                    (moodData.0, moodData.1, moodData.2),
                    ("exercise_cadence".localized(), "\(metrics.cadence)/m", "IcWalking")
                ]
            )
            
            // 자세한 분석 보러 가기 (안드로이드: Box(fillMaxWidth, Center), Row(wrapContentWidth), padding(top = 12.dp))
            HStack {
                Spacer()
                
                Button(action: {
                    viewModel.navigateToExerciseResult(metrics: metrics, recordDto: recordDto)
                }) {
                    HStack(spacing: 0) {
                        // 안드로이드: ElegaiterTypography.Label3, TextSub1
                        Text("exercise_ready_view_detailed_analysis".localized())
                            .typography(ElegaiterTypography.Label3)
                            .foregroundColor(ElegaiterColors.Text.sub1)
                        
                        // 안드로이드: ic_arrow_right, size(24.dp)
                        Image("IcArrowRight")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 12)
            
            // 건강 여정 (안드로이드: Spacer(height = 60.dp), Text(Headline5), BackgroundLightCard)
            Spacer()
                .frame(height: 60)
            
            VStack(alignment: .leading, spacing: 0) {
                // 건강 여정 제목 (안드로이드: ElegaiterTypography.Headline5, TextMain)
                Text("exercise_ready_health_journey".localized())
                    .typography(ElegaiterTypography.Headline5)
                    .foregroundColor(ElegaiterColors.Text.main)
                
                // 건강 여정 카드 (안드로이드: BackgroundLightCard(topPadding = 12.dp, cornerRadius = 20.dp, internalVerticalPadding = 16.dp))
                BackgroundLightCard {
                    VStack(alignment: .center, spacing: 0) {
                        // 배지 아이콘 (안드로이드: size(96.dp), currentGoalMilestone에 따라 다른 아이콘)
                        let badgeIconName: String = {
                            switch viewModel.uiState.currentGoalMilestone {
                            case 3:
                                return "IcBadge3daySuccess"
                            case 7:
                                return "IcBadge7daySuccess"
                            case 15:
                                return "IcBadge15daySuccess"
                            case 30:
                                return "IcBadge30daySuccess"
                            default:
                                return "IcBadge3daySuccess"
                            }
                        }()
                        
                        Image(badgeIconName)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                        
                        // 연속 측정 정보 (안드로이드: Row(fillMaxWidth, SpaceBetween), padding(top = 4.dp, bottom = 9.dp))
                        HStack {
                            // 안드로이드: ElegaiterTypography.Label3, TextMain
                            Text(String(format: "exercise_ready_consecutive_measurement".localized(), viewModel.uiState.currentGoalMilestone))
                                .typography(ElegaiterTypography.Label3)
                                .foregroundColor(ElegaiterColors.Text.main)
                            
                            Spacer()
                            
                            // 안드로이드: currentStreak는 Green500, 나머지는 TextSub2
                            HStack(spacing: 0) {
                                Text("\(viewModel.uiState.currentStreak)")
                                    .typography(ElegaiterTypography.Label3)
                                    .foregroundColor(ElegaiterColors.Green.green500)
                                
                                Text(String(format: "exercise_ready_consecutive_days_format".localized(), viewModel.uiState.currentGoalMilestone))
                                    .typography(ElegaiterTypography.Label3)
                                    .foregroundColor(ElegaiterColors.Text.sub2)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 9)
                        
                        // 프로그레스 바 (안드로이드: SimpleGradientProgressBar)
                        let progressValue = min(max(Float(viewModel.uiState.currentStreak) / Float(viewModel.uiState.currentGoalMilestone), 0.0), 1.0)
                        SimpleGradientProgressBar(progress: progressValue)
                    }
                }
                .padding(.top, 12)
            }
        }
    }
}

#Preview {
    ExerciseReadyView()
        .environmentObject(AppCoordinator())
}
