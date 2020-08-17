<#
.Synopsis
  This Powershell script enrols a Windows 10 device to Workspace ONE UEM
  
.DESCRIPTION
  Enrols a Windows 10 device to Workspace ONE UEM, whilst waiting for the staging enrolment to complete
  Requires AirWatchAgent.msi in the current folder
  Requires WS1UEM URL, OG, Staging Username and Password in the script as variables

.AUTHOR
  Phil Helmling

.EXAMPLE
  .\WS1EnrolWin10_TS_v0.1.ps1
#>

$current_path = $PSScriptRoot;
if($PSScriptRoot -eq ""){
    #PSScriptRoot only popuates if the script is being run.  Default to default location if empty
    $current_path = "C:\Temp";
} 

# Script Vars
$DestinationURL = "ENROLLMENT_URL"
$DestinationOGName = "ENROLLMENT_OG_ID"
$Username = "PROMPTED_USERNAME"
$Password = "PROMPTED_PASSWORD"

function Get-EnrollmentStatus {

    $EnrollmentStatus = (Get-ItemProperty -Path HKLM:\SOFTWARE\AIRWATCH\EnrollmentStatus -ErrorAction SilentlyContinue).status

    if(EnrollmentStatus -eq 'Completed') {
        $output = $true
    } else {
        $output = $false
    }

    return $output
}

Function Enroll-Device {
    Write-host "Enrolling device into $DestinationURL"
    Try {
        Start-Process msiexec.exe -Wait -ArgumentList "/i $current_path\AirwatchAgent.msi /qn ENROLL=Y  DOWNLOADWSBUNDLE=false IMAGE=N SERVER=$DestinationURL LGNAME=$DestinationOGName USERNAME=$Username PASSWORD=$Password"
	} catch {
        Write-host $_.Exception
	}
}

Start-Sleep -Seconds 1
$connectionStatus = Test-Connection -ComputerName $DestinationURL -Quiet
if($connectionStatus -eq $true) {
    Write-host "Device has connectivity to the Destination Server"
    $enrolled = Get-EnrollmentStatus

    if($enrolled -eq $false) {
        Write-host "Running Enrollment process"
        Enroll-Device

        Start-Sleep -Seconds 1
        
        while($enrolled -eq $false) {
            $status = Get-EnrollmentStatus
            if($status -eq $true) {
                $enrolled = $status
                Write-host "Device Enrollment is complete"
                Start-Sleep -Seconds 1

            } else {
                Write-host "Waiting for enrollment to complete"
                Start-Sleep -Seconds 10
            }
        }
    } else 
    {
        Write-host "Not connected to Wifi, showing UI notification to continue once reconnected"
    }
}


