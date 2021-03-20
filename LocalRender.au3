#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <Constants.au3>
#include <FileConstants.au3>
#include <Array.au3>
#include <File.au3>

$sessionDat = @TempDir&"\LR.ini"

$blenderBin = IniRead($sessionDat, "Config", "BlenderBin", "C:\Program Files\Blender Foundation\Blender 2.92\blender.exe")
$wFolder = IniRead($sessionDat, "Config", "WFolder", @TempDir&"\RRC")

$started = false
$routineSleep = 0

#Region GUI
$GUI = GUICreate("Local Render", 320, 280)

GUICtrlCreateLabel("Ejecutable de Blender", 10, 10)
$GUI_BLENDER = GUICtrlCreateInput($blenderBin, 10, 25, 300)

GUICtrlCreateLabel("Carpeta de trabajo", 10, 60)
$GUI_FOLDER = GUICtrlCreateInput($wFolder, 10, 75, 300)

$GUI_SHUTDOWN = GUICtrlCreateCheckbox("Apagar al terminar", 10, 110, 100)

$GUI_START = GUICtrlCreateButton("Iniciar", 110, 170, 100)

$GUI_OUTPOUT = GUICtrlCreateLabel("Preparado", 10, 210, 300, 20, $SS_CENTER)

$GUI_PROGRESS = GUICtrlCreateProgress(10, 240, 300, 30)

GUISetState(@SW_SHOW, $GUI)
#EndRegion

While True
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			ExitLoop
		Case $GUI_START
			start()
	EndSwitch
	Sleep(10)
WEnd

GUIDelete($GUI)

Func routine()
	act("Buscando ficheros")
	$jobs = _FileListToArray($wFolder, "*.blend", $FLTA_FILES)
	If Not IsArray($jobs) Then Return
	For $cJob = 1 To $jobs[0]
		$job = $Jobs[$cJob]
		$jobName = StringReplace(StringReplace(StringMid($job,StringInStr($job,"/",2,-1) +1), ".blend", ""), " ", "_")
		act("Comenzando "&$jobName)
		$command = '"'&$blenderBin&'" -b "'&$job&'" -o //'&$jobName&'/ -a'
		$pid = Run($command, $wFolder, @SW_HIDE, $STDOUT_CHILD)
		consoleWrite("Comando: "&$command&@CRLF)
		$cFrame = 0
		$oFrame = 0
		While 1
			$line = StdoutRead($pid)
			If @error Then ExitLoop
			If StringInStr($line, "Fra:") <> 0 Then
				$parts = StringSplit($line, " ", 2)
				$cFrame = Number(StringMid($parts[0], 5))
			EndIf
			If StringInStr($line, "Append frame") <> 0 Then
				$parts = StringSplit($line, " ", 2)
				$cFrame = Number($parts[2])
			EndIf
			If $oFrame <> $cFrame Then
				act("Frame: "&$cFrame&" de "&$jobName)
				$oFrame = $cFrame
			EndIf
		WEnd
		GUICtrlSetData($GUI_PROGRESS, ($cJob/$jobs[0])*100)
	Next
EndFunc

Func start()
	GUICtrlSetData($GUI_PROGRESS, 0)
	$blenderBin = GUICtrlRead($GUI_BLENDER)
	$wFolder = GUICtrlRead($GUI_FOLDER)
	IniWrite ($sessionDat, "Config", "BlenderBin", $blenderBin)
	IniWrite ($sessionDat, "Config", "WFolder", $wFolder)
	GUICtrlSetState ($GUI_START, $GUI_DISABLE)
	routine()
	GUICtrlSetData($GUI_START, "Iniciar")
	act("Trabajo terminado")
	GUICtrlSetState ($GUI_START, $GUI_ENABLE)

	If GUICtrlRead($GUI_SHUTDOWN) == $GUI_CHECKED Then
		Shutdown(BitOR($SD_SHUTDOWN, $SD_FORCEHUNG))
	EndIf
EndFunc

Func act($text)
	GUICtrlSetData($GUI_OUTPOUT, $text)
EndFunc


