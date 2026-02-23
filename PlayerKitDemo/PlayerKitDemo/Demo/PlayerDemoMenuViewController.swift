//
//  PlayerDemoMenuViewController.swift
//  playerkit
//
//  播放器功能演示主菜单
//

import UIKit

/// 播放器功能演示主菜单
@MainActor
public class PlayerDemoMenuViewController: UIViewController {

    // MARK: - Properties

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Demo Items

    private enum DemoAction {
        case showcase
        case speed
        case looping
        case gesture
        case snapshot
        case subtitle
        case zoom
        case startTime
    }

    private struct DemoItem {
        let title: String
        let subtitle: String
        let action: DemoAction
    }

    private struct DemoSection {
        let title: String
        let items: [DemoItem]
    }

    private let demoSections: [DemoSection] = [
        DemoSection(title: "综合场景", items: [
            DemoItem(title: "综合演示", subtitle: "35个Comp全能力展示", action: .showcase),
        ]),
        DemoSection(title: "插件功能演示", items: [
            DemoItem(title: "倍速播放", subtitle: "PlayerSpeedPlugin · PlayerSpeedPanelPlugin", action: .speed),
            DemoItem(title: "循环播放", subtitle: "PlayerLoopingPlugin · PlayerFinishViewPlugin", action: .looping),
            DemoItem(title: "手势交互", subtitle: "PlayerGesturePlugin · 单击/双击/滑动/长按/捏合", action: .gesture),
            DemoItem(title: "视频截图", subtitle: "PlayerSnapshotPlugin · 同步/异步截帧/缩略图", action: .snapshot),
            DemoItem(title: "字幕", subtitle: "PlayerSubtitlePlugin · 加载/切换/样式调整", action: .subtitle),
            DemoItem(title: "缩放与满屏", subtitle: "PlayerZoomPlugin · PlayerFullScreenPlugin", action: .zoom),
            DemoItem(title: "起播与进度", subtitle: "PlayerStartTimePlugin · PlayerProcessPlugin · PlayerTimeControlPlugin", action: .startTime),
        ]),
    ]

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "PlayerKit Demo"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        setupTableView()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SubtitleCell.self, forCellReuseIdentifier: "Cell")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Navigation

    private func showDemo(_ action: DemoAction) {
        let viewController: UIViewController

        switch action {
        case .showcase:
            viewController = ShowcaseFeedListViewController()
        case .speed:
            viewController = SpeedDemoViewController()
        case .looping:
            viewController = LoopingDemoViewController()
        case .gesture:
            viewController = GestureDemoViewController()
        case .snapshot:
            viewController = SnapshotDemoViewController()
        case .subtitle:
            viewController = SubtitleDemoViewController()
        case .zoom:
            viewController = ZoomDemoViewController()
        case .startTime:
            viewController = StartTimeDemoViewController()
        }

        for section in demoSections {
            if let item = section.items.first(where: { $0.action == action }) {
                viewController.title = item.title
                break
            }
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

private final class SubtitleCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - UITableViewDataSource

extension PlayerDemoMenuViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return demoSections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return demoSections[section].items.count
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return demoSections[section].title
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let item = demoSections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

// MARK: - UITableViewDelegate

extension PlayerDemoMenuViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = demoSections[indexPath.section].items[indexPath.row]
        showDemo(item.action)
    }
}
