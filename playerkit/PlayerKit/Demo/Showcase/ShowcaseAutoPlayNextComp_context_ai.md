# ShowcaseAutoPlayNextComp

## 职责
自动连播组件。当前视频播放结束后，自动请求跳转到下一个视频。

## 注册位置
`ShowcaseFeedSceneRegProvider` → `ShowcaseFeedSceneContext`（Cell 级别 Context）

## 依赖的 Service
- `ShowcaseFeedDataService` — 获取当前视频 index
- `PlayerEngineCoreService` — 最后一个视频时 replay

## 监听事件
- `.playerPlaybackDidFinish` — 播放完成时触发连播逻辑

## 发出事件
- `.showcaseAutoPlayNextRequest` — 携带当前 videoIndex，请求 VC 层滚动到下一页

## 配置模型
`ShowcaseAutoPlayNextConfigModel`
- `totalCount: Int` — 视频总数
- `isEnabled: Bool` — 是否启用

## 连播逻辑
1. 播放结束 → 检查是否启用
2. 当前 index + 1 < totalCount → 发出 `.showcaseAutoPlayNextRequest` 事件
3. 当前是最后一个视频 → seek(0) + play()（替代 looping）

## 关联修改
- `ShowcaseFeedPlaybackPlugin.playVideo()` 中 `isLooping` 从 `true` 改为 `false`
- `ShowcaseViewController` 监听 `.showcaseAutoPlayNextRequest`，收到后 scrollToItem + handlePageChange
