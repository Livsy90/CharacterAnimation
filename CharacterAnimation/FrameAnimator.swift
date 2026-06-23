import Foundation

@MainActor
@Observable
final class FrameAnimator {
    var frame: Int = 1
    
    @ObservationIgnored
    private var animationTask: Task<Void, Never>?
    
    private let totalFrames: Int
    private let interval: TimeInterval
    private let loopPause: TimeInterval
    
    init(
        interval: TimeInterval,
        totalFrames: Int,
        loopPause: TimeInterval = 0
    ) {
        self.interval = max(0, interval)
        self.totalFrames = max(1, totalFrames)
        self.loopPause = max(0, loopPause)
    }
    
    func start(
        repeats: Bool = true,
        onCompletion: (() -> Void)? = nil
    ) {
        stop()
        
        animationTask = Task { [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                await self.sleep(for: self.interval)
                guard !Task.isCancelled else { return }
                
                if self.frame >= self.totalFrames {
                    if repeats {
                        self.frame = 1
                        await self.sleep(for: self.loopPause)
                        guard !Task.isCancelled else { return }
                    } else {
                        self.animationTask = nil
                        onCompletion?()
                        return
                    }
                } else {
                    self.frame += 1
                    
                    if !repeats, self.frame >= self.totalFrames {
                        self.animationTask = nil
                        onCompletion?()
                        return
                    }
                }
            }
        }
    }
    
    func stop() {
        animationTask?.cancel()
        animationTask = nil
    }
    
    func reset() {
        stop()
        frame = 1
    }
    
    private func sleep(for duration: TimeInterval) async {
        guard duration > 0 else { return }
        
        let nanoseconds = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
