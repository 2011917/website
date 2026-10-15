$Port = 8080
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$Def = @'
[DllImport("user32.dll")] public static extern void mouse_event(long f, long dx, long dy, long b, long e);
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
'@
try { $User32 = Add-Type -MemberDefinition $Def -Name U32 -Namespace Win32 -PassThru; [void]$User32::SetProcessDPIAware() } catch {}

$Listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
$Listener.Start()
$IP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.254.*" -and $_.InterfaceAlias -match "Wi-Fi|Ethernet" } | Select-Object -First 1).IPAddress
if (-not $IP) { $IP = "localhost" }
Write-Host "Connect at: http://${IP}:${Port}" -ForegroundColor Cyan

$Page = @"
<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no'>
<style>body{background:#121212;color:#fff;font-family:sans-serif;text-align:center;margin:0;padding:15px}
html,body{height:100%;overflow:hidden}
img{max-width:100%;max-height:70vh;border:2px solid #444;border-radius:6px;cursor:crosshair;object-fit:contain}
.input-box{width:100%;max-width:450px;padding:10px;background:#222;border:1px solid #555;border-radius:8px;color:#fff;text-align:center;font-size:16px;box-sizing:border-box;margin-bottom:5px}
.rc{padding:10px;background:#444;border:1px solid #666;border-radius:8px;color:#fff;font-size:14px;margin-bottom:5px}
.rc.on{background:#b71c1c}</style></head>
<body><button id='rc' class='rc' onclick='toggleRC()'>Right-Click: OFF</button>
<input id='kbd' class='input-box' placeholder='Tap here to type...' autocomplete='off' autocorrect='off' autocapitalize='off' spellcheck='false'>
<img id='s' src='/screenshot.jpg' onclick='c(event)'>
<script>
var kbd=document.getElementById('kbd'),img=document.getElementById('s'),rc=false,rcBtn=document.getElementById('rc');
function toggleRC(){rc=!rc;rcBtn.textContent='Right-Click: '+(rc?'ON':'OFF');rcBtn.className='rc'+(rc?' on':'');}
function c(e){var r=img.getBoundingClientRect();fetch('/click?x='+(e.clientX-r.left)/r.width+'&y='+(e.clientY-r.top)/r.height+'&rc='+rc).then(()=>{setTimeout(refresh,250);if(rc)toggleRC();});}
kbd.addEventListener('keydown',function(e){if(e.key==='Enter'){sendText(this.value);this.value='';}});
function sendText(t){var i=0;function next(){if(i<t.length){fetch('/type?key='+encodeURIComponent(t[i])).then(()=>{i++;setTimeout(next,80);});}}next();}
function refresh(){img.src='/screenshot.jpg?v='+Date.now();}
setInterval(refresh,2000);
</script></body></html>
"@

while ($true) {
    if ($Listener.Pending()) {
        $Client = $Listener.AcceptTcpClient()
        $Stream = $Client.GetStream()
        $Reader = New-Object System.IO.StreamReader($Stream)
        $Request = $Reader.ReadLine()

        if ($Request -match "GET /(.*) HTTP/1.1") {
            $Path = $Matches[1]

            if ($Path -like "screenshot.jpg*") {
                try {
                    try { [void]$User32::SetProcessDPIAware() } catch {}
                    $W=[System.Windows.Forms.SystemInformation]::VirtualScreen.Width
                    $H=[System.Windows.Forms.SystemInformation]::VirtualScreen.Height
                    $L=[System.Windows.Forms.SystemInformation]::VirtualScreen.Left
                    $T=[System.Windows.Forms.SystemInformation]::VirtualScreen.Top
                    $Bmp=New-Object System.Drawing.Bitmap $W,$H
                    $G=[System.Drawing.Graphics]::FromImage($Bmp)
                    $G.CopyFromScreen($L,$T,0,0,$Bmp.Size)
                    $Ms=New-Object System.IO.MemoryStream
                    $Bmp.Save($Ms,[System.Drawing.Imaging.ImageFormat]::Jpeg)
                    $Bytes=$Ms.ToArray()
                    $G.Dispose();$Bmp.Dispose();$Ms.Dispose()
                    $W2=New-Object System.IO.StreamWriter($Stream)
                    $W2.Write("HTTP/1.1 200 OK`r`nContent-Type: image/jpeg`r`nContent-Length: $($Bytes.Length)`r`n`r`n")
                    $W2.Flush()
                    $Stream.Write($Bytes,0,$Bytes.Length)
                } catch {}
                $Client.Close(); continue
            }
            elseif ($Path -match "click\?x=(.*)&y=(.*)&rc=(.*)") {
                $PctX=[double]$Matches[1]; $PctY=[double]$Matches[2]; $Rc=$Matches[3] -eq "true"
                try { [void]$User32::SetProcessDPIAware() } catch {}
                $W=[System.Windows.Forms.SystemInformation]::VirtualScreen.Width
                $H=[System.Windows.Forms.SystemInformation]::VirtualScreen.Height
                $L=[System.Windows.Forms.SystemInformation]::VirtualScreen.Left
                $T=[System.Windows.Forms.SystemInformation]::VirtualScreen.Top
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point([int]($L+$W*$PctX),[int]($T+$H*$PctY))
                if ($User32) {
                    if ($Rc) { $User32::mouse_event(0x0008,0,0,0,0); $User32::mouse_event(0x0010,0,0,0,0) }
                    else { $User32::mouse_event(0x0002,0,0,0,0); $User32::mouse_event(0x0004,0,0,0,0) }
                }
                $W2=New-Object System.IO.StreamWriter($Stream); $W2.Write("HTTP/1.1 200 OK`r`nContent-Length: 2`r`n`r`nOK"); $W2.Flush()
                $Client.Close(); continue
            }
            elseif ($Path -match "type\?key=(.*)") {
                $Key=[System.Net.WebUtility]::UrlDecode($Matches[1])
                if ($Key -eq "Backspace") { [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}") }
                elseif ($Key -eq "Enter") { [System.Windows.Forms.SendKeys]::SendWait("{ENTER}") }
                elseif ($Key -match '^[\+\^%\~\(\)\{\}\[\]]$') { [System.Windows.Forms.SendKeys]::SendWait("{$Key}") }
                elseif ($Key.Length -gt 0) { [System.Windows.Forms.SendKeys]::SendWait($Key) }
                $W2=New-Object System.IO.StreamWriter($Stream); $W2.Write("HTTP/1.1 200 OK`r`nContent-Length: 2`r`n`r`nOK"); $W2.Flush()
                $Client.Close(); continue
            }
            else {
                $W2=New-Object System.IO.StreamWriter($Stream)
                $W2.Write("HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`n`r`n$Page")
                $W2.Flush()
            }
        }
        $Client.Close()
    }
    Start-Sleep -Milliseconds 50
}