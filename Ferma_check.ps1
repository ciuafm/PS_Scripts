
Function SQL_insert($SQLText)
{
    try
    {
                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
                    $SqlConnection.ConnectionString = $cs
                    $SqlConnection.Open()
                    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
                    $SqlCmd.CommandText = $SQLText
                    $SqlCmd.Connection = $SqlConnection
                    $SqlCmd.ExecuteReader()
                    $SqlCmd.Dispose()
                    $SqlConnection.Close()
    } # try
        Catch
    {
        Write-Host ""
        Write-Host "******************************************** Exception occurs **********************************"
        Write-Host "*** ErrorMessage = " $_.Exception.Message
        Write-Host "*** FailedItem   = " $_.Exception.ItemName
        Write-Host "*** SQLText      = " $SQLText
        Write-Host "******************************************** End of exception **********************************"
    }
                
}


$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = $cs
    $SqlConnection.Open()
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand

$LastTime = "0"
for ($i=0;$i -lt 1; $i=$i)
{
    $skip=$false
    
    $R=Invoke-WebRequest http://88.88.88.88:8888/ # -SessionVariable fb
    if ($R.StatusCode -ne 200)
    {
        write "out of service"
    }
    else
    {
        $A = $R.Content
        $A = $A.Substring($A.IndexOf("{"))
        $A = $A.Substring(0,$A.IndexOf("}")+1)
        $A = $A.Substring($A.IndexOf("[")+1)
        $A = $A.Substring(0,$A.IndexOf("]"))
        #$A 
        $D = $A -split(", ")
        #$D
        $Time = $D[1].Replace('"','')
        if ($LastTime -eq $Time) {$skip=$true}
        $LastTime = $Time
        "TIME: "+$Time+" ----------------------------------------------------"
        $Total = $D[2].Replace('"','')
        #"Total: "+$Total
        $T = $Total -split(";")
        $TotalHR=$T[0]
        $TotalSH=$T[1]
        $Hashrates = $D[3].Replace('"','')
        #"Hashrates: "+$Hashrates 
        $Temp_Pers = $D[6].Replace('"','')
        #"Temp_Pers: "+ $Temp_Pers
        $B = $R.Content -split("</font>")
        $C=""
        $B | foreach     { if ($_ -like "*), Rejected:*")  {    $C=$_  }  }
        $C = $C.Substring($C.IndexOf("(")+1)
        $C = $C.Substring(0,$C.IndexOf(")"))
        $C = $C.Replace("+",";")
        #"Total_sh: "+$C
        
        $cesttime = Get-Date
        
        $TimeNow = (Get-Date $cesttime.AddHours(+2) -Format "yyyy-MM-dd HH:mm:ss")
        
        if (-not ($skip))
        {
            $sql = "INSERT INTO [dbo].[Miner_log] ( [Uptime] ,[TotalHR],[TotalSH],[HRpC]   ,[TCpC]   ,[SHpC]   ,[time]) 
            VALUES ('$Time','$TotalHR','$TotalSH','$Hashrates','$Temp_Pers','$C','$TimeNow')"
            SQL_insert($sql)
            $pic = @"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg version = "1.1" baseProfile="full" xmlns = "http://www.w3.org/2000/svg"  xmlns:xlink = "http://www.w3.org/1999/xlink" xmlns:ev = "http://www.w3.org/2001/xml-events"
   height = "400px"  width = "800px">
   <rect x="0" y="0" width="800" height="400"  fill="none" stroke="black" stroke-width="1px" />
         

"@
    
           $Datatable = New-Object System.Data.DataTable
           $sql ="  select top 900 * from [Miner_log] where time > '2017-09-29T09:53:38.000' order by 1 desc"
           #  $sql
           $SqlCmd.CommandText = $sql
           $SqlCmd.Connection = $SqlConnection
           $Reader = $SqlCmd.ExecuteReader()
           $Datatable.Load($Reader)
    
    
           $array = @()
           $LatestReport = ""
           $not_first = $false
           $not_second = $false
           $long_enough  = $false
           $pic_TotalSH = "";
           $pic_T0 = "<path fill='none' stroke='green' d='"; # "' />";
           $pic_T1 = "<path fill='none' stroke='green' d='"; # "' />";
           $pic_T2 = "<path fill='none' stroke='green' d='"; # "' />";
           $pic_T3 = "<path fill='none' stroke='green' d='"; # "' />";
           $pic_P0 = "<path fill='none' stroke='blue' d='"; # "' />";
           $pic_P1 = "<path fill='none' stroke='blue' d='"; # "' />";
           $pic_P2 = "<path fill='none' stroke='blue' d='"; # "' />";
           $pic_P3 = "<path fill='none' stroke='blue' d='"; # "' />";
           $FirstTime = 0;
           $prev_object = New-Object -TypeName PSObject
           $prev_prev_object = New-Object -TypeName PSObject
           
           foreach ($line in $Datatable)
           {
               if (-not($long_enough))
               {# [Uptime] ,[TotalHR],[TotalSH],[HRpC]   ,[TCpC]   ,[SHpC] 
                   $object = New-Object -TypeName PSObject
                   $object | Add-Member -Name 'Time' -MemberType Noteproperty -Value $line[0].ToString()
                   $object | Add-Member -Name 'TotalHR' -MemberType Noteproperty -Value $line[1].ToString()
                   $object | Add-Member -Name 'TotalSH' -MemberType Noteproperty -Value $line[2].ToString()
                   $object | Add-Member -Name 'HRpC' -MemberType Noteproperty -Value $line[3].ToString().split(";")
                   $object | Add-Member -Name 'TCpC' -MemberType Noteproperty -Value $line[4].ToString().split(";")
                   $object | Add-Member -Name 'SHpC' -MemberType Noteproperty -Value $line[5].ToString().split(";")
                   if ($not_first)
                   {
                       if (($not_second) -and ((0+$prev_object.Time-$object.Time) -eq 0))
                           {$prev_object = $prev_prev_object }
                           
                       $x = 0+$FirstTime-$object.Time
                       $w = 0.000001+(($prev_object.Time-$object.Time))
                       $di = 0+($prev_object.TotalSH-$object.TotalSH) 
                       $h = $di*10/$w
                       $h0 =0+($prev_object.SHpC[0]-$object.SHpC[0])*2/$w
                       $h1 =0+($prev_object.SHpC[1]-$object.SHpC[1])*2/$w
                       $h2 =0+($prev_object.SHpC[2]-$object.SHpC[2])*2/$w
                       $h3 =0+($prev_object.SHpC[3]-$object.SHpC[3])*2/$w
                       $h4 =0+($prev_object.SHpC[4]-$object.SHpC[4])*2/$w
                       $x =  [math]::Round(($x-$w)+5)
                       if ($x -gt 800) {$long_enough = $true}
                       $w = [math]::Round($w)
                       $h = [math]::Round($h)
                       $h0 =[math]::Round($h0)
                       $h1 =[math]::Round($h1)
                       $h2 =[math]::Round($h2)
                       $h3 =[math]::Round($h3)
                       $h4 =[math]::Round($h4)
                       if ($h0 -ge 1) {$h0=3}
                       if ($h1 -ge 1) {$h1=3}
                       if ($h2 -ge 1) {$h2=3}
                       if ($h3 -ge 1) {$h3=3}
                       if ($h4 -ge 1) {$h4=3}
                       #$object | Add-Member -Name 'x' -MemberType Noteproperty -Value "$x"
                       #$object | Add-Member -Name 'w' -MemberType Noteproperty -Value "$w"
                       #$object | Add-Member -Name 'di' -MemberType Noteproperty -Value "$di"
                       #$object | Add-Member -Name 'h' -MemberType Noteproperty -Value "$h"
    
                       $pic_TotalSH = $pic_TotalSH + "<rect x='$x' y='1' width='$w' height='$h0' fill='#ff8080'/>`r`n"
                       $pic_TotalSH = $pic_TotalSH + "<rect x='$x' y='5' width='$w' height='$h1' fill='#80ff80'/>`r`n"
                       $pic_TotalSH = $pic_TotalSH + "<rect x='$x' y='9' width='$w' height='$h2' fill='#8080ff'/>`r`n"
                       $pic_TotalSH = $pic_TotalSH + "<rect x='$x' y='13' width='$w' height='$h3' fill='#ff80ff'/>`r`n"
                       $pic_TotalSH = $pic_TotalSH + "<rect x='$x' y='17' width='$w' height='$h4' fill='#80FFff'/>`r`n"
                       $pic_TotalSH = $pic_TotalSH + "<rect x='$x' y='21' width='$w' height='$h' fill='#808080'/>`r`n"
                       $y = 100+$object.TCpC[0]
                       $pic_T0 = $pic_T0+"L $x $y "
                       $y = 100+$object.TCpC[2]
                       $pic_T1 = $pic_T1+"L $x $y "
                       $y = 100+$object.TCpC[4]
                       $pic_T2 = $pic_T2+"L $x $y "
                       $y = 100+$object.TCpC[6]
                       $pic_T3 = $pic_T3+"L $x $y "
                       $y = 100+$object.TCpC[1]
                       $pic_P0 = $pic_P0+"L $x $y "
                       $y = 100+$object.TCpC[3]
                       $pic_P1 = $pic_P1+"L $x $y "
                       $y = 100+$object.TCpC[5]
                       $pic_P2 = $pic_P2+"L $x $y "
                       $y = 100+$object.TCpC[7]
                       $pic_P3 = $pic_P3+"L $x $y "
                       $not_second = $true
                   } else
                   {
                       $LatestReport =$line[6].ToString()
                       $x = 5
                       $y = 100+$object.TCpC[0]
                       $pic_T0 = $pic_T0+"M $x $y "
                       $y = 100+$object.TCpC[2]
                       $pic_T1 = $pic_T1+"M $x $y "
                       $y = 100+$object.TCpC[4]
                       $pic_T2 = $pic_T2+"M $x $y "
                       $y = 100+$object.TCpC[6]
                       $pic_T3 = $pic_T3+"M $x $y "
                       $y = 100+$object.TCpC[1]
                       $pic_P0 = $pic_P0+"M $x $y "
                       $y = 100+$object.TCpC[3]
                       $pic_P1 = $pic_P1+"M $x $y "
                       $y = 100+$object.TCpC[5]
                       $pic_P2 = $pic_P2+"M $x $y "
                       $y = 100+$object.TCpC[7]
                       $pic_P3 = $pic_P3+"M $x $y "
                       #$object | Add-Member -Name 'x' -MemberType Noteproperty -Value '0'
                       #$object | Add-Member -Name 'w' -MemberType Noteproperty -Value '0'
                       #$object | Add-Member -Name 'di' -MemberType Noteproperty -Value '0'
                       #$object | Add-Member -Name 'h' -MemberType Noteproperty -Value '0'
                       $FirstTime = ""+$object.Time
                       $not_first = $true
                   }
                   $prev_prev_object = $prev_object
                   $prev_object = $object 
                   $array += $object
                 }
               }
               # $array | Format-Table  -Auto
               
               $Datatable.Dispose()
               $Reader.Dispose()
               $pic_T0 = $pic_T0+"' />";
               $pic_T1 = $pic_T1+"' />";
               $pic_T2 = $pic_T2+"' />";
               $pic_T3 = $pic_T3+"' />";
               $pic_P0 = $pic_P0+"' />";
               $pic_P1 = $pic_P1+"' />";
               $pic_P2 = $pic_P2+"' />";
               $pic_P3 = $pic_P3+"' />";
               $pic = $pic +  #"<path fill='none' stroke='red' d='M 0 100 L 800 100 M 0 150 L 800 150 M 0 180 L 800 180  M 0 200 L 800 200' />
               "<rect x='0' y='100' width='800' height='50' fill='#ddffdd'  />"+
               "<rect x='0' y='150' width='800' height='30' fill='#ffffdd'  />"+
               "<rect x='0' y='180' width='800' height='20' fill='#ffdddd'  />"
               
               $pic = $pic + $pic_TotalSH+"`r`n"+$pic_T0+"`r`n"+$pic_T1+"`r`n"+$pic_T2+"`r`n"+$pic_T3+"`r`n"+$pic_P0+"`r`n"+$pic_P1+"`r`n"+$pic_P2+"`r`n"+$pic_P3+"`r`n";
               $pic = $pic + "<text x = '10' y = '240' font-family = 'Verdana' font-size = '15'>    Latest report: "+$LatestReport+" </text>"
               $pic = $pic + "</svg>"  # </g>
               $pic > C:\dl_tl\TL\miner.svg
            }   
    
            if (-not ($skip))
            { 
                Start-Sleep -s 60 
                $command='& "C:\Program Files (x86)\Inkscape\inkscape.exe" -z -e "C:\dl_tl\TL\miner.png" "C:\dl_tl\TL\miner.svg"'
                Invoke-Expression $command
            }
            else
            { 
                Start-Sleep -s 1 
            }
        }
}
$SqlCmd.Dispose()
$SqlConnection.Close()
                
#########       USE [books-index]
#########       GO
#########       
#########       /****** Object:  Table [dbo].[log]    Script Date: 9/29/2017 9:10:12 AM ******/
#########       SET ANSI_NULLS ON
#########       GO
#########       
#########       SET QUOTED_IDENTIFIER ON
#########       GO
#########       
#########       CREATE TABLE [dbo].[Miner_log](
#########       	[Uptime]  [nchar](10) NULL, -- Uptime in minutes
#########       	[TotalHR] [nchar](10) NULL, -- Total Hash Rate
#########       	[TotalSH] [nchar](10) NULL, -- Total Shares
#########       	[HRpC]    [nchar](30) NULL, -- Hash Rate per Card
#########       	[TCpC]    [nchar](30) NULL, -- Temperature ; Cooler percents per Card
#########       	[SHpC]    [nchar](40) NULL, -- Shares per Card
#########       	[time]    [datetime]  NULL, -- Time Stamp
#########       
#########       )
#########       
#########       GO