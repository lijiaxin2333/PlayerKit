//
//  PlayerConfiguration.swift
//  PlayerKit
//
//  播放器配置类
//

import Foundation

/// 播放器配置
public class PlayerConfiguration: NSObject {

    /// 是否为预渲染创建的播放器
    public var createForPreRender: Bool = false

    /// 要屏蔽的模块注册信息ID，一般为服务名
    public var compBlackList: Set<String> = []

    /// 预渲染key
    public var prerenderKey: String?

    public override init() {
        super.init()
    }
}
