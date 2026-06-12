//
//  StepGoalViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import Combine
import ElegaiterSDK

/// 목표 걸음 수 설정 ViewModel
/// 
/// Android의 `StepGoalViewModel`을 Swift로 변환
/// - 걸음 수 목표 조회 및 저장
/// - 증가/감소 버튼 처리
@MainActor
class StepGoalViewModel: ObservableObject {
    // MARK: - Dependencies
    
    private let sdk: ElegaiterSdk
    private let stepGoalRepository: StepGoalRepository
    weak var coordinator: AppCoordinator?
    
    // MARK: - Published Properties
    
    /// UI 상태
    @Published var uiState = StepGoalUiState()
    
    /// 이벤트 스트림
    private let eventSubject = PassthroughSubject<StepGoalEvent, Never>()
    var events: AnyPublisher<StepGoalEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        stepGoalRepository: StepGoalRepository = StepGoalRepositoryImpl()
    ) {
        self.sdk = sdk
        self.stepGoalRepository = stepGoalRepository
        
        getUserStepGoal()
    }
    
    // MARK: - Data Loading
    
    /// 사용자 걸음 수 목표 조회
    private func getUserStepGoal() {
        // currentUserId Publisher 구독
        sdk.authManager.currentUserId
            .compactMap { $0 }
            .first()
            .flatMap { [weak self] userId -> AnyPublisher<Int, Never> in
                guard let self = self else {
                    return Just(10000).eraseToAnyPublisher()
                }
                return self.stepGoalRepository.stepGoalPublisher(userId: userId)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] goal in
                self?.uiState.stepGoal = goal
                self?.uiState.initialStepGoal = goal
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    /// 목표 걸음 수 변경
    /// - Parameter newGoal: 새 목표 값
    func onStepGoalChange(_ newGoal: Int) {
        let goalChanged = newGoal != uiState.initialStepGoal
        
        uiState.stepGoal = newGoal
        uiState.isSaveButtonEnabled = goalChanged
    }
    
    /// 목표 걸음 수 증가 (1000걸음)
    func incrementStepGoal() {
        let newGoal = uiState.stepGoal + 1000
        onStepGoalChange(newGoal)
    }
    
    /// 목표 걸음 수 감소 (1000걸음, 최소 0)
    func decrementStepGoal() {
        let newGoal = max(0, uiState.stepGoal - 1000)
        onStepGoalChange(newGoal)
    }
    
    /// 목표 걸음 수 저장
    func saveStepGoal() {
        Task {
            // currentUserId Publisher에서 첫 번째 값 가져오기
            var userId: String?
            let cancellable = sdk.authManager.currentUserId
                .compactMap { $0 }
                .first()
                .sink { userId = $0 }
            
            // 비동기로 기다리기
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
            cancellable.cancel()
            
            guard let userId = userId else {
                return
            }
            
            await stepGoalRepository.saveStepGoal(userId: userId, goal: uiState.stepGoal)
            
            uiState.initialStepGoal = uiState.stepGoal
            uiState.isSaveButtonEnabled = false
            
            eventSubject.send(.navigateBack)
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
}

// MARK: - UI State

/// 목표 걸음 수 설정 UI 상태
struct StepGoalUiState {
    /// 현재 목표 걸음 수
    var stepGoal: Int = 0
    /// 초기 목표 걸음 수 (변경사항 비교용)
    var initialStepGoal: Int = 0
    /// 저장 버튼 활성화 여부
    var isSaveButtonEnabled: Bool = false
}

/// 목표 걸음 수 설정 이벤트
enum StepGoalEvent {
    case navigateBack
}

