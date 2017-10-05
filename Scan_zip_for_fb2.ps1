$enb = 'ENCODING="'
$ene = '"?>'
$dee = '</description>'
Add-Type -assembly "system.io.compression.filesystem"
$UTF8 = [System.Text.Encoding]::GetEncoding(65001)
$1251 = [System.Text.Encoding]::GetEncoding(1251)

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


# $libpath = "E:\fb2.Flibusta.Net"
# $libname = "Flibusta"

 $libpath = "E:\lib.rus.ec"
 $libname = "lib.rus.ec"


Get-ChildItem -path $libpath -file -Recurse | foreach {

$zip_name = $_.FullName                       #"C:\dl\FB2Daily\f.fb2.464695-464761.zip"

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = $cs
    $SqlConnection.Open()
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    

    $sql ="  select count(*) from files where [file-name] = '$zip_name' "
    #  $sql
    $SqlCmd.CommandText = $sql
    $SqlCmd.Connection = $SqlConnection
    $resu = $SqlCmd.ExecuteScalar()
    $SqlCmd.Dispose()
    $SqlConnection.Close()
$lineCount = 0
echo ""
echo "================================ $zip_name has SQL count $resu ============================= "
if ($resu -eq '0')
{
$zip = [io.compression.zipfile]::OpenRead($zip_name)
foreach ($file in $zip.Entries) 
    {
    $lineCount = $lineCount+1
    if (($lineCount%100) -eq 0)  {echo ""}
    try {
    $fsize = $file.Length
    $csize = $file.CompressedLength
    $ftime = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    $stream = $file.Open()
        $pre_reader = New-Object IO.StreamReader($stream)
            $a = $pre_reader.ReadLine()
        $pre_reader.Close()
    $stream.Close()
    $a = $a.Replace(' ','').ToUpper()
    $i = $a.IndexOf($enb)
    $j = $a.IndexOf($ene)
    $e=''
    if ($i -gt 0)
        {
        if ($j -gt 0)
            {
            $e = $a.Substring($i+$enb.length,$j-$i-$enb.length)
            }
        }
    
    #echo "$a   $i   $j   $e"
    
    $stream = $file.Open()
    
        if ($e -eq 'UTF-8') 
            {
            $reader = New-Object IO.StreamReader($stream,$UTF8)
            } else
            {
              if ($e -eq 'WINDOWS-1251') 
                  {
                  $reader = New-Object IO.StreamReader($stream,$1251)
                  } else
                      {
                      $reader = New-Object IO.StreamReader($stream)
                      }
            }

        $text = ''
        $line = ''
        while ($line.Indexof($dee) -lt 0)
        {
            $line = $reader.ReadLine()
            $text = $text + $line
        }
        
        $reader.Close()
    $stream.Close()
    
    $i = $text.IndexOf('<description>')
    $j = $text.IndexOf($dee)
    if (($j-$i+$dee.length -le 0) -or ($i -lt 0))
        { echo $text } 
    else
    {
    $d = $text.Substring($i,$j-$i+$dee.length)
    #echo "$i $j"
    $d = $d.Replace('<image l:href','<image href')
    $d = $d.Replace('<a l:href','<a href')
    $d = $d.Replace("’","'")
    $d = $d.Replace('''','’’')
    $d = $d.Replace('<a xlink:href','<a href')
    $d = $d.Replace('<image xlink:href','<image href')
    $d = '<?xml version="1.0"?><FictionBook>'+$d+'<binary content-type="image/jpeg" id="cover.jpg">a</binary></FictionBook>'
    #$d    
    # image xlink:href
    # '
    
    [xml]$book = $d
    
    
    #$f=$book.FictionBook.description.'title-info'.author.'first-name' 
    #$l=$book.FictionBook.description.'title-info'.author.'last-name'
    $f=''
    $t=$book.FictionBook.description.'title-info'.'book-title'
    $la=$book.FictionBook.description.'title-info'.'lang'
    if ($la.Length -gt 5) {$la = $la.Substring(0,5)}
    $a = " "
    $a=$book.FictionBook.description.'title-info'.'annotation'.innertext  # new
    $id=""+$book.FictionBook.description.'document-info'.'id'      # new
    $isbn=""+$book.FictionBook.description.'publish-info'.'isbn'   # new
    $seq = ""
    $seqn = ""
    if ($book.FictionBook.description.'title-info'.'sequence' -ne $null)
    {
        if ($book.FictionBook.description.'title-info'.'sequence'.HasAttributes)
        {
            if ($book.FictionBook.description.'title-info'.'sequence'.name.GetType().ToString() -eq 'System.String')
            {
                $seq=$book.FictionBook.description.'title-info'.'sequence'.Attributes.GetNamedItem('name').Value # new
                $seqn=$book.FictionBook.description.'title-info'.'sequence'.Attributes.GetNamedItem('number').Value # new
            } else
            {
                $seq=$book.FictionBook.description.'title-info'.'sequence'[0].Attributes.GetNamedItem('name').Value # new
                $seqn=$book.FictionBook.description.'title-info'.'sequence'[0].Attributes.GetNamedItem('number').Value # new
            }
        }
    }

    $pattern = '[^0-9]'
    $n=$file.Name.Replace(".fb2","")
    $n=$n -replace $pattern,''
    $z = $zip_name #.Replace("\\","/")
    $seqn=$seqn -replace $pattern,''
    #if ($seqn -eq "") {$seqn="0"}
    
    if ($id.Length -gt 49) {$id = $id.Substring(0,49)}
    if ($isbn.Length -gt 49) {$isbn = $isbn.Substring(0,49)}
    $sql ="INSERT INTO [dbo].[main] ([book-title],[file-name],[number],[size],[date],[annotation],[seq-name],[id],[isbn],[seq-num],[lang],[lib]) VALUES
                                    ('$t',        '$z',       $n,      $fsize,'$ftime','$a',      '$seq',    '$id','$isbn','$seqn','$la','$libname') "
    
    
    $l=''
    ForEach($autor in $book.FictionBook.description.'title-info'.author)
    {
    $l = $l+" : "+($autor.'last-name'+' ').trim()+" "+($autor.'first-name'+' ').trim()+" "+($autor.'middle-name'+' ').trim()
    }

    $tmp = $la+"  "+$n+"   "+$t+"                  "+$l+"                      "+$seq+"   "+$seqn
    

    # Write-Host -NoNewline  $tmp
    # Write-Host -NoNewline "main  "
    SQL_insert($sql)

    ForEach($autor in $book.FictionBook.description.'title-info'.author)
    {
    $l = ""+($autor.'last-name'+' ').trim()+" "+($autor.'first-name'+' ').trim()+" "+($autor.'middle-name'+' ').trim()
    $l = $l.Replace('  ',' ')
    #$f = $f + "|" + $l
    #"INSERT INTO [dbo].[autors] ([number], [autor]) VALUES ($n, '$l') "
    # Write-Host -NoNewline "autor  "
    $sql = "BEGIN
                IF NOT EXISTS (SELECT * FROM [dbo].[autors] WHERE [number] = $n AND [autor] = '$l' AND [lib] = '$libname')
                BEGIN
                    INSERT INTO [dbo].[autors] ([number], [autor], [lib]) VALUES ($n, '$l', '$libname')
                END
            END"
    SQL_insert($sql)
    }


    ForEach($genre in $book.FictionBook.description.'title-info'.genre)
     {
     $g = (' '+$genre).trim()
     #$sql ="INSERT INTO [dbo].[genres] ([number], [genre]) VALUES ($n, '$g') "
     # Write-Host -NoNewline "genre "
     $sql ="BEGIN
                IF NOT EXISTS (SELECT * FROM [dbo].[genres] WHERE [number] = $n AND [genre] = '$g' AND [lib] = '$libname')
                BEGIN
                    INSERT INTO [dbo].[genres] ([number], [genre], [lib]) VALUES ($n, '$g', '$libname')
                END
            END"
     SQL_insert($sql)
     }
    Write-Host -NoNewline "."
    
    }
    } # try
    Catch
{
    Write-Host ""
    Write-Host "******************************************** Exception occurs **********************************"
    Write-Host "*** ErrorMessage = " $_.Exception.Message
    Write-Host "*** FailedItem   = " $_.Exception.ItemName
    Write-Host "*** Book data    = " $tmp
    Write-Host "*** Description  = " $d
    Write-Host "*** Encoding     = " $e
    Write-Host "*** ZIP filename = " $zip_name
    Write-Host "******************************************** End of exception **********************************"
}     
    } # For each item in zip
$zip.Dispose()
    $sql = "BEGIN
                IF NOT EXISTS (select * from files where [file-name] = '$zip_name') 
                BEGIN
                    INSERT INTO [dbo].[files] ([file-name]) VALUES ('$zip_name')
                END
            END"
    SQL_insert($sql)

} # if
else
{
echo "-------------------------------- Skip $zip_name ---------------------------"
}
}
    

