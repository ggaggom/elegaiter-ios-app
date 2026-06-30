//
//  SplashViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import CoreLocation
import ElegaiterSDK
import os.log

/// Splash 화면의 UI 상태
/// 
/// Android의 `SplashUiState` sealed interface를 Swift enum으로 변환
enum SplashUiState: Equatable {
    /// 초기 로딩 중
    case loading
    /// 로그인된 상태 (사용자 ID 포함)
    case isLoggedIn(userId: String)
    /// 로그인되지 않은 상태
    case notLoggedIn
}

/// Splash 화면의 ViewModel
/// 
/// Android의 `SplashViewModel`을 Swift로 변환
/// - SDK의 세션 상태를 점검하여 로그인 상태 확인
/// - 상태에 따라 적절한 화면으로 분기
@MainActor
class SplashViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "SplashViewModel")

    // MARK: - Published Properties
    
    /// 현재 UI 상태
    /// 
    /// Android의 `StateFlow<SplashUiState>`를 `@Published`로 변환
    @Published var uiState: SplashUiState = .loading
    
    /// 권한 안내 팝업 표시 여부
    /// 
    /// 최초 실행 시 한 번만 표시되는 권한 안내 팝업
    @Published var showPermissionGuide: Bool = false
    
    // MARK: - Properties
    
    weak var coordinator: AppCoordinator?
    
    private let sdk: ElegaiterSdk
    private let appRepository: AppRepository

    private var permissionContinuation: CheckedContinuation<Void, Never>?
    private var locationMonitor: LocationMonitor?
    private var locationPermissionCancellable: AnyCancellable?
    
    // 권한 안내 팝업 관련
    private var permissionGuideContinuation: CheckedContinuation<Void, Never>?
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameters:
    ///   - sdk: ElegaiterSDK 인스턴스 (기본값: 전역 SDK)
    ///   - coordinator: AppCoordinator 인스턴스
    ///   - appRepository: 앱 설정 저장소 인스턴스 (기본값: AppRepositoryImpl)
    init(
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        appRepository: AppRepository = AppRepositoryImpl(),
        coordinator: AppCoordinator? = nil
    ) {
        self.sdk = sdk
        self.coordinator = coordinator
        self.appRepository = appRepository
    }

    func determineInitialRoute() async {
        // 권한 안내 팝업 체크 (최초 실행 시)
        if await shouldShowPermissionGuide() {
            // 권한 안내 표시 및 대기 (팝업 내에서 권한 요청도 처리됨)
            await waitForPermissionGuideDismiss()
        } else {
            // 권한 안내 팝업이 표시되지 않은 경우에만 최초 실행 체크
            // (이미 권한 안내를 본 경우는 최초 실행 체크를 건너뜀)
            if !appRepository.isFirstLaunchCompleted() {
                // 최초 실행 (권한 안내는 이미 본 경우)
                // 퍼미션 요청 및 응답 대기
                await waitForPermissionToGranted()
                appRepository.markFirstLaunchCompleted()
                // 권한 요청 완료 처리 (이후부터 권한 모니터링 시작)
                appRepository.markPermissionRequestCompleted()
            }
        }

        await checkLoginStatus()
    }

    private func waitForPermissionToGranted() async {
        await withCheckedContinuation { continuation in
            self.permissionContinuation = continuation
            Task {
                await startPermissionRequest()
            }
        }
    }

    /// 권한 요청 시작
    /// 
    /// 위치 권한과 블루투스 권한을 순차적으로 요청하고 응답을 기다립니다.
    /// 모든 권한 요청이 완료되면 화면 라우팅을 수행합니다.
    private func startPermissionRequest() async {
        logger.debug("🚀 [Splash] 권한 요청 시작")
        
        // 1. 위치 권한 요청 및 응답 대기
        await requestLocationPermission()
        
        // 2. 블루투스 권한 요청 및 응답 대기
        await requestBluetoothPermission()
        
        // 3. 모든 권한 요청 완료 후 continuation 완료 (있는 경우에만)
        logger.debug("✅ [Splash] 모든 권한 요청 완료")
        if let continuation = permissionContinuation {
            continuation.resume()
            permissionContinuation = nil
        }
    }
    
    /// 위치 권한 요청 및 응답 대기
    /// 
    /// LocationMonitorImpl을 사용하여 위치 권한을 요청하고,
    /// 사용자가 선택할 때까지 대기합니다.
    private func requestLocationPermission() async {
        logger.debug("📍 [Splash] 위치 권한 요청 시작")
        
        // LocationMonitorImpl 생성
        let locationMonitorImpl = LocationMonitorImpl()
        self.locationMonitor = locationMonitorImpl
        
        // 현재 권한 상태 확인
        let status = locationMonitorImpl.getAuthorizationStatus()
        logger.debug("📍 [Splash] 현재 위치 권한 상태: \(status.rawValue)")
        
        // 이미 권한이 있는 경우 바로 진행
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            logger.debug("✅ [Splash] 위치 권한이 이미 부여됨")
            return
        }
        
        // 권한이 결정되지 않은 경우에만 요청
        if status == .notDetermined {
            logger.debug("📱 [Splash] 위치 권한 다이얼로그 표시")
            locationMonitorImpl.requestWhenInUseAuthorization()
            
            // 권한 응답 대기 (허용 또는 거부 모두 대기)
            await withCheckedContinuation { continuation in
                var cancellable: AnyCancellable?
                var hasResumed = false
                
                // 권한 상태 변경을 관찰 (허용 또는 거부 모두 처리)
                cancellable = locationMonitorImpl.isGranted
                    .dropFirst() // 초기 값은 무시하고 변경만 감지
                    .sink { [weak self] isGranted in
                        guard !hasResumed else { return }
                        hasResumed = true
                        
                        if isGranted {
                            self?.logger.debug("✅ [Splash] 위치 권한 부여됨")
                        } else {
                            self?.logger.debug("⚠️ [Splash] 위치 권한이 거부됨 - 계속 진행")
                        }
                        
                        cancellable?.cancel()
                        self?.locationPermissionCancellable = nil
                        continuation.resume()
                    }
                
                self.locationPermissionCancellable = cancellable
                
                // 타임아웃 처리: 5초 후에도 응답이 없으면 진행
                weak var weakSelf = self
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5초
                    guard let self = weakSelf, !hasResumed else { return }
                    hasResumed = true
                    self.logger.debug("⏱️ [Splash] 위치 권한 응답 타임아웃 - 계속 진행")
                    cancellable?.cancel()
                    self.locationPermissionCancellable = nil
                    continuation.resume()
                }
            }
        } else {
            // 권한이 거부된 경우에도 진행 (사용자가 나중에 설정에서 변경 가능)
            logger.debug("⚠️ [Splash] 위치 권한이 거부됨 - 계속 진행")
        }
    }

    /// 블루투스 권한 요청 및 응답 대기
    /// 
    /// SDK의 BleManager를 사용하여 블루투스 권한을 요청합니다.
    /// iOS에서는 initializeBluetooth() 호출 시 자동으로 권한 다이얼로그가 표시됩니다.
    private func requestBluetoothPermission() async {
        logger.debug("🔵 [Splash] 블루투스 권한 요청 시작")
        
        // 블루투스 초기화 (권한 다이얼로그 자동 표시)
        sdk.bleManager.initializeBluetooth()
        
        // iOS에서 블루투스 권한은 initializeBluetooth() 호출 시 자동으로 요청되며,
        // 사용자가 선택하면 시스템이 처리합니다.
        // 실제 권한 상태를 확인할 수 있는 방법이 SDK에 없으므로,
        // 다이얼로그가 표시되고 사용자가 선택할 시간을 줍니다.
        // 일반적으로 사용자가 다이얼로그를 보고 선택하는 데 1-2초 정도 소요됩니다.
        logger.debug("🔵 [Splash] 블루투스 권한 다이얼로그 표시됨 - 사용자 응답 대기")
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5초 대기
        
        logger.debug("✅ [Splash] 블루투스 권한 요청 완료")
    }


    
    // MARK: - Private Methods
    
    /// 저장된 세션 상태 점검
    /// 
    /// Android의 `checkAuthStatus()` 기반 자동 로그인 판단과 동일한 역할을 수행합니다.
    private func checkLoginStatus() async {
        let result = await sdk.authManager.checkAuthStatus()
        
        switch result {
        case .success(true):
            guard let userId = await sdk.authManager.currentUserId.first() else {
                logger.debug("⚠️ [Splash] 세션 점검 성공 후 사용자 ID를 복원하지 못함")
                uiState = .notLoggedIn
                return
            }
            
            logger.debug("✅ [Splash] 자동 로그인 가능: \(userId)")
            await ReviewDemoDataSeeder.seedIfNeeded(userId: userId, sdk: sdk)
            uiState = .isLoggedIn(userId: userId)
            
        case .success(false):
            logger.debug("ℹ️ [Splash] 자동 로그인 불가")
            uiState = .notLoggedIn
            
        case .failure(let error):
            logger.debug("⚠️ [Splash] 세션 점검 실패: \(error.localizedDescription)")
            uiState = .notLoggedIn
        }
    }
    
    // MARK: - Permission Guide
    
    /// 권한 안내 팝업을 보여줄지 확인하는 함수
    /// 
    /// - Returns: 권한 안내 팝업을 표시해야 하면 true, 아니면 false
    private func shouldShowPermissionGuide() async -> Bool {
        // AppRepository에서 권한 안내 팝업 노출 여부 확인
        return !appRepository.isPermissionGuideShown()
    }
    
    /// 권한 안내 팝업이 닫힐 때까지 대기하는 함수
    private func waitForPermissionGuideDismiss() async {
        await withCheckedContinuation { continuation in
            self.permissionGuideContinuation = continuation
            self.showPermissionGuide = true
        }
    }
    
    /// 권한 안내 팝업 닫기 함수 (확인 버튼 클릭 시 호출)
    /// 
    /// 팝업을 닫고 권한 요청을 시작합니다.
    func dismissPermissionGuide() {
        showPermissionGuide = false
        // 권한 요청 시작 (resume은 권한 요청 완료 후에 호출)
        Task {
            await startPermissionRequestAfterGuide()
        }
    }
    
    /// 권한 안내 후 권한 요청 시작 함수
    private func startPermissionRequestAfterGuide() async {
        // 실제 권한 요청 수행
        await startPermissionRequest()
        
        // 권한 안내 표시 완료 처리
        appRepository.markPermissionGuideShown()
        
        // 최초 실행 완료 처리 (권한 안내 팝업이 표시된 경우 최초 실행도 완료된 것으로 간주)
        appRepository.markFirstLaunchCompleted()
        
        // 권한 요청 완료 처리 (이후부터 권한 모니터링 시작)
        appRepository.markPermissionRequestCompleted()
        
        // 권한 요청 완료 후 continuation resume
        await MainActor.run {
            permissionGuideContinuation?.resume()
            permissionGuideContinuation = nil
        }
    }
    
    // MARK: - Navigation
    
    /// 로그인 화면으로 이동
    /// 
    /// Splash 화면을 백스택에서 제거하고 Login 화면으로 이동합니다.
    func navigateToLogin() {
        coordinator?.navigateFromSplash(to: .login)
    }
    
    /// JawsSearch 화면으로 이동
    /// 
    /// Splash 화면을 백스택에서 제거하고 JawsSearch 화면으로 이동합니다.
    func navigateToJawsSearch() {
        coordinator?.navigateFromSplash(to: .jawsSearch)
    }
}

