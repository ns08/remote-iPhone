import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var loginId = UserDefaults.standard.string(forKey: "iphone_bg_id") ?? ""
    @State private var password = UserDefaults.standard.string(forKey: "iphone_bg_pw") ?? ""
    @State private var connectKey = UserDefaults.standard.string(forKey: "iphone_bg_key") ?? ""
    @State private var secretAnswer = UserDefaults.standard.string(forKey: "iphone_bg_ans") ?? ""
    @State private var statusMessage = "状態: バックグラウンド待機中"

    var body: some View {
        NavigationView {
            Form {
                Text("接続キー: \(connectKey.isEmpty ? "未設定" : connectKey)").bold()
                TextField("アカウントID", text: $loginId)
                SecureField("パスワード (PW)", text: $password)
                TextField("接続キー", text: $connectKey)
                TextField("秘密の質問の答え", text: $secretAnswer)
                Button("接続して常時稼働") {
                    BackgroundEngine.shared.authenticateNow(lid: loginId, pw: password, ck: connectKey, sa: secretAnswer) { msg in
                        statusMessage = msg
                    }
                }
                Text(statusMessage)
            }
            .navigationBarTitle("iPhone Background Target")
            .onAppear {
                BackgroundEngine.shared.startAlwaysRunning()
            }
            .onChange(of: scenePhase) { _ in
                BackgroundEngine.shared.startAlwaysRunning()
            }
        }
    }
}
