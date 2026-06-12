//
//  MonthlyAchievementRepository.swift
//  ElegaiterApp
//
//  Created on 2025-12-05.
//

import Foundation
import os.log

/// 월간 성취 저장소 인터페이스
/// 
/// Android의 `MonthlyAchievementRepository` interface를 Swift protocol로 변환
/// - 이번 달 운동 기록 확인
/// - 연속 기록 목표 달성 여부 확인
/// - 월간 걸음 수 목표 달성 여부 확인
public protocol MonthlyAchievementRepository {
    /// 이번 달에 운동 기록이 있는지 여부를 확인합니다.
    /// - Returns: 운동 기록이 있으면 true, 없으면 false
    func hasExerciseRecordThisMonth() async -> Bool
    
    /// 이번 달에 총 운동한 날짜(일수)를 계산합니다.
    /// - Returns: 이번 달 운동 일수
    func getTotalExerciseDaysThisMonth() async -> Int
    
    /// 오늘을 기준으로 현재 진행 중인 연속 운동 일수(streak)를 계산합니다.
    /// - Returns: 현재 연속 운동 일수
    func getCurrentConsecutiveExerciseDays() async -> Int
    
    /// 이번달 특정 연속 기록 목표(3일, 7일, 15일, 30일) 달성 여부를 확인합니다.
    /// - Returns: 목표(일수)를 키로, 달성 여부(Bool)를 값으로 하는 딕셔너리
    func checkStreakMilestonesAchieved() async -> [Int: Bool]
    
    /// 이번 달 누적 걸음 수를 기준으로 특정 걸음 수 목표(1만, 3만, 5만, 10만) 달성 여부를 확인합니다.
    /// - Returns: 목표(걸음 수)를 키로, 달성 여부(Bool)를 값으로 하는 딕셔너리
    func checkMonthlyStepGoalsAchieved() async -> [Int: Bool]
    
    /// 이번 달 내에서 특정 연속 운동 목표(goal)를 최초로 달성한 날짜를 조회합니다.
    /// - Parameter goal: 확인할 목표 연속 일수 (예: 3, 7, 15, 30)
    /// - Returns: 목표를 최초로 달성한 날짜(yyyyMMdd 형식). 아직 달성하지 않았다면 nil 반환
    func getFirstStreakAchievedDate(goal: Int) async -> String?
}

/// 월간 성취 저장소 구현체
/// 
/// Android의 `MonthlyAchievementRepositoryImpl`을 Swift로 변환
/// - ExerciseStatsRepository를 사용하여 데이터 조회
public final class MonthlyAchievementRepositoryImpl: MonthlyAchievementRepository {

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "MonthlyAchievementRepository")

    // MARK: - Properties
    
    /// 운동 통계 저장소
    private let statsRepo: ExerciseStatsRepository
    
    // MARK: - Initialization
    
    /// 초기화
    /// - Parameter statsRepo: 운동 통계 저장소
    public init(statsRepo: ExerciseStatsRepository) {
        self.statsRepo = statsRepo
    }
    
    // MARK: - MonthlyAchievementRepository
    
    public func hasExerciseRecordThisMonth() async -> Bool {
        let (startDate, endDate) = getThisMonthDateRange()
        let result = await statsRepo.getSessionsByDateRange(startDate: startDate, endDate: endDate)
        
        switch result {
        case .success(let sessions):
            return !sessions.isEmpty
        case .failure:
            return false
        }
    }
    
    public func getTotalExerciseDaysThisMonth() async -> Int {
        let (startDate, endDate) = getThisMonthDateRange()
        let result = await statsRepo.getDailyTotalStepsMapByDateRange(startDate: startDate, endDate: endDate)
        
        switch result {
        case .success(let dailyStepsMap):
            return dailyStepsMap.filter { $0.value > 0 }.count
        case .failure:
            return 0
        }
    }
    
    public func getCurrentConsecutiveExerciseDays() async -> Int {
        let (startDate, endDate) = getThisMonthDateRange()
        let result = await statsRepo.getDailyTotalStepsMapByDateRange(startDate: startDate, endDate: endDate)
        
        switch result {
        case .success(let dailyStepsMap):
            let exerciseDaysSet = Set(dailyStepsMap.filter { $0.value > 0 }.keys)
            
            if exerciseDaysSet.isEmpty {
                return 0
            }
            
            let calendar = Calendar.current
            let now = Date()
            var consecutiveDays = 0
            var currentDate = now
            
            // 날짜 포맷터
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            // 이번 달 첫 날
            let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            
            // 오늘부터 1일까지 역순으로 반복
            while currentDate >= firstDayOfMonth {
                let dateString = dateFormatter.string(from: currentDate)
                
                if exerciseDaysSet.contains(dateString) {
                    consecutiveDays += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            }
            
            return consecutiveDays
            
        case .failure:
            return 0
        }
    }
    
    public func checkStreakMilestonesAchieved() async -> [Int: Bool] {
        let (startDate, endDate) = getThisMonthDateRange()
        let result = await statsRepo.getDailyTotalStepsMapByDateRange(startDate: startDate, endDate: endDate)
        
        switch result {
        case .success(let dailyStepsMap):
            let exerciseDayStrings = Set(dailyStepsMap.filter { $0.value > 0 }.keys)
            
            if exerciseDayStrings.isEmpty {
                logger.debug("🏆 [MonthlyAchievement] 운동 기록 없음")
                return [3: false, 7: false, 15: false, 30: false]
            }
            
            // 날짜 문자열을 Date 객체로 변환 후 정렬
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            let sortedDates = exerciseDayStrings
                .compactMap { dateFormatter.date(from: $0) }
                .sorted()
            
            logger.debug("🏆 [MonthlyAchievement] 운동 기록 날짜: \(sortedDates.map { dateFormatter.string(from: $0) })")
            
            // 정렬된 날짜 목록을 순회하며 '최대' 연속 일수를 찾습니다
            // 안드로이드와 동일하게 maxStreak 초기값을 0으로 설정
            var maxStreak = 0
            var currentStreak = 1
            
            // 1일부터 시작 (첫 번째 날짜는 이미 currentStreak = 1로 처리)
            for i in 1..<sortedDates.count {
                let previousDay = sortedDates[i - 1]
                let currentDay = sortedDates[i]
                
                let calendar = Calendar.current
                if let days = calendar.dateComponents([.day], from: previousDay, to: currentDay).day,
                   days == 1 {
                    // 연속된 날짜
                    currentStreak += 1
                    logger.debug("🏆 [MonthlyAchievement] 연속 기록: \(dateFormatter.string(from: previousDay)) → \(dateFormatter.string(from: currentDay)), currentStreak: \(currentStreak)")
                } else {
                    // 연속이 끊김
                    logger.debug("🏆 [MonthlyAchievement] 연속 끊김: \(dateFormatter.string(from: previousDay)) → \(dateFormatter.string(from: currentDay)), maxStreak 업데이트: \(max(maxStreak, currentStreak))")
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            }
            
            // 루프가 끝난 후, 마지막 streak 값도 최대값과 비교
            maxStreak = max(maxStreak, currentStreak)
            
            logger.debug("🏆 [MonthlyAchievement] 최종 maxStreak: \(maxStreak)")
            
            // 계산된 maxStreak으로 목표 달성 여부 딕셔너리 생성
            let milestones = [3, 7, 15, 30]
            let result = Dictionary(uniqueKeysWithValues: milestones.map { ($0, $0 <= maxStreak) })
            logger.debug("🏆 [MonthlyAchievement] 달성 여부: \(result)")
            
            return result
            
        case .failure:
            logger.debug("🏆 [MonthlyAchievement] 데이터 조회 실패")
            return [3: false, 7: false, 15: false, 30: false]
        }
    }
    
    public func checkMonthlyStepGoalsAchieved() async -> [Int: Bool] {
        let (startDate, endDate) = getThisMonthDateRange()
        let result = await statsRepo.getAggregatedStatsByDateRange(startDate: startDate, endDate: endDate)
        
        switch result {
        case .success(let aggregatedStats):
            let totalSteps = aggregatedStats.totalSteps
            
            // 목표 리스트와 비교하여 딕셔너리 생성
            let goals = [10_000, 30_000, 50_000, 100_000]
            return Dictionary(uniqueKeysWithValues: goals.map { ($0, totalSteps >= $0) })
            
        case .failure:
            return [
                10_000: false,
                30_000: false,
                50_000: false,
                100_000: false
            ]
        }
    }
    
    public func getFirstStreakAchievedDate(goal: Int) async -> String? {
        let (startDate, endDate) = getThisMonthDateRange()
        let result = await statsRepo.getDailyTotalStepsMapByDateRange(startDate: startDate, endDate: endDate)
        
        switch result {
        case .success(let dailyStepsMap):
            let exerciseDaysSet = Set(dailyStepsMap.filter { $0.value > 0 }.keys)
            
            // 날짜 오름차순 정렬 (옛날 날짜 -> 오늘 날짜)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            let sortedDates = exerciseDaysSet
                .compactMap { dateFormatter.date(from: $0) }
                .sorted()
            
            var currentStreak = 1
            
            for i in sortedDates.indices {
                if i > 0 {
                    let calendar = Calendar.current
                    if let days = calendar.dateComponents([.day], from: sortedDates[i - 1], to: sortedDates[i]).day,
                       days == 1 {
                        // 연속된 날짜
                        currentStreak += 1
                    } else {
                        // 연속이 끊김
                        currentStreak = 1
                    }
                }
                
                if currentStreak == goal {
                    return dateFormatter.string(from: sortedDates[i])
                }
            }
            
            return nil
            
        case .failure:
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 이번 달의 날짜 범위를 가져옵니다.
    /// - Returns: (시작일, 종료일) 튜플 (yyyyMMdd 형식)
    private func getThisMonthDateRange() -> (String, String) {
        let calendar = Calendar.current
        let now = Date()
        
        // 이번 달 첫 날
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth) else {
            // 실패 시 현재 날짜로 설정
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            let today = dateFormatter.string(from: now)
            return (today, today)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        let startDate = dateFormatter.string(from: firstDayOfMonth)
        let endDate = dateFormatter.string(from: lastDayOfMonth)
        
        return (startDate, endDate)
    }
}
