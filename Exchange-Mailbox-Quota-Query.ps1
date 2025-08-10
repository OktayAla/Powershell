$mailbox = Get-Mailbox -Identity "kullanici.adi@mail.com.tr"
$mailboxStats = Get-EXOMailboxStatistics -Identity $mailbox.UserPrincipalName

if ($mailbox.ArchiveStatus -eq "Active") {
    $archiveStats = Get-EXOMailboxStatistics -Identity $mailbox.UserPrincipalName -Archive
    $archiveQuota = $mailbox.ArchiveQuota
    $archiveUsage = $archiveStats.TotalItemSize
} else {
    $archiveQuota = "None"
    $archiveUsage = "None"
}

[PSCustomObject]@{
    DisplayName    = $mailbox.DisplayName
    ArchiveStatus  = $mailbox.ArchiveStatus
    ArchiveQuota   = $archiveQuota
    ArchiveUsage   = $archiveUsage
    MailboxQuota   = $mailbox.ProhibitSendQuota
    MailboxUsage   = $mailboxStats.TotalItemSize
}
