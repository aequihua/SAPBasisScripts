param (
    [string]$dirtpfiles = "\\dmxsrv-sapdev\transportes",
    [string]$dirtrans = "\\dmxsrv-sapdev\sapmnt\trans",
	[string]$testmode = "yes",
	[string]$destino = "DXQ"
 )
 
# Script que manda llamar a pasatranscript.ps1
# Busca en $dirtpfiles los archivos que existan con extension .tp y los procesa para aplicar los transportes ahi contenidos
# Este script tiene que ser colocado en el directorio \\dmxsrv-sapdev\sapmnt\trans, y ser ejecutado desde el servidor dmxsrv-sapqa o dmxsrv-sappro (segun se quiera usar para calidad o productivo)
# El servidor dmxsrv-sapqa y dmxsrv-sappro deben tener dado de alta el servidor dmxsrv-sapdev en la lista de sites de la zona "Local Intranet" en las opciones de Internet

# get-childitem -path $dirscan -recurse -filter *.tp | select-object name | group {$_.name} | sort name | select-object name,count
$archivos = get-childitem -path $dirtpfiles -recurse -filter *.tp | select-object name | group {$_.name} | sort name
foreach ($file in $archivos)
{
    $file.Name
	$comando = $dirtrans+"\pasatranscript.ps1 -tplistfile " + $dirtpfiles+"\"+$file.Name + " -addbuffer yes -sourcesys "+ $destino + " -sourcesid DXD -destsid " + $destino + " -destclient 300 -testmode "+ $testmode +" -sourcedomain " + $destino + " -tpdomain DXD"
	try {
		$comando 
		Invoke-Expression $comando
	}
	catch {
		"Error al ejecutar el archivo " + $comando
	}
	
}


