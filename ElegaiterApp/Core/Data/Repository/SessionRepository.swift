//
//  SessionRepository.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import Foundation

/// 세션 저장소 인터페이스
/// 
/// Android의 `SessionRepository` interface를 Swift protocol로 변환
/// - 마지막 운동 세션 정보 저장/로드
/// - UserDefaults 기반 저장
public protocol SessionRepository {
    /// 마지막 세션 정보 가져오기
    /// 
    /// Android의 `suspend fun getLastSessionInfo(userId: String?): Pair<String, Int>`를 Swift로 변환
    /// 
    /// - Parameter userId: 사용자 ID (nil 가능)
    /// - Returns: (날짜, 세션 번호) 튜플
    func getLastSessionInfo(userId: String?) async -> (date: String, count: Int)
    
    /// 마지막 세션 정보 저장
    /// 
    /// Android의 `suspend fun saveLastSessionInfo(userId: String?, date: String, count: Int)`를 Swift로 변환
    /// 
    /// - Parameters:
    ///   - userId: 사용자 ID (nil 가능)
    ///   - date: 날짜 (yyyy-MM-dd 형식)
    ///   - count: 세션 번호
    func saveLastSessionInfo(userId: String?, date: String, count: Int) async
}

/// 세션 저장소 구현체
/// 
/// Android의 `SessionRepositoryImpl`을 Swift로 변환
/// - UserDefaults를 사용하여 세션 정보 저장
/// - SharedPreferences의 `exercise_session_prefs`를 UserDefaults로 변환
public final class SessionRepositoryImpl: SessionRepository {
    
    // MARK: - Properties
    
    /// UserDefaults 인스턴스
    /// 
    /// Android의 `SharedPreferences("exercise_session_prefs", ...)`에 해당
    private let userDefaults: UserDefaults
    
    /// UserDefaults 키
    private enum Keys {
        static let lastUserId = "last_user_id"
        static let lastSessionDate = "last_session_date"
        static let lastSessionCount = "last_session_count"
    }
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameter userDefaults: UserDefaults 인스턴스 (nil이면 standard 사용)
    public init(userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults ?? UserDefaults.standard
    }
    
    // MARK: - SessionRepository
    
    public func getLastSessionInfo(userId: String?) async -> (date: String, count: Int) {
        let storedUserId = userDefaults.string(forKey: Keys.lastUserId)
        
        if let userId = userId, userId == storedUserId {
            // 저장된 사용자 ID와 일치하는 경우 저장된 값 사용
            let yesterday = getYesterdayDateString()
            let date = userDefaults.string(forKey: Keys.lastSessionDate) ?? yesterday
            let count = userDefaults.integer(forKey: Keys.lastSessionCount)
            return (date, count)
        }
        
        // 저장된 사용자 ID가 없거나 일치하지 않는 경우 기본값 반환
        let yesterday = getYesterdayDateString()
        return (yesterday, 0)
    }
    
    public func saveLastSessionInfo(userId: String?, date: String, count: Int) async {
        userDefaults.set(userId, forKey: Keys.lastUserId)
        userDefaults.set(date, forKey: Keys.lastSessionDate)
        userDefaults.set(count, forKey: Keys.lastSessionCount)
    }
    
    // MARK: - Private Helper Methods
    
    /// 어제 날짜를 yyyy-MM-dd 형식 문자열로 반환
    /// 
    /// Android의 `LocalDate.now().minusDays(1).format(DateTimeFormatter.ISO_LOCAL_DATE)`를 Swift로 변환
    /// DateTimeFormatter.ISO_LOCAL_DATE는 yyyy-MM-dd 형식입니다.
    /// - Returns: 어제 날짜 (yyyy-MM-dd 형식)
    private func getYesterdayDateString() -> String {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: yesterday)
    }
}

