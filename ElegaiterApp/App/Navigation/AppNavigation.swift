//
//  AppNavigation.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK
import Combine
import os.log

/// 커스텀 탭바 + NavigationStack 통합 설정
///
/// Android의 `ElegaiterNavHost`를 SwiftUI로 변환
/// - 로그인 전: 단일 NavigationStack (탭바 없음)
/// - 로그인 후: 커스텀 탭바 + 각 탭별 NavigationStack
///
/// TabView를 사용하지 않고 직접 구현하여 기본 탭바가 생성되지 않도록 함
struct AppNavigation: View {

    private static let logger = Logger(subsystem: "com.elegaiter.app", category: "AppNavigation")

    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var permissionMonitor = PermissionMonitorManager()
    
    /// 네트워크 모니터 인스턴스
    private let networkMonitor = NetworkMonitorImpl()
    
    /// 네트워크 온라인 상태
    @State private var isOnline: Bool = false
    
    /// SDK 인스턴스
    private let sdk = SDKManager.shared.sdk
    
    /// 네트워크 상태 구독 취소용
    @State private var networkCancellable: AnyCancellable?
    
    /// 세션 만료 처리 중복 방지 플래그
    @State private var isHandlingSessionExpiration: Bool = false
    // 키보드 프리로드 관련 (현재 비활성화)
    // @FocusState private var keyboardPreloadFocus: Bool
    // @State private var hasKeyboardPreloaded = false
    
    /// 탭바 아이템 정의
    private var tabBarItems: [ElegaiterTabBar.TabItem] {
        [
            ElegaiterTabBar.TabItem(
                id: 0,
                title: "HOME",
                icon: "IcHomeNormal",
                selectedIcon: "IcHomeSelected",
                onClick: {
                    coordinator.selectedTab = .exercise
                }
            ),
            ElegaiterTabBar.TabItem(
                id: 1,
                title: "RECORD",
                icon: "IcRecordNormal",
                selectedIcon: "IcRecordSelected",
                onClick: {
                    coordinator.selectedTab = .history
                }
            ),
            ElegaiterTabBar.TabItem(
                id: 2,
                title: "MY",
                icon: "IcMyNormal",
                selectedIcon: "IcMySelected",
                onClick: {
                    coordinator.selectedTab = .setting
                }
            )
        ]
    }
    
    /// 현재 선택된 탭의 ID
    private var selectedTabId: Int {
        switch coordinator.selectedTab {
        case .exercise: return 0
        case .history: return 1
        case .setting: return 2
        }
    }
    
    // 키보드 프리로드 관련 (현재 비활성화)
    // /// 키보드 프리로드를 실행해야 하는지 확인
    // /// 
    // /// 입력 필드가 있는 화면(로그인, 회원가입, 계정 찾기 등)에서만 true 반환
    // private var shouldPreloadKeyboard: Bool {
    //     // 로그인 전 화면에서만 실행
    //     guard !coordinator.isLoggedIn else { return false }
    //     
    //     // mainPath가 비어있으면 Splash 화면이므로 실행하지 않음
    //     guard !coordinator.mainPath.isEmpty else { return false }
    //     
    //     // NavigationPath에서 마지막 Route를 직접 가져올 수 없으므로,
    //     // mainPath의 count를 확인하여 Splash 이후 화면인지 확인
    //     // 실제로는 각 화면(LoginView, SignUpView 등)에서 자체적으로 프리로드를 처리하므로
    //     // 여기서는 실행하지 않음
    //     return false
    // }
    
    var body: some View {
        Group {
            if coordinator.isLoggedIn {
                // 로그인 후: 커스텀 탭바 사용 (TabView 없이 직접 구현)
                ZStack(alignment: .bottom) {
                // 모든 탭 뷰를 미리 생성하고 표시/숨김만 제어 (뷰 재사용으로 스크롤 위치 유지)
                // EXERCISE 탭
                NavigationStack(path: $coordinator.exercisePath) {
                    ExerciseReadyView()
                        .navigationDestination(for: AppCoordinator.Route.self) { route in
                            coordinator.view(for: route)
                        }
                }
                .opacity(coordinator.selectedTab == .exercise ? 1 : 0)
                .zIndex(coordinator.selectedTab == .exercise ? 1 : 0)
                .allowsHitTesting(coordinator.selectedTab == .exercise)
                
                // HISTORY 탭
                NavigationStack(path: $coordinator.historyPath) {
                    HistoryView()
                        .navigationDestination(for: AppCoordinator.Route.self) { route in
                            coordinator.view(for: route)
                        }
                }
                .opacity(coordinator.selectedTab == .history ? 1 : 0)
                .zIndex(coordinator.selectedTab == .history ? 1 : 0)
                .allowsHitTesting(coordinator.selectedTab == .history)
                
                // SETTING 탭
                NavigationStack(path: $coordinator.settingPath) {
                    SettingView()
                        .navigationDestination(for: AppCoordinator.Route.self) { route in
                            coordinator.view(for: route)
                        }
                }
                .opacity(coordinator.selectedTab == .setting ? 1 : 0)
                .zIndex(coordinator.selectedTab == .setting ? 1 : 0)
                .allowsHitTesting(coordinator.selectedTab == .setting)
                
                // 커스텀 Elegaiter Tab Bar (shouldShowTabBar가 true일 때만 표시)
                // zIndex를 높게 설정하여 항상 위에 표시되도록 함
                if coordinator.shouldShowTabBar {
                    VStack {
                        Spacer()
                        ElegaiterTabBar(
                            items: tabBarItems,
                            selectedTabId: selectedTabId
                        )
                    }
                    .zIndex(100) // 탭바가 항상 위에 표시되도록 높은 zIndex 설정
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinator.shouldShowTabBar)
            .onChange(of: coordinator.exercisePath) { newPath in
                // 각 탭의 root 경로에서만 TabBar 표시, 나머지는 모두 숨김
                coordinator.shouldShowTabBar = newPath.isEmpty
            }
            .onChange(of: coordinator.historyPath) { newPath in
                // 각 탭의 root 경로에서만 TabBar 표시, 나머지는 모두 숨김
                coordinator.shouldShowTabBar = newPath.isEmpty
            }
            .onChange(of: coordinator.settingPath) { newPath in
                // 각 탭의 root 경로에서만 TabBar 표시, 나머지는 모두 숨김
                coordinator.shouldShowTabBar = newPath.isEmpty
            }
            .onChange(of: coordinator.selectedTab) { _ in
                // 탭 전환 시 현재 선택된 탭의 경로 상태에 따라 TabBar 표시/숨김
                switch coordinator.selectedTab {
                case .exercise:
                    coordinator.shouldShowTabBar = coordinator.exercisePath.isEmpty
                case .history:
                    coordinator.shouldShowTabBar = coordinator.historyPath.isEmpty
                case .setting:
                    coordinator.shouldShowTabBar = coordinator.settingPath.isEmpty
                }
            }
            .environmentObject(coordinator)
            .onAppear {
                // 네트워크 상태 구독 시작
                observeNetworkState()
                
                // 앱 실행 시점에 레코드 통계 로그 출력
                logRecordStats()
            }
            .onChange(of: isOnline) { newValue in
                // 네트워크가 온라인 상태가 되면 대기 중인 기록 동기화
                // Android의 LaunchedEffect(isOnline) { if (isOnline) syncPendingData() }와 동일한 로직
                if newValue {
                    syncPendingRecords()
                }
            }
            .overlay {
                // 전역 토스트 오버레이
                GlobalToastView(toastManager: ToastManager.shared)
                
                // 필수 권한 요청 팝업
                if permissionMonitor.showPermissionRequiredPopup {
                    PermissionRequiredPopup(
                        isPresented: $permissionMonitor.showPermissionRequiredPopup,
                        onSettings: {
                            permissionMonitor.openAppSettings()
                        }
                    )
                }
            }
            
        } else {
            // 로그인 전: 단일 NavigationStack (TabView 없음)
            NavigationStack(path: $coordinator.mainPath) {
                // SplashView 표시 조건: mainPath가 비어있고 shouldShowSplash가 true일 때만
                // shouldShowSplash가 false이면 루트 뷰를 숨김 (뒤로가기 버튼 방지)
                Group {
                    if coordinator.mainPath.isEmpty && coordinator.shouldShowSplash {
                        SplashView()
                    } else {
                        // mainPath에 route가 있으면 navigationDestination에서 처리됨
                        // 루트 뷰를 숨기기 위해 투명한 뷰 사용
                        Color.clear
                    }
                }
                .navigationDestination(for: AppCoordinator.Route.self) { route in
                    coordinator.view(for: route)
                }
            }
            .environmentObject(coordinator)
            .onAppear {
                // 네트워크 상태 구독 시작
                observeNetworkState()
                
                // 앱 실행 시점에 레코드 통계 로그 출력
                logRecordStats()
            }
            .onChange(of: isOnline) { newValue in
                // 네트워크가 온라인 상태가 되면 대기 중인 기록 동기화
                // Android의 LaunchedEffect(isOnline) { if (isOnline) syncPendingData() }와 동일한 로직
                if newValue {
                    syncPendingRecords()
                }
            }
            .overlay {
                // 전역 토스트 오버레이
                GlobalToastView(toastManager: ToastManager.shared)
                
                // 필수 권한 요청 팝업
                if permissionMonitor.showPermissionRequiredPopup {
                    PermissionRequiredPopup(
                        isPresented: $permissionMonitor.showPermissionRequiredPopup,
                        onSettings: {
                            permissionMonitor.openAppSettings()
                        }
                    )
                }
            }
            // MARK: - 키보드 프리로드 (현재 비활성화)
            // 
            // 문제점:
            // 1. 입력 필드가 없는 화면(SplashView 등)에서도 키보드가 올라옴
            // 2. 타이밍이 맞지 않아 예상치 못한 시점에 키보드가 표시됨
            // 3. 화면 전환 시마다 onAppear가 호출되어 중복 실행됨
            //
            // 해결 방안:
            // - 각 화면(LoginView, SignUpView 등)에서 필요할 때만 자체적으로 프리로드 처리
            // - 전역 프리로드는 제거하고 각 화면의 onAppear에서 처리하도록 변경
            //
            // .background(
            //     // 키보드 프리로드를 위한 숨겨진 TextField
            //     // 입력 필드가 있는 화면(로그인, 회원가입 등)에서만 실행되도록 조건 추가
            //     // 한 번만 실행되도록 hasKeyboardPreloaded 플래그 사용
            //     Group {
            //         if shouldPreloadKeyboard {
            //             TextField("", text: .constant(""))
            //                 .keyboardType(.default)
            //                 .opacity(0)
            //                 .frame(width: 0, height: 0)
            //                 .focused($keyboardPreloadFocus)
            //                 .onAppear {
            //                     // 이미 프리로드가 실행되었으면 건너뜀
            //                     guard !hasKeyboardPreloaded else { return }
            //                     
            //                     // 키보드 프리로드: 입력 필드가 있는 화면에서만 실행
            //                     // 앱 시작 후 짧은 지연(0.5초)을 두고 키보드를 잠시 활성화했다가 비활성화
            //                     // 이렇게 하면 키보드가 메모리에 로드되어 첫 터치 시 빠르게 표시됨
            //                     Task { @MainActor in
            //                         // 화면이 완전히 로드될 때까지 대기
            //                         try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
            //                         
            //                         // 이미 실행되었는지 다시 확인 (화면 전환 중일 수 있음)
            //                         guard !hasKeyboardPreloaded else { return }
            //                         
            //                         hasKeyboardPreloaded = true
            //                         keyboardPreloadFocus = true
            //                         
            //                         // 매우 짧게 활성화했다가 즉시 비활성화
            //                         try? await Task.sleep(nanoseconds: 10_000_000) // 0.01초
            //                         keyboardPreloadFocus = false
            //                     }
            //                 }
            //         }
            //     }
            // )
            }
        }
        .onReceive(sdk.authManager.sessionExpiredEvent.receive(on: DispatchQueue.main)) { _ in
            handleSessionExpired()
        }
    }
    
    // MARK: - Private Methods
    
    /// 네트워크 상태 관찰
    /// 
    /// Android의 `LaunchedEffect(isOnline)`와 동일한 역할
    /// 네트워크 상태 변화를 감지하여 `isOnline` 상태를 업데이트합니다.
    private func observeNetworkState() {
        // 기존 구독이 있으면 취소
        networkCancellable?.cancel()
        
        // 새로운 구독 시작
        networkCancellable = networkMonitor.isOnline
            .receive(on: DispatchQueue.main)
            .sink { [self] online in
                self.isOnline = online
            }
    }
    
    /// 대기 중인 기록 동기화
    /// 
    /// Android의 `syncPendingData()`와 동일한 역할
    /// PENDING 상태인 운동 기록을 서버에 동기화합니다.
    private func syncPendingRecords() {
        Task {
            let result = await sdk.gaitRecordManager.syncPendingRecords()
            
            switch result {
            case .success(let count):
                if count > 0 {
                    Self.logger.debug("✅ [AppNavigation] 대기 중인 기록 \(count)개 동기화 완료")
                }
            case .failure(let error):
                Self.logger.debug("⚠️ [AppNavigation] 대기 중인 기록 동기화 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// 레코드 통계 로그 출력
    /// 
    /// 앱 실행 시점에 동기화된 레코드와 펜딩 중인 레코드 개수를 출력합니다.
    private func logRecordStats() {
        Task {
            let result = await sdk.gaitRecordManager.getRecordStats()
            
            switch result {
            case .success(let stats):
                Self.logger.debug("📊 [AppNavigation] 레코드 통계 - 동기화 완료: \(stats.syncedCount)개, 펜딩 중: \(stats.pendingCount)개")
            case .failure(let error):
                Self.logger.debug("⚠️ [AppNavigation] 레코드 통계 조회 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// 앱 전역 세션 만료 처리
    ///
    /// Android의 `ElegaiterNavHost`가 `sessionExpiredEvent`를 감지하는 것과 동일한 역할입니다.
    private func handleSessionExpired() {
        guard !isHandlingSessionExpiration else { return }
        
        isHandlingSessionExpiration = true
        ToastManager.shared.show(message: "session_expired".localized())
        Self.logger.debug("⚠️ [AppNavigation] 세션 만료 이벤트 수신")
        
        Task {
            await sdk.authManager.logout()
            
            await MainActor.run {
                coordinator.logout()
                isHandlingSessionExpiration = false
            }
        }
    }
}

#Preview {
    AppNavigation()
}

