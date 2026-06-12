//
//  ExerciseStatsRepository.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import Foundation
import ElegaiterSDK

/// 운동 통계 집계된 데이터
/// 
/// Android의 `AggregatedStats` data class를 Swift struct로 변환
public struct AggregatedStats: Equatable {
    /// 총 걸음 수
    public let totalSteps: Int
    
    /// 걸음 유형별 통계 (집계된)
    public let combinedStepTypeStats: StepTypeStatistics
    
    public init(totalSteps: Int, combinedStepTypeStats: StepTypeStatistics) {
        self.totalSteps = totalSteps
        self.combinedStepTypeStats = combinedStepTypeStats
    }
}

/// 운동 통계 저장소 인터페이스
/// 
/// Android의 `ExerciseStatsRepository` interface를 Swift protocol로 변환
/// - SDK의 `gaitRecordManager`를 사용하여 운동 세션 데이터 조회 및 집계
/// - 날짜 범위별 통계 집계 기능 제공
public protocol ExerciseStatsRepository {
    /// 지정된 날짜 범위 내에 기록된 모든 운동 세션(SessionInfo) 목록을 가져옵니다.
    /// 
    /// Android의 `getSessionsByDateRange(startDate: String, endDate: String): Result<List<SessionInfo>>`를 Swift로 변환
    /// 
    /// - Parameters:
    ///   - startDate: 조회 시작일 (yyyyMMdd 형식)
    ///   - endDate: 조회 종료일 (yyyyMMdd 형식)
    /// - Returns: 세션 정보 목록 또는 오류
    func getSessionsByDateRange(startDate: String, endDate: String) async -> Result<[SessionInfo]>
    
    /// 지정된 날짜 범위 내의 모든 세션에 대한 총 걸음 수 및 걸음 유형별 통계를 집계하여 가져옵니다.
    /// 
    /// Android의 `getAggregatedStatsByDateRange(startDate: String, endDate: String): Result<AggregatedStats>`를 Swift로 변환
    /// 
    /// - Parameters:
    ///   - startDate: 조회 시작일 (yyyyMMdd 형식)
    ///   - endDate: 조회 종료일 (yyyyMMdd 형식)
    /// - Returns: 집계된 통계 데이터 또는 오류
    func getAggregatedStatsByDateRange(startDate: String, endDate: String) async -> Result<AggregatedStats>
    
    /// 지정된 날짜 범위 내에서 날짜별로 집계된 총 운동 시간(경과 시간, 초 단위)을 가져옵니다.
    /// 
    /// Android의 `getDailyElapsedTimeByDateRange(startDate: String, endDate: String): Result<Map<String, Long>>`를 Swift로 변환
    /// 
    /// - Parameters:
    ///   - startDate: 조회 시작일 (yyyyMMdd 형식)
    ///   - endDate: 조회 종료일 (yyyyMMdd 형식)
    /// - Returns: 날짜(yyyyMMdd)를 키로, 총 경과 시간을 값으로 하는 딕셔너리 또는 오류
    func getDailyElapsedTimeByDateRange(startDate: String, endDate: String) async -> Result<[String: Int64]>
    
    /// 지정된 날짜 범위 내에서 날짜별로 집계된 총 걸음 수를 가져옵니다.
    /// 
    /// Android의 `getDailyTotalStepsMapByDateRange(startDate: String, endDate: String): Result<Map<String, Int>>`를 Swift로 변환
    /// 
    /// - Parameters:
    ///   - startDate: 조회 시작일 (yyyyMMdd 형식)
    ///   - endDate: 조회 종료일 (yyyyMMdd 형식)
    /// - Returns: 날짜(yyyyMMdd)를 키로, 총 걸음 수를 값으로 하는 딕셔너리 또는 오류
    func getDailyTotalStepsMapByDateRange(startDate: String, endDate: String) async -> Result<[String: Int]>
}

/// 운동 통계 저장소 구현체
/// 
/// Android의 `ExerciseStatsRepositoryImpl`을 Swift로 변환
/// - SDK의 `gaitRecordManager`를 사용하여 데이터 조회
/// - 날짜 범위 필터링 및 통계 집계 수행
public final class ExerciseStatsRepositoryImpl: ExerciseStatsRepository {
    
    // MARK: - Properties
    
    /// ElegaiterSDK 인스턴스
    private let sdk: ElegaiterSdk
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameter sdk: ElegaiterSDK 인스턴스
    public init(sdk: ElegaiterSdk) {
        self.sdk = sdk
    }
    
    // MARK: - ExerciseStatsRepository
    
    public func getSessionsByDateRange(startDate: String, endDate: String) async -> Result<[SessionInfo]> {
        let result = await sdk.gaitRecordManager.listRecords()
        
        switch result {
        case .success(let sessions):
            let filteredList = sessions.filter { sessionInfo in
                let date = sessionInfo.date
                return date >= startDate && date <= endDate
            }
            return .success(filteredList)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func getAggregatedStatsByDateRange(startDate: String, endDate: String) async -> Result<AggregatedStats> {
        let recordsResult = await sdk.gaitRecordManager.listRecords()
        
        switch recordsResult {
        case .success(let sessions):
            let filteredSessions = sessions.filter { sessionInfo in
                sessionInfo.date >= startDate && sessionInfo.date <= endDate
            }
            
            var totalSteps = 0
            var combinedStats = StepTypeStatistics(
                walking: PerGaitTypeStat(count: 0, ratio: 0.0, totalDurationS: 0.0),
                running: PerGaitTypeStat(count: 0, ratio: 0.0, totalDurationS: 0.0),
                limping: PerGaitTypeStat(count: 0, ratio: 0.0, totalDurationS: 0.0)
            )
            
            for session in filteredSessions {
                let metricsResult = await sdk.gaitRecordManager.loadRecord(fileName: session.fileName)
                
                if case .success(let metrics) = metricsResult, let metrics = metrics {
                    totalSteps += metrics.totalSteps
                    combinedStats = mergeStepTypeStats(combinedStats, metrics.stepTypeStats)
                }
            }
            
            let finalStats = recalculateRatios(combinedStats, totalSteps: totalSteps)
            
            return .success(AggregatedStats(totalSteps: totalSteps, combinedStepTypeStats: finalStats))
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func getDailyElapsedTimeByDateRange(startDate: String, endDate: String) async -> Result<[String: Int64]> {
        let recordsResult = await sdk.gaitRecordManager.listRecords()
        
        switch recordsResult {
        case .success(let sessions):
            let filteredSessions = sessions.filter { sessionInfo in
                sessionInfo.date >= startDate && sessionInfo.date <= endDate
            }
            
            var dailyElapsedTimeMap: [String: Int64] = [:]
            
            for session in filteredSessions {
                let metaResult = await sdk.gaitRecordManager.loadRecordMetaData(fileName: session.fileName)
                
                if case .success(let recordDto) = metaResult, let recordDto = recordDto {
                    let date = session.date
                    let time = recordDto.elapsedTime
                    
                    dailyElapsedTimeMap[date] = (dailyElapsedTimeMap[date] ?? 0) + time
                }
            }
            
            return .success(dailyElapsedTimeMap)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func getDailyTotalStepsMapByDateRange(startDate: String, endDate: String) async -> Result<[String: Int]> {
        let recordsResult = await sdk.gaitRecordManager.listRecords()
        
        switch recordsResult {
        case .success(let sessions):
            let filteredSessions = sessions.filter { sessionInfo in
                sessionInfo.date >= startDate && sessionInfo.date <= endDate
            }
            
            var dailyTotalStepsMap: [String: Int] = [:]
            
            for session in filteredSessions {
                let metricsResult = await sdk.gaitRecordManager.loadRecord(fileName: session.fileName)
                
                if case .success(let metrics) = metricsResult, let metrics = metrics {
                    let date = session.date
                    let steps = metrics.totalSteps
                    
                    dailyTotalStepsMap[date] = (dailyTotalStepsMap[date] ?? 0) + steps
                }
            }
            
            return .success(dailyTotalStepsMap)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// 걸음 유형별 통계 병합
    /// 
    /// Android의 `mergeStepTypeStats` 메서드를 Swift로 변환
    private func mergeStepTypeStats(_ statsA: StepTypeStatistics, _ statsB: StepTypeStatistics) -> StepTypeStatistics {
        return StepTypeStatistics(
            walking: mergeGaitTypeStat(statsA.walking, statsB.walking),
            running: mergeGaitTypeStat(statsA.running, statsB.running),
            limping: mergeGaitTypeStat(statsA.limping, statsB.limping)
        )
    }
    
    /// 걸음 유형별 통계 병합 (개별)
    /// 
    /// Android의 `mergeGaitTypeStat` 메서드를 Swift로 변환
    private func mergeGaitTypeStat(_ statA: PerGaitTypeStat, _ statB: PerGaitTypeStat) -> PerGaitTypeStat {
        return PerGaitTypeStat(
            count: statA.count + statB.count,
            ratio: 0.0,
            totalDurationS: statA.totalDurationS + statB.totalDurationS
        )
    }
    
    /// 비율 재계산
    /// 
    /// Android의 `recalculateRatios` 메서드를 Swift로 변환
    private func recalculateRatios(_ stats: StepTypeStatistics, totalSteps: Int) -> StepTypeStatistics {
        guard totalSteps > 0 else { return stats }
        
        func calculateRatio(_ stat: PerGaitTypeStat) -> PerGaitTypeStat {
            let newRatio = Double(stat.count) / Double(totalSteps)
            return PerGaitTypeStat(
                count: stat.count,
                ratio: newRatio,
                totalDurationS: stat.totalDurationS
            )
        }
        
        return StepTypeStatistics(
            walking: calculateRatio(stats.walking),
            running: calculateRatio(stats.running),
            limping: calculateRatio(stats.limping)
        )
    }
}

