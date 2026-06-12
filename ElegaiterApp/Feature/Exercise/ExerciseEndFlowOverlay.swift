//
//  ExerciseEndFlowOverlay.swift
//  ElegaiterApp
//
//  Created on 2026-05-29.
//

import SwiftUI
import UIKit

/// 운동 종료 후 완료 오버레이 및 보행 기록 다이얼로그
///
/// Android `RealTimeExerciseRoute` / `ArcadeRoute`의 종료 플로우 UI를 공통화
struct ExerciseEndFlowOverlay: View {
    @ObservedObject var viewModel: ExerciseSessionViewModel
    
    @State private var showPermissionDialog = false
    @State private var showGpsDialog = false
    
    var body: some View {
        ZStack {
            StatusOverlay(title: "exercise_completed".localized())
            
            if viewModel.showCommentPrompt {
                StyledAlertDialog(
                    isPresented: Binding(
                        get: { viewModel.showCommentPrompt },
                        set: { viewModel.showCommentPrompt = $0 }
                    ),
                    title: "exercise_description_title".localized(),
                    message: "exercise_description_message1".localized(),
                    content: { EmptyView() },
                    confirmText: "exercise_description_confirm".localized(),
                    onConfirm: {
                        viewModel.showCommentInput = true
                    },
                    dismissText: "exercise_description_dismiss".localized(),
                    onDismiss: {
                        viewModel.saveExercise()
                    }
                )
            }
            
            if viewModel.showCommentInput {
                StyledAlertDialog(
                    isPresented: Binding(
                        get: { viewModel.showCommentInput },
                        set: { viewModel.showCommentInput = $0 }
                    ),
                    title: "exercise_description_title".localized(),
                    message: "exercise_description_message2".localized(),
                    content: {
                        RoundedTextArea(
                            value: Binding(
                                get: { viewModel.uiState.gaitDescription },
                                set: { viewModel.onGaitDescriptionChange($0) }
                            ),
                            placeholder: "exercise_description_placeholder".localized(),
                            onValueChange: viewModel.onGaitDescriptionChange
                        )
                        .padding(.bottom, 12)
                    },
                    confirmText: "exercise_description_save".localized(),
                    onConfirm: {
                        viewModel.saveExercise()
                    }
                )
            }
            
            if showPermissionDialog {
                StyledAlertDialog(
                    isPresented: $showPermissionDialog,
                    title: "popup_location_title".localized(),
                    message: "popup_location_content".localized(),
                    content: { EmptyView() },
                    confirmText: "realtime_exercise_go_to_settings".localized(),
                    onConfirm: {
                        showPermissionDialog = false
                        openAppSettings()
                    }
                )
            }
            
            if showGpsDialog {
                StyledAlertDialog(
                    isPresented: $showGpsDialog,
                    title: "popup_gps_title".localized(),
                    message: "popup_gps_content".localized(),
                    content: { EmptyView() },
                    confirmText: "realtime_exercise_go_to_settings".localized(),
                    onConfirm: {
                        showGpsDialog = false
                        openAppSettings()
                    }
                )
            }
        }
        .onChange(of: viewModel.uiState.locationDialogToShow) { dialog in
            switch dialog {
            case .permissionNeeded:
                showPermissionDialog = true
            case .gpsNeeded:
                showGpsDialog = true
            case .none:
                showPermissionDialog = false
                showGpsDialog = false
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
