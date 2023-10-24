# Check1Drive

OneDrive for Buisiness の残り容量・最大容量を取得するPowershellスクリプトです。  
残り容量が少ない際のメール通知機能も備えています。

## 開発環境
* Powershell 5.1.19041.3570

## 使い方

1. Microsoft Azur https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade にてアプリを登録します。
2. 1で登録したアプリで以下の項目を登録します。
    * クライアントシークレット
    * リダイレクトURI（実在しないアドレスでも動作します）
    * 認証->暗黙的な許可およびハイブリッド フロー->IDトークンをチェック状態とします
3. 以下の項目を控えておきます。（後の操作で使用します）
    * テナントID
    * クライアントID
    * クライアントシークレット
    * リダイレクトURI
4. 本フォルダを任意のフォルダにコピーします。
5. 設定ファイルを作成します。付属の`config.example.json`ファイルをコピーし（ファイル名は`config.json`とします）、実行環境に合わせて内容を編集します。
6. この時点でスクリプトが実行できる状態となります。コマンド例は次の項の通りです。
7. 始めて実行する際はMicrosoftアカウントのログインページが起動します。（Webブラウザ画面が起動します）。  
ここでは、容量を確認したいOneDriveアカウントでログインしてください。  
以後、クライアントシークレットの期限が切れるまでは再認証は不要だと思います（未確認）

## コマンド例

``` powershell
$ ./Check1Drive.ps1 -User someuser@some_tenant.onmicrosoft.com

# メール送信を行わない場合
$ ./Check1Drive.ps1 -User someuser@some_tenant.onmicrosoft.com -EnableNotification $false
```

### !!!注意!!!

本スクリプトは以下2点の問題を抱えています。ご理解の上で利用ください。

1. アカウントの切替えができない
    * ver0.0.1時点では、認証情報をクリアする方法が無いため、認証後はユーザを切り替える事ができません。  
    複数アカウントで利用したい場合は、OSのユーザを切り替えるか、実行端末を変える必要があります。
    * Microsoft.Forms.WebBrowserのセッション情報をクリアできれば解決できるかもしれません。
2. トークン更新が未実装（長期運用で期限切れになるかも）
    * 開発段階でトークンが期限切れにならず、トークンを更新する手続きを実装できていません...。  
    そのため、長期の使用でトークンが期限切れになるかもしれません。

## 参考情報

* Microsoft Graph 用のアプリの登録
    * https://learn.microsoft.com/ja-jp/onedrive/developer/rest-api/getting-started/app-registration?view=odsp-graph-online
* PowerShellGallery-OneDrive （認証操作の手続きはこちらのソースを参考にしました）
    * https://github.com/MarcelMeurer/PowerShellGallery-OneDrive

## ライセンス

Check1Drive は[MIT license](LICENSE)で利用できるものとします。

本プログラムは自己責任の元利用ください。もし何らかの損害が発生することがあっても、制作者は一切の責任を負いません。
