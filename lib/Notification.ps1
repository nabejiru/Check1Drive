function Send-Mail {
    PARAM(
        <#
        .DESCRIPTION
        ���[���𑗐M���܂�
        .PARAMETER Subject
        ���[���̃^�C�g��.
        .PARAMETER Body
        ���[���{��
        .PARAMETER ToAddresses
        ���M��A�h���X�̔z��
        .PARAMETER Settings
        ���[���T�[�o���̐ݒ�B�ȉ��̂悤�ȃI�u�W�F�N�g�����҂��܂��B
        {
            "from_address": "���M���[���A�h���X",    
            "smtp_address":"SMTP�T�[�o�̃A�h���X",
            "port": SMTP�T�[�o�̃|�[�g�ԍ�,
            "enable_ssl": SSL�g�p,
            "user":"���[���T�[�o�̃��[�UID",
            "password" : "���[���T�[�o�̃p�X���[�h"
        }
        #>

		[Parameter(Mandatory=$True)]
        [string] $Subject,
        [string] $Body,
        [string[]] $ToAddresses,
		[object] $Settings
	)

    # ���M���[���T�[�o�[�̐ݒ�
    $client=New-Object Net.Mail.SmtpClient($Settings.smtp_address,$Settings.port)
    $client.EnableSsl = $Settings.enable_ssl
    $client.DeliveryMethod = [System.Net.Mail.SmtpDeliveryMethod]::Network
    $client.Credentials = New-Object Net.NetworkCredential($Settings.user,$Settings.password)
    write-verbose "���[���𑗐M���܂�..."

    $to = $ToAddresses -join ";"
    $message = New-Object Net.Mail.MailMessage($Settings.from_address,$to,$Subject,$Body)
    $client.Send($message)
    $message.Dispose()
    $client.Dispose()
}
