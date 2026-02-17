import Foundation
import UIKit

struct ShowcaseVideo {
    let feedId: String
    let creatorId: String
    let title: String
    let desc: String
    let url: URL?
    let coverURL: URL?
    let thumbnailCoverURL: URL?
    let duration: TimeInterval
    let width: Int
    let height: Int
    let subtitleURL: URL?
    let creator: ShowcaseCreator

    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    var playCount: Int
    var isLiked: Bool
}

struct ShowcaseCreator {
    let userId: String
    let nickname: String
    let avatarURL: URL?
}

/// SectionViewModel 工厂模式的数据包装类型
struct ShowcaseFeedSectionData {
    let video: ShowcaseVideo
    let index: Int
}

final class ShowcaseDataSource: @unchecked Sendable {

    static let shared = ShowcaseDataSource()

    private static let baseURL = "https://efa-test.liblib.art"
    private static let guestLoginPath = "/api/app/v1/user/login/guest"
    private static let feedPath = "/api/app/v1/feed/recommend/list"
    private static let deviceId = "8CD8FB57-C5A0-4740-A0EC-356C34578233"

    private static let hardcodedUserId = "17724881673477143"
    private static let hardcodedToken = "0ne33834d51c9046138e3117ad1bfed1dd"

    private let lock = NSLock()
    private var _videos: [ShowcaseVideo] = []
    private var _isLoading = false
    private var _hasMore = true
    private var _token: String?
    private var _userId: String?
    private var _cursor: String = ""
    private var _pageNo: Int = 1
    private let _pageSize: Int = 10
    private var _feedIdSet = Set<String>()

    var videos: [ShowcaseVideo] {
        lock.lock(); defer { lock.unlock() }
        return _videos
    }
    var isLoading: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isLoading
    }
    var hasMore: Bool {
        lock.lock(); defer { lock.unlock() }
        return _hasMore
    }

    func fetchFeed(completion: @escaping @Sendable ([ShowcaseVideo], Bool) -> Void) {
        lock.lock()
        guard !_isLoading else { lock.unlock(); return }
        _isLoading = true
        if _token == nil {
            _token = Self.hardcodedToken
            _userId = Self.hardcodedUserId
        }
        lock.unlock()
        requestFeed(completion: completion)
    }

    func loadMore(completion: @escaping @Sendable ([ShowcaseVideo], Bool) -> Void) {
        lock.lock()
        guard !_isLoading, _hasMore else { lock.unlock(); return }
        _isLoading = true
        lock.unlock()
        requestFeed(completion: completion)
    }

    func reset() {
        lock.lock()
        _videos = []
        _cursor = ""
        _pageNo = 1
        _hasMore = true
        _feedIdSet = []
        lock.unlock()
    }

    private func guestLogin(completion: @escaping @Sendable (Bool) -> Void) {
        guard let url = URL(string: Self.baseURL + Self.guestLoginPath) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("iOS", forHTTPHeaderField: "X-Client-Type")
        request.setValue(Self.deviceId, forHTTPHeaderField: "X-Client-Device-Id")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self,
                  let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["code"] as? Int, code == 0,
                  let dataObj = json["data"] as? [String: Any],
                  let token = dataObj["token"] as? String,
                  let userId = dataObj["userId"] as? String else {
                completion(false)
                return
            }
            self.lock.lock()
            self._token = token
            self._userId = userId
            self.lock.unlock()
            completion(true)
        }.resume()
    }

    private func requestFeed(completion: @escaping @Sendable ([ShowcaseVideo], Bool) -> Void) {
        lock.lock()
        let token = _token
        let userId = _userId
        let pageNo = _pageNo
        let cursor = _cursor
        lock.unlock()

        guard let url = URL(string: Self.baseURL + Self.feedPath),
              let token = token, let userId = userId else {
            lock.lock()
            _isLoading = false
            lock.unlock()
            DispatchQueue.main.async { completion([], false) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("iOS", forHTTPHeaderField: "X-Client-Type")
        request.setValue(Self.deviceId, forHTTPHeaderField: "X-Client-Device-Id")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        request.setValue(token, forHTTPHeaderField: "X-Token")
        request.setValue("1.1.6.1", forHTTPHeaderField: "X-Build-Version")
        request.setValue("Debug", forHTTPHeaderField: "X-iOS-Channel")
        request.setValue("1.1.6", forHTTPHeaderField: "X-Client-Version")

        let body: [String: Any] = [
            "scene": "StoryPage",
            "pageNo": pageNo,
            "pageSize": _pageSize,
            "cursor": cursor,
            "userFeature": [
                "labelIds": [] as [String],
                "isOnboardUser": false
            ] as [String: Any]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                self?.lock.lock()
                self?._isLoading = false
                self?.lock.unlock()
                DispatchQueue.main.async { completion([], false) }
                return
            }
            let (parsed, newCursor, more) = Self.parseFeedResponse(data)

            self.lock.lock()
            let unique = parsed.filter { self._feedIdSet.insert($0.feedId).inserted }
            self._cursor = newCursor
            self._hasMore = more
            if more { self._pageNo += 1 }
            self._videos.append(contentsOf: unique)
            self._isLoading = false
            self.lock.unlock()

            DispatchQueue.main.async {
                completion(unique, more)
            }
        }.resume()
    }

    private static func parseFeedResponse(_ data: Data) -> ([ShowcaseVideo], String, Bool) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["code"] as? Int, code == 0,
              let dataObj = json["data"] as? [String: Any],
              let list = dataObj["list"] as? [[String: Any]] else {
            return ([], "", false)
        }

        let cursor = dataObj["cursor"] as? String ?? ""
        let hasMore = dataObj["hasMore"] as? Bool ?? false

        let videos = list.compactMap { item -> ShowcaseVideo? in
            guard let feedId = item["feedId"] as? String,
                  let content = item["content"] as? [String: Any],
                  let videoURLStr = content["url"] as? String,
                  let videoURL = URL(string: videoURLStr) else {
                return nil
            }

            let creatorId = item["creatorId"] as? String ?? ""
            let title = item["title"] as? String ?? ""
            let desc = item["desc"] as? String ?? ""
            let coverStr = content["cover"] as? String
            let thumbnailStr = content["thumbnailCover"] as? String
            let duration = content["duration"] as? Int ?? 0
            let w = content["w"] as? Int ?? 0
            let h = content["h"] as? Int ?? 0

            let creatorDict = item["creator"] as? [String: Any]
            let userId = creatorDict?["userId"] as? String ?? creatorId
            let nickname = creatorDict?["nickname"] as? String ?? ""
            let avatarStr = creatorDict?["avatar"] as? String

            let likeDict = item["like"] as? [String: Any]
            let belikeCount = likeDict?["belikeCount"] as? Int ?? 0
            let likeStatus = likeDict?["likeStatus"] as? Int ?? 0

            let commentDict = item["comment"] as? [String: Any]
            let commentCount = commentDict?["commentCount"] as? Int ?? 0

            let counterDict = item["counter"] as? [String: Any]
            let shareCount = counterDict?["shareCount"] as? Int ?? 0
            let playCount = counterDict?["playCount"] as? Int ?? 0

            return ShowcaseVideo(
                feedId: feedId,
                creatorId: creatorId,
                title: title,
                desc: desc,
                url: videoURL,
                coverURL: coverStr.flatMap { URL(string: $0) },
                thumbnailCoverURL: thumbnailStr.flatMap { URL(string: $0) },
                duration: TimeInterval(duration),
                width: w,
                height: h,
                subtitleURL: nil,
                creator: ShowcaseCreator(
                    userId: userId,
                    nickname: nickname,
                    avatarURL: avatarStr.flatMap { URL(string: $0) }
                ),
                likeCount: belikeCount,
                commentCount: commentCount,
                shareCount: shareCount,
                playCount: playCount,
                isLiked: likeStatus == 1
            )
        }

        return (videos, cursor, hasMore)
    }
}
