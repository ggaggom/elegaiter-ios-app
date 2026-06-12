//
//  BackgroundLightCard.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 배경이 밝은 카드 컴포넌트
/// 
/// Android의 `BackgroundLightCard`를 SwiftUI로 변환
/// - 밝은 배경색의 카드 컨테이너
struct BackgroundLightCard<Content: View>: View {
    /// 카드 내용
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .padding(16)
            .background(ElegaiterColors.Background.light) // 안드로이드: BackgroundLight = Neutral100 (#F5F5F5)
            .cornerRadius(20)
    }
}

#Preview {
    BackgroundLightCard {
        VStack(alignment: .leading, spacing: 12) {
            Text("카드 제목")
                .font(.headline)
            Text("카드 내용입니다.")
                .font(.body)
        }
    }
    .padding()
}
