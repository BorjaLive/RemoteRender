#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <Constants.au3>
#include <Array.au3>
#include "HTTP.au3"
#include "lib.au3"

$serverURL = "http://192.168.1.81/remoteRender"
$blenderBin = "C:\Program Files\Blender Foundation\Blender 2.92\blender.exe"
$tmpFolder = @TempDir&"\RRC"

$started = false
$routineSleep = 0

#Region GUI
$GUI = GUICreate("Remote Render Client", 320, 280)
GUISetState(@SW_SHOW, $GUI)

GUICtrlCreateLabel("URL del servidor", 10, 10)
$GUI_SERVER = GUICtrlCreateInput($serverURL, 10, 25, 300)

GUICtrlCreateLabel("Ejecutable de Blender", 10, 60)
$GUI_BLENDER = GUICtrlCreateInput($blenderBin, 10, 75, 300)

GUICtrlCreateLabel("Carpeta temporal", 10, 110)
$GUI_TMP = GUICtrlCreateInput($tmpFolder, 10, 125, 300)

$GUI_START = GUICtrlCreateButton("Iniciar", 110, 170, 100)

$GUI_OUTPOUT = GUICtrlCreateLabel("Cliente no iniciado", 10, 210, 300, 20, $SS_CENTER)

$GUI_PROGRESS = GUICtrlCreateProgress(10, 240, 300, 30)
#EndRegion

While True
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			ExitLoop
		Case $GUI_START
			startStop()
	EndSwitch
	If $started And $routineSleep == 0 Then routine()
	$routineSleep = mod($routineSleep+1, 100)
	Sleep(10)
WEnd

GUIDelete($GUI)

Func routine()
	act("Buscando trabajo")
	$job = getJob()
	If $job <> null Then
		If FileExists($tmpFolder) Then DirRemove($tmpFolder, 1)
		DirCreate($tmpFolder)
		;_ArrayDisplay($job)
		act("Descargando archivo")
		acceptJob($job[0])
		If downloadFile($job[0]) Then
			ProgressOff()

			updateJobStatus($job[0], "Descomprimiendo")
			act("Descomprimiendo")
			unCompressFiles($job[0])

			updateJobStatus($job[0], "Procesando")
			act("Ejecutando blender")
			runBlender($job, false)

			updateJobStatus($job[0], "Comprimiendo")
			act("Comprimiendo fichero")
			compressFiles($job[0])

			updateJobStatus($job[0], "Subiendo")
			act("Subiendo fichero")
			uploadFile($job[0])
		EndIf
	EndIf
EndFunc

Func startStop()
	$started = Not $started
	If $started Then
		$serverURL = GUICtrlRead($GUI_SERVER)
		$blenderBin = GUICtrlRead($GUI_BLENDER)
		$tmpFolder = GUICtrlRead($GUI_TMP)
		GUICtrlSetData($GUI_START, "Detener")
		act("Cliente iniciado")
	Else
		GUICtrlSetData($GUI_START, "Iniciar")
		act("Cliente no iniciado")
	EndIf

EndFunc

Func getJob()
	$text = HttpGet($serverURL, "action=get")
	$jobs = StringSplit($text, "|", 2)
	For $job in $jobs
		If $job <> "" Then
			$data = StringSplit($job, "]", 2)
			If $data[1] == "Pendiente" Then Return $data
		EndIf
	Next
	Return null
EndFunc
Func acceptJob($name)
	HttpGet($serverURL, "action=update&mod=set&status=Descargando&job="&$name)
EndFunc
Func updateJob($name, $progress)
	HttpGet($serverURL, "action=update&mod=set&status=Procesando&job="&$name&"&progress="&$progress)
EndFunc
Func updateJobStatus($name, $status)
	HttpGet($serverURL, "action=update&mod=set&status="&$status&"&job="&$name&"&progress=0")
EndFunc
Func terminateJob($name)
	HttpGet($serverURL, "action=update&mod=unset&job="&$name)
EndFunc

Func downloadFile($name)
	Return _webDownloader($serverURL&"/DATA/"&$name&".zip", $name&".zip", $name, $tmpFolder, False)
EndFunc

Func runBlender($job, $show = false)
	$command = '"'&$blenderBin&'" -b "'&$tmpFolder&'\'&$job[0]&'.blend" -o //out/ -a'
	$params = StringSplit($job[3], " ", 2)
	$start = Number($params[1])
	$end = Number($params[3])
	$pid = Run($command, $tmpFolder, $show?@SW_SHOW:@SW_HIDE, $STDOUT_CHILD)
	;consoleWrite("Comando: "&$command&@CRLF)
    While 1
        $line = StdoutRead($pid)
        If @error Then ExitLoop
		If StringInStr($line, "Append frame") <> 0 Then
			$parts = StringSplit($line, " ", 2)
			$cur = ((Number($parts[2])-$start)/($end-$start))*100
			updateJob($job[0], $cur)
			GUICtrlSetData($GUI_PROGRESS, $cur)
		EndIf
    WEnd
	GUICtrlSetData($GUI_PROGRESS, 0)
EndFunc

Func unCompressFiles($name)
	$OUTPUT = $tmpFolder&"\"&$name&".7z"
	$pid = RunWait('7za\7za.exe a "'&$OUTPUT&'" "'&$tmpFolder&'\*" -x!"'&$tmpFolder&'\*.blend" -r', @ScriptDir, @SW_HIDE)
EndFunc

Func compressFiles($name)
	$OUTPUT = $tmpFolder&"\"&$name&".7z"
	$pid = RunWait('7za\7za.exe a "'&$OUTPUT&'" "'&$tmpFolder&'\*" -x!"'&$tmpFolder&'\*.blend" -r', @ScriptDir, @SW_HIDE)
EndFunc

Func uploadFile($name)
	$file = $tmpFolder&"\"&$name&".7z"
	$text = _HTTP_Upload($serverURL&"/finishUpload.php?passSecretCode=atornilladorDiscoZumoPlastico", $file, "finishFile")
	ConsoleWrite($text&@CRLF)
	;Cuando la subida termina, notificarlo
	terminateJob($name)
EndFunc

Func act($text)
	GUICtrlSetData($GUI_OUTPOUT, $text)
EndFunc

