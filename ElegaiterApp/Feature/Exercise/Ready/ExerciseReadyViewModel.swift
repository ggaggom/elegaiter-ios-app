//
//  ExerciseReadyViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import ElegaiterSDK
import os.log

/// Exercise Ready 화면의 UI 상태
/// 
/// Android의 `HomeUiState` data class를 Swift struct로 변환
struct HomeUiState {
    var userName: String = ""
    var records: [SessionInfo] = []
    var isLoading: Bool = true
    var gaitMetrics: GaitMetrics? = nil
    var recordDto: GaitRecordDto? = nil
    var hasTodayRecord: Bool = false
    var gender: String = ""
    var dailyStepGoal: Int = 10000
    var todayTotalSteps: String = "0"
    var dailyProgress: Float = 0.0
    var weeklyTotalSteps: Int = 0
    var weeklyStepTypeStats: StepTypeStatistics? = nil
    var weeklyRecordExistence: [String: Bool] = [:]
    /// 현재 연속 운동 일수 (안드로이드: currentStreak)
    var currentStreak: Int = 0
    /// 현재 목표 마일스톤 (안드로이드: currentGoalMilestone)
    var currentGoalMilestone: Int = 3
}

@MainActor
class ExerciseReadyViewModel: ObservableObject {
    weak var coordinator: AppCoordinator?

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "ExerciseReadyViewModel")

    // MARK: - Published Properties
    
    @Published var uiState = HomeUiState()
    
    // MARK: - Private Properties
    
    private let sdk: ElegaiterSdk
    private let sessionRepository: SessionRepository
    private let stepGoalRepository: StepGoalRepository
    private let exerciseStatsRepository: ExerciseStatsRepository
    private let monthlyAchievementRepository: MonthlyAchievementRepository
    private var cancellables = Set<AnyCancellable>()
    
    // 날짜 포맷터
    private let todayStr: String
    private let todayDate: Date
    private let dateFormatter: DateFormatter
    private let repoDateFormat: DateFormatter
    
    // MARK: - Initialization
    
    init(
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        sessionRepository: SessionRepository = SessionRepositoryImpl(),
        stepGoalRepository: StepGoalRepository = StepGoalRepositoryImpl(),
        exerciseStatsRepository: ExerciseStatsRepository? = nil,
        monthlyAchievementRepository: MonthlyAchievementRepository? = nil,
        coordinator: AppCoordinator? = nil
    ) {
        self.sdk = sdk
        self.sessionRepository = sessionRepository
        self.stepGoalRepository = stepGoalRepository
        self.exerciseStatsRepository = exerciseStatsRepository ?? ExerciseStatsRepositoryImpl(sdk: sdk)
        self.monthlyAchievementRepository = monthlyAchievementRepository ?? MonthlyAchievementRepositoryImpl(statsRepo: exerciseStatsRepository ?? ExerciseStatsRepositoryImpl(sdk: sdk))
        self.coordinator = coordinator
        
        // 날짜 초기화
        let calendar = Calendar.current
        self.todayDate = Date()
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = displayFormatter
        self.todayStr = displayFormatter.string(from: todayDate)
        
        let repoFormatter = DateFormatter()
        repoFormatter.dateFormat = "yyyyMMdd"
        self.repoDateFormat = repoFormatter
        
        // 초기 데이터 로드
        loadUserName()
        loadHasTodayRecord()
        loadWeeklyStats()
        loadStreakProgress()
    }
    
    // MARK: - Data Loading
    
    /// 사용자 이름 로드
    private func loadUserName() {
        Task {
            // currentUserId가 설정될 때까지 대기
            // Publisher를 구독하여 값이 설정될 때까지 기다림
            var userId: String? = await sdk.authManager.currentUserId.first()
            
            // nil이면 최대 2초 동안 대기하며 재시도
            if userId == nil {
                var attempts = 0
                let maxAttempts = 20 // 2초 (100ms * 20)
                
                while userId == nil && attempts < maxAttempts {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms 대기
                    userId = await sdk.authManager.currentUserId.first()
                    attempts += 1
                }
            }
            
            guard let userId = userId else {
                logger.debug("⚠️ [ExerciseReady] currentUserId를 가져올 수 없습니다.")
                return
            }

            logger.debug("✅ [ExerciseReady] currentUserId 확인: \(userId)")
            
            let result = await sdk.authManager.getUserProfile()
            
            switch result {
            case .success(let profile):
                uiState.userName = profile.name
                logger.debug("✅ [ExerciseReady] 사용자 이름 로드 성공: \(profile.name)")
            case .failure(let error):
                logger.debug("⚠️ [ExerciseReady] 프로필 조회 실패: \(error.localizedDescription)")
                // 사용자 이름 로딩 실패 처리 (기본값 유지)
                break
            }
        }
    }
    
    /// 오늘의 기록 존재 여부 확인
    func loadHasTodayRecord() {
        Task {
            // 현재 사용자 ID 가져오기
            // currentUserId가 설정될 때까지 대기
            var userId: String? = await sdk.authManager.currentUserId.first()
            
            // nil이면 최대 2초 동안 대기하며 재시도
            if userId == nil {
                var attempts = 0
                let maxAttempts = 20 // 2초 (100ms * 20)
                
                while userId == nil && attempts < maxAttempts {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms 대기
                    userId = await sdk.authManager.currentUserId.first()
                    attempts += 1
                }
            }
            
            guard let userId = userId else {
                logger.debug("⚠️ [ExerciseReady] currentUserId를 가져올 수 없습니다. 기록을 로드할 수 없습니다.")
                return
            }

            logger.debug("✅ [ExerciseReady] currentUserId 확인: \(userId)")
            
            // 마지막 세션 정보 조회
            let (lastDateStr, _) = await sessionRepository.getLastSessionInfo(userId: userId)
            
            // 안드로이드와 동일하게 yyyy-MM-dd 형식으로 비교
            // lastDateStr과 todayStr 모두 yyyy-MM-dd 형식
            logger.debug("📅 [ExerciseReady] 날짜 비교 - lastDateStr: \(lastDateStr), todayStr: \(self.todayStr)")
            
            if lastDateStr == todayStr {
                // 오늘 기록이 있음
                uiState.hasTodayRecord = true
                await loadLatestRecordDetails()
                await getDailyStepGoal()
            } else {
                // 오늘 기록이 없음 - 성별 정보만 로드
                let userProfileResult = await sdk.authManager.getUserProfile()
                switch userProfileResult {
                case .success(let profile):
                    uiState.gender = profile.gender
                case .failure:
                    break
                }
            }
        }
    }
    
    /// 최신 기록 상세 정보 로드
    func loadLatestRecordDetails() async {
        let listResult = await sdk.gaitRecordManager.listRecords()
        
        // 가장 최근 fileName을 가져옴
        let latestRecordFileName: String?
        switch listResult {
        case .success(let records):
            latestRecordFileName = records.first?.fileName
        case .failure:
            latestRecordFileName = nil
        }
        
        guard let fileName = latestRecordFileName else {
            uiState.isLoading = false
            return
        }
        
        // 보행 지표 데이터 로드
        let metricsResult = await sdk.gaitRecordManager.loadRecord(fileName: fileName)
        let metrics: GaitMetrics?
        
        switch metricsResult {
        case .success(let loadedMetrics):
            metrics = loadedMetrics
        case .failure:
            // 기록 로드 실패 시 삭제
            await deleteRecord(fileName: fileName)
            metrics = nil
        }
        
        // 메타데이터 로드
        let metaResult = await sdk.gaitRecordManager.loadRecordMetaData(fileName: fileName)
        let loadedRecordDto: GaitRecordDto?
        
        switch metaResult {
        case .success(let recordDto):
            loadedRecordDto = recordDto
        case .failure:
            loadedRecordDto = nil
        }
        
        uiState.gaitMetrics = metrics
        uiState.recordDto = loadedRecordDto
        uiState.isLoading = false
    }
    
    /// 오늘의 총 걸음 수 계산
    private func loadTodayTotalSteps() async {
        let listResult = await sdk.gaitRecordManager.listRecords()
        var totalStepsSum = 0
        var todayRecordFileNames: [String] = []
        
        switch listResult {
        case .success(let records):
            let todayRepoStr = repoDateFormat.string(from: todayDate)
            todayRecordFileNames = records
                .filter { $0.date == todayRepoStr }
                .map { $0.fileName }
        case .failure:
            break
        }
        
        // 오늘의 모든 기록의 걸음 수 합산
        for fileName in todayRecordFileNames {
            let recordResult = await sdk.gaitRecordManager.loadRecord(fileName: fileName)
            
            if case .success(let metrics) = recordResult, let metrics = metrics {
                totalStepsSum += metrics.totalSteps
            }
        }
        
        // 목표 달성률 계산
        let progress: Float
        if totalStepsSum >= uiState.dailyStepGoal {
            progress = 1.0 // 목표 달성 시 1.0
        } else if totalStepsSum > 0 {
            progress = Float(totalStepsSum) / Float(uiState.dailyStepGoal)
        } else {
            progress = 0.0
        }
        
        // 천 단위 구분 표시 형식으로 변환
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedSteps = formatter.string(from: NSNumber(value: totalStepsSum)) ?? "0"
        
        uiState.todayTotalSteps = formattedSteps
        uiState.dailyProgress = progress
    }
    
    /// 일일 목표 조회
    private func getDailyStepGoal() async {
        // 현재 사용자 ID 가져오기 (AsyncPublisher 사용)
        var userId: String?
        for await value in sdk.authManager.currentUserId.values {
            if let value = value {
                userId = value
                break // 첫 번째 nil이 아닌 값만 가져오기
            }
        }
        
        guard let userId = userId else {
            return
        }
        
        // 목표 조회
        let goal = await stepGoalRepository.getStepGoal(userId: userId)
        uiState.dailyStepGoal = goal
        
        // 목표가 업데이트되면 오늘의 총 걸음 수 재계산
        await loadTodayTotalSteps()
        
        // Publisher 구독 (목표 변경 시 자동 업데이트)
        stepGoalRepository.stepGoalPublisher(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] goal in
                Task { @MainActor [weak self] in
                    self?.uiState.dailyStepGoal = goal
                    await self?.loadTodayTotalSteps()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 주간 통계 로드
    func loadWeeklyStats() {
        Task {
            let endDateStr = repoDateFormat.string(from: todayDate)
            
            // 최근 7일간 날짜 범위 계산 (오늘 포함 7일)
            let calendar = Calendar.current
            guard let startDate = calendar.date(byAdding: .day, value: -6, to: todayDate) else {
                return
            }
            let startDateStr = repoDateFormat.string(from: startDate)
            
            // 최근 7일간 총 걸음수 및 combinedStepTypeStats 로드
            await loadAggregatedStats(startDateStr: startDateStr, endDateStr: endDateStr)
            
            // 최근 7일간 날짜별 기록 존재 여부 확인
            await checkWeeklyRecordExistence(startDate: startDate, endDate: todayDate)
        }
    }
    
    /// 집계 통계 로드
    private func loadAggregatedStats(startDateStr: String, endDateStr: String) async {
        let result = await exerciseStatsRepository.getAggregatedStatsByDateRange(
            startDate: startDateStr,
            endDate: endDateStr
        )
        
        switch result {
        case .success(let stats):
            uiState.weeklyTotalSteps = stats.totalSteps
            uiState.weeklyStepTypeStats = stats.combinedStepTypeStats
        case .failure:
            break
        }
    }
    
    /// 기록 존재 여부 확인
    private func checkWeeklyRecordExistence(startDate: Date, endDate: Date) async {
        let startDateStr = repoDateFormat.string(from: startDate)
        let endDateStr = repoDateFormat.string(from: endDate)
        
        let sessionsResult = await exerciseStatsRepository.getSessionsByDateRange(
            startDate: startDateStr,
            endDate: endDateStr
        )
        
        switch sessionsResult {
        case .success(let sessions):
            let recordedDates = Set(sessions.map { $0.date })
            
            var existenceMap: [String: Bool] = [:]
            var currentDate = startDate
            let calendar = Calendar.current
            
            while currentDate <= endDate {
                let dateStr = repoDateFormat.string(from: currentDate)
                existenceMap[dateStr] = recordedDates.contains(dateStr)
                
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDate
            }
            
            uiState.weeklyRecordExistence = existenceMap
        case .failure:
            uiState.weeklyRecordExistence = [:]
        }
    }
    
    /// 기록 삭제
    func deleteRecord(fileName: String) async {
        _ = await sdk.gaitRecordManager.deleteRecord(fileName: fileName)
    }
    
    // MARK: - Navigation
    
    /// 운동 정보 입력 화면으로 이동
    func navigateToExerciseInfo() {
        coordinator?.exerciseRouter.navigate(to: .info)
    }
    
    /// 운동 결과 화면으로 이동
    func navigateToExerciseResult(metrics: GaitMetrics, recordDto: GaitRecordDto) {
        coordinator?.exerciseRouter.navigateToResult(fileName: recordDto.fileName)
    }
    
    /// 운동 정보 리셋 (이어서 운동하기 시)
    func resetExerciseInfo() {
        // 운동 정보를 초기화하는 로직
        // 안드로이드에서는 resetExerciseInfo()가 있지만, iOS에서는 필요시 구현
        // 현재는 단순히 운동 정보 입력 화면으로 이동
    }
    
    /// 현재 연속 운동 일수와 다음 연속 운동 목표(milestone)를 계산하여 로드합니다.
    /// 
    /// Android의 `loadStreakProgress()` 메서드를 Swift로 변환
    func loadStreakProgress() {
        Task {
            // 현재 연속 일수
            let currentStreak = await monthlyAchievementRepository.getCurrentConsecutiveExerciseDays()
            
            // 이번 달에 달성한 목표 목록
            let achievedMilestones = await monthlyAchievementRepository.checkStreakMilestonesAchieved()
            
            // 다음 목표 계산, 달성하지 못한(false) 첫 번째 목표가 다음 목표
            let goals = [3, 7, 15, 30]
            var currentGoalMilestone = 3
            
            let calendar = Calendar.current
            let todayDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            let todayStr = dateFormatter.string(from: todayDate)
            
            for i in goals.indices {
                let goal = goals[i]
                if achievedMilestones[goal] == false {
                    // 직전 목표(예: 3일)와 현재 스트릭이 같을 때, 오늘 달성 여부에 따라 분기 처리
                    if i > 0 && currentStreak == goals[i - 1] {
                        let prevGoal = goals[i - 1]
                        let firstAchievedDate = await monthlyAchievementRepository.getFirstStreakAchievedDate(goal: prevGoal)
                        // 오늘 처음 달성했다면 목표 유지(예: 3/3), 과거 달성이라면 다음 목표 노출(예: 3/7)
                        if let firstAchievedDate = firstAchievedDate, firstAchievedDate == todayStr {
                            currentGoalMilestone = prevGoal
                        } else {
                            currentGoalMilestone = goal
                        }
                    } else {
                        currentGoalMilestone = goal
                    }
                    
                    uiState.currentStreak = currentStreak
                    uiState.currentGoalMilestone = currentGoalMilestone
                    return
                }
            }
            
            // 모든 목표를 달성한 경우
            let maxGoal = 30
            uiState.currentStreak = currentStreak
            uiState.currentGoalMilestone = maxGoal
        }
    }
}
