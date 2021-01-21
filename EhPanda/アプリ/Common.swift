//
//  Common.swift
//  EhPanda
//
//  Created by 荒木辰造 on R 2/11/22.
//

import SwiftUI
import Combine
import Kingfisher

class Common {
    
}


public func ePrint(_ error: Error) {
    print("debugMark " + error.localizedDescription)
}

public func ePrint(_ string: String) {
    print("debugMark " + string)
}

public func ePrint(_ string: String?) {
    print("debugMark " + (string ?? "エラーの内容が解析できませんでした"))
}

public var didLogin: Bool {
    verifyCookies(url: URL(string: Defaults.URL.ehentai)!, isEx: false)
}
public var exAccess: Bool {
    verifyCookies(url: URL(string: Defaults.URL.exhentai)!, isEx: true)
}

public var appVersion: String {
    Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as? String ?? "(null)"
}
public var appBuild: String {
    Bundle.main.object(
        forInfoDictionaryKey: "CFBundleVersion"
    ) as? String ?? "(null)"
}

public func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: style)
        .impactOccurred()
}

public var exx: Bool {
    UserDefaults.standard.string(forKey: "entry") == "Rra3MKpjKBJLgraHqt9t"
}

public var isPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

public var galleryType: GalleryType {
    let rawValue = UserDefaults
        .standard
        .string(forKey: "GalleryType")
        ?? "E-Hentai"
    return GalleryType(rawValue: rawValue)!
}

public var vcsCount: Int {
    guard let navigationVC = UIApplication
            .shared.windows.first?
            .rootViewController?
            .children.first
            as? UINavigationController
    else { return -1 }
    
    return navigationVC.viewControllers.count
}

// MARK: 容量管理
public func readableUnit(bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useAll]
    return formatter.string(fromByteCount: bytes)
}

public func browsingCaches() -> String {
    guard let fileURL = FileManager
            .default
            .urls(
                for: .cachesDirectory,
                in: .userDomainMask
            )
            .first?
            .appendingPathComponent(
                "cachedList.json"
            ),
          let data = try? Data(
            contentsOf: fileURL
          )
    else { return "0 KB" }
    
    return readableUnit(bytes: Int64(data.count))
}

public func clearCookies() {
    if let historyCookies = HTTPCookieStorage.shared.cookies {
        historyCookies.forEach {
            HTTPCookieStorage.shared.deleteCookie($0)
        }
    }
}

// MARK: スレッド
public func executeMainAsync(_ closure: @escaping (()->())) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async {
            closure()
        }
    }
}

public func executeMainAsync(_ delay: Double, _ closure: @escaping (()->())) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        closure()
    }
}

public func executeAsync(_ closure: @escaping (()->())) {
    DispatchQueue.global().async {
        closure()
    }
}

public func executeSync(_ closure: @escaping (()->())) {
    DispatchQueue.global().sync {
        closure()
    }
}

// MARK: クッキー
public func initiateCookieFrom(_ cookie: HTTPCookie, value: String) -> HTTPCookie {
    var properties = cookie.properties
    properties?[.value] = value
    return HTTPCookie(properties: properties ?? [:]) ?? HTTPCookie()
}

public func checkExistence(url: URL, key: String) -> Bool {
    if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
        var existence: HTTPCookie?
        cookies.forEach { cookie in
            if cookie.name == key {
                existence = cookie
            }
        }
        return existence != nil
    } else {
        return false
    }
}

public func setCookie(url: URL, key: String, value: String) {
    let expiredDate = Date(
        timeIntervalSinceNow:
            TimeInterval(60 * 60 * 24 * 365)
    )
    let cookie = HTTPCookie(
        properties: [
            .name: key,
            .value: value,
            .originURL: url,
            .expires: expiredDate
        ])
    HTTPCookieStorage.shared.setCookie(cookie ?? HTTPCookie())
}

public func removeCookie(url: URL, key: String) {
    if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
        cookies.forEach { cookie in
            if cookie.name == key {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
}

public func editCookie(url: URL, key: String, value: String) {
    var newCookie: HTTPCookie?
    if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
        cookies.forEach { cookie in
            if cookie.name == key
            {
                newCookie = initiateCookieFrom(cookie, value: value)
                removeCookie(url: url, key: key)
            }
        }
    }
    
    guard let cookie = newCookie else { return }
    HTTPCookieStorage.shared.setCookie(cookie)
}

public func getCookieValue(url: URL, key: String) -> CookieValue {
    var value = CookieValue(
        rawValue: "",
        lString: Defaults.Cookie.null.lString()
    )
    
    guard let cookies =
            HTTPCookieStorage
            .shared
            .cookies(for: url),
          !cookies.isEmpty
    else { return value }
    
    let date = Date()
    
    cookies.forEach { cookie in
        guard let expiresDate = cookie.expiresDate
        else { return }
        
        if cookie.name == key
            && !cookie.value.isEmpty
        {
            if expiresDate > date {
                if cookie.value == Defaults.Cookie.mystery {
                    value = CookieValue(
                        rawValue: cookie.value,
                        lString: Defaults.Cookie.mystery.lString()
                    )
                } else {
                    value = CookieValue(
                        rawValue: cookie.value,
                        lString: ""
                    )
                }
            } else {
                value = CookieValue(
                    rawValue: "",
                    lString: Defaults.Cookie.expired.lString()
                )
            }
        }
    }
    
    return value
}

func verifyCookies(url: URL, isEx: Bool) -> Bool {
    guard let cookies =
            HTTPCookieStorage
            .shared
            .cookies(for: url),
          !cookies.isEmpty
    else { return false }
    
    let date = Date()
    var igneous: String?
    var memberID: String?
    var passHash: String?
    
    cookies.forEach { cookie in
        guard let expiresDate = cookie.expiresDate
        else { return }
                
        if cookie.name == Defaults.Cookie.igneous
            && !cookie.value.isEmpty
            && cookie.value != Defaults.Cookie.mystery
            && expiresDate > date
        {
            igneous = cookie.value
        }
        
        if cookie.name == Defaults.Cookie.ipb_member_id
            && !cookie.value.isEmpty
            && expiresDate > date
        {
            memberID = cookie.value
        }
        
        if cookie.name == Defaults.Cookie.ipb_pass_hash
            && !cookie.value.isEmpty
            && expiresDate > date
        {
            passHash = cookie.value
        }
    }
    
    if isEx {
        return igneous != nil && memberID != nil && passHash != nil
    } else {
        return memberID != nil && passHash != nil
    }
}

// MARK: 画像処理
struct KFImageModifier: ImageModifier {
    let targetScale: CGFloat
    
    func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage {
        let originW = image.size.width
        let originH = image.size.height
        let scale = originW / originH
        
        let targetW = originW * targetScale
        
        if abs(targetScale - scale) <= 0.2 {
            return image
                .kf
                .resize(
                    to: CGSize(
                        width: targetW,
                        height: originH
                    ),
                    for: .aspectFill
                )
        } else {
            return image
        }
    }
}
