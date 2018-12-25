param (
    [string]$sourcepath = "\\dmxsrv-sapdev\sapmnt\trans",
    [string]$tplistfile = "./listatran.txt",
    [string]$addbuffer = "no",	
	[string]$sourcesid = "DXD",
    [string]$destsid = "DXP",
	[string]$destclient = "300",
	[string]$testmode = "yes",
	[string]$sourcesys = "DXP",
	[string]$tpdomain = "DXD"
 )
 
# Este script tiene que ser colocado en el directorio \\dmxsrv-sapdev\sapmnt\trans

$listatran = Get-Content $tplistfile
$tpvalid = 0
$tpinvalid = 0
$tpnoexist = 0
$tpfailed = 0


# Renombrar archivo de entrada hacia archivo de salida con mismo nombre pero agregando timestamp y extension .done
[string]$filePath = $tplistfile;
[string]$directory = [System.IO.Path]::GetDirectoryName($filePath);
[string]$strippedFileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath);
[string]$extension = [System.IO.Path]::GetExtension($filePath);
[string]$newFileName = $strippedFileName + [DateTime]::Now.ToString("yyyyMMdd-HHmmss") + $extension + ".done";
[string]$outfile = [System.IO.Path]::Combine($directory, $newFileName);
Move-Item -LiteralPath $filePath -Destination $outfile;
$outfile

$stream = [System.IO.StreamWriter] $outfile

foreach ($elemento in $listatran) {
	$elemento
	$transporte = $elemento.Trim()
	if ($transporte.Length -eq 10) {
		"Procesando transporte " + $transporte
		$numtran = $transporte.SubString(4,6)
		$sid = $transporte.SubString(0,3)
		$archcofile = $sourcepath + "\cofiles\K" + $numtran + "." + $sid 
		$archdata = $sourcepath + "\data\R" + $numtran + "." + $sid
			
		If ((Test-Path $archcofile) -and (Test-Path $archdata)) {
		# // File exists
			if ($addbuffer -eq "yes") {
				# // Agregar transporte a buffer 
				$comandotp = "e:\usr\sap\"+$sourcesys+"\D01\exe\tp addtobuffer " + $transporte + " " + $destsid + " client=" + $destclient + " pf=" + $sourcepath + "\bin\TP_DOMAIN_"  + $tpdomain + ".PFL"
				$stream.WriteLine($comandotp)
				$comandotp
				if ($testmode -ne "yes")
				{
					Invoke-Expression $comandotp
					if ($LastExitCode -ne 0) {
						"Falla al agregar transporte en buffer!"
					}
				}
			}
			$comandotp = "e:\usr\sap\"+$sourcesys+"\D01\exe\tp import " + $transporte + " " + $destsid + " client=" + $destclient + " u128 pf=" + $sourcepath + "\bin\TP_DOMAIN_"  + $tpdomain + ".PFL"
			$stream.WriteLine($comandotp)
			$comandotp
			if ($testmode -ne "yes")
			{
				Invoke-Expression $comandotp
				if ($LastExitCode -ne 0) {
					"Falla al importar transporte!"
					$stream.WriteLine($transporte+" ,Fail")
					$tpfailed++
				}
				else
				{
					"Transporte aplicado."
					$stream.WriteLine($transporte+" ,Success")
					$tpvalid++
				}
			}
		}Else{
			# // File does not exist
			$tpnoexist++
			"No existen archivos transporte " + $transporte
			$stream.WriteLine($transporte+" ,NonExistent")
			
		}
	}
	else
	{
		"Transporte nomenclatura inválida: " + $transporte
		$stream.WriteLine($transporte," ,Invalid")		
		$tpinvalid++
	}
}

$stream.WriteLine("--------------------------")
$stream.WriteLine("ESTADISTICAS DE PROCESO: ")
$stream.WriteLine("--------------------------")
$stream.WriteLine("Transportes aplicados correctamente: " + $tpvalid)
$stream.WriteLine("Transportes inválidos:   " + $tpinvalid)
$stream.WriteLine("Transportes que no existen: " + $tpnoexist)
$stream.WriteLine("Transportes que pasaron con error: " + $tpfailed)

$stream.close()

# $destinatario = $strippedFileName + "@molineramx.com"
# Enviar correo a solicitante
# Send-MailMessage -From "Transportes <aequihua@molineramx.com>" -To $destinatario -Cc "Arturo <aequihua@molineramx.com>" -Subject "Transportes realizados" -Body "Se adjunta resultado de transportes realizados" -Attachments $outfile -Priority High -dno onFailure -SmtpServer "mail.molineramx.com"


