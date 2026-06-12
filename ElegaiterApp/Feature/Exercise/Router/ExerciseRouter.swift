//
//  ExerciseRouter.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

/// Exercise Feature Router
/// 
/// ExerciseGraph 내부 Route들을 관리합니다.
/// Android의 구조와 일관성을 위해 ExerciseSessionViewModel을 공유합니다.
@MainActor
class ExerciseRouter: ObservableObject {
    weak var coordinator: AppCoordinator?
    
    /// 공유되는 운동 세션 ViewModel
    /// 
    /// 여러 화면에서 공유되는 세션 관리 ViewModel
    /// Android의 구조와 일관성을 위해 Router에서 관리합니다.
    let sessionViewModel: ExerciseSessionViewModel
    
    // ExerciseGraph 내부 Route들 (startDestination: info)
    enum Route: Hashable {
        case info              // startDestination
        case infoIndexWalking
        case indexWalking
        case realTime
        case arcade            // 게임 모드 (아케이드)
        // result는 그래프 외부이므로 포함하지 않음
    }
    
    init(coordinator: AppCoordinator, sessionViewModel: ExerciseSessionViewModel? = nil) {
        self.coordinator = coordinator
        self.sessionViewModel = sessionViewModel ?? ExerciseSessionViewModel()
        self.sessionViewModel.router = self
    }
    
    // ExerciseGraph 내부 네비게이션
    func navigate(to route: Route) {
        coordinator?.navigateInExercise(to: .exerciseGraph(route))
    }
    
    // ExerciseResult는 그래프 외부, 다중 진입점 (Coordinator에서 직접 관리)
    /// fileName으로 결과 화면으로 이동
    /// 
    /// Route에는 ID만 전달하고, 실제 데이터는 ViewModel에서 조회합니다.
    /// 안드로이드 분석 문서에 따르면: "백스택에서 ExerciseGraph까지 모든 화면 제거"
    func navigateToResult(fileName: String) {
        coordinator?.navigateToExerciseResult(fileName: fileName)
    }
    
    /// metrics와 record로 결과 화면으로 이동
    /// 
    /// RealTimeExercise에서 사용하는 메서드
    /// metrics와 record를 Coordinator에 임시 저장하고 fileName으로 네비게이션합니다.
    /// 안드로이드 분석 문서에 따르면: "백스택에서 ExerciseGraph까지 모든 화면 제거"
    func navigateToResult(metrics: GaitMetrics, record: GaitRecordDto) {
        coordinator?.exerciseResultData = (metrics: metrics, record: record)
        navigateToResult(fileName: record.fileName)
    }
    
    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .info:
            ExerciseInfoView(router: self, viewModel: sessionViewModel)
        case .infoIndexWalking:
            InfoIndexWalkingView(router: self, viewModel: sessionViewModel)
        case .indexWalking:
            IndexWalkingView(router: self, viewModel: sessionViewModel)
        case .realTime:
            RealTimeExerciseView(router: self, viewModel: sessionViewModel)
        case .arcade:
            ArcadeView(router: self, viewModel: sessionViewModel)
        }
    }
}

