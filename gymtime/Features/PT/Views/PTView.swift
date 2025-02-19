// 📄 Displays the user's body status and recovery information

import SwiftUI

struct PTView: View {
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Muscles to Work Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Muscles to Work")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            
                            // Gray bars
                            ForEach(0..<10, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)
                            }
                        }
                        
                        Text("Hit every muscle to unlock this score")
                            .foregroundColor(.gray)
                            .font(.footnote)
                        
                        // Muscle Group Cards
                        VStack(spacing: 12) {
                            MuscleGroupCard(title: "Push Muscles", strength: "00")
                            MuscleGroupCard(title: "Pull Muscles", strength: "00")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Anterior Muscles to Work Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Anterior Muscles to Work")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                        
                        // Apple Health Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Use Apple Health?")
                                    .foregroundColor(.white)
                                    .font(.callout.weight(.medium))
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Text("Use body composition stats and")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
            
            Spacer()
        }
        .background(Color.black)
    }
}

struct MuscleGroupCard: View {
    let title: String
    let strength: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.callout.weight(.medium))
                
                Text("\(strength) mSTRENGTH")
                    .foregroundColor(.gray)
                    .font(.callout.weight(.medium))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    PTView()
} 