//
//  ToSView.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 이용약관 동의 화면
///
/// Android의 `ToSScreen`을 SwiftUI로 변환
/// - 전체 동의 버튼
/// - 개별 약관 동의 체크박스
/// - 약관 상세보기 기능
/// - 다음 버튼 (모든 약관 동의 시 활성화)
struct ToSView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = ToSViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "setting_menu_terms_policy".localized(),
                    onBackClick: {
                        dismiss()
                    },
                    showProgress: true,
                    currentStep: 1,
                    totalStep: 3
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 전체 동의 버튼
                        AgreeAllButton(
                            checked: Binding(
                                get: { viewModel.agreedAll },
                                set: { viewModel.onAgreeAllChanged($0) }
                            ),
                            onCheckedChange: viewModel.onAgreeAllChanged
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        
                        // 개별 약관 동의 항목들
                        VStack(spacing: 20) {
                            // 이용 약관
                            AgreementRow(
                                label: "terms_title_service".localized(),
                                checked: viewModel.agreedTerms,
                                onCheckedChange: viewModel.onTermsChanged,
                                onViewDetail: {
                                    viewModel.onViewDetailClicked(fileName: "terms_of_service.txt")
                                }
                            )
                            
                            // 개인정보 처리방침
                            AgreementRow(
                                label: "terms_title_privacy".localized(),
                                checked: viewModel.agreedPrivacy,
                                onCheckedChange: viewModel.onPrivacyChanged,
                                onViewDetail: {
                                    viewModel.onViewDetailClicked(fileName: "privacy_policy.txt")
                                }
                            )
                            
                            // 위치정보 서비스 이용 동의
                            AgreementRow(
                                label: "terms_title_location".localized(),
                                checked: viewModel.agreedLocation,
                                onCheckedChange: viewModel.onLocationChanged,
                                onViewDetail: {
                                    viewModel.onViewDetailClicked(fileName: "location_terms.txt")
                                }
                            )
                            
                            // 민감정보 수집 및 이용 동의
                            AgreementRow(
                                label: "terms_title_sensitive".localized(),
                                checked: viewModel.agreedSPI,
                                onCheckedChange: viewModel.onSPIChanged,
                                onViewDetail: {
                                    viewModel.onViewDetailClicked(fileName: "sensitive_info.txt")
                                }
                            )
                        }
                        .padding(.top, 28)
                        .padding(.horizontal, 28)
                        
                        // 스크롤 가능한 공간 확보 (버튼 높이 + 패딩)
                        Spacer()
                            .frame(height: 120)
                    }
                }
            }
            .background(Color.white) // NavigationStack 배경색 명시
            .navigationBarBackButtonHidden(true)
            
            // 하단 고정 동의하고 가입 계속 버튼
            VStack {
                Spacer()
                PrimaryButton(
                    onClick: {
                        viewModel.navigateToSignUp()
                    },
                    enabled: viewModel.allAgreed
                ) {
                    Text("sign_up_agree_continue".localized())
                        .typography(ElegaiterTypography.Label1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                viewModel.coordinator = coordinator
            }
            .sheet(item: $viewModel.selectedTerm) { termItem in
                TermsBottomSheet(
                    termItem: termItem,
                    onDismissClick: {
                        viewModel.onDismissDetail()
                    }
                )
                .presentationDetents([.large, .medium])
                .presentationDragIndicator(.hidden)
                .modifier(CornerRadiusModifier(radius: 20))
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
}

// MARK: - CustomCheckboxWrapper Component

/// CustomCheckbox를 외부 값 변경에 반응하도록 래핑하는 컴포넌트
private struct CustomCheckboxWrapper: View {
    let checked: Bool
    let onCheckedChange: (Bool) -> Void
    
    var body: some View {
        CustomCheckbox(
            checked: checked,
            onCheckedChange: onCheckedChange
        )
        .onChange(of: checked) { newValue in
            // 외부 값이 변경되면 CustomCheckbox 내부 상태도 업데이트됨
            // (CustomCheckbox의 onChange에서 처리)
        }
    }
}

// MARK: - AgreementRow Component

/// 개별 약관 동의 행 컴포넌트
///
/// Android의 `AgreementRow`를 SwiftUI로 변환
/// - 체크박스와 약관명
/// - 상세보기 버튼
struct AgreementRow: View {
    /// 약관 라벨
    let label: String
    /// 체크 상태
    let checked: Bool
    /// 체크 상태 변경 콜백
    let onCheckedChange: (Bool) -> Void
    /// 상세보기 클릭 콜백
    let onViewDetail: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 체크박스
            CustomCheckboxWrapper(
                checked: checked,
                onCheckedChange: onCheckedChange
            )
            
            // 약관명
            Text(label)
                .typography(ElegaiterTypography.Label2)
                .foregroundColor(ElegaiterColors.Text.sub2)
                .padding(.leading, 8)
                .padding(.trailing, 6)
            
            // (필수) 텍스트
            Text("terms_required".localized())
                .typography(ElegaiterTypography.Label2)
                .foregroundColor(ElegaiterColors.Green.green500)
            
            Spacer()
            
            // 상세보기 버튼
            Button(action: onViewDetail) {
                Text("terms_view_all".localized())
                    .typography(ElegaiterTypography.Label3)
                    .foregroundColor(ElegaiterColors.Text.sub1)
                    .underline()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ToSView()
            .environmentObject(AppCoordinator())
    }
}

