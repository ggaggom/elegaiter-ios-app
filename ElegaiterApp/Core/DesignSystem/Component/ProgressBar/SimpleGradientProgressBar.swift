//
//  SimpleGradientProgressBar.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 단순 그라데이션 프로그레스 바 컴포넌트
/// 
/// Android의 `SimpleGradientProgressBar`를 SwiftUI로 변환
/// - 목표 시간 달성률을 그라데이션으로 표시
/// - 수평 프로그레스 바
struct SimpleGradientProgressBar: View {
    /// 진행률 (0.0 ~ 1.0)
    let progress: Float
    
    /// 높이 (안드로이드: 기본값 8.dp)
    var height: CGFloat = 8
    
    var body: some View {
        // 안드로이드: Box(fillMaxWidth, height), clip(RoundedCornerShape(4.dp)), background(StrokeWeak)
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경 (안드로이드: StrokeWeak)
                RoundedRectangle(cornerRadius: 4)
                    .fill(ElegaiterColors.Stroke.weak)
                    .frame(width: geometry.size.width, height: height)
                
                // 진행 바 (안드로이드: Brush.linearGradient(Green300 -> Green400), fillMaxWidth(safeProgress))
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
                    .frame(width: geometry.size.width * CGFloat(min(max(progress, 0.0), 1.0)), height: height)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    VStack(spacing: 20) {
        SimpleGradientProgressBar(progress: 0.0)
        SimpleGradientProgressBar(progress: 0.3)
        SimpleGradientProgressBar(progress: 0.5)
        SimpleGradientProgressBar(progress: 0.7)
        SimpleGradientProgressBar(progress: 1.0)
    }
    .padding()
}
