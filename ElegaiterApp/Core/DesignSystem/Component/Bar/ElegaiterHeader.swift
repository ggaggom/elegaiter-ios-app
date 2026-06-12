//
//  ElegaiterHeader.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// Elegaiter Header 컴포넌트
/// 
/// Android의 `ElegaiterHeader`를 SwiftUI로 변환
/// - 뒤로가기 버튼과 제목을 포함하는 헤더
/// - ElegaiterTopBar와 유사하지만 배경이 투명한 버전
struct ElegaiterHeader: View {
    /// 제목
    let title: String
    /// 뒤로가기 액션
    let onBackClick: () -> Void
    /// 뒤로가기 아이콘 표시 여부 (기본값: true)
    var showBackIcon: Bool = true
    /// 우측 액션 버튼 (선택적)
    var actions: (() -> AnyView)? = nil
    
    var body: some View {
        HStack {
            // 뒤로가기 버튼 (showBackIcon이 true일 때만 표시)
            if showBackIcon {
                Button(action: onBackClick) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            } else {
                // 레이아웃 균형을 위한 투명 뷰
                Color.clear
                    .frame(width: 24, height: 24)
            }
            
            Spacer()
            
            // 제목
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // 우측 액션 버튼 또는 레이아웃 균형을 위한 투명 뷰
            if let actions = actions {
                actions()
            } else {
                Color.clear
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(spacing: 0) {
        ElegaiterHeader(
            title: "인덱스 워킹",
            onBackClick: {}
        )
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}
