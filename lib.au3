#include <InetConstants.au3>

Func HttpGet($serverURL, $sData = "")
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    $oHTTP.Open("GET", $serverURL & "/api.php?" & $sData, False)
    $oHTTP.SetTimeouts(50, 50, 50, 50)
    If (@error) Then Return SetError(1, 0, 0)
    $oHTTP.Send()
    If (@error) Then Return SetError(2, 0, 0)
    If ($oHTTP.Status <> 200) Then Return SetError(3, 0, 0)
    Return SetError(0, 0, $oHTTP.ResponseText)
EndFunc   ;==>HttpGet


Func _webDownloader($sSourceURL, $sTargetName, $sVisibleName, $sTargetDir = @TempDir, $bProgressOff = True, $iEndMsgTime = 2000, $sDownloaderTitle = "Descarga")
    ; Declare some general vars
    Local $iMBbytes = 1048576

    ; If the target directory doesn't exist -> create the dir
    If Not FileExists($sTargetDir) Then DirCreate($sTargetDir)

    ; Get download and target info
    Local $sTargetPath = $sTargetDir & "\" & $sTargetName
    Local $iFileSize = InetGetSize($sSourceURL)
    Local $hFileDownload = InetGet($sSourceURL, $sTargetPath, $INET_LOCALCACHE, $INET_DOWNLOADBACKGROUND)

    ; Show progress UI
    ProgressOn($sDownloaderTitle, "Descargando " & $sVisibleName)

    ; Keep checking until download completed
    Do
        Sleep(250)

        ; Set vars
        Local $iDLPercentage = Round(InetGetInfo($hFileDownload, $INET_DOWNLOADREAD) * 100 / $iFileSize, 0)
        Local $iDLBytes = Round(InetGetInfo($hFileDownload, $INET_DOWNLOADREAD) / $iMBbytes, 2)
        Local $iDLTotalBytes = Round($iFileSize / $iMBbytes, 2)

        ; Update progress UI
        If IsNumber($iDLBytes) And $iDLBytes >= 0 Then
            ProgressSet($iDLPercentage, $iDLPercentage & "% - Descargados " & $iDLBytes & " MB of " & $iDLTotalBytes & " MB")
        Else
            ProgressSet(0, "Descargando '" & $sVisibleName & "'")
        EndIf
    Until InetGetInfo($hFileDownload, $INET_DOWNLOADCOMPLETE)

    ; If the download was successfull, return the target location
    If InetGetInfo($hFileDownload, $INET_DOWNLOADSUCCESS) Then
        ProgressSet(100, "Descarga '" & $sVisibleName & "' completada")
        If $bProgressOff Then
            Sleep($iEndMsgTime)
            ProgressOff()
        EndIf
        Return $sTargetPath
    ; If the download failed, set @error and return False
    Else
        Local $errorCode = InetGetInfo($hFileDownload, $INET_DOWNLOADERROR)
        ProgressSet(0, "Descarga '" & $sVisibleName & "' fallido" & @CRLF & "Error: " & $errorCode)
        If $bProgressOff Then
            Sleep($iEndMsgTime)
            ProgressOff()
        EndIf
        SetError(1, $errorCode, False)
    EndIf
EndFunc   ;==>_webDownloader



