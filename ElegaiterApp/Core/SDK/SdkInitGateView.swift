//
//  SdkInitGateView.swift
//  ElegaiterApp
//

import ElegaiterSDK
import SwiftUI
import UIKit

/// SDK 라이선스 검증 완료 후에만 하위 콘텐츠를 표시 (Android MainActivity `InitState` 대응)
struct SdkInitGateView<Content: View>: View {
    @ObservedObject private var sdkManager = SDKManager.shared

    @ViewBuilder let content: () -> Content

    @State private var showErrorDialog = false

    var body: some View {
        ZStack {
            switch sdkManager.initState {
            case .loading:
                Color.white.ignoresSafeArea()
            case .success:
                content()
            case .error:
                Color.white.ignoresSafeArea()
            }
        }
        .onAppear {
            sdkManager.preload()
        }
        .onChange(of: sdkManager.initState) { newState in
            if case .error = newState {
                showErrorDialog = true
            } else {
                showErrorDialog = false
            }
        }
        .overlay {
            if case .error(let result, let detail) = sdkManager.initState, showErrorDialog {
                licenseErrorDialog(result: result, detail: detail)
            }
        }
    }

    @ViewBuilder
    private func licenseErrorDialog(result: ElegaiterInitResult, detail: String?) -> some View {
        let copy = dialogCopy(for: result, detail: detail)

        StyledAlertDialog(
            isPresented: $showErrorDialog,
            title: copy.title,
            message: copy.message,
            content: { EmptyView() },
            confirmText: NSLocalizedString("license_popup_btn_retry", comment: ""),
            onConfirm: {
                showErrorDialog = false
                sdkManager.retry()
            },
            dismissText: NSLocalizedString("license_popup_btn_exit", comment: ""),
            onDismiss: {
                exitApp()
            }
        )
    }

    private func dialogCopy(for result: ElegaiterInitResult, detail: String?) -> (title: String, message: String) {
        switch result {
        case .networkError:
            return (
                NSLocalizedString("license_popup_network_error_title", comment: ""),
                NSLocalizedString("license_popup_network_error_content", comment: "")
            )
        case .invalidLicense:
            return (
                NSLocalizedString("license_popup_invalid_error_title", comment: ""),
                NSLocalizedString("license_popup_invalid_error_content", comment: "")
            )
        case .serverError:
            let title = NSLocalizedString("license_popup_system_error_title", comment: "")
            let base = NSLocalizedString("license_popup_system_error_content", comment: "")
            if let detail, !detail.isEmpty {
                return (title, "\(base)\n\n(\(detail))")
            }
            return (title, base)
        case .success:
            return ("", "")
        }
    }

    private func exitApp() {
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
    }
}
