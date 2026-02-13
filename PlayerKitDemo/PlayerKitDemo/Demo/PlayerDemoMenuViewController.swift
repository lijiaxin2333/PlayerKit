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
    }

    private struct DemoItem {
        let title: String
        let subtitle: String
        let action: DemoAction
    }

    private let demoItems: [DemoItem] = [
        DemoItem(title: "综合演示", subtitle: "35个Comp全能力展示", action: .showcase),
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

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
        }

        viewController.title = demoItems.first { $0.action == action }?.title
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension PlayerDemoMenuViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return demoItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let item = demoItems[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

// MARK: - UITableViewDelegate

extension PlayerDemoMenuViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = demoItems[indexPath.row]
        showDemo(item.action)
    }
}
