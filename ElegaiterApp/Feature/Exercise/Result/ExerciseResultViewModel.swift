//
//  ExerciseResultViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import ElegaiterSDK

@MainActor
class ExerciseResultViewModel: ObservableObject {
    weak var coordinator: AppCoordinator?
    
    @Published var metrics: GaitMetrics?
    @Published var record: GaitRecordDto?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteDialog: Bool = false
    @Published var isWebReportLoading: Bool = false
    @Published var isOnline: Bool = false
    
    /// 삭제 버튼 표시 여부
    /// RealTimeExercise에서 온 경우 false (닫기 버튼), 나머지는 true (삭제 버튼)
    /// 초기화 시점에 결정되며 이후 변경되지 않음
    let showDeleteButton: Bool
    
    /// 이벤트 발행을 위한 Subject
    let eventSubject = PassthroughSubject<ExerciseResultEvent, Never>()
    
    private let fileName: String?
    private let sdk: ElegaiterSdk
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    /// fileName으로 초기화 (데이터 로드 필요)
    /// History 등에서 사용하는 초기화 메서드 (삭제 버튼 표시)
    init(
        fileName: String,
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        networkMonitor: NetworkMonitor = NetworkMonitorImpl(),
        coordinator: AppCoordinator? = nil
    ) {
        self.fileName = fileName
        self.sdk = sdk
        self.networkMonitor = networkMonitor
        self.coordinator = coordinator
        // exerciseResultData가 없으면 History 등에서 온 것 (삭제 버튼)
        self.showDeleteButton = coordinator?.exerciseResultData == nil
        observeNetworkState()
        loadData()
    }
    
    /// metrics와 record로 직접 초기화 (데이터 로드 불필요)
    /// RealTimeExercise 또는 History에서 사용하는 초기화 메서드
    init(
        metrics: GaitMetrics,
        record: GaitRecordDto,
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        networkMonitor: NetworkMonitor = NetworkMonitorImpl(),
        coordinator: AppCoordinator? = nil
    ) {
        self.fileName = nil
        self.sdk = sdk
        self.networkMonitor = networkMonitor
        self.coordinator = coordinator
        self.metrics = metrics
        self.record = record
        self.isLoading = false
        // exerciseResultSourceTab이 있으면 History에서 온 것 (삭제 버튼)
        // exerciseResultSourceTab이 없으면 RealTimeExercise에서 온 것 (닫기 버튼)
        // exerciseResultData가 있으면 RealTimeExercise에서 온 것 (닫기 버튼)
        if let sourceTab = coordinator?.exerciseResultSourceTab {
            // History에서 온 경우 (삭제 버튼)
            self.showDeleteButton = true
        } else if coordinator?.exerciseResultData != nil {
            // RealTimeExercise에서 온 경우 (닫기 버튼)
            self.showDeleteButton = false
        } else {
            // 기본값: 삭제 버튼 (안전하게)
            self.showDeleteButton = true
        }
        observeNetworkState()
    }
    
    // MARK: - Network
    
    private func observeNetworkState() {
        networkMonitor.isOnline
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOnline)
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        guard let fileName = fileName else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            // 메타데이터와 메트릭을 병렬로 로드
            async let recordTask = sdk.gaitRecordManager.loadRecordMetaData(fileName: fileName)
            async let metricsTask = sdk.gaitRecordManager.loadRecord(fileName: fileName)
            
            let recordResult = await recordTask
            let metricsResult = await metricsTask
            
            await MainActor.run {
                isLoading = false
                
                switch (recordResult, metricsResult) {
                case (.success(let record), .success(let metrics)):
                    self.record = record
                    self.metrics = metrics
                    
                case (.failure(let error), _):
                    self.errorMessage = String(format: "exercise_result_metadata_load_failed".localized(), error.localizedDescription)
                    
                case (_, .failure(let error)):
                    self.errorMessage = String(format: "exercise_result_data_load_failed".localized(), error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Delete Record
    
    /// 삭제 다이얼로그 표시
    func presentDeleteDialog() {
        showDeleteDialog = true
    }
    
    /// 삭제 다이얼로그 닫기
    func dismissDeleteDialog() {
        showDeleteDialog = false
    }
    
    /// 운동 기록 삭제
    func deleteRecord() {
        guard let fileName = record?.fileName else {
            // 삭제 실패 토스트 표시
            eventSubject.send(.showDeleteFailedToast)
            return
        }
        
        Task {
            let result = await sdk.gaitRecordManager.deleteRecord(fileName: fileName)
            
            await MainActor.run {
                switch result {
                case .success:
                    showDeleteDialog = false
                    // 삭제 성공 토스트 표시
                    eventSubject.send(.deleteSuccess)
                    // 삭제 성공 후 뒤로가기
                    navigateBackAfterDelete()
                case .failure:
                    showDeleteDialog = false
                    // 삭제 실패 토스트 표시
                    eventSubject.send(.showDeleteFailedToast)
                }
            }
        }
    }
    
    /// 삭제 후 뒤로가기 처리
    private func navigateBackAfterDelete() {
        guard let coordinator = coordinator else { return }
        
        // History에서 온 경우 History 탭으로 돌아가기
        if let sourceTab = coordinator.exerciseResultSourceTab {
            coordinator.exerciseResultSourceTab = nil // 플래그 초기화
            coordinator.selectedTab = sourceTab
            // exercisePath 정리 (History로 돌아가므로 exercisePath는 비워둠)
            coordinator.exercisePath = NavigationPath()
            return
        }
        
        // RealTimeExercise에서 온 경우 (기본 동작)
        // ExerciseReady 화면 새로고침 플래그 설정
        coordinator.shouldRefreshExerciseReady = true
        
        coordinator.pop(in: Binding(
            get: { coordinator.exercisePath },
            set: { coordinator.exercisePath = $0 }
        ))
    }
    
    // MARK: - Web Report
    
    /// 웹 리포트 URL을 가져와 브라우저 오픈 이벤트를 방출합니다.
    func openWebReport() {
        guard !isWebReportLoading else { return }
        guard let fileName = record?.fileName else { return }
        
        Task {
            isWebReportLoading = true
            let result = await sdk.gaitRecordManager.getDashboardUrl(fileName: fileName)
            isWebReportLoading = false
            
            switch result {
            case .success(let url):
                eventSubject.send(.openWebReport(url: url))
            case .failure(let error):
                eventSubject.send(.showWebReportError(error))
            }
        }
    }
    
    // MARK: - Navigation
    
    func navigateBack() {
        guard let coordinator = coordinator else { return }
        
        // History에서 온 경우 History 탭으로 돌아가기
        if let sourceTab = coordinator.exerciseResultSourceTab {
            coordinator.exerciseResultSourceTab = nil // 플래그 초기화
            coordinator.selectedTab = sourceTab
            // exercisePath 정리 (History로 돌아가므로 exercisePath는 비워둠)
            coordinator.exercisePath = NavigationPath()
            // History 탭의 경로도 확인하여 적절히 처리
            // History에서 ExerciseResult로 이동했을 때 historyPath는 비어있으므로
            // History 탭으로 전환하면 자동으로 HistoryView가 표시됨
            return
        }
        
        // RealTimeExercise에서 온 경우 (기본 동작)
        // ExerciseReady 화면 새로고침 플래그 설정
        coordinator.shouldRefreshExerciseReady = true
        
        coordinator.pop(in: Binding(
            get: { coordinator.exercisePath },
            set: { coordinator.exercisePath = $0 }
        ))
    }
}
