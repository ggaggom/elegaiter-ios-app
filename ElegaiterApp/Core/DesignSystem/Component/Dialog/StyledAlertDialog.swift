//
//  StyledAlertDialog.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import os.log

/// 스타일이 적용된 Alert 다이얼로그 컴포넌트
/// 
/// Android의 `StyledAlertDialog`를 SwiftUI로 변환
/// - 커스텀 콘텐츠 지원
/// - 확인 버튼 및 하단 텍스트 링크 지원
struct StyledAlertDialog<Content: View>: View {
    /// 다이얼로그 표시 여부
    @Binding var isPresented: Bool
    
    /// 제목
    let title: String
    
    /// 메시지 (선택적)
    var message: String? = nil
    
    /// 커스텀 콘텐츠
    @ViewBuilder let content: () -> Content
    
    /// 확인 버튼 텍스트
    let confirmText: String
    
    /// 확인 버튼 액션
    let onConfirm: () -> Void
    
    /// 취소 버튼 텍스트 (nil이면 취소 버튼 숨김)
    var dismissText: String? = nil
    
    /// 취소 버튼 액션
    var onDismiss: (() -> Void)? = nil
    
    /// 하단 텍스트 표시 여부
    var showBottomText: Bool = false
    
    /// 하단 텍스트
    var bottomText: String = ""
    
    /// 하단 텍스트 클릭 액션
    var onBottomTextClick: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // 배경 오버레이
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    // 배경 탭 시 닫기 (선택적)
                }
            
            // 다이얼로그 컨텐츠
            VStack(spacing: 0) {
                // 제목
                Text(title)
                    .typography(ElegaiterTypography.Headline5)
                    .foregroundColor(ElegaiterColors.Text.main)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
                
                // 메시지 (선택적)
                if let message = message {
                    Text(message)
                        .typography(ElegaiterTypography.Body2)
                        .foregroundColor(ElegaiterColors.Text.sub2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 24)
                }
                
                // 커스텀 콘텐츠
                content()
                
                // 버튼 영역
                HStack(spacing: 8) {
                    // 취소 버튼 (dismissText가 있는 경우만 표시)
                    if let dismissText = dismissText, let onDismiss = onDismiss {
                        Button(action: {
                            isPresented = false
                            onDismiss()
                        }) {
                            Text(dismissText)
                                .typography(ElegaiterTypography.Label1)
                                .foregroundColor(ElegaiterColors.Text.main)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(ElegaiterColors.Stroke.medium, lineWidth: 1)
                                )
                                .cornerRadius(32)
                        }
                    }
                    
                    // 확인 버튼 (PrimaryButton 사용)
                    PrimaryButton(
                        onClick: {
                            isPresented = false
                            onConfirm()
                        },
                        enabled: true
                    ) {
                        Text(confirmText)
                            .typography(ElegaiterTypography.Label1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 0)
                
                // 하단 텍스트
                if showBottomText {
                    Button(action: {
                        if let onBottomTextClick = onBottomTextClick {
                            isPresented = false
                            onBottomTextClick()
                        }
                    }) {
                        Text(bottomText)
                            .typography(ElegaiterTypography.Label3)
                            .foregroundColor(ElegaiterColors.Text.sub2)
                            .underline()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        private static let logger = Logger(subsystem: "com.elegaiter.app", category: "StyledAlertDialog+Preview")
        @State private var showDialog = true

        var body: some View {
            ZStack {
                Color.gray.opacity(0.3)
                
                if showDialog {
                    StyledAlertDialog(
                        isPresented: $showDialog,
                        title: "아이디 찾기 완료",
                        message: "회원님의 아이디를 찾았어요",
                        content: {
                            LabeledRoundedInputField(
                                labelText: "아이디",
                                value: .constant("testuser123"),
                                placeholder: "",
                                onValueChange: { _ in },
                                enabled: false
                            )
                        },
                        confirmText: "로그인하기",
                        onConfirm: {
                            Self.logger.debug("로그인하기 클릭")
                        },
                        showBottomText: true,
                        bottomText: "비밀번호 찾기",
                        onBottomTextClick: {
                            Self.logger.debug("비밀번호 찾기 클릭")
                        }
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}
