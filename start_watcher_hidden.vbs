Set objShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = fso.BuildPath(scriptDir, "safe_watch.ps1")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & psScript & """", 0, False
