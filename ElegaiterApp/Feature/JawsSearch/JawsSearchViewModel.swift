//
//  JawsSearchViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import ElegaiterSDK
import os.log

/// JawsSearch 화면의 ViewModel
/// 
/// Android의 `JawsSearchViewModel`을 Swift로 변환
/// - BLE 디바이스 스캔 및 연결 관리
/// - 디바이스 저장/로드
/// - 연결 상태 모니터링
/// - 다이얼로그 상태 관리
@MainActor
class JawsSearchViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "JawsSearchViewModel")

    // MARK: - Published Properties
    
    /// 로딩 상태
    @Published var isLoading: Bool = false
    
    /// 다이얼로그 상태
    @Published var dialogState: DialogState = .none
    
    /// 스캔된 디바이스 목록
    @Published var scannedDevices: [ScannedDevice] = []
    
    /// 현재 연결된 디바이스
    @Published var connectedDevice: ScannedDevice? = nil
    
    /// 마지막으로 연결했던 디바이스
    @Published var lastConnectedDevice: ScannedDevice? = nil
    
    /// Threshold 프롬프트 표시 여부
    @Published var shouldShowThresholdPrompt: Bool = true
    
    /// 이벤트 Subject
    /// 
    /// Android의 `MutableSharedFlow<JawsSearchEvent>`를 `PassthroughSubject`로 변환
    let eventSubject = PassthroughSubject<JawsSearchEvent, Never>()
    
    /// BLE 연결 상태
    /// 
    /// Android의 `bleConnectionState`를 Swift로 변환
    var bleConnectionState: AnyPublisher<BleConnectionState, Never> {
        sdk.bleManager.connectionState.eraseToAnyPublisher()
    }
    
    // MARK: - Properties
    
    weak var coordinator: AppCoordinator?
    
    private let sdk: ElegaiterSdk
    private let deviceRepository: DeviceRepository
    private var cancellables = Set<AnyCancellable>()
    
    /// 현재 연결 상태 (UI 바인딩용)
    @Published var currentConnectionState: BleConnectionState = .disconnected
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameters:
    ///   - sdk: ElegaiterSDK 인스턴스 (기본값: 전역 SDK)
    ///   - deviceRepository: 디바이스 저장소 인스턴스
    ///   - coordinator: AppCoordinator 인스턴스
    init(
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        deviceRepository: DeviceRepository = DeviceRepositoryImpl(),
        coordinator: AppCoordinator? = nil
    ) {
        self.sdk = sdk
        self.deviceRepository = deviceRepository
        self.coordinator = coordinator
        
        // [검증용 로그] 화면 전환 시 init 재호출 여부 확인 (필요 없으면 제거 가능)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let stackTraceStr: String
        if #available(iOS 16.0, *) {
            stackTraceStr = Thread.callStackSymbols.prefix(8).joined(separator: "\n   ")
        } else {
            stackTraceStr = "(unavailable)"
        }
        logger.debug("""
            🆕 [JawsSearchViewModel] init() 호출됨
               - 시각: \(formatter.string(from: Date()))
               - 호출 스택 (상위 8개):
               \(stackTraceStr)
            """)
        
        // init에서는 disconnect() 호출하지 않음.
        // 화면 전환 시 SwiftUI가 JawsSearchView(StateObject)를 다시 만들면서 init이 재호출될 수 있고,
        // 그때 disconnect()가 실행되면 이미 연결된 디바이스가 끊김. 로그로 확인됨(14:01:48 init → disconnect → 연결 해제).
        
        // 초기 데이터 로드
        loadInitialData()
        
        // 연결 상태 관찰
        observeConnectionState()
    }
    
    /// 연결 상태 관찰
    /// 
    /// BLE 연결 상태를 관찰하여 currentConnectionState 업데이트
    private func observeConnectionState() {
        sdk.bleManager.connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentConnectionState)
    }
    
    // MARK: - Initialization
    
    /// 재설정 팝업 다시 보기 여부 및 최근 연결 디바이스 로드
    /// 
    /// Android의 `loadInitialData()` 로직을 Swift로 변환
    private func loadInitialData() {
        Task {
            let lastDevice = await deviceRepository.loadDevice()
            let shouldShow = await deviceRepository.loadShouldShowThresholdPrompt()
            
            await MainActor.run {
                self.lastConnectedDevice = lastDevice
                self.shouldShowThresholdPrompt = shouldShow
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// BLE 스캔 시작
    /// 
    /// Android의 `startScan()` 로직을 Swift로 변환
    /// 화면 진입 시 자동으로 호출됨
    func startScan() {
        Task {
            isLoading = true
            
            let result = await sdk.bleManager.scan()
            
            switch result {
            case .success(let devices):
                // "Elegaiter"로 시작하는 디바이스 필터링
                let elegaiterDevices = devices.filter { $0.name.startsWith("EL") }
                // 테스트용: "Mock"으로 시작하는 디바이스도 포함
                // let mockDevices = devices.filter { $0.name.startsWith("Mock") }
                // let allDevices = elegaiterDevices + mockDevices
                // scannedDevices = allDevices
                scannedDevices = elegaiterDevices
                
            case .failure:
                dialogState = .bluetoothError
            }
            
            isLoading = false
        }
    }
    
    /// 연결된 디바이스 초기화 및 재스캔
    /// 
    /// Android의 `resetConnectedDeviceAndRescan()` 로직을 Swift로 변환
    func resetConnectedDeviceAndRescan() {
        connectedDevice = nil
        startScan()
    }
    
    /// 디바이스 선택 처리
    /// 
    /// Android의 `onDeviceSelected()` 로직을 Swift로 변환
    /// - 선택한 디바이스 연결
    /// - 연결 성공 시 connectedDevice 업데이트
    /// - Parameter device: 선택한 디바이스
    /// 
    /// Note: 디바이스 목록이 이미 있는 경우 isLoading을 변경하지 않아 UI 깜빡임 방지
    func onDeviceSelected(_ device: ScannedDevice) {
        Task {
            // 디바이스 목록이 이미 있는 경우 isLoading을 변경하지 않음 (UI 깜빡임 방지)
            let shouldSetLoading = scannedDevices.isEmpty
            
            if shouldSetLoading {
                isLoading = true
            }
            dialogState = .none
            
            let result = await sdk.bleManager.connect(device: device)
            
            switch result {
            case .success:
                connectedDevice = device
                
            case .failure:
                dialogState = .bluetoothError
            }
            
            if shouldSetLoading {
                isLoading = false
            }
        }
    }
    
    /// 다음 버튼 클릭 처리
    /// 
    /// Android의 `onNextClick()` 로직을 Swift로 변환
    /// - 연결된 디바이스 저장
    /// - Threshold 프롬프트 표시 여부 확인 후 다이얼로그 표시
    func onNextClick() {
        Task {
            guard let device = connectedDevice else { return }
            
            logger.debug("💾 [JawsSearchViewModel] 디바이스 저장 - 디바이스 이름: \(device.name), MAC 주소: \(device.address)")
            await deviceRepository.saveDevice(device)
            
            if !shouldShowThresholdPrompt {
                eventSubject.send(.navigateToMain)
                return
            }
            
            dialogState = .existingThresholdPrompt
        }
    }
    
    /// 수동 설정 화면 이동
    /// 
    /// Android의 `onManualConfigureClick()` 로직을 Swift로 변환
    func onManualConfigureClick() {
        dialogState = .none
        eventSubject.send(.navigateToThreshold)
    }
    
    /// 설정 유지 및 홈화면 이동
    /// 
    /// Android의 `onKeepSettingsClick()` 로직을 Swift로 변환
    func onKeepSettingsClick() {
        dialogState = .none
        eventSubject.send(.navigateToMain)
    }
    
    /// Threshold 프롬프트 표시 여부 토글
    /// 
    /// Android의 `toggleShouldShowThresholdPrompt()` 로직을 Swift로 변환
    func toggleShouldShowThresholdPrompt(_ isChecked: Bool) {
        shouldShowThresholdPrompt = !isChecked
    }
    
    /// Threshold 프롬프트 표시 여부 저장
    /// 
    /// Android의 `saveShouldShowThresholdPrompt()` 로직을 Swift로 변환
    func saveShouldShowThresholdPrompt() {
        Task {
            await deviceRepository.saveShouldShowThresholdPrompt(shouldShowThresholdPrompt)
        }
    }
    
    /// 다이얼로그 닫기
    func dismissDialog() {
        dialogState = .none
    }
    
    // MARK: - Navigation
    
    /// Threshold 설정 화면으로 이동
    ///
    /// 진입 경로에 따라 다른 NavigationStack 사용:
    /// - Setting(마이페이지)에서 진입한 경우: settingPath에 push
    /// - 로그인 플로우(JawsSearch)에서 진입한 경우: mainPath에 push
    func navigateToThreshold() {
        guard let coordinator = coordinator else { return }
        if !coordinator.settingPath.isEmpty {
            coordinator.navigateInSetting(to: .threshold)
        } else {
            coordinator.navigateInMain(to: .threshold)
        }
    }
    
    /// 운동 화면으로 이동 또는 이전 화면으로 돌아가기
    /// 
    /// 진입 경로에 따라 다르게 처리:
    /// - Setting에서 진입한 경우: settingPath에서 제거하여 Setting으로 돌아가기
    /// - JawsSearch 이후 진입한 경우: 로그인 상태로 전환하고 운동 홈으로 이동
    /// - Threshold 프롬프트에서 취소 시 호출
    func navigateToMain() {
        guard let coordinator = coordinator else { return }
        
        // Setting에서 진입한 경우 (settingPath에 jawsSearch가 있는 경우)
        if !coordinator.settingPath.isEmpty {
            // Setting으로 돌아가기
            coordinator.settingPath.removeLast()
        } else {
            // JawsSearch 이후 진입한 경우: 로그인 상태로 전환하고 운동 홈으로 이동
            // Threshold 프롬프트에서 취소하는 경우, 로그인 상태로 전환
            // (Threshold 완료와 동일하게 처리)
            coordinator.isLoggedIn = true
            
            // exercise 탭 선택 및 exerciseReady 화면으로 이동
            coordinator.switchTab(to: .exercise)
            
            // exercisePath 초기화하여 ExerciseReadyView가 루트로 표시되도록 함
            coordinator.exercisePath = NavigationPath()
        }
    }
    
    // MARK: - Private Methods
}

// MARK: - DialogState

/// 다이얼로그 상태
/// 
/// Android의 `DialogState` sealed class를 Swift enum으로 변환
enum DialogState: Equatable {
    /// 다이얼로그 없음
    case none
    /// BLE 에러 다이얼로그
    case bluetoothError
    /// 임계값 설정 프롬프트 (건너뛰기/설정)
    case existingThresholdPrompt
}

// MARK: - String Extension

private extension String {
    /// 문자열이 특정 접두사로 시작하는지 확인
    /// 
    /// - Parameter prefix: 확인할 접두사
    /// - Returns: 접두사로 시작하면 true
    func startsWith(_ prefix: String) -> Bool {
        return self.hasPrefix(prefix)
    }
}
