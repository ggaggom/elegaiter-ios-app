//
//  View+Extensions.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

extension View {
    /// 특정 모서리에만 corner radius를 적용하는 확장 메서드
    /// 
    /// - Parameters:
    ///   - radius: 모서리 반경
    ///   - corners: 적용할 모서리 (UIRectCorner)
    /// - Returns: 수정된 View
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// 타이포그래피 스타일을 적용하는 확장 메서드
    /// 
    /// - Parameter style: 적용할 타이포그래피 스타일
    /// - Returns: 수정된 View
    func typography(_ style: ElegaiterTypography.TypographyStyle) -> some View {
        self
            .font(style.font)
            .lineSpacing(style.lineHeight - style.fontSize)
            .tracking(style.letterSpacing)
    }
    
    /// Safe Area 상단에 블러 배경을 적용하는 확장 메서드
    /// 
    /// 스크롤 시 status bar 영역에 블러 효과를 적용하여 콘텐츠와 겹치지 않도록 합니다.
    /// - Parameter material: Material 블러 종류 (기본값: .ultraThinMaterial)
    /// - Returns: 블러 효과가 적용된 View
    func statusBarBlur(material: Material = .ultraThinMaterial) -> some View {
        ZStack(alignment: .top) {
            // 원본 콘텐츠
            self
            
            // Safe Area에 블러 배경 오버레이
            GeometryReader { geometry in
                Rectangle()
                    .fill(material)
                    .frame(height: geometry.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)
            }
            .allowsHitTesting(false)  // 터치 이벤트는 아래로 전달
        }
    }
}

/// 특정 모서리에만 corner radius를 적용하는 Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

