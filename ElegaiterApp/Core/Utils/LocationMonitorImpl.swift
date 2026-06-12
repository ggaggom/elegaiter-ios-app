//
//  LocationMonitorImpl.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import Foundation
import Combine
import CoreLocation
import UIKit
import ElegaiterSDK
import os.log

/// iOS 위치 모니터 구현체
/// 
/// Android의 `FusedLocationManagerLocationMonitor`를 iOS로 변환
/// - `CLLocationManager`를 사용한 실시간 위치 권한 및 GPS 상태 감지
/// - Combine Publisher로 상태 스트리밍
/// - 앱이 포그라운드로 전환될 때 상태 재확인
final class LocationMonitorImpl: NSObject, LocationMonitor {

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "LocationMonitorImpl")

    // MARK: - Properties

    /// 위치 관리자
    private let locationManager: CLLocationManager
    
    /// 위치 권한 상태 Subject
    private let _isGranted = CurrentValueSubject<Bool, Never>(false)
    
    /// GPS 활성화 상태 Subject
    private let _isGpsOn = CurrentValueSubject<Bool, Never>(false)
    
    /// 위치 권한 부여 상태 Publisher
    /// 
    /// Android의 `Flow<Boolean>`을 Combine `Publisher`로 변환
    /// - true: 위치 권한 부여됨
    /// - false: 위치 권한 부여 안 됨
    public var isGranted: AnyPublisher<Bool, Never> {
        _isGranted.eraseToAnyPublisher()
    }
    
    /// GPS 활성화 상태 Publisher
    /// 
    /// Android의 `Flow<Boolean>`을 Combine `Publisher`로 변환
    /// - true: GPS 활성화됨
    /// - false: GPS 비활성화됨
    public var isGpsOn: AnyPublisher<Bool, Never> {
        _isGpsOn.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameter locationManager: Core Location 위치 관리자 (기본값: 새 인스턴스)
    init(locationManager: CLLocationManager = CLLocationManager()) {
        logger.debug("🚀 [LocationMonitor] 초기화 시작")
        self.locationManager = locationManager
        super.init()

        locationManager.delegate = self
        logger.debug("🚀 [LocationMonitor] 델리게이트 설정 완료")

        updatePermissionStatus()
        updateGpsStatus()
        logger.debug("🚀 [LocationMonitor] 초기 상태 설정 완료")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        logger.debug("🚀 [LocationMonitor] 초기화 완료")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    
    /// 위치 권한 상태 업데이트
    private func updatePermissionStatus() {
        let status = locationManager.authorizationStatus
        let isGranted = status == .authorizedWhenInUse || status == .authorizedAlways
        logger.debug("🔍 [LocationMonitor] 권한 상태 업데이트 - 상태: \(status.rawValue), 허용: \(isGranted)")
        _isGranted.send(isGranted)
    }
    
    /// GPS 활성화 상태 업데이트
    private func updateGpsStatus() {
        let isGpsOn = CLLocationManager.locationServicesEnabled()
        logger.debug("🔍 [LocationMonitor] GPS 상태 업데이트 - 활성화: \(isGpsOn)")
        _isGpsOn.send(isGpsOn)
    }
    
    /// 앱이 포그라운드로 전환될 때 호출
    @objc private func applicationDidBecomeActive() {
        updatePermissionStatus()
        updateGpsStatus()
    }
    
    // MARK: - Public Methods
    
    /// 현재 권한 상태 가져오기
    /// 
    /// PermissionViewModel에서 권한 요청 전 상태 확인용
    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    /// 위치 권한 요청
    /// 
    /// PermissionViewModel에서 권한 요청 시 사용
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationMonitorImpl: CLLocationManagerDelegate {
    
    /// 위치 권한 상태 변경 시 호출
    /// 
    /// Android의 `BroadcastReceiver`와 `LifecycleObserver`를 대체
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updatePermissionStatus()
        updateGpsStatus()
    }
    
    /// 위치 업데이트 (사용하지 않지만 프로토콜 준수를 위해 구현)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 위치 업데이트는 필요하지 않음 (권한 및 GPS 상태만 모니터링)
    }
    
    /// 위치 오류 (사용하지 않지만 프로토콜 준수를 위해 구현)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 오류 처리 (필요시)
    }
}

