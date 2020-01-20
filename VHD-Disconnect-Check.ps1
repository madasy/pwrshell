 #Get all Users with a active and inactive rdp session

$queryResults = (qwinsta /server:mah-svr-101 | foreach { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv)  

$DisRDPSessions = $queryResults.SESSIONNAME 
$ActivRDPSessions = $queryResults.USERNAME

#Removing admin and system session from the array
  
$a= Get-ADGroupMember RDS2016

$disRDSUsers = $a.SamAccountName | where {$DisRDPSessions -contains $psitem}
$activRDSUsers = $a.SamAccountName | where {$ActivRDPSessions -contains $psitem}

$connectedRDSUsers = $activRDSUsers + $disRDSUsers
   
#Get all connected Fslogix Disks

$Volumes = Get-WmiObject Win32_Volume

$VolumeLabel = $Volumes.Label

#Filterling for the Fslogix Disks

$O365DISKS = $VolumeLabel | Where-Object { $_ -like "O365-*" }

$activDISKS = $O365DISKS.trim("O365-")

#Check if a VHD is connected although the RDS session has ended

$DismountVHDs = $activDISKS | where {$connectedRDSUsers -notcontains $psitem}


#Sending an Alert 


if ($DismountVHDs) 
    
    {
    #$cred = Get-Credential
    #$cred | Export-CliXml C:\scripts\ForAlerting_by_Anish\cred.clixml
    $cred = Import-CliXml "C:\scripts\ForAlerting_by_Anish\cred.clixml"

    ##############################################################################
    $From = "anish.madassery@igeeks.ch"
    $To = "anish.madassery@igeeks.ch"
    $Cc = "alerts.critical@igeeks.ch"
    $Attachments = "C:\scripts\ForAlerting_by_Anish\MAH Workaround - Example.png"
    $Subject = "ALERT: MAH-SVR-101 -> ODFC disk could not be removed."
    $Body = "The following Disks could not be removed from the server:
$DismountVHDs
Workaround: Log in to the RDS server and open Disk Manager: Selects the VHDX mentioned in the alert e-mail and disconnects it from the system. The name of the VHDX always starts with ODFC_ as shown in the example."
    $SMTPServer = "mail.igeeks.ch"
    $SMTPPort = "587"
    Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject `
    -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Attachments $Attachments `
    -Credential $cred 
    ##############################################################################

    } 
