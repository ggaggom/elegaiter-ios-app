//
//  StepGoalRepository.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import Foundation
import Combine

/// 걸음 수 목표 저장소 인터페이스
/// 
/// Android의 `StepGoalRepository` interface를 Swift protocol로 변환
/// - 사용자별 걸음 수 목표 저장/로드
/// - UserDefaults 기반 저장
public protocol StepGoalRepository {
    /// 걸음 수 목표 가져오기
    /// 
    /// Android의 `suspend fun getStepGoal(userId: String): Flow<Int>`를 Swift로 변환
    /// iOS에서는 async/await를 사용하지만, 필요시 Publisher도 제공 가능
    /// 
    /// - Parameter userId: 사용자 ID
    /// - Returns: 걸음 수 목표
    func getStepGoal(userId: String) async -> Int
    
    /// 걸음 수 목표 저장
    /// 
    /// Android의 `suspend fun saveStepGoal(userId: String, goal: Int)`를 Swift로 변환
    /// 
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - goal: 걸음 수 목표
    func saveStepGoal(userId: String, goal: Int) async
    
    /// 걸음 수 목표 Publisher (선택적)
    /// 
    /// Android의 Flow를 Swift Combine Publisher로 변환
    /// 값이 변경될 때마다 업데이트되는 스트림 제공
    /// 
    /// - Parameter userId: 사용자 ID
    /// - Returns: 걸음 수 목표를 발행하는 Publisher
    func stepGoalPublisher(userId: String) -> AnyPublisher<Int, Never>
}

/// 걸음 수 목표 저장소 구현체
/// 
/// Android의 `StepGoalRepositoryImpl`을 Swift로 변환
/// - UserDefaults를 사용하여 목표 저장
/// - SharedPreferences의 `user_goals_prefs`를 UserDefaults로 변환
public final class StepGoalRepositoryImpl: StepGoalRepository {
    
    // MARK: - Properties
    
    /// UserDefaults 인스턴스
    /// 
    /// Android의 `SharedPreferences("user_goals_prefs", ...)`에 해당
    private let userDefaults: UserDefaults
    
    /// 기본 목표 값
    /// 
    /// Android의 `KEY_DEFAULT_GOAL = 8000`에 해당
    private static let defaultGoal = 8000
    
    /// UserDefaults 키 접두사
    private static let goalKeyPrefix = "goal_"
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameter userDefaults: UserDefaults 인스턴스 (nil이면 standard 사용)
    public init(userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults ?? UserDefaults.standard
    }
    
    // MARK: - StepGoalRepository
    
    public func getStepGoal(userId: String) async -> Int {
        let key = Self.goalKeyPrefix + userId
        return userDefaults.integer(forKey: key) != 0 
            ? userDefaults.integer(forKey: key) 
            : Self.defaultGoal
    }
    
    public func saveStepGoal(userId: String, goal: Int) async {
        let key = Self.goalKeyPrefix + userId
        userDefaults.set(goal, forKey: key)
        
        // Publisher 업데이트를 위한 알림 발송
        NotificationCenter.default.post(
            name: .stepGoalDidChange,
            object: nil,
            userInfo: ["userId": userId, "goal": goal]
        )
    }
    
    public func stepGoalPublisher(userId: String) -> AnyPublisher<Int, Never> {
        let key = Self.goalKeyPrefix + userId
        
        // 초기 값
        let initialValue = userDefaults.integer(forKey: key) != 0 
            ? userDefaults.integer(forKey: key) 
            : Self.defaultGoal
        
        // NotificationCenter를 통한 변경 알림 구독
        return NotificationCenter.default.publisher(for: .stepGoalDidChange)
            .compactMap { notification -> Int? in
                guard let notificationUserId = notification.userInfo?["userId"] as? String,
                      notificationUserId == userId,
                      let goal = notification.userInfo?["goal"] as? Int else {
                    return nil
                }
                return goal
            }
            .prepend(initialValue)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Notification Name Extension

private extension Notification.Name {
    /// 걸음 수 목표 변경 알림
    static let stepGoalDidChange = Notification.Name("stepGoalDidChange")
}

