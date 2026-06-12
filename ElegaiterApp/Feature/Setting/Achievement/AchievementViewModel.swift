//
//  AchievementViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-12-05.
//

import SwiftUI
import Combine
import ElegaiterSDK

/// 내 성취 ViewModel
/// 
/// Android의 `AchievementViewModel`을 Swift로 변환
/// - 이번 달 운동 기록 확인
/// - 연속 기록 목표 달성 여부 확인
/// - 월간 걸음 수 목표 달성 여부 확인
@MainActor
class AchievementViewModel: ObservableObject {
    // MARK: - Dependencies
    
    private let monthlyAchievementRepository: MonthlyAchievementRepository
    weak var coordinator: AppCoordinator?
    
    // MARK: - Published Properties
    
    /// UI 상태
    @Published var uiState = AchievementUiState()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        monthlyAchievementRepository: MonthlyAchievementRepository? = nil,
        sdk: ElegaiterSdk = SDKManager.shared.sdk
    ) {
        // MonthlyAchievementRepository가 제공되지 않으면 기본 구현체 생성
        if let repo = monthlyAchievementRepository {
            self.monthlyAchievementRepository = repo
        } else {
            let statsRepo = ExerciseStatsRepositoryImpl(sdk: sdk)
            self.monthlyAchievementRepository = MonthlyAchievementRepositoryImpl(statsRepo: statsRepo)
        }
    }
    
    // MARK: - Public Methods
    
    /// 뱃지 달성 여부 확인
    /// - Parameter item: 뱃지 항목
    /// - Returns: 달성 여부
    func isBadgeAchieved(item: BadgeItem) -> Bool {
        switch item.key {
        case "hasRecordThisMonth":
            return uiState.hasRecordThisMonth
        case "3", "7", "15", "30":
            guard let days = Int(item.key) else { return false }
            return uiState.streakMilestones[days] ?? false
        default:
            guard let steps = Int(item.key) else { return false }
            return uiState.monthlyStepGoals[steps] ?? false
        }
    }
    
    /// 성취 데이터 로드
    func loadAchievements() {
        Task {
            await loadHasExerciseRecordThisMonth()
            await loadStreakMilestonesAchieved()
            await loadMonthlyStepGoalsAchieved()
        }
    }
    
    // MARK: - Navigation
    
    func navigateBack() {
        guard let coordinator = coordinator else { return }
        coordinator.pop(in: Binding(
            get: { coordinator.settingPath },
            set: { coordinator.settingPath = $0 }
        ))
    }
    
    // MARK: - Private Methods
    
    /// 이번 달에 운동 기록이 있는지 여부를 확인하고 UI State를 업데이트합니다.
    private func loadHasExerciseRecordThisMonth() async {
        let hasRecord = await monthlyAchievementRepository.hasExerciseRecordThisMonth()
        uiState.hasRecordThisMonth = hasRecord
    }
    
    /// 이번달 특정 연속 기록 목표(3일, 7일, 15일, 30일) 달성 여부를 확인하고 UI State를 업데이트합니다.
    private func loadStreakMilestonesAchieved() async {
        let milestones = await monthlyAchievementRepository.checkStreakMilestonesAchieved()
        uiState.streakMilestones = milestones
    }
    
    /// 이번 달 누적 걸음 수 목표(1만, 3만, 5만, 10만) 달성 여부를 확인하고 UI State를 업데이트합니다.
    private func loadMonthlyStepGoalsAchieved() async {
        let stepGoals = await monthlyAchievementRepository.checkMonthlyStepGoalsAchieved()
        uiState.monthlyStepGoals = stepGoals
    }
}

// MARK: - UI State

/// 내 성취 UI 상태
struct AchievementUiState {
    /// 이번 달에 운동 기록이 있는지 여부
    var hasRecordThisMonth: Bool = false
    /// 연속 기록 목표 달성 여부 (일수: 달성 여부)
    var streakMilestones: [Int: Bool] = [:]
    /// 월간 걸음 수 목표 달성 여부 (걸음 수: 달성 여부)
    var monthlyStepGoals: [Int: Bool] = [:]
}
