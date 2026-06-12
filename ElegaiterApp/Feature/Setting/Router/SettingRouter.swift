//
//  SettingRouter.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

/// Setting Feature Router
@MainActor
class SettingRouter: ObservableObject {
    weak var coordinator: AppCoordinator?
    
    enum Route: Hashable {
        case setting
        case achievement
        case accountEdit
        case stepGoal
        case deviceError
        case terms
        case resetPassword
        case appLanguage
    }
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    func navigate(to route: Route) {
        coordinator?.navigateInSetting(to: .settingGraph(route))
    }
    
    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .setting:
            SettingView()
        case .achievement:
            AchievementView()
        case .accountEdit:
            AccountEditView()
        case .stepGoal:
            StepGoalView()
        case .deviceError:
            DeviceErrorView()
        case .terms:
            TermsView()
        case .resetPassword:
            ResetPwView(requiresCurrentPassword: true)
        case .appLanguage:
            AppLanguageView()
        }
    }
}
