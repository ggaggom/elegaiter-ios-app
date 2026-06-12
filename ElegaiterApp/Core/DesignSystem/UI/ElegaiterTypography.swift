//
//  ElegaiterTypography.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 타이포그래피 스타일 정의
/// 
/// Pretendard Variable 폰트를 사용한 일관된 타이포그래피 시스템
/// 안드로이드 ElegaiterTypography와 동일한 스타일 규격을 따릅니다.
enum ElegaiterTypography {
    // MARK: - Font Names
    
    /// Pretendard Variable 폰트 이름 상수
    enum FontName {
        static let thin = "PretendardVariable-Thin"
        static let extraLight = "PretendardVariable-ExtraLight"
        static let light = "PretendardVariable-Light"
        static let regular = "PretendardVariable-Regular"
        static let medium = "PretendardVariable-Medium"
        static let semiBold = "PretendardVariable-SemiBold"
        static let bold = "PretendardVariable-Bold"
        static let extraBold = "PretendardVariable-ExtraBold"
        static let black = "PretendardVariable-Black"
    }
    
    // MARK: - Typography Style
    
    /// 타이포그래피 스타일 정보
    /// 
    /// 안드로이드 TextStyle과 동일한 스타일 속성을 포함합니다.
    struct TypographyStyle {
        let font: Font
        let fontSize: CGFloat
        let lineHeight: CGFloat
        let letterSpacing: CGFloat
    }
    
    // MARK: - Display Styles (Bold, 130% lineHeight, -2.5% letterSpacing)
    
    /// Display1 (56pt, Bold)
    static let Display1 = TypographyStyle(
        font: font(size: 56, weight: .bold),
        fontSize: 56,
        lineHeight: 56 * 1.3, // 72.8
        letterSpacing: -56 * 0.025 // -1.4
    )
    
    /// Display2 (48pt, Bold)
    static let Display2 = TypographyStyle(
        font: font(size: 48, weight: .bold),
        fontSize: 48,
        lineHeight: 48 * 1.3, // 62.4
        letterSpacing: -48 * 0.025 // -1.2
    )
    
    /// Display3 (40pt, Bold)
    static let Display3 = TypographyStyle(
        font: font(size: 40, weight: .bold),
        fontSize: 40,
        lineHeight: 40 * 1.3, // 52
        letterSpacing: -40 * 0.025 // -1.0
    )
    
    /// Display4 (36pt, Bold)
    static let Display4 = TypographyStyle(
        font: font(size: 36, weight: .bold),
        fontSize: 36,
        lineHeight: 36 * 1.3, // 46.8
        letterSpacing: -36 * 0.025 // -0.9
    )
    
    // MARK: - Headline Styles (Bold, 130% lineHeight, -2.5% letterSpacing)
    
    /// Headline1 (32pt, Bold)
    static let Headline1 = TypographyStyle(
        font: font(size: 32, weight: .bold),
        fontSize: 32,
        lineHeight: 32 * 1.3, // 41.6
        letterSpacing: -32 * 0.025 // -0.8
    )
    
    /// Headline2 (28pt, Bold)
    static let Headline2 = TypographyStyle(
        font: font(size: 28, weight: .bold),
        fontSize: 28,
        lineHeight: 28 * 1.3, // 36.4
        letterSpacing: -28 * 0.025 // -0.7
    )
    
    /// Headline3 (24pt, Bold)
    static let Headline3 = TypographyStyle(
        font: font(size: 24, weight: .bold),
        fontSize: 24,
        lineHeight: 24 * 1.3, // 31.2
        letterSpacing: -24 * 0.025 // -0.6
    )
    
    /// Headline4 (20pt, Bold)
    static let Headline4 = TypographyStyle(
        font: font(size: 20, weight: .bold),
        fontSize: 20,
        lineHeight: 20 * 1.3, // 26
        letterSpacing: -20 * 0.025 // -0.5
    )
    
    /// Headline5 (18pt, Bold)
    static let Headline5 = TypographyStyle(
        font: font(size: 18, weight: .bold),
        fontSize: 18,
        lineHeight: 18 * 1.3, // 23.4
        letterSpacing: -18 * 0.025 // -0.45
    )
    
    /// Headline6 (16pt, Bold)
    static let Headline6 = TypographyStyle(
        font: font(size: 16, weight: .bold),
        fontSize: 16,
        lineHeight: 16 * 1.3, // 20.8
        letterSpacing: -16 * 0.025 // -0.4
    )
    
    // MARK: - Body Styles (Medium, 150% lineHeight, -2.5% letterSpacing)
    
    /// Body1 (17pt, Medium)
    static let Body1 = TypographyStyle(
        font: font(size: 17, weight: .medium),
        fontSize: 17,
        lineHeight: 17 * 1.5, // 25.5
        letterSpacing: -17 * 0.025 // -0.425
    )
    
    /// Body2 (16pt, Medium)
    static let Body2 = TypographyStyle(
        font: font(size: 16, weight: .medium),
        fontSize: 16,
        lineHeight: 16 * 1.5, // 24
        letterSpacing: -16 * 0.025 // -0.4
    )
    
    /// Body3 (15pt, Medium)
    static let Body3 = TypographyStyle(
        font: font(size: 15, weight: .medium),
        fontSize: 15,
        lineHeight: 15 * 1.5, // 22.5
        letterSpacing: -15 * 0.025 // -0.375
    )
    
    /// Body4 (14pt, Medium)
    static let Body4 = TypographyStyle(
        font: font(size: 14, weight: .medium),
        fontSize: 14,
        lineHeight: 14 * 1.5, // 21
        letterSpacing: -14 * 0.025 // -0.35
    )
    
    // MARK: - Caption Styles (Medium, 150% lineHeight, -2.5% letterSpacing)
    
    /// Caption1 (13pt, Medium)
    static let Caption1 = TypographyStyle(
        font: font(size: 13, weight: .medium),
        fontSize: 13,
        lineHeight: 13 * 1.5, // 19.5
        letterSpacing: -13 * 0.025 // -0.325
    )
    
    /// Caption2 (12pt, Medium)
    static let Caption2 = TypographyStyle(
        font: font(size: 12, weight: .medium),
        fontSize: 12,
        lineHeight: 12 * 1.5, // 18
        letterSpacing: -12 * 0.025 // -0.3
    )
    
    /// Caption3 (11pt, Medium)
    static let Caption3 = TypographyStyle(
        font: font(size: 11, weight: .medium),
        fontSize: 11,
        lineHeight: 11 * 1.5, // 16.5
        letterSpacing: -11 * 0.025 // -0.275
    )
    
    // MARK: - Label Styles (SemiBold, 150% lineHeight, -2.5% letterSpacing)
    
    /// Label1 (16pt, SemiBold)
    static let Label1 = TypographyStyle(
        font: font(size: 16, weight: .semiBold),
        fontSize: 16,
        lineHeight: 16 * 1.5, // 24
        letterSpacing: -16 * 0.025 // -0.4
    )
    
    /// Label2 (15pt, SemiBold)
    static let Label2 = TypographyStyle(
        font: font(size: 15, weight: .semiBold),
        fontSize: 15,
        lineHeight: 15 * 1.5, // 22.5
        letterSpacing: -15 * 0.025 // -0.375
    )
    
    /// Label3 (14pt, SemiBold)
    static let Label3 = TypographyStyle(
        font: font(size: 14, weight: .semiBold),
        fontSize: 14,
        lineHeight: 14 * 1.5, // 21
        letterSpacing: -14 * 0.025 // -0.35
    )
    
    /// Label4 (13pt, SemiBold)
    static let Label4 = TypographyStyle(
        font: font(size: 13, weight: .semiBold),
        fontSize: 13,
        lineHeight: 13 * 1.5, // 19.5
        letterSpacing: -13 * 0.025 // -0.325
    )
    
    /// Label5 (12pt, SemiBold)
    static let Label5 = TypographyStyle(
        font: font(size: 12, weight: .semiBold),
        fontSize: 12,
        lineHeight: 12 * 1.5, // 18
        letterSpacing: -12 * 0.025 // -0.3
    )
    
    // MARK: - Font Factory
    
    /// 커스텀 폰트 생성
    /// - Parameters:
    ///   - size: 폰트 크기
    ///   - weight: 폰트 굵기 (기본값: regular)
    /// - Returns: SwiftUI Font
    static func font(size: CGFloat, weight: FontWeight = .regular) -> Font {
        let fontName = weight.fontName
        return .custom(fontName, size: size)
    }
}

// MARK: - Font Weight

extension ElegaiterTypography {
    /// 폰트 굵기 열거형
    enum FontWeight {
        case thin
        case extraLight
        case light
        case regular
        case medium
        case semiBold
        case bold
        case extraBold
        case black
        
        /// 폰트 이름 반환
        var fontName: String {
            switch self {
            case .thin:
                return FontName.thin
            case .extraLight:
                return FontName.extraLight
            case .light:
                return FontName.light
            case .regular:
                return FontName.regular
            case .medium:
                return FontName.medium
            case .semiBold:
                return FontName.semiBold
            case .bold:
                return FontName.bold
            case .extraBold:
                return FontName.extraBold
            case .black:
                return FontName.black
            }
        }
    }
}
