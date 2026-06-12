//
//  PrimaryButton.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 기본 버튼 컴포넌트
/// 
/// Android의 `PrimaryButton`을 SwiftUI로 변환
/// - 주요 액션에 사용되는 버튼
/// - 하단 정보 텍스트 옵션 지원
struct PrimaryButton<Content: View>: View {
    /// 버튼 클릭 액션
    let onClick: () -> Void
    /// 활성화 여부
    var enabled: Bool = true
    /// 버튼 높이 (기본값: 56, 안드로이드와 동일)
    var height: CGFloat = 56
    /// 하단 정보 표시 여부
    var showBottomInfo: Bool = false
    /// 단일 하단 링크 표시 여부
    var showSingleBottomLink: Bool = false
    /// 하단 정보 텍스트 1
    var bottomInfoText1: String = ""
    /// 하단 정보 텍스트 2 (링크)
    var bottomInfoText2: String = ""
    /// 하단 텍스트 클릭 액션
    var onBottomTextClick: (() -> Void)? = nil
    /// 버튼 내용
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            // 버튼
            Button(action: onClick) {
                HStack {
                    content()
                        .foregroundColor(enabled ? ElegaiterColors.Text.main : ElegaiterColors.Text.disabled)
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(
                    Group {
                        if enabled {
                            // 활성화: Green300 → Green400 그라데이션
                            LinearGradient(
                                colors: [ElegaiterColors.Green.green300, ElegaiterColors.Green.green400],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            // 비활성화: BackgroundLight 배경 + StrokeMedium 테두리
                            ElegaiterColors.Background.light
                        }
                    }
                )
                .overlay(
                    // 비활성화일 때만 테두리 표시
                    Group {
                        if !enabled {
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(ElegaiterColors.Stroke.medium, lineWidth: 1)
                        }
                    }
                )
                .cornerRadius(32)
            }
            .disabled(!enabled)
            
            // 하단 정보 (두 개의 텍스트)
            if showBottomInfo {
                HStack(spacing: 12) {
                    Text(bottomInfoText1)
                        .typography(ElegaiterTypography.Label4)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                    
                    Button(action: onBottomTextClick ?? {}) {
                        Text(bottomInfoText2)
                            .typography(ElegaiterTypography.Label4)
                            .foregroundColor(ElegaiterColors.Green.green500)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            }
            
            // 단일 하단 링크
            if showSingleBottomLink {
                Button(action: onBottomTextClick ?? {}) {
                    Text(bottomInfoText1)
                        .typography(ElegaiterTypography.Label3)
                        .foregroundColor(ElegaiterColors.Text.sub2)
                        .underline()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(
            onClick: {},
            enabled: true
        ) {
            Text("로그인")
        }
        
        PrimaryButton(
            onClick: {},
            enabled: false
        ) {
            Text("로그인 (비활성화)")
        }
        
        PrimaryButton(
            onClick: {},
            enabled: true,
            showBottomInfo: true,
            bottomInfoText1: "계정이 없으신가요?",
            bottomInfoText2: "회원가입하기",
            onBottomTextClick: {}
        ) {
            Text("로그인")
        }
        
        PrimaryButton(
            onClick: {},
            enabled: true,
            showSingleBottomLink: true,
            bottomInfoText1: "단일 링크 텍스트",
            onBottomTextClick: {}
        ) {
            Text("버튼")
        }
        
        PrimaryButton(
            onClick: {},
            enabled: true
        ) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(ElegaiterColors.Text.main)
                Text("로딩 중...")
            }
        }
    }
    .padding()
}
