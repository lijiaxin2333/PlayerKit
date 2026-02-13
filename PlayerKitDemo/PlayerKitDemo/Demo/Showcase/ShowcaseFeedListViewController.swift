import UIKit
import AVFoundation
import IGListKit
import PlayerKit
import ListKit

@MainActor
final class ShowcaseFeedListViewController: BaseListViewController<ShowcaseFeedListViewModel> {

    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private var playbackPlugin: ShowcaseFeedPlaybackPlugin?

    private var showcaseViewModel: ShowcaseFeedListViewModel {
        viewModel
    }

    init() {
        let vm = ShowcaseFeedListViewModel()
        super.init(viewModel: vm)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Showcase"

        let plugin = ShowcaseFeedPlaybackPlugin()
        self.playbackPlugin = plugin
        viewModel.registerBusinessPlugin(plugin)
        setupLoadingIndicator()
        setupPaging()
        bindShowcaseViewModel()
        showcaseViewModel.fetchListData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if isMovingFromParent || isBeingDismissed {
            cleanupOnExit()
        }
    }

    private func cleanupOnExit() {
        if let cv = baseCollectionView {
            for cell in cv.visibleCells {
                if let feedCell = cell as? ShowcaseFeedCell {
                    feedCell.detachPlayer()
                }
            }
        }
        playbackPlugin?.cleanup()
        playbackPlugin = nil
        showcaseViewModel.onDataLoaded = nil
        showcaseViewModel.onLoadError = nil
        viewModel.removeAllBusinessPlugins()
        viewModel.sectionViewModelsArray.removeAll()
        ShowcaseDataSource.shared.reset()
        PLog.clearCellVisibleCache()
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Override

    override func layoutForCollectionView() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }

    override func setupCollectionView(_ collectionView: UICollectionView) {
        collectionView.backgroundColor = .black
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
    }

    // MARK: - DataSource Override

    override func dataSourceDidCreateSectionController(_ sectionController: BaseListSectionController, forSectionViewModel sectionViewModel: BaseListSectionViewModel) {
        sectionController.containerConfig = self
    }

    // MARK: - Setup

    private func setupLoadingIndicator() {
        loadingIndicator.color = .white
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        loadingIndicator.startAnimating()
    }

    private func setupPaging() {
        scrollViewDelegate = self
        baseCollectionView?.isPagingEnabled = true
    }

    private func bindShowcaseViewModel() {
        showcaseViewModel.onDataLoaded = { [weak self] _ in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.isHidden = true
        }
        showcaseViewModel.onLoadError = { [weak self] in
            self?.loadingIndicator.stopAnimating()
            self?.loadingIndicator.isHidden = true
            self?.showErrorRetry()
        }
    }

    // MARK: - Error

    private func showErrorRetry() {
        let label = UILabel()
        label.text = "Failed to load feed.\nTap to retry."
        label.textColor = .white.withAlphaComponent(0.7)
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.tag = 8888
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(retryFetch))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
    }

    @objc private func retryFetch() {
        view.viewWithTag(8888)?.removeFromSuperview()
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        showcaseViewModel.fetchListData()
    }
}
