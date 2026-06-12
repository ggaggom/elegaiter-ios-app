//
//  PermissionRequiredPopup.swift
//  ElegaiterApp
//
//  Created on 2025-12-17.
//

import SwiftUI
import os.log

private let permissionPopupLogger = Logger(subsystem: "com.elegaiter.app", category: "PermissionRequiredPopup")

/// 필수 권한 요청 팝업
/// 
/// BLE 및 위치 권한이 해제되었을 때 표시되는 팝업입니다.
/// 최초 가이드 팝업과 동일한 디자인으로 권한이 왜 필요한지 설명합니다.
/// '설정하기' 버튼을 누르면 앱 설정 화면으로 이동합니다.
struct PermissionRequiredPopup: View {
    @Binding var isPresented: Bool
    let onSettings: () -> Void
    
    var body: some View {
        StyledAlertDialog(
            isPresented: $isPresented,
            title: "permission_required_title".localized(),
            message: "permission_required_message".localized(),
            content: {
                PermissionDetailBox()
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            },
            confirmText: "permission_required_button".localized(),
            onConfirm: {
                onSettings()
            }
        )
    }
}

// MARK: - PermissionDetailBox

/// 권한 상세 정보 박스
/// 
/// 권한 안내 팝업 내에서 권한 상세 정보를 박스로 감싸서 표시
private struct PermissionDetailBox: View {
    var body: some View {
        VStack(spacing: 16) {
            // 블루투스 권한 항목
            PermissionItem(
                icon: "antenna.radiowaves.left.and.right",
                iconColor: ElegaiterColors.Green.green400,
                title: "splash_permission_bluetooth_title".localized(),
                description: "splash_permission_bluetooth_description".localized()
            )
            
            // 위치 권한 항목
            PermissionItem(
                icon: "location.fill",
                iconColor: ElegaiterColors.Green.green400,
                title: "permission_location_title".localized(),
                description: "splash_permission_location_description".localized()
            )
        }
        .padding(16)
        .background(ElegaiterColors.Background.light)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ElegaiterColors.Stroke.weak, lineWidth: 1)
        )
    }
}

// MARK: - PermissionItem

/// 권한 항목 컴포넌트
/// 
/// 각 권한에 대한 아이콘, 제목, 설명을 표시
private struct PermissionItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 아이콘
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            // 텍스트 영역
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .typography(ElegaiterTypography.Body2)
                    .foregroundColor(ElegaiterColors.Text.main)
                
                Text(description)
                    .typography(ElegaiterTypography.Label4)
                    .foregroundColor(ElegaiterColors.Text.sub2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var showPopup = true
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.3)
                
                if showPopup {
                    PermissionRequiredPopup(
                        isPresented: $showPopup,
                        onSettings: {
                            permissionPopupLogger.debug("설정하기 클릭")
                        }
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}
