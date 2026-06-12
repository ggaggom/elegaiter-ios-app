//
//  DeviceErrorView.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import ElegaiterSDK

/// 디바이스 에러 화면
/// 
/// Android의 `DeviceErrorScreen`을 SwiftUI로 변환
/// - 디바이스 연결 상태 확인
/// - 에러 발생/해소 명령 전송
struct DeviceErrorView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = DeviceErrorViewModel()
    
    /// 블루투스 아이콘 이름 결정
    /// 
    /// Android의 `when (uiState.connectionState)` 로직을 Swift로 변환
    private var bluetoothIconName: String {
        switch viewModel.uiState.connectionState {
        case .connected:
            return viewModel.uiState.isError ? "IcBluetoothRed" : "IcBluetoothBlue"
        default:
            return "IcBluetoothGray"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            // Android: ElegaiterHeader
            // iOS: ElegaiterTopBar 사용
            ElegaiterTopBar(
                title: "setting_menu_device_error".localized(),
                onBackClick: { viewModel.navigateBack() }
            )
            // ElegaiterHeader(
            //     title: "디바이스 에러",
            //     onBackClick: { viewModel.navigateBack() }
            // )
            
            if viewModel.uiState.connectionState == .connected {
                // 연결된 경우 (Android: Column with 위에서부터 시작)
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 40)
                        
                        // 블루투스 아이콘 (Android: Icon with size 80.dp, align center horizontally)
                        HStack {
                            Spacer()
                            Image(bluetoothIconName)
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            Spacer()
                        }
                        
                        Spacer()
                            .frame(height: 52)
                        
                        // 연결된 디바이스 정보 카드 (Android: Column with padding horizontal 20.dp)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("device_error_connected_device".localized())
                                .typography(ElegaiterTypography.Body3)
                                .foregroundColor(ElegaiterColors.Text.main)
                                .padding(.bottom, 8)
                                .padding(.horizontal, 20)
                            
                            // 디바이스 정보 카드 (Android: Card with RoundedCornerShape(20.dp))
                            VStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 0) {
                                    // ConnectionStatusRow (Android: ConnectionStatusRow)
                                    // 안드로이드: showCheckIcon 기본값이 true
                                    ConnectionStatusRow(
                                        deviceName: viewModel.uiState.connectedDevice?.name ?? "",
                                        deviceType: "device_jaws".localized(),
                                        statusText: "device_connected".localized(),
                                        statusTextColor: ElegaiterColors.Text.disabled,
                                        statusBackgroundColor: ElegaiterColors.Background.light,
                                        showCheckIcon: true
                                    )
                                    
                                    Spacer()
                                        .frame(height: 20)
                                    
                                    // 에러 발생 버튼 (Android: Button with Color(0xFFFFE3E3))
                                    Button(action: {
                                        viewModel.sendErrorCommand(code: 1)
                                    }) {
                                        Text("device_error_e1".localized())
                                            .typography(ElegaiterTypography.Label3)
                                            .foregroundColor(ElegaiterColors.Status.error)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 45)
                                    }
                                    .background(Color(red: 1.0, green: 0.89, blue: 0.89)) // Color(0xFFFFE3E3)
                                    .cornerRadius(48)
                                    
                                    Spacer()
                                        .frame(height: 12)
                                    
                                    // 에러 해소 버튼 (Android: Button with Color(0xFFE1F1FF))
                                    Button(action: {
                                        viewModel.sendErrorCommand(code: 0)
                                    }) {
                                        Text("device_error_e0".localized())
                                            .typography(ElegaiterTypography.Label3)
                                            .foregroundColor(ElegaiterColors.Additional.bluetooth)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 45)
                                    }
                                    .background(Color(red: 0.88, green: 0.95, blue: 1.0)) // Color(0xFFE1F1FF)
                                    .cornerRadius(48)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(ElegaiterColors.Stroke.medium, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }
            } else {
                // 연결되지 않은 경우
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 120)
                    
                    // 블루투스 아이콘 (Android: Icon with size 80.dp)
                    Image(bluetoothIconName)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    
                    Text("device_error_no_device".localized())
                        .typography(ElegaiterTypography.Body3)
                        .foregroundColor(ElegaiterColors.Text.sub2)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    
                    // 디바이스 연결하러 가기 버튼
                    Button(action: {
                        viewModel.navigateToJawsSearch()
                    }) {
                        Text("device_error_connect_button".localized())
                            .typography(ElegaiterTypography.Label3)
                            .foregroundColor(ElegaiterColors.Text.main)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .background(ElegaiterColors.Background.light)
                    .cornerRadius(48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 48)
                            .stroke(ElegaiterColors.Stroke.weak, lineWidth: 1)
                    )
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.coordinator = coordinator
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
}

#Preview {
    DeviceErrorView()
        .environmentObject(AppCoordinator())
}
