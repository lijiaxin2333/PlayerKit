import UIKit

public let PlayerKitVersionString = "1.0.0"

// MARK: - CCL

@_exported import struct PlayerKit.CCLEvent
@_exported import struct PlayerKit.CCLEventOption
@_exported import class PlayerKit.CCLContext
@_exported import class PlayerKit.CCLBaseComp
@_exported import class PlayerKit.Player

// MARK: - CCL Protocols

@_exported import protocol PlayerKit.CCLContextProtocol
@_exported import protocol PlayerKit.CCLPublicContext
@_exported import protocol PlayerKit.CCLCompProtocol
@_exported import protocol PlayerKit.CCLCompService

// MARK: - Engine

@_exported import protocol PlayerKit.PlayerEngineCoreService
@_exported import class PlayerKit.PlayerEngineCoreComp
@_exported import class PlayerKit.PlayerEngineCoreConfigModel

// MARK: - PlaybackControl

@_exported import protocol PlayerKit.PlayerPlaybackControlService
@_exported import class PlayerKit.PlayerPlaybackControlComp

// MARK: - Pool

@_exported import protocol PlayerKit.PlayerEnginePoolService
@_exported import class PlayerKit.PlayerEnginePoolComp
@_exported import class PlayerKit.PlayerEnginePoolConfig

// MARK: - Scene

@_exported import protocol PlayerKit.PlayerSceneProtocol
@_exported import protocol PlayerKit.PlayerSceneManagerService
@_exported import class PlayerKit.PlayerSceneManagerComp

// MARK: - SceneTransfer

@_exported import protocol PlayerKit.PlayerSceneTransferService
@_exported import class PlayerKit.PlayerSceneTransferComp

// MARK: - States

@_exported import enum PlayerKit.PlayerPlaybackState
@_exported import enum PlayerKit.PlayerLoadState
