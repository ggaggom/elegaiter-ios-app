//
//  StepCardGrid.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 걸음 관련 카드 그리드 컴포넌트
/// 
/// Android의 `StepCardGrid`를 SwiftUI로 변환
/// - 발 강도, 컨디션, 케이던스 등을 그리드 형태로 표시
struct StepCardGrid: View {
    /// 카드 데이터 (제목, 값, 아이콘 이름)
    let items: [(title: String, value: String, icon: String)]
    
    var body: some View {
        // 안드로이드: Column(verticalArrangement = spacedBy(8.dp), modifier = Modifier.fillMaxWidth().padding(top = 8.dp))
        VStack(spacing: 8) {
            // 2x2 그리드로 배치
            ForEach(0..<(items.count + 1) / 2, id: \.self) { rowIndex in
                // 안드로이드: Row(horizontalArrangement = spacedBy(8.dp))
                HStack(spacing: 8) {
                    // 첫 번째 카드
                    if rowIndex * 2 < items.count {
                        InfoCard(
                            title: items[rowIndex * 2].title,
                            value: items[rowIndex * 2].value,
                            icon: items[rowIndex * 2].icon
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                    
                    // 두 번째 카드
                    if rowIndex * 2 + 1 < items.count {
                        InfoCard(
                            title: items[rowIndex * 2 + 1].title,
                            value: items[rowIndex * 2 + 1].value,
                            icon: items[rowIndex * 2 + 1].icon
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

/// 개별 정보 카드 (안드로이드: InfoCard)
private struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        // 안드로이드: BackgroundLightCard
        // height: 72, padding(top: 12, right: 16, bottom: 12, left: 16), border-radius: 12
        VStack(alignment: .leading, spacing: 0) {
            // 제목 (안드로이드: Caption1, TextSub2)
            Text(title)
                .typography(ElegaiterTypography.Caption1)
                .foregroundColor(ElegaiterColors.Text.sub2)
            
            // 값과 아이콘 (안드로이드: Row, verticalAlignment = Bottom, horizontalArrangement = SpaceBetween)
            HStack(alignment: .bottom, spacing: 0) {
                // 값 (안드로이드: Headline4, TextMain)
                Text(value)
                    .typography(ElegaiterTypography.Headline4)
                    .foregroundColor(ElegaiterColors.Text.main)
                
                Spacer()
                
                // 아이콘 (안드로이드: size(28.dp))
                Image(icon)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.top, 12)
        .padding(.trailing, 16)
        .padding(.bottom, 12)
        .padding(.leading, 16)
        .frame(height: 72)
        .background(ElegaiterColors.Background.light)
        .cornerRadius(12)
    }
}

#Preview {
    StepCardGrid(
        items: [
            ("왼발 강도", "50%", "figure.walk"),
            ("오른발 강도", "50%", "figure.walk"),
            ("컨디션", "좋아요", "face.smiling"),
            ("분당 걸음 수", "120/m", "timer")
        ]
    )
    .padding()
}
