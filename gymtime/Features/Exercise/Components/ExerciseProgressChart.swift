// 📄 Chart component for displaying exercise weight progression over time

import SwiftUI
import Charts

public struct ExerciseProgressChart: View {
    let workouts: [WorkoutEntry]
    
    init(workouts: [WorkoutEntry]) {
        self.workouts = workouts
    }
    
    // Only include workouts with weights, sorted by date
    private var chartData: [(date: Date, weight: Double)] {
        workouts
            .compactMap { workout -> (Date, Double)? in
                guard let weight = workout.weight else { return nil }
                return (workout.date, weight)
            }
            .sorted { $0.0 < $1.0 } // Sort by date ascending
    }
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if chartData.isEmpty {
                Text("No weight data available")
                    .foregroundColor(.gymtimeTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
            } else {
                Chart {
                    ForEach(chartData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Weight", item.weight)
                        )
                        .foregroundStyle(Color.gymtimeAccent)
                        .interpolationMethod(.catmullRom) // Smooth curve
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Weight", item.weight)
                        )
                        .foregroundStyle(Color.gymtimeAccent)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(dateFormatter.string(from: date))
                                    .font(.caption2)
                                    .foregroundColor(.gymtimeTextSecondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text("\(Int(weight))lbs")
                                    .font(.caption2)
                                    .foregroundColor(.gymtimeTextSecondary)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 8)
            }
            
            // Show max weight if available
            if let maxWeight = chartData.max(by: { $0.weight < $1.weight })?.weight {
                HStack(spacing: 16) {
                    Text("Max Weight: \(Int(maxWeight))lbs")
                        .font(.caption)
                        .foregroundColor(.gymtimeTextSecondary)
                    
                    // Calculate and show average reps
                    let workoutsWithReps = workouts.compactMap { $0.reps }
                    if !workoutsWithReps.isEmpty {
                        let avgReps = Double(workoutsWithReps.reduce(0, +)) / Double(workoutsWithReps.count)
                        Text("Average Reps: \(String(format: "%.1f", avgReps))")
                            .font(.caption)
                            .foregroundColor(.gymtimeTextSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
} 