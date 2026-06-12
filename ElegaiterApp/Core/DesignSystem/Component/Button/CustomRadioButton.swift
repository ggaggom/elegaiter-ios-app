//
//  CustomRadioButton.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 커스텀 라디오 버튼 컴포넌트
/// 
/// Android의 `CustomRadioButton`을 SwiftUI로 변환
/// - 단일 선택 그룹에서 사용되는 라디오 버튼
/// - 텍스트와 함께 표시되는 버튼 형태
struct CustomRadioButton: View {
    /// 버튼 텍스트
    let text: String
    /// 선택 상태
    let selected: Bool
    /// 클릭 액션
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            Text(text)
                .typography(ElegaiterTypography.Label1)
                .foregroundColor(selected ? ElegaiterColors.Text.main : ElegaiterColors.Text.sub1)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if selected {
                            // 선택 시: Green300 → Green400 그라데이션
                            LinearGradient(
                                colors: [
                                    ElegaiterColors.Green.green300,
                                    ElegaiterColors.Green.green400
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            // 미선택 시: 흰색 배경
                            Color.white
                        }
                    }
                )
                .cornerRadius(32)
                .overlay(
                    // 미선택 시에만 테두리 표시
                    Group {
                        if !selected {
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(ElegaiterColors.Stroke.weak, lineWidth: 1)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedGender = "M"
        
        var body: some View {
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    CustomRadioButton(
                        text: "남성",
                        selected: selectedGender == "M",
                        onClick: {
                            selectedGender = "M"
                        }
                    )
                    
                    CustomRadioButton(
                        text: "여성",
                        selected: selectedGender == "F",
                        onClick: {
                            selectedGender = "F"
                        }
                    )
                }
                
                Text("선택된 성별: \(selectedGender == "M" ? "남성" : "여성")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
