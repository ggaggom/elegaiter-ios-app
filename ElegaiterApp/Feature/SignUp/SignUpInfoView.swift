//
//  SignUpInfoView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 회원가입 화면 (추가 정보 입력)
/// 
/// Android의 `SignUpInfoScreen`을 SwiftUI로 변환
/// - 이름, 성별, 생년월일, 전화번호, 키, 몸무게 입력
/// - 회원가입 버튼
/// - 회원가입 성공 다이얼로그
struct SignUpInfoView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @ObservedObject var viewModel: SignUpViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    
    /// 초기화 (SignUpView에서 생성한 ViewModel을 전달받음)
    init(viewModel: SignUpViewModel) {
        self.viewModel = viewModel
    }
    
    /// 생년월일 문자열을 Date로 변환
    private func dateFromBirthday(_ birthday: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.date(from: birthday) ?? Date()
    }
    
    /// 포커스 필드 열거형
    enum Field {
        case name
        case phone
        case height
        case weight
    }
    
    /// 생년월일 표시 형식 (yyyy / MM / dd)
    private var displayBirthday: String {
        if viewModel.birthday.isEmpty {
            return ""
        }
        
        // yyyy-MM-dd 형식을 yyyy / MM / dd 형식으로 변환
        let components = viewModel.birthday.split(separator: "-")
        if components.count == 3 {
            return "\(components[0]) / \(components[1]) / \(components[2])"
        }
        return viewModel.birthday
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "sign_up_info_title".localized(),
                    onBackClick: {
                        dismiss()
                    },
                    showProgress: true,
                    currentStep: 3,
                    totalStep: 3
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
                                value: $viewModel.name,
                                placeholder: "auth_name_placeholder".localized(),
                                onValueChange: viewModel.updateName,
                                enabled: !viewModel.isRegistering
                            )
                            .focused($focusedField, equals: .name)
                            
                            // 전화번호 입력
                            PhoneNumberInputField(
                                labelText: "auth_phone".localized(),
                                value: $viewModel.phone,
                                placeholder: "auth_phone_placeholder".localized(),
                                onValueChange: viewModel.updatePhone,
                                enabled: !viewModel.isRegistering
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
                                        selected: viewModel.gender == "M",
                                        onClick: {
                                            viewModel.updateGender("M")
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    
                                    CustomRadioButton(
                                        text: "auth_gender_female".localized(),
                                        selected: viewModel.gender == "F",
                                        onClick: {
                                            viewModel.updateGender("F")
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
                            .disabled(viewModel.isRegistering)
                            .buttonStyle(.plain)
                            
                            // 키 입력
                            LabeledRoundedInputField(
                                labelText: "auth_height".localized(),
                                value: $viewModel.height,
                                placeholder: "signup_height_placeholder".localized(),
                                onValueChange: viewModel.updateHeight,
                                enabled: !viewModel.isRegistering
                            )
                            .focused($focusedField, equals: .height)
                            .keyboardType(.decimalPad)
                            
                            // 몸무게 입력
                            LabeledRoundedInputField(
                                labelText: "auth_weight".localized(),
                                value: $viewModel.weight,
                                placeholder: "signup_weight_placeholder".localized(),
                                onValueChange: viewModel.updateWeight,
                                enabled: !viewModel.isRegistering
                            )
                            .focused($focusedField, equals: .weight)
                            .keyboardType(.decimalPad)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                        
                        // 하단 고정 버튼을 위한 여유 공간
                        Spacer()
                            .frame(height: 150)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    // 화면 탭 시 키보드 닫기
                    focusedField = nil
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white) // NavigationStack 배경색 명시
            
            // 하단 고정 회원가입 버튼
            VStack(spacing: 0) {
                PrimaryButton(
                    onClick: {
                        viewModel.registerUser()
                    },
                    enabled: viewModel.isRegisterEnabled && !viewModel.isRegistering
                ) {
                    if viewModel.isRegistering {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("sign_up_title".localized())
                            .typography(ElegaiterTypography.Label1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.coordinator = coordinator
            // 생년월일이 이미 설정되어 있으면 DatePicker의 초기값으로 설정
            if !viewModel.birthday.isEmpty {
                selectedDate = dateFromBirthday(viewModel.birthday)
            }
        }
        .onReceive(viewModel.eventSubject) { event in
            handleEvent(event)
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedDate,
                onDateSelected: { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.locale = Locale(identifier: "ko_KR")
                    viewModel.updateBirthday(formatter.string(from: date))
                    showDatePicker = false
                },
                onCancel: {
                    showDatePicker = false
                }
            )
        }
        .overlay {
            // 회원가입 성공 다이얼로그
            if viewModel.showSuccessDialog {
                StyledAlertDialog(
                    isPresented: Binding(
                        get: { viewModel.showSuccessDialog },
                        set: { newValue in
                            if !newValue {
                                viewModel.showSuccessDialog = false
                            }
                        }
                    ),
                    title: "sign_up_completed".localized(),
                    message: "sign_up_success_message".localized(),
                    content: {
                        EmptyView()
                    },
                    confirmText: "btn_confirm".localized(),
                    onConfirm: {
                        viewModel.onRegistrationSuccessDialogConfirmed()
                    }
                )
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    // MARK: - Private Methods
    
    /// 이벤트 처리
    private func handleEvent(_ event: SignUpEvent) {
        switch event {
        case .navigateToSignUpInfo:
            // 이미 SignUpInfo 화면이므로 무시
            break
            
        case .navigateToLogin:
            // ViewModel 정리 후 로그인 화면으로 이동
            coordinator.clearSignUpViewModel()
            viewModel.navigateToLogin()
            
        case .showToast(let message):
            // 글로벌 토스트로 메시지 표시
            ToastManager.shared.show(message: message)
        }
    }
}

// MARK: - DatePickerSheet Component

/// 생년월일 선택 시트 컴포넌트
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker(
                    "auth_birthday".localized(),
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                
                Spacer()
            }
            .navigationTitle("signup_datepicker_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onCancel) {
                        Text("btn_cancel".localized())
                            .typography(ElegaiterTypography.Label4)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDateSelected(selectedDate)
                    }) {
                        Text("btn_confirm".localized())
                            .typography(ElegaiterTypography.Label4)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        SignUpInfoView(viewModel: SignUpViewModel())
            .environmentObject(AppCoordinator())
    }
}
