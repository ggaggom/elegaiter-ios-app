//
//  ExerciseInfoView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK
import os.log

/// 운동 정보 입력 화면
///
/// Android의 `ExerciseInfoScreen`을 SwiftUI로 변환
/// - 운동 정보 입력 (속도, 경사도, 목표 시간)
/// - 인덱스 워킹 발 선택
/// - 기본 설정 저장 옵션
/// - 오늘 컨디션 선택
/// - 블루투스 연결 상태 확인
struct ExerciseInfoView: View {

    private static let logger = Logger(subsystem: "com.elegaiter.app", category: "ExerciseInfoView")

    @ObservedObject var router: ExerciseRouter
    @ObservedObject var viewModel: ExerciseSessionViewModel
    
    @State private var showDisconnectionDialog = false
    @State private var previousBleConnectionState: BleConnectionState = .disconnected
    @FocusState private var focusedField: Field?
    
    enum Field {
        case speed
        case incline
        case duration
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // 헤더 (고정)
                ElegaiterTopBar(
                    title: "exercise_setup_title".localized(),
                    onBackClick: {
                        // 뒤로가기: NavigationStack의 pop 사용
                        if let coordinator = router.coordinator {
                            coordinator.pop(in: Binding(
                                get: { coordinator.exercisePath },
                                set: { coordinator.exercisePath = $0 }
                            ))
                        }
                    },
                    showProgress: true,
                    currentStep: 1,
                    totalStep: 2
                )
                
                // 스크롤 가능한 콘텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 블루투스 연결 상태 (연결된 경우만 표시)
                        if viewModel.bleConnectionState == .connected {
                            WhiteGrayCard {
                                ConnectionStatusRow(
                                    deviceName: "device_jaws".localized(),
                                    deviceType: viewModel.uiState.connectedDevice?.name ?? "",
                                    statusText: "device_connected".localized(),
                                    statusTextColor: .white,
                                    statusBackgroundColor: ElegaiterColors.Additional.bluetooth,
                                    showCheckIcon: true
                                )
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            // 안내 텍스트
                            Text("exercise_setup_description".localized())
                                .typography(ElegaiterTypography.Body3)
                                .foregroundColor(ElegaiterColors.Text.main)
                                .padding(.horizontal, 20)
                                .padding(.top, 40)
                            
                            // 입력 필드
                            VStack(spacing: 28) {
                                LabeledRoundedInputField(
                                    labelText: "exercise_setup_speed".localized(),
                                    value: Binding(
                                        get: { viewModel.uiState.speed },
                                        set: { viewModel.onSpeedChange($0) }
                                    ),
                                    placeholder: "exercise_setup_speed_placeholder".localized(),
                                    onValueChange: viewModel.onSpeedChange
                                )
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .speed)
                                
                                LabeledRoundedInputField(
                                    labelText: "exercise_setup_incline".localized(),
                                    value: Binding(
                                        get: { viewModel.uiState.incline },
                                        set: { viewModel.onInclineChange($0) }
                                    ),
                                    placeholder: "exercise_setup_incline_placeholder".localized(),
                                    onValueChange: viewModel.onInclineChange
                                )
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .incline)
                                
                                LabeledRoundedInputField(
                                    labelText: "exercise_setup_time".localized(),
                                    value: Binding(
                                        get: { viewModel.uiState.duration },
                                        set: { viewModel.onDurationChange($0) }
                                    ),
                                    placeholder: "exercise_setup_time_placeholder".localized(),
                                    onValueChange: viewModel.onDurationChange
                                )
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .duration)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // 인덱스 워킹 발 선택
                            Text("exercise_setup_select_index_foot".localized())
                                .typography(ElegaiterTypography.Body3)
                                .foregroundColor(ElegaiterColors.Text.main)
                                .padding(.horizontal, 20)
                                .padding(.top, 32)
                            
                            HStack(spacing: 6) {
                                CustomRadioButton(
                                    text: "exercise_left_foot".localized(),
                                    selected: viewModel.uiState.selectedFoot == "left",
                                    onClick: {
                                        viewModel.onFootChange("left")
                                    }
                                )
                                
                                CustomRadioButton(
                                    text: "exercise_right_foot".localized(),
                                    selected: viewModel.uiState.selectedFoot == "right",
                                    onClick: {
                                        viewModel.onFootChange("right")
                                    }
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            
                            // 기본 설정 저장 체크박스
                            HStack {
                                Spacer()
                                
                                Text("exercise_setup_default".localized())
                                    .typography(ElegaiterTypography.Label4)
                                    .foregroundColor(ElegaiterColors.Text.sub1)
                                    .padding(.trailing, 6)
                                
                                CustomCheckbox(
                                    checked: Binding(
                                        get: { viewModel.uiState.autoSave },
                                        set: { viewModel.onAutoSaveChange($0) }
                                    ),
                                    onCheckedChange: viewModel.onAutoSaveChange
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                            
                            // 오늘 컨디션 선택
                            Text("exercise_condition_prompt".localized())
                                .typography(ElegaiterTypography.Body3)
                                .foregroundColor(ElegaiterColors.Text.main)
                                .padding(.horizontal, 20)
                                .padding(.top, 40)
                            
                            HStack(spacing: 8) {
                                CustomRadioButton(
                                    text: "exercise_condition_good".localized(),
                                    selected: viewModel.uiState.mood == "GOOD",
                                    onClick: {
                                        viewModel.onMoodChange("GOOD")
                                    }
                                )
                                
                                CustomRadioButton(
                                    text: "exercise_condition_soso".localized(),
                                    selected: viewModel.uiState.mood == "SOSO",
                                    onClick: {
                                        viewModel.onMoodChange("SOSO")
                                    }
                                )
                                
                                CustomRadioButton(
                                    text: "exercise_condition_tired".localized(),
                                    selected: viewModel.uiState.mood == "TIRED",
                                    onClick: {
                                        viewModel.onMoodChange("TIRED")
                                    }
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 20)
                        }
                        
                        // 하단 여백 (버튼 공간 확보)
                        Spacer()
                            .frame(height: 150)
                    }
                }
                .id("exerciseInfoScrollView") // 고유 ID로 스크롤 상태 분리
                .onTapGesture {
                    // 화면 탭 시 키보드 닫기
                    focusedField = nil
                }
            }
            
            // 하단 버튼 (고정)
            VStack(spacing: 10) {
                PrimaryButton(
                    onClick: {
                        viewModel.navigateToInfoIndexWalking()
                    },
                    enabled: viewModel.uiState.isFormValid
                ) {
                    Text("btn_next".localized())
                        .typography(ElegaiterTypography.Label1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .padding(.bottom, 20)
            .background(Color(.systemBackground))
            
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(.systemBackground)) // 전체 배경 설정
        .navigationBarBackButtonHidden(true) // ElegaiterTopBar 사용하므로 기본 back 버튼 숨김
        .onAppear {
            previousBleConnectionState = viewModel.bleConnectionState
            if let device = viewModel.uiState.connectedDevice {
                Self.logger.debug("📱 [ExerciseInfoView] onAppear - 연결된 디바이스: \(device.name), MAC: \(device.address)")
            } else {
                Self.logger.debug("📱 [ExerciseInfoView] onAppear - 연결된 디바이스 없음")
            }
            
            // 레이아웃 강제 업데이트 (다른 탭에서 돌아올 때 버튼 위치 고정)
            DispatchQueue.main.async {
                // 레이아웃 재계산을 위한 작은 지연
            }
        }
        .onChange(of: viewModel.bleConnectionState) { newValue in
            // 연결 상태가 CONNECTED가 아니면 다이얼로그 표시
            if newValue != .connected && previousBleConnectionState == .connected {
                showDisconnectionDialog = true
            }
            previousBleConnectionState = newValue
        }
        .overlay {
            // 블루투스 연결 끊김 다이얼로그
            if showDisconnectionDialog {
                StyledAlertDialog(
                    isPresented: $showDisconnectionDialog,
                    title: "exercise_bluetooth_connection_lost_title".localized(),
                    message: "exercise_info_bluetooth_disconnected_message".localized(),
                    content: {
                        EmptyView()
                    },
                    confirmText: "exercise_info_navigate_to_search".localized(),
                    onConfirm: {
                        navigateToJawsSearch()
                    },
                    dismissText: "btn_cancel".localized(),
                    onDismiss: {
                        // 다이얼로그만 닫기
                    }
                )
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    /// JawsSearch 화면으로 이동
    ///
    /// ExerciseGraph를 벗어나서 JawsSearch 화면으로 이동합니다.
    private func navigateToJawsSearch() {
        // Coordinator를 통해 JawsSearch 화면으로 이동
        // ExerciseGraph를 벗어나므로 exercisePath를 초기화하고 새로 추가
        if let coordinator = router.coordinator {
            // 현재 ExerciseGraph의 모든 화면을 제거하고 JawsSearch로 이동
            coordinator.exercisePath = NavigationPath()
            coordinator.navigateInExercise(to: .jawsSearch)
        }
    }
}

#Preview {
    let coordinator = AppCoordinator()
    let router = ExerciseRouter(coordinator: coordinator)
    return ExerciseInfoView(router: router, viewModel: router.sessionViewModel)
}
