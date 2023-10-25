<#
.SYNOPSIS
  OneDrive for Buisiness �̃h���C�u�c��c�ʂ��m�F���܂��B
  �c�ʂ��������l�ȉ��̏ꍇ�̓��[���𑗐M���܂��B
.DESCRIPTION
  Microsoft Graph��API���g�p����OneDrive�̎c��e�ʂ��m�F���܂��B
  ���炩����Azure�̃T�C�g�ɂăA�v���o�^���K�v�ł��B�ڍׂ͊֘A�����N���Q�Ƃ��������B

  �܂��A������s����Microsoft�A�J�E���g�̃p�X���[�h�F�؂����߂��܂��B�iWeb�u���E�U���N�����܂��j
  �����ł́A�m�F�������h���C�u�̃I�[�i�[�Ń��O�C�����Ă��������B
.PARAMETER ConfigFile
  �ݒ�t�@�C���̃p�X�B�f�t�H���g��"./config.json"�ł��B
.PARAMETER EnableNotification
  �c�ʌx�����[���̑��M�L�����w�肵�܂��B�f�t�H���g��true�ł��B
.NOTES  
  [���ӓ_] 
  ��x�F�؂���ƃA�J�E���g��؂�ւ��鎖���ł��܂���B�i2023/10/24���_�j
  ���̃A�J�E���g�̗e�ʂ��m�F����ꍇ�́AOS�̃��[�U��؂�ւ��邩���s�[����ς���K�v������܂��B
.LINK
Microsoft Graph �p�̃A�v���̓o�^
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
	�����_�ȉ���؂�̂Ă܂�
	.PARAMETER Value
    �؂�̂Ă����鐔�l
	.PARAMETER Digits
    �؂�̂Č�Ɏc�������_�ȉ��̌���
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
	���l���M�K�o�C�g�P�ʂɂ��܂�
	.PARAMETER Value
    �؂�̂Ă����鐔�l
    #>
    PARAM(
		[long]$value
	)
    $giga = $value / 1024 / 1024 / 1024
    $giga = floor -value $giga -digits 2
    return $giga
}


$scope = "Files.Read.All offline_access"
    
#�F��
write-information("�R�[�h�F�؂��s���܂�...")

# TSL1.2�ʐM��������iWindowsServer�n��InvalidOperation����������΍�j
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$auth = ODAuthentication -ClientID $settings.client_id -AppKey $settings.secret -RedirectURI $settings.redirect_url -TenantId $settings.tenant_id -Scope $scope
write-verbose($auth)

if($auth.error -ne $null) {
    write-warning("�F�؂Ɏ��s�������߁A�����𒆎~���܂� error=${$auth.error}")
    return 
}

# �h���C�u���̎擾
write-verbose("�h���C�u�����擾���Ă��܂�...")
$drive = Get-Drive -AccessToken $auth.access_token 
write-verbose($drive)

$ret=ODAuthentication -ClientID $settings.client_id -AppKey $settings.secret -RedirectURI $settings.redirect_url -TenantId $settings.tenant_id -LogOut $true
if ($drive.quota -eq $null) {
    write-warning("�h���C�u�����擾�ł��܂���")
    return
}

# �e�ʂ��o�͂���
$percent = floor -Value ($drive.quota.remaining / $drive.quota.total * 100) -digits 2
$remainGiga = toGiga -value $drive.quota.remaining
$totalGiga = toGiga -value $drive.quota.total

write-host("owner     : $($drive.owner.user.email)")
write-host("deleted   : $($drive.quota.deleted)")
write-host("used      : $($drive.quota.used)")
write-host("remaining : $($drive.quota.remaining) ($percent%)")
write-host("total     : $($drive.quota.total)")

write-verbose("�������l=$($settings.threthold_percent)%")

# �e�ʂ����Ȃ��ꍇ�̓��[���ʒm����
if (($EnableNotification) -And ($percent -le $settings.threthold_percent)) {
    $subject="[OneDrive]�e�ʌx��"
    $body= @"
OneDrive�̎c��e�ʂ�$($settings.threthold_percent)%�ȉ��ɂȂ�܂����B

# �A�J�E���g: $($drive.owner.user.email)
# ���e��=${totalGiga}GB  �c��=${remainGiga}GB�i$percent%�j
"@

    write-warning("�e�ʂ��c��$($settings.threthold_percent)%�ȉ��̂��߃��[���𑗐M���܂����B")
    Send-Mail -Subject $subject -Body $body -ToAddresses $settings.to_addresses -Settings $settings.mail
}
