//
//  StepTimeCard.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 스텝 시간 분석 카드 컴포넌트
/// 
/// Android의 `StepTimeCard`를 SwiftUI로 변환
/// - 스텝 시간 또는 보폭 시간 분석 결과를 카드 형태로 표시
/// - Median 시간과 IQR 시간을 표시
struct StepTimeCard: View {
    /// 제목 (예: "좌 → 우", "우 → 좌", "좌 → 좌", "우 → 우")
    let title: String
    /// Median 시간 (초)
    let value1: String
    /// IQR 시간 (초)
    let value2: String
    
    var body: some View {
        // 안드로이드: Box with border, Column (horizontalAlignment = CenterHorizontally)
        VStack(alignment: .center, spacing: 0) {
            // 제목 (안드로이드: Label3, Green500)
            Text(title)
                .typography(ElegaiterTypography.Label3)
                .foregroundColor(ElegaiterColors.Green.green500)
            
            // 구분선 (안드로이드: Box with height = 1.dp, StrokeMedium)
            Rectangle()
                .fill(ElegaiterColors.Stroke.medium)
                .frame(height: 1)
                .padding(.vertical, 6)
            
            // Median 행 (안드로이드: Caption1 (TextSub2), Headline4 (TextMain))
            HStack {
                Text("Median")
                    .typography(ElegaiterTypography.Caption1)
                    .foregroundColor(ElegaiterColors.Text.sub2)
                Spacer()
                Text("\(value1) s")
                    .typography(ElegaiterTypography.Headline4)
                    .foregroundColor(ElegaiterColors.Text.main)
            }
            
            // IQR 행 (안드로이드: Caption1 (TextSub2), Headline4 (TextMain))
            HStack {
                Text("IQR")
                    .typography(ElegaiterTypography.Caption1)
                    .foregroundColor(ElegaiterColors.Text.sub2)
                Spacer()
                Text("\(value2) s")
                    .typography(ElegaiterTypography.Headline4)
                    .foregroundColor(ElegaiterColors.Text.main)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .overlay(
            // 안드로이드: border (1.dp, StrokeMedium, RoundedCornerShape(12.dp))
            RoundedRectangle(cornerRadius: 12)
                .stroke(ElegaiterColors.Stroke.medium, lineWidth: 1)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        StepTimeCard(
            title: "좌 → 우",
            value1: "0.5",
            value2: "0.2"
        )
        
        StepTimeCard(
            title: "우 → 좌",
            value1: "0.6",
            value2: "0.3"
        )
    }
    .padding()
}
