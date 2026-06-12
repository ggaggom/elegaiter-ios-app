//
//  SettingView.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI

/// 설정 메인 화면
///
/// Android의 `SettingScreen`을 SwiftUI로 변환
/// - 계정 관련, 기기 관련, 정보 메뉴 표시
/// - 로그아웃, 회원 탈퇴 기능
struct SettingView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = SettingViewModel()
    
    @State private var withdrawPassword: String = ""
    @State private var verifyPassword: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경색 (Safe Area까지 확장) - 흰색
                Color.white
                    .ignoresSafeArea(edges: .all)
                
                VStack(spacing: 0) {
                    // 고정 헤더 (Safe Area 내부에 배치)
                    HStack {
                        Spacer()
                        Text("setting_my_page_title".localized())
                            .typography(ElegaiterTypography.Headline4)
                            .foregroundColor(ElegaiterColors.Text.main)
                        Spacer()
                    }
                    .padding(.top, 8) // status bar 영역 여백
                    .padding(.vertical, 16)
                    .background(Color.white) // 헤더 배경색 (흰색)
                    
                    // 스크롤 가능한 컨텐츠
                    ScrollView {
                        VStack(spacing: 0) {
                            // 내 성취 (첫 번째 섹션, horizontal padding 4dp)
                            MyPageSection(
                                title: "",
                                menuItems: [
                                    MyPageMenuItem(
                                        "setting_menu_my_achievement".localized(),
                                        { viewModel.navigateToAchievement() },
                                        iconName: "IcAchievement"
                                    )
                                ],
                                additionalHorizontalPadding: 4 // 기본 16dp에 추가로 4dp 적용
                            )
                            
                            // 계정 관련
                            MyPageSection(
                                title: "setting_menu_account".localized(),
                                menuItems: [
                                    MyPageMenuItem("setting_menu_edit_profile".localized(), { viewModel.showDialog(.verifyPw) }),
                                    MyPageMenuItem("auth_password_reset".localized(), { viewModel.navigateToResetPassword() }),
                                    MyPageMenuItem("setting_menu_step_goal".localized(), { viewModel.navigateToStepGoal() }),
                                    MyPageMenuItem("setting_menu_language_title".localized(), { viewModel.navigateToAppLanguage() }),
                                ]
                            )
                            
                            // 기기 관련
                            MyPageSection(
                                title: "setting_menu_device".localized(),
                                menuItems: [
                                    MyPageMenuItem("threshold_title".localized(), { viewModel.navigateToThreshold() }),
                                    MyPageMenuItem("setting_menu_bluetooth_reconnect".localized(), { viewModel.showDialog(.disconnect) }, showArrow: false),
                                    MyPageMenuItem("setting_menu_device_error".localized(), { viewModel.navigateToDeviceError() }),
                                ]
                            )
                            
                            // 정보
                            MyPageSection(
                                title: "setting_menu_info".localized(),
                                menuItems: [
                                    MyPageMenuItem("setting_menu_terms_policy".localized(), { viewModel.navigateToTerms() }),
                                ]
                            )
                            
                            // 계정 관리
                            MyPageSection(
                                title: "",
                                menuItems: [
                                    MyPageMenuItem("setting_menu_logout".localized(), { viewModel.showDialog(.logout) }, showArrow: false),
                                    MyPageMenuItem(
                                        "setting_menu_withdraw".localized(),
                                        { viewModel.showDialog(.withdraw) },
                                        textColor: ElegaiterColors.Status.error,
                                        showArrow: false
                                    ),
                                ]
                            )
                            
                            // 앱 버전 정보
                            appVersionView
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .background(Color.white) // NavigationStack 배경색 명시
            .navigationBarHidden(true)
            .onAppear {
                viewModel.coordinator = coordinator
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .restartApp:
                    coordinator.logout()
                }
            }
            .onChange(of: viewModel.uiState.dialogState) { newState in
                // 다이얼로그가 열릴 때 비밀번호 필드 초기화
                if newState == .withdraw {
                    withdrawPassword = ""
                } else if newState == .verifyPw {
                    verifyPassword = ""
                }
            }
            .overlay {
                // 다이얼로그
                if viewModel.uiState.dialogState != .none {
                    dialogView
                }
            }
            .localized() // 언어 변경 시 자동 업데이트
        }
    }
    
    // MARK: - Dialog Views
    
    @ViewBuilder
    private var dialogView: some View {
        switch viewModel.uiState.dialogState {
        case .logout:
            logoutDialog
        case .disconnect:
            disconnectDialog
        case .withdraw:
            withdrawDialog
        case .verifyPw:
            verifyPwDialog
        default:
            EmptyView()
        }
    }
    
    /// 로그아웃 다이얼로그
    private var logoutDialog: some View {
        StyledAlertDialog(
            isPresented: Binding(
                get: { viewModel.uiState.dialogState == .logout },
                set: { if !$0 { viewModel.dismissDialog() } }
            ),
            title: "setting_menu_logout".localized(),
            message: "setting_logout_message".localized(),
            content: { EmptyView() },
            confirmText: "btn_confirm".localized(),
            onConfirm: {
                viewModel.onLogout()
                showToast(message: "setting_logout_toast".localized())
            },
            dismissText: "btn_cancel".localized(),
            onDismiss: { viewModel.dismissDialog() }
        )
    }
    
    /// 블루투스 재연결 다이얼로그
    private var disconnectDialog: some View {
        StyledAlertDialog(
            isPresented: Binding(
                get: { viewModel.uiState.dialogState == .disconnect },
                set: { if !$0 { viewModel.dismissDialog() } }
            ),
            title: "setting_menu_bluetooth_reconnect".localized(),
            message: "setting_bluetooth_reconnect_message".localized(),
            content: { EmptyView() },
            confirmText: "btn_confirm".localized(),
            onConfirm: {
                viewModel.dismissDialog() // 다이얼로그 먼저 닫기
                Task {
                    await viewModel.onDisconnect() // 블루투스 연결 해제
                    viewModel.navigateToJawsSearch() // JawsSearch로 이동
                }
            },
            dismissText: "btn_cancel".localized(),
            onDismiss: { viewModel.dismissDialog() }
        )
    }
    
    /// 비밀번호 재인증 다이얼로그 (회원정보 수정 진입 전)
    private var verifyPwDialog: some View {
        StyledAlertDialog(
            isPresented: Binding(
                get: { viewModel.uiState.dialogState == .verifyPw },
                set: { if !$0 { viewModel.dismissDialog() } }
            ),
            title: "setting_verify_pw_title".localized(),
            message: "setting_verify_pw_message".localized(),
            content: {
                LabeledPasswordInputField(
                    labelText: "auth_password".localized(),
                    value: $verifyPassword,
                    placeholder: "setting_pw_input".localized(),
                    onValueChange: { verifyPassword = $0 }
                )
                .padding(.bottom, 24)
            },
            confirmText: "btn_confirm".localized(),
            onConfirm: {
                if !viewModel.isOnline {
                    showToast(message: "error_network_connection".localized())
                    return
                }

                viewModel.onVerifyPw(password: verifyPassword) { success in
                    if success {
                        verifyPassword = ""
                        viewModel.dismissDialog()
                        showToast(message: "setting_pw_verified".localized())
                        viewModel.navigateToAccountEdit()
                    } else {
                        showToast(message: "setting_pw_invalid_toast".localized())
                    }
                }
            },
            dismissText: "btn_cancel".localized(),
            onDismiss: {
                verifyPassword = ""
                viewModel.dismissDialog()
            }
        )
    }

    /// 회원 탈퇴 다이얼로그
    private var withdrawDialog: some View {
        StyledAlertDialog(
            isPresented: Binding(
                get: { viewModel.uiState.dialogState == .withdraw },
                set: { if !$0 { viewModel.dismissDialog() } }
            ),
            title: "setting_menu_withdraw".localized(),
            message: "setting_withdraw_message".localized(),
            content: {
                LabeledPasswordInputField(
                    labelText: "auth_password".localized(),
                    value: $withdrawPassword,
                    placeholder: "setting_pw_input".localized(),
                    onValueChange: { withdrawPassword = $0 }
                )
                .padding(.bottom, 24)
            },
            confirmText: "btn_confirm".localized(),
            onConfirm: {
                Task {
                    if !viewModel.isOnline {
                        showToast(message: "error_network_connection".localized())
                        return
                    }
                    
                    let success = await viewModel.onWithdraw(password: withdrawPassword)
                    if success {
                        showToast(message: "setting_withdraw_toast".localized())
                    } else {
                        showToast(message: "setting_pw_invalid_toast".localized())
                    }
                }
            },
            dismissText: "btn_cancel".localized(),
            onDismiss: {
                withdrawPassword = ""
                viewModel.dismissDialog()
            }
        )
    }
    
    // MARK: - Helper Methods
    
    private func showToast(message: String) {
        // 전역 토스트 사용 (화면 이동해도 유지됨)
        ToastManager.shared.show(message: message)
    }
    
    /// 앱 버전 정보 뷰
    private var appVersionView: some View {
        VStack(spacing: 0) {
            Text(appVersionString)
                .typography(ElegaiterTypography.Label5)
                .foregroundColor(ElegaiterColors.Text.sub1)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .padding(.horizontal, 16) // 다른 섹션과 동일한 좌우 패딩
        }
    }
    
    /// 앱 버전 정보 문자열 생성
    /// 형식: Ver [앱 버전] ( [빌드날짜]/[빌드번호] )
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        // 빌드 날짜 가져오기 (Info.plist의 BuildDate 키 또는 앱 번들 수정 날짜)
        let buildDate: String
        if let buildDateString = Bundle.main.infoDictionary?["BuildDate"] as? String {
            buildDate = buildDateString
        } else {
            let bundlePath = Bundle.main.bundlePath
            if let attributes = try? FileManager.default.attributesOfItem(atPath: bundlePath),
               let modificationDate = attributes[.modificationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                buildDate = formatter.string(from: modificationDate)
            } else {
                buildDate = "Unknown"
            }
        }
        
        return "Ver \(version) (\(buildDate)/\(buildNumber))"
    }
}

#Preview {
    SettingView()
        .environmentObject(AppCoordinator())
}
