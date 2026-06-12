//
//  JawsSearchView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

/// JawsSearch 화면
/// 
/// Android의 `JawsSearchScreen`을 SwiftUI로 변환
/// - BLE 디바이스 검색 및 연결
/// - 상태별 UI (로딩, 디바이스 없음, 디바이스 목록)
/// - 디바이스 선택 및 연결
/// - Threshold 프롬프트 다이얼로그
struct JawsSearchView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = JawsSearchViewModel()
    
    var body: some View {
        ZStack {
            // 메인 콘텐츠
            VStack(spacing: 0) {
                // 상태별 콘텐츠
                if viewModel.isLoading {
                    Spacer()
                    ScanStatusContent(
                        useAnimatedIcon: true,
                        iconName: "IcBluetoothGreen",
                        iconColor: ElegaiterColors.Green.green400,
                        headlineText: "bluetooth_connect_prompt".localized(),
                        bodyText: "bluetooth_connect_searching".localized(),
                        fillMaxHeight: false,
                        verticalOffset: -80 // 위로 올림
                    )
                    Spacer()
                } else if viewModel.scannedDevices.isEmpty {
                    Spacer()
                    ScanStatusContent(
                        useAnimatedIcon: false,
                        iconName: "IcBluetoothGray",
                        iconColor: nil,
                        headlineText: "bluetooth_connect_not_found".localized(),
                        fillMaxHeight: false,
                        verticalOffset: -80 // 위로 올림
                    )
                    Spacer()
                } else {
                    // 디바이스 목록 상태
                    VStack(spacing: 0) {
                        // 헤더
                        ElegaiterHeader(
                            title: "",
                            onBackClick: {
                                viewModel.resetConnectedDeviceAndRescan()
                            }
                        )
                        .frame(height: 76)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // 상태 아이콘 및 텍스트
                        ScanStatusContent(
                            iconName: viewModel.connectedDevice != nil && viewModel.currentConnectionState == .connected
                                ? "IcBluetoothBlue"
                                : "IcBluetoothGreen",
                            headlineText: "bluetooth_connect_prompt".localized(),
                            showBodyText: false,
                            fillMaxHeight: false // 디바이스 목록 상태에서는 내용만큼만 차지
                        )
                        
                        Spacer()
                            .frame(height: 52)
                        
                        // 디바이스 목록
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(sortedDevices, id: \.address) { device in
                                    DeviceCard(
                                        device: device,
                                        isConnected: isDeviceConnected(device),
                                        isLastConnected: isLastConnectedDevice(device),
                                        onTap: {
                                            viewModel.onDeviceSelected(device)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            
            // 하단 고정 버튼
            VStack {
                Spacer()
                
                PrimaryButton(
                    onClick: {
                        if isNoDeviceFound {
                            viewModel.resetConnectedDeviceAndRescan()
                        } else {
                            viewModel.onNextClick()
                        }
                    },
                    enabled: buttonEnabled,
                    showSingleBottomLink: true,
                    bottomInfoText1: "bluetooth_connect_later".localized(),
                    onBottomTextClick: {
                        viewModel.navigateToMain()
                    }
                ) {
                    Text(buttonText)
                        .typography(ElegaiterTypography.Label1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 0)
                }
            }
            
            // 다이얼로그 오버레이
            if case .bluetoothError = viewModel.dialogState {
                BluetoothErrorDialog(
                    isPresented: Binding(
                        get: { viewModel.dialogState == .bluetoothError },
                        set: { if !$0 { viewModel.dismissDialog() } }
                    ),
                    onConfirm: {
                        viewModel.dismissDialog()
                    }
                )
            }
            
            if case .existingThresholdPrompt = viewModel.dialogState {
                ExistingThresholdPromptDialog(
                    isPresented: Binding(
                        get: { viewModel.dialogState == .existingThresholdPrompt },
                        set: { if !$0 { viewModel.dismissDialog() } }
                    ),
                    shouldShowThresholdPrompt: viewModel.shouldShowThresholdPrompt,
                    onKeepSettings: {
                        viewModel.onKeepSettingsClick()
                        viewModel.saveShouldShowThresholdPrompt()
                    },
                    onReset: {
                        viewModel.onManualConfigureClick()
                        viewModel.saveShouldShowThresholdPrompt()
                    },
                    onToggleShouldShow: { isChecked in
                        viewModel.toggleShouldShowThresholdPrompt(isChecked)
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.coordinator = coordinator
            // 화면 진입 시 자동으로 BLE 스캔 시작
            viewModel.startScan()
        }
        .onReceive(viewModel.eventSubject) { event in
            handleEvent(event)
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    // MARK: - Computed Properties
    
    /// 디바이스가 없는지 여부
    private var isNoDeviceFound: Bool {
        !viewModel.isLoading && viewModel.scannedDevices.isEmpty
    }
    
    /// 버튼 텍스트
    private var buttonText: String {
        isNoDeviceFound ? "bluetooth_connect_retry".localized() : "btn_next".localized()
    }
    
    /// 버튼 활성화 여부
    private var buttonEnabled: Bool {
        if isNoDeviceFound {
            return true
        } else {
            return viewModel.connectedDevice != nil && viewModel.currentConnectionState == .connected
        }
    }
    
    /// 정렬된 디바이스 목록 (마지막 연결 디바이스를 상단에)
    private var sortedDevices: [ScannedDevice] {
        viewModel.scannedDevices.sorted { device1, device2 in
            let isLast1 = isLastConnectedDevice(device1)
            let isLast2 = isLastConnectedDevice(device2)
            if isLast1 && !isLast2 {
                return true
            } else if !isLast1 && isLast2 {
                return false
            }
            return false
        }
    }
    
    /// 디바이스가 연결되어 있는지 확인
    private func isDeviceConnected(_ device: ScannedDevice) -> Bool {
        guard let connectedDevice = viewModel.connectedDevice else { return false }
        return connectedDevice.address == device.address
            && connectedDevice.name == device.name
            && viewModel.currentConnectionState == .connected
    }
    
    /// 마지막 연결 디바이스인지 확인
    private func isLastConnectedDevice(_ device: ScannedDevice) -> Bool {
        guard let lastDevice = viewModel.lastConnectedDevice else { return false }
        return lastDevice.address == device.address && lastDevice.name == device.name
    }
    
    // MARK: - Private Methods
    
    /// 이벤트 처리
    /// 
    /// Android의 `LaunchedEffect` + `repeatOnLifecycle` 로직을 SwiftUI로 변환
    private func handleEvent(_ event: JawsSearchEvent) {
        switch event {
        case .navigateToThreshold:
            viewModel.navigateToThreshold()
            
        case .navigateToMain:
            viewModel.navigateToMain()
            
        case .showBleError:
            // 글로벌 토스트로 메시지 표시
            ToastManager.shared.show(message: "jaws_search_device_not_found".localized())
        }
    }
}

// MARK: - AnimatedGradientIconView

/// 애니메이션 그라데이션 아이콘 컴포넌트
/// 
/// Android의 `AnimatedGradientIcon`을 SwiftUI로 변환
/// - RadialGradient를 사용한 원형 그라데이션 후광
/// - 반경 애니메이션 (35dp → 45dp 반복)
private struct AnimatedGradientIconView: View {
    let iconName: String
    let iconColor: Color
    
    @State private var animatedRadius: CGFloat = 35
    
    var body: some View {
        ZStack {
            // 아래 레이어: RadialGradient 후광 (애니메이션)
            // 안드로이드와 동일: 중심에서 바깥으로 퍼지는 원형 그라데이션
            RadialGradient(
                colors: [
                    iconColor.opacity(0.8),  // 중심부: 투명도 높여서 더 진하게
                    iconColor.opacity(0.4),  // 중간
                    Color.clear              // 바깥쪽: 완전 투명
                ],
                center: .center,
                startRadius: 0,
                endRadius: animatedRadius
            )
            .frame(width: 90, height: 90)
            
            // 위 레이어: 원본 아이콘 이미지
            Image(iconName)
                .resizable()
                .renderingMode(.original)
                .frame(width: 50, height: 50)
        }
        .onAppear {
            // 애니메이션 시작: 35 → 45 → 35 반복 (700ms, EaseInOut)
            withAnimation(
                Animation
                    .easeInOut(duration: 0.7)
                    .repeatForever(autoreverses: true)
            ) {
                animatedRadius = 45
            }
        }
    }
}

// MARK: - ScanStatusContent

/// 스캔 상태 콘텐츠 컴포넌트
/// 
/// Android의 `ScanStatusContent`를 SwiftUI로 변환
private struct ScanStatusContent: View {
    var useAnimatedIcon: Bool = false
    let iconName: String
    var iconColor: Color? = nil
    let headlineText: String
    var bodyText: String = ""
    var showBodyText: Bool = true
    var fillMaxHeight: Bool = true // 로딩/디바이스 없음 상태에서만 maxHeight 적용
    var verticalOffset: CGFloat = 0 // 수직 offset (로딩/디바이스 없음 상태에서 위로 올리기)
    
    var body: some View {
        VStack(spacing: 0) {
            if useAnimatedIcon {
                // 애니메이션 아이콘 (그라데이션 후광 효과)
                // 안드로이드의 AnimatedGradientIcon과 동일하게 구현
                AnimatedGradientIconView(
                    iconName: iconName,
                    iconColor: iconColor ?? ElegaiterColors.Green.green400
                )
            } else {
                // 템플릿 모드 또는 원본 이미지 모드
                // 로딩 상태와 동일한 크기 컨테이너 사용 (90x90)
                ZStack {
                    // 빈 공간 유지 (로딩 상태의 AnimatedGradientIconView와 동일한 크기)
                    Color.clear
                        .frame(width: 90, height: 90)
                    
                    // 아이콘 (중앙 정렬)
                    // IcBluetoothGreen은 50pt, 그 외는 80pt
                    let iconSize: CGFloat = iconName == "IcBluetoothGreen" ? 50 : 80
                    Image(iconName)
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: iconSize, height: iconSize)
                }
            }
            
            Spacer()
                .frame(height: 12)
            
            Text(headlineText)
                .typography(ElegaiterTypography.Headline4)
                .foregroundColor(ElegaiterColors.Text.main)
            
            // headlineText와 bodyText 사이: 8
            // showBodyText가 true일 때 항상 Spacer와 Text 표시 (bodyText가 비어있어도 공간 유지)
            if showBodyText {
                Spacer()
                    .frame(height: 8)
                
                Text(bodyText) // bodyText가 비어있어도 빈 Text가 공간을 차지
                    .typography(ElegaiterTypography.Body4)
                    .foregroundColor(ElegaiterColors.Text.sub1)
            }
        }
        .frame(maxWidth: .infinity)
        .offset(y: verticalOffset)
    }
}

// MARK: - DeviceCard

/// 디바이스 카드 컴포넌트
private struct DeviceCard: View {
    let device: ScannedDevice
    let isConnected: Bool
    let isLastConnected: Bool
    let onTap: () -> Void
    
    var body: some View {
        WhiteGrayCard {
            ConnectionStatusRow(
                deviceName: device.name,
                deviceType: "device_jaws".localized(),
                statusText: isConnected ? "device_connected".localized() : "bluetooth_connect_device".localized(),
                statusTextColor: .white,
                statusBackgroundColor: isConnected
                    ? ElegaiterColors.Additional.bluetooth
                    : ElegaiterColors.Background.dark,
                showCheckIcon: isConnected,
                hasTag: isLastConnected
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
    }
}

// MARK: - BluetoothErrorDialog

/// BLE 에러 다이얼로그
/// 
/// Android의 BLE 에러 다이얼로그를 SwiftUI로 변환
private struct BluetoothErrorDialog: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        StyledAlertDialog(
            isPresented: $isPresented,
            title: "bluetooth_unavailable_title".localized(),
            message: "bluetooth_unavailable_content".localized(),
            content: {
                EmptyView()
            },
            confirmText: "btn_confirm".localized(),
            onConfirm: onConfirm
        )
    }
}

// MARK: - ExistingThresholdPromptDialog

/// 임계값 설정 프롬프트 다이얼로그
/// 
/// Android의 `ExistingThresholdPrompt` 다이얼로그를 SwiftUI로 변환
private struct ExistingThresholdPromptDialog: View {
    @Binding var isPresented: Bool
    let shouldShowThresholdPrompt: Bool
    let onKeepSettings: () -> Void
    let onReset: () -> Void
    let onToggleShouldShow: (Bool) -> Void
    
    var body: some View {
        StyledAlertDialog(
            isPresented: $isPresented,
            title: "threshold_title".localized(),
            message: "bluetooth_threshold_reset_content".localized(),
            content: {
                HStack(spacing: 6) {
                    CustomCheckbox(
                        checked: !shouldShowThresholdPrompt,
                        onCheckedChange: onToggleShouldShow
                    )
                    
                    Text("bluetooth_threshold_do_not_ask_again".localized())
                        .typography(ElegaiterTypography.Label4)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                    
                    Spacer() // 왼쪽 정렬을 위해 Spacer 추가
                }
                .frame(maxWidth: .infinity, alignment: .leading) // 왼쪽 정렬
                .padding(.bottom, 24)
            },
            confirmText: "bluetooth_threshold_keep_setting".localized(),
            onConfirm: onKeepSettings,
            dismissText: "bluetooth_threshold_reset_confirm".localized(),
            onDismiss: onReset
        )
    }
}

// MARK: - Preview

#Preview {
    JawsSearchView()
        .environmentObject(AppCoordinator())
}
