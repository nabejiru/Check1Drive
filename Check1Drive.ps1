<#
.SYNOPSIS
  OneDrive for Buisiness のドライブ残り残量を確認します。
  残量がしきい値以下の場合はメールを送信します。
.DESCRIPTION
  Microsoft GraphのAPIを使用してOneDriveの残り容量を確認します。
  あらかじめAzureのサイトにてアプリ登録が必要です。詳細は関連リンクを参照ください。

  また、初回実行時はMicrosoftアカウントのパスワード認証を求められます。（Webブラウザが起動します）
  ここでは、確認したいドライブのオーナーでログインしてください。
.PARAMETER ConfigFile
  設定ファイルのパス。デフォルトは"./config.json"です。
.PARAMETER EnableNotification
  残量警告メールの送信有無を指定します。デフォルトはtrueです。
.NOTES  
  [注意点] 
  一度認証するとアカウントを切り替える事ができません。（2023/10/24時点）
  他のアカウントの容量を確認する場合は、OSのユーザを切り替えるか実行端末を変える必要があります。
.LINK
Microsoft Graph 用のアプリの登録
https://learn.microsoft.com/ja-jp/onedrive/developer/rest-api/getting-started/app-registration?view=odsp-graph-online

#>
PARAM(
    [string]$ConfigFile = "./config.json",
    [switch]$EnableNotification = $true
)
. "$($PSScriptRoot)\lib\OneDrive.ps1"
. "$($PSScriptRoot)\lib\Notification.ps1"

$settings = Get-Content $ConfigFile | ConvertFrom-Json

function floor
{
    <#
	.DESCRIPTION
	小数点以下を切り捨てます
	.PARAMETER Value
    切り捨てをする数値
	.PARAMETER Digits
    切り捨て後に残す小数点以下の桁数
    #>
    PARAM(
        [double]$Value,
        [int]$Digits
    )
    $d = [Math]::Pow(10, $Digits)
    return [Math]::Floor($Value * $d) / $d
}

function toGiga
{
    <#
	.DESCRIPTION
	数値をギガバイト単位にします
	.PARAMETER Value
    切り捨てをする数値
    #>
    PARAM(
		[long]$value
	)
    $giga = $value / 1024 / 1024 / 1024
    $giga = floor -value $giga -digits 2
    return $giga
}


$scope = "Files.Read.All offline_access"
    
#認証
write-information("コード認証を行います...")

# TSL1.2通信を許可する（WindowsServer系でInvalidOperationが発生する対策）
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$auth = ODAuthentication -ClientID $settings.client_id -AppKey $settings.secret -RedirectURI $settings.redirect_url -TenantId $settings.tenant_id -Scope $scope
write-verbose($auth)

if($auth.error -ne $null) {
    write-warning("認証に失敗したため、処理を中止します error=${$auth.error}")
    return 
}

# ドライブ情報の取得
write-verbose("ドライブ情報を取得しています...")
$drive = Get-Drive -AccessToken $auth.access_token 
write-verbose($drive)

$ret=ODAuthentication -ClientID $settings.client_id -AppKey $settings.secret -RedirectURI $settings.redirect_url -TenantId $settings.tenant_id -LogOut $true
if ($drive.quota -eq $null) {
    write-warning("ドライブ情報を取得できません")
    return
}

# 容量を出力する
$percent = floor -Value ($drive.quota.remaining / $drive.quota.total * 100) -digits 2
$remainGiga = toGiga -value $drive.quota.remaining
$totalGiga = toGiga -value $drive.quota.total

write-host("owner     : $($drive.owner.user.email)")
write-host("deleted   : $($drive.quota.deleted)")
write-host("used      : $($drive.quota.used)")
write-host("remaining : $($drive.quota.remaining) ($percent%)")
write-host("total     : $($drive.quota.total)")

write-verbose("しきい値=$($settings.threthold_percent)%")

# 容量が少ない場合はメール通知する
if (($EnableNotification) -And ($percent -le $settings.threthold_percent)) {
    $subject="[OneDrive]容量警告"
    $body= @"
OneDriveの残り容量が$($settings.threthold_percent)%以下になりました。

# アカウント: $($drive.owner.user.email)
# 総容量=${totalGiga}GB  残り=${remainGiga}GB（$percent%）
"@

    write-warning("容量が残り$($settings.threthold_percent)%以下のためメールを送信しました。")
    Send-Mail -Subject $subject -Body $body -ToAddresses $settings.to_addresses -Settings $settings.mail
}
