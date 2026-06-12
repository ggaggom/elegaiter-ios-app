//
//  HistoryRouter.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

/// History Feature Router
@MainActor
class HistoryRouter: ObservableObject {
    weak var coordinator: AppCoordinator?
    
    enum Route: Hashable {
        case history
        case dailySession(selectedDate: String)
    }
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    func navigate(to route: Route) {
        coordinator?.navigateInHistory(to: .historyGraph(route))
    }
    
    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .history:
            HistoryView()
        case .dailySession(let selectedDate):
            // ViewModel 생성 및 세션 로드
            let viewModel = HistoryViewModel()
            DailySessionView(
                sessions: [],
                selectedDate: selectedDate,
                viewModel: viewModel
            )
            .task {
                // 날짜로 세션 로드
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                if let date = formatter.date(from: selectedDate) {
                    viewModel.loadSessionForSpecificDay(date: date)
                }
            }
        }
    }
}
