//
//  ElapsedTimeBarGraph.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI

/// 운동 시간 막대 그래프 컴포넌트
/// 
/// Android의 `ElapsedTimeBarGraph`를 SwiftUI로 변환
/// - 주간/월간 뷰에 따라 다른 형태로 표시
/// - 운동 시간을 막대 그래프로 시각화
/// - Y축이 0분부터 시작하여 위로 올라가면서 시간이 늘어남
struct ElapsedTimeBarGraph: View {
    /// 주간 일별 운동 시간 리스트 (초 단위)
    let weeklyTimes: [Int64]
    
    /// 월간 주별 운동 시간 리스트 (초 단위)
    let monthlyWeeklyTimes: [Int64]
    
    /// 주간 뷰 여부
    let isWeeklyView: Bool
    
    /// 그래프 높이 (안드로이드: 150.dp)
    private let graphHeight: CGFloat = 150
    
    /// 주간 최대값 (분 단위, 안드로이드: 120L)
    private let maxWeekly: Int64 = 120
    
    /// 월간 최대값 (분 단위, 안드로이드: 720L)
    private let maxMonthly: Int64 = 720
    
    /// 주간 Y축 단위 (분 단위, 안드로이드: 30)
    private let weeklyYStep: Int64 = 30
    
    /// 월간 Y축 단위 (분 단위, 안드로이드: 180)
    private let monthlyYStep: Int64 = 180
    
    var body: some View {
        // 안드로이드: Column(modifier = Modifier.fillMaxWidth())
        VStack(alignment: .leading, spacing: 0) {
            // 안드로이드: Row(modifier = Modifier.fillMaxWidth())
            HStack(alignment: .top, spacing: 0) {
                // Y축 레이블 (안드로이드: Column with offset)
                yAxisLabels
                
                // 안드로이드: Spacer(modifier = Modifier.width(6.dp))
                Spacer()
                    .frame(width: 6)
                
                // 그래프 영역 (안드로이드: Column(modifier = Modifier.fillMaxWidth()))
                graphArea
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Y Axis Labels
    
    private var yAxisLabels: some View {
        let yMax = isWeeklyView ? maxWeekly : maxMonthly
        let yStep = isWeeklyView ? weeklyYStep : monthlyYStep
        let stepCount = Int(yMax / yStep)
        let stepHeight = graphHeight / CGFloat(stepCount)
        
        // 안드로이드: height(150.dp + (150.dp / (yMax / yStep).toInt())), offset(y = -(150.dp / (yMax / yStep).toInt()) / 2)
        let totalHeight = graphHeight + (graphHeight / CGFloat(stepCount))
        let offsetY = -(graphHeight / CGFloat(stepCount)) / 2
        
        return VStack(alignment: .trailing, spacing: 0) {
            ForEach(0...stepCount, id: \.self) { i in
                let yVal = yMax - (Int64(i) * yStep)
                
                // 안드로이드: Box(modifier = Modifier.height(stepHeight), contentAlignment = Alignment.CenterStart)
                // "시간"의 "간" 위치를 일치시키기 위해 우측 정렬
                Text(formatYAxisLabel(yVal))
                    .typography(ElegaiterTypography.Caption3)
                    .foregroundColor(ElegaiterColors.Text.disabled)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(height: stepHeight, alignment: .trailing)
            }
        }
        .frame(height: totalHeight, alignment: .trailing)
        .offset(y: offsetY)
        // 안드로이드: Y축 Column은 고정 너비 없이 내용에 맞게 크기 결정
        // 우측 정렬로 "시간"의 "간" 위치 일치
    }
    
    // MARK: - Graph Area
    
    private var graphArea: some View {
        let weeklyTimesInMin = weeklyTimes.map { $0 / 60 }
        let monthlyWeeklyTimesInMin = monthlyWeeklyTimes.map { $0 / 60 }
        let data = isWeeklyView ? weeklyTimesInMin : monthlyWeeklyTimesInMin
        let xLabels = isWeeklyView 
            ? ["월", "화", "수", "목", "금", "토", "일"]
            : (0..<data.count).map { "\($0 + 1)주차" }
        let yMax = isWeeklyView ? maxWeekly : maxMonthly
        
        // 안드로이드: Column(modifier = Modifier.fillMaxWidth())
        return VStack(alignment: .leading, spacing: 0) {
            // 안드로이드: Box(modifier = Modifier.fillMaxWidth().height(150.dp))
            ZStack(alignment: .bottom) {
                // 그리드 라인 (안드로이드: Canvas)
                gridLines(yMax: yMax)
                
                // 막대 그래프 (안드로이드: Row with Arrangement.SpaceEvenly)
                // SpaceEvenly: 막대들 사이에 균등한 간격을 두고 배치
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        let fraction = min(max(CGFloat(value) / CGFloat(yMax), 0), 1)
                        
                        // 안드로이드: Box(modifier = Modifier.weight(1f).fillMaxHeight(), contentAlignment = Alignment.BottomCenter)
                        // SpaceEvenly를 위해 각 항목에 균등한 공간 할당
                        VStack {
                            Spacer()
                            
                            // 안드로이드: width(14.dp), fillMaxHeight(fraction), clip(RoundedCornerShape(topStart = 30.dp, topEnd = 30.dp))
                            // 위쪽만 둥근 모서리 (하단부는 라디어스 없음)
                            Rectangle()
                                .fill(
                                    // 안드로이드: Brush.verticalGradient(Green400 -> Green500)
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            ElegaiterColors.Green.green400,
                                            ElegaiterColors.Green.green500
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 14, height: graphHeight * fraction)
                                .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: graphHeight)
            
            // 안드로이드: Spacer(modifier = Modifier.height(4.dp))
            Spacer()
                .frame(height: 4)
            
            // X축 레이블 (안드로이드: Row(modifier = Modifier.fillMaxWidth()))
            HStack(spacing: 0) {
                ForEach(Array(xLabels.enumerated()), id: \.offset) { index, label in
                    // 안드로이드: ElegaiterTypography.Caption2, TextSub1, TextAlign.Center, weight(1f)
                    Text(label)
                        .typography(ElegaiterTypography.Caption2)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Grid Lines
    
    private func gridLines(yMax: Int64) -> some View {
        let yStep = isWeeklyView ? weeklyYStep : monthlyYStep
        let stepCount = Int(yMax / yStep)
        let spacing = graphHeight / CGFloat(stepCount)
        
        // 안드로이드: Canvas, StrokeWeak
        return GeometryReader { geometry in
            Path { path in
                for i in 0...stepCount {
                    let y = geometry.size.height - (CGFloat(i) * spacing)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(ElegaiterColors.Stroke.weak, lineWidth: 1)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Y축 레이블 포맷팅
    private func formatYAxisLabel(_ minutes: Int64) -> String {
        if isWeeklyView {
            return "\(minutes)분"
        } else {
            return "\(minutes / 60)시간"
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        ElapsedTimeBarGraph(
            weeklyTimes: [3600, 7200, 5400, 1800, 9000, 3600, 5400],
            monthlyWeeklyTimes: [25200, 18000, 21600, 14400],
            isWeeklyView: true
        )
        .padding()
        
        ElapsedTimeBarGraph(
            weeklyTimes: [3600, 7200, 5400, 1800, 9000, 3600, 5400],
            monthlyWeeklyTimes: [25200, 18000, 21600, 14400],
            isWeeklyView: false
        )
        .padding()
    }
}
