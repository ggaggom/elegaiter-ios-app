//
//  HistoryViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import Combine
import ElegaiterSDK
import os.log

/// History Feature의 UI 상태
/// 
/// Android의 `HistoryUiState` data class를 Swift struct로 변환
struct HistoryUiState {
    /// 최근 운동 기록 목록 (최대 10개)
    var records: [SessionInfo] = []
    
    /// 로딩 상태
    var isLoading: Bool = true
    
    /// 편집 모드 여부
    var isSelectionMode: Bool = false
    
    /// 선택된 기록 파일명 집합
    var selectedRecords: Set<String> = []
    
    /// 날짜별 총 걸음 수 (키: "yyyyMMdd")
    var dailyTotalStepsMap: [String: Int] = [:]
    
    /// 일일 걸음 수 목표
    var dailyStepGoal: Int = 10000
    
    /// 날짜별 목표 달성률 (0~100%)
    var dailyGoalProgressMap: [String: Int] = [:]
    
    /// 지정 범위 내 총 걸음 수
    var rangeTotalSteps: Int = 0
    
    /// 지정 범위 내 StepTypeStatistics
    var rangeStepTypeStats: StepTypeStatistics? = nil
    
    /// 날짜별 운동 시간 (초)
    var dailyElapsedTimeMap: [String: Int64] = [:]
    
    /// 주간 일별 운동 시간 리스트 (7일)
    var weeklyElapsedTimes: [Int64] = []
    
    /// 주간 총 운동 시간
    var weeklyTotalElapsedTime: Int64 = 0
    
    /// 월간 주별 운동 시간 리스트
    var monthlyWeeklyElapsedTimes: [Int64] = []
    
    /// 월간 총 운동 시간
    var monthlyTotalElapsedTime: Int64 = 0
    
    /// 선택된 날짜의 운동 세션 목록
    var selectedDaySessions: [SessionInfo] = []
    
    /// 선택된 날짜 (yyyyMMdd 형식)
    var selectedDate: String? = nil
    
    /// 현재 연속 운동 일수
    var currentStreak: Int = 0
    
    /// 이번 달 총 운동 일수
    var totalExerciseDaysThisMonth: Int = 0
}

/// History Feature의 ViewModel
/// 
/// Android의 `HistoryViewModel`을 Swift로 변환
/// - 운동 기록 조회 및 관리
/// - 통계 집계 및 계산
/// - 날짜별 세션 조회
@MainActor
class HistoryViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "HistoryViewModel")

    // MARK: - Published Properties
    
    /// UI 상태
    @Published var uiState = HistoryUiState()
    
    /// 일별 세션으로 이동하는 이벤트
    @Published var navigateToDailySession: [SessionInfo]? = nil
    
    // MARK: - Private Properties
    
    /// Coordinator 참조
    weak var coordinator: AppCoordinator?
    
    /// SDK 인스턴스
    private let sdk: ElegaiterSdk
    
    /// 운동 통계 저장소
    private let exerciseStatsRepository: ExerciseStatsRepository
    
    /// 걸음 수 목표 저장소
    private let stepGoalRepository: StepGoalRepository
    
    /// 월간 성취 저장소
    private let monthlyAchievementRepository: MonthlyAchievementRepository
    
    /// Combine 구독 관리
    private var cancellables = Set<AnyCancellable>()
    
    /// 날짜 포맷터 (yyyyMMdd)
    private let repoDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameters:
    ///   - coordinator: AppCoordinator 참조
    ///   - sdk: ElegaiterSdk 인스턴스
    ///   - exerciseStatsRepository: 운동 통계 저장소
    ///   - stepGoalRepository: 걸음 수 목표 저장소
    ///   - monthlyAchievementRepository: 월간 성취 저장소
    init(
        coordinator: AppCoordinator? = nil,
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        exerciseStatsRepository: ExerciseStatsRepository? = nil,
        stepGoalRepository: StepGoalRepository? = nil,
        monthlyAchievementRepository: MonthlyAchievementRepository? = nil
    ) {
        self.coordinator = coordinator
        self.sdk = sdk
        
        // Repository 초기화 (nil이면 기본 구현체 사용)
        let statsRepo = exerciseStatsRepository ?? ExerciseStatsRepositoryImpl(sdk: sdk)
        self.exerciseStatsRepository = statsRepo
        self.stepGoalRepository = stepGoalRepository ?? StepGoalRepositoryImpl()
        self.monthlyAchievementRepository = monthlyAchievementRepository ?? MonthlyAchievementRepositoryImpl(statsRepo: statsRepo)
        
        // 초기 데이터 로드
        loadRecords()
        getDailyStepGoal()
        loadMonthlyAchievementStats()
    }
    
    // MARK: - Public Methods
    
    /// 운동 기록 목록 로드
    /// 
    /// Android의 `loadRecords()` 메서드를 Swift로 변환
    func loadRecords() {
        Task {
            uiState.isLoading = true
            
            let result = await sdk.gaitRecordManager.listRecords()
            
            switch result {
            case .success(let records):
                logger.debug("📋 [HistoryViewModel] listRecords 반환: \(records.count)개")
                let latestRecords = Array(records.prefix(10))
                logger.debug("📋 [HistoryViewModel] 표시할 기록: \(latestRecords.count)개")
                
                uiState.records = latestRecords
                uiState.isLoading = false
                
            case .failure(let error):
                logger.debug("❌ [HistoryViewModel] 기록 목록 로드 실패: \(error.localizedDescription)")
                uiState.isLoading = false
            }
        }
    }
    
    /// 기록 상세 정보 조회
    /// 
    /// Android의 `getRecordDetails()` 메서드를 Swift로 변환
    /// - Parameter fileName: 기록 파일명
    /// - Returns: GaitMetrics (없으면 nil)
    func getRecordDetails(fileName: String) async -> GaitMetrics? {
        let result = await sdk.gaitRecordManager.loadRecord(fileName: fileName)
        
        switch result {
        case .success(let metrics):
            return metrics
            
        case .failure:
            // 로드 실패 시 해당 기록 삭제
            await deleteRecord(fileName: fileName)
            return nil
        }
    }
    
    /// 기록 메타데이터 조회
    /// 
    /// Android의 `getRecordMetaData()` 메서드를 Swift로 변환
    /// - Parameter fileName: 기록 파일명
    /// - Returns: GaitRecordDto (없으면 nil)
    func getRecordMetaData(fileName: String) async -> GaitRecordDto? {
        let result = await sdk.gaitRecordManager.loadRecordMetaData(fileName: fileName)
        
        switch result {
        case .success(let recordDto):
            return recordDto
            
        case .failure:
            return nil
        }
    }
    
    /// 기록 삭제
    /// 
    /// Android의 `deleteRecord()` 메서드를 Swift로 변환
    /// - Parameter fileName: 삭제할 기록 파일명
    func deleteRecord(fileName: String) async {
        _ = await sdk.gaitRecordManager.deleteRecord(fileName: fileName)
        // 목록 새로고침
        loadRecords()
    }
    
    /// 편집 모드 토글
    /// 
    /// Android의 `toggleSelectionMode()` 메서드를 Swift로 변환
    func toggleSelectionMode() {
        uiState.isSelectionMode.toggle()
        uiState.selectedRecords = []
    }
    
    /// 기록 선택/해제
    /// 
    /// Android의 `toggleRecordSelection()` 메서드를 Swift로 변환
    /// - Parameter fileName: 기록 파일명
    func toggleRecordSelection(fileName: String) {
        if uiState.selectedRecords.contains(fileName) {
            uiState.selectedRecords.remove(fileName)
        } else {
            uiState.selectedRecords.insert(fileName)
        }
    }
    
    /// 선택된 기록들 삭제
    /// 
    /// Android의 `deleteSelectedRecords()` 메서드를 Swift로 변환
    func deleteSelectedRecords() async {
        let selected = uiState.selectedRecords
        
        for fileName in selected {
            _ = await sdk.gaitRecordManager.deleteRecord(fileName: fileName)
        }
        
        // 목록 새로고침
        loadRecords()
        
        // 편집 모드 비활성화
        uiState.isSelectionMode = false
        uiState.selectedRecords = []
    }
    
    /// 일일 걸음 수 목표 조회
    /// 
    /// Android의 `getDailyStepGoal()` 메서드를 Swift로 변환
    private func getDailyStepGoal() {
        Task {
            // 현재 사용자 ID 가져오기
            var userId: String?
            for await value in sdk.authManager.currentUserId.values {
                if let value = value {
                    userId = value
                    break
                }
            }
            
            guard let userId = userId else {
                return
            }
            
            // 목표 조회
            let goal = await stepGoalRepository.getStepGoal(userId: userId)
            uiState.dailyStepGoal = goal
            
            // Publisher 구독 (목표 변경 시 자동 업데이트)
            stepGoalRepository.stepGoalPublisher(userId: userId)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] goal in
                    self?.uiState.dailyStepGoal = goal
                }
                .store(in: &cancellables)
        }
    }
    
    /// 날짜별 걸음 수 및 목표 달성률 계산
    /// 
    /// Android의 `loadDailyStepsAndCalculateProgress()` 메서드를 Swift로 변환
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    func loadDailyStepsAndCalculateProgress(startDate: Date, endDate: Date) {
        Task {
            let startDateString = repoDateFormat.string(from: startDate)
            let endDateString = repoDateFormat.string(from: endDate)
            
            let result = await exerciseStatsRepository.getDailyTotalStepsMapByDateRange(
                startDate: startDateString,
                endDate: endDateString
            )
            
            switch result {
            case .success(let dailyStepsMap):
                uiState.dailyTotalStepsMap = dailyStepsMap
                calculateDailyGoalProgress(dailyStepsMap)
                
            case .failure:
                uiState.dailyTotalStepsMap = [:]
                uiState.dailyGoalProgressMap = [:]
            }
        }
    }
    
    /// 날짜별 목표 달성률 계산
    /// 
    /// Android의 `calculateDailyGoalProgress()` 메서드를 Swift로 변환
    /// - Parameter dailyTotalStepsMap: 날짜별 총 걸음 수 맵
    private func calculateDailyGoalProgress(_ dailyTotalStepsMap: [String: Int]) {
        let goalSteps = Double(uiState.dailyStepGoal)
        
        guard goalSteps > 0 else {
            uiState.dailyGoalProgressMap = [:]
            return
        }
        
        let progressMap = dailyTotalStepsMap.mapValues { steps in
            let progress = (Double(steps) / goalSteps) * 100.0
            return min(Int(progress), 100)
        }
        
        uiState.dailyGoalProgressMap = progressMap
    }
    
    /// 집계 통계 로드
    /// 
    /// Android의 `loadAggregatedStats()` 메서드를 Swift로 변환
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    func loadAggregatedStats(startDate: Date, endDate: Date) {
        Task {
            let startDateString = repoDateFormat.string(from: startDate)
            let endDateString = repoDateFormat.string(from: endDate)
            
            let result = await exerciseStatsRepository.getAggregatedStatsByDateRange(
                startDate: startDateString,
                endDate: endDateString
            )
            
            switch result {
            case .success(let stats):
                uiState.rangeTotalSteps = stats.totalSteps
                uiState.rangeStepTypeStats = stats.combinedStepTypeStats
                
            case .failure:
                break
            }
        }
    }
    
    /// 날짜별 운동 시간 계산
    /// 
    /// Android의 `loadDailyElapsedTime()` 메서드를 Swift로 변환
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///   - isWeeklyView: 주간 뷰 여부
    func loadDailyElapsedTime(startDate: Date, endDate: Date, isWeeklyView: Bool) {
        Task {
            let startDateString = repoDateFormat.string(from: startDate)
            let endDateString = repoDateFormat.string(from: endDate)
            
            let result = await exerciseStatsRepository.getDailyElapsedTimeByDateRange(
                startDate: startDateString,
                endDate: endDateString
            )
            
            switch result {
            case .success(let dailyElapsedTimeMap):
                uiState.dailyElapsedTimeMap = dailyElapsedTimeMap
                
                if isWeeklyView {
                    let weeklyTimes = getWeeklyElapsedTimes(startDate: startDate)
                    let weeklyTotal = weeklyTimes.reduce(0, +)
                    uiState.weeklyElapsedTimes = weeklyTimes
                    uiState.weeklyTotalElapsedTime = weeklyTotal
                } else {
                    let monthlyWeeklyTimes = getMonthlyWeeklyElapsedTimes(currentDate: startDate)
                    let monthlyTotal = monthlyWeeklyTimes.reduce(0, +)
                    uiState.monthlyWeeklyElapsedTimes = monthlyWeeklyTimes
                    uiState.monthlyTotalElapsedTime = monthlyTotal
                }
                
            case .failure:
                uiState.dailyElapsedTimeMap = [:]
                uiState.weeklyElapsedTimes = []
                uiState.weeklyTotalElapsedTime = 0
                uiState.monthlyWeeklyElapsedTimes = []
                uiState.monthlyTotalElapsedTime = 0
            }
        }
    }
    
    /// 주간 일별 운동 시간 계산
    /// 
    /// Android의 `getWeeklyElapsedTimes()` 메서드를 Swift로 변환
    /// - Parameter startOfWeek: 주의 시작일
    /// - Returns: 7일간의 운동 시간 리스트
    func getWeeklyElapsedTimes(startDate: Date) -> [Int64] {
        let calendar = Calendar.current
        
        return (0..<7).map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                return 0
            }
            
            let key = repoDateFormat.string(from: date)
            return uiState.dailyElapsedTimeMap[key] ?? 0
        }
    }
    
    /// 월간 주별 운동 시간 계산
    /// 
    /// Android의 `getMonthlyWeeklyElapsedTimes()` 메서드를 Swift로 변환
    /// - Parameter currentDate: 현재 날짜
    /// - Returns: 주별 운동 시간 리스트
    func getMonthlyWeeklyElapsedTimes(currentDate: Date) -> [Int64] {
        let calendar = Calendar.current
        
        // 해당 월의 첫 번째 날
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else {
            return []
        }
        
        // 해당 월의 마지막 날
        guard let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay) else {
            return []
        }
        
        // 첫 번째 월요일 찾기
        let weekday = calendar.component(.weekday, from: firstDay)
        let daysToMonday = (weekday + 5) % 7 // 월요일까지의 일수
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToMonday, to: firstDay) else {
            return []
        }
        
        var weeks: [Int64] = []
        var currentWeekStart = startOfWeek
        
        while currentWeekStart <= lastDay {
            let weekSum = (0..<7).reduce(Int64(0)) { sum, dayOffset in
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) else {
                    return sum
                }
                
                let key = repoDateFormat.string(from: date)
                return sum + (uiState.dailyElapsedTimeMap[key] ?? 0)
            }
            
            weeks.append(weekSum)
            
            // 다음 주로 이동
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else {
                break
            }
            currentWeekStart = nextWeek
        }
        
        return weeks
    }
    
    /// 특정 날짜의 세션 조회
    /// 
    /// Android의 `loadSessionForSpecificDay()` 메서드를 Swift로 변환
    /// - Parameter date: 조회할 날짜
    func loadSessionForSpecificDay(date: Date) {
        Task {
            let dateString = repoDateFormat.string(from: date)
            
            let result = await exerciseStatsRepository.getSessionsByDateRange(
                startDate: dateString,
                endDate: dateString
            )
            
            switch result {
            case .success(let sessions):
                uiState.selectedDaySessions = sessions
                uiState.selectedDate = dateString
                
                if !sessions.isEmpty {
                    navigateToDailySession = sessions
                }
                
            case .failure:
                break
            }
        }
    }
    
    /// 월간 성취 통계 로드
    /// 
    /// Android의 `loadMonthlyAchievementStats()` 메서드를 Swift로 변환
    /// - 현재 연속 운동 일수 및 이번 달 총 운동 일수 조회
    func loadMonthlyAchievementStats() {
        Task {
            do {
                let streak = await monthlyAchievementRepository.getCurrentConsecutiveExerciseDays()
                let totalDays = await monthlyAchievementRepository.getTotalExerciseDaysThisMonth()
                
                uiState.currentStreak = streak
                uiState.totalExerciseDaysThisMonth = totalDays
            } catch {
                // 에러 발생 시 기본값 설정
                uiState.currentStreak = 0
                uiState.totalExerciseDaysThisMonth = 0
            }
        }
    }
}
