//
//  PermissionMonitorManager.swift
//  ElegaiterApp
//
//  Created on 2025-12-17.
//

import Foundation
import Combine
import UIKit
import CoreLocation
import CoreBluetooth
import ElegaiterSDK
import os.log

/// 전역 권한 모니터링 매니저
/// 
/// BLE 및 위치 권한을 실시간으로 모니터링하고,
/// 앱이 foreground로 전환될 때 권한 상태를 체크합니다.
/// 권한이 해제되면 팝업 표시를 위한 상태를 제공합니다.
@MainActor
class PermissionMonitorManager: ObservableObject {

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "PermissionMonitorManager")

    // MARK: - Published Properties
    
    /// 필수 권한 요청 팝업 표시 여부
    @Published var showPermissionRequiredPopup: Bool = false
    
    // MARK: - Properties
    
    private let locationMonitor: LocationMonitor
    private let appRepository: AppRepository
    private var cancellables = Set<AnyCancellable>()
    private var foregroundObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameters:
    ///   - locationMonitor: 위치 모니터 인스턴스
    ///   - appRepository: 앱 설정 저장소 인스턴스
    init(
        locationMonitor: LocationMonitor = LocationMonitorImpl(),
        appRepository: AppRepository = AppRepositoryImpl()
    ) {
        self.locationMonitor = locationMonitor
        self.appRepository = appRepository
        
        setupForegroundObserver()
        observePermissions()
    }
    
    deinit {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Private Methods
    
    /// Foreground 이벤트 관찰자 설정
    /// 
    /// 앱이 foreground로 전환될 때 권한 상태를 체크합니다.
    private func setupForegroundObserver() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkPermissionsOnForeground()
            }
        }
    }
    
    /// 권한 상태 관찰
    /// 
    /// 위치 권한 상태를 실시간으로 모니터링합니다.
    private func observePermissions() {
        locationMonitor.isGranted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isGranted in
                Task { @MainActor in
                    await self?.checkRequiredPermissions()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Foreground 전환 시 권한 체크
    /// 
    /// 앱이 foreground로 전환될 때 호출됩니다.
    /// 권한 요청이 완료된 이후에만 체크합니다.
    private func checkPermissionsOnForeground() async {
        // 권한 요청이 완료되지 않았으면 체크하지 않음
        guard appRepository.isPermissionRequestCompleted() else {
            logger.debug("🔍 [PermissionMonitor] 권한 요청이 아직 완료되지 않음 - 체크 건너뜀")
            return
        }

        logger.debug("🔍 [PermissionMonitor] Foreground 전환 - 권한 상태 체크")
        await checkRequiredPermissions()
    }
    
    /// 필수 권한 체크
    /// 
    /// BLE 및 위치 권한이 모두 허용되었는지 확인하고,
    /// 하나라도 허용되지 않으면 팝업을 표시합니다.
    private func checkRequiredPermissions() async {
        // 권한 요청이 완료되지 않았으면 체크하지 않음
        guard appRepository.isPermissionRequestCompleted() else {
            logger.debug("🔍 [PermissionMonitor] 권한 요청이 아직 완료되지 않음 - 체크 건너뜀")
            return
        }

        // 위치 권한 체크
        let locationStatus = await getLocationPermissionStatus()
        let isLocationGranted = locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways
        
        // BLE 권한 체크
        let isBluetoothGranted = await getBluetoothPermissionStatus()
        
        logger.debug("🔍 [PermissionMonitor] 권한 상태 - 위치: \(isLocationGranted), BLE: \(isBluetoothGranted)")

        // 하나라도 권한이 없으면 팝업 표시
        if !isLocationGranted || !isBluetoothGranted {
            logger.debug("⚠️ [PermissionMonitor] 필수 권한이 해제됨 - 팝업 표시")
            showPermissionRequiredPopup = true
        } else {
            // 모든 권한이 있으면 팝업 숨김
            showPermissionRequiredPopup = false
        }
    }
    
    /// 위치 권한 상태 가져오기
    private func getLocationPermissionStatus() async -> CLAuthorizationStatus {
        guard let locationMonitorImpl = locationMonitor as? LocationMonitorImpl else {
            return .notDetermined
        }
        return locationMonitorImpl.getAuthorizationStatus()
    }
    
    /// BLE 권한 상태 가져오기
    /// 
    /// iOS에서는 CBCentralManager의 state를 통해 BLE 권한 상태를 확인합니다.
    /// - .unauthorized: 권한이 거부됨
    /// - .poweredOn: 권한이 허용되고 블루투스가 켜짐
    /// - .poweredOff: 블루투스가 꺼짐 (권한은 있을 수 있음)
    /// - .unsupported: 블루투스 미지원
    private func getBluetoothPermissionStatus() async -> Bool {
        // CBCentralManager를 생성하여 상태 확인
        // 주의: 초기화 시점에 상태가 .unknown일 수 있으므로 잠시 대기
        let manager = CBCentralManager()
        
        // 상태가 업데이트될 때까지 대기 (최대 1초)
        var state = manager.state
        var waitCount = 0
        while state == .unknown && waitCount < 10 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            state = manager.state
            waitCount += 1
        }
        
        // .unauthorized이면 권한이 거부된 것으로 간주
        // 그 외의 경우(.poweredOn, .poweredOff, .unsupported 등)는 권한이 있거나
        // 블루투스가 꺼져있거나 미지원인 것으로 간주 (권한 자체는 문제없음)
        return state != .unauthorized
    }
    
    // MARK: - Public Methods
    
    /// 앱 설정 화면으로 이동
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
