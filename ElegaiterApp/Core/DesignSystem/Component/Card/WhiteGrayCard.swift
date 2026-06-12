//
//  WhiteGrayCard.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 흰색 배경에 회색 테두리를 가진 카드 컴포넌트
/// 
/// Android의 `WhiteGrayCard`를 SwiftUI로 변환
/// - 흰색 배경에 회색 테두리 (StrokeMedium)
/// - 기본 cornerRadius: 20pt
struct WhiteGrayCard<Content: View>: View {
    /// 카드 내용
    @ViewBuilder let content: () -> Content
    /// 모서리 반경 (기본값: 20pt)
    let cornerRadius: CGFloat
    
    init(
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ElegaiterColors.Stroke.medium, lineWidth: 1)
            )
    }
}

#Preview {
    WhiteGrayCard {
        VStack(alignment: .leading, spacing: 12) {
            Text("카드 제목")
                .typography(ElegaiterTypography.Headline5)
                .foregroundColor(ElegaiterColors.Text.main)
            Text("카드 내용입니다.")
                .typography(ElegaiterTypography.Body2)
                .foregroundColor(ElegaiterColors.Text.sub2)
        }
        .padding(20)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
