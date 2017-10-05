
$Datatable = New-Object System.Data.DataTable
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = $cs
    $SqlConnection.Open()
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    

    $sql ="  select distinct [IP_address] from log "
    #  $sql
    $SqlCmd.CommandText = $sql
    $SqlCmd.Connection = $SqlConnection
    $Reader = $SqlCmd.ExecuteReader()
    $Datatable.Load($Reader)
    $SqlCmd.Dispose()
    $SqlConnection.Close()

foreach ($line in $Datatable)
{

$ip = ""+$line[0].ToString() 
#"10.0.0.4"
$ip

$range = 22,80,443,3389,8080

foreach ($port in $range)

{


 if(Test-Connection -BufferSize 32 -Count 1 -Quiet -ComputerName $ip)

   {

     $socket = new-object System.Net.Sockets.TcpClient($ip, $port)

     If($socket.Connected)

       {

        "$ip listening to port $port"

        $socket.Close() }

         }

 }
 #sleep 1000

 }