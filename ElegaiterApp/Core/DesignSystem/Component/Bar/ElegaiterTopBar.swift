//
//  ElegaiterTopBar.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// Elegaiter TopBar 컴포넌트
/// 
/// Android의 `ElegaiterTopbar`를 SwiftUI로 변환
/// - 뒤로가기 버튼
/// - 제목
/// - 진행 표시 (선택적)
/// - 우측 액션 버튼 (선택적)
struct ElegaiterTopBar: View {
    /// 제목
    let title: String
    /// 뒤로가기 액션
    let onBackClick: () -> Void
    /// 진행 표시 여부
    var showProgress: Bool = false
    /// 현재 단계
    var currentStep: Int = 1
    /// 전체 단계
    var totalStep: Int = 3
    /// 우측 액션 버튼 (선택적)
    var trailingAction: (() -> AnyView)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 뒤로가기 버튼 + 진행 표시 + 우측 액션 영역
            HStack(spacing: 0) {
                // 뒤로가기 버튼
                Button(action: {
                    onBackClick()
                }) {
                    Image("ChevronLeft")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(ElegaiterColors.Text.main)
                        .frame(width: 36, height: 36)
                }
                
                // 진행 표시 (선택적)
                if showProgress {
                    HStack(spacing: 6) {
                        ForEach(0..<totalStep, id: \.self) { index in
                            if index == currentStep - 1 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                ElegaiterColors.Green.green300,
                                                ElegaiterColors.Green.green400
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 8)
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(ElegaiterColors.Stroke.weak)
                                    .frame(height: 8)
                            }
                        }
                    }
                    .padding(.leading, 0)
                }
                
                Spacer()
                
                // 우측 액션 버튼 (선택적)
                if let trailingAction = trailingAction {
                    trailingAction()
                }
            }
            
            // 제목
            Text(title)
                .typography(ElegaiterTypography.Headline3)
                .foregroundColor(ElegaiterColors.Text.main)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                .padding(.leading, 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 0) {
        ElegaiterTopBar(
            title: "운동 준비",
            onBackClick: {},
            showProgress: true,
            currentStep: 2,
            totalStep: 2
        )
        
        ElegaiterTopBar(
            title: "운동 정보 입력",
            onBackClick: {},
            showProgress: true,
            currentStep: 1,
            totalStep: 2
        )
        
        ElegaiterTopBar(
            title: "설정",
            onBackClick: {}
        )
        
        Spacer()
    }
}
