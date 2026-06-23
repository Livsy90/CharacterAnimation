import SwiftUI

struct AnimatedCharacterView: View {
    private enum AnimationKind {
        case idle
        case firstAction
        case secondAction
    }
    
    private var idleFrames: [Image]
    private var firstActionFrames: [Image]
    private var secondActionFrames: [Image]
    
    private var actionFinishPause: TimeInterval = 1
    
    private var firstActionTitle: LocalizedStringKey = "smoke"
    private var secondActionTitle: LocalizedStringKey = "wink"
    
    @State private var idleFrameAnimator: FrameAnimator
    @State private var firstActionFrameAnimator: FrameAnimator
    @State private var secondActionFrameAnimator: FrameAnimator
    @State private var type: AnimationKind = .idle
    @State private var finishActionTask: Task<Void, Never>?
    @State private var shaderStartDate = Date()
    
    init(
        idleFrames: [Image] = .defaultIdleFrames,
        firstActionFrames: [Image] = .defaultFirstActionFrames,
        secondActionFrames: [Image] = .defaultSecondActionFrames,
        idleInterval: TimeInterval = 0.08,
        firstActionInterval: TimeInterval = 0.1,
        secondActionInterval: TimeInterval = 0.1,
        idleLoopPause: TimeInterval = 4
    ) {
        let idleFrames = idleFrames.isEmpty ? [Image(systemName: "photo")] : idleFrames
        let firstActionFrames = firstActionFrames.isEmpty ? idleFrames : firstActionFrames
        let secondActionFrames = secondActionFrames.isEmpty ? idleFrames : secondActionFrames
        
        self.idleFrames = idleFrames
        self.firstActionFrames = firstActionFrames
        self.secondActionFrames = secondActionFrames
        
        let idleInterval = max(0, idleInterval)
        let firstActionInterval = max(0, firstActionInterval)
        let secondActionInterval = max(0, secondActionInterval)
        let idleLoopPause = max(0, idleLoopPause)
        
        idleFrameAnimator = FrameAnimator(
            interval: idleInterval,
            totalFrames: idleFrames.count,
            loopPause: idleLoopPause
        )
        
        firstActionFrameAnimator = FrameAnimator(
            interval: firstActionInterval,
            totalFrames: firstActionFrames.count
        )
        
        secondActionFrameAnimator = FrameAnimator(
            interval: secondActionInterval,
            totalFrames: secondActionFrames.count
        )
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let side = min(geometry.size.width, geometry.size.height)
                
                TimelineView(.animation) { _ in
                    currentImage
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(.vertical, 22)
                        .padding(.horizontal, 6)
                        .background(.black)
                        .frame(width: side, height: side)
                        .layerEffect(
                            ShaderLibrary.vhsDisplayShader(
                                .float(-shaderStartDate.timeIntervalSinceNow),
                                .float2(side, side)
                            ),
                            maxSampleOffset: .zero
                        )
                        .cigaretteSmoke(
                            isActive: isSmokeVisible,
                            anchor: UnitPoint(x: 0.18, y: 0.25),
                            relativeSize: CGSize(width: 0.24, height: 0.25)
                        )
                        .exhaledSmoke(isActive: isExhaleSmokeVisible)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .onAppear {
                shaderStartDate = Date()
                guard type == .idle else { return }
                idleFrameAnimator.start()
            }
            .onDisappear {
                finishActionTask?.cancel()
                finishActionTask = nil
                idleFrameAnimator.stop()
                firstActionFrameAnimator.stop()
                secondActionFrameAnimator.stop()
            }
            
            HStack {
                Button(firstActionTitle) {
                    startAction(.firstAction, frameAnimator: firstActionFrameAnimator)
                }
                .buttonStyle(.glass)
                .buttonSizing(.flexible)
                .fontDesign(.monospaced)
                .font(.footnote)
                
                Button(secondActionTitle) {
                    startAction(.secondAction, frameAnimator: secondActionFrameAnimator)
                }
                .buttonStyle(.glass)
                .buttonSizing(.flexible)
                .fontDesign(.monospaced)
                .font(.footnote)
            }
        }
    }
    
    func actionFinishPause(_ value: TimeInterval) -> Self {
        var copy = self
        copy.actionFinishPause = max(0, value)
        return copy
    }
    
    func firstActionTitle(_ value: LocalizedStringKey) -> Self {
        var copy = self
        copy.firstActionTitle = value
        return copy
    }
    
    func secondActionTitle(_ value: LocalizedStringKey) -> Self {
        var copy = self
        copy.secondActionTitle = value
        return copy
    }
}

extension AnimatedCharacterView {
    static var `default`: some View {
        AnimatedCharacterView(
            idleInterval: 0.08,
            firstActionInterval: 0.1,
            secondActionInterval: 0.1,
            idleLoopPause: 4
        )
        .actionFinishPause(1)
        .firstActionTitle("smoke")
        .secondActionTitle("wink")
        .padding(26)
        .background(Color.secondary.opacity(0.4), in: .rect(cornerRadius: 30))
        .padding()
    }
}

private extension AnimatedCharacterView {
    var currentImage: Image {
        switch type {
        case .idle:
            idleFrames[frameIndex(for: idleFrameAnimator.frame, in: idleFrames)]
            
        case .firstAction:
            firstActionFrames[frameIndex(for: firstActionFrameAnimator.frame, in: firstActionFrames)]
            
        case .secondAction:
            secondActionFrames[frameIndex(for: secondActionFrameAnimator.frame, in: secondActionFrames)]
        }
    }
    
    var isSmokeVisible: Bool {
        switch type {
        case .idle, .secondAction:
            true
            
        case .firstAction:
            firstActionFrameAnimator.frame >= firstActionFrames.count
        }
    }
    
    var isExhaleSmokeVisible: Bool {
        type == .firstAction && firstActionFrameAnimator.frame >= firstActionFrames.count
    }
    
    private func startAction(_ animationKind: AnimationKind, frameAnimator: FrameAnimator) {
        guard type == .idle else { return }
        
        idleFrameAnimator.stop()
        frameAnimator.reset()
        type = animationKind
        frameAnimator.start(repeats: false) {
            finishAction(animationKind, frameAnimator: frameAnimator)
        }
    }
    
    private func finishAction(_ animationKind: AnimationKind, frameAnimator: FrameAnimator) {
        frameAnimator.stop()
        guard type == animationKind else { return }
        
        finishActionTask?.cancel()
        finishActionTask = Task { @MainActor in
            await sleep(for: actionFinishPause)
            guard !Task.isCancelled, type == animationKind else { return }
            
            type = .idle
            idleFrameAnimator.reset()
            idleFrameAnimator.start()
        }
    }
    
    func sleep(for duration: TimeInterval) async {
        guard duration > 0 else { return }
        
        let nanoseconds = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
    
    func frameIndex(for frame: Int, in frames: [Image]) -> Int {
        min(max(frame - 1, 0), frames.count - 1)
    }
}

private extension Array where Element == Image {
    static let defaultIdleFrames = (1...5).map { Image("idle-\($0)") }
    static let defaultFirstActionFrames = (1...13).map { Image("smoke-\($0)") }
    static let defaultSecondActionFrames = (1...6).map { Image("wink-\($0)") }
}

#Preview {
    AnimatedCharacterView.default
}

