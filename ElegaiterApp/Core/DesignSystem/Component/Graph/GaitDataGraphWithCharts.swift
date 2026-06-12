//
//  GaitDataGraphWithCharts.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import Charts

/// Swift Charts를 사용한 보행 데이터 그래프 컴포넌트
/// 
/// 안드로이드의 `FixedDataLineGraph`와 동일한 기능
/// - X, Y축 레이블 자동 표시
/// - 그리드 라인 (범위 구분선) 지원
/// - Median-IQR 모드 지원
struct GaitDataGraphWithCharts: View {
    /// 원본 보행 데이터 (Float 배열)
    let rawData: [Float]
    
    /// 선택적 원본 데이터 (IQR 등, Median-IQR 모드에서 사용)
    var optionalRawData: [Float]? = nil
    
    /// 다른 데이터 (max 값 비교용)
    var anotherData: [Float]? = nil
    
    /// 그래프 색상
    var lineColor: Color = .green
    /// 선택적 데이터 색상 (IQR 등)
    var optionalColor: Color = .green
    /// 그래프 선 두께
    var lineWidth: CGFloat = 2.0
    
    // Y축 설정
    private var yMax: Double {
        let allDataForMax = rawData + (anotherData ?? [])
        let maxDataValue = allDataForMax.max() ?? 0.0
        let calculatedYMax = maxDataValue * 1.2
        return calculatedYMax > 0 ? Double(calculatedYMax) : 300.0
    }
    
    // 데이터 포인트 생성
    private var dataPoints: [DataPoint] {
        rawData.enumerated().compactMap { index, value in
            guard value > 0 else { return nil }
            return DataPoint(x: Double(index), y: Double(value), series: "median")
        }
    }
    
    private var iqrDataPoints: [DataPoint] {
        guard let iqrData = optionalRawData, !iqrData.isEmpty else { return [] }
        return iqrData.enumerated().compactMap { index, value in
            guard value > 0 else { return nil }
            return DataPoint(x: Double(index), y: Double(value), series: "iqr")
        }
    }
    
    var body: some View {
        // 안드로이드: 빈 상태 처리 없음, Canvas만 사용
        // rawData가 비어있으면 아무것도 그리지 않음
        if !rawData.isEmpty {
            Chart {
                // Median 선 (별도 시리즈)
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Time", point.x),
                        y: .value("Median", point.y),
                        series: .value("Series", "median")
                    )
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }
                
                // IQR 선 (별도 시리즈)
                ForEach(iqrDataPoints) { point in
                    LineMark(
                        x: .value("Time", point.x),
                        y: .value("IQR", point.y),
                        series: .value("Series", "iqr")
                    )
                    .foregroundStyle(optionalColor)
                    .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: [0, 10, 20, 30, 40, 50, 60]) { value in // 0 포함, 60 포함
                    // AxisGridLine 제거 (세로선 제거)
                    AxisTick() // tick mark 유지
                    AxisValueLabel(centered: false) { // 수직선 바로 아래에 레이블 배치
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: yMax / 7)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...yMax)
            .chartXScale(domain: 0...70) // 나눠보기 모드에서 60이 잘리지 않도록 domain 더 확장
            .frame(height: 150)
            .background(Color.white) // 안드로이드: 흰색 배경, 좌우 여백 없음
        }
    }
}

/// 데이터 포인트 모델
private struct DataPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let series: String // "median" 또는 "iqr"
}

/// 겹쳐 보기용 그래프 컴포넌트 (Swift Charts 사용)
/// 
/// 안드로이드의 `FixedDataLineGraphV2`와 동일한 기능
struct GaitDataGraphOverlayWithCharts: View {
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
    
    // Y축 설정
    private var yMax: Double {
        let allDataForMax = leftMedianData + rightMedianData
        let maxDataValue = allDataForMax.max() ?? 0.0
        let calculatedYMax = maxDataValue * 1.2
        return calculatedYMax > 0 ? Double(calculatedYMax) : 300.0
    }
    
    // 데이터 포인트 생성
    private var leftMedianPoints: [DataPoint] {
        leftMedianData.enumerated().compactMap { index, value in
            guard value > 0 else { return nil }
            return DataPoint(x: Double(index), y: Double(value), series: "leftMedian")
        }
    }
    
    private var leftIqrPoints: [DataPoint] {
        guard let iqrData = leftIqrData, !iqrData.isEmpty else { return [] }
        return iqrData.enumerated().compactMap { index, value in
            guard value > 0 else { return nil }
            return DataPoint(x: Double(index), y: Double(value), series: "leftIqr")
        }
    }
    
    private var rightMedianPoints: [DataPoint] {
        rightMedianData.enumerated().compactMap { index, value in
            guard value > 0 else { return nil }
            return DataPoint(x: Double(index), y: Double(value), series: "rightMedian")
        }
    }
    
    private var rightIqrPoints: [DataPoint] {
        guard let iqrData = rightIqrData, !iqrData.isEmpty else { return [] }
        return iqrData.enumerated().compactMap { index, value in
            guard value > 0 else { return nil }
            return DataPoint(x: Double(index), y: Double(value), series: "rightIqr")
        }
    }
    
    var body: some View {
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
            Chart {
                // 왼발 Median 선 (불투명)
                ForEach(leftMedianPoints) { point in
                    LineMark(
                        x: .value("Time", point.x),
                        y: .value("Left Median", point.y),
                        series: .value("Series", "leftMedian")
                    )
                    .foregroundStyle(leftColor)
                    .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }
                
                // 왼발 IQR 선 (불투명)
                ForEach(leftIqrPoints) { point in
                    LineMark(
                        x: .value("Time", point.x),
                        y: .value("Left IQR", point.y),
                        series: .value("Series", "leftIqr")
                    )
                    .foregroundStyle(leftColor)
                    .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }
                
                // 오른발 Median 선 (반투명)
                ForEach(rightMedianPoints) { point in
                    LineMark(
                        x: .value("Time", point.x),
                        y: .value("Right Median", point.y),
                        series: .value("Series", "rightMedian")
                    )
                    .foregroundStyle(rightColor.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }
                
                // 오른발 IQR 선 (반투명)
                ForEach(rightIqrPoints) { point in
                    LineMark(
                        x: .value("Time", point.x),
                        y: .value("Right IQR", point.y),
                        series: .value("Series", "rightIqr")
                    )
                    .foregroundStyle(rightColor.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: [0, 10, 20, 30, 40, 50, 60]) { value in // 0 포함, 60 포함
                    // AxisGridLine 제거 (세로선 제거)
                    AxisTick() // tick mark 유지
                    AxisValueLabel(centered: false) { // 수직선 바로 아래에 레이블 배치
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: yMax / 7)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...yMax)
            .chartXScale(domain: 0...70) // 나눠보기 모드에서 60이 잘리지 않도록 domain 더 확장
            .frame(height: 150)
            .background(Color.white) // 안드로이드: 흰색 배경, 좌우 여백 없음
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Median-IQR 그래프 예시
        GaitDataGraphWithCharts(
            rawData: (0..<61).map { index in
                Float(100 + 80 * sin(Double(index) * 0.1))
            },
            optionalRawData: (0..<61).map { index in
                Float(20 + 10 * sin(Double(index) * 0.1))
            },
            lineColor: .green,
            optionalColor: .green.opacity(0.5)
        )
        .frame(height: 200)
        .padding()
        
        // 겹쳐 보기 그래프 예시
        GaitDataGraphOverlayWithCharts(
            leftMedianData: (0..<61).map { index in
                Float(100 + 80 * sin(Double(index) * 0.1))
            },
            leftIqrData: (0..<61).map { index in
                Float(20 + 10 * sin(Double(index) * 0.1))
            },
            rightMedianData: (0..<61).map { index in
                Float(90 + 70 * sin(Double(index) * 0.1 + 0.5))
            },
            rightIqrData: (0..<61).map { index in
                Float(18 + 8 * sin(Double(index) * 0.1 + 0.5))
            },
            leftColor: .green,
            rightColor: .red
        )
        .frame(height: 200)
        .padding()
    }
}

