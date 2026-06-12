//
//  PermissionViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import CoreLocation
import ElegaiterSDK
import os.log

/// Permission 화면의 UI 상태
/// 
/// Android의 `PermissionUiState`를 Swift enum으로 변환
enum PermissionUiState {
    /// 성공 상태 (위치 권한 및 GPS 모두 활성화)
    case success
    
    /// 로딩 상태 (권한 또는 GPS 확인 중)
    /// - isGranted: 위치 권한 허용 여부
    /// - isGpsOn: GPS 활성화 여부 (nil = 확인 중)
    case loading(isGranted: Bool, isGpsOn: Bool?)
}

/// Permission 화면의 ViewModel
/// 
/// Android의 `PermissionViewModel`을 Swift로 변환
/// - 위치 권한 및 GPS 상태 모니터링
/// - 상태에 따른 UI 업데이트
/// - 권한 요청 처리
@MainActor
class PermissionViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "PermissionViewModel")

    // MARK: - Published Properties
    
    /// UI 상태
    /// 
    /// Android의 `StateFlow<PermissionUiState>`를 `@Published`로 변환
    @Published var uiState: PermissionUiState = .loading(isGranted: false, isGpsOn: nil)
    
    /// 위치 권한 필요 다이얼로그 표시 여부
    @Published var showPermissionDialog: Bool = false
    
    /// GPS 설정 필요 다이얼로그 표시 여부
    @Published var showGpsDialog: Bool = false
    
    // MARK: - Properties
    
    weak var coordinator: AppCoordinator?
    
    private let locationMonitor: LocationMonitor
    private var cancellables = Set<AnyCancellable>()
    
    /// 권한 요청이 이미 시도되었는지 여부 (중복 요청 방지)
    private var hasRequestedPermission = false
    
    /// 성공 상태로 이미 이동했는지 여부 (중복 이동 방지)
    private var hasNavigatedToNext = false
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameters:
    ///   - locationMonitor: 위치 모니터 인스턴스 (기본값: LocationMonitorImpl)
    ///   - coordinator: AppCoordinator 인스턴스
    init(
        locationMonitor: LocationMonitor = LocationMonitorImpl(),
        coordinator: AppCoordinator? = nil
    ) {
        logger.debug("🚀 [Permission] ViewModel 초기화 시작")
        self.locationMonitor = locationMonitor
        self.coordinator = coordinator
        logger.debug("🚀 [Permission] ViewModel 초기화 완료 - observeLocationState 호출")
        observeLocationState()
    }
    
    // MARK: - Private Methods
    
    /// 위치 상태 관찰
    /// 
    /// Android의 `combine(locationMonitor.isGpsOn, locationMonitor.isGranted)` 로직을 Combine으로 변환
    private func observeLocationState() {
        logger.debug("🔍 [Permission] observeLocationState 시작 - Publisher 구독 시작")
        
        // 두 Publisher를 결합하여 상태 계산
        // removeDuplicates를 사용하여 중복 값 제거
        Publishers.CombineLatest(
            locationMonitor.isGpsOn,
            locationMonitor.isGranted
        )
        .removeDuplicates { prev, next in
            // 이전 값과 다음 값이 같으면 중복으로 간주
            prev.0 == next.0 && prev.1 == next.1
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] gpsOn, gpsGranted in
            guard let self = self else { return }

            self.logger.debug("🔍 [Permission] 상태 업데이트 - GPS: \(gpsOn), 권한: \(gpsGranted)")
            
            // 두 값이 모두 true이면 Success 상태
            if gpsOn && gpsGranted {
                // 이미 이동했으면 무시
                guard !self.hasNavigatedToNext else {
                    self.logger.debug("⚠️ [Permission] 이미 다음 화면으로 이동했으므로 무시")
                    return
                }

                self.logger.debug("✅ [Permission] 성공 상태 도달")
                self.hasNavigatedToNext = true
                self.uiState = .success
                
                // 성공 시 자동으로 다음 화면으로 이동 (한 번만)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.navigateToJawsSearch()
                }
            } else {
                // 그 외의 경우 Loading 상태로 유지
                self.uiState = .loading(isGranted: gpsGranted, isGpsOn: gpsOn)
                
                // 다이얼로그 표시 조건 확인
                self.checkDialogConditions(isGranted: gpsGranted, isGpsOn: gpsOn)
            }
        }
        .store(in: &cancellables)

        logger.debug("🔍 [Permission] observeLocationState 완료 - 구독 저장됨")
    }
    
    /// 다이얼로그 표시 조건 확인
    /// 
    /// Android의 다이얼로그 표시 로직을 Swift로 변환
    private func checkDialogConditions(isGranted: Bool, isGpsOn: Bool) {
        logger.debug("🔍 [Permission] 다이얼로그 조건 확인 - 권한: \(isGranted), GPS: \(isGpsOn)")
        
        // 위치 권한이 없는 경우
        if !isGranted {
            logger.debug("⚠️ [Permission] 위치 권한 필요 다이얼로그 표시")
            showPermissionDialog = true
            showGpsDialog = false
        }
        // 권한은 있지만 GPS가 꺼져있는 경우
        else if isGranted && !isGpsOn {
            logger.debug("⚠️ [Permission] GPS 설정 필요 다이얼로그 표시")
            showPermissionDialog = false
            showGpsDialog = true
        }
        // 그 외의 경우 다이얼로그 숨김
        else {
            showPermissionDialog = false
            showGpsDialog = false
        }
    }
    
    // MARK: - Public Methods
    
    /// 위치 권한 요청
    /// 
    /// Android의 `rememberMultiplePermissionsState.launchMultiplePermissionRequest()` 로직을 Swift로 변환
    /// - 권한이 아직 결정되지 않은 경우에만 요청
    /// - LocationMonitorImpl의 locationManager를 사용하여 권한 요청
    func requestLocationPermission() {
        // 중복 요청 방지
        guard !hasRequestedPermission else {
            logger.debug("⚠️ [Permission] 권한 요청이 이미 시도되었습니다")
            return
        }
        
        // LocationMonitorImpl의 locationManager에 접근하기 위해 타입 체크
        guard let locationMonitorImpl = locationMonitor as? LocationMonitorImpl else {
            logger.debug("❌ [Permission] LocationMonitorImpl로 캐스팅 실패")
            return
        }
        
        // LocationMonitorImpl의 locationManager를 통해 권한 상태 확인
        let status = locationMonitorImpl.getAuthorizationStatus()
        
        logger.debug("🔍 [Permission] 현재 권한 상태: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            // 권한이 아직 결정되지 않은 경우에만 요청
            logger.debug("📱 [Permission] 권한 요청 다이얼로그 표시")
            hasRequestedPermission = true
            locationMonitorImpl.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // 권한이 거부된 경우 설정 화면으로 이동 안내
            logger.debug("⚠️ [Permission] 권한이 거부됨 - 다이얼로그 표시")
            showPermissionDialog = true
        case .authorizedWhenInUse, .authorizedAlways:
            // 이미 권한이 있는 경우 상태만 업데이트
            logger.debug("✅ [Permission] 이미 권한이 있음")
            break
        @unknown default:
            break
        }
    }
    
    /// 앱 설정 화면으로 이동
    /// 
    /// Android의 `Settings.ACTION_APPLICATION_DETAILS_SETTINGS` Intent를 Swift로 변환
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// GPS 설정 화면으로 이동
    /// 
    /// 주의: iOS에서는 직접 위치 서비스 설정 화면으로 이동할 수 없으므로
    /// 앱 설정 화면으로 이동 후 사용자가 수동으로 위치 서비스로 이동해야 함
    func openLocationSettings() {
        // iOS에서는 앱 설정 화면으로만 이동 가능
        openAppSettings()
    }
    
    // MARK: - Navigation
    
    /// 디바이스 검색 화면으로 이동
    /// 
    /// Android의 `navigateToJawsSearch()` 로직과 동일
    /// 권한 설정이 완료되면 다음 화면으로 이동
    /// 주의: isLoggedIn은 Threshold 완료 후에 설정됩니다
    func navigateToJawsSearch() {
        logger.debug("🚀 [Permission] navigateToJawsSearch 호출됨 - 권한 설정 완료")
        // 다음 화면으로 이동 (isLoggedIn은 아직 false 유지)
        coordinator?.navigateInMain(to: .jawsSearch)
        logger.debug("🚀 [Permission] JawsSearch 화면으로 이동 완료")
    }
}
