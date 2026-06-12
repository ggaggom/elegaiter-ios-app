//
//  AccountEditView.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI

/// 계정 정보 수정 화면
///
/// Android의 `AccountEditScreen`을 SwiftUI로 변환
/// - 사용자 프로필 정보 수정
/// - 이름, 전화번호, 성별, 생년월일, 키, 몸무게 입력
struct AccountEditView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = AccountEditViewModel()
    
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, phone, height, weight
    }
    
    /// 생년월일 표시 형식 (yyyy / MM / dd)
    private var displayBirthday: String {
        if viewModel.uiState.birthday.isEmpty {
            return ""
        }
        
        // yyyy-MM-dd 형식을 yyyy / MM / dd 형식으로 변환
        let components = viewModel.uiState.birthday.split(separator: "-")
        if components.count == 3 {
            return "\(components[0]) / \(components[1]) / \(components[2])"
        }
        return viewModel.uiState.birthday
    }
    
    /// 생년월일 문자열을 Date로 변환
    private func dateFromBirthday(_ birthday: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.date(from: birthday) ?? Date()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "setting_menu_edit_profile".localized(),
                    onBackClick: {
                        viewModel.navigateBack()
                    }
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 입력 필드 영역
                        VStack(spacing: 20) {
                            // 이름 입력
                            LabeledRoundedInputField(
                                labelText: "auth_name".localized(),
                                value: Binding(
                                    get: { viewModel.uiState.name },
                                    set: { viewModel.onValueChange(field: "name", value: $0) }
                                ),
                                placeholder: "auth_name_placeholder".localized(),
                                onValueChange: { viewModel.onValueChange(field: "name", value: $0) },
                                enabled: !viewModel.uiState.isSaving
                            )
                            .focused($focusedField, equals: .name)
                            
                            // 전화번호 입력
                            PhoneNumberInputField(
                                labelText: "auth_phone".localized(),
                                value: Binding(
                                    get: { viewModel.uiState.phone },
                                    set: { viewModel.onValueChange(field: "phone", value: $0) }
                                ),
                                placeholder: "auth_phone_placeholder".localized(),
                                onValueChange: { viewModel.onValueChange(field: "phone", value: $0) },
                                enabled: !viewModel.uiState.isSaving
                            )
                            .focused($focusedField, equals: .phone)
                            
                            // 성별 선택
                            VStack(alignment: .leading, spacing: 0) {
                                Text("auth_gender".localized())
                                    .typography(ElegaiterTypography.Label3)
                                    .foregroundColor(ElegaiterColors.Text.sub1)
                                    .padding(.bottom, 6)
                                
                                HStack(spacing: 6) {
                                    CustomRadioButton(
                                        text: "auth_gender_male".localized(),
                                        selected: viewModel.uiState.gender == "M",
                                        onClick: {
                                            viewModel.onValueChange(field: "gender", value: "M")
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    
                                    CustomRadioButton(
                                        text: "auth_gender_female".localized(),
                                        selected: viewModel.uiState.gender == "F",
                                        onClick: {
                                            viewModel.onValueChange(field: "gender", value: "F")
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                }
                            }
                            
                            // 생년월일 선택
                            Button(action: {
                                showDatePicker = true
                            }) {
                                LabeledRoundedInputField(
                                    labelText: "auth_birthday".localized(),
                                    value: Binding(
                                        get: { displayBirthday },
                                        set: { _ in }
                                    ),
                                    placeholder: "auth_birthday_placeholder".localized(),
                                    onValueChange: { _ in },
                                    enabled: false,
                                    trailingIcon: {
                                        AnyView(
                                            Image("IcDatePicker")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                        )
                                    }
                                )
                            }
                            .disabled(viewModel.uiState.isSaving)
                            .buttonStyle(.plain)
                            
                            // 키 입력
                            LabeledRoundedInputField(
                                labelText: "auth_height".localized(),
                                value: Binding(
                                    get: { viewModel.uiState.height },
                                    set: { viewModel.onValueChange(field: "height", value: $0) }
                                ),
                                placeholder: "auth_height_placeholder".localized(),
                                onValueChange: { viewModel.onValueChange(field: "height", value: $0) },
                                enabled: !viewModel.uiState.isSaving
                            )
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .height)
                            
                            // 몸무게 입력
                            LabeledRoundedInputField(
                                labelText: "auth_weight".localized(),
                                value: Binding(
                                    get: { viewModel.uiState.weight },
                                    set: { viewModel.onValueChange(field: "weight", value: $0) }
                                ),
                                placeholder: "auth_weight_placeholder".localized(),
                                onValueChange: { viewModel.onValueChange(field: "weight", value: $0) },
                                enabled: !viewModel.uiState.isSaving
                            )
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .weight)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 하단 고정 버튼을 위한 여유 공간
                        Spacer()
                            .frame(height: 150)
                    }
                }
                .onTapGesture {
                    // 화면 탭 시 키보드 닫기
                    focusedField = nil
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white) // NavigationStack 배경색 명시
            
            // 하단 고정 저장하기 버튼
            VStack {
                Spacer()
                PrimaryButton(
                    onClick: {
                        viewModel.onSaveClick()
                    },
                    enabled: viewModel.uiState.isSaveEnabled && !viewModel.uiState.isSaving
                ) {
                    if viewModel.uiState.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(ElegaiterColors.Text.main)
                    } else {
                        Text("btn_save".localized())
                            .typography(ElegaiterTypography.Label1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationBarBackButtonHidden(true)
        .localized() // 언어 변경 시 자동 업데이트
        .onAppear {
            viewModel.coordinator = coordinator
            // 생년월일이 이미 설정되어 있으면 DatePicker의 초기값으로 설정
            if !viewModel.uiState.birthday.isEmpty {
                selectedDate = dateFromBirthday(viewModel.uiState.birthday)
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .showToast(let message):
                ToastManager.shared.show(message: message)
            case .saveSuccess:
                viewModel.navigateBack()
            case .navigateBack:
                viewModel.navigateBack()
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedDate,
                onDateSelected: { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.locale = Locale(identifier: "ko_KR")
                    viewModel.onValueChange(field: "birthday", value: formatter.string(from: date))
                    showDatePicker = false
                },
                onCancel: {
                    showDatePicker = false
                }
            )
        }
    }
}

#Preview {
    AccountEditView()
        .environmentObject(AppCoordinator())
}
