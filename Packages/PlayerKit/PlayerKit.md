# PlayerKit 架构设计文档

**PlayerKit（Context / Plugin / Service）** 是一个适用于复杂播放器业务场景的服务发现框架，提供了三种不同维度的架构单元以进行对应的业务领域建模。相对于其他框架，PlayerKit 提倡拆分而非再度封装，以此能够更好地实现业务的复用和维护。

PlayerKit 并不是一种特定于 UI 表现层的框架，它更加强调的是 **业务逻辑的拆分和抽象**，以及 **不同层级之间的协作**。

通过使用 PlayerKit 框架，我们可以将复杂的播放器业务逻辑拆分为不同的模块，每个模块负责特定的职责，从而实现业务的高度解耦和复用。同时，PlayerKit 框架还促导每个模块自己定义清晰且完备的生命周期事件，使得不同模块之间的协作更加顺畅和可控。

---

## PlayerKit 的核心特性

- 一个 Context 实例可以持有多个 Plugin 实例，不同的 Context 实例可以有灵活的 Plugin 组合
- 有且只能通过 Context 实例访问（resolve）其下面 Plugin 提供的服务（Service），从而减轻维护各个模块持有关系的负担
- Plugin 自己可以发布事件（post event）到对应的 Context 中，在 Context 下可以监听（observe）对应的 event 来处理自己的逻辑
- 支持 **粘性事件（Sticky Event）**，后注册的监听者也能收到最后发送的值
- 支持 **@PlayerPlugin 宏** 实现声明式依赖注入

---

## Context — 上下文

`Context` 是 `Plugin` 的容器，负责创建并持有 `Plugin` 实例。以容器的维度对外暴露模块服务，并且是事件分发的范围和模块服务调用的入口。

`Context` 具有 **组合结构**、**扩展结构** 和 **共享实例（Shared）结构**。为了维护架构设计简单性，不允许直接存储和访问业务数据，也不建议再继承 `Context`。

> `Context` 来源于 DDD 中的 Bounded Context，是领域模型适用的边界。在 PlayerKit 中，`Context` 由 `Context` 类实现。

### Context 提供的四种能力

1. **事件通信** `<EventHandlerProtocol>` — `Context` 的结构会影响事件发布的范围和服务发现的范围
2. **服务发现** `<ServiceDiscovery>`
3. **模块管理** `<PluginRegisterProtocol>`
4. **组合结构和扩展结构：**
    - `<PublicContext>` — 父子层级关系
    - `<ExtendContext>` — 扩展关系

---

## Context 类型和实例创建

Context 只有一个实现类型 `Context`，与 Plugin 不同，我们 **不推荐再继承它**，应该使用组合的方式：创建一个实例与自己的业务模型相关联。如果想要区别不同的 Context 类型，使用 `name` 标识符即可。

```swift
// 创建 Context 实例
let player = Player()
player.context = Context(name: "Player")

// 使用 RegisterProvider 批量注册模块
player.context.addRegProvider(PlayerRegProvider())
```

我们在构思不同的 Context 类型时，应该和构思业务建模对象一样。比如整个列表拥有一种 Context，列表下面的卡片也有一种 Context，卡片里的体裁播放器也是一种 Context，虽然它们都是 `Context` 实例，但它们拥有的 Plugins 和 Scope 并不一样。

---

## 两层播放器架构

PlayerKit 采用两层分层架构，每层关注不同的职责：

### 第一层：场景层（Scene Layer）

> 为当前场景进行播放器配置，满足场景特异性功能，耦合场景层，**可以感知具体场景**。

场景层负责管理场景级别的状态和生命周期，通过 `ScenePlayerProtocol` 协议定义：

```swift
@MainActor
public protocol ScenePlayerProtocol: ContextHolder {
    /// 场景的公共 Context
    var context: PublicContext { get }
    /// 当前关联的播放器
    var player: Player? { get }
    /// 创建播放器
    func createPlayer(prerenderKey: String?) -> Player
    /// 添加播放器（建立 Context 层级关系）
    func addPlayer(_ player: Player)
    /// 移除播放器
    func removePlayer()
    /// 是否已有播放器
    func hasPlayer() -> Bool
}
```

场景层典型插件：

- `PlayerScenePlayerProcessPlugin` — 场景播放流程管理
- `PlayerPlayerLayeredPlugin` — 播放器生命周期管理
- `ShowcaseFeedDataPlugin` — Feed 场景数据
- `ShowcaseFeedCellViewPlugin` — Feed 场景视图

### 第二层：基础层（Base Layer）

> 提供通用框架，封装通用播放能力，**只感知播放数据**。

**核心 Plugin：**

| 插件 | 服务 | 职责 |
|------|------|------|
| `PlayerEngineCorePlugin` | `PlayerEngineCoreService` | 管理 AVPlayer 引擎 |
| `PlayerProcessPlugin` | `PlayerProcessService` | 播放流程控制 |
| `PlayerViewPlugin` | `PlayerViewService` | 播放器视图管理 |
| `PlayerSpeedPlugin` | `PlayerSpeedService` | 播放速度控制 |
| `PlayerDataPlugin` | `PlayerDataService` | 播放数据管理 |
| `PlayerFullScreenPlugin` | `PlayerFullScreenService` | 全屏控制 |

**业务 Plugin（可复用）：**

- `PlayerWaterMarkPlugin` — 水印
- `PlayerTitlePlugin` — 视频标题
- `PlayerAvatarPlugin` — 作者头像
- `PlayerDanmakuPlugin` — 弹幕

### 层级间通信规则

- **上层可以监听下层的事件**，访问下层的服务
- **下层不可以监听上层的事件**，访问上层的服务
- **Config** 用于配置场景信息和场景逻辑

### Context 层级关系

```
ShowcaseFeedScenePlayer.context (场景层)
│
│   [场景插件]
│   - PlayerPlayerLayeredPlugin
│   - ShowcaseFeedDataPlugin
│   - ShowcaseFeedCellViewPlugin
│
└── Player.context (基础层)
    │
    │   [基础插件]
    │   - PlayerEngineCorePlugin
    │   - PlayerProcessPlugin
    │   - PlayerSpeedPlugin
```

---

## 服务发现

Context 会要求内部的业务模块通过服务的方式对外、对内暴露接口，Context 本身并不提供任何具体服务。

服务发现流程：`Caller` 通过 `context.resolveService(Service.self)` 发起调用 → Context 查找绑定了 `Service` 的 Plugin → 最终找到 `Plugin` 实例。

### resolveService 方法

```swift
// 必定返回服务（失败时断言）
let engineService = context.resolveService(PlayerEngineCoreService.self)

// 可选返回服务（失败时返回 nil）
let speedService = context.tryResolveService(PlayerSpeedService.self)

// 检查服务是否可用
if context.checkService(PlayerSpeedService.self) {
    // 服务可用
}
```

### 服务查找链

Context 实现了服务查找的层级链：

1. 在当前 Context 查找
2. 在子 Context 中递归查找
3. 在基础 Context 中查找（扩展关系）

```swift
private func resolvePlugin(forKey key: String, fromChild: Bool = false) -> BasePlugin? {
    // 1. 在当前 Context 查找
    if let entry = services[key] { return getOrCreatePlugin(from: entry) }

    // 2. 在子 Context 中递归查找
    for child in subContexts.allObjects {
        if let p = child.resolvePlugin(forKey: key, fromChild: true) { return p }
    }

    // 3. 在基础 Context 中查找（扩展关系）
    if !fromChild, let baseCtx = baseContext {
        return baseCtx.resolvePlugin(forKey: key, fromChild: false)
    }

    return nil
}
```

---

## 调用方服务依赖检查

### @PlayerPlugin 宏

PlayerKit 使用 `@PlayerPlugin` 属性包装器实现声明式依赖注入：

```swift
class MyPlugin: BasePlugin {
    @PlayerPlugin(serviceType: PlayerEngineCoreService.self)
    private var engineService: PlayerEngineCoreService?

    @PlayerPlugin(serviceType: PlayerSpeedService.self)
    private var speedService: PlayerSpeedService?

    func doSomething() {
        engineService?.play()
        speedService?.setSpeed(1.5)
    }
}
```

### dependencyProtocols 方法

虽然调用服务很方便，但这实际上意味着调用方内部对这个服务有依赖。PlayerKit 框架要求调用方显式地声明自己依赖了哪些服务：

```swift
class PlayerDanmakuPlugin: BasePlugin {
    // 显式声明依赖的服务
    static func dependencyProtocols() -> [Any.Type]? {
        return [
            PlayerEngineCoreService.self,
            PlayerViewService.self,
            PlayerProcessService.self
        ]
    }
}
```

> **服务依赖检查的必要性**
>
> 在 PlayerKit 中，调用方很容易通过服务发现调用其他模块提供的服务，但是这种便利性会导致调用方对外部的耦合度升高，同时降低了调用方的可复用性。因此，我们需要对服务依赖进行检查，以确保整个系统内部依赖的合理程度。

---

## 事件机制

事件机制是一种 **一对多的广播式模块对外通信方式**，可以类比于 `NotificationCenter`，但区别于传统全局通知，它的作用域受到 Context 限制，从而可以省去识别业务上下文的工作 —— 比如当前 App 进程内有多个播放器实例的情况下，到底是哪一个播放器实例发出的事件。

### 事件定义

事件定义在 `PlayerCoreService.swift` 中，通过扩展 `Event` 类型：

```swift
public extension Event {
    // 播放状态事件
    static let playerPlaybackStateChanged: Event = "PlayerPlaybackStateChanged"
    static let playerReadyToPlay: Event = "PlayerReadyToPlay"
    static let playerDidFinish: Event = "PlayerDidFinish"

    // 粘性事件
    static let playerEngineDidCreateSticky: Event = "PlayerEngineDidCreateSticky"
    static let playerReadyForDisplaySticky: Event = "PlayerReadyForDisplaySticky"

    // Seek 事件
    static let playerSeekBegin: Event = "PlayerSeekBegin"
    static let playerSeekEnd: Event = "PlayerSeekEnd"
}
```

### 事件监听

```swift
// 基本监听
context.add(self, event: .playerPlaybackStateChanged) { object, event in
    // 处理事件
    guard let state = object as? PlayerPlaybackState else { return }
    print("Playback state changed: \(state)")
}

// 监听多个事件
context.add(self, events: [.playerSeekBegin, .playerSeekEnd]) { object, event in
    if event == .playerSeekBegin {
        print("Seek began")
    }
}

// 带选项监听
context.add(self, event: .playerReadyToPlay, option: .execOnlyOnce) { _, _ in
    // 只执行一次
    self?.startTracking()
}

// AOP 监听
context.add(self, beforeEvent: .playerSeekBegin) { object, event in
    // 在 Seek 开始前执行
    print("About to seek")
}

context.add(self, afterEvent: .playerSeekEnd) { object, event in
    // 在 Seek 结束后执行
    print("Seek completed")
}
```

### 事件选项

```swift
public struct EventOption: OptionSet {
    public static let none: EventOption          // 无特殊选项
    public static let execWhenAdd: EventOption   // 注册时立即执行一次回调
    public static let execOnlyOnce: EventOption  // 仅执行一次后自动移除
}
```

### 事件发送

```swift
// 发送普通事件
context.post(.playerSpeedDidChange, object: speedValue, sender: self)

// 发送粘性事件
context.post(.playerReadyForDisplaySticky, object: playerView, sender: self)
```

### 事件传播机制

事件在 Context 层级中自动传播：

```swift
private func propagateEvent(_ event: Event, object: Any?, sender: AnyObject, visited: inout Set<ObjectIdentifier>) {
    // 1. 触发当前 Context 的处理器
    eventHandler.post(event, object: object, sender: sender)

    // 2. 传播到 SharedContext
    sharedContext?.receiveSharedEvent(event, object: object, senderContext: self)

    // 3. 传播到扩展 Context
    extensionContexts.allObjects.forEach {
        $0.propagateEvent(event, object: object, sender: sender, visited: &visited)
    }

    // 4. 传播到父 Context
    superContext?.propagateEvent(event, object: object, sender: sender, visited: &visited)
}
```

---

## 粘性事件（Sticky Event）

粘性事件是一种特殊的事件类型，它的特点是：**后注册的监听者也能收到最后发送的值**。

### 绑定粘性事件

插件在加载时可以绑定粘性事件，用于提供当前状态：

```swift
class MyPlugin: BasePlugin {
    override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 绑定粘性事件
        (self.context as? Context)?.bindStickyEvent(.playerEngineDidCreateSticky) { [weak self] in
            guard let self = self else { return nil }
            return .shouldSend(self.currentEngine)  // 返回当前状态
        }
    }
}
```

### 监听粘性事件

```swift
context.add(self, event: .playerEngineDidCreateSticky) { object, event in
    // 如果事件已经发送过，会立即收到最后的值
    guard let engine = object as? AVPlayer else { return }
    print("Engine created: \(engine)")
}
```

---

## 共享结构 SharedContext

当我们需要获得比单个 Context 更长的存活周期、全局性地进行某个业务时，我们就需要 `SharedContext`。PlayerKit 支持我们为每一种 Context 绑定一个共享 Context，并且注册在 `SharedContext` 下的 Plugin 就是某层的 `SharedPlugin`。

### SharedContext 特性

- `SharedContext` 可以监听收到同类型单个 Context 上发出的生命周期事件
- 相同的服务发现方式

```swift
// 绑定 SharedContext
context.bindSharedContext(PlayerSharedContext.shared)

// 在 SharedPlugin 中监听所有 Context 的事件
class PlayerSharedCachePlugin: BasePlugin {
    override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        context.sharedAdd(self, event: .playerWillCacheProgress) { senderContext, progress, event in
            // 收到所有绑定该 SharedContext 的 Context 发出的事件
            let duration = senderContext.resolveService(PlayerTimeControlService.self).duration
            self.cacheProgress(progress: progress, duration: duration)
        }
    }
}
```

---

## 模块管理

### 模块注册

如果一个 Context 里的要注册的模块比较少，或者这个 Context 不需要考虑将其集成到其他环境中，那么可以直接使用 `<PluginRegisterProtocol>` 中的方法：

```swift
// 直接注册（注册时立即创建实例）
context.register(PlayerEnginePlugin.self, serviceType: PlayerEngineService.self)

// 带配置注册
context.register(PlayerSpeedPlugin.self,
                 serviceType: PlayerSpeedService.self,
                 configModel: speedConfig)
```

### 模块注册器（RegisterProvider）

但如果一种 Context 建模后的 Plugin 会非常多，且注册时机不一样，需要按照业务线或者注册时机进行分类。推荐实现模块注册器 `<RegisterProvider>`，自定义的类型实现该协议后，再使用 Context 的 `addRegProvider` 和 `removeRegProvider` 接口来批量注册和批量移除。

```swift
@MainActor
public protocol RegisterProvider: AnyObject {
    func registerPlugins(with registerSet: PluginRegisterSet)
    func configPluginCreate(_ registerSet: PluginRegisterSet)
}

// 实现注册器
final class PlayerRegProvider: RegisterProvider {
    func registerPlugins(with registerSet: PluginRegisterSet) {
        // 核心插件
        registerSet.addEntry(pluginClass: PlayerDataPlugin.self,
                            serviceType: PlayerDataService.self)
        registerSet.addEntry(pluginClass: PlayerEngineCorePlugin.self,
                            serviceType: PlayerEngineCoreService.self)
        registerSet.addEntry(pluginClass: PlayerProcessPlugin.self,
                            serviceType: PlayerProcessService.self)
        registerSet.addEntry(pluginClass: PlayerSpeedPlugin.self,
                            serviceType: PlayerSpeedService.self)
        // ... 更多插件
    }
}

// 使用注册器
let player = Player()
player.context.addRegProvider(PlayerRegProvider())
```

### PluginRegisterSet

```swift
public final class PluginRegisterSet {
    /// 添加插件注册条目
    public func addEntry(pluginClass: AnyClass,
                        serviceType: Any.Type?,
                        options: PluginCreateOption = [])

    /// 配置分组创建策略
    public func configGroupCreate(groupName: String,
                                 createType: PluginCreateType,
                                 events: [Event]? = nil)
}
```

---

## Plugin 的生命周期

### 生命周期回调

模块实例创建时，它会收到对应的生命周期方法回调：

```swift
/// 模块实例创建并加载到当前 context 中，可以做一些和 context 有关的 setup 工作，
/// 但是禁止直接访问当前 context 下的其他同层服务
/// - Parameter context: 加入的 context
func pluginDidLoad(_ context: ContextProtocol)

/// 模块即将从当前 context 中移除，可以做一些移除的工作
/// - Parameter context: 之前所在的 context
func pluginWillUnload(_ context: ContextProtocol)
```

### Context 层级变化回调

```swift
/// Context 被添加到父 Context 时调用
func contextDidAddToSuperContext(_ superContext: PublicContext)

/// Context 即将从父 Context 移除时调用
func contextWillRemoveFromSuperContext(_ superContext: PublicContext)

/// Context 添加了子 Context 时调用
func contextDidAddSubContext(_ subContext: PublicContext)

/// Context 即将移除子 Context 时调用
func contextWillRemoveSubContext(_ subContext: PublicContext)

/// Context 建立扩展关系时调用
func contextDidExtend(on baseContext: PublicContext)

/// Context 即将解除扩展关系时调用
func contextWillUnextend(on baseContext: PublicContext)
```

### 创建时机分类 PluginCreateType

```swift
public struct PluginCreateType: OptionSet, Sendable {
    /// 注册时就创建实例
    public static let whenRegistered

    /// 第一次配置模块接口数据的时候创建实例
    public static let whenFirstConfig

    /// 第一次服务发现时创建实例
    public static let whenFirstResolve

    /// 延迟创建，发布指定的事件时才创建
    public static let whenPostEvent
}
```

---

## 模块实例存活周期

### 实例创建

通常情况下，当一个模块注册到一个 Context 实例中时，模块实例就会被创建并且被 Context 持有。不过，PlayerKit 也提供了强大的支持，以便满足各种创建时机的需求。

### 实例销毁

1. 当调用 Context 下的 `unregisterService` 或 `unregisterPluginClass` 方法时，Context 会清除模块的注册信息并释放模块实例
2. 调用 Context `removeRegProvider` 移除一个 Plugin 注册器时也会释放注册器当时注册的模块
3. 当 Context 被释放时，它所管理的模块实例也会被释放
4. 当 super/sub 结构发生变化时

---

## 配置模块

有些模块需要外部配置才能正常工作。为了让调用方可以轻松配置模块，而不用担心模块实例是否已创建，Context 提供一个安全的接口进行所有模块的配置：`configPlugin`。Context 内部会暂存这次调用传进来的 model 实例，等模块实例创建时再进行真正的配置工作。

```swift
// 配置引擎模块
let engineConfig = PlayerEngineCoreConfigModel()
engineConfig.autoPlay = true
engineConfig.muted = false

// 方式1：使用 configPlugin（推荐，不依赖模块是否创建）
context.configPlugin(serviceProtocol: PlayerEngineCoreService.self, withModel: engineConfig)

// 方式2：直接调用服务的 config 方法（需要模块已创建）
context.resolveService(PlayerEngineCoreService.self).config(engineConfig)
```

---

## 小心服务发现失败 — 原来是模块实例还没创建

> **注意**
>
> 由于有许多灵活的创建时机，因此当 Plugin 内部具有相互依赖的服务时，需要注意依赖的模块是否已创建，尤其是在调用方模块自身初始化时。因此，框架会进行运行时断言检查：如果在 `pluginDidLoad` 中进行设置，不允许直接调用同一个 Context 下的服务。

### ServiceDidLoadEvent

`ServiceDidLoadEvent` 是框架原生支持的一种模块服务加载事件，当关注的服务加载成功时，会跟其他事件一样发布到所在的 Context 中。同时这也是一种 **StickyEvent**。

```swift
class PlayerAvatarPlugin: BasePlugin {
    override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 当 PlayerViewService 加载成功时，才会调用服务来绑定视图
        let eventName = "ServiceDidLoadEvent_PlayerViewService"
        context.add(self, event: eventName) { [weak self] object, event in
            guard let self = self else { return }
            let viewService = context.resolveService(PlayerViewService.self)
            viewService?.bindView { self.createAvatarView() }
        }
    }
}
```

---

## 快速上手

### 创建基础播放器

```swift
import PlayerKit

// 创建播放器
let player = Player()

// 配置引擎
let engineConfig = PlayerEngineCoreConfigModel()
engineConfig.autoPlay = true
player.context.configPlugin(serviceProtocol: PlayerEngineCoreService.self, withModel: engineConfig)

// 获取服务
let engineService = player.context.resolveService(PlayerEngineCoreService.self)

// 监听事件
player.context.add(self, event: .playerReadyToPlay) { _, _ in
    print("Ready to play")
}

// 设置数据并播放
engineService?.setAsset(url: videoURL)
```

### 创建场景播放器

```swift
import PlayerKit

// 创建场景播放器
let scenePlayer = ShowcaseFeedScenePlayer()

// 创建并添加播放器
let player = scenePlayer.createPlayer(prerenderKey: "video_123")
scenePlayer.addPlayer(player)

// 访问场景层服务
let dataService = scenePlayer.context.resolveService(ShowcaseFeedDataService.self)

// 监听场景层事件
scenePlayer.context.add(self, event: .showcaseFeedDataDidUpdate) { object, event in
    print("Feed data updated")
}

// 访问播放器
if let player = scenePlayer.player {
    player.engineService?.play()
}
```

---

## 文件结构

```
PlayerKit/
├── Sources/PlayerKit/
│   ├── Infra/                    # 核心架构实现
│   │   ├── Protocol.swift        # 核心协议定义
│   │   ├── Context.swift         # Context 实现
│   │   ├── BasePlugin.swift      # 插件基类
│   │   ├── EventHandler.swift    # 事件处理器
│   │   └── PlayerPluginMacro.swift # @PlayerPlugin 宏
│   ├── Core/                     # 播放器核心插件
│   │   ├── PlayerCoreService.swift  # 事件定义汇总
│   │   ├── Engine/               # 引擎模块
│   │   ├── Process/              # 播放流程
│   │   ├── Speed/                # 速度控制
│   │   ├── View/                 # 视图管理
│   │   └── Scene/                # 场景层基础设施
│   └── Player/                   # Player 主类
└── PlayerKitDemo/                # Demo 应用
    ├── Player/                   # 业务层封装
    │   └── Feed/                 # FeedPlayer 实现
    └── Demo/Showcase/            # Showcase 场景实现
```

---

## 核心设计原则

1. **单一职责**：每个 Plugin 只负责一个明确的功能
2. **依赖倒置**：模块间通过 Service 协议通信，而非具体实现
3. **开闭原则**：通过注册新的 Plugin 来扩展功能，无需修改现有代码
4. **层级分明**：两层架构确保职责清晰，上层依赖下层，下层不依赖上层
5. **事件驱动**：模块间通过事件进行松耦合通信

---

## 核心插件详解

### PlayerProcessPlugin — 播放进度管理插件

`PlayerProcessPlugin` 是**播放进度管理插件**，在引擎的时间数据之上封装了进度监听和 scrubbing（拖拽进度条）能力。

#### 核心职责

```
引擎层（原始时间数据）
    ↓ addPeriodicTimeObserver
PlayerProcessPlugin（进度百分比 + scrubbing 状态机）
    ↓ progressHandlers
上层 UI（进度条、时间标签、全屏播控等）
```

#### 两大功能

**1. 进度广播**

通过 `addPeriodicTimeObserver` 定时（默认 0.1s）从引擎拿当前时间，算出 `progress`（0~1），分发给所有订阅者：

```swift
observeProgress { progress, currentTime in
    // 更新进度条、时间标签等
}
```

**2. Scrubbing 状态机**

用户拖拽进度条时的三阶段协议：

```
beginScrubbing()      → 状态 = .scrubbing，广播事件
scrubbing(to: 0.75)   → 记录目标进度，广播当前拖拽位置
endScrubbing()        → seek 到目标位置，完成后状态 = .idle
```

这样其他插件（比如播控 UI）可以在 scrubbing 期间暂停进度更新、显示预览等。

#### 使用示例

```swift
// 监听进度更新
let token = processService.observeProgress { progress, currentTime in
    self.progressBar.setProgress(Float(progress), animated: false)
    self.timeLabel.text = formatTime(currentTime)
}

// 拖拽进度条
func sliderDidBeginDragging() {
    processService.beginScrubbing()
}

func sliderValueChanged(to value: Float) {
    processService.scrubbing(to: Double(value))
}

func sliderDidEndDragging() {
    processService.endScrubbing()
}

// 移除监听
processService.removeProgressObserver(token)
```

#### 常见问题与解决方案

**Q1: `removeProgressObserver` 删除全部而不是指定的**

```swift
// 问题代码
public func removeProgressObserver(_ observer: AnyObject?) {
    progressHandlers.removeAll()  // 全清了！
}
```

参数 `observer` 完全没用，一调就把所有订阅者都干掉了。正确做法是 `observeProgress` 返回一个 key/token，`removeProgressObserver` 按 key 移除：

```swift
public func observeProgress(_ handler: ...) -> String {
    let key = UUID().uuidString
    progressHandlers[key] = handler
    return key
}

public func removeProgressObserver(forKey key: String) {
    progressHandlers.removeValue(forKey: key)
}
```

**Q2: `pluginDidLoad` 时 `engineService` 可能还是 nil**

```swift
// 问题代码
public override func pluginDidLoad(_ context: ContextProtocol) {
    super.pluginDidLoad(context)
    timeObserver = engineService?.addPeriodicTimeObserver(...)  // engineService 可能是 nil
}
```

如果引擎插件还没加载完，`engineService` 是 nil，`timeObserver` 就是 nil，进度广播永远不会启动。应该用 sticky 事件：

```swift
public override func pluginDidLoad(_ context: ContextProtocol) {
    super.pluginDidLoad(context)

    context.add(self, event: .playerEngineDidCreateSticky, option: .execOnlyOnce) { [weak self] _, _ in
        self?.setupTimeObserver()
    }
}

private func setupTimeObserver() {
    timeObserver = engineService?.addPeriodicTimeObserver(...)
}
```

**Q3: scrubbing 期间没有暂停进度广播**

用户在拖进度条时，`progressHandlers` 还在按 0.1s 频率广播真实播放进度，会导致进度条在"用户拖拽位置"和"真实播放位置"之间跳动。应该在 scrubbing 时跳过广播：

```swift
// 在 timeObserver 回调里加判断
timeObserver = engineService?.addPeriodicTimeObserver(forInterval: CMTime(...)) { [weak self] time in
    guard let self = self else { return }
    guard !self.isScrubbing else { return }  // scrubbing 时跳过

    self.notifyProgress(time)
}
```

**Q4: `seek(to:)` 接受的是 progress（0~1）而不是时间**

方法签名是 `seek(to progress: Double)`，内部转换成时间再调引擎。这没问题，但容易和引擎的 `seek(to time:)` 混淆。建议改名为 `seekToProgress(_:)` 更清晰。

#### 总结

这是一个标准的进度管理中间层，核心价值是把引擎的"绝对时间"转换成"百分比进度"+ 提供 scrubbing 状态机。主要问题是 `removeProgressObserver` 的全清 bug 和 `pluginDidLoad` 时引擎可能未就绪。

---

## 常见问题

### Q: 为什么在 pluginDidLoad 中调用其他服务会失败？

A: 因为其他服务可能还未创建。请使用 `ServiceDidLoadEvent` 等待依赖服务加载完成后再调用。

### Q: 如何在多个 Context 之间共享状态？

A: 使用 `SharedContext` 机制，将需要共享的状态放在 SharedPlugin 中。

### Q: 如何实现跨层通信？

A: 上层可以直接访问下层的服务和监听下层的事件。下层可以通过事件向上层传递信息。

### Q: Plugin 的创建时机如何选择？

A:
- `whenRegistered`: 模块需要立即初始化
- `whenFirstConfig`: 模块需要配置才能工作
- `whenFirstResolve`: 模块可能不会被使用，延迟创建节省资源
- `whenPostEvent`: 模块只在特定场景下需要
