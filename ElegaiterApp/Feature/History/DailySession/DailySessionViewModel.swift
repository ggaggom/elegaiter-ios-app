//
//  DailySessionViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine

@MainActor
class DailySessionViewModel: ObservableObject {
    weak var coordinator: AppCoordinator?
    
    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator
    }
    
    // MARK: - Navigation
    
    func navigateBack() {
        guard let coordinator = coordinator else { return }
        coordinator.pop(in: Binding(
            get: { coordinator.historyPath },
            set: { coordinator.historyPath = $0 }
        ))
    }
}
