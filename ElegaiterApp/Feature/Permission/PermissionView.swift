//
//  PermissionView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import UIKit
import os.log

/// Permission 화면
/// 
/// Android의 `PermissionScreen`을 SwiftUI로 변환
/// - 위치 권한 및 GPS 상태 확인
/// - 권한 요청 처리
/// - 다이얼로그 표시
struct PermissionView: View {

    private static let logger = Logger(subsystem: "com.elegaiter.app", category: "PermissionView")

    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = PermissionViewModel()

    init() {
        Self.logger.debug("🚀 [Permission] View init 호출됨")
    }

    var body: some View {
        let _ = Self.logger.debug("🚀 [Permission] View body 렌더링")
        return ZStack {
            // 메인 콘텐츠
            VStack(spacing: 0) {
                Spacer()
                
                // 로딩 상태 UI
                LoadingStateView(uiState: viewModel.uiState)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            
            // 다이얼로그 오버레이
            if viewModel.showPermissionDialog {
                PermissionRequiredDialog(
                    isPresented: $viewModel.showPermissionDialog,
                    onConfirm: {
                        viewModel.openAppSettings()
                    }
                )
            }
            
            if viewModel.showGpsDialog {
                GpsRequiredDialog(
                    isPresented: $viewModel.showGpsDialog,
                    onConfirm: {
                        viewModel.openLocationSettings()
                    }
                )
            }
        }
        .onAppear {
            Self.logger.debug("🚀 [Permission] View onAppear 호출됨")
            viewModel.coordinator = coordinator
            Self.logger.debug("🚀 [Permission] coordinator 설정 완료 - 권한 요청 시작")
            viewModel.requestLocationPermission()
            Self.logger.debug("🚀 [Permission] requestLocationPermission 호출 완료")
        }
    }
}

// MARK: - LoadingStateView

/// 로딩 상태 UI 컴포넌트
/// 
/// Android의 `LoadingState` Composable을 SwiftUI로 변환
private struct LoadingStateView: View {
    let uiState: PermissionUiState
    
    var body: some View {
        VStack(spacing: 24) {
            // 로딩 인디케이터
            // Android의 LinearProgressIndicator를 SwiftUI로 변환
            LinearProgressBar()
                .frame(width: 200, height: 8)
            
            // 상태 메시지
            Text("위치 권한 및 GPS 상태를 확인 중입니다")
                .typography(ElegaiterTypography.Body2)
                .foregroundColor(.primary)
            
            // 상태 표시
            VStack(spacing: 12) {
                // 위치 권한 상태
                StatusRow(
                    icon: "location.fill",
                    title: "위치 권한",
                    isChecked: isGranted
                )
                
                // GPS 상태
                StatusRow(
                    icon: "location.circle.fill",
                    title: "GPS",
                    isChecked: isGpsOn
                )
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }
    
    /// 위치 권한 허용 여부
    private var isGranted: Bool {
        if case .loading(let granted, _) = uiState {
            return granted
        }
        return false
    }
    
    /// GPS 활성화 여부
    private var isGpsOn: Bool {
        if case .loading(_, let gpsOn) = uiState {
            return gpsOn ?? false
        }
        return false
    }
}

// MARK: - StatusRow

/// 상태 행 컴포넌트
/// 
/// Android의 상태 표시 Row를 SwiftUI로 변환
private struct StatusRow: View {
    let icon: String
    let title: String
    let isChecked: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isChecked ? .green : .gray)
                .font(.system(size: 20))
            
            Text(title)
                .typography(ElegaiterTypography.Body3)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - PermissionRequiredDialog

/// 위치 권한 필요 다이얼로그
/// 
/// Android의 위치 권한 필요 다이얼로그를 SwiftUI로 변환
private struct PermissionRequiredDialog: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        StyledAlertDialog(
            isPresented: $isPresented,
            title: "위치 권한 필요",
            message: "앱 사용을 위해 위치 권한을 허용해주세요.",
            content: {
                EmptyView()
            },
            confirmText: "설정으로 이동",
            onConfirm: onConfirm
        )
    }
}

// MARK: - GpsRequiredDialog

/// GPS 설정 필요 다이얼로그
/// 
/// Android의 GPS 설정 필요 다이얼로그를 SwiftUI로 변환
private struct GpsRequiredDialog: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        StyledAlertDialog(
            isPresented: $isPresented,
            title: "GPS 설정 필요",
            message: "정확한 위치 서비스를 위해 GPS를 켜주세요.",
            content: {
                EmptyView()
            },
            confirmText: "설정으로 이동",
            onConfirm: onConfirm
        )
    }
}

// MARK: - LinearProgressBar

/// 선형 진행 표시줄
/// 
/// Android의 `LinearProgressIndicator`를 SwiftUI로 변환
private struct LinearProgressBar: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                // 진행 바
                Rectangle()
                    .fill(Color.green)
                    .frame(width: isAnimating ? geometry.size.width * 0.7 : geometry.size.width * 0.3, height: 8)
                    .cornerRadius(4)
                    .animation(
                        Animation.linear(duration: 1.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview {
    PermissionView()
        .environmentObject(AppCoordinator())
}
