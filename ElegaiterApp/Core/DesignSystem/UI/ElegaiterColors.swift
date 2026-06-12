//
//  ElegaiterColors.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// Elegaiter 컬러 시스템
/// 
/// 디자인 시스템의 컬러를 의미론적으로 그룹화하여 제공합니다.
/// Android의 컬러 시스템과 일관성을 유지합니다.
enum ElegaiterColors {
    
    // MARK: - Brand Colors
    
    /// Elegaiter 브랜드 컬러
    enum Brand {
        static let green = Color("elegaiter_green", bundle: nil)
    }
    
    // MARK: - Color Palettes
    
    /// Green 컬러 팔레트
    enum Green {
        static let green50 = Color("Green50", bundle: nil)
        static let green100 = Color("Green100", bundle: nil)
        static let green200 = Color("Green200", bundle: nil)
        static let green300 = Color("Green300", bundle: nil)
        static let green400 = Color("Green400", bundle: nil)
        /// Green300에서 Green400으로의 그라데이션 컬러 (중간 컬러)
        static let green300_400 = Color("Green300_400", bundle: nil)
        static let green500 = Color("Green500", bundle: nil)
        static let green600 = Color("Green600", bundle: nil)
        static let green700 = Color("Green700", bundle: nil)
        static let green800 = Color("Green800", bundle: nil)
        static let green900 = Color("Green900", bundle: nil)
        static let green950 = Color("Green950", bundle: nil)
    }
    
    /// Neutral 컬러 팔레트
    enum Neutral {
        static let neutral50 = Color("Neutral50", bundle: nil)
        static let neutral100 = Color("Neutral100", bundle: nil)
        static let neutral200 = Color("Neutral200", bundle: nil)
        static let neutral300 = Color("Neutral300", bundle: nil)
        static let neutral400 = Color("Neutral400", bundle: nil)
        static let neutral500 = Color("Neutral500", bundle: nil)
        static let neutral600 = Color("Neutral600", bundle: nil)
        static let neutral700 = Color("Neutral700", bundle: nil)
        static let neutral800 = Color("Neutral800", bundle: nil)
        static let neutral900 = Color("Neutral900", bundle: nil)
        static let neutral950 = Color("Neutral950", bundle: nil)
    }
    
    // MARK: - Semantic Colors
    
    /// 텍스트 컬러
    enum Text {
        /// 주요 텍스트 컬러
        static let main = Color("TextMain", bundle: nil)
        /// 보조 텍스트 컬러 (Sub2)
        static let sub2 = Color("TextSub2", bundle: nil)
        /// 보조 텍스트 컬러 (Sub1)
        static let sub1 = Color("TextSub1", bundle: nil)
        /// 비활성화된 텍스트 컬러
        static let disabled = Color("TextDisabled", bundle: nil)
    }
    
    /// 배경 컬러
    enum Background {
        /// 투명 배경 컬러
        static let transparent = Color("BackgroundTransparent", bundle: nil)
        /// 다크 배경 컬러
        static let dark = Color("BackgroundDark", bundle: nil)
        /// 라이트 배경 컬러
        static let light = Color("BackgroundLight", bundle: nil)
    }
    
    /// 스트로크(테두리) 컬러
    enum Stroke {
        /// 강한 스트로크 컬러
        static let strong = Color("StrokeStrong", bundle: nil)
        /// 중간 스트로크 컬러
        static let medium = Color("StrokeMedium", bundle: nil)
        /// 약한 스트로크 컬러
        static let weak = Color("StrokeWeak", bundle: nil)
    }
    
    /// 상태 컬러
    enum Status {
        /// 정보 상태 컬러
        static let info = Color("StatusInfo", bundle: nil)
        /// 경고 상태 컬러
        static let warning = Color("StatusWarning", bundle: nil)
        /// 성공 상태 컬러
        static let success = Color("StatusSuccess", bundle: nil)
        /// 에러 상태 컬러
        static let error = Color("StatusError", bundle: nil)
    }
    
    // MARK: - Additional Colors
    
    /// 추가 컬러
    enum Additional {
        /// 블루투스 컬러
        static let bluetooth = Color("Bluetooth", bundle: nil)
        /// 오렌지 컬러
        static let orange = Color("Orange", bundle: nil)
    }
    
    // MARK: - Gradients
    
    /// 그라데이션
    enum Gradient {
        /// Green300에서 Green400으로의 그라데이션
        static let green300_400 = LinearGradient(
            colors: [Green.green300, Green.green400],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
