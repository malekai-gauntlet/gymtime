import SwiftUI
@available(iOS 16.0, *)

struct PBCelebrationView: View {
    let pbInfo: PBInfo
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Full screen black overlay
            Color.black
                .opacity(0.7)
                .ignoresSafeArea()  // This will cover everything
                .frame(maxWidth: .infinity, maxHeight: .infinity)  // Ensure full coverage
            
            // Modal content
            VStack(spacing: 16) {
                // Emoji and Title
                VStack(spacing: 12) {
                    Text("NEW PR")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gymtimeText)
                    
                    Text(pbInfo.exercise)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.gymtimeText)
                }
                
                // Weight achievement
                VStack(spacing: 8) {
                    Text("\(Int(pbInfo.weight)) lbs")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.gymtimeAccent)
                    
                    // Sets and Reps
                    if let sets = pbInfo.sets, let reps = pbInfo.reps {
                        Text("\(sets) sets × \(reps) reps")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gymtimeTextSecondary)
                    }
                }
                
                // Congratulatory message
                Text("Congrats on your new personal record!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gymtimeTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Dismiss button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 200)
                        .padding(.vertical, 12)
                        .background(Color.gymtimeAccent)
                        .cornerRadius(10)
                }
                .padding(.top, 4)
                
                // Share button
                Button(action: {
                    // Create snapshot of the achievement view
                    let renderer = ImageRenderer(content: 
                        VStack(spacing: 20) {
                            // Achievement card content
                            VStack(spacing: 12) {
                                Text("NEW PR")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(pbInfo.exercise)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("\(Int(pbInfo.weight)) lbs")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.gymtimeAccent)
                                
                                if let sets = pbInfo.sets, let reps = pbInfo.reps {
                                    Text("\(sets) sets × \(reps) reps")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .frame(width: 300, height: 250)
                        .padding(30)
                        .background(Color.black)
                        .cornerRadius(20)
                    )
                    
                    renderer.scale = 3.0 // Higher resolution
                    
                    // Generate the image
                    let image = renderer.uiImage
                    
                    // Create share text
                    var shareText = "New PR on gymhead — hit \(Int(pbInfo.weight))lbs on \(pbInfo.exercise)!"
                    if let sets = pbInfo.sets, let reps = pbInfo.reps {
                        shareText += " (\(sets)×\(reps))"
                    }
                    
                    // Items to share
                    var itemsToShare: [Any] = []
                    if let image = image {
                        itemsToShare.append(image)
                    }
                    itemsToShare.append(shareText)
                    
                    let activityVC = UIActivityViewController(
                        activityItems: itemsToShare,
                        applicationActivities: nil
                    )
                    
                    // Get the root view controller
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                        Text("Share")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.gymtimeTextSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .padding(30)
            .background(Color.black.opacity(0.95))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
} 