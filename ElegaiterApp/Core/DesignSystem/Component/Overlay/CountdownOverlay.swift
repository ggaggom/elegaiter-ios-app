//
//  CountdownOverlay.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 카운트다운 오버레이 컴포넌트
/// 
/// Android의 `CountdownOverlay`를 SwiftUI로 변환
/// - 어두운 배경으로 화면 전체 덮기
/// - 중앙에 카운트다운 프로그레스 바와 안내 메시지 표시
struct CountdownOverlay: View {
    /// 전체 시간 (초)
    let totalSeconds: Int
    /// 남은 시간 (초)
    let remainingTime: Int
    /// 타이틀 텍스트
    let titleText: String
    /// 버튼 텍스트 (선택적)
    var buttonText: String? = nil
    /// 버튼 클릭 핸들러
    var onButtonClick: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // 어두운 배경 (안드로이드: BackgroundDark)
            ElegaiterColors.Background.dark
                .ignoresSafeArea()
                .allowsHitTesting(false) // 클릭 비활성화
            
            // 중앙 컨텐츠
            VStack(spacing: 0) {
                CountdownProgressBar(
                    totalSeconds: totalSeconds,
                    remainingTime: remainingTime
                )
                
                // 타이틀 텍스트 (안드로이드: Headline5, padding(top = 40.dp))
                Text(titleText)
                    .typography(ElegaiterTypography.Headline5)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                
                // 버튼 (선택적)
                if let buttonText = buttonText, let onButtonClick = onButtonClick {
                    PrimaryButton(
                        onClick: onButtonClick
                    ) {
                        Text(buttonText)
                            .typography(ElegaiterTypography.Label1)
                    }
                    .frame(width: 160)
                    .padding(.top, 40)
                }
            }
        }
    }
}

#Preview {
    CountdownOverlay(
        totalSeconds: 5,
        remainingTime: 3,
        titleText: "트레드밀을 시작해 주세요"
    )
}

