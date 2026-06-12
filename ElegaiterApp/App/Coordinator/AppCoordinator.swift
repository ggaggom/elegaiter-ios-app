//
//  AppCoordinator.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

/// 메인 Coordinator
/// 
/// 앱 전체의 네비게이션을 관리합니다.
/// - 각 탭별 독립적인 NavigationPath 관리 (Top Level Destinations)
/// - 메인 네비게이션 경로 관리 (Splash, Login 등)
/// - 복잡한 백스택 관리
@MainActor
class AppCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    // 로그인 전 네비게이션
    @Published var mainPath = NavigationPath()
    @Published var shouldShowSplash = true
    
    // 로그인 후 네비게이션 (각 탭별 독립적인 스택)
    @Published var exercisePath = NavigationPath()
    @Published var historyPath = NavigationPath()
    @Published var settingPath = NavigationPath()
    
    // 앱 상태
    @Published var selectedTab: TopLevelDestination = .exercise
    @Published var isLoggedIn: Bool = false
    
    // 화면 새로고침 플래그
    @Published var shouldRefreshExerciseReady: Bool = false
    
    // 커스텀 탭바 표시 여부
    /// 로그인 후에도 특정 화면(threshold, exerciseResult 등)에서는 탭바를 숨겨야 함
    @Published var shouldShowTabBar: Bool = true
    
    // MARK: - Private Properties
    
    /// 뒤로가기 버튼을 숨겨야 하는 Route 집합
    /// 
    /// NavigationStack의 루트 뷰(SplashView 등)가 백스택에 남아있어서
    /// 뒤로가기 버튼이 표시되는 것을 방지하기 위해 사용합니다.
    /// - navigateFromSplash: SplashView에서 이동한 화면
    /// - logout: 로그아웃 후 LoginView
    private var routesWithoutBackButton: Set<Route> = []
    
    /// 회원가입 ViewModel 임시 저장 (SignUpView → SignUpInfoView 전달용)
    /// 
    /// 실무적 접근: NavigationStack의 제약으로 인해 ViewModel을 Route로 전달하기 어려우므로,
    /// 화면 간 데이터 전달을 위한 최소한의 임시 저장소로 사용합니다.
    /// 회원가입 플로우가 완료되면 자동으로 정리됩니다.
    private var signUpViewModel: SignUpViewModel?
    
    /// 비밀번호 찾기 ViewModel 임시 저장 (FindPwView → ResetPwView 전달용)
    /// 
    /// FindPw 화면에서 인증된 아이디를 ResetPw 화면에서 사용하기 위해 ViewModel을 공유합니다.
    /// 비밀번호 재설정 플로우가 완료되면 자동으로 정리됩니다.
    private var findPwViewModel: FindPwViewModel?
    
    /// 운동 결과 데이터 임시 저장 (RealTimeExercise → ExerciseResult 전달용)
    /// 
    /// RealTimeExercise 화면에서 운동 완료 후 결과 화면으로 이동할 때
    /// metrics와 record를 전달하기 위해 임시 저장합니다.
    var exerciseResultData: (metrics: GaitMetrics, record: GaitRecordDto)?
    
    /// ExerciseResult로 이동하기 전의 탭 (뒤로가기 시 돌아갈 탭)
    /// 
    /// History에서 ExerciseResult로 이동한 경우 .history로 설정
    /// RealTimeExercise에서 ExerciseResult로 이동한 경우 nil (기본 동작)
    var exerciseResultSourceTab: TopLevelDestination?
    
    // MARK: - Feature Routers
    
    lazy var exerciseRouter = ExerciseRouter(coordinator: self)
    lazy var historyRouter = HistoryRouter(coordinator: self)
    lazy var settingRouter = SettingRouter(coordinator: self)
    
    // MARK: - Enums
    
    enum TopLevelDestination {
        case exercise
        case history
        case setting
    }
    
    enum Route: Hashable {
        // 인증 관련
        case splash
        case login
        case permission
        case jawsSearch
        case threshold
        
        // 회원가입 (SignUpGraph - 중첩 그래프)
        case toS
        case signUp
        case signUpInfo
        
        // 계정 찾기
        case findId
        case findPw
        case resetPw(requiresCurrentPassword: Bool)
        
        // Exercise (중첩 그래프)
        case exerciseReady
        case exerciseGraph(ExerciseRouter.Route)
        case exerciseResult(fileName: String)  // ID만 전달, 데이터는 ViewModel에서 조회
        
        // History (중첩 그래프)
        case historyGraph(HistoryRouter.Route)
        
        // Setting
        case setting
        case settingGraph(SettingRouter.Route)
        
        // MARK: - Hashable Implementation
        
        /// GaitMetrics와 GaitRecordDto가 Hashable을 준수하지 않으므로 수동 구현
        func hash(into hasher: inout Hasher) {
            switch self {
            case .splash: hasher.combine(0)
            case .login: hasher.combine(1)
            case .permission: hasher.combine(2)
            case .jawsSearch: hasher.combine(3)
            case .threshold: hasher.combine(4)
            case .toS: hasher.combine(5)
            case .signUp: hasher.combine(6)
            case .signUpInfo: hasher.combine(7)
            case .findId: hasher.combine(8)
            case .findPw: hasher.combine(9)
            case .resetPw(let requiresCurrentPassword):
                hasher.combine(10)
                hasher.combine(requiresCurrentPassword)
            case .exerciseReady: hasher.combine(11)
            case .exerciseGraph(let route):
                hasher.combine(12)
                hasher.combine(route)
            case .exerciseResult(let fileName):
                hasher.combine(13)
                hasher.combine(fileName)
            case .historyGraph(let route):
                hasher.combine(14)
                hasher.combine(route)
            case .setting: hasher.combine(15)
            case .settingGraph(let route):
                hasher.combine(16)
                hasher.combine(route)
            }
        }
        
        // MARK: - Equatable Implementation
        
        /// GaitMetrics와 GaitRecordDto가 Equatable을 준수하므로 사용 가능
        static func == (lhs: Route, rhs: Route) -> Bool {
            switch (lhs, rhs) {
            case (.splash, .splash),
                 (.login, .login),
                 (.permission, .permission),
                 (.jawsSearch, .jawsSearch),
                 (.threshold, .threshold),
                 (.toS, .toS),
                 (.signUp, .signUp),
                 (.signUpInfo, .signUpInfo),
                 (.findId, .findId),
                 (.findPw, .findPw),
                 (.exerciseReady, .exerciseReady),
                 (.setting, .setting):
                return true
            case (.resetPw(let lhsValue), .resetPw(let rhsValue)):
                return lhsValue == rhsValue
            case (.exerciseGraph(let lhsRoute), .exerciseGraph(let rhsRoute)):
                return lhsRoute == rhsRoute
            case (.exerciseResult(let lhsFileName), .exerciseResult(let rhsFileName)):
                return lhsFileName == rhsFileName
            case (.historyGraph(let lhsRoute), .historyGraph(let rhsRoute)):
                return lhsRoute == rhsRoute
            case (.settingGraph(let lhsRoute), .settingGraph(let rhsRoute)):
                return lhsRoute == rhsRoute
            default:
                return false
            }
        }
    }
    
    // MARK: - Tab Management
    
    /// 탭 전환 (백스택 유지)
    func switchTab(to destination: TopLevelDestination) {
        selectedTab = destination
    }
    
    // MARK: - Navigation Methods
    
    /// 각 탭의 네비게이션
    func navigateInExercise(to route: Route) {
        exercisePath.append(route)
    }
    
    /// ExerciseResult 화면으로 이동 (백스택 정리 포함)
    /// 
    /// 안드로이드 분석 문서에 따르면: "백스택에서 ExerciseGraph까지 모든 화면 제거"
    /// ExerciseGraph 내부 화면들(Info, InfoIndexWalking, IndexWalking, RealTime)을 모두 제거하고
    /// ExerciseReady만 남긴 후 ExerciseResult를 추가합니다.
    /// 
    /// ExerciseReadyView는 NavigationStack의 root이므로 exercisePath에 포함되지 않습니다.
    /// 따라서 exercisePath가 비어있으면 exerciseResult만 추가하고,
    /// 비어있지 않으면 경로를 정리한 후 exerciseResult만 추가합니다.
    func navigateToExerciseResult(fileName: String) {
        // ExerciseReadyView는 NavigationStack의 root이므로 exercisePath에 포함되지 않음
        // exercisePath가 비어있으면 exerciseResult만 추가
        // 비어있지 않으면 경로를 정리한 후 exerciseResult만 추가
        
        var newPath = NavigationPath()
        
        // ExerciseResult만 추가 (ExerciseReady는 root이므로 경로에 포함하지 않음)
        newPath.append(Route.exerciseResult(fileName: fileName))
        
        // 새로운 경로로 교체
        // TabBar 표시/숨김은 AppNavigation의 onChange에서 경로 기반으로 자동 처리
        exercisePath = newPath
    }
    
    func navigateInHistory(to route: Route) {
        historyPath.append(route)
    }
    
    func navigateInSetting(to route: Route) {
        settingPath.append(route)
    }
    
    /// 메인 네비게이션 (Splash, Login 등)
    func navigateInMain(to route: Route) {
        // 다른 화면으로 이동하면 routesWithoutBackButton에서 제거
        // (백스택에 쌓이면 뒤로가기 버튼 표시 가능)
        routesWithoutBackButton.remove(route)
        mainPath.append(route)
    }
    
    /// SplashView에서 이동 시 백스택 초기화 (뒤로가기 불가)
    /// 
    /// SplashView를 백스택에서 완전히 제거하고 새로운 화면으로 이동합니다.
    /// SplashView는 NavigationStack의 루트에 있기 때문에, 명시적으로 뒤로가기 버튼을 숨겨야 합니다.
    func navigateFromSplash(to route: Route) {
        shouldShowSplash = false
        mainPath = NavigationPath()
        routesWithoutBackButton.insert(route)
        mainPath.append(route)
    }
    
    /// 로그아웃 처리
    /// 
    /// 로그인 상태를 해제하고 LoginView로 이동합니다.
    /// TabView가 사라지고 단일 NavigationStack으로 전환됩니다.
    func logout() {
        isLoggedIn = false
        
        // 모든 탭의 백스택 초기화
        exercisePath = NavigationPath()
        historyPath = NavigationPath()
        settingPath = NavigationPath()
        
        // 메인 네비게이션 초기화 및 LoginView로 이동
        // 로그아웃 후 LoginView는 뒤로가기 버튼이 없어야 함 (설정 화면으로 돌아갈 수 없음)
        mainPath = NavigationPath()
        shouldShowSplash = false
        routesWithoutBackButton.insert(.login)
        mainPath.append(Route.login)
    }
    
    // MARK: - Back Stack Management
    
    /// 복잡한 백스택 관리 (안드로이드의 popUpTo 대응)
    func popToRoute(in path: Binding<NavigationPath>, route: Route, inclusive: Bool = false) {
        // TODO: 특정 Route까지 백스택 제거 구현
    }
    
    /// 백스택에서 마지막 화면 제거
    func pop(in path: Binding<NavigationPath>) {
        if !path.wrappedValue.isEmpty {
            path.wrappedValue.removeLast()
        }
    }
    
    /// 특정 Route까지 백스택에서 제거하고 새로운 Route로 이동 (안드로이드의 popUpTo + navigate 대응)
    /// 
    /// - Parameters:
    ///   - popToRoute: 제거할 Route (inclusive가 true면 이 Route도 제거)
    ///   - navigateToRoute: 이동할 새로운 Route
    ///   - inclusive: popToRoute도 함께 제거할지 여부
    func popToRouteAndNavigate(popToRoute: Route, navigateToRoute: Route, inclusive: Bool = true) {
        // mainPath를 로그인 화면까지만 유지하고 새로운 Route로 이동
        // 안드로이드의 popUpTo<FindIdRoute> { inclusive = true }와 동일한 동작
        // 로그인 화면은 백스택에 유지하여 뒤로가기 시 로그인 화면으로 돌아가도록 함
        var newPath = NavigationPath()
        newPath.append(Route.login)
        routesWithoutBackButton.remove(navigateToRoute)
        newPath.append(navigateToRoute)
        mainPath = newPath
    }
    
    // MARK: - SignUp ViewModel 관리
    
    /// SignUpViewModel 저장 (SignUpView → SignUpInfoView 전달용)
    func setSignUpViewModel(_ viewModel: SignUpViewModel) {
        self.signUpViewModel = viewModel
    }
    
    /// SignUpViewModel 가져오기
    func getSignUpViewModel() -> SignUpViewModel? {
        return signUpViewModel
    }
    
    /// SignUpViewModel 정리 (회원가입 완료 후)
    func clearSignUpViewModel() {
        self.signUpViewModel = nil
    }
    
    // MARK: - FindPw ViewModel 관리
    
    /// FindPwViewModel 저장 (FindPwView → ResetPwView 전달용)
    func setFindPwViewModel(_ viewModel: FindPwViewModel) {
        self.findPwViewModel = viewModel
    }
    
    /// FindPwViewModel 가져오기
    func getFindPwViewModel() -> FindPwViewModel? {
        return findPwViewModel
    }
    
    /// FindPwViewModel 정리 (비밀번호 재설정 완료 후)
    func clearFindPwViewModel() {
        self.findPwViewModel = nil
    }
    
    // MARK: - Tab Bar Visibility
    
    /// 특정 Route에서 탭바를 숨겨야 하는지 확인
    /// 
    // MARK: - View Factory
    
    /// Route에 해당하는 View 생성
    @ViewBuilder
    func view(for route: Route) -> some View {
        let baseView = viewContent(for: route)
        
        // 뒤로가기 버튼을 숨겨야 하는 Route인지 확인
        // (SplashView나 로그아웃 후 LoginView 등, NavigationStack의 루트가 백스택에 남아있는 경우)
        let contentWithBackButton = Group {
            if routesWithoutBackButton.contains(route) {
                baseView.navigationBarBackButtonHidden(true)
            } else {
                baseView
            }
        }
        
        // 탭바 표시/숨김은 AppNavigation의 onChange에서 경로 기반으로 처리
        // 각 탭의 root 경로에서만 TabBar 표시, 나머지는 모두 숨김
        contentWithBackButton
    }
    
    /// Route에 해당하는 기본 View 생성 (내부 헬퍼)
    @ViewBuilder
    private func viewContent(for route: Route) -> some View {
        switch route {
        case .splash:
            SplashView()
        case .login:
            LoginView()
        case .permission:
            PermissionView()
        case .jawsSearch:
            JawsSearchView()
        case .threshold:
            ThresholdView()
        case .toS:
            ToSView()
        case .signUp:
            SignUpView()
        case .signUpInfo:
            // SignUpView에서 생성한 ViewModel을 사용
            if let viewModel = signUpViewModel {
                SignUpInfoView(viewModel: viewModel)
            } else {
                // ViewModel이 없는 경우 (직접 접근한 경우) 새로 생성
                SignUpInfoView(viewModel: SignUpViewModel(coordinator: self))
            }
        case .findId:
            FindIdView()
        case .findPw:
            FindPwView()
        case .resetPw(let requiresCurrentPassword):
            // FindPwView에서 생성한 ViewModel을 사용 (비밀번호 찾기 모드)
            // 마이페이지 모드인 경우 새로운 ViewModel 생성
            if let viewModel = findPwViewModel, !requiresCurrentPassword {
                ResetPwView(requiresCurrentPassword: requiresCurrentPassword, viewModel: viewModel)
            } else {
                // 마이페이지 모드이거나 ViewModel이 없는 경우 새로 생성
                ResetPwView(requiresCurrentPassword: requiresCurrentPassword)
            }
        case .exerciseReady:
            ExerciseReadyView()
        case .exerciseGraph(let route):
            exerciseRouter.view(for: route)
        case .exerciseResult(let fileName):
            // 임시 저장된 데이터가 있으면 사용, 없으면 fileName으로 로드
            Group {
                if let resultData = exerciseResultData {
                    let metrics = resultData.metrics
                    let record = resultData.record
                    ExerciseResultView(metrics: metrics, record: record, coordinator: self)
                        .onAppear {
                            // View가 나타난 후 데이터 정리
                            self.exerciseResultData = nil
                        }
                } else {
                    ExerciseResultView(fileName: fileName, coordinator: self)
                }
            }
        case .historyGraph(let route):
            historyRouter.view(for: route)
        case .setting:
            SettingView()
        case .settingGraph(let route):
            settingRouter.view(for: route)
        }
    }
}
