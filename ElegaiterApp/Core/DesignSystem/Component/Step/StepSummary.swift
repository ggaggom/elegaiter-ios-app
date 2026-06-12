//
//  StepSummary.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

/// 걸음 유형 요약 컴포넌트
/// 
/// Android의 `StepSummary`를 SwiftUI로 변환
/// - 총 걸음 수 및 걸음 유형별 비율 표시
struct StepSummary: View {
    /// 제목 (기본값: "총 걸음수")
    let title: String
    /// 총 걸음 수
    let totalSteps: Int
    /// 걸음 유형별 아이템
    let items: [StepItem]
    
    init(title: String = "총 걸음수", totalSteps: Int, items: [StepItem]) {
        self.title = title
        self.totalSteps = totalSteps
        self.items = items
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 Row: 왼쪽(제목/총 걸음수), 오른쪽(StepRow)
            HStack(alignment: .center, spacing: 0) {
                // 왼쪽: 제목과 총 걸음수
                VStack(alignment: .leading, spacing: 0) {
                Text(title)
                        .typography(ElegaiterTypography.Caption3)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                    
                    Text(formatNumber(totalSteps))
                        .typography(ElegaiterTypography.Headline2)
                        .foregroundColor(ElegaiterColors.Text.main)
                }
                
                Spacer()
                
                // 오른쪽: StepRow
                StepRow(items: items, useItemWeight: false)
            }
            
            Spacer()
                .frame(height: 16)
            
            // 하단: StepBarGraph
            StepBarGraph(items: items)
        }
    }
    
    /// 숫자를 콤마가 포함된 문자열로 변환
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - StepRow

/// 걸음 유형별 행 컴포넌트
/// 
/// Android의 `StepRow`를 SwiftUI로 변환
/// - 각 아이템마다 색상 박스와 라벨/비율 표시
private struct StepRow: View {
    let items: [StepItem]
    /// weight 사용 여부 (StepSummary3에서 true)
    let useItemWeight: Bool
    /// 아이템 간 간격 (useItemWeight가 false일 때만 적용)
    let itemSpacing: CGFloat
    
    init(items: [StepItem], useItemWeight: Bool = false, itemSpacing: CGFloat = 0) {
        self.items = items
        self.useItemWeight = useItemWeight
        self.itemSpacing = itemSpacing
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: useItemWeight ? 0 : itemSpacing) {
            ForEach(items, id: \.label) { item in
                HStack(alignment: .top, spacing: 7) {
                    // 색상 박스 (16x16, corner radius 4)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.color)
                        .frame(width: 16, height: 16)
                    
                    // 라벨과 비율
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.label)
                            .typography(ElegaiterTypography.Caption3)
                            .foregroundColor(ElegaiterColors.Text.sub1)
                        
                        Text("\(Int(item.percentage * 100))%")
                            .typography(ElegaiterTypography.Body3)
                            .foregroundColor(ElegaiterColors.Text.main)
                    }
                }
                .frame(minWidth: 62)
                .if(useItemWeight) { view in
                    view.frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - View Extension for Conditional Modifier

private extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - StepBarGraph

/// 걸음 유형별 프로그레스 바 그래프
/// 
/// Android의 `StepBarGraph`를 SwiftUI로 변환
/// - 가로로 배치된 프로그레스 바들
/// - 각 아이템의 percentage에 따라 비율로 배치 (안드로이드의 weight와 동일)
private struct StepBarGraph: View {
    let items: [StepItem]
    
    var body: some View {
        GeometryReader { geometry in
            let filteredItems = items.filter { $0.percentage > 0 }
            let totalPercentage = filteredItems.reduce(0.0) { $0 + $1.percentage }
            
            HStack(spacing: 0) {
                ForEach(filteredItems, id: \.label) { item in
                    Rectangle()
                        .fill(item.color)
                        .frame(width: totalPercentage > 0 
                               ? geometry.size.width * CGFloat(item.percentage / totalPercentage)
                               : 0)
                }
            }
        }
        .frame(height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

/// 걸음 유형 아이템
struct StepItem {
    let label: String
    let percentage: Double
    let color: Color
    /// 지속 시간 (초, 선택적)
    let durationS: Double?
    /// 걸음 수 문자열 (StepSummary2용, 선택적)
    let steps: String?
    /// 지속 시간 문자열 (StepSummary2용, 선택적)
    let duration: String?
    
    init(
        label: String,
        percentage: Double,
        color: Color,
        durationS: Double? = nil,
        steps: String? = nil,
        duration: String? = nil
    ) {
        self.label = label
        self.percentage = percentage
        self.color = color
        self.durationS = durationS
        self.steps = steps
        self.duration = duration
    }
}

#Preview("StepSummary") {
    StepSummary(
        title: "최근 7일간 총 걸음수",
        totalSteps: 21500,
        items: [
            StepItem(label: "걷기", percentage: 0.55, color: ElegaiterColors.Green.green400),
            StepItem(label: "미분류", percentage: 0.15, color: ElegaiterColors.Status.warning),
            StepItem(label: "뛰기", percentage: 0.30, color: ElegaiterColors.Additional.orange)
        ]
    )
    .padding()
}

#Preview("StepSummary2") {
    StepSummary2(
        totalSteps: 38000,
        items: [
            StepItem(
                label: "걷기",
                percentage: 0.52,
                color: ElegaiterColors.Green.green400,
                steps: "4,451걸음",
                duration: "15분 7초"
            ),
            StepItem(
                label: "미분류",
                percentage: 0.08,
                color: ElegaiterColors.Status.warning,
                steps: "682걸음",
                duration: "2분 30초"
            ),
            StepItem(
                label: "뛰기",
                percentage: 0.40,
                color: ElegaiterColors.Additional.orange,
                steps: "15,267걸음",
                duration: "22분 10초"
            )
        ]
    )
    .padding()
}

#Preview("StepSummary3") {
    StepSummary3(
        items: [
            StepItem(
                label: "걷기",
                percentage: 0.52,
                color: ElegaiterColors.Green.green400
            ),
            StepItem(
                label: "미분류",
                percentage: 0.08,
                color: ElegaiterColors.Status.warning
            ),
            StepItem(
                label: "뛰기",
                percentage: 0.40,
                color: ElegaiterColors.Additional.orange
            )
        ]
    )
    .padding()
}

// MARK: - StepSummary2

/// 걸음 유형 요약 컴포넌트 (버전 2)
/// 
/// Android의 `StepSummary2`를 SwiftUI로 변환
/// - 총 걸음 수와 StepBarGraph가 같은 Row에 배치
/// - 각 아이템의 걸음 수, 비율, 시간을 상세히 표시
struct StepSummary2: View {
    /// 총 걸음 수
    let totalSteps: Int
    /// 걸음 유형별 아이템
    let items: [StepItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // 제목 (안드로이드: "총 걸음수", Caption3, TextSub1)
                    Text("총 걸음수")
                        .typography(ElegaiterTypography.Caption3)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                    
                    // 총 걸음 수와 StepBarGraph (안드로이드: Row, spacedBy 39.dp)
                    HStack(alignment: .center, spacing: 39) {
                        Text(formatNumber(totalSteps))
                            .typography(ElegaiterTypography.Headline2)
                            .foregroundColor(ElegaiterColors.Text.main)
                        
                        StepBarGraph(items: items)
                    }
                    
                    Spacer()
                        .frame(height: 16)
                    
                    // 아이템 상세 정보 (안드로이드: Column, spacedBy 10.dp)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(items, id: \.label) { item in
                            HStack(alignment: .center, spacing: 0) {
                                // 왼쪽: 색상 박스와 라벨 (안드로이드: Row, spacedBy 6.dp)
                                HStack(alignment: .center, spacing: 6) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.color)
                                        .frame(width: 16, height: 16)
                                    
                                    Text(item.label)
                                        .typography(ElegaiterTypography.Caption3)
                                        .foregroundColor(ElegaiterColors.Text.sub1)
                                }
                                
                                Spacer()
                                
                                // 오른쪽: 걸음 수, 비율, 시간 (안드로이드: Row, spacedBy 10.dp)
                                HStack(alignment: .center, spacing: 10) {
                                    // 걸음 수 (안드로이드: Caption1, TextSub2, width 65.dp, end)
                                    if let steps = item.steps {
                                        Text(steps)
                                            .typography(ElegaiterTypography.Caption1)
                                            .foregroundColor(ElegaiterColors.Text.sub2)
                                            .frame(width: 65, alignment: .trailing)
                                    }
                                    
                                    // 비율 (안드로이드: Caption1, TextSub2, width 30.dp, end)
                                    Text("\(Int(item.percentage * 100))%")
                                        .typography(ElegaiterTypography.Caption1)
                                        .foregroundColor(ElegaiterColors.Text.sub2)
                                        .frame(width: 30, alignment: .trailing)
                                    
                                    // 시간 (안드로이드: Caption1, TextSub2, width 55.dp, end)
                                    if let duration = item.duration {
                                        Text(duration)
                                            .typography(ElegaiterTypography.Caption1)
                                            .foregroundColor(ElegaiterColors.Text.sub2)
                                            .frame(width: 55, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 숫자를 콤마가 포함된 문자열로 변환
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - StepSummary3

/// 걸음 유형 요약 컴포넌트 (버전 3)
/// 
/// Android의 `StepSummary3`를 SwiftUI로 변환
/// - StepBarGraph가 위에, StepRow가 아래에 배치
/// - StepRow의 각 아이템이 균등 분배 (weight 적용)
struct StepSummary3: View {
    /// 걸음 유형별 아이템
    let items: [StepItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // StepBarGraph (안드로이드: 위쪽)
            StepBarGraph(items: items)
            
            Spacer()
                .frame(height: 12)
            
            StepRow(items: items, useItemWeight: false, itemSpacing: 44)
        }
        .frame(maxWidth: .infinity)
    }
}
