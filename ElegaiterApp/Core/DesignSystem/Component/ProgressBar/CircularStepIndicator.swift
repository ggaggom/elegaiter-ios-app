//
//  CircularStepIndicator.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 원형 스텝 인디케이터 컴포넌트
/// 
/// Android의 `CircularStepIndicator`를 SwiftUI로 변환
/// - 현재 단계를 원형으로 표시
/// - 총 5단계 중 현재 단계를 시각화
/// - 원 안에 단계 번호 텍스트 표시
struct CircularStepIndicator: View {
    /// 현재 단계 (1~5)
    let currentStep: Int
    
    /// 총 단계 수 (기본값: 5)
    let totalSteps: Int = 5
    
    /// 원 크기 (기본값: 32, 안드로이드: 32.dp)
    var circleSize: CGFloat = 32
    
    var body: some View {
        HStack(spacing: 8) { // 안드로이드: 8.dp
            ForEach(1...totalSteps, id: \.self) { step in
                let isActive = step == currentStep
                
                ZStack {
                    // 원 배경 (안드로이드: activeBrush 또는 BackgroundLight)
                    Circle()
                        .fill(
                            isActive
                                ? ElegaiterColors.Green.green300
                                : ElegaiterColors.Background.light
                        )
                        .frame(width: circleSize, height: circleSize)
                    
                    // 단계 번호 텍스트 (안드로이드: stepNumber.toString())
                    Text("\(step)")
                        .typography(ElegaiterTypography.Body3)
                        .foregroundColor(
                            isActive
                                ? ElegaiterColors.Text.main
                                : ElegaiterColors.Text.disabled
                        )
                }
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularStepIndicator(currentStep: 1)
        CircularStepIndicator(currentStep: 3)
        CircularStepIndicator(currentStep: 5)
    }
    .padding()
}
