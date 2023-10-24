function Send-Mail {
    PARAM(
        <#
        .DESCRIPTION
        メールを送信します
        .PARAMETER Subject
        メールのタイトル.
        .PARAMETER Body
        メール本文
        .PARAMETER ToAddresses
        送信先アドレスの配列
        .PARAMETER Settings
        メールサーバ等の設定。以下のようなオブジェクトを期待します。
        {
            "from_address": "送信元ールアドレス",    
            "smtp_address":"SMTPサーバのアドレス",
            "port": SMTPサーバのポート番号,
            "enable_ssl": SSL使用,
            "user":"メールサーバのユーザID",
            "password" : "メールサーバのパスワード"
        }
        #>

		[Parameter(Mandatory=$True)]
        [string] $Subject,
        [string] $Body,
        [string[]] $ToAddresses,
		[object] $Settings
	)

    # 送信メールサーバーの設定
    $client=New-Object Net.Mail.SmtpClient($Settings.smtp_address,$Settings.port)
    $client.EnableSsl = $Settings.enable_ssl
    $client.DeliveryMethod = [System.Net.Mail.SmtpDeliveryMethod]::Network
    $client.Credentials = New-Object Net.NetworkCredential($Settings.user,$Settings.password)
    write-verbose "メールを送信します..."

    $to = $ToAddresses -join ";"
    $message = New-Object Net.Mail.MailMessage($Settings.from_address,$to,$Subject,$Body)
    $client.Send($message)
    $message.Dispose()
    $client.Dispose()
}
