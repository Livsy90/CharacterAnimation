import SwiftUI

extension View {
    func exhaledSmoke(
        isActive: Bool,
        particleCount: Int = 28,
        duration: TimeInterval = 1.35
    ) -> some View {
        modifier(
            ExhaledSmokeModifier(
                isActive: isActive,
                particleCount: particleCount,
                duration: duration
            )
        )
    }
    
    func cigaretteSmoke(
        isActive: Bool = true,
        particleCount: Int = 18,
        anchor: UnitPoint = UnitPoint(x: 0.28, y: 0.46),
        relativeSize: CGSize = CGSize(width: 0.24, height: 0.42)
    ) -> some View {
        modifier(
            CigaretteSmokeModifier(
                isActive: isActive,
                particleCount: particleCount,
                anchor: anchor,
                relativeSize: relativeSize
            )
        )
    }
}

private struct ExhaledSmokeModifier: ViewModifier {
    let isActive: Bool
    let particleCount: Int
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    ExhaledSmokeView(
                        particleCount: particleCount,
                        duration: duration
                    )
                    .padding(.vertical, 44)
                }
            }
            .clipped()
    }
}

private struct ExhaledSmokeView: View {
    let particleCount: Int
    let duration: TimeInterval
    
    @State private var startDate = Date()
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawSmoke(in: &context, size: size, date: timeline.date)
            }
        }
        .onAppear {
            startDate = Date()
        }
    }
    
    private func drawSmoke(in context: inout GraphicsContext, size: CGSize, date: Date) {
        guard size.width > 0, size.height > 0, particleCount > 0, duration > 0 else { return }
        
        let elapsed = max(0, date.timeIntervalSince(startDate))
        let progress = min(elapsed / duration, 1)
        let origin = CGPoint(x: size.width * 0.5, y: size.height * 0.48)
        let baseScale = min(size.width, size.height)
        
        for index in 0..<particleCount {
            let seed = Double(index)
            let angle = -Double.pi * 0.92 + Double(index % 11) / 10 * Double.pi * 0.84
            let phase = Double((index * 29) % 100) / 100
            let particleProgress = min(max(progress + phase * 0.18, 0), 1)
            let particleEase = 1 - pow(1 - particleProgress, 2)
            let horizontalSpread = cos(angle) * size.width * (0.24 + phase * 0.28)
            let verticalLift = sin(angle) * size.height * (0.16 + phase * 0.22) - size.height * 0.1
            let drift = sin(elapsed * (1.1 + seed * 0.04) + seed) * baseScale * 0.035
            let x = origin.x + horizontalSpread * particleEase + drift
            let y = origin.y + verticalLift * particleEase
            let radius = baseScale * (0.035 + particleProgress * 0.11) * (0.75 + Double(index % 4) * 0.12)
            let opacity = max(0, 0.16 * sin(particleProgress * .pi) * (1 - progress * 0.55))
            
            var particleContext = context
            particleContext.opacity = opacity
            particleContext.addFilter(.blur(radius: radius * (0.55 + progress * 0.65)))
            
            let rect = CGRect(
                x: x - radius * 1.35,
                y: y - radius * 0.8,
                width: radius * 2.7,
                height: radius * 1.6
            )
            
            particleContext.fill(
                Path(ellipseIn: rect),
                with: .color(.white.opacity(0.68))
            )
        }
    }
}

private struct CigaretteSmokeModifier: ViewModifier {
    let isActive: Bool
    let particleCount: Int
    let anchor: UnitPoint
    let relativeSize: CGSize
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    if isActive {
                        CigaretteSmokeView(particleCount: particleCount)
                            .frame(
                                width: geometry.size.width * relativeSize.width,
                                height: geometry.size.height * relativeSize.height
                            )
                            .position(
                                x: geometry.size.width * anchor.x,
                                y: geometry.size.height * anchor.y
                            )
                            .allowsHitTesting(false)
                    }
                }
            }
    }
}

private struct CigaretteSmokeView: View {
    let particleCount: Int
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawSmoke(in: &context, size: size, date: timeline.date)
            }
        }
    }
    
    private func drawSmoke(in context: inout GraphicsContext, size: CGSize, date: Date) {
        guard size.width > 0, size.height > 0, particleCount > 0 else { return }
        
        let elapsed = date.timeIntervalSinceReferenceDate
        let origin = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
        
        for index in 0..<particleCount {
            let seed = Double(index)
            let duration = 4.2 + Double(index % 5) * 0.32
            let phase = Double((index * 37) % 100) / 100
            let progress = (elapsed / duration + phase).truncatingRemainder(dividingBy: 1)
            let easeOut = 1 - pow(1 - progress, 2)
            let side = index.isMultiple(of: 2) ? -1.0 : 1.0
            let lateralWander = sin(elapsed * (0.55 + seed * 0.018) + seed) * size.width * 0.035
            let wideningDrift = side * easeOut * size.width * (0.045 + Double(index % 4) * 0.009)
            let x = origin.x + lateralWander + wideningDrift
            let y = origin.y - easeOut * size.height * 0.62
            let radius = size.width * (0.025 + progress * 0.055) * (0.8 + Double(index % 3) * 0.12)
            let opacity = max(0, 0.18 * sin(progress * .pi))
            
            var particleContext = context
            particleContext.opacity = opacity
            particleContext.addFilter(.blur(radius: radius * 0.42))
            
            let rect = CGRect(
                x: x - radius,
                y: y - radius * 0.72,
                width: radius * 2,
                height: radius * 1.44
            )
            
            particleContext.fill(
                Path(ellipseIn: rect),
                with: .color(.white.opacity(0.72))
            )
        }
    }
}
