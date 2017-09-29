function ChooseFile() 
    {
        Add-Type -AssemblyName System.Windows.Forms
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            Multiselect = $true # Multiple files can be chosen if switched to true.
        }
        [void]$FileBrowser.ShowDialog()
        $file = $FileBrowser.FileName;
        If($FileBrowser.FileNames -like "*\*") {
            $FileBrowser.FileName #Lists selected files (optional)
        }
        else {
            [System.Windows.MessageBox]::Show('Operation cancelled by user','Choose File Error','Ok','Error')
        }
    }


function pingInfo ($var1) {

$pingResult=ping -n 2 $var1 | fl | out-string;
$PingoutputBox.text=$pingResult
}

function pingAInfo ($var1) {

$pingResult= ping -a -n 2 $var1 | fl | out-string;
$PingoutputBox.text=$pingResult
}

Function DiscoverFromList($List_File) {
    
    $count = 0
    $length = Get-Content $List_File -Force | Measure-Object -Line -IgnoreWhiteSpace | Format-Table Lines -HideTableHeaders | Out-String
    $length = $length.ToString()
    $length = $length.TrimStart().TrimEnd()
    foreach ($item in get-content $List_File)
        {
        $command = Get-WmiObject -ErrorAction SilentlyContinue -Class Win32_PingStatus -Filter "Address='$item' AND Timeout=1000"
            if ($command.StatusCode -eq 0) {
                $count++
                $Name = $command.ProtocolAddressResolved
                $Address = $command.ProtocolAddress
                $Status = $StatusCodes[$command.StatusCode]
                $global:Available_IP.Add($Name,$Address)
                Write-Progress -Activity "Gathering IP" -status "$count of $length completed" -percentComplete ($count / $length*100)
            } elseif ($command.StatusCode -ge 11001) {
                $count++
                $Name = $command.ProtocolAddressResolved
                $Address = $command.ProtocolAddress
                $Status = $StatusCodes[$command.StatusCode]
                $global:Not_Available_IP.Add($Name,$Address)
                Write-Progress -Activity "Gathering IP" -status "$count of $length completed" -percentComplete ($count / $length*100)
            } elseif ($command.StatusCode -eq $null) {
                $count++
                $global:Not_Existent.add($item,$item)
                Write-Progress -Activity "Gathering IP" -status "$count of $length completed" -percentComplete ($count / $length*100)
            }

    }
}

Function DiscoverFromInput($item) {
    $command = Get-WmiObject -ErrorAction SilentlyContinue -Class Win32_PingStatus -Filter "Address='$item' AND Timeout=1000 AND ResolveAddressNames='true'"
            if ($command.StatusCode -eq 0) {
                $Name = $command.ProtocolAddressResolved
                $Address = $command.ProtocolAddress
                $global:Available_IP.Add($Name,$Address)
            } elseif ($command.StatusCode -ge 11001) {
                $Name = $command.ProtocolAddressResolved
                $Address = $command.ProtocolAddress
                $global:Not_Available_IP.Add($Name,$Address)
            } elseif ($command.StatusCode -eq $null) {
                $global:Not_Existent.add($item,$item)
            }
}

function Test-Port{   
<#     
.SYNOPSIS     
    Tests port on computer.   
     
.DEscriptION   
    Tests port on computer.  
      
.PARAMETER computer   
    Name of server to test the port connection on. 
       
.PARAMETER port   
    Port to test  
        
.PARAMETER tcp   
    Use tcp port  
       
.PARAMETER udp   
    Use udp port   
      
.PARAMETER UDPTimeOut  
    Sets a timeout for UDP port query. (In milliseconds, Default is 1000)   
       
.PARAMETER TCPTimeOut  
    Sets a timeout for TCP port query. (In milliseconds, Default is 1000) 
                  
.NOTES     
    Name: Test-Port.ps1   
    Author: Boe Prox   
    DateCreated: 18Aug2010    
    List of Ports: http://www.iana.org/assignments/port-numbers   
       
    To Do:   
        Add capability to run background jobs for each host to shorten the time to scan.          
.LINK     
    https://boeprox.wordpress.org  
      
.EXAMPLE     
    Test-Port -computer 'server' -port 80   
    Checks port 80 on server 'server' to see if it is listening   
     
.EXAMPLE     
    'server' | Test-Port -port 80   
    Checks port 80 on server 'server' to see if it is listening  
       
.EXAMPLE     
    Test-Port -computer @("server1","server2") -port 80   
    Checks port 80 on server1 and server2 to see if it is listening   
     
.EXAMPLE 
    Test-Port -comp dc1 -port 17 -udp -UDPtimeout 10000 
     
    Server   : dc1 
    Port     : 17 
    TypePort : UDP 
    Open     : True 
    Notes    : "My spelling is Wobbly.  It's good spelling but it Wobbles, and the letters 
            get in the wrong places." A. A. Milne (1882-1958) 
     
    Description 
    ----------- 
    Queries port 17 (qotd) on the UDP port and returns whether port is open or not 
        
.EXAMPLE     
    @("server1","server2") | Test-Port -port 80   
    Checks port 80 on server1 and server2 to see if it is listening   
       
.EXAMPLE     
    (Get-Content hosts.txt) | Test-Port -port 80   
    Checks port 80 on servers in host file to see if it is listening  
      
.EXAMPLE     
    Test-Port -computer (Get-Content hosts.txt) -port 80   
    Checks port 80 on servers in host file to see if it is listening  
         
.EXAMPLE     
    Test-Port -computer (Get-Content hosts.txt) -port @(1..59)   
    Checks a range of ports from 1-59 on all servers in the hosts.txt file       
             
#>    
[cmdletbinding(   
    DefaultParameterSetName = '',   
    ConfirmImpact = 'low'   
)]   
    Param(   
        [Parameter(   
            Mandatory = $True,   
            Position = 0,   
            ParameterSetName = '',   
            ValueFromPipeline = $True)]   
            [array]$computer,   
        [Parameter(   
            Position = 1,   
            Mandatory = $True,   
            ParameterSetName = '')]   
            [array]$port,   
        [Parameter(   
            Mandatory = $False,   
            ParameterSetName = '')]   
            [int]$TCPtimeout=1000,   
        [Parameter(   
            Mandatory = $False,   
            ParameterSetName = '')]   
            [int]$UDPtimeout=1000,              
        [Parameter(   
            Mandatory = $False,   
            ParameterSetName = '')]   
            [switch]$TCP,   
        [Parameter(   
            Mandatory = $False,   
            ParameterSetName = '')]   
            [switch]$UDP                                     
        )   
    Begin {   
        If (!$tcp -AND !$udp) {$tcp = $True}   
        #Typically you never do this, but in this case I felt it was for the benefit of the function   
        #as any errors will be noted in the output of the report           
        $ErrorActionPreference = "SilentlyContinue"   
        $report = @()   
    }   
    Process {      
        ForEach ($c in $computer) {   
            ForEach ($p in $port) {   
                If ($tcp) {     
                    #Create temporary holder    
                    $temp = "" | Select Server, Port, TypePort, Open, Notes   
                    #Create object for connecting to port on computer   
                    $tcpobject = new-Object system.Net.Sockets.TcpClient   
                    #Connect to remote machine's port                 
                    $connect = $tcpobject.BeginConnect($c,$p,$null,$null)   
                    #Configure a timeout before quitting   
                    $wait = $connect.AsyncWaitHandle.WaitOne($TCPtimeout,$false)   
                    #If timeout   
                    If(!$wait) {   
                        #Close connection   
                        $tcpobject.Close()   
                        Write-Verbose "Connection Timeout"   
                        #Build report   
                        $temp.Server = $c   
                        $temp.Port = $p   
                        $temp.TypePort = "TCP"   
                        $temp.Open = "False"   
                        $temp.Notes = "Connection to Port Timed Out"   
                    } Else {   
                        $error.Clear()   
                        $tcpobject.EndConnect($connect) | out-Null   
                        #If error   
                        If($error[0]){   
                            #Begin making error more readable in report   
                            [string]$string = ($error[0].exception).message   
                            $message = (($string.split(":")[1]).replace('"',"")).TrimStart()   
                            $failed = $true   
                        }   
                        #Close connection       
                        $tcpobject.Close()   
                        #If unable to query port to due failure   
                        If($failed){   
                            #Build report   
                            $temp.Server = $c   
                            $temp.Port = $p   
                            $temp.TypePort = "TCP"   
                            $temp.Open = "False"   
                            $temp.Notes = "$message"   
                        } Else{   
                            #Build report   
                            $temp.Server = $c   
                            $temp.Port = $p   
                            $temp.TypePort = "TCP"   
                            $temp.Open = "True"     
                            $temp.Notes = ""   
                        }   
                    }      
                    #Reset failed value   
                    $failed = $Null       
                    #Merge temp array with report               
                    $report += $temp   
                }       
                If ($udp) {   
                    #Create temporary holder    
                    $temp = "" | Select Server, Port, TypePort, Open, Notes                                      
                    #Create object for connecting to port on computer   
                    $udpobject = new-Object system.Net.Sockets.Udpclient 
                    #Set a timeout on receiving message  
                    $udpobject.client.ReceiveTimeout = $UDPTimeout  
                    #Connect to remote machine's port                 
                    Write-Verbose "Making UDP connection to remote server"  
                    $udpobject.Connect("$c",$p)  
                    #Sends a message to the host to which you have connected.  
                    Write-Verbose "Sending message to remote host"  
                    $a = new-object system.text.asciiencoding  
                    $byte = $a.GetBytes("$(Get-Date)")  
                    [void]$udpobject.Send($byte,$byte.length)  
                    #IPEndPoint object will allow us to read datagrams sent from any source.   
                    Write-Verbose "Creating remote endpoint"  
                    $remoteendpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0)  
                    Try {  
                        #Blocks until a message returns on this socket from a remote host.  
                        Write-Verbose "Waiting for message return"  
                        $receivebytes = $udpobject.Receive([ref]$remoteendpoint)  
                        [string]$returndata = $a.GetString($receivebytes) 
                        If ($returndata) { 
                           Write-Verbose "Connection Successful"   
                            #Build report   
                            $temp.Server = $c   
                            $temp.Port = $p   
                            $temp.TypePort = "UDP"   
                            $temp.Open = "True"   
                            $temp.Notes = $returndata    
                            $udpobject.close()    
                        }                        
                    } Catch {  
                        If ($Error[0].ToString() -match "\bRespond after a period of time\b") {  
                            #Close connection   
                            $udpobject.Close()   
                            #Make sure that the host is online and not a false positive that it is open  
                            If (Test-Connection -comp $c -count 1 -quiet) {  
                                Write-Verbose "Connection Open"   
                                #Build report   
                                $temp.Server = $c   
                                $temp.Port = $p   
                                $temp.TypePort = "UDP"   
                                $temp.Open = "True"   
                                $temp.Notes = ""  
                            } Else {  
                                <#  
                                It is possible that the host is not online or that the host is online,   
                                but ICMP is blocked by a firewall and this port is actually open.  
                                #>  
                                Write-Verbose "Host maybe unavailable"   
                                #Build report   
                                $temp.Server = $c   
                                $temp.Port = $p   
                                $temp.TypePort = "UDP"   
                                $temp.Open = "False"   
                                $temp.Notes = "Unable to verify if port is open or if host is unavailable."                                  
                            }                          
                        } ElseIf ($Error[0].ToString() -match "forcibly closed by the remote host" ) {  
                            #Close connection   
                            $udpobject.Close()   
                            Write-Verbose "Connection Timeout"   
                            #Build report   
                            $temp.Server = $c   
                            $temp.Port = $p   
                            $temp.TypePort = "UDP"   
                            $temp.Open = "False"   
                            $temp.Notes = "Connection to Port Timed Out"                          
                        } Else {                       
                            $udpobject.close()  
                        }  
                    }      
                    #Merge temp array with report               
                    $report += $temp   
                }                                   
            }   
        }                   
    }   
    End {   
        #Generate Report   
        $global:report = $report

    } 
}

Function Output {
    param ($table, $Output_File)
    $table | Export-Csv -Append $Output_File -NoTypeInformation
}


function CreateForm {
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
$global:Available_IP = @{}
$global:Not_Available_IP = @{}
$global:Not_Existent = @{}
$path = (Get-Item -Path ".\" -Verbose).FullName
$global:export = @()
#[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
#[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.drawing

$form1 = New-Object System.Windows.Forms.Form

$TabControl = New-object System.Windows.Forms.TabControl
$DiscoverPage = New-Object System.Windows.Forms.TabPage
$Discovergroupbox1 = New-Object System.Windows.Forms.GroupBox
$Discoverradiobutton2 = New-Object System.Windows.Forms.RadioButton
$Discoverradiobutton1 = New-Object System.Windows.Forms.RadioButton
$DiscoverPagebutton1 = New-Object System.Windows.Forms.Button
$DiscoverPagebutton2 = New-Object System.Windows.Forms.Button
$PingPage = New-Object System.Windows.Forms.TabPage
$PingPagebutton1 = New-Object System.Windows.Forms.Button
$PingPagebutton2 = New-Object System.Windows.Forms.Button
$PingCheckBox1 =  New-Object System.Windows.Forms.CheckBox
$PingInputBox = New-Object System.Windows.Forms.TextBox 
$PingOutputBox = New-Object System.Windows.Forms.TextBox
$ViewPage = New-Object System.Windows.Forms.TabPage
$ViewPagebutton1 = New-Object System.Windows.Forms.Button
$ViewPagebutton2 = New-Object System.Windows.Forms.Button
$ViewPagebutton3 = New-Object System.Windows.Forms.Button
$ViewCheckBox1 =  New-Object System.Windows.Forms.CheckBox
$ViewOutputBox1 = New-Object System.Windows.Forms.TextBox
$ViewOutputBox2 = New-Object System.Windows.Forms.TextBox
$Viewgroupbox1 = New-Object System.Windows.Forms.GroupBox
$Viewradiobutton3 = New-Object System.Windows.Forms.RadioButton
$Viewradiobutton2 = New-Object System.Windows.Forms.RadioButton
$Viewradiobutton1 = New-Object System.Windows.Forms.RadioButton
$ConnectPage = New-Object System.Windows.Forms.TabPage
$ConnectPagebutton1 = New-Object System.Windows.Forms.Button
$ConnectPagebutton2 = New-Object System.Windows.Forms.Button
$ConnectPagebutton3 = New-Object System.Windows.Forms.Button
$ConnectCheckBox1 =  New-Object System.Windows.Forms.CheckBox
$ConnectCheckBox2 =  New-Object System.Windows.Forms.CheckBox
$ConnectInputBox1 = New-Object System.Windows.Forms.TextBox
$ConnectOutputBox2 = New-Object System.Windows.Forms.TextBox
$Connectgroupbox1 = New-Object System.Windows.Forms.GroupBox
$Connectradiobutton5 = New-Object System.Windows.Forms.RadioButton
$Connectradiobutton4 = New-Object System.Windows.Forms.RadioButton
$Connectradiobutton3 = New-Object System.Windows.Forms.RadioButton
$Connectradiobutton2 = New-Object System.Windows.Forms.RadioButton
$Connectradiobutton1 = New-Object System.Windows.Forms.RadioButton
$Connectgroupbox2 = New-Object System.Windows.Forms.GroupBox


$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

#Form Parameter
$form1.Text = "MultiPing"
$form1.Name = "MultiPing"
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 725
$System_Drawing_Size.Height = 400
$form1.ClientSize = $System_Drawing_Size
$Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$Form1.Icon = $Icon


###########################################################################

#Tab Control 
$tabControl.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 65
$System_Drawing_Point.Y = 65
$tabControl.Location = $System_Drawing_Point
$tabControl.Name = "tabControl"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 300
$System_Drawing_Size.Width = 575
$tabControl.Size = $System_Drawing_Size
$form1.Controls.Add($tabControl)

# Ping
#Ping Page
$PingPage.DataBindings.DefaultDataSourceUpdateMode = 0
$PingPage.UseVisualStyleBackColor = $True
$PingPage.Name = "Ping Page"
$PingPage.Text = "Ping"
$tabControl.Controls.Add($PingPage)

$PingInputBox.Location = New-Object System.Drawing.Size(20,50) 
$PingInputBox.Size = New-Object System.Drawing.Size(150,20)
$PingPage.Controls.Add($PingInputBox) 

$PingOutputBox.Location = New-Object System.Drawing.Size(10,150) 
$PingOutputBox.Size = New-Object System.Drawing.Size(500,110) 
$PingOutputBox.MultiLine = $True 
$PingOutputBox.ScrollBars = "Vertical" 
$PingPage.Controls.Add($PingOutputBox) 

#PingPageButton 1 Action 
$PingPagebutton1_RunOnClick= 
{
    if ($PingcheckBox1.Checked) {
        pingAInfo $PingInputBox.text        
    }
    Else {
        pingInfo $PingInputBox.text
    }
    $PingInputBox.text = ""
    $PingcheckBox1.Checked = $false
}

#PingPageButton 1
$PingPagebutton1.Name = "PingPagebutton1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 200
$System_Drawing_Size.Height = 30
$PingPagebutton1.Size = $System_Drawing_Size
$PingPagebutton1.UseVisualStyleBackColor = $True
$PingPagebutton1.Text = "Ping"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 350
$System_Drawing_Point.Y = 45
$PingPagebutton1.Location = $System_Drawing_Point
$PingPagebutton1.DataBindings.DefaultDataSourceUpdateMode = 0
$PingPagebutton1.add_Click($PingPagebutton1_RunOnClick)
$PingPage.Controls.Add($PingPagebutton1)

#PingPageButton 2 Action 
$PingPagebutton2_RunOnClick= 
{
    $PingOutputBox.Text = ""
}

#PingPageButton 2
$PingPagebutton2.Name = "PingPagebutton2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 200
$System_Drawing_Size.Height = 30
$PingPagebutton2.Size = $System_Drawing_Size
$PingPagebutton2.UseVisualStyleBackColor = $True
$PingPagebutton2.Text = "Reset"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 350
$System_Drawing_Point.Y = 95
$PingPagebutton2.Location = $System_Drawing_Point
$PingPagebutton2.DataBindings.DefaultDataSourceUpdateMode = 0
$PingPagebutton2.add_Click($PingPagebutton2_RunOnClick)
$PingPage.Controls.Add($PingPagebutton2)

#Ping Check Box 1
$PingCheckBox1.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$PingCheckBox1.Size = $System_Drawing_Size
$PingCheckBox1.TabIndex = 0
$PingCheckBox1.Text = "Add -a option"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 25
$System_Drawing_Point.Y = 105
$PingCheckBox1.Location = $System_Drawing_Point
$PingCheckBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$PingCheckBox1.Name = "PingCheckBox1"
$PingPage.Controls.Add($PingCheckBox1)

# Discover

#DiscoverGroup Box
$Discovergroupbox1.Controls.Add($Discoverradiobutton2)
$Discovergroupbox1.Controls.Add($Discoverradiobutton1)
$Discovergroupbox1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Discovergroupbox1.Location = New-Object System.Drawing.Point(60,100)
$Discovergroupbox1.Name = "groupbox1"
$Discovergroupbox1.Size = New-Object System.Drawing.Size(100,100)
$Discovergroupbox1.TabIndex = 0
$Discovergroupbox1.TabStop = $False
$Discovergroupbox1.Text = ""
$DiscoverPage.Controls.Add($Discovergroupbox1)

# radiobutton2
$Discoverradiobutton2.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Discoverradiobutton2.Location = New-Object System.Drawing.Point(20,40)
$Discoverradiobutton2.Name = "radiobutton2"
$Discoverradiobutton2.Size = New-Object System.Drawing.Size(75,75)
$Discoverradiobutton2.TabIndex = 1
$Discoverradiobutton2.TabStop = $True
$Discoverradiobutton2.Text = "List"
$Discoverradiobutton2.UseVisualStyleBackColor = $True

# radiobutton1
$Discoverradiobutton1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Discoverradiobutton1.Location = New-Object System.Drawing.Point(20,20)
$Discoverradiobutton1.Name = "radiobutton1"
$Discoverradiobutton1.Size = New-Object System.Drawing.Size(104,24)
$Discoverradiobutton1.TabIndex = 0
$Discoverradiobutton1.TabStop = $True
$Discoverradiobutton1.Text = "Individual"
$Discoverradiobutton1.UseVisualStyleBackColor = $True

#Discover Page
$DiscoverPage.DataBindings.DefaultDataSourceUpdateMode = 0
$DiscoverPage.UseVisualStyleBackColor = $True
$DiscoverPage.Name = "Discover Page"
$DiscoverPage.Text = "Discover"
$tabControl.Controls.Add($DiscoverPage)

#DiscoverPage Label1 TextBox1
$DiscoverPageobjLabel = New-Object System.Windows.Forms.Label
$DiscoverPageobjLabel.Location = New-Object System.Drawing.Size(10,15)  
$DiscoverPageobjLabel.Size = New-Object System.Drawing.Size(120,20)  
$DiscoverPage.Controls.Add($DiscoverPageobjLabel)
$global:DiscoverPageobjTextBox1 = New-Object System.Windows.Forms.TextBox 
$global:DiscoverPageobjTextBox1.Location = New-Object System.Drawing.Size(60,45) 
$global:DiscoverPageobjTextBox1.Size = New-Object System.Drawing.Size(250,20)  
$DiscoverPage.Controls.Add($global:DiscoverPageobjTextBox1)

#DiscoverPageButton 1 Action 
$DiscoverPagebutton1_RunOnClick= 
{
    $global:Discoverfile1 = ChooseFile
    $global:Discovertext1 = $global:Discoverfile1 | Out-String
    $global:DiscoverPageobjTextBox1.Text = $global:Discovertext1
}

#DiscoverPageButton 1
$DiscoverPagebutton1.Name = "DiscoverPagebutton1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 75
$System_Drawing_Size.Height = 25
$DiscoverPagebutton1.Size = $System_Drawing_Size
$DiscoverPagebutton1.UseVisualStyleBackColor = $True
$DiscoverPagebutton1.Text = "Choose File"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 350
$System_Drawing_Point.Y = 45
$DiscoverPagebutton1.Location = $System_Drawing_Point
$DiscoverPagebutton1.DataBindings.DefaultDataSourceUpdateMode = 0
$DiscoverPagebutton1.add_Click($DiscoverPagebutton1_RunOnClick)
$DiscoverPage.Controls.Add($DiscoverPagebutton1)

#DiscoverPageButton 2 Action 
$DiscoverPagebutton2_RunOnClick= 
{   
    if ($Discoverradiobutton1.Checked)     {
            $DiscoverPageText1 = $global:DiscoverPageobjTextBox1.Text
            DiscoverFromInput $DiscoverPageText1 
        }
    if ($Discoverradiobutton2.Checked)    {
            $global:Discovertext1 = $global:Discoverfile1 | Out-String
            $global:DiscoverPageobjTextBox1.Text = $global:Discovertext1
            DiscoverFromList $global:DiscoverPageobjTextBox1.Text
        }

}

#DiscoverPageButton 2
$DiscoverPagebutton2.Name = "DiscoverPagebutton2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 75
$System_Drawing_Size.Height = 25
$DiscoverPagebutton2.Size = $System_Drawing_Size
$DiscoverPagebutton2.UseVisualStyleBackColor = $True
$DiscoverPagebutton2.Text = "Run"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 350
$System_Drawing_Point.Y = 105
$DiscoverPagebutton2.Location = $System_Drawing_Point
$DiscoverPagebutton2.DataBindings.DefaultDataSourceUpdateMode = 0
$DiscoverPagebutton2.add_Click($DiscoverPagebutton2_RunOnClick)
$DiscoverPage.Controls.Add($DiscoverPagebutton2)

# View

$ViewPage.DataBindings.DefaultDataSourceUpdateMode = 0
$ViewPage.UseVisualStyleBackColor = $True
$ViewPage.Name = "View Page"
$ViewPage.Text = "View"
$tabControl.Controls.Add($ViewPage)

$ViewPageobjLabel1 = New-Object System.Windows.Forms.Label
$ViewPageobjLabel1.Location = New-Object System.Drawing.Size(10,130)  
$ViewPageobjLabel1.Size = New-Object System.Drawing.Size(120,20) 
$ViewPageobjLabel1.Text = "Key"
$ViewPage.Controls.Add($ViewPageobjLabel1)

$ViewOutputBox1.Location = New-Object System.Drawing.Size(10,150) 
$ViewOutputBox1.Size = New-Object System.Drawing.Size(250,110) 
$ViewOutputBox1.MultiLine = $True 
$ViewOutputBox1.ScrollBars = "Vertical" 
$ViewPage.Controls.Add($ViewOutputBox1) 

$ViewPageobjLabel2 = New-Object System.Windows.Forms.Label
$ViewPageobjLabel2.Location = New-Object System.Drawing.Size(280,130)  
$ViewPageobjLabel2.Size = New-Object System.Drawing.Size(120,20) 
$ViewPageobjLabel2.Text = "Value" 
$ViewPage.Controls.Add($ViewPageobjLabel2)

$ViewOutputBox2.Location = New-Object System.Drawing.Size(280,150) 
$ViewOutputBox2.Size = New-Object System.Drawing.Size(250,110) 
$ViewOutputBox2.MultiLine = $True 
$ViewOutputBox2.ScrollBars = "Vertical" 
$ViewPage.Controls.Add($ViewOutputBox2) 

#ViewPageButton 1 Action 
$ViewPagebutton1_RunOnClick= 
{
    if ($Viewradiobutton1.Checked) {
        
        $Viewtext1 = $global:Available_IP.Keys | Out-String
        $Viewtext2 = $global:Available_IP.Values | Out-String
        $ViewoutputBox1.text=  $Viewtext1
        $ViewoutputBox2.text=  $Viewtext2
    }
    if ($Viewradiobutton2.Checked) {
        $ViewoutputBox.text=$global:Not_Available_IP
    }
    if ($Viewradiobutton3.Checked) {
        $ViewoutputBox.text=$global:Not_Existent
    }
}

#ViewPageButton 1
$ViewPagebutton1.Name = "ViewPagebutton1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 30
$ViewPagebutton1.Size = $System_Drawing_Size
$ViewPagebutton1.UseVisualStyleBackColor = $True
$ViewPagebutton1.Text = "View"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 50
$System_Drawing_Point.Y = 95
$ViewPagebutton1.Location = $System_Drawing_Point
$ViewPagebutton1.DataBindings.DefaultDataSourceUpdateMode = 0
$ViewPagebutton1.add_Click($ViewPagebutton1_RunOnClick)
$ViewPage.Controls.Add($ViewPagebutton1)

#ViewPageButton 2 Action 
$ViewPagebutton2_RunOnClick= 
{
    $ViewOutputBox1.Text = ""
    $ViewOutputBox2.Text = ""
}

#ViewPageButton 2
$ViewPagebutton2.Name = "ViewPagebutton2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 30
$ViewPagebutton2.Size = $System_Drawing_Size
$ViewPagebutton2.UseVisualStyleBackColor = $True
$ViewPagebutton2.Text = "Reset"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 220
$System_Drawing_Point.Y = 95
$ViewPagebutton2.Location = $System_Drawing_Point
$ViewPagebutton2.DataBindings.DefaultDataSourceUpdateMode = 0
$ViewPagebutton2.add_Click($ViewPagebutton2_RunOnClick)
$ViewPage.Controls.Add($ViewPagebutton2)

#ViewPageButton 3 Action 
$ViewPagebutton3_RunOnClick= 
{
    $location = ChooseFile

    if ($Viewradiobutton1.Checked) {
        $table1 = $global:Available_IP | Format-List | Out-File -Append $location
    }
    if ($Viewradiobutton2.Checked) {
        $table1 = $global:Not_Available_IP | Format-List | Out-File -Append $location
    }
    if ($Viewradiobutton3.Checked) {
        $table1 = $global:Not_Existent | Format-List | Out-File -Append $location
    }
}

#ViewPageButton 3
$ViewPagebutton3.Name = "ViewPagebutton2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 30
$ViewPagebutton3.Size = $System_Drawing_Size
$ViewPagebutton3.UseVisualStyleBackColor = $True
$ViewPagebutton3.Text = "Export"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 390
$System_Drawing_Point.Y = 95
$ViewPagebutton3.Location = $System_Drawing_Point
$ViewPagebutton3.DataBindings.DefaultDataSourceUpdateMode = 0
$ViewPagebutton3.add_Click($ViewPagebutton3_RunOnClick)
$ViewPage.Controls.Add($ViewPagebutton3)

#ViewGroup Box
$Viewgroupbox1.Controls.Add($Viewradiobutton3)
$Viewgroupbox1.Controls.Add($Viewradiobutton2)
$Viewgroupbox1.Controls.Add($Viewradiobutton1)
$Viewgroupbox1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Viewgroupbox1.Location = New-Object System.Drawing.Point(30,20)
$Viewgroupbox1.Name = "Viewgroupbox1"
$Viewgroupbox1.Size = New-Object System.Drawing.Size(500,50)
$Viewgroupbox1.TabIndex = 0
$Viewgroupbox1.TabStop = $False
$Viewgroupbox1.Text = ""
$ViewPage.Controls.Add($Viewgroupbox1)

# Viewradiobutton3
$Viewradiobutton3.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Viewradiobutton3.Location = New-Object System.Drawing.Point(300,20)
$Viewradiobutton3.Name = "Viewradiobutton3"
$Viewradiobutton3.Size = New-Object System.Drawing.Size(100,30)
$Viewradiobutton3.TabIndex = 1
$Viewradiobutton3.TabStop = $True
$Viewradiobutton3.Text = "Unavailable"
$Viewradiobutton3.UseVisualStyleBackColor = $True


# Viewradiobutton2
$Viewradiobutton2.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Viewradiobutton2.Location = New-Object System.Drawing.Point(160,20)
$Viewradiobutton2.Name = "Viewradiobutton2"
$Viewradiobutton2.Size = New-Object System.Drawing.Size(100,30)
$Viewradiobutton2.TabIndex = 1
$Viewradiobutton2.TabStop = $True
$Viewradiobutton2.Text = "Offline"
$Viewradiobutton2.UseVisualStyleBackColor = $True

# Viewradiobutton1
$Viewradiobutton1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Viewradiobutton1.Location = New-Object System.Drawing.Point(20,20)
$Viewradiobutton1.Name = "Viewradiobutton1"
$Viewradiobutton1.Size = New-Object System.Drawing.Size(100,30)
$Viewradiobutton1.TabIndex = 0
$Viewradiobutton1.TabStop = $True
$Viewradiobutton1.Text = "Available"
$Viewradiobutton1.UseVisualStyleBackColor = $True

# Connect

$ConnectPage.DataBindings.DefaultDataSourceUpdateMode = 0
$ConnectPage.UseVisualStyleBackColor = $True
$ConnectPage.Name = "Connect Page"
$ConnectPage.Text = "Connect"
$tabControl.Controls.Add($ConnectPage)

$ConnectPageobjLabel1 = New-Object System.Windows.Forms.Label
$ConnectPageobjLabel1.Location = New-Object System.Drawing.Size(180,20)  
$ConnectPageobjLabel1.Size = New-Object System.Drawing.Size(120,20) 
$ConnectPageobjLabel1.Text = "Port"
$ConnectPage.Controls.Add($ConnectPageobjLabel1)

$ConnectInputBox1.Location = New-Object System.Drawing.Size(180,40) 
$ConnectInputBox1.Size = New-Object System.Drawing.Size(70,20) 
$ConnectInputBox1.MultiLine = $False
$ConnectInputBox1.MaxLength = 5
$ConnectPage.Controls.Add($ConnectInputBox1) 

$ConnectPageobjLabel2 = New-Object System.Windows.Forms.Label
$ConnectPageobjLabel2.Location = New-Object System.Drawing.Size(30,130)  
$ConnectPageobjLabel2.Size = New-Object System.Drawing.Size(140,20) 
$ConnectPageobjLabel2.Text = "Connection Report" 
$ConnectPage.Controls.Add($ConnectPageobjLabel2)

$ConnectOutputBox2.Location = New-Object System.Drawing.Size(30,150) 
$ConnectOutputBox2.Size = New-Object System.Drawing.Size(500,110) 
$ConnectOutputBox2.MultiLine = $True 
$ConnectOutputBox2.ScrollBars = "Vertical" 
$ConnectPage.Controls.Add($ConnectOutputBox2)

#ConnectPageButton 1 Action 
$ConnectPagebutton1_RunOnClick= 
{
    # Table
    if ($Connectradiobutton1.Checked) {
        $global:table = $Available_IP
    }
    if ($Connectradiobutton2.Checked) {
        $global:table = $Not_Available_IP
    }
    if ($Connectradiobutton3.Checked) {
        $global:table = $Not_Existent
    }

    # Port
    $global:port = $ConnectInputBox1.Text

    # Protocol
    if ($Connectradiobutton4.Checked) {
        $list = $table.GetEnumerator() | % { $_.Value }
        foreach ($item in $list){
            Test-Port -computer "$item" -port $port -tcp
		    $global:export += New-Object -TypeName psobject -Property @{
		        Server = $report.Server
		        Port = $report.Port
		        Protocol = $report.TypePort
		        OpenStatus = $report.Open
		        Notes = $report.Notes
		    }
        }
    }
    if ($Connectradiobutton5.Checked) {
        $list = $table.GetEnumerator() | % { $_.Value }
        foreach ($item in $list){
            Test-Port -computer "$item" -port $port -udp
            $global:export += New-Object -TypeName psobject -Property @{
			    Server = $report.Server
			    Port = $report.Port
			    Protocol = $report.TypePort
			    OpenStatus = $report.Open
			    Notes = $report.Notes
			}
        }
    }
    $ConnectOutputBox2.Text = $global:export | format-table -AutoSize Server,Port,Protocol,OpenStatus,Notes | Out-String
    $ConnectInputBox1.Text = ""
}

#ConnectPageButton 1
$ConnectPagebutton1.Name = "ConnectPagebutton1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 200
$System_Drawing_Size.Height = 30
$ConnectPagebutton1.Size = $System_Drawing_Size
$ConnectPagebutton1.UseVisualStyleBackColor = $True
$ConnectPagebutton1.Text = "Connect"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 300
$System_Drawing_Point.Y = 25
$ConnectPagebutton1.Location = $System_Drawing_Point
$ConnectPagebutton1.DataBindings.DefaultDataSourceUpdateMode = 0
$ConnectPagebutton1.add_Click($ConnectPagebutton1_RunOnClick)
$ConnectPage.Controls.Add($ConnectPagebutton1)

#ConnectPageButton 2 Action 
$ConnectPagebutton2_RunOnClick= 
{
    $ConnectOutputBox2.Text = ""
    $global:table = ""
    $global:port = ""
    $Connectradiobutton1.Checked = $False
    $Connectradiobutton2.Checked = $False
    $Connectradiobutton3.Checked = $False
    $Connectradiobutton4.Checked = $False
    $Connectradiobutton5.Checked = $False
}

#ConnectPageButton 2
$ConnectPagebutton2.Name = "ConnectPagebutton2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 200
$System_Drawing_Size.Height = 30
$ConnectPagebutton2.Size = $System_Drawing_Size
$ConnectPagebutton2.UseVisualStyleBackColor = $True
$ConnectPagebutton2.Text = "Reset"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 300
$System_Drawing_Point.Y = 95
$ConnectPagebutton2.Location = $System_Drawing_Point
$ConnectPagebutton2.DataBindings.DefaultDataSourceUpdateMode = 0
$ConnectPagebutton2.add_Click($ConnectPagebutton2_RunOnClick)
$ConnectPage.Controls.Add($ConnectPagebutton2)

#ConnectPageButton 3 Action 
$ConnectPagebutton3_RunOnClick= 
{
    $location = ChooseFile
    $export | select-object "Server", "Port", "Protocol", "OpenStatus", "Notes" |export-csv $location -NoTypeInformation
}

#ConnectPageButton 3
$ConnectPagebutton3.Name = "ConnectPagebutton1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 200
$System_Drawing_Size.Height = 30
$ConnectPagebutton3.Size = $System_Drawing_Size
$ConnectPagebutton3.UseVisualStyleBackColor = $True
$ConnectPagebutton3.Text = "Export Connection Report"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 300
$System_Drawing_Point.Y = 60
$ConnectPagebutton3.Location = $System_Drawing_Point
$ConnectPagebutton3.DataBindings.DefaultDataSourceUpdateMode = 0
$ConnectPagebutton3.add_Click($ConnectPagebutton3_RunOnClick)
$ConnectPage.Controls.Add($ConnectPagebutton3)

#ConnectGroup Box
$Connectgroupbox1.Controls.Add($Connectradiobutton3)
$Connectgroupbox1.Controls.Add($Connectradiobutton2)
$Connectgroupbox1.Controls.Add($Connectradiobutton1)
$Connectgroupbox1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Connectgroupbox1.Location = New-Object System.Drawing.Point(40,20)
$Connectgroupbox1.Name = "Connectgroupbox1"
$Connectgroupbox1.Size = New-Object System.Drawing.Size(130,105)
$Connectgroupbox1.TabIndex = 0
$Connectgroupbox1.TabStop = $False
$Connectgroupbox1.Text = "Table"
$ConnectPage.Controls.Add($Connectgroupbox1)

# Connectradiobutton3
$Connectradiobutton3.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Connectradiobutton3.Location = New-Object System.Drawing.Point(20,70)
$Connectradiobutton3.Name = "Connectradiobutton3"
$Connectradiobutton3.Size = New-Object System.Drawing.Size(100,30)
$Connectradiobutton3.TabIndex = 1
$Connectradiobutton3.TabStop = $True
$Connectradiobutton3.Text = "Unavailable"
$Connectradiobutton3.UseVisualStyleBackColor = $True


# Connectradiobutton2
$Connectradiobutton2.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Connectradiobutton2.Location = New-Object System.Drawing.Point(20,45)
$Connectradiobutton2.Name = "Connectradiobutton2"
$Connectradiobutton2.Size = New-Object System.Drawing.Size(80,30)
$Connectradiobutton2.TabIndex = 1
$Connectradiobutton2.TabStop = $True
$Connectradiobutton2.Text = "Offline"
$Connectradiobutton2.UseVisualStyleBackColor = $True

# Connectradiobutton1
$Connectradiobutton1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Connectradiobutton1.Location = New-Object System.Drawing.Point(20,20)
$Connectradiobutton1.Name = "Connectradiobutton1"
$Connectradiobutton1.Size = New-Object System.Drawing.Size(80,30)
$Connectradiobutton1.TabIndex = 0
$Connectradiobutton1.TabStop = $True
$Connectradiobutton1.Text = "Available"
$Connectradiobutton1.UseVisualStyleBackColor = $True

#ConnectGroup Box2
$Connectgroupbox2.Controls.Add($Connectradiobutton4)
$Connectgroupbox2.Controls.Add($Connectradiobutton5)
$Connectgroupbox2.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Connectgroupbox2.Location = New-Object System.Drawing.Point(180,70)
$Connectgroupbox2.Name = "Connectgroupbox1"
$Connectgroupbox2.Size = New-Object System.Drawing.Size(110,75)
$Connectgroupbox2.TabIndex = 0
$Connectgroupbox2.TabStop = $False
$Connectgroupbox2.Text = "Protocol"
$ConnectPage.Controls.Add($Connectgroupbox2)

# Connectradiobutton3
$Connectradiobutton4.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Connectradiobutton4.Location = New-Object System.Drawing.Point(10,15)
$Connectradiobutton4.Name = "Connectradiobutton1"
$Connectradiobutton4.Size = New-Object System.Drawing.Size(50,24)
$Connectradiobutton4.TabIndex = 0
$Connectradiobutton4.TabStop = $True
$Connectradiobutton4.Text = "TCP"
$Connectradiobutton4.UseVisualStyleBackColor = $True

# Connectradiobutton4
$Connectradiobutton5.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
$Connectradiobutton5.Location = New-Object System.Drawing.Point(10,35)
$Connectradiobutton5.Name = "Connectradiobutton1"
$Connectradiobutton5.Size = New-Object System.Drawing.Size(50,24)
$Connectradiobutton5.TabIndex = 0
$Connectradiobutton5.TabStop = $True
$Connectradiobutton5.Text = "UDP"
$Connectradiobutton5.UseVisualStyleBackColor = $True

#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form1.ShowDialog()| Out-Null
} 

CreateForm