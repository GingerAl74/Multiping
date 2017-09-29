$List_File = "C:\Scripts\multiping\inping.txt"
$OUT = "C:\Scripts\multiping\outping.txt"
$count = 0
$length = Get-Content $List_File -Force | Measure-Object -Line -IgnoreWhiteSpace | Format-Table Lines -HideTableHeaders | Out-String
$length = $length.ToString()
$length = $length.TrimStart().TrimEnd()
$now=Get-Date -format "yyyy-MM-dd"
$fail = "Failure"

$StatusCodes = @{
    [uint32]0     = 'Success';
    [uint32]11001 = 'Buffer Too Small';
    [uint32]11002 = 'Destination Net Unreachable';
    [uint32]11003 = 'Destination Host Unreachable';
    [uint32]11004 = 'Destination Protocol Unreachable';
    [uint32]11005 = 'Destination Port Unreachable';
    [uint32]11006 = 'No Resources';
    [uint32]11007 = 'Bad Option';
    [uint32]11008 = 'Hardware Error';
    [uint32]11009 = 'Packet Too Big';
    [uint32]11010 = 'Request Timed Out';
    [uint32]11011 = 'Bad Request';
    [uint32]11012 = 'Bad Route';
    [uint32]11013 = 'TimeToLive Expired Transit';
    [uint32]11014 = 'TimeToLive Expired Reassembly';
    [uint32]11015 = 'Parameter Problem';
    [uint32]11016 = 'Source Quench';
    [uint32]11017 = 'Option Too Big';
    [uint32]11018 = 'Bad Destination';
    [uint32]11032 = 'Negotiating IPSEC';
    [uint32]11050 = 'General Failure'
    }

foreach ($item in get-content $List_File)
    {$command = Get-WmiObject -ErrorAction SilentlyContinue -Class Win32_PingStatus -Filter "Address='$item' AND Timeout=1000"
            if ($command.StatusCode -eq 0) {
            $count++
            $Address = $command.IPV4Address.IPAddressToString
            $Status = $StatusCodes[$command.StatusCode] 
            Write-Output "$item,$Address,$now,$Status," | out-file -Append $OUT
            Write-Progress -Activity "Gathering Services" -status "$count of $length completed" -percentComplete ($count / $length*100)
            } elseif ($command.StatusCode -ge 11001) {
                $count++
                $Address = $command.IPV4Address.IPAddressToString
                $Status = $StatusCodes[$command.StatusCode]
                Write-Output "$item,$Address,$now,$Status," | out-file -Append $OUT
                Write-Progress -Activity "Gathering Services" -status "$count of $length completed" -percentComplete ($count / $length*100)
            } elseif ($command.StatusCode -eq $null) {
                $count++
                Write-Output "$item,$item,$now,$fail," | out-file -Append $OUT
                Write-Progress -Activity "Gathering Services" -status "$count of $length completed" -percentComplete ($count / $length*100)
            }

    }
