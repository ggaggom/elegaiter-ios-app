//
//  ExerciseSessionViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import ElegaiterSDK
import os.log

/// 운동 세션 UI 상태
/// 
/// Android의 `ExerciseSessionUiState` data class를 Swift struct로 변환
struct ExerciseSessionUiState {
    var sessionCount: Int = 1
    
    // 운동 정보 입력
    var speed: String = ""
    var incline: String = ""
    var duration: String = ""
    var selectedFoot: String = "left"
    var autoSave: Bool = true
    var mood: String = "GOOD"
    var exerciseInfo: ExerciseInfo? = nil
    
    // 카운트다운
    var isCountingDown: Bool = false
    var remainingCountdownTime: Int = 0
    
    // 인덱싱
    var indexingProgress: Int = 0
    var isIndexing: Bool = true
    var isShowExtensionGuide: Bool = false
    var isIndexingSuccess: Bool = false
    var showRetryMessage: Bool = false
    
    // 그래프 데이터
    var rawGaitStream: [Float] = []
    var leftMedianStream: [Float] = []
    var leftIqrStream: [Float] = []
    var rightMedianStream: [Float] = []
    var rightIqrStream: [Float] = []
    
    // 통계 데이터
    var gaitMetrics: GaitMetrics? = nil
    var finalMetrics: GaitMetrics? = nil
    var gaitRecordDto: GaitRecordDto? = nil
    
    // 그래프 설정
    var showMedianIqrGraph: Bool = false
    var graphSizePercent: Float = 1.0
    var graphCount: Int = 10
    
    // 위치 권한
    var locationDialogToShow: LocationDialog? = nil
    
    // 시간 정보
    var remainingTime: Int64 = 0
    var elapsedTime: Int64 = 0
    var progress: Float = 0.0
    
    // 세션 연장 (안드로이드: isSessionExtended)
    var isSessionExtended: Bool = false
    
    // 저장 상태
    var isAwaitingSave: Bool = false
    
    /// 사용자 보행 기록(설명) — 운동 종료 시 입력
    var gaitDescription: String = ""
    
    // 연결된 디바이스
    var connectedDevice: ScannedDevice? = nil
    
    // 게임 관련 (Arcade)
    /// 캐릭터 표시 타입 (걷기/뛰기)
    var displayStepType: DisplayStepType = .walk
    /// 캐릭터 Y축 목표 위치 (0.95f = 바닥, -0.7f = 하늘)
    var targetCharacterBias: Float = 0.95
    
    /// 폼 검증 결과
    var isFormValid: Bool {
        !speed.isEmpty && !incline.isEmpty && !duration.isEmpty
    }
    
    /// 인덱싱에 필요한 걸음 수
    var requiredIndexingSteps: Int {
        10
    }
}

/// 위치 다이얼로그 타입
enum LocationDialog {
    case permissionNeeded
    case gpsNeeded
}

/// 운동 세션 관리 ViewModel
/// 
/// 여러 화면에서 공유되는 세션 관리
@MainActor
class ExerciseSessionViewModel: ObservableObject {
    weak var router: ExerciseRouter?

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "ExerciseSessionViewModel")

    // MARK: - Published Properties
    
    @Published var uiState = ExerciseSessionUiState()
    @Published var bleConnectionState: BleConnectionState = .disconnected
    
    /// 게임 상태 (점수, 콤보, 스턴)
    @Published var gameState = ArcadeGameState()
    
    /// 운동 종료 완료 오버레이 표시 (Android: ShowFinishOverlay)
    @Published var showFinishOverlay: Bool = false
    
    /// 보행 기록 1단계 다이얼로그 (Android: ShowCommentPrompt)
    @Published var showCommentPrompt: Bool = false
    
    /// 보행 기록 2단계 입력 다이얼로그
    @Published var showCommentInput: Bool = false
    
    // MARK: - Private Properties
    
    private let sdk: ElegaiterSdk
    private let sessionRepository: SessionRepository
    private let locationMonitor: LocationMonitor
    private let deviceRepository: DeviceRepository
    
    /// BLE 연결 상태 및 위치 상태 관찰용 (항상 유지되어야 함)
    private var persistentCancellables = Set<AnyCancellable>()
    
    /// 보행 분석 데이터 관찰용 (운동 시작 시 재설정됨)
    private var gaitAnalysisCancellables = Set<AnyCancellable>()
    
    /// 운동 자동 종료 여부 (안드로이드: isAutoFinishEnabled)
    /// - true: 목표 시간이 끝나면 자동으로 운동 종료
    /// - false: 목표 시간이 끝나도 운동 계속 (세션 연장)
    private var isAutoFinishEnabled: Bool = true
    
    /// 위치 상태 (GPS 권한 및 GPS 활성화)
    @Published var gpsState: (isGranted: Bool, isGpsOn: Bool) = (false, false)
    
    // MARK: - Game State (Arcade)
    
    /// 게임 활성 상태 여부
    private var isGameActive: Bool = false
    
    /// 게임 로직에서 사용하는 이전 총 걸음 수
    private var gameLogicPreviousTotalSteps: Int = 0
    
    /// 최근 보행 유형 히스토리 (최대 9개)
    private var previousSteps: [StepType] = []
    
    /// 최대 히스토리 크기
    private let maxHistory = 9
    
    /// 운동 모드를 저장하는 구간 정보 리스트
    private var sessionSegments: [SessionSegment] = []
    
    /// 카운트다운 코루틴 추적 (안드로이드: countdownJob)
    private var countdownTask: Task<Void, Never>?
    
    /// 인덱싱 실패 후 자동 재시도 Task
    private var indexingRetryTask: Task<Void, Never>?
    
    /// 인덱싱 진행률 계산 기준점 (안드로이드: indexingStepOffset)
    private var indexingStepOffset = 0
    
    /// 종료 버튼 중복 클릭 방지 (안드로이드: isStopping)
    private var isStopping = false
    
    /// 저장 작업 중복 실행 방지 (안드로이드: isSavingProcess)
    private var isSavingProcess = false
    
    /// stop() 결과 1회 보관 (안드로이드: pendingMetrics)
    private var pendingMetrics: GaitMetrics?
    
    /// BLE 끊김 후 저장 완료 시 JawsSearch 이동 여부
    private var pendingGotoJawsSearch: Bool = false
    
    // MARK: - Initialization
    
    init(
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        sessionRepository: SessionRepository = SessionRepositoryImpl(),
        locationMonitor: LocationMonitor = LocationMonitorImpl(),
        deviceRepository: DeviceRepository = DeviceRepositoryImpl(),
        router: ExerciseRouter? = nil
    ) {
        self.sdk = sdk
        self.sessionRepository = sessionRepository
        self.locationMonitor = locationMonitor
        self.deviceRepository = deviceRepository
        self.router = router
        
        observeBleConnectionState()
        observeLocationState()
        loadInitialSettings()
        loadConnectedDevice()
    }
    
    // MARK: - Private Methods
    
    /// BLE 연결 상태 관찰
    /// 
    /// 주의: 이 구독은 항상 유지되어야 하므로 persistentCancellables에 저장됩니다.
    private func observeBleConnectionState() {
        var previousState: BleConnectionState = .disconnected
        
        sdk.bleManager.connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self = self else { return }
                
                // BLE 연결 상태 변경 상세 로그
                let oldState = previousState
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                let stackTraceStr: String
                if #available(iOS 16.0, *) {
                    stackTraceStr = Thread.callStackSymbols.prefix(3).joined(separator: "\n")
                } else {
                    stackTraceStr = ""
                }
                let stateMsg: String
                switch (oldState, newState) {
                case (.connected, .disconnected): stateMsg = "⚠️ 연결 → 끊김"
                case (.connected, .connecting): stateMsg = "🔄 연결 → 재연결 시도"
                case (.connected, .error): stateMsg = "❌ 연결 → 에러"
                case (.disconnected, .connecting): stateMsg = "🔄 끊김 → 연결 시도"
                case (.disconnected, .connected): stateMsg = "✅ 끊김 → 연결 성공"
                case (.connecting, .connected): stateMsg = "✅ 연결 시도 → 연결 성공"
                case (.connecting, .disconnected): stateMsg = "⚠️ 연결 시도 → 연결 실패 (끊김)"
                case (.connecting, .error): stateMsg = "❌ 연결 시도 → 에러"
                case (.error, .connecting): stateMsg = "🔄 에러 → 재연결 시도"
                case (.error, .connected): stateMsg = "✅ 에러 → 연결 복구"
                default: stateMsg = "상태 변경: \(String(describing: oldState)) → \(String(describing: newState))"
                }
                self.logger.debug("""
                    🔵 [ExerciseSessionViewModel] BLE 연결 상태 변경 - \(stateMsg)
                       이전: \(String(describing: oldState)), 현재: \(String(describing: newState))
                       시각: \(formatter.string(from: Date())), 스택: \(stackTraceStr)
                    """)
                
                // 상태 업데이트
                self.bleConnectionState = newState
                previousState = newState
            }
            .store(in: &persistentCancellables)
    }
    
    /// 위치 상태 관찰
    /// 
    /// GPS 권한 및 GPS 활성화 상태를 실시간으로 관찰
    /// 주의: 이 구독은 항상 유지되어야 하므로 persistentCancellables에 저장됩니다.
    private func observeLocationState() {
        Publishers.CombineLatest(
            locationMonitor.isGpsOn,
            locationMonitor.isGranted
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] gpsOn, isGranted in
            self?.gpsState = (isGranted, gpsOn)
            
            // GPS 복구 시 보행 기록 팝업 표시 (자동 저장하지 않음)
            if self?.uiState.isAwaitingSave == true,
               self?.pendingMetrics != nil,
               isGranted,
               gpsOn {
                self?.uiState.locationDialogToShow = nil
                self?.showCommentPrompt = true
            }
        }
        .store(in: &persistentCancellables)
    }
    
    /// 연결된 디바이스 정보 로드
    /// 
    /// Android의 `getConnectedDevice()` 함수를 Swift로 변환
    private func loadConnectedDevice() {
        Task { @MainActor in
            let device = await deviceRepository.loadDevice()
            if let device = device {
                logger.debug("📱 [ExerciseSessionViewModel] 연결된 디바이스 로드 - 이름: \(device.name), MAC: \(device.address)")
            } else {
                logger.debug("📱 [ExerciseSessionViewModel] 연결된 디바이스 로드 - 저장된 디바이스 없음")
            }
            uiState.connectedDevice = device
        }
    }
    
    /// 초기 설정 로드
    /// 
    /// 저장된 운동 정보와 세션 번호를 로드합니다.
    private func loadInitialSettings() {
        Task { @MainActor in
            // 저장된 운동 정보 조회
            let savedInfo = await sdk.authManager.savedExerciseInfo.first()
            
            // 현재 사용자 ID 조회
            guard let userId = await sdk.authManager.currentUserId.first() else {
                return
            }
            
            // 마지막 세션 정보 조회
            let (lastDateStr, lastCount) = await sessionRepository.getLastSessionInfo(userId: userId)
            
            // 오늘 날짜 문자열 생성
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayStr = dateFormatter.string(from: Date())
            
            // 세션 번호 계산
            let newSessionCount = lastDateStr == todayStr ? lastCount + 1 : 1
            
            // 저장된 정보가 있고 autoSave가 true면 입력 필드 자동 채움
            if let savedInfo = savedInfo, savedInfo.autoSave {
                // connectedDevice를 보존하기 위해 기존 값을 저장
                let existingDevice = uiState.connectedDevice
                uiState = ExerciseSessionUiState(
                    sessionCount: newSessionCount,
                    speed: String(savedInfo.speed),
                    incline: String(savedInfo.incline),
                    duration: String(savedInfo.duration),
                    selectedFoot: savedInfo.indexFoot,
                    autoSave: true,
                    mood: savedInfo.mood
                )
                // connectedDevice 복원
                uiState.connectedDevice = existingDevice
            } else {
                uiState.sessionCount = newSessionCount
            }
        }
    }
    
    // MARK: - Input Handlers
    
    func onSpeedChange(_ speed: String) {
        uiState.speed = speed
    }
    
    func onInclineChange(_ incline: String) {
        uiState.incline = incline
    }
    
    func onDurationChange(_ duration: String) {
        uiState.duration = duration
    }
    
    func onFootChange(_ foot: String) {
        uiState.selectedFoot = foot
    }
    
    func onAutoSaveChange(_ autoSave: Bool) {
        uiState.autoSave = autoSave
    }
    
    func onMoodChange(_ mood: String) {
        uiState.mood = mood
    }
    
    func onGaitDescriptionChange(_ description: String) {
        uiState.gaitDescription = description
    }
    
    // MARK: - Navigation
    
    func navigateToInfoIndexWalking() {
        router?.navigate(to: .infoIndexWalking)
    }
    
    func navigateToIndexWalking() {
        router?.navigate(to: .indexWalking)
    }
    
    func navigateToRealTime() {
        router?.navigate(to: .realTime)
    }
    
    /// 운동 결과 화면으로 이동
    /// 
    /// Route에는 fileName만 전달하고, 실제 데이터는 ExerciseResultViewModel에서 조회합니다.
    func navigateToResult(fileName: String) {
        router?.navigateToResult(fileName: fileName)
    }
    
    /// 운동 완료 후 결과 저장 및 결과 화면으로 이동
    /// 
    /// 운동 데이터를 저장한 후 저장된 fileName으로 결과 화면으로 이동합니다.
    func saveAndNavigateToResult(metrics: GaitMetrics, exerciseInfo: ExerciseInfo) {
        Task { @MainActor in
            // TODO: 실제 운동 완료 시 SDK를 통해 저장
            // let result = await sdk.gaitRecordManager.recordAndSyncGait(...)
            // if case .success(let record) = result {
            //     navigateToResult(fileName: record.fileName)
            // }
            
            // 테스트용: 더미 fileName 사용
            navigateToResult(fileName: "test_file_\(Date().timeIntervalSince1970)")
        }
    }
    
    func navigateToResultWithDummyData() {
        // 테스트용 더미 fileName
        navigateToResult(fileName: "test_dummy_file")
    }
    
    // MARK: - Countdown & Exercise Session
    
    /// 카운트다운 후 IndexWalking 화면으로 이동
    /// 
    /// Android의 `onCountDownToNavigateIndexWalking()` 메서드를 Swift로 변환
    /// - 5초 카운트다운 후 운동 세션 초기화 및 IndexWalking 화면으로 이동
    func onCountDownToNavigateIndexWalking() {
        countdownTask?.cancel()
        
        countdownTask = Task { @MainActor in
            // 카운트다운 시작
            uiState.isCountingDown = true
            
            // 5초부터 1초까지 카운트다운
            for i in stride(from: 5, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                uiState.remainingCountdownTime = i
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
            }
            
            guard !Task.isCancelled else { return }
            
            // 카운트다운 완료
            uiState.isCountingDown = false
            uiState.remainingCountdownTime = 0
            
            // 운동 세션 초기화
            onStartExerciseClick()
            
            guard !Task.isCancelled else { return }
            
            // IndexWalking 화면으로 이동
            navigateToIndexWalking()
        }
    }
    
    /// 운동 세션 시작
    /// 
    /// Android의 `onStartExerciseClick()` 메서드를 Swift로 변환
    /// - ExerciseInfo 생성 및 저장
    /// - GaitAnalysisManager 시작
    /// - 실시간 데이터 관찰 시작
    func onStartExerciseClick() {
        Task { @MainActor in
            // 새 운동 시작 시 이전 세션 데이터 초기화
            resetExerciseSessionState()
            
            let currentState = uiState
            
            // ExerciseInfo 생성
            guard let speed = Float(currentState.speed),
                  let incline = Float(currentState.incline),
                  let duration = Int(currentState.duration) else {
                return
            }
            
            let exerciseInfo = ExerciseInfo(
                speed: speed,
                incline: incline,
                duration: duration,
                indexFoot: currentState.selectedFoot,
                autoSave: currentState.autoSave,
                mood: currentState.mood
            )
            
            // 상태 업데이트
            uiState.exerciseInfo = exerciseInfo
            uiState.isIndexing = true
            uiState.isIndexingSuccess = false
            uiState.showRetryMessage = false
            uiState.indexingProgress = 0
            
            // 테스트: MockBleManager인 경우 파일에서 데이터 스트리밍 시작
            // BleManager 프로토콜의 옵셔널 extension을 통해 호출
            logger.debug("📡 [ExerciseSessionViewModel] Starting file streaming: envelop_01.txt, bleManager type: \(String(describing: type(of: self.sdk.bleManager)))")
            await sdk.bleManager.startStreamingFromFile(fileName: "envelop_01.txt")
            logger.debug("📡 [ExerciseSessionViewModel] File streaming started")
            
            // 기본 설정 저장 (autoSave가 true인 경우)
            if currentState.autoSave {
                // 사용자 ID가 설정될 때까지 대기 (최대 2초)
                var userId: String? = await sdk.authManager.currentUserId.first()
                if userId == nil {
                    var attempts = 0
                    let maxAttempts = 20 // 2초 (100ms * 20)
                    
                    while userId == nil && attempts < maxAttempts {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms 대기
                        userId = await sdk.authManager.currentUserId.first()
                        attempts += 1
                    }
                }
                
                if userId != nil {
                    logger.debug("✅ [ExerciseSessionViewModel] 사용자 ID 확인: \(userId!)")
                    await sdk.authManager.saveExerciseInfo(info: exerciseInfo)
                } else {
                    logger.debug("⚠️ [ExerciseSessionViewModel] 사용자 ID를 가져올 수 없어 운동 설정을 저장할 수 없습니다")
                }
            }
            
            // GaitAnalysisManager 시작 (인덱싱은 아직 시작하지 않음)
            // isAutoFinishEnabled 초기화 (안드로이드: 기본값 true)
            isAutoFinishEnabled = true
            
            sdk.gaitAnalysisManager.start(
                exerciseInfo: exerciseInfo,
                onExerciseFinished: { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        
                        // 안드로이드: isAutoFinishEnabled가 true일 때만 자동 종료
                        if self.isAutoFinishEnabled {
                            // 목표 시간 달성 시 자동 종료
                            let durationMinutes = self.uiState.duration.toIntOrNull() ?? 0
                            let totalDurationSeconds = Int64(durationMinutes * 60)
                            
                            self.uiState.elapsedTime = totalDurationSeconds
                            self.uiState.remainingTime = 0
                            self.uiState.progress = 1.0
                            
                            // 운동 자동 종료 (안드로이드: onStopExerciseClick() 호출)
                            self.onStopExerciseClick()
                        }
                    }
                },
                startIndexingImmediately: false
            )
            
            // 실시간 데이터 관찰 시작
            observeGaitAnalysis()
        }
    }
    
    /// 실시간 보행 분석 데이터 관찰
    /// 
    /// Android의 `observeGaitAnalysis()` 메서드를 Swift로 변환
    /// - rawGaitStream, leftStatStream, rightStatStream, gaitMetrics, remainingTime 관찰
    /// 
    /// 주의: BLE 연결 상태 관찰과 위치 상태 관찰은 persistentCancellables에 저장되어
    /// 이 메서드에서 취소되지 않습니다.
    private func observeGaitAnalysis() {
        logger.debug("📊 [ExerciseSessionViewModel] observeGaitAnalysis 시작")
        // 기존 보행 분석 구독만 취소 (BLE 연결 상태 관찰은 유지)
        gaitAnalysisCancellables.removeAll()
        
        // 1. 보행 시계열 그래프 데이터
        sdk.gaitAnalysisManager.rawGaitStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRawData in
                // 첫 10번과 이후 100번마다 로그 출력
                let count = newRawData.count
                if count <= 10 || count % 100 == 0 {
                    self?.logger.debug("📊 [ExerciseSessionViewModel] rawGaitStream 업데이트: \(count)개 데이터")
                }
                self?.uiState.rawGaitStream = newRawData
            }
            .store(in: &gaitAnalysisCancellables)
        
        // 2. 왼발 Median/IQR 데이터
        sdk.gaitAnalysisManager.leftStatStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.uiState.leftMedianStream = stats.map { Float($0.median) }
                self?.uiState.leftIqrStream = stats.map { Float($0.iqr) }
            }
            .store(in: &gaitAnalysisCancellables)
        
        // 3. 오른발 Median/IQR 데이터
        sdk.gaitAnalysisManager.rightStatStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.uiState.rightMedianStream = stats.map { Float($0.median) }
                self?.uiState.rightIqrStream = stats.map { Float($0.iqr) }
            }
            .store(in: &gaitAnalysisCancellables)
        
        // 4. 실시간 통계 데이터
        sdk.gaitAnalysisManager.gaitMetrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                guard let self = self else { return }
                
                let currentStep = metrics.totalSteps
                let requiredSteps = self.uiState.requiredIndexingSteps
                
                self.uiState.gaitMetrics = metrics
                let currentAttemptProgress = max(0, currentStep - self.indexingStepOffset)
                self.uiState.indexingProgress = min(currentAttemptProgress, requiredSteps)
                
                // 게임 모드일 때 캐릭터 상태 업데이트
                self.updateCharacterState(metrics: metrics)
            }
            .store(in: &gaitAnalysisCancellables)
        
        // 5. 경과 시간 (안드로이드: elapsedTime 구독)
        // 안드로이드와 동일하게 elapsedTime을 직접 구독하여 남은 시간과 진행률 계산
        sdk.gaitAnalysisManager.elapsedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] elapsed in
                guard let self = self else { return }
                
                let durationMinutes = Int(self.uiState.duration) ?? 0
                let totalDurationSeconds = Int64(durationMinutes * 60)
                
                let remaining = max(0, totalDurationSeconds - elapsed)
                let progress: Float = totalDurationSeconds > 0
                    ? Float(elapsed) / Float(totalDurationSeconds)
                    : 0.0
                
                self.uiState.elapsedTime = elapsed
                self.uiState.remainingTime = remaining
                self.uiState.progress = min(max(progress, 0.0), 1.0)
            }
            .store(in: &gaitAnalysisCancellables)
        
        // 6. 인덱싱 실패 이벤트 (안드로이드: indexingFailEvent 구독)
        sdk.gaitAnalysisManager.indexingFailEvent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // 재시도 메시지 표시
                self.uiState.showRetryMessage = true
                // 인덱싱 실패 시에는 IndexWalking 화면을 유지해야 하므로 상태를 명확히 초기화합니다.
                self.uiState.isIndexing = true
                self.uiState.isIndexingSuccess = false
                self.uiState.indexingProgress = 0
                
                // 4초 후 자동으로 재인덱싱 시작
                self.indexingRetryTask?.cancel()
                self.indexingRetryTask = Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    
                    try? await Task.sleep(nanoseconds: 4_000_000_000) // 4초 대기
                    
                    guard !Task.isCancelled else { return }
                    
                    let metrics = await self.sdk.gaitAnalysisManager.gaitMetrics.first()
                    self.indexingStepOffset = metrics.totalSteps
                    
                    if let exerciseInfo = self.uiState.exerciseInfo {
                        self.sdk.gaitAnalysisManager.startIndexing(
                            exerciseInfo: exerciseInfo,
                            startExerciseTimerWithDelay: true
                        )
                    }
                    
                    // 인덱싱 진행률 초기화
                    self.uiState.showRetryMessage = false
                    self.uiState.indexingProgress = 0
                }
            }
            .store(in: &gaitAnalysisCancellables)
        
        // 7. 인덱싱 성공 이벤트 (안드로이드: indexingSuccessEvent 구독)
        sdk.gaitAnalysisManager.indexingSuccessEvent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // 인덱싱 완료 - 화면 전환 트리거
                self.uiState.isIndexing = false
                self.uiState.isIndexingSuccess = true
            }
            .store(in: &gaitAnalysisCancellables)
    }
    
    // MARK: - Index Walking
    
    /// 10초 카운트다운 후 인덱싱 시작
    /// 
    /// Android의 `onCountDownToStartIndexWalking()` 메서드를 Swift로 변환
    /// - 10초 카운트다운 후 `startIndexing()` 호출
    func onCountDownToStartIndexWalking() {
        // INDEX 모드로 세그먼트 전환
        switchSegment(newMode: .index)
        countdownTask?.cancel()
        
        countdownTask = Task { @MainActor in
            // 카운트다운 시작
            uiState.isCountingDown = true
            
            // 10초부터 1초까지 카운트다운
            for i in stride(from: 10, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                uiState.remainingCountdownTime = i
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
            }
            
            guard !Task.isCancelled else { return }
            
            // 카운트다운 완료
            uiState.isCountingDown = false
            uiState.remainingCountdownTime = 0
            
            // 발 뻗기 가이드 표시 (안드로이드: isShowExtensionGuide = true)
            uiState.isShowExtensionGuide = true
            
            // 가이드 표시 후 2초 대기 (안드로이드: delay(2000L))
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
            
            guard !Task.isCancelled else { return }
            
            // 가이드 숨김 (안드로이드: isShowExtensionGuide = false)
            uiState.isShowExtensionGuide = false
            
            guard !Task.isCancelled else { return }
            
            let metrics = await sdk.gaitAnalysisManager.gaitMetrics.first()
            indexingStepOffset = metrics.totalSteps
            
            // 인덱싱 시작 (안드로이드: 가이드가 사라진 후에 호출)
            if let exerciseInfo = uiState.exerciseInfo {
                sdk.gaitAnalysisManager.startIndexing(
                    exerciseInfo: exerciseInfo,
                    startExerciseTimerWithDelay: true
                )
            }
        }
    }
    
    /// 인덱스 워킹 화면에서 뒤로가기를 눌렀을 때 호출됩니다.
    ///
    /// Android의 `onCancelIndexWalking()` 메서드를 Swift로 변환
    /// - 진행 중인 카운트다운/인덱싱 세션을 안전하게 종료하고 SDK 리소스를 해제합니다.
    func onCancelIndexWalking() {
        countdownTask?.cancel()
        countdownTask = nil
        indexingRetryTask?.cancel()
        indexingRetryTask = nil
        
        _ = sdk.gaitAnalysisManager.stop()
        
        resetStopAndSaveFlags()
        indexingStepOffset = 0
        
        uiState.isCountingDown = false
        uiState.remainingCountdownTime = 0
        uiState.isShowExtensionGuide = false
        uiState.showRetryMessage = false
        uiState.isIndexing = false
        uiState.indexingProgress = 0
        uiState.isIndexingSuccess = false
    }
    
    /// 카운트다운 상태 초기화
    /// 
    /// Android의 `resetCountdownState()` 메서드를 Swift로 변환
    func resetCountdownState() {
        countdownTask?.cancel()
        countdownTask = nil
        
        uiState.isCountingDown = false
        uiState.remainingCountdownTime = 0
        uiState.isShowExtensionGuide = false
    }
    
    // MARK: - RealTime Exercise Methods
    
    /// 그래프 타입 변경
    /// 
    /// Android의 `onGraphTypeChange()` 메서드를 Swift로 변환
    func onGraphTypeChange(_ showMedianIqr: Bool) {
        uiState.showMedianIqrGraph = showMedianIqr
    }
    
    /// 그래프 높이 증가
    /// 
    /// Android의 `increaseGraphHeight()` 메서드를 Swift로 변환
    /// - 범위: 50% ~ 100% (10% 단위)
    func increaseGraphHeight() {
        let newSize = min(uiState.graphSizePercent + 0.1, 1.0)
        uiState.graphSizePercent = newSize
    }
    
    /// 그래프 높이 감소
    /// 
    /// Android의 `decreaseGraphHeight()` 메서드를 Swift로 변환
    /// - 범위: 50% ~ 100% (10% 단위)
    func decreaseGraphHeight() {
        let newSize = max(uiState.graphSizePercent - 0.1, 0.5)
        uiState.graphSizePercent = newSize
    }
    
    /// 그래프 폭 증가
    /// 
    /// Android의 `increaseGraphWidth()` 메서드를 Swift로 변환
    /// - 범위: 5 ~ 10 (데이터 포인트 수)
    /// - graphCount가 작을수록 그래프가 넓어짐
    func increaseGraphWidth() {
        let newCount = max(uiState.graphCount - 1, 5)
        uiState.graphCount = newCount
    }
    
    /// 그래프 폭 감소
    /// 
    /// Android의 `decreaseGraphWidth()` 메서드를 Swift로 변환
    /// - 범위: 5 ~ 10 (데이터 포인트 수)
    /// - graphCount가 작을수록 그래프가 넓어짐
    func decreaseGraphWidth() {
        let newCount = min(uiState.graphCount + 1, 10)
        uiState.graphCount = newCount
    }
    
    /// 그래프 초기화
    /// 
    /// Android의 `onResetExerciseClick()` 메서드를 Swift로 변환
    /// - Median/IQR 분석만 초기화
    /// - 누적 통계는 유지
    func onResetExerciseClick() {
        sdk.gaitAnalysisManager.reset()
    }
    
    /// 운동 세션 연장
    /// 
    /// Android의 `extendExerciseSession()` 메서드를 Swift로 변환
    /// - 목표 시간이 끝나기 전에 세션을 연장하여 자동 종료 방지
    /// - isAutoFinishEnabled를 false로 설정하여 자동 종료 방지
    /// - isSessionExtended를 true로 설정
    func extendExerciseSession() {
        isAutoFinishEnabled = false
        uiState.isSessionExtended = true
    }
    
    /// 운동 종료
    /// 
    /// Android의 `onStopExerciseClick()` 메서드를 Swift로 변환
    /// - 측정 종료 후 완료 오버레이 및 보행 기록 팝업 표시
    /// - GPS 권한이 없으면 설정 다이얼로그 표시
    func onStopExerciseClick(gotoJawsSearch: Bool = false) {
        if isStopping { return }
        isStopping = true
        pendingGotoJawsSearch = gotoJawsSearch
        
        Task { @MainActor in
            uiState.isAwaitingSave = true
            
            if pendingMetrics == nil {
                pendingMetrics = sdk.gaitAnalysisManager.stop()
                
                let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
                if let lastSegment = sessionSegments.last, lastSegment.endTime == nil {
                    sessionSegments[sessionSegments.count - 1].endTime = currentTime
                }
            }
            
            showFinishOverlay = true
            
            let currentGpsState = gpsState
            if currentGpsState.isGranted && currentGpsState.isGpsOn {
                showCommentPrompt = true
            } else {
                isStopping = false
                if !currentGpsState.isGranted {
                    uiState.locationDialogToShow = .permissionNeeded
                } else {
                    uiState.locationDialogToShow = .gpsNeeded
                }
            }
        }
    }
    
    /// 운동 데이터 저장
    /// 
    /// Android의 `saveExercise()` 메서드를 Swift로 변환
    /// - 보행 기록 팝업 확인 후 호출
    /// - pendingMetrics에 보관된 최종 분석 결과 사용 (stop() 재호출 없음)
    func saveExercise(gotoJawsSearch: Bool? = nil) {
        if isSavingProcess { return }
        isSavingProcess = true
        
        let shouldGotoJaws = gotoJawsSearch ?? pendingGotoJawsSearch
        
        showCommentPrompt = false
        showCommentInput = false
        
        Task { @MainActor in
            defer { isSavingProcess = false }
            
            guard uiState.isAwaitingSave else { return }
            guard let finalMetrics = pendingMetrics else { return }
            guard let exerciseInfo = uiState.exerciseInfo else { return }
            guard let userId = await sdk.authManager.currentUserId.first() else { return }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayDateStr = dateFormatter.string(from: Date())
            
            let sessionCount = uiState.sessionCount
            let elapsedTime = uiState.elapsedTime
            let trimmedDescription = uiState.gaitDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let recordResult = await sdk.gaitRecordManager.recordAndSyncGait(
                metrics: finalMetrics,
                exerciseInfo: exerciseInfo,
                userId: userId,
                date: todayDateStr,
                sessionCount: sessionCount,
                elapsedTime: elapsedTime,
                sessionSegments: sessionSegments.isEmpty ? nil : sessionSegments,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription
            )
            
            await sessionRepository.saveLastSessionInfo(userId: userId, date: todayDateStr, count: sessionCount)
            
            uiState.isAwaitingSave = false
            pendingMetrics = nil
            isStopping = false
            
            switch recordResult {
            case .success(let record):
                uiState.finalMetrics = finalMetrics
                uiState.gaitRecordDto = record
                uiState.sessionCount = sessionCount + 1
                resetEndFlowUiState()
                
                if shouldGotoJaws {
                    navigateToJawsSearch()
                } else {
                    navigateToResult(metrics: finalMetrics, record: record)
                }
            case .failure(let error):
                logger.debug("❌ [ExerciseSessionViewModel] 운동 저장 실패: \(error)")
                resetEndFlowUiState()
            }
        }
    }
    
    /// BLE 끊김 후 디바이스 연결 화면으로 이동
    func navigateToJawsSearch() {
        guard let coordinator = router?.coordinator else { return }
        coordinator.exercisePath = NavigationPath()
        coordinator.navigateInExercise(to: .jawsSearch)
    }
    
    /// 운동 결과 화면으로 이동 (메트릭스와 레코드 전달)
    /// 
    /// Android의 `NavigateToResult` 이벤트를 Swift로 변환
    func navigateToResult(metrics: GaitMetrics, record: GaitRecordDto) {
        router?.navigateToResult(metrics: metrics, record: record)
    }
    
    /// 운동 완료 오버레이 표시 후 결과 화면으로 이동
    /// 
    /// Android의 `emitNavigateToResult()` 메서드를 Swift로 변환
    func emitNavigateToResult() {
        if let metrics = uiState.finalMetrics, let record = uiState.gaitRecordDto {
            navigateToResult(metrics: metrics, record: record)
        }
    }
    
    // MARK: - Exercise Session Reset
    
    /// 운동 세션 상태 초기화
    /// 
    /// 새 운동을 시작할 때 이전 세션의 데이터를 초기화합니다.
    /// - 세션 세그먼트 초기화
    /// - 시간 정보 초기화
    /// - 저장 상태 초기화
    /// - 최종 메트릭스 및 레코드 초기화
    /// - 게임 상태 초기화 (점수, 콤보 등)
    /// 종료 UX 오버레이·다이얼로그 상태 초기화
    private func resetEndFlowUiState() {
        showFinishOverlay = false
        showCommentPrompt = false
        showCommentInput = false
        pendingGotoJawsSearch = false
    }
    
    /// 종료·저장 관련 플래그 초기화
    private func resetStopAndSaveFlags() {
        isStopping = false
        isSavingProcess = false
        pendingMetrics = nil
        resetEndFlowUiState()
    }
    
    private func resetExerciseSessionState() {
        // 세션 세그먼트 초기화 (이전 세션의 세그먼트가 남아있으면 안 됨)
        sessionSegments.removeAll()
        indexingStepOffset = 0
        resetStopAndSaveFlags()
        
        // 시간 정보 초기화
        uiState.elapsedTime = 0
        uiState.remainingTime = 0
        uiState.progress = 0.0

        // 인덱싱 상태 초기화
        uiState.isIndexing = true
        uiState.isIndexingSuccess = false
        uiState.showRetryMessage = false
        uiState.indexingProgress = 0
        
        // 저장 상태 초기화
        uiState.isAwaitingSave = false
        uiState.gaitDescription = ""
        
        // 최종 메트릭스 및 레코드 초기화
        uiState.finalMetrics = nil
        uiState.gaitRecordDto = nil
        
        // 세션 연장 상태 초기화
        uiState.isSessionExtended = false
        
        // 그래프 데이터 초기화
        uiState.rawGaitStream.removeAll()
        uiState.leftMedianStream.removeAll()
        uiState.leftIqrStream.removeAll()
        uiState.rightMedianStream.removeAll()
        uiState.rightIqrStream.removeAll()
        
        // 통계 데이터 초기화 (현재 운동 중인 메트릭스는 SDK가 초기화)
        uiState.gaitMetrics = nil
        
        // 게임 상태 초기화 (새 세션 시작 시 점수, 콤보 등 초기화)
        gameState = ArcadeGameState()
        gameLogicPreviousTotalSteps = 0
        previousSteps.removeAll()
    }
    
    // MARK: - Arcade Game Methods
    
    /// 게임 화면 진입 시 호출
    /// 
    /// Android의 `onGameScreenEntered()` 메서드를 Swift로 변환
    /// - 현재 총 걸음을 기준으로 게임에서 새로 점수를 올릴 기준점을 설정
    /// - 세션 중에는 게임 상태를 초기화하지 않음 (점수 유지)
    /// - 새 세션 시작 시에만 게임 상태가 초기화됨 (resetExerciseSessionState에서 처리)
    /// - 게임모드에서 나갔다가 다시 돌아온 경우, 현재 걸음 수로 기준점을 동기화하여 일시정지 중 증가한 점수가 반영되지 않도록 함
    func onGameScreenEntered() {
        Task { @MainActor in
            // 세션이 시작되지 않은 경우에만 게임 상태 초기화
            // (세션이 이미 시작된 경우에는 점수를 유지해야 함)
            if uiState.exerciseInfo == nil {
                // 세션이 시작되지 않은 경우에만 초기화
                gameState = ArcadeGameState()
                gameLogicPreviousTotalSteps = 0
                previousSteps.removeAll()
            }
            
            // 현재 총 걸음을 기준으로 게임에서 새로 점수를 올릴 기준점을 설정
            let currentMetrics = await sdk.gaitAnalysisManager.gaitMetrics.first()
            let currentSteps = currentMetrics.totalSteps
            
            // 새 세션 시작 시 (gameLogicPreviousTotalSteps == 0)
            if gameLogicPreviousTotalSteps == 0 {
                gameLogicPreviousTotalSteps = currentSteps
            } else {
                // 세션 중 게임모드 재진입 시: 일시정지 중 증가한 걸음 수는 점수에 반영하지 않도록
                // 현재 걸음 수로 기준점을 동기화 (재개 후부터 점수 증가)
                gameLogicPreviousTotalSteps = currentSteps
            }
            
            isGameActive = true
        }
        
        // GAME 모드로 세그먼트 전환
        switchSegment(newMode: .game)
    }
    
    /// 게임 화면 이탈 시 호출
    /// 
    /// Android의 `onGameScreenExited()` 메서드를 Swift로 변환
    /// - 게임 일시정지: isGameActive를 false로 설정하여 점수 증가 및 캐릭터 상태 업데이트 중지
    func onGameScreenExited() {
        // 게임 일시정지: 점수 증가 및 캐릭터 상태 업데이트 중지
        isGameActive = false
        
        // STATIC 모드로 세그먼트 전환
        switchSegment(newMode: .static)
    }
    
    /// 장애물 통과 시 호출
    /// 
    /// Android의 `onObstaclePassed()` 메서드를 Swift로 변환
    /// - 보너스 점수 추가 (10 * multiplier)
    /// - 콤보 1 증가
    func onObstaclePassed() {
        guard !gameState.isStunned else { return } // 스턴이면 점수 획득 불가
        
        // struct이므로 전체 객체를 다시 할당해야 @Published가 변경을 감지함
        var updatedState = gameState
        let bonus = Int(10 * updatedState.multiplier)
        updatedState.score += bonus
        updatedState.combo += 1
        gameState = updatedState
    }
    
    /// 장애물 충돌 시 호출
    /// 
    /// Android의 `onObstacleCollision()` 메서드를 Swift로 변환
    /// - 콤보 0으로 초기화
    /// - 3초간 스턴 상태 부여
    func onObstacleCollision() {
        guard !gameState.isStunned else { return } // 이미 스턴이면 중복 처리 안 함
        
        // struct이므로 전체 객체를 다시 할당해야 @Published가 변경을 감지함
        var updatedState = gameState
        updatedState.combo = 0
        updatedState.stunRemainingMs = 3000 // 3초 스턴
        gameState = updatedState
    }
    
    /// 스턴 시간 감소
    /// 
    /// Android의 `decreaseStunTime()` 메서드를 Swift로 변환
    /// - 게임 루프에서 매 프레임마다 호출 (약 16ms씩 감소)
    func decreaseStunTime(deltaMs: Int64) {
        guard gameState.stunRemainingMs > 0 else { return }
        
        // struct이므로 전체 객체를 다시 할당해야 @Published가 변경을 감지함
        var updatedState = gameState
        updatedState.stunRemainingMs = max(0, updatedState.stunRemainingMs - deltaMs)
        gameState = updatedState
    }
    
    /// 캐릭터 상태 업데이트 (보행 데이터 기반)
    /// 
    /// Android의 `updateCharacterState()` 메서드를 Swift로 변환
    /// - 최근 9개 걸음의 보행 유형(WALK/RUN) 히스토리 관리
    /// - 뛰기 비율 계산 및 캐릭터 위치 결정
    /// - 게임이 활성화되지 않은 경우(일시정지) 점수 증가 및 상태 업데이트 중지
    private func updateCharacterState(metrics: GaitMetrics) {
        // 게임이 활성화되지 않은 경우(게임모드에서 나간 상태) 점수 증가 및 상태 업데이트 중지
        guard isGameActive else { return }
        
        let currentTotalSteps = metrics.totalSteps
        let lastStepType = metrics.lastStepType
        
        // 걸음 수가 늘어나지 않았으면 무시
        guard currentTotalSteps > gameLogicPreviousTotalSteps else { return }
        
        // 걸음 증가 점수 처리 (콤보/배율과 무관)
        let stepDelta = currentTotalSteps - gameLogicPreviousTotalSteps
        if stepDelta > 0 {
            // struct이므로 전체 객체를 다시 할당해야 @Published가 변경을 감지함
            var updatedState = gameState
            updatedState.score += stepDelta
            gameState = updatedState
        }
        
        // 최근 보행 유형 기준 히스토리 업데이트
        if lastStepType != .none {
            previousSteps.append(lastStepType)
            if previousSteps.count > maxHistory {
                previousSteps.removeFirst()
            }
        }
        
        // 최근 패턴 기반 걷기/날기 비율 계산
        let walkCount = previousSteps.filter { $0 == .walk }.count
        let runCount = previousSteps.filter { $0 == .run }.count
        
        let validHistorySize = max(1, walkCount + runCount)
        let rawRunRatio = Float(runCount) / Float(validHistorySize)
        
        let minRunRatio: Float = 0.35
        let maxRunRatio: Float = 0.8
        let rawAdjustedRatio = (rawRunRatio - minRunRatio) / (maxRunRatio - minRunRatio)
        let adjustedRunRatio = min(max(rawAdjustedRatio, 0), 1)
        
        let floorBias: Float = 0.95 // 바닥 위치
        let skyBias: Float = -0.7   // 하늘 위치
        
        let targetBias = floorBias + (skyBias - floorBias) * adjustedRunRatio
        let displayType: DisplayStepType = targetBias >= 0.94 ? .walk : .fly
        
        uiState.displayStepType = displayType
        uiState.targetCharacterBias = targetBias
        
        gameLogicPreviousTotalSteps = currentTotalSteps
    }
    
    /// 현재 운동 모드(구간)를 새로운 모드로 전환하고, 이를 세션 리스트에 기록합니다.
    /// 
    /// Android의 `switchSegment()` 메서드를 Swift로 변환
    /// 이 함수를 통해 생성된 구간 정보는 추후 데이터 분석 시,
    /// 보행 분석이 가능한 구간(STATIC)과 게임 중인 구간(GAME)을 타임스탬프 기준으로 정확히 분리하는 데 사용됩니다.
    /// 
    /// - Parameter newMode: 전환할 새로운 운동 모드 (`.index`, `.static`, `.game`)
    func switchSegment(newMode: ExerciseMode) {
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        
        // 리스트가 있으면 -> 마지막 구간의 endTime을 기록
        if let lastSegment = sessionSegments.last {
            // 같은 모드면 전환하지 않음
            if lastSegment.mode == newMode {
                return
            }
            
            // 마지막 구간의 endTime이 nil이면 현재 시간으로 설정
            if lastSegment.endTime == nil {
                sessionSegments[sessionSegments.count - 1].endTime = currentTime
            }
        }
        
        // 새 구간 추가
        sessionSegments.append(
            SessionSegment(startTime: currentTime, mode: newMode)
        )
    }
}

// MARK: - String Extensions

extension String {
    /// 문자열을 Int로 변환 (실패 시 nil)
    func toIntOrNull() -> Int? {
        Int(self)
    }
}

// MARK: - Combine Extensions

extension Publisher {
    /// Publisher의 첫 번째 값을 가져옵니다.
    /// 
    /// Android의 `Flow.first()`를 Swift로 변환
    /// 
    /// **주의**: continuation이 여러 번 resume되지 않도록 보장합니다.
    func first() async -> Output {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            var hasResumed = false
            
            cancellable = self
                .sink(
                    receiveCompletion: { _ in
                        cancellable?.cancel()
                        // completion에서는 resume하지 않음 (이미 값이 emit되었거나 nil 처리 필요)
                    },
                    receiveValue: { value in
                        cancellable?.cancel()
                        // 한 번만 resume되도록 보장
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(returning: value)
                        }
                    }
                )
        }
    }
}

