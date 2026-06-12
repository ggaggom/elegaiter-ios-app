//
//  GaitDataGraph.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 보행 데이터 그래프 컴포넌트
/// 
/// Android의 `GaitDataGraph`를 SwiftUI로 변환
/// - 실시간 보행 시계열 데이터를 그래프로 표시
/// - 원본 압력 데이터를 파형 그래프로 시각화
/// - Median-IQR 모드에서 optionalRawData(IQR) 지원
struct GaitDataGraph: View {
    /// 원본 보행 데이터 (Float 배열)
    let rawData: [Float]
    
    /// 선택적 원본 데이터 (IQR 등, Median-IQR 모드에서 사용)
    var optionalRawData: [Float]? = nil
    
    /// 다른 데이터 (max 값 비교용, 안드로이드의 anotherData와 동일)
    var anotherData: [Float]? = nil
    
    /// 그래프 색상 (안드로이드 기본값: Green500)
    var lineColor: Color = ElegaiterColors.Green.green500
    /// 선택적 데이터 색상 (IQR 등, 안드로이드 기본값: StatusError)
    var optionalColor: Color = ElegaiterColors.Status.error
    /// 그래프 선 두께 (안드로이드: 3.dp)
    var lineWidth: CGFloat = 3.0
    /// 그래프 폭 (데이터 포인트 수, 보행 시계열 모드에서 사용, 안드로이드 기본값: rawData.size)
    var widthSize: Int? = nil
    /// 그래프 배경색상 (iOS 전용, 안드로이드에는 없음)
    var backgroundColor: Color? = nil
    /// 고정 최대값 (안드로이드: fixedMaxValue)
    var fixedMaxValue: Float? = nil
    /// 고정 최소값 (안드로이드: fixedMinValue)
    var fixedMinValue: Float? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경색상 (iOS 전용, 안드로이드에는 없음)
                if let bgColor = backgroundColor {
                    Rectangle()
                        .fill(bgColor)
                }
                
                // 안드로이드: 빈 상태 처리 없음, Canvas만 사용
                // rawData가 비어있으면 아무것도 그리지 않음
                if !rawData.isEmpty {
                    // 안드로이드: Canvas만 사용, 배경 없음
                    // 선택적 데이터가 있으면 (Median-IQR 모드)
                    if let iqrData = optionalRawData, !iqrData.isEmpty {
                        medianIqrGraph(
                            geometry: geometry,
                            medianData: rawData,
                            iqrData: iqrData
                        )
                    } else {
                    // 보행 시계열 모드 (안드로이드: drawDataPath)
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        // widthSize가 지정되면 해당 크기만큼만 표시 (안드로이드: subList)
                        let displayData: [Float]
                        
                        if let widthSize = widthSize, widthSize > 0 && rawData.count > widthSize {
                            displayData = Array(rawData.suffix(widthSize))
                        } else {
                            displayData = rawData
                        }
                        
                        // 안드로이드: data.size < 2면 return
                        guard displayData.count >= 2 else { return }
                        
                        // 데이터 범위 계산 (안드로이드: fixedMaxValue ?: (rawData.maxOrNull() ?: 0f))
                        let graphMaxValue = fixedMaxValue ?? (displayData.max() ?? 1.0)
                        let graphMinValue = fixedMinValue ?? (displayData.min() ?? 0.0)
                        let range = max(graphMaxValue - graphMinValue, 1.0) // 최소 1.0 보장
                        
                        // 첫 번째 점으로 이동 (안드로이드: firstX = 0f, firstY 계산)
                        let firstX = CGFloat(0)
                        let firstY = height - (CGFloat((displayData[0] - graphMinValue) / range) * height)
                        path.move(to: CGPoint(x: firstX, y: firstY))
                        
                        // 나머지 점들 연결 (안드로이드: data[i] == 0f이면 continue)
                        for i in 1..<displayData.count {
                            if displayData[i] == 0.0 {
                                continue // 안드로이드: data[i] == 0f일 때 continue
                            }
                            let x = CGFloat(i) / CGFloat(displayData.count - 1) * width
                            let y = height - (CGFloat((displayData[i] - graphMinValue) / range) * height)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Median-IQR 그래프 생성
    /// 
    /// Median과 IQR을 각각 선으로 그립니다.
    /// - Median: 상단 영역에 그리기
    /// - IQR: 하단 영역에 그리기
    @ViewBuilder
    private func medianIqrGraph(
        geometry: GeometryProxy,
        medianData: [Float],
        iqrData: [Float]
    ) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let count = min(medianData.count, iqrData.count)
        
        if count > 0 {
            // Y축 범위 계산 (안드로이드: fixedMaxValue ?: (rawData.maxOrNull() ?: 0f))
            let graphMaxValue = fixedMaxValue ?? {
                // anotherData 포함하여 max 값 비교
                let allDataForMax = medianData + (anotherData ?? [])
                let maxDataValue = allDataForMax.max() ?? 0.0
                let calculatedYMax = maxDataValue * 1.2
                return calculatedYMax > 0 ? calculatedYMax : 300.0
            }()
            let graphMinValue = fixedMinValue ?? 0.0
            let valueRange = graphMaxValue - graphMinValue
            
            if valueRange > 0 {
                // Median 선 그리기 (상단 영역: 0 ~ height/2)
                let medianHeight = height / 2
                Path { path in
                    var startedDrawing = false
                    for i in 0..<count {
                        let value = min(max(medianData[i], graphMinValue), graphMaxValue)
                        let x = CGFloat(i) / CGFloat(max(count - 1, 1)) * width
                        // 상단 영역에 그리기: y = 0이 상단, medianHeight가 하단
                        let y = medianHeight - (CGFloat((value - graphMinValue) / valueRange) * medianHeight)
                        
                        if value > graphMinValue {
                            if !startedDrawing {
                                path.move(to: CGPoint(x: x, y: y))
                                startedDrawing = true
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        } else {
                            startedDrawing = false
                        }
                    }
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                
                // IQR 선 그리기 (하단 영역: height/2 ~ height)
                let iqrHeight = height / 2
                let iqrTop = height / 2
                Path { path in
                    var startedDrawing = false
                    for i in 0..<count {
                        let value = min(max(iqrData[i], graphMinValue), graphMaxValue)
                        let x = CGFloat(i) / CGFloat(max(count - 1, 1)) * width
                        // 하단 영역에 그리기: iqrTop이 상단, height가 하단
                        let y = height - (CGFloat((value - graphMinValue) / valueRange) * iqrHeight)
                        
                        if value > graphMinValue {
                            if !startedDrawing {
                                path.move(to: CGPoint(x: x, y: y))
                                startedDrawing = true
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        } else {
                            startedDrawing = false
                        }
                    }
                }
                .stroke(optionalColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
    }
    
}

/// 겹쳐 보기용 그래프 컴포넌트
/// 
/// Android의 `FixedDataLineGraphV2`를 SwiftUI로 변환
/// - 왼발과 오른발을 하나의 그래프에 함께 표시
/// - 왼발은 불투명하게, 오른발은 반투명하게 표시
struct GaitDataGraphOverlay: View {
    /// 왼발 중앙값 데이터
    let leftMedianData: [Float]
    /// 왼발 IQR 데이터
    var leftIqrData: [Float]? = nil
    /// 오른발 중앙값 데이터
    let rightMedianData: [Float]
    /// 오른발 IQR 데이터
    var rightIqrData: [Float]? = nil
    /// 왼발 그래프 색상
    var leftColor: Color = .green
    /// 오른발 그래프 색상
    var rightColor: Color = .red
    /// 그래프 선 두께
    var lineWidth: CGFloat = 2.0
    
    var body: some View {
        GeometryReader { geometry in
            if leftMedianData.isEmpty && rightMedianData.isEmpty {
                // 데이터가 없을 때 빈 그래프 표시
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Text("데이터 대기 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            } else {
                ZStack {
                    // 배경
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                    
                    // 겹쳐 보기 그래프
                    overlayGraph(geometry: geometry)
                }
            }
        }
    }
    
    @ViewBuilder
    private func overlayGraph(geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        
        // Y축 범위 계산 (왼발과 오른발 모두 포함)
        let allDataForMax = leftMedianData + rightMedianData
        let maxDataValue = allDataForMax.max() ?? 0.0
        let calculatedYMax = maxDataValue * 1.2
        let Y_MAX = calculatedYMax > 0 ? calculatedYMax : 300.0
        let valueRange = Y_MAX - 0.0
        
        if valueRange > 0 {
            // 왼발 Median 선 (불투명)
            if !leftMedianData.isEmpty {
                drawPath(
                    data: leftMedianData,
                    color: leftColor,
                    width: width,
                    height: height,
                    Y_MAX: Y_MAX,
                    valueRange: valueRange
                )
            }
            
            // 왼발 IQR 선 (불투명)
            if let leftIqr = leftIqrData, !leftIqr.isEmpty {
                drawPath(
                    data: leftIqr,
                    color: leftColor,
                    width: width,
                    height: height,
                    Y_MAX: Y_MAX,
                    valueRange: valueRange
                )
            }
            
            // 오른발 Median 선 (반투명, alpha 0.7)
            if !rightMedianData.isEmpty {
                drawPath(
                    data: rightMedianData,
                    color: rightColor.opacity(0.7),
                    width: width,
                    height: height,
                    Y_MAX: Y_MAX,
                    valueRange: valueRange
                )
            }
            
            // 오른발 IQR 선 (반투명, alpha 0.7)
            if let rightIqr = rightIqrData, !rightIqr.isEmpty {
                drawPath(
                    data: rightIqr,
                    color: rightColor.opacity(0.7),
                    width: width,
                    height: height,
                    Y_MAX: Y_MAX,
                    valueRange: valueRange
                )
            }
        }
    }
    
    private func drawPath(
        data: [Float],
        color: Color,
        width: CGFloat,
        height: CGFloat,
        Y_MAX: Float,
        valueRange: Float
    ) -> some View {
        Path { path in
            var startedDrawing = false
            let count = data.count
            
            for i in 0..<count {
                let value = min(max(data[i], 0.0), Y_MAX)
                let x = CGFloat(i) / CGFloat(max(count - 1, 1)) * width
                let y = height - (CGFloat(value / valueRange) * height)
                
                if value > 0.0 {
                    if !startedDrawing {
                        path.move(to: CGPoint(x: x, y: y))
                        startedDrawing = true
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                } else {
                    startedDrawing = false
                }
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}

#Preview {
    VStack(spacing: 20) {
        // 샘플 데이터로 그래프 표시
        GaitDataGraph(
            rawData: (0..<100).map { index in
                Float(100 + 80 * sin(Double(index) * 0.2))
            }
        )
        .frame(height: 200)
        .padding()
        
        // 빈 데이터 그래프
        GaitDataGraph(rawData: [])
            .frame(height: 200)
            .padding()
    }
}
