//
//  GraphButton.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 그래프 제어 버튼 컴포넌트
/// 
/// Android의 `GraphButton`을 SwiftUI로 변환
/// - 그래프 높이/폭 조절에 사용되는 작은 버튼
/// - 안드로이드: size = 28.dp, RoundedCornerShape(10.dp), White 배경, StrokeMedium 테두리, Green400 아이콘
struct GraphButton: View {
    /// 클릭 액션
    let onClick: () -> Void
    /// 아이콘 이름 (SF Symbols)
    let iconName: String
    
    /// 버튼 크기 (안드로이드: 28.dp)
    var size: CGFloat = 28
    
    var body: some View {
        Button(action: onClick) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(ElegaiterColors.Green.green400)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ElegaiterColors.Stroke.medium, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 20) {
        GraphButton(
            onClick: {},
            iconName: "plus"
        )
        
        GraphButton(
            onClick: {},
            iconName: "minus"
        )
    }
    .padding()
}
