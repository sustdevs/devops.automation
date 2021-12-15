$path = 'C:\Program Files (x86)\Google\Chrome\Application'
#$path = 'C:\Program Files\Google\Chrome\Application'

cd $path
$bin = $path + '\chrome.exe'
#Get-Process | Where-Object {$_.Name -match 'chrome'} | foreach{$_.CloseMainWindow()}
Stop-Process -Name chrome

$localapp = $env:localappdata
$chromedata = $localapp + '\Google\Chrome\User Data'
# Write-Host $chromedata

Start-Sleep -Milliseconds 250

##Start-Process -FilePath $bin -ArgumentList "--restore-last-session  --remote-debugging-port=53891 --user-data-dir=`"$chromedata`" --crash-dumps-dir=`"$chromedata`""

Start-Process -FilePath $bin -ArgumentList "--restore-last-session  --remote-debugging-port=53891"
