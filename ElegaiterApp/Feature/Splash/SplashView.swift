//
//  SplashView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// Splash 화면
/// 
/// Android의 `SplashScreen`을 SwiftUI로 변환
/// - 앱 시작 시 가장 먼저 표시되는 화면
/// - 로그인 상태를 확인하고 적절한 화면으로 분기
struct SplashView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = SplashViewModel()
    
    @State private var hasNavigated = false
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // 배경색 (흰색)
            Color.white
                .ignoresSafeArea()
            
            // SplashLogo 이미지 (중앙 정렬, 애니메이션 적용)
            Image("SplashLogoV2")
                .resizable()
                .scaledToFit()
                .frame(width: 320, height: 66)
                //.scaleEffect(logoScale)
                //.opacity(logoOpacity)
            
            // 권한 안내 팝업 (앱 최초 실행 시 한 번만 표시되는 권한 안내 팝업)
            if viewModel.showPermissionGuide {
                PermissionGuidePopupView(
                    isPresented: $viewModel.showPermissionGuide,
                    onDismiss: {
                        viewModel.dismissPermissionGuide()
                    }
                )
            }
        }
        .onAppear {
            viewModel.coordinator = coordinator
            
            // 로고 등장 애니메이션: 페이드 인 + 스케일 업 (오버슈팅 없이 부드럽게)
            // withAnimation(.smooth(duration: 1.5)) {
            //     logoScale = 1.0
            //     logoOpacity = 1.0
            // }
            
            // 애니메이션 완료 후 determineInitialRoute 호출
            // 로고 등장 애니메이션 완료(0.6초) + 최소 표시 시간(1.5초) = 총 2.1초
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                await viewModel.determineInitialRoute()
            }
        }
        .onChange(of: viewModel.uiState) { _ in
            // 상태 변경 시 네비게이션 처리
            handleNavigation()
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    // MARK: - Private Methods
    
    /// 상태에 따른 네비게이션 처리
    /// 
    /// Android의 `SplashScreen`의 분기 로직과 동일합니다.
    /// - `IsLoggedIn`: JawsSearch 화면으로 이동
    /// - `NotLoggedIn` / `Loading`: Login 화면으로 이동
    private func handleNavigation() {
        guard !hasNavigated else { return }
        
        switch viewModel.uiState {
        case .isLoggedIn:
            hasNavigated = true
            viewModel.navigateToJawsSearch()
        case .notLoggedIn, .loading:
            // 로딩 중이면 기본적으로 로그인 화면으로 이동
            hasNavigated = true
            viewModel.navigateToLogin()
        }
    }
}

// MARK: - PermissionGuidePopupView

/// 권한 안내 팝업 뷰
/// 
/// 앱 최초 실행 시 한 번만 표시되는 권한 안내 팝업
/// - BLE 권한 및 위치 권한에 대한 안내
/// - 확인 버튼 클릭 시 권한 요청 시작
private struct PermissionGuidePopupView: View {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        StyledAlertDialog(
            isPresented: $isPresented,
            title: "splash_permission_title".localized(),
            message: "splash_permission_message".localized(),
            content: {
                PermissionDetailBox()
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            },
            confirmText: "btn_confirm".localized(),
            onConfirm: {
                onDismiss()
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

#Preview {
    SplashView()
        .environmentObject(AppCoordinator())
}

