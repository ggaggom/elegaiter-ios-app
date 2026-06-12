//
//  AppRepository.swift
//  ElegaiterApp
//
//  Created on 2025-12-17.
//

import Foundation

/// 앱 설정 저장소 인터페이스
/// 
/// 앱의 전역 설정 및 상태를 관리합니다.
/// - UserDefaults 기반 저장
/// - 권한 가이드 표시 여부, 최초 실행 완료 여부 등
public protocol AppRepository {
    /// 권한 가이드 표시 여부 확인
    /// 
    /// - Returns: 권한 가이드를 이미 표시했으면 true, 아니면 false
    func isPermissionGuideShown() -> Bool
    
    /// 권한 가이드 표시 완료 처리
    /// 
    /// 권한 가이드를 사용자에게 표시했음을 저장합니다.
    func markPermissionGuideShown()
    
    /// 최초 실행 완료 여부 확인
    /// 
    /// - Returns: 최초 실행이 완료되었으면 true, 아니면 false
    func isFirstLaunchCompleted() -> Bool
    
    /// 최초 실행 완료 처리
    /// 
    /// 앱이 한 번 실행되었음을 표시합니다.
    func markFirstLaunchCompleted()
    
    /// 권한 요청 완료 여부 확인
    /// 
    /// - Returns: 권한 요청이 완료되었으면 true, 아니면 false
    func isPermissionRequestCompleted() -> Bool
    
    /// 권한 요청 완료 처리
    /// 
    /// 권한 요청이 완료되었음을 저장합니다.
    func markPermissionRequestCompleted()
}

/// 앱 설정 저장소 구현체
/// 
/// UserDefaults를 사용하여 앱 전역 설정을 저장합니다.
public final class AppRepositoryImpl: AppRepository {
    
    // MARK: - Properties
    
    /// UserDefaults 인스턴스
    private let userDefaults: UserDefaults
    
    /// UserDefaults 키
    private enum Keys {
        static let permissionGuideShown = "permission_guide_shown"
        static let firstLaunchCompleted = "first_launch_completed"
        static let permissionRequestCompleted = "permission_request_completed"
    }
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameter userDefaults: UserDefaults 인스턴스 (nil이면 standard 사용)
    public init(userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults ?? UserDefaults.standard
    }
    
    // MARK: - AppRepository
    
    public func isPermissionGuideShown() -> Bool {
        return userDefaults.bool(forKey: Keys.permissionGuideShown)
    }
    
    public func markPermissionGuideShown() {
        userDefaults.set(true, forKey: Keys.permissionGuideShown)
    }
    
    public func isFirstLaunchCompleted() -> Bool {
        return userDefaults.bool(forKey: Keys.firstLaunchCompleted)
    }
    
    public func markFirstLaunchCompleted() {
        userDefaults.set(true, forKey: Keys.firstLaunchCompleted)
    }
    
    public func isPermissionRequestCompleted() -> Bool {
        return userDefaults.bool(forKey: Keys.permissionRequestCompleted)
    }
    
    public func markPermissionRequestCompleted() {
        userDefaults.set(true, forKey: Keys.permissionRequestCompleted)
    }
}

