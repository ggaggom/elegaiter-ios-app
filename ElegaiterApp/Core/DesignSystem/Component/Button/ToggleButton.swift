//
//  ToggleButton.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 토글 버튼 컴포넌트
/// 
/// Android의 `ToggleButton`을 SwiftUI로 변환
/// - 여러 옵션 중 하나를 선택할 수 있는 토글 버튼
/// - 선택된 옵션은 강조 표시
struct ToggleButton: View {
    /// 옵션 리스트
    let options: [String]
    /// 현재 선택된 옵션
    let selectedOption: String
    /// 옵션 선택 콜백
    let onOptionSelected: (String) -> Void
    
    /// 배경 색상 (안드로이드: BackgroundLight)
    var backgroundColor: Color = ElegaiterColors.Background.light
    /// 선택된 박스 배경 색상 (안드로이드: Color.White)
    var selectedBoxColor: Color = .white
    /// 선택된 박스 테두리 색상 (안드로이드: StrokeWeak)
    var selectedBoxBorderColor: Color = ElegaiterColors.Stroke.weak
    /// 선택된 텍스트 색상 (안드로이드: TextMain)
    var selectedTextColor: Color = ElegaiterColors.Text.main
    /// 선택되지 않은 텍스트 색상 (안드로이드: TextSub1)
    var unselectedTextColor: Color = ElegaiterColors.Text.sub1
    /// 배경 모서리 반경 (안드로이드: 32.dp)
    var backgroundRadius: CGFloat = 32
    /// 박스 모서리 반경 (안드로이드: 48.dp)
    var boxRadius: CGFloat = 48
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                let isSelected = option == selectedOption
                
                // 터치 영역을 확대하기 위해 ZStack 사용
                ZStack {
                    // 배경 (선택된 경우만)
                    if isSelected {
                        RoundedRectangle(cornerRadius: boxRadius)
                            .fill(selectedBoxColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: boxRadius)
                                    .stroke(selectedBoxBorderColor, lineWidth: 1)
                            )
                    }
                    
                    // 텍스트
                    Text(option)
                        .typography(ElegaiterTypography.Label3)
                        .foregroundColor(
                            isSelected ? selectedTextColor : unselectedTextColor
                        )
                }
                .frame(maxWidth: .infinity) // weight(1f)와 동일
                .frame(height: 45) // 전체 높이 53 - padding 4*2 = 45
                .contentShape(Rectangle()) // 터치 영역 확대
                .onTapGesture {
                    onOptionSelected(option)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedOption)
                
                // 옵션 사이 Spacer (2개 옵션일 때만 첫 번째 옵션 뒤에 추가)
                if index == 0 && options.count == 2 {
                    Spacer()
                        .frame(width: 10)
                }
            }
        }
        .padding(4) // 상하좌우 여백 4
        .frame(height: 53) // 전체 높이 53
        .background(
            RoundedRectangle(cornerRadius: backgroundRadius)
                .fill(backgroundColor)
        )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedOption = "보행 시계열"
        
        var body: some View {
            VStack(spacing: 30) {
                ToggleButton(
                    options: ["보행 시계열", "Median-IQR"],
                    selectedOption: selectedOption,
                    onOptionSelected: { option in
                        selectedOption = option
                    }
                )
                .frame(width: 220, height: 45)
                
                Text("선택된 옵션: \(selectedOption)")
                    .font(.caption)
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
