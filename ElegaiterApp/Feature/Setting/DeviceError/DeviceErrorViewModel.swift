//
//  DeviceErrorViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import Combine
import ElegaiterSDK

/// 디바이스 에러 화면 ViewModel
/// 
/// Android의 `DeviceErrorViewModel`을 Swift로 변환
/// - 블루투스 연결 상태 모니터링
/// - 연결된 디바이스 정보 로드
/// - 에러 명령 전송
@MainActor
class DeviceErrorViewModel: ObservableObject {
    // MARK: - Dependencies
    
    private let sdk: ElegaiterSdk
    private let deviceRepository: DeviceRepository
    weak var coordinator: AppCoordinator?
    
    // MARK: - Published Properties
    
    /// UI 상태
    @Published var uiState = DeviceUiState()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        deviceRepository: DeviceRepository = DeviceRepositoryImpl()
    ) {
        self.sdk = sdk
        self.deviceRepository = deviceRepository
        
        observeConnectionState()
        getConnectedDevice()
    }
    
    // MARK: - Connection State Monitoring
    
    /// 블루투스 연결 상태 관찰
    private func observeConnectionState() {
        sdk.bleManager.connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.uiState.connectionState = state
            }
            .store(in: &cancellables)
    }
    
    /// 연결된 디바이스 정보 로드
    /// 
    /// Android의 `getConnectedDevice()` 함수를 Swift로 변환
    private func getConnectedDevice() {
        Task {
            let connectedDevice = await deviceRepository.loadDevice()
            await MainActor.run {
                uiState.connectedDevice = connectedDevice
            }
        }
    }
    
    // MARK: - Actions
    
    /// 에러 명령 전송
    /// 
    /// Android의 `sendErrorCommand(code: Int)` 함수를 Swift로 변환
    /// - Parameter code: 에러 코드 (1: 에러 발생, 0: 에러 해소)
    func sendErrorCommand(code: Int) {
        guard uiState.connectionState == .connected else {
            return
        }
        
        Task {
            let result = await sdk.bleManager.sendError(errorCode: code)
            
            switch result {
            case .success:
                uiState.isError = (code == 1)
            case .failure:
                break
            }
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
    
    func navigateToJawsSearch() {
        // Setting에서 진입한 경우 settingPath 사용 (SettingViewModel과 동일)
        coordinator?.navigateInSetting(to: .jawsSearch)
    }
}

// MARK: - UI State

/// 디바이스 에러 UI 상태
/// 
/// Android의 `DeviceUiState` data class를 Swift struct로 변환
struct DeviceUiState {
    /// 블루투스 연결 상태
    var connectionState: BleConnectionState = .disconnected
    /// 에러 상태 여부
    var isError: Bool = false
    /// 연결된 디바이스 정보
    var connectedDevice: ScannedDevice? = nil
}
