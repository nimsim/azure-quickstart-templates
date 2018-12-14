configuration CreateADPDC 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)
    $domain=$DomainName.split(".")[0]
    $domainSuffix=$DomainName.Split(".")[1]

    Node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

	    WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"		
        }

        Script EnableDNSDiags
	    {
      	    SetScript = { 
		        Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript =  { @{} }
            TestScript = { $false }
	        DependsOn = "[WindowsFeature]DNS"
        }

	    WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
	    }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
	        DependsOn = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk ADDataDisk {
            DiskNumber = 2
            DriveLetter = "F"
            DependsOn = "[xWaitForDisk]Disk2"
        }
<#
        cDiskNoRestart ADDataDisk
        {
            DiskNumber = 2
            DriveLetter = "F"
        }
#>
        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
	        DependsOn="[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDS 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
	        DependsOn = "[xDisk]ADDataDisk"
        } 
        xADUser User1
        {
            Ensure = "Present"
            DomainAdministratorCredential = $DomainCreds
            DomainName = $DomainName
            UserName = "John.Adams"
            Password = "H3dgehogsRunFast!2"
            Path = "CN=Users,DC=$domain,DC=$domainSuffix"
            UserPrincipalName = John.adams@$domainname
            DisplayName = "John Adams"
            GivenName = "John"
            Surname = "Adams"
            Description = "User description John Adams"
            StreetAddress = "Engene 2B"
            City = "Trondheim"
            PostalCode = "7052"
            Country = "Norway"
            Department = "Research"
            Division = "MSFast"
            Company = "Contoso"
            Office = "Superiora"
            JobTitle = "PM Research"
            EmailAddress = "John.Adams@$domain.onmicrosoft.com"
            EmployeeID = "5512"
            EmployeeNumber = "3"
            MobilePhone = "46124712"
            PasswordNeverExpires = True
            CannotChangePassword = True
            
        } 

        xADUser User2
        {
            Ensure = "Present"
            DomainAdministratorCredential = $DomainCreds
            DomainName = $DomainName
            UserName = "Anne.Faraway"
            Password = "H3dgehogsRunFast!2"
            Path = "CN=Users,DC=$domain,DC=$domainSuffix"
            UserPrincipalName = Anne.Faraway@$domainname
            DisplayName = "Anne Faraway"
            GivenName = "Anne"
            Surname = "Faraway"
            Description = "User description Anne Faraway"
            StreetAddress = "Engene 2B"
            City = "Trondheim"
            PostalCode = "7052"
            Country = "Norway"
            Department = "Research"
            Division = "MSFast"
            Company = "Contoso"
            Office = "Superiora"
            JobTitle = "GM Research"
            EmailAddress = "Anne.Farway@$domain.onmicrosoft.com"
            EmployeeID = "7891"
            EmployeeNumber = "1"
            MobilePhone = "46124812"
            PasswordNeverExpires = True
            CannotChangePassword = True
            
        } 
   }
} 