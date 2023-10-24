function ODAuthentication
{
	<#
	.DESCRIPTION
	OneDrive�ɐڑ����邽�߂̔F�؂��s���܂��B
	���O�� https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade �ŃN���C�A���gID�𔭍s���Ă����K�v������܂��B
	�Q�l�ɂ����\�[�X�F https://github.com/MarcelMeurer/PowerShellGallery-OneDrive
	.PARAMETER TenantId
	���삷��g�D�̃e�i���gID
	.PARAMETER ClientId
	https://portal.azure.com �Ŕ��s�����N���C�A���gID
	.PARAMETER AppKey
	https://portal.azure.com �Ŕ��s�����N���C�A���g���B
	�R�[�h�F�؂̏ꍇ�ɕK�v�ł��B�i�R�[�h�F�؂ł́A�F�؃g�[�N�����X�V���邱�Ƃ��ł��܂��j 
	.PARAMETER Scope
	�X�y�[�X��؂肳�ꂽ �A�N�Z�X���� 
	�f�t�H���g: "files.read,offline_access"
	.PARAMETER RefreshToken
	���t���b�V�� �g�[�N�����g�p���ĔF�؃g�[�N���𖳐l�Ń��t���b�V�����܂��B�F�؃g�[�N���̊������؂ꂽ�ꍇ�Ɏw�肵�܂��B
	.PARAMETER AutoAccept
	true���w�肷��ƃg�[�N�� ���[�h��Web �t�H�[���̏��F�{�^���������I�ɉ����܂��B
	.PARAMETER RedirectURI
	https://portal.azure.com �ɓo�^�������_�C���N�gURI�BURL�͎��݂��Ȃ��Ă����삵�܂��B
	�f�t�H���g�� https://login.live.com/oauth20_desktop.srf �ł��B
	.EXAMPLE
    $Authentication=ODAuthentication -ClientId "0000000012345678"
	$AuthToken=$Authentication.access_token
	Connect to OneDrive for authentication and save the token to $AuthToken
	�F�؂��s���g�[�N���� $AuthToken �ɕۑ����܂�
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
		write-verbose("���t���b�V���g�[�N�����w�肳��܂����B�g�[�N�����X�V���܂��B")
		$body="client_id=$ClientId&redirect_URI=$RedirectURI&client_secret=$([uri]::EscapeDataString($AppKey))&refresh_token="+$RefreshToken+"&grant_type=refresh_token"
		$webRequest=Invoke-WebRequest -Method POST -Uri "https://login.microsoftonline.com/$TenantId/oauth2$optOauthVersion/token" -ContentType "application/x-www-form-urlencoded" -Body $Body -UseBasicParsing

		$Authentication = $webRequest.Content |   ConvertFrom-Json
	} else
	{
		write-verbose("�F�؃��[�h: " +$Type)
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
		write-verbose("�F�؃y�[�W�ɃA�N�Z�X���܂�... URL=$URIGetAccessToken")

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
			write-verbose("�I�v�V���� -DontShowLoginScreen���w�肳��܂����B���O�C����ʔ�\���ɂ��܂��B")
			$form.Opacity = 0.0;
		}
		$form.showdialog() | out-null
		
		# ���_�C���N�gURI����F�؃R�[�h���擾���܂�
		$returnedUrl=($web.Url).ToString().Replace("#","&")
		Write-verbose("return URI=$returnedUrl")

		if ($LogOut) {return "Logout"}
		if ($Type -eq "code")
		{
			write-verbose("�F�؃R�[�h����g�[�N�����擾���܂�...")
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
	OneDrive�̃h���C�u�����擾���܂�
	.PARAMETER AccessToken
	WebAPI���Ăяo���ۂɎg�p����A�N�Z�X�g�[�N��.
	.PARAMETER User
	�擾�������h���C�u���̏��L�ҁB�w�肵�Ȃ��ꍇ�̓��O�C�����[�U���g�ƂȂ�܂��B

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

