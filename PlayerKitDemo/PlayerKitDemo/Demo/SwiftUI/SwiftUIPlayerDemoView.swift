//
//  SwiftUIPlayerDemoView.swift
//  PlayerKitDemo
//
//  SwiftUI 播放器演示 - 胶水代码模式
//

import SwiftUI
import PlayerKit

// MARK: - SwiftUI View

struct SwiftUIPlayerDemoView: View {
    @StateObject private var viewModel = PlayerViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 播放器视图
                    PlayerView(playerView: viewModel.playerView)
                        .frame(height: geometry.size.width * 9 / 16)
                        .clipped()

                    // 控制面板
                    ScrollView {
                        VStack(spacing: 20) {
                            videoInfoSection
                            playbackControlSection
                            speedControlSection
                            featureDemoSection
                            statusSection
                            videoListSection
                            Spacer(minLength: 100)
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
        .navigationTitle("SwiftUI Player")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadInitialData() }
        .onDisappear { viewModel.cleanup() }
    }

    // MARK: - Video Info

    private var videoInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let video = viewModel.currentVideo {
                Text(video.title).font(.headline)
                Text(video.desc).font(.subheadline).foregroundColor(.secondary).lineLimit(2)

                HStack {
                    Label("\(video.playCount)", systemImage: "play.circle")
                    Label("\(video.likeCount)", systemImage: "heart")
                    Spacer()
                    Text("作者: \(video.creator.nickname)").font(.caption).foregroundColor(.secondary)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            } else {
                Text("加载中...").foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Playback Control

    private var playbackControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("播放控制").font(.headline)

            HStack(spacing: 20) {
                Button { viewModel.playPrevious() } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.hasPrevious ? .blue : .gray)
                }
                .disabled(!viewModel.hasPrevious)

                Button { viewModel.togglePlayPause() } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }

                Button { viewModel.playNext() } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.hasNext ? .blue : .gray)
                }
                .disabled(!viewModel.hasNext)

                Spacer()

                Button { viewModel.toggleFullScreen() } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle())

                HStack {
                    Text(viewModel.timeText).font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("缓冲: \(Int(viewModel.bufferProgress * 100))%").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Speed Control

    private var speedControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("倍速控制").font(.headline)

            HStack(spacing: 12) {
                ForEach([0.5, 1.0, 1.5, 2.0] as [Float], id: \.self) { speed in
                    Button {
                        viewModel.setSpeed(speed)
                    } label: {
                        Text(speed == 1.0 ? "1x" : String(format: "%.1fx", speed))
                            .font(.subheadline)
                            .fontWeight(viewModel.currentSpeed == speed ? .bold : .regular)
                            .foregroundColor(viewModel.currentSpeed == speed ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.currentSpeed == speed ? Color.blue : Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Feature Demo

    private var featureDemoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("插件功能").font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FeatureButton(title: "Toast", icon: "bubble.right") {
                    viewModel.showToast("这是一个 Toast 消息")
                }

                FeatureButton(title: viewModel.isLooping ? "循环: 开" : "循环: 关",
                              icon: viewModel.isLooping ? "repeat.1" : "repeat") {
                    viewModel.toggleLoop()
                }

                FeatureButton(title: viewModel.isMuted ? "取消静音" : "静音",
                              icon: viewModel.isMuted ? "speaker.slash" : "speaker.wave.2") {
                    viewModel.toggleMute()
                }

                FeatureButton(title: "截图", icon: "camera") {
                    viewModel.captureSnapshot()
                }

                FeatureButton(title: "重播", icon: "arrow.clockwise") {
                    viewModel.replay()
                }

                FeatureButton(title: "进度", icon: "timer") {
                    viewModel.showToast("进度: \(Int(viewModel.progress * 100))%")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("播放器状态").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                StatusRow(label: "状态", value: viewModel.playbackStateText)
                StatusRow(label: "循环", value: viewModel.isLooping ? "开" : "关")
                StatusRow(label: "静音", value: viewModel.isMuted ? "是" : "否")
                StatusRow(label: "索引", value: "\(viewModel.currentIndex + 1) / \(viewModel.videos.count)")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Video List

    private var videoListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("视频列表").font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView().scaleEffect(0.8)
                } else if viewModel.hasMore {
                    Button("加载更多") { viewModel.loadMore() }.font(.caption)
                }
            }

            LazyVStack(spacing: 8) {
                ForEach(Array(viewModel.videos.enumerated()), id: \.element.feedId) { index, video in
                    VideoRow(video: video, isActive: index == viewModel.currentIndex) {
                        viewModel.playVideo(at: index)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Helper Views

struct PlayerView: UIViewRepresentable {
    let playerView: UIView?

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        return container
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        guard let pv = playerView, pv.superview !== uiView else { return }
        uiView.subviews.forEach { $0.removeFromSuperview() }
        pv.frame = uiView.bounds
        pv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        uiView.addSubview(pv)
    }
}

struct FeatureButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
}

struct StatusRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct VideoRow: View {
    let video: ShowcaseVideo
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(isActive ? "▶" : "")
                    .font(.caption)
                    .foregroundColor(isActive ? .blue : .clear)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(isActive ? .bold : .regular)
                        .lineLimit(1)

                    HStack {
                        Text(formatDuration(video.duration)).font(.caption)
                        Text("•").font(.caption)
                        Text("\(video.playCount) 播放").font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isActive ? "play.circle.fill" : "play.circle")
                    .foregroundColor(isActive ? .blue : .gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%d:%02d", Int(duration) / 60, Int(duration) % 60)
    }
}

// MARK: - PlayerViewModel (胶水层)

@MainActor
class PlayerViewModel: ObservableObject {

    // MARK: - SwiftUI 绑定属性

    @Published var videos: [ShowcaseVideo] = []
    @Published var currentVideo: ShowcaseVideo?
    @Published var currentIndex: Int = -1
    @Published var isLoading = false
    @Published var hasMore = true

    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var bufferProgress: Double = 0
    @Published var timeText = "00:00 / 00:00"
    @Published var playbackStateText = "未开始"
    @Published var isLooping = false
    @Published var isMuted = false
    @Published var currentSpeed: Float = 1.0

    // MARK: - 计算属性

    var hasPrevious: Bool { currentIndex > 0 }
    var hasNext: Bool { currentIndex < videos.count - 1 }

    // MARK: - PlayerKit 相关

    private(set) var player: Player?
    private(set) var playerView: UIView?
    private var progressToken: String?

    // MARK: - 数据加载

    func loadInitialData() {
        isLoading = true
        ShowcaseDataSource.shared.fetchFeed { [weak self] newVideos, hasMore in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.videos = newVideos
                self.hasMore = hasMore
                self.isLoading = false
                if let first = newVideos.first {
                    self.playVideo(at: 0)
                }
            }
        }
    }

    func loadMore() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        ShowcaseDataSource.shared.loadMore { [weak self] newVideos, hasMore in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.videos.append(contentsOf: newVideos)
                self.hasMore = hasMore
                self.isLoading = false
            }
        }
    }

    // MARK: - 播放控制

    func playVideo(at index: Int) {
        guard index >= 0, index < videos.count else { return }

        let video = videos[index]
        currentVideo = video
        currentIndex = index

        // 清理旧播放器
        cleanupPlayer()

        // 创建新播放器
        player = Player()
        playerView = player?.playerView

        // 配置数据
        if let url = video.url {
            var model = PlayerDataModel()
            model.videoURL = url
            model.title = video.title
            model.duration = video.duration
            player?.dataService?.updateDataModel(model)
        }

        // 绑定事件
        bindEvents()

        // 开始播放
        player?.playbackControlService?.play()
    }

    func playPrevious() {
        guard hasPrevious else { return }
        playVideo(at: currentIndex - 1)
    }

    func playNext() {
        guard hasNext else { return }
        playVideo(at: currentIndex + 1)
    }

    func togglePlayPause() {
        player?.playbackControlService?.togglePlayPause()
    }

    func toggleFullScreen() {
        player?.fullScreenService?.toggleFullScreen(orientation: .auto, animated: true)
    }

    func setSpeed(_ speed: Float) {
        player?.speedService?.setSpeed(speed)
        currentSpeed = speed
    }

    func toggleLoop() {
        player?.engineCoreService?.isLooping.toggle()
        isLooping = player?.engineCoreService?.isLooping ?? false
    }

    func toggleMute() {
        player?.mediaControlService?.toggleMute()
        isMuted = player?.mediaControlService?.isMuted ?? false
    }

    func showToast(_ message: String) {
        player?.toastService?.showToast(message, style: .info, duration: 2.0)
    }

    func captureSnapshot() {
        player?.snapshotService?.currentFrameImage { [weak self] image in
            self?.showToast(image != nil ? "截图成功!" : "截图失败")
        }
    }

    func replay() {
        player?.engineCoreService?.seek(to: 0)
        player?.playbackControlService?.play()
    }

    // MARK: - 事件绑定 (胶水代码核心)

    private func bindEvents() {
        guard let player = player else { return }
        let ctx = player.context

        // 播放状态 → @Published isPlaying
        ctx.add(self, event: .playerPlaybackStateChanged) { [weak self] state, _ in
            guard let self = self,
                  let state = state as? PlayerPlaybackState else { return }
            self.isPlaying = (state == .playing)
            self.playbackStateText = self.describe(state)
        }

        // 加载状态 → @Published bufferProgress
        ctx.add(self, event: .playerLoadStateDidChange) { [weak self] _, _ in
            guard let self = self else { return }
            self.bufferProgress = self.player?.engineCoreService?.bufferProgress ?? 0
        }

        // 循环状态 → @Published isLooping
        ctx.add(self, event: .playerLoopingDidChange) { [weak self] _, _ in
            self?.isLooping = self?.player?.engineCoreService?.isLooping ?? false
        }

        // 进度监听 → @Published progress, timeText
        progressToken = player.processService?.observeProgress { [weak self] progress, time in
            guard let self = self else { return }
            self.progress = progress
            if let duration = self.player?.engineCoreService?.duration {
                self.timeText = "\(format(time)) / \(format(duration))"
            }
        }

        // 播放完成 → 自动下一个
        ctx.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.playNext()
            }
        }
    }

    // MARK: - 清理

    private func cleanupPlayer() {
        if let token = progressToken {
            player?.processService?.removeProgressObserver(token: token)
            progressToken = nil
        }
        player?.context.removeHandlers(forObserver: self)
        player?.stop()
        player = nil
        playerView = nil
    }

    func cleanup() {
        cleanupPlayer()
    }

    // MARK: - Helpers

    private func describe(_ state: PlayerPlaybackState) -> String {
        switch state {
        case .stopped: return "已停止"
        case .playing: return "播放中"
        case .paused: return "已暂停"
        case .seeking: return "Seek中"
        case .failed: return "失败"
        }
    }

    private func format(_ time: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(time) / 60, Int(time) % 60)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SwiftUIPlayerDemoView()
    }
}
