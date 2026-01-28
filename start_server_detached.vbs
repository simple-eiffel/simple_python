' VBScript to start Python server detached from parent process
' This uses WScript.Shell which properly handles process isolation on Windows

Dim objShell, strCommand, strServerPath, strPort

Set objShell = CreateObject("WScript.Shell")

' Get the directory where this script is located
strServerPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
strPort = WScript.Arguments(0)

If strPort = "" Then
    strPort = "8889"
End If

' Build command to start Python server
strCommand = "py -3 """ & strServerPath & "\python_test_server.py"" --port " & strPort

' Start process with proper flags:
' 0 = hidden window
' True = wait for process (but we return immediately anyway)
objShell.Run strCommand, 0, False

' Exit immediately - the process runs independently
WScript.Quit(0)
