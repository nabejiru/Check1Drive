function ODAuthentication
{
	<#
	.DESCRIPTION
	OneDriveに接続するための認証を行います。
	事前に https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade でクライアントIDを発行しておく必要があります。
	参考にしたソース： https://github.com/MarcelMeurer/PowerShellGallery-OneDrive
	.PARAMETER TenantId
	操作する組織のテナントID
	.PARAMETER ClientId
	https://portal.azure.com で発行したクライアントID
	.PARAMETER AppKey
	https://portal.azure.com で発行したクライアント鍵。
	コード認証の場合に必要です。（コード認証では、認証トークンを更新することができます） 
	.PARAMETER Scope
	スペース区切りされた アクセス許可 
	デフォルト: "files.read,offline_access"
	.PARAMETER RefreshToken
	リフレッシュ トークンを使用して認証トークンを無人でリフレッシュします。認証トークンの期限が切れた場合に指定します。
	.PARAMETER AutoAccept
	trueを指定するとトークン モードでWeb フォームの承認ボタンを自動的に押します。
	.PARAMETER RedirectURI
	https://portal.azure.com に登録したリダイレクトURI。URLは実在しなくても動作します。
	デフォルトは https://login.live.com/oauth20_desktop.srf です。
	.EXAMPLE
    $Authentication=ODAuthentication -ClientId "0000000012345678"
	$AuthToken=$Authentication.access_token
	Connect to OneDrive for authentication and save the token to $AuthToken
	認証を行いトークンを $AuthToken に保存します
	.NOTES
    Author: Marcel Meurer, marcel.meurer@sepago.de, Twitter: MarcelMeurer
	#>
	PARAM(
		[Parameter(Mandatory=$True)]
		[string]$TenantId="unknown",
		[string]$ClientId = "unknown",
		[string]$Scope = "files.read offline_access",
		[string]$RedirectURI ="https://login.live.com/oauth20_desktop.srf",
		[string]$AppKey="",
		[string]$RefreshToken="",
		[switch]$DontShowLoginScreen=$false,
		[switch]$AutoAccept,
		[switch]$LogOut
	)

	$optResourceId=""
	$optOauthVersion="/v2.0"

	$Authentication=""
	if ($AppKey -eq "")
	{ 
		$Type="token"
	} else 
	{ 
		$Type="code"
	}
	
	if ($RefreshToken -ne "")
	{
		write-verbose("リフレッシュトークンが指定されました。トークンを更新します。")
		$body="client_id=$ClientId&redirect_URI=$RedirectURI&client_secret=$([uri]::EscapeDataString($AppKey))&refresh_token="+$RefreshToken+"&grant_type=refresh_token"
		$webRequest=Invoke-WebRequest -Method POST -Uri "https://login.microsoftonline.com/$TenantId/oauth2$optOauthVersion/token" -ContentType "application/x-www-form-urlencoded" -Body $Body -UseBasicParsing

		$Authentication = $webRequest.Content |   ConvertFrom-Json
	} else
	{
		write-verbose("認証モード: " +$Type)
		[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
		[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | out-null
		[Reflection.Assembly]::LoadWithPartialName("System.Web") | out-null
		if ($Logout)
		{
			$URIGetAccessToken="https://login.live.com/logout.srf"
			$URIGetAccessToken="https://login.microsoftonline.com/$TenantId/oauth2$optOauthVersion/logout"
		}
		else
		{
			$URIGetAccessToken="https://login.microsoftonline.com/$TenantId/oauth2$optOauthVersion/authorize?client_id=${ClientId}&scope=${Scope}&response_type=${Type}&redirect_URI=${RedirectURI}"
		}
		write-verbose("認証ページにアクセスします... URL=$URIGetAccessToken")

		$form = New-Object Windows.Forms.Form
		$form.text = "Authenticate to OneDrive"
		$form.size = New-Object Drawing.size @(700,600)
		$form.Width = 675
		$form.Height = 750
		$web=New-object System.Windows.Forms.WebBrowser
		$web.IsWebBrowserContextMenuEnabled = $true
		$web.Width = 600
		$web.Height = 700
		$web.Location = "25, 25"
		$web.navigate($URIGetAccessToken)
		$DocComplete  = {
			if ($web.Url.AbsoluteUri -match "access_token=|error|code=|logout") {$form.Close() }
			if ($web.DocumentText -like '*ucaccept*') {
				#if ($AutoAccept) {$web.Document.GetElementById("idBtn_Accept").InvokeMember("click")}
			}
		}
		$web.Add_DocumentCompleted($DocComplete)
		$form.Controls.Add($web)
		if ($DontShowLoginScreen)
		{
			write-verbose("オプション -DontShowLoginScreenが指定されました。ログイン画面非表示にします。")
			$form.Opacity = 0.0;
		}
		$form.showdialog() | out-null
		
		# リダイレクトURIから認証コードを取得します
		$returnedUrl=($web.Url).ToString().Replace("#","&")
		Write-verbose("return URI=$returnedUrl")

		if ($LogOut) {return "Logout"}
		if ($Type -eq "code")
		{
			write-verbose("認証コードからトークンを取得します...")
			$Authentication = New-Object PSObject
			ForEach ($element in $returnedUrl.Split("?")[1].Split("&")) 
			{
                if([string]::IsNullOrEmpty($element)) {
                    break
                }
				$Authentication | add-member Noteproperty $element.split("=")[0] $element.split("=")[1]
			}
			if ($Authentication.code)
			{
				$body="client_id=$ClientId&redirect_URI=$RedirectURI&client_secret=$([uri]::EscapeDataString($AppKey))&code="+$Authentication.code+"&grant_type=authorization_code"+$optResourceId+"&scope="+$([uri]::EscapeDataString($Scope))
				if ($ResourceId -ne "")
				{
					# OD4B
                    $webRequest=Invoke-WebRequest -Method POST -Uri "https://login.microsoftonline.com/$TenantId/oauth2$optOauthVersion/token" -ContentType "application/x-www-form-urlencoded" -Body $Body -UseBasicParsing
                } else {
					# OD private
					$webRequest=Invoke-WebRequest -Method POST -Uri "https://login.live.com/oauth20_token.srf" -ContentType "application/x-www-form-urlencoded" -Body $Body -UseBasicParsing
				}
				$Authentication = $webRequest.Content |   ConvertFrom-Json
			} else
			{
				write-error("Cannot get authentication code. Error: "+$returnedUrl)
			}
		} else
		{
			$Authentication = New-Object PSObject
			ForEach ($element in $returnedUrl.Split("?")[1].Split("&")) 
			{
				$Authentication | add-member Noteproperty $element.split("=")[0] $element.split("=")[1]
			}
			if ($Authentication.PSobject.Properties.name -match "expires_in")
			{
				$Authentication | add-member Noteproperty "expires" ([System.DateTime]::Now.AddSeconds($Authentication.expires_in))
			}
		}
	}
	if (!($Authentication.PSobject.Properties.name -match "expires_in"))
	{
		write-warning("There is maybe an errror, because there is no access_token!")
	}
	return $Authentication 
}


function Get-Drive 
{
	<#
	.DESCRIPTION
	OneDriveのドライブ情報を取得します
	.PARAMETER AccessToken
	WebAPIを呼び出す際に使用するアクセストークン.
	.PARAMETER User
	取得したいドライブ情報の所有者。指定しない場合はログインユーザ自身となります。

	.EXAMPLE
	$AuthToken=$Authentication.access_token
	Get-Drive
	#>
	PARAM(
		[Parameter(Mandatory=$True)]
		[string]$AccessToken,
		[string]$User = $null
	)

	$headers = @{
		Authorization="bearer ${AccessToken}"
	}

	if([string]::IsNullOrEmpty($User)) {
		$apiUrl = "/me/drive"
	} else {
		$apiUrl = "/users/$User/drive"
	}
	write-verbose("request to $apiUrl")

	$response=Invoke-WebRequest -Method GET -Uri "https://graph.microsoft.com/v1.0$apiUrl" -ContentType "application/json" -Headers $headers
	write-verbose("drive response = ${response}")
	return $response.Content | ConvertFrom-Json
}

