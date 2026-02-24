//
//  SwiftUIPlayerDemoView.swift
//  PlayerKitDemo
//
//  SwiftUI 播放器演示 - 展示插件化架构
//

import SwiftUI
import PlayerKit
import AVKit

// MARK: - SwiftUI Player Demo View

struct SwiftUIPlayerDemoView: View {

    @StateObject private var viewModel = PlayerViewModel()
    @State private var selectedSpeed: Float = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 播放器视图
                    PlayerViewRepresentable(
                        player: viewModel.player,
                        playerView: viewModel.playerView
                    )
                    .frame(height: geometry.size.width * 9 / 16)
                    .clipped()

                    // 控制面板
                    ScrollView {
                        VStack(spacing: 20) {
                            // 视频信息
                            videoInfoSection

                            // 播放控制
                            playbackControlSection

                            // 倍速控制
                            speedControlSection

                            // 功能演示
                            featureDemoSection

                            // 状态显示
                            statusSection

                            // 视频列表
                            videoListSection

                            Spacer(minLength: 100)
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
        .navigationTitle("SwiftUI Player Demo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadInitialData()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Video Info Section

    private var videoInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let video = viewModel.currentVideo {
                Text(video.title)
                    .font(.headline)
                Text(video.desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Label("\(video.playCount)", systemImage: "play.circle")
                    Label("\(video.likeCount)", systemImage: "heart")
                    Label("\(video.commentCount)", systemImage: "bubble.right")
                    Spacer()
                    Text("创作者: \(video.creator.nickname)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            } else {
                Text("加载中...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Playback Control Section

    private var playbackControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("播放控制")
                .font(.headline)

            HStack(spacing: 20) {
                // 上一个
                Button(action: {
                    viewModel.playPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.hasPrevious ? .blue : .gray)
                }
                .disabled(!viewModel.hasPrevious)

                // 播放/暂停
                Button(action: {
                    viewModel.togglePlayPause()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }

                // 下一个
                Button(action: {
                    viewModel.playNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.hasNext ? .blue : .gray)
                }
                .disabled(!viewModel.hasNext)

                Spacer()

                // 全屏按钮
                Button(action: {
                    viewModel.toggleFullScreen()
                }) {
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
                    Text(viewModel.timeText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("缓冲: \(Int(viewModel.bufferProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Speed Control Section

    private var speedControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("倍速控制")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach([Float(0.5), Float(1.0), Float(1.5), Float(2.0)], id: \.self) { speed in
                    Button(action: {
                        viewModel.setSpeed(speed)
                        selectedSpeed = speed
                    }) {
                        Text(speed == 1.0 ? "1x" : String(format: "%.1fx", speed))
                            .font(.subheadline)
                            .fontWeight(selectedSpeed == speed ? .bold : .regular)
                            .foregroundColor(selectedSpeed == speed ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedSpeed == speed ? Color.blue : Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Feature Demo Section

    private var featureDemoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("插件功能演示")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FeatureButton(title: "Toast 提示", icon: "bubble.right") {
                    viewModel.showToast("这是一个 Toast 消息")
                }

                FeatureButton(title: "显示进度", icon: "timer") {
                    viewModel.showToast("当前进度: \(Int(viewModel.progress * 100))%")
                }

                FeatureButton(title: "切换循环", icon: viewModel.isLooping ? "repeat.1" : "repeat") {
                    viewModel.toggleLoop()
                }

                FeatureButton(title: "静音/取消", icon: viewModel.isMuted ? "speaker.slash" : "speaker.wave.2") {
                    viewModel.toggleMute()
                }

                FeatureButton(title: "截图", icon: "camera") {
                    viewModel.captureSnapshot()
                }

                FeatureButton(title: "重播", icon: "arrow.clockwise") {
                    viewModel.replay()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("播放器状态")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                StatusRow(label: "状态", value: viewModel.playbackStateText)
                StatusRow(label: "加载状态", value: viewModel.loadStateText)
                StatusRow(label: "循环", value: viewModel.isLooping ? "开启" : "关闭")
                StatusRow(label: "静音", value: viewModel.isMuted ? "是" : "否")
                StatusRow(label: "全屏", value: viewModel.isFullScreen ? "是" : "否")
                StatusRow(label: "视频索引", value: "\(viewModel.currentIndex + 1) / \(viewModel.totalCount)")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Video List Section

    private var videoListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("视频列表")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if viewModel.hasMore {
                    Button("加载更多") {
                        viewModel.loadMore()
                    }
                    .font(.caption)
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

// MARK: - Video Row

struct VideoRow: View {
    let video: ShowcaseVideo
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 序号
                Text("\(isActive ? "▶" : "")")
                    .font(.caption)
                    .foregroundColor(isActive ? .blue : .clear)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(isActive ? .bold : .regular)
                        .lineLimit(1)

                    HStack {
                        Text(formatDuration(video.duration))
                            .font(.caption)
                        Text("•")
                        Text("\(video.playCount) 播放")
                            .font(.caption)
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
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Feature Button

struct FeatureButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Status Row

struct StatusRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Player View Representable

struct PlayerViewRepresentable: UIViewRepresentable {
    let player: Player?
    let playerView: UIView?

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        return container
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        uiView.subviews.forEach { $0.removeFromSuperview() }

        if let playerView = playerView {
            playerView.translatesAutoresizingMaskIntoConstraints = false
            uiView.addSubview(playerView)
            NSLayoutConstraint.activate([
                playerView.topAnchor.constraint(equalTo: uiView.topAnchor),
                playerView.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: uiView.trailingAnchor),
                playerView.bottomAnchor.constraint(equalTo: uiView.bottomAnchor)
            ])
        }
    }
}

// MARK: - Player ViewModel

@MainActor
class PlayerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var videos: [ShowcaseVideo] = []
    @Published var currentVideo: ShowcaseVideo?
    @Published var currentIndex: Int = -1
    @Published var isLoading = false
    @Published var hasMore = true

    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var timeText = "00:00 / 00:00"
    @Published var bufferProgress: Double = 0
    @Published var playbackStateText = "未开始"
    @Published var loadStateText = "空闲"
    @Published var isLooping = false
    @Published var isMuted = false
    @Published var isFullScreen = false
    @Published var snapshotImage: UIImage?

    // MARK: - Computed Properties

    var hasPrevious: Bool { currentIndex > 0 }
    var hasNext: Bool { currentIndex < videos.count - 1 }
    var totalCount: Int { videos.count }

    // MARK: - Private Properties

    private(set) var player: Player?
    private(set) var playerView: UIView?
    private var sceneContext: SwiftUIPlayerSceneContext?
    private var progressObserverToken: String?

    // MARK: - Data Loading

    func loadInitialData() {
        isLoading = true

        ShowcaseDataSource.shared.fetchFeed { [weak self] newVideos, hasMore in
            Task { @MainActor in
                guard let self = self else { return }

                self.videos = newVideos
                self.hasMore = hasMore
                self.isLoading = false

                // 自动播放第一个
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
            Task { @MainActor in
                guard let self = self else { return }

                self.videos.append(contentsOf: newVideos)
                self.hasMore = hasMore
                self.isLoading = false
            }
        }
    }

    // MARK: - Playback

    func playVideo(at index: Int) {
        guard index >= 0, index < videos.count else { return }

        let video = videos[index]
        currentVideo = video
        currentIndex = index

        // 清理旧播放器
        cleanupPlayer()

        // 创建新播放器
        setupPlayer(url: video.url, video: video)
    }

    func playPrevious() {
        guard hasPrevious else { return }
        playVideo(at: currentIndex - 1)
    }

    func playNext() {
        guard hasNext else { return }
        playVideo(at: currentIndex + 1)
    }

    // MARK: - Setup

    private func setupPlayer(url: URL?, video: ShowcaseVideo) {
        guard let url = url else { return }

        // 创建场景 Context
        let context = SwiftUIPlayerSceneContext()
        self.sceneContext = context

        // 创建播放器
        let player = Player()
        self.player = player

        // 添加到场景
        context.addPlayer(player)

        // 获取 playerView
        self.playerView = player.playerView

        // 配置数据
        if let dataService = player.dataService {
            var model = PlayerDataModel()
            model.videoURL = url
            model.title = video.title
            model.duration = video.duration
            model.videoWidth = video.width
            model.videoHeight = video.height
            dataService.updateDataModel(model)
        }

        player.engineCoreService?.prepareToPlay()

        // 监听事件
        setupEventObservers(player: player)

        // 监听进度
        setupProgressObserver(player: player)

        // 监听播放完成
        player.context.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            // 自动播放下一个
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.playNext()
            }
        }
    }

    private func setupEventObservers(player: Player) {
        let ctx = player.context

        ctx.add(self, event: .playerPlaybackStateChanged) { [weak self] state, _ in
            guard let self = self else { return }
            if let state = state as? PlayerPlaybackState {
                self.isPlaying = (state == .playing)
                self.playbackStateText = self.stateDescription(state)
            }
        }

        ctx.add(self, event: .playerLoadStateDidChange) { [weak self] _, _ in
            guard let self = self else { return }
            if let engine = self.player?.engineCoreService {
                self.loadStateText = self.loadStateDescription(engine.loadState)
                self.bufferProgress = engine.bufferProgress
            }
        }

        ctx.add(self, event: .playerLoopingDidChange) { [weak self] _, _ in
            guard let self = self else { return }
            self.isLooping = self.player?.engineCoreService?.isLooping ?? false
        }

        ctx.add(self, event: .playerFullScreenStateChanged) { [weak self] _, _ in
            guard let self = self else { return }
            if let fsService = self.player?.fullScreenService {
                self.isFullScreen = fsService.isFullScreen
            }
        }
    }

    private func setupProgressObserver(player: Player) {
        guard let processService = player.processService else { return }

        progressObserverToken = processService.observeProgress { [weak self] progress, time in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.progress = progress
                self.updateTimeText(currentTime: time)
            }
        }
    }

    // MARK: - Controls

    func togglePlayPause() {
        player?.playbackControlService?.togglePlayPause()
    }

    func toggleFullScreen() {
        player?.fullScreenService?.toggleFullScreen(orientation: .auto, animated: true)
    }

    func setSpeed(_ speed: Float) {
        player?.speedService?.setSpeed(speed)
    }

    func toggleLoop() {
        if let engine = player?.engineCoreService {
            engine.isLooping.toggle()
            isLooping = engine.isLooping
        }
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
            self?.snapshotImage = image
            if image != nil {
                self?.showToast("截图成功!")
            }
        }
    }

    func replay() {
        player?.engineCoreService?.seek(to: 0)
        player?.playbackControlService?.play()
    }

    // MARK: - Helpers

    private func updateTimeText(currentTime: TimeInterval) {
        guard let duration = player?.engineCoreService?.duration else { return }
        timeText = "\(formatTime(currentTime)) / \(formatTime(duration))"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "00:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func stateDescription(_ state: PlayerPlaybackState) -> String {
        switch state {
        case .stopped: return "已停止"
        case .playing: return "播放中"
        case .paused: return "已暂停"
        case .seeking: return "Seek中"
        case .failed: return "播放失败"
        }
    }

    private func loadStateDescription(_ state: PlayerLoadState) -> String {
        switch state {
        case .idle: return "空闲"
        case .preparing: return "准备中"
        case .ready: return "就绪"
        case .loading: return "加载中"
        case .stalled: return "卡顿"
        case .failed: return "失败"
        }
    }

    // MARK: - Cleanup

    private func cleanupPlayer() {
        if let token = progressObserverToken {
            player?.processService?.removeProgressObserver(token: token)
            progressObserverToken = nil
        }
        player?.context.removeHandlers(forObserver: self)
        player?.stop()
        sceneContext?.removePlayer()

        player = nil
        playerView = nil
        sceneContext = nil
    }

    func cleanup() {
        cleanupPlayer()
    }
}

// MARK: - SwiftUI Player Scene Context

@MainActor
final class SwiftUIPlayerSceneContext {

    let context: PublicContext
    private let regProvider = SwiftUIPlayerRegProvider()
    private weak var _player: Player?

    init() {
        let ctx = Context(name: "SwiftUIPlayerSceneContext")
        self.context = ctx
        ctx.addRegProvider(regProvider)
    }

    func addPlayer(_ player: Player) {
        if _player === player { return }
        removePlayer()
        _player = player
        context.addSubContext(player.context)
    }

    func removePlayer() {
        guard let player = _player else { return }
        context.removeSubContext(player.context)
        _player = nil
    }
}

// MARK: - SwiftUI Player RegProvider

@MainActor
final class SwiftUIPlayerRegProvider: RegisterProvider {

    private let scenePlayerRegProvider = ScenePlayerRegProvider()

    func registerPlugins(with registerSet: PluginRegisterSet) {
        scenePlayerRegProvider.registerPlugins(with: registerSet)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SwiftUIPlayerDemoView()
    }
}
