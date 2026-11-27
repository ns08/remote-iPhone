import Foundation

final class BackgroundEngine: ObservableObject {
    static let shared = BackgroundEngine()
    private let authURL = "https://ss752723.stars.ne.jp/remote_auth/auth_api.php"
    private let relayURL = "https://ss752723.stars.ne.jp/remote_auth/relay_api.php"
    private var timer: Timer?
    private var lastId = 0

    func startAlwaysRunning() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func authenticateNow(lid: String, pw: String, ck: String, sa: String, done: ((String) -> Void)? = nil) {
        guard let url = URL(string: authURL) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "action": "login_local_connect",
            "login_id": lid,
            "password": pw,
            "connect_key": ck,
            "secret_answer": sa,
            "role": "target"
        ])
        URLSession.shared.dataTask(with: req) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data,
                      let res = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      (res["ok"] as? Bool) == true,
                      let ch = res["channel_id"] as? String,
                      let tok = res["session_token"] as? String else {
                    done?("状態: 再接続待機中")
                    return
                }
                let d = UserDefaults.standard
                d.set(true, forKey: "iphone_bg_once")
                d.set(lid, forKey: "iphone_bg_id")
                d.set(pw, forKey: "iphone_bg_pw")
                d.set(ck, forKey: "iphone_bg_key")
                d.set(sa, forKey: "iphone_bg_ans")
                d.set(ch, forKey: "iphone_bg_ch")
                d.set(tok, forKey: "iphone_bg_tok")
                let port = (res["assigned_port"] as? Int) ?? 24001
                done?("状態: バックグラウンド常時接続中 (Port=\(port))")
            }
        }.resume()
    }

    private func tick() {
        let d = UserDefaults.standard
        let ch = d.string(forKey: "iphone_bg_ch") ?? ""
        let tok = d.string(forKey: "iphone_bg_tok") ?? ""
        if ch.isEmpty || tok.isEmpty {
            if d.bool(forKey: "iphone_bg_once") {
                authenticateNow(
                    lid: d.string(forKey: "iphone_bg_id") ?? "",
                    pw: d.string(forKey: "iphone_bg_pw") ?? "",
                    ck: d.string(forKey: "iphone_bg_key") ?? "",
                    sa: d.string(forKey: "iphone_bg_ans") ?? ""
                )
            }
            return
        }
        guard let url = URL(string: relayURL) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "action": "poll",
            "role": "target",
            "channel_id": ch,
            "session_token": tok,
            "after_id": lastId
        ])
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let res = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  (res["ok"] as? Bool) == true else { return }
            if let next = res["after_id"] as? Int {
                self.lastId = next
            }
        }.resume()
    }
}
