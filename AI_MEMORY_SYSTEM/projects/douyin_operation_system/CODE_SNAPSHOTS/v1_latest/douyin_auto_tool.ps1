param(
    [switch]$SelfTest,
    [switch]$LiveTest,
    [Alias('test-mode')]
    [switch]$TestMode,
    [switch]$CardDebug,
    [string]$ProfileUrl = '',
    [int]$TestLimit = 2,
    [Alias('max-works')]
    [int]$MaxWorks = 30,
    [ValidateSet("public","authorized")]
    [string]$CollectionMode = "public"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ErrorActionPreference = "Stop"
$Script:Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:OutputRoot = Join-Path $Script:Root "output"
$Script:OutputZipRoot = Join-Path $Script:Root "output_zip"
$Script:EdgeProfile = Join-Path $Script:Root ".edge_profile"
$Script:Port = 9222
$Script:EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$Script:Socket = $null
$Script:MsgId = 0
$Script:CurrentPackage = $null
$Script:PreferredCdpUrl = ""
$Script:CollectionMode = "public"
$Script:CardMetadata = @{}
$Script:ProfileWorksText = ""
$Script:TargetProfileName = ""
$Script:TargetDouyinId = ""
$Script:TargetProfilePath = ""
$Script:TargetWorksCount = 0
$Script:PaddleOcrChecked = $false
$Script:PaddleOcrPython = ""
$Script:EffectiveWorkLimit = 0
$Script:IsTestMode = $false
$Script:RunMode = "formal_collection"
$Script:SampleSize = $null
$Script:FormalAcceptance = $true
$Script:RunTimestamp = ""
$Script:CurrentOutputZipPath = ""

function SetRunMode([int]$RequestedLimit, [int]$EffectiveLimit) {
    $isSample = $Script:IsTestMode -or ($RequestedLimit -gt 0 -and $RequestedLimit -lt 30)
    if ($isSample) {
        $Script:RunMode = "sample_check"
        $Script:SampleSize = $EffectiveLimit
        $Script:FormalAcceptance = $false
    } else {
        $Script:RunMode = "formal_collection"
        $Script:SampleSize = $null
        $Script:FormalAcceptance = $true
    }
}

function U([int[]]$Codes) {
    return -join ($Codes | ForEach-Object { [char]$_ })
}

$CN = @{
    verify = (U @(0x9a8c,0x8bc1,0x7801))
    login = (U @(0x767b,0x5f55))
    scanLogin = (U @(0x626b,0x7801,0x767b,0x5f55))
    pleaseLogin = (U @(0x8bf7,0x767b,0x5f55))
    security = (U @(0x5b89,0x5168,0x9a8c,0x8bc1))
    play = (U @(0x64ad,0x653e))
    watch = (U @(0x89c2,0x770b))
    view = (U @(0x6d4f,0x89c8))
    like = (U @(0x70b9,0x8d5e))
    fav = (U @(0x6536,0x85cf))
    comment = (U @(0x8bc4,0x8bba))
    share = (U @(0x5206,0x4eab))
    repost = (U @(0x8f6c,0x53d1))
    address = (U @(0x5730,0x5740))
    location = (U @(0x5b9a,0x4f4d))
    nav = (U @(0x5bfc,0x822a))
    shop = (U @(0x95e8,0x5e97))
    price = (U @(0x4ef7,0x683c))
    howmuch = (U @(0x591a,0x5c11,0x94b1))
    avg = (U @(0x4eba,0x5747))
    package = (U @(0x5957,0x9910))
    discount = (U @(0x4f18,0x60e0))
    groupbuy = (U @(0x56e2,0x8d2d))
    private = (U @(0x79c1,0x4fe1))
    follow = (U @(0x5173,0x6ce8))
}

function Log($Box, [string]$Message) {
    if ($null -eq $Box) {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message"
        return
    }
    if ($Box.InvokeRequired) {
        $Box.Invoke([Action]{ $Box.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $Message`r`n"); $Box.ScrollToCaret() }) | Out-Null
    } else {
        $Box.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $Message`r`n")
        $Box.ScrollToCaret()
        [Windows.Forms.Application]::DoEvents()
    }
}

function SetStatus($Label, [string]$Message) {
    if ($null -eq $Label) {
        Write-Host "[状态] $Message"
        return
    }
    if ($Label.InvokeRequired) {
        $Label.Invoke([Action]{ $Label.Text = $Message }) | Out-Null
    } else {
        $Label.Text = $Message
        [Windows.Forms.Application]::DoEvents()
    }
}

function SetProgress($Bar, [int]$Value, [int]$Maximum) {
    if ($null -eq $Bar) { return }
    if ($Bar.InvokeRequired) {
        $Bar.Invoke([Action]{
            $Bar.Style = [Windows.Forms.ProgressBarStyle]::Continuous
            $Bar.Maximum = [Math]::Max(1, $Maximum)
            $Bar.Value = [Math]::Min([Math]::Max(0, $Value), $Bar.Maximum)
        }) | Out-Null
    } else {
        $Bar.Style = [Windows.Forms.ProgressBarStyle]::Continuous
        $Bar.Maximum = [Math]::Max(1, $Maximum)
        $Bar.Value = [Math]::Min([Math]::Max(0, $Value), $Bar.Maximum)
        [Windows.Forms.Application]::DoEvents()
    }
}

function SafeName([string]$Text, [string]$Fallback) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $Fallback }
    $name = [Regex]::Replace($Text, '[\\/:*?"<>|\r\n\t]+', "_").Trim(" ._")
    if ([string]::IsNullOrWhiteSpace($name)) { return $Fallback }
    if ($name.Length -gt 60) { return $name.Substring(0, 60) }
    return $name
}

function RelPath([string]$Path, [string]$BaseDir) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    try {
        $base = [IO.Path]::GetFullPath($BaseDir).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
        $full = [IO.Path]::GetFullPath($Path)
        $baseUri = [Uri]$base
        $fullUri = [Uri]$full
        return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($fullUri).ToString()).Replace('\','/')
    } catch {
        return $Path.Replace('\','/')
    }
}

function Compact([string]$Text) {
    if ($null -eq $Text) { return "" }
    return ([Regex]::Replace($Text, "\s+", " ")).Trim()
}

function NormalizeUrl([string]$Url) {
    $u = (Compact $Url)
    if ([string]::IsNullOrWhiteSpace($u)) { return "" }
    $u = ($u -split "(\s|%20|%0A|%0D)")[0]
    if ($u.StartsWith("//")) { $u = "https:" + $u }
    if ($u.StartsWith("/")) { $u = "https://www.douyin.com" + $u }
    if ($u -notmatch "^https?://") { return "" }
    try {
        $uri = [Uri]$u
        if ($uri.Host -notmatch "(^|\.)douyin\.com$") { return "" }
        return $uri.AbsoluteUri
    } catch {
        return ""
    }
}

function IsWorkUrl([string]$Url) {
    $clean = NormalizeUrl $Url
    if ([string]::IsNullOrWhiteSpace($clean)) { return $false }
    try {
        $uri = [Uri]$clean
        if ($uri.AbsolutePath -match "^/(video|note)/[0-9]+/?$") { return $true }
        if ($uri.Query -match "(^|[?&])(modal_id|aweme_id)=[0-9]+") { return $true }
        return $false
    } catch {
        return $false
    }
}

function GetWorkId([string]$Url) {
    $clean = NormalizeUrl $Url
    if ([string]::IsNullOrWhiteSpace($clean)) { return "unknown" }
    try {
        $uri = [Uri]$clean
        $m = [Regex]::Match($uri.Query, "(?:modal_id|aweme_id)=([0-9]+)")
        if ($m.Success) { return $m.Groups[1].Value }
        $m = [Regex]::Match($uri.AbsolutePath, "/(?:video|note)/([0-9]+)")
        if ($m.Success) { return $m.Groups[1].Value }
    } catch {}
    return "unknown"
}

function ToNumberString([string]$Text) {
    $t = Compact $Text
    if ([string]::IsNullOrWhiteSpace($t)) { return "" }
    $m = [Regex]::Match($t, "([0-9]+(?:\.[0-9]+)?)\s*([万亿wWkK]?)")
    if (-not $m.Success) { return "" }
    $n = [double]$m.Groups[1].Value
    $unit = $m.Groups[2].Value
    if ($unit -eq "万" -or $unit -eq "w" -or $unit -eq "W") { $n = $n * 10000 }
    elseif ($unit -eq "亿") { $n = $n * 100000000 }
    elseif ($unit -eq "k" -or $unit -eq "K") { $n = $n * 1000 }
    return ([Math]::Round($n)).ToString()
}

function ToIntCount([string]$Text) {
    $n = ToNumberString $Text
    if ([string]::IsNullOrWhiteSpace($n)) { return 0 }
    $parsed = 0
    if ([int]::TryParse($n, [ref]$parsed)) { return $parsed }
    return 0
}

function ExtractStatNumber([string]$Text, [string[]]$Names) {
    $alias = ($Names | ForEach-Object { [Regex]::Escape($_) }) -join "|"
    foreach ($p in @("($alias)\s*[:：]?\s*([0-9]+(?:\.[0-9]+)?\s*[万亿wWkK]?)", "([0-9]+(?:\.[0-9]+)?\s*[万亿wWkK]?)\s*($alias)")) {
        $m = [Regex]::Match($Text, $p)
        if ($m.Success) {
            foreach ($g in $m.Groups) {
                if ($g.Success -and $g.Value -match "[0-9]" -and $g.Value -notmatch "^($alias)$") {
                    return ToNumberString $g.Value
                }
            }
        }
    }
    return ""
}

function FirstUsefulTitle([string]$Title, [string]$Body) {
    $bad = "抖音|Douyin|搜索|关注|粉丝|获赞|作品|推荐|喜欢|合集|短剧|分享主页|下载|私信|评论|收藏|点赞|转发|首页|精选"
    foreach ($candidate in @($Title) + ($Body -split "(`r`n|`n|`r)")) {
        $line = Compact $candidate
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.Length -lt 4 -or $line.Length -gt 120) { continue }
        if ($line -match $bad) { continue }
        if ($line -match "^\d+(\.\d+)?[万亿wWkK]?$") { continue }
        return $line
    }
    return ""
}

function IsBadExtractedTitle([string]$Title) {
    $line = Compact $Title
    if ([string]::IsNullOrWhiteSpace($line)) { return $true }
    if ($line -match "^(0\.75x|1\.0x|1\.25x|1\.5x|1\.75x|2\.0x|3\.0x)+$") { return $true }
    if ($line -match "倍速|清屏|智能|连播|暂停|播放") { return $true }
    return $false
}

function CleanCardTitle([string]$Text) {
    $line = Compact $Text
    $line = Compact ($line -replace "^置顶\s*", "")
    $line = Compact ($line -replace "^[0-9]+(\.[0-9]+)?\s*", "")
    $pinIndex = $line.IndexOf("置顶")
    if ($pinIndex -gt 0) { $line = Compact $line.Substring(0, $pinIndex) }
    if ($line.Length -gt 24) {
        $prefix = $line.Substring(0, [Math]::Min(12, $line.Length))
        $second = $line.IndexOf($prefix, 12)
        if ($second -gt 12) { $line = Compact $line.Substring(0, $second) }
    }
    if ($line.Length -gt 120) { $line = $line.Substring(0, 120) }
    return $line
}

function ExtractCardLikeCount([string]$Text) {
    $line = Compact $Text
    if ([string]::IsNullOrWhiteSpace($line)) { return $null }
    $pin = [Regex]::Match($line, "置顶\s*([0-9]+(?:\.[0-9]+)?\s*[万亿wWkK]?)")
    if ($pin.Success) { return ToNumberString $pin.Groups[1].Value }
    $matches = @([Regex]::Matches($line, "(?<![A-Za-z0-9])([0-9]+(?:\.[0-9]+)?\s*[万亿wWkK]?)(?![A-Za-z0-9])"))
    if ($matches.Count -eq 0) { return $null }
    return ToNumberString $matches[$matches.Count - 1].Groups[1].Value
}

function GetPreciseCardDomMetadata([double]$X, [double]$Y, $FallbackCard) {
    $json = Js @"
JSON.stringify((() => {
  const x = $X, y = $Y;
  let media = document.elementFromPoint(x, y);
  if (!media) return null;
  if (!/^(IMG|VIDEO)$/.test(media.tagName)) {
    const found = media.querySelector && media.querySelector('img,video');
    if (found) media = found;
  }
  if (!/^(IMG|VIDEO)$/.test(media.tagName)) {
    for (let p = media; p && p !== document.body; p = p.parentElement) {
      const found = p.querySelector && p.querySelector('img,video');
      if (found) { media = found; break; }
    }
  }
  const mr = media.getBoundingClientRect();
  let root = media;
  for (let p = media.parentElement; p && p !== document.body; p = p.parentElement) {
    const pr = p.getBoundingClientRect();
    const containsMedia = pr.left <= mr.left + 2 && pr.right >= mr.right - 2 && pr.top <= mr.top + 2 && pr.bottom >= mr.bottom - 2;
    if (!containsMedia) continue;
    if (pr.width > mr.width + 180 || pr.height > mr.height + 240) break;
    const t = (p.innerText || '').replace(/\s+/g, ' ').trim();
    if (t && t.length < 260) root = p;
  }
  const rootRect = root.getBoundingClientRect();
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      const t = (node.nodeValue || '').replace(/\s+/g, ' ').trim();
      if (!t || t.length > 120) return NodeFilter.FILTER_REJECT;
      const p = node.parentElement;
      if (!p) return NodeFilter.FILTER_REJECT;
      const s = getComputedStyle(p);
      if (s.display === 'none' || s.visibility === 'hidden' || Number(s.opacity) === 0) return NodeFilter.FILTER_REJECT;
      return NodeFilter.FILTER_ACCEPT;
    }
  });
  const parts = [];
  while (walker.nextNode()) {
    const node = walker.currentNode;
    const range = document.createRange();
    range.selectNodeContents(node);
    const rects = Array.from(range.getClientRects());
    range.detach();
    for (const r of rects) {
      if (r.width < 1 || r.height < 1) continue;
      const cx = r.left + r.width / 2;
      const cy = r.top + r.height / 2;
      const inCard = cx >= rootRect.left - 4 && cx <= rootRect.right + 4 && cy >= rootRect.top - 4 && cy <= rootRect.bottom + 4;
      if (!inCard) continue;
      parts.push({
        text: (node.nodeValue || '').replace(/\s+/g, ' ').trim(),
        left: Math.round(r.left),
        top: Math.round(r.top),
        width: Math.round(r.width),
        height: Math.round(r.height),
        in_media: cy >= mr.top && cy <= mr.bottom
      });
    }
  }
  parts.sort((a,b) => (a.top-b.top) || (a.left-b.left));
  const text = parts.map(p => p.text).join(' ').replace(/\s+/g, ' ').trim();
  const nums = parts.filter(p => p.in_media && /^[0-9]+(\.[0-9]+)?\s*[万亿wWkK]?$/.test(p.text));
  const like = nums.length ? nums[nums.length - 1].text : '';
  let modalId = '';
  for (let p = root; p && p !== document.body; p = p.parentElement) {
    const attrs = ['href','data-e2e','data-id','data-aweme-id','data-item-id','id'];
    for (const a of attrs) {
      const v = p.getAttribute && (p.getAttribute(a) || '');
      const m = String(v).match(/(?:modal_id|aweme_id|video\/|note\/|^)([0-9]{10,})/);
      if (m) { modalId = m[1]; break; }
    }
    if (!modalId && p.querySelectorAll) {
      for (const a of Array.from(p.querySelectorAll('a')).slice(0,8)) {
        const v = a.href || a.getAttribute('href') || '';
        const m = String(v).match(/(?:modal_id|aweme_id|video\/|note\/)([0-9]{10,})/);
        if (m) { modalId = m[1]; break; }
      }
    }
    if (modalId) break;
  }
  return {
    text,
    public_card_like_count: like,
    is_pinned: /置顶/.test(text),
    modal_id: modalId,
    cover: media.currentSrc || media.src || media.poster || media.getAttribute('src') || '',
    rect: { left: Math.round(mr.left), top: Math.round(mr.top), width: Math.round(mr.width), height: Math.round(mr.height) }
  };
})())
"@
    try {
        if ([string]::IsNullOrWhiteSpace($json) -or $json -eq "null") { return $FallbackCard }
        $meta = $json | ConvertFrom-Json
        if ($null -eq $meta -or [string]::IsNullOrWhiteSpace([string]$meta.text)) { return $FallbackCard }
        return $meta
    } catch {
        return $FallbackCard
    }
}

function StartEdge([string]$OpenUrl = "https://www.douyin.com/") {
    if (!(Test-Path $Script:EdgePath)) { throw "未找到 Microsoft Edge。" }
    $profileExists = Test-Path $Script:EdgeProfile
    New-Item -ItemType Directory -Force -Path $Script:EdgeProfile | Out-Null
    Start-Process -FilePath $Script:EdgePath -ArgumentList @(
        "--remote-debugging-port=$Script:Port",
        "--user-data-dir=$Script:EdgeProfile",
        "--no-first-run",
        $OpenUrl
    ) | Out-Null
    Start-Sleep -Seconds 2
    return $profileExists
}

function ConnectCdp([string]$PreferredUrl = "") {
    if ($Script:Socket) {
        try { $Script:Socket.Dispose() } catch {}
        $Script:Socket = $null
    }
    $tabs = Invoke-RestMethod -Uri "http://127.0.0.1:$Script:Port/json/list" -TimeoutSec 8
    $pages = @($tabs | Where-Object { $_.type -eq "page" })
    $tab = $null
    if (-not [string]::IsNullOrWhiteSpace($PreferredUrl)) {
        $preferred = NormalizeUrl $PreferredUrl
        $tab = @($pages | Where-Object { $_.url -eq $preferred -or $_.url -like "$preferred*" } | Select-Object -First 1)[0]
    }
    if ($null -eq $tab) {
        $tab = @($pages | Where-Object { $_.url -match "douyin\.com/user/" } | Select-Object -First 1)[0]
    }
    if ($null -eq $tab) {
        $tab = @($pages | Where-Object { $_.url -match "douyin\.com" } | Select-Object -First 1)[0]
    }
    if ($null -eq $tab) {
        $tab = @($pages | Select-Object -First 1)[0]
    }
    if ($null -eq $tab) { throw "没有找到可连接的 Edge 页面。" }
    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $ws.ConnectAsync([Uri]$tab.webSocketDebuggerUrl, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
    $Script:Socket = $ws
}

function ReceiveCdp {
    $buffer = New-Object byte[] 1048576
    $stream = [IO.MemoryStream]::new()
    do {
        $seg = [ArraySegment[byte]]::new($buffer)
        $res = $Script:Socket.ReceiveAsync($seg, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
        if ($res.Count -gt 0) { $stream.Write($buffer, 0, $res.Count) }
    } while (-not $res.EndOfMessage)
    $json = [Text.Encoding]::UTF8.GetString($stream.ToArray())
    if ([string]::IsNullOrWhiteSpace($json)) { return $null }
    return $json | ConvertFrom-Json
}

function Cdp([string]$Method, $Params = @{}) {
    for ($attempt = 0; $attempt -lt 2; $attempt++) {
        try {
            if ($null -eq $Script:Socket -or $Script:Socket.State -ne [Net.WebSockets.WebSocketState]::Open) {
                ConnectCdp $Script:PreferredCdpUrl
            }
            $Script:MsgId++
            $id = $Script:MsgId
            $payload = @{ id = $id; method = $Method; params = $Params } | ConvertTo-Json -Depth 30 -Compress
            $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
            $Script:Socket.SendAsync([ArraySegment[byte]]::new($bytes), [Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
            while ($true) {
                $msg = ReceiveCdp
                if ($null -ne $msg -and $msg.id -eq $id) {
                    if ($msg.error) { throw $msg.error.message }
                    return $msg.result
                }
            }
        } catch {
            if ($attempt -eq 0) {
                try {
                    ConnectCdp $Script:PreferredCdpUrl
                } catch {
                    try {
                        StartEdge $(if ([string]::IsNullOrWhiteSpace($Script:PreferredCdpUrl)) { "https://www.douyin.com/" } else { $Script:PreferredCdpUrl }) | Out-Null
                        Start-Sleep -Seconds 2
                        ConnectCdp $Script:PreferredCdpUrl
                    } catch {}
                }
                Start-Sleep -Milliseconds 500
                continue
            }
            throw "与 Edge 的调试连接中断，请关闭多余的 Edge 标签页后重新点击开始。原始错误：$($_.Exception.Message)"
        }
    }
}

function Js([string]$Expression) {
    $r = Cdp "Runtime.evaluate" @{ expression = $Expression; awaitPromise = $true; returnByValue = $true }
    return $r.result.value
}

function Nav([string]$Url) {
    $target = NormalizeUrl $Url
    if ([string]::IsNullOrWhiteSpace($target)) {
        throw "无效链接，已跳过：$Url"
    }
    Cdp "Page.navigate" @{ url = $target } | Out-Null
    Start-Sleep -Seconds 5
}

function NavFast([string]$Url) {
    $target = NormalizeUrl $Url
    if ([string]::IsNullOrWhiteSpace($target)) {
        throw "无效链接，已跳过：$Url"
    }
    Cdp "Page.navigate" @{ url = $target } | Out-Null
    for ($wait = 0; $wait -lt 20; $wait++) {
        Start-Sleep -Milliseconds 150
        [Windows.Forms.Application]::DoEvents()
        $ready = Js "document.readyState"
        $current = Compact (Js "location.href")
        if (($ready -eq "interactive" -or $ready -eq "complete") -and $current -match "douyin\.com/user/") {
            break
        }
    }
}

function NavHardHome([string]$Url) {
    $target = NormalizeUrl $Url
    if ([string]::IsNullOrWhiteSpace($target)) {
        throw "无效链接，已跳过：$Url"
    }
    Cdp "Page.navigate" @{ url = $target } | Out-Null
    for ($wait = 0; $wait -lt 35; $wait++) {
        Start-Sleep -Milliseconds 200
        [Windows.Forms.Application]::DoEvents()
        $ready = Js "document.readyState"
        $current = Compact (Js "location.href")
        $cards = CountVisibleWorkCards
        if (($ready -eq "interactive" -or $ready -eq "complete") -and $current -match "douyin\.com/user/" -and $cards -gt 0) {
            break
        }
    }
}

function WaitManual($LogBox) {
    $deadline = (Get-Date).AddMinutes(5)
    $announced = $false
    while ((Get-Date) -lt $deadline) {
        $needsManual = Js "(()=>{const re=/(扫码登录|请登录|登录后|安全验证|验证码|拖动滑块|验证身份|账号异常)/;const els=Array.from(document.querySelectorAll('body *'));for(const el of els){const r=el.getBoundingClientRect();if(r.width<80||r.height<20||r.bottom<0||r.right<0||r.top>innerHeight||r.left>innerWidth)continue;const s=getComputedStyle(el);if(s.visibility==='hidden'||s.display==='none'||Number(s.opacity)===0)continue;const t=(el.innerText||'').replace(/\s+/g,' ').trim();if(t&&t.length<260&&re.test(t))return true;}return false})()"
        if (-not [bool]$needsManual) { return }
        if (-not $announced) {
            Log $LogBox "检测到登录或验证提示，请先在 Edge 中手动完成；最多等待 5 分钟。"
            $announced = $true
        }
        Start-Sleep -Seconds 5
    }
    Log $LogBox "登录/验证等待结束，继续读取当前可见页面。"
}

function WorkLinkScanJs {
    return "JSON.stringify((()=>{const out=[];const add=v=>{if(v&&!out.includes(v))out.push(v)};document.querySelectorAll('a').forEach(a=>{add(a.href);add(a.getAttribute('href'))});const html=document.documentElement.innerHTML;for(const m of html.matchAll(/https?:\/\/(?:www\.)?douyin\.com\/(?:video|note)\/[0-9]+/g))add(m[0]);for(const m of html.matchAll(/\/(?:video|note)\/[0-9]+/g))add(m[0]);for(const m of html.matchAll(/(?:modal_id|aweme_id)=([0-9]{6,})/g))add(location.origin+location.pathname+'?modal_id='+m[1]);return out})())"
}

function CountVisibleWorkLinks {
    $json = Js (WorkLinkScanJs)
    $links = @($json | ConvertFrom-Json)
    $count = 0
    foreach ($href in $links) {
        $clean = NormalizeUrl ([string]$href)
        if (-not [string]::IsNullOrWhiteSpace($clean) -and (IsWorkUrl $clean)) {
            $count++
        }
    }
    return $count
}

function CountVisibleWorkCards {
    $count = Js "(()=>{const seen=[];const cards=[];const els=Array.from(document.querySelectorAll('div,li,a'));for(const el of els){const r=el.getBoundingClientRect();if(r.width<120||r.height<120||r.top<250||r.bottom<0||r.left<80)continue;if(!el.querySelector('img,video'))continue;const key=Math.round(r.left)+'_'+Math.round(r.top)+'_'+Math.round(r.width)+'_'+Math.round(r.height);if(seen.includes(key))continue;seen.push(key);cards.push(el)}return cards.length})()"
    if ($null -eq $count) { return 0 }
    return [int]$count
}

function HasVideoOverlay {
    $flag = Js "(()=>{const v=document.querySelector('video');if(!v)return false;const r=v.getBoundingClientRect();return r.width>300&&r.height>300&&r.top<260})()"
    return [bool]$flag
}

function CardScanJs([string]$SkipIdsJson = "[]") {
    $skipB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($SkipIdsJson))
    return "JSON.stringify((()=>{const skip=new Set(JSON.parse(atob('$skipB64')));const seen=[];const cards=[];const vw=window.innerWidth||1200;const vh=window.innerHeight||800;const medias=Array.from(document.querySelectorAll('img,video'));for(const media of medias){const mr=media.getBoundingClientRect();if(mr.width<90||mr.width>430||mr.height<110||mr.height>580)continue;if(mr.top<240||mr.bottom>vh-10||mr.right<90||mr.left>vw-40)continue;let el=media;for(let p=media.parentElement;p&&p!==document.body;p=p.parentElement){const pr=p.getBoundingClientRect();if(pr.width>520||pr.height>760)break;const t=(p.innerText||'').replace(/\s+/g,' ').trim();if(t&&pr.width>=mr.width*0.8&&pr.height>=mr.height*0.8&&pr.width<=mr.width+130&&pr.height<=mr.height+190){el=p}}const r=el.getBoundingClientRect();const cx=Math.round(mr.left+mr.width/2);const cy=Math.round(mr.top+mr.height/2);if(cx<=50||cx>vw-10||cy<=240||cy>vh-10)continue;const pointed=document.elementFromPoint(cx,cy);if(!pointed)continue;const grid=[Math.round(mr.top/80)|0,Math.round((mr.left+mr.width/2)/80)].join('_');const viewGrid='viewport_'+Math.round(cx/40)+'_'+Math.round(cy/40);const texts=[];const add=t=>{t=(t||'').replace(/\s+/g,' ').trim();if(t&&t.length<140&&!texts.includes(t))texts.push(t)};Array.from(document.querySelectorAll('span,div,p')).forEach(node=>{const tr=node.getBoundingClientRect();if(tr.width<2||tr.width>mr.width+45||tr.height<2||tr.height>90) return;const tx=tr.left+tr.width/2;const ty=tr.top+tr.height/2;if(tx>=mr.left-12&&tx<=mr.right+12&&ty>=mr.top-16&&ty<=mr.bottom+100){add(node.innerText)}});const txt=(texts.join(' ')||media.alt||'').replace(/\s+/g,' ').trim();const img=(media.currentSrc||media.src||media.poster||media.alt||'').slice(0,180);const sig=((txt||img||grid).slice(0,160)+'_'+img.slice(-60)+'_'+Math.round(mr.width)+'x'+Math.round(mr.height)).replace(/\s+/g,' ');if(seen.includes(grid)||skip.has(sig)||skip.has(viewGrid))continue;seen.push(grid);cards.push({sig,top:mr.top,vtop:mr.top,left:mr.left,width:mr.width,height:mr.height,cx,cy,text:txt,img:(media.currentSrc||media.src||media.poster||media.alt||'')})}cards.sort((a,b)=>(a.top-b.top)||(a.left-b.left));return cards})())"
}

function GetVisibleCards([string[]]$SkipIds) {
    $skipJson = ConvertToJsonArray $SkipIds 5
    $json = Js (CardScanJs $skipJson)
    if ([string]::IsNullOrWhiteSpace($json)) { return @() }
    return @($json | ConvertFrom-Json)
}

function CardGridKey($Card) {
    $cx = [Math]::Round((AsDouble $Card.cx) / 40)
    $cy = [Math]::Round((AsDouble $Card.cy) / 40)
    return "viewport_$cx`_$cy"
}

function IsTargetProfileCard($Card) {
    $text = Compact ([string]$Card.text)
    if ([string]::IsNullOrWhiteSpace($text)) { return $false }
    if ([string]::IsNullOrWhiteSpace($Script:ProfileWorksText)) { return $true }
    $clean = Compact ($text -replace "^置顶\s*", "" -replace "^[0-9]+(\.[0-9]+)?\s*", "")
    if ($clean.Length -lt 4) { return $false }
    if ($Script:ProfileWorksText.Contains($clean)) { return $true }
    $tokens = @([Regex]::Matches($clean, "[\u4e00-\u9fffA-Za-z0-9#]{4,}") | ForEach-Object { $_.Value })
    foreach ($token in $tokens) {
        if ($Script:ProfileWorksText.Contains($token)) { return $true }
    }
    return $false
}

function ShortPreview([string]$Text, [int]$Max = 90) {
    $preview = Compact $Text
    if ($preview.Length -gt $Max) { return $preview.Substring(0, $Max) }
    return $preview
}

function GetOpenedWorkSnapshot {
    $json = Js @"
JSON.stringify((() => {
  const visible = (document.body ? document.body.innerText : '').replace(/\s+/g, ' ').trim();
  const isShown = el => {
    const r = el.getBoundingClientRect();
    if (r.width < 1 || r.height < 1 || r.bottom < 0 || r.right < 0 || r.top > innerHeight || r.left > innerWidth) return false;
    const s = getComputedStyle(el);
    if (s.visibility === 'hidden' || s.display === 'none' || Number(s.opacity) === 0) return false;
    const x = Math.max(1, Math.min(innerWidth - 2, r.left + Math.min(r.width / 2, 80)));
    const y = Math.max(1, Math.min(innerHeight - 2, r.top + Math.min(r.height / 2, 30)));
    const p = document.elementFromPoint(x, y);
    return !!p && (el === p || el.contains(p) || p.contains(el));
  };
  const videos = Array.from(document.querySelectorAll('video')).map(v => ({ el: v, r: v.getBoundingClientRect() }))
    .filter(v => v.r.width > 240 && v.r.height > 240 && v.r.bottom > 0 && v.r.right > 0)
    .sort((a,b) => (b.r.width*b.r.height) - (a.r.width*a.r.height));
  const vr = videos[0] ? videos[0].r : { left: 0, right: innerWidth, top: 0, bottom: innerHeight };
  const nearVideo = el => {
    const r = el.getBoundingClientRect();
    const horizontal = r.right >= vr.left - 360 && r.left <= vr.right + 360;
    const vertical = r.bottom >= vr.top - 120 && r.top <= vr.bottom + 220;
    return horizontal && vertical;
  };
  const textEls = Array.from(document.querySelectorAll('a,span,div,p,h1,h2,h3,strong,em'))
    .filter(el => nearVideo(el) && isShown(el))
    .map(el => {
      const r = el.getBoundingClientRect();
      return {
        tag: el.tagName,
        href: el.tagName === 'A' ? (el.href || el.getAttribute('href') || '') : '',
        text: (el.innerText || el.getAttribute('aria-label') || '').replace(/\s+/g, ' ').trim(),
        left: Math.round(r.left),
        top: Math.round(r.top),
        width: Math.round(r.width),
        height: Math.round(r.height)
      };
    })
    .filter(x => x.text && x.text.length <= 260);
  const links = textEls.filter(x => x.href);
  const foreground = textEls.map(x => x.text).join(' ').replace(/\s+/g, ' ').trim();
  const avatarAlts = Array.from(document.querySelectorAll('img')).slice(0, 200)
    .filter(img => nearVideo(img) && isShown(img))
    .map(img => (img.alt || img.getAttribute('aria-label') || '').replace(/\s+/g, ' ').trim())
    .filter(Boolean);
  return { url: location.href, title: document.title || '', visible, foreground, links, avatarAlts };
})())
"@
    if ([string]::IsNullOrWhiteSpace($json)) { return $null }
    return ($json | ConvertFrom-Json)
}

function TestOpenedWorkBelongsToTarget([string]$Url, $LogBox) {
    if ([string]::IsNullOrWhiteSpace($Script:TargetProfileName) -and [string]::IsNullOrWhiteSpace($Script:TargetDouyinId) -and [string]::IsNullOrWhiteSpace($Script:TargetProfilePath)) {
        Log $LogBox "未提取到目标账号身份，无法做作者强校验；为避免混入推荐视频，本轮跳过该候选。"
        return $false
    }
    $targetName = Compact $Script:TargetProfileName
    $targetId = Compact $Script:TargetDouyinId
    $targetPath = Compact $Script:TargetProfilePath
    for ($try = 0; $try -lt 10; $try++) {
        [Windows.Forms.Application]::DoEvents()
        $current = Compact (Js "location.href")
        if (IsWorkUrl $current) { break }
        Start-Sleep -Milliseconds 250
    }
    $snap = GetOpenedWorkSnapshot
    if ($null -eq $snap) { return $false }
    $text = Compact ([string]$snap.foreground)
    $all = Compact (($text + " " + (($snap.links | ForEach-Object { "$($_.href) $($_.text)" }) -join " ") + " " + (($snap.avatarAlts | ForEach-Object { $_ }) -join " ")))

    if (-not [string]::IsNullOrWhiteSpace($targetName) -and $all.Contains($targetName)) { return $true }
    if (-not [string]::IsNullOrWhiteSpace($targetName)) {
        $targetAliases = @($targetName -split "[|｜/]" | ForEach-Object {
            Compact (($_ -replace "官方号$", "") -replace "认证徽章|商家认证账号|企业认证账号", "")
        } | Where-Object { $_.Length -ge 2 } | Select-Object -Unique)
        foreach ($alias in $targetAliases) {
            if ($all.Contains($alias) -or $all.Contains("@$alias")) { return $true }
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($targetId) -and $all.Contains($targetId)) { return $true }
    if (-not [string]::IsNullOrWhiteSpace($targetPath)) {
        foreach ($link in @($snap.links)) {
            $href = [string]$link.href
            if ($href -match [Regex]::Escape($targetPath)) { return $true }
        }
    }

    $authorHints = @()
    foreach ($m in [Regex]::Matches($text, "@[^\s，。|/]{2,30}")) {
        $authorHints += $m.Value
        if ($authorHints.Count -ge 3) { break }
    }
    $reason = if ($authorHints.Count) { $authorHints -join " / " } else { ShortPreview $text 80 }
    Log $LogBox "打开后作者归属不一致，已跳过该作品。页面作者/文本：$reason"
    return $false
}

function AsDouble($Value) {
    if ($null -eq $Value) { return 0.0 }
    if ($Value -is [array]) { $Value = $Value[0] }
    $text = [string]$Value
    $parsed = 0.0
    if ([double]::TryParse($text, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return $parsed
    }
    return 0.0
}

function WaitProfileReady([string]$HomeUrl, $LogBox) {
    $deadline = (Get-Date).AddMinutes(3)
    $lastLog = [DateTime]::MinValue
    while ((Get-Date) -lt $deadline) {
        [Windows.Forms.Application]::DoEvents()
        $currentUrl = Compact (Js "location.href")
        $workCount = CountVisibleWorkLinks
        $cardCount = CountVisibleWorkCards
        if ($currentUrl -match "douyin\.com/user/" -and ($workCount -gt 0 -or $cardCount -gt 0)) {
            Log $LogBox "已检测到主页作品列表，准备开始采集。"
            return
        }
        if (((Get-Date) - $lastLog).TotalSeconds -ge 10) {
            Log $LogBox "正在自动检查主页状态：当前可见作品链接 $workCount 条，作品卡片 $cardCount 个。若未登录，请在 Edge 中完成登录。"
            $lastLog = Get-Date
        }
        Start-Sleep -Seconds 2
    }
    throw "未检测到主页作品列表。请确认 Edge 已登录，并且当前页面停留在目标账号主页。"
}

function ClickWorkCardAndGetUrl([double]$X, [double]$Y) {
    $beforeUrl = Compact (Js "location.href")
    $clicked = Js "(()=>{const x=$X,y=$Y;let el=document.elementFromPoint(x,y);if(!el)return false;let clickable=el;for(let p=el;p&&p!==document.body;p=p.parentElement){const r=p.getBoundingClientRect();if((p.tagName==='A'||p.querySelector('img,video'))&&r.width>=100&&r.height>=120&&r.width<=500&&r.height<=700){clickable=p;break}}clickable.dispatchEvent(new MouseEvent('mouseover',{bubbles:true,clientX:x,clientY:y}));clickable.dispatchEvent(new MouseEvent('mousemove',{bubbles:true,clientX:x,clientY:y}));clickable.dispatchEvent(new MouseEvent('mousedown',{bubbles:true,clientX:x,clientY:y}));clickable.dispatchEvent(new MouseEvent('mouseup',{bubbles:true,clientX:x,clientY:y}));clickable.click();return true})()"
    if (-not $clicked) { return "" }
    $url = ""
    for ($wait = 0; $wait -lt 15; $wait++) {
        Start-Sleep -Milliseconds 180
        [Windows.Forms.Application]::DoEvents()
        $url = Compact (Js "location.href")
        if ($url -ne $beforeUrl -and (IsWorkUrl $url)) { break }
    }
    return (NormalizeUrl $url)
}

function ReturnToProfileFast([string]$HomeUrl, [int]$ScrollTop) {
    try {
        Js "try { history.back(); } catch(e) {}; true" | Out-Null
        for ($i = 0; $i -lt 8; $i++) {
            Start-Sleep -Milliseconds 180
            [Windows.Forms.Application]::DoEvents()
            $current = Compact (Js "location.href")
            if ($current -match "douyin\.com/user/" -and $current -notmatch "modal_id=|aweme_id=|/video/|/note/" -and -not (HasVideoOverlay)) {
                return
            }
        }
        Cdp "Input.dispatchKeyEvent" @{ type = "rawKeyDown"; windowsVirtualKeyCode = 27; nativeVirtualKeyCode = 27; code = "Escape"; key = "Escape" } | Out-Null
        Cdp "Input.dispatchKeyEvent" @{ type = "keyUp"; windowsVirtualKeyCode = 27; nativeVirtualKeyCode = 27; code = "Escape"; key = "Escape" } | Out-Null
        for ($i = 0; $i -lt 8; $i++) {
            Start-Sleep -Milliseconds 180
            [Windows.Forms.Application]::DoEvents()
            $current = Compact (Js "location.href")
            if ($current -match "douyin\.com/user/" -and $current -notmatch "modal_id=|aweme_id=|/video/|/note/" -and -not (HasVideoOverlay)) {
                return
            }
        }
    } catch {}
    NavHardHome $HomeUrl
    ScrollProfileWorks $ScrollTop
    Start-Sleep -Milliseconds 700
}

function ScrollProfileWorks([int]$ScrollTop) {
    Js @"
(()=> {
  const y = $ScrollTop;
  window.scrollTo(0, y);
  const nodes = Array.from(document.querySelectorAll('body, body *'));
  const scrollables = nodes.filter(el => {
    try {
      const s = getComputedStyle(el);
      return (el.scrollHeight - el.clientHeight > 200) && /(auto|scroll|overlay)/.test(s.overflowY + s.overflow);
    } catch(e) { return false; }
  }).sort((a,b)=>(b.scrollHeight-b.clientHeight)-(a.scrollHeight-a.clientHeight)).slice(0,6);
  for (const el of scrollables) {
    try { el.scrollTop = y; } catch(e) {}
  }
  window.dispatchEvent(new Event('scroll', {bubbles: true}));
  return {windowY: window.scrollY, scrollers: scrollables.map(el => ({top: el.scrollTop, max: el.scrollHeight - el.clientHeight}))};
})()
"@ | Out-Null
}

function NudgeProfileWorks([int]$Delta = 220) {
    Js @"
(()=> {
  const delta = $Delta;
  const x = Math.max(120, Math.min(window.innerWidth - 120, Math.floor(window.innerWidth / 2)));
  const y = Math.max(260, Math.min(window.innerHeight - 80, Math.floor(window.innerHeight * 0.72)));
  const target = document.elementFromPoint(x, y) || document.body;
  try {
    target.dispatchEvent(new WheelEvent('wheel', {deltaY: delta, clientX: x, clientY: y, bubbles: true, cancelable: true}));
  } catch(e) {}
  try { window.scrollBy(0, Math.round(delta * 0.35)); } catch(e) {}
  return true;
})()
"@ | Out-Null
}

function GetProfileScrollTop {
    $value = Js @"
(()=> {
  const vals = [];
  try { vals.push(window.scrollY || 0); } catch(e) {}
  try { vals.push((document.scrollingElement && document.scrollingElement.scrollTop) || 0); } catch(e) {}
  try {
    const nodes = Array.from(document.querySelectorAll('body, body *'));
    const scrollables = nodes.filter(el => {
      try {
        const s = getComputedStyle(el);
        return (el.scrollHeight - el.clientHeight > 200) && /(auto|scroll|overlay)/.test(s.overflowY + s.overflow);
      } catch(e) { return false; }
    });
    for (const el of scrollables) vals.push(el.scrollTop || 0);
  } catch(e) {}
  return Math.round(Math.max(0, ...vals));
})()
"@
    if ($null -eq $value) { return 0 }
    return [int]$value
}

function CollectLinksByClickingCards([string]$HomeUrl, [int]$Limit, $LogBox) {
    $works = New-Object System.Collections.Generic.List[string]
    $visitedCards = New-Object System.Collections.Generic.List[string]
    $visitedViewportSlots = New-Object System.Collections.Generic.List[string]
    $scrollTop = 0
    $emptyRounds = 0
    for ($round = 0; $round -lt 160 -and $works.Count -lt $Limit -and $emptyRounds -lt 24; $round++) {
        $beforeCount = $works.Count
        $currentPage = Compact (Js "location.href")
        $hasOverlay = HasVideoOverlay
        if ($currentPage -notmatch "douyin\.com/user/" -or $currentPage -match "modal_id=|aweme_id=|/video/|/note/" -or $hasOverlay) {
            Log $LogBox "检测到当前不在主页作品列表，强制返回主页继续。"
            ReturnToProfileFast $HomeUrl $scrollTop
        }
        $skipNow = @($visitedCards.ToArray()) + @($visitedViewportSlots.ToArray())
        $cards = @(GetVisibleCards $skipNow | Where-Object {
            (AsDouble $_.cx) -gt 50 -and (AsDouble $_.cy) -gt 240
        })
        if ($cards.Count -eq 0) {
            $scrollTop += 180
            $visitedViewportSlots.Clear()
            Log $LogBox "当前视窗没有下一张未采卡片，小步下滑到 $scrollTop 后继续按视觉顺序扫描。"
            ScrollProfileWorks $scrollTop
            NudgeProfileWorks 220
            $actualScrollTop = GetProfileScrollTop
            if ($actualScrollTop -gt $scrollTop) { $scrollTop = $actualScrollTop }
            [Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 650
            $skipNow = @($visitedCards.ToArray()) + @($visitedViewportSlots.ToArray())
            $cards = @(GetVisibleCards $skipNow | Where-Object {
                (AsDouble $_.cx) -gt 50 -and (AsDouble $_.cy) -gt 240
            })
            if ($cards.Count -eq 0) {
                $emptyRounds++
                continue
            }
        }
        Log $LogBox "备用方式：当前可点击候选卡片 $($cards.Count) 个。"
        $card = $cards[0]
        $visitedCards.Add([string]$card.sig)
        $visitedViewportSlots.Add((CardGridKey $card))
        if (-not (IsTargetProfileCard $card)) {
            $preview = ShortPreview ([string]$card.text) 80
            Log $LogBox "跳过非目标账号作品卡片：$preview"
            $emptyRounds++
            continue
        }
        $x = [Math]::Round((AsDouble $card.cx))
        $y = [Math]::Round((AsDouble $card.cy))
        $preciseCard = GetPreciseCardDomMetadata $x $y $card
        $preciseText = Compact ([string]$preciseCard.text)
        $preciseLike = ToNumberString ([string]$preciseCard.public_card_like_count)
        Log $LogBox "备用方式：按页面顺序点击候选卡片，坐标 $x,$y。"
        $url = ClickWorkCardAndGetUrl $x $y
            if (IsWorkUrl $url) {
                if (-not (TestOpenedWorkBelongsToTarget $url $LogBox)) {
                    Log $LogBox "该作品不是目标账号发布，未加入队列：$url"
                    ReturnToProfileFast $HomeUrl $scrollTop
                    $emptyRounds++
                    continue
                }
                if (-not $works.Contains($url)) {
                    $works.Add($url)
                    $wid = GetWorkId $url
                    $cardModalId = Compact ([string]$preciseCard.modal_id)
                    if ([string]::IsNullOrWhiteSpace($cardModalId)) { $cardModalId = $wid }
                    if (-not [string]::IsNullOrWhiteSpace($wid)) {
                        $visualOrder = $works.Count
                        $Script:CardMetadata[$wid] = [ordered]@{
                            visual_order = $visualOrder
                            is_pinned = ([string]$preciseText -match "置顶")
                            card_text = CleanCardTitle $preciseText
                            public_card_like_count = $preciseLike
                            public_card_like_source = "homepage_card"
                            modal_id = $cardModalId
                            opened_modal_id_from_click = $wid
                            row = ([Math]::Floor(($visualOrder - 1) / 6) + 1)
                            col = ((($visualOrder - 1) % 6) + 1)
                            cover = $(if ($preciseCard.cover) { [string]$preciseCard.cover } else { [string]$card.img })
                            card_bbox = [ordered]@{
                                left = [Math]::Round((AsDouble $card.left))
                                top = [Math]::Round((AsDouble $card.top))
                                width = [Math]::Round((AsDouble $card.width))
                                height = [Math]::Round((AsDouble $card.height))
                            }
                            card_position = [ordered]@{ x = $x; y = $y; sig = [string]$card.sig }
                        }
                    }
                    Log $LogBox "通过点击卡片获得作品链接：$url"
                } else {
                    Log $LogBox "该作品链接已采集，跳过重复卡片：$url"
                }
            } else {
                Log $LogBox "该卡片未打开有效作品链接，继续下一个候选卡片。"
            }
            ReturnToProfileFast $HomeUrl $scrollTop
        Log $LogBox "已返回主页作品列表，继续下一个候选。"
        if ($works.Count -eq $beforeCount) {
            $emptyRounds++
        } else {
            $emptyRounds = 0
        }
    }
    return $works.ToArray()
}

function ExtractStat([string]$Text, [string[]]$Names) {
    $alias = ($Names | ForEach-Object { [Regex]::Escape($_) }) -join "|"
    foreach ($p in @("($alias)\s*[:：]?\s*([0-9.,万亿wWkK]+)", "([0-9.,万亿wWkK]+)\s*($alias)")) {
        $m = [Regex]::Match($Text, $p)
        if ($m.Success) {
            foreach ($g in $m.Groups) {
                if ($g.Success -and $g.Value -match "[0-9]" -and $g.Value -notmatch "^($alias)$") { return $g.Value }
            }
        }
    }
    return ""
}

function ExtractTime([string]$Text) {
    foreach ($p in @("\d{4}[-/.年]\d{1,2}[-/.月]\d{1,2}日?(\s+\d{1,2}:\d{2})?", "\d{1,2}[-/.月]\d{1,2}日?(\s+\d{1,2}:\d{2})?", "\d+\s*(分钟前|小时前|天前|周前|个月前|年前)")) {
        $m = [Regex]::Match($Text, $p)
        if ($m.Success) { return $m.Value }
    }
    return ""
}

function NewConversionFlag([bool]$Present, [string]$Evidence = "", [string]$Source = "") {
    return [ordered]@{
        present = $Present
        evidence = $(if ($Present) { $Evidence } else { "" })
        source = $(if ($Present) { $Source } else { "" })
    }
}

function NewConversionFlagFromEvidence($EvidenceObj) {
    return NewConversionFlag ([bool]$EvidenceObj.present) ([string]$EvidenceObj.evidence) ([string]$EvidenceObj.source)
}

function FindConversionEvidence([hashtable]$Sources, [string]$Pattern) {
    foreach ($key in @("title","ocr","transcript","comments")) {
        $text = Compact ([string]$Sources[$key])
        if ([string]::IsNullOrWhiteSpace($text)) { continue }
        if ($key -eq "ocr") {
            if ($text -match "OCR 状态|ChatGPT|关键帧可上传|OCR 引擎不可用") { continue }
            $cleanChunks = @($text -split "[\r\n；;]+" | ForEach-Object {
                GetReliableVisualSummaryText (ExtractPriorityOcrText $_)
            } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
            $text = Compact ($cleanChunks -join " ")
            if ([string]::IsNullOrWhiteSpace($text)) { continue }
        } else {
            $text = CleanSummaryText $text
        }
        $m = [Regex]::Match($text, $Pattern)
        if ($m.Success) {
            $start = [Math]::Max(0, $m.Index - 18)
            $len = [Math]::Min(60, $text.Length - $start)
            $evidence = CleanSummaryText ($text.Substring($start, $len))
            if ($key -eq "ocr") {
                $evidence = GetReliableVisualSummaryText $evidence
            }
            if ([string]::IsNullOrWhiteSpace($evidence)) { continue }
            return [ordered]@{ present = $true; evidence = $evidence; source = $key }
        }
    }
    return [ordered]@{ present = $false; evidence = ""; source = "" }
}

function DetectConversion($Sources) {
    if ($null -eq $Sources) { $Sources = @{} }
    [ordered]@{
        address = NewConversionFlagFromEvidence (FindConversionEvidence $Sources "$($CN.address)|$($CN.location)|$($CN.nav)|到店|门店地址|路线|在哪")
        price = NewConversionFlagFromEvidence (FindConversionEvidence $Sources "$($CN.avg)\s*[:：]?\s*[0-9]+|[¥￥]\s*[0-9]+|[0-9]+(?:\.[0-9]+)?\s*元|人均\s*[0-9]+|套餐(?:价|价格)?\s*[:：]?\s*[¥￥]?\s*[0-9]+|[0-9]+(?:\.[0-9]+)?\s*/\s*(人|位|份)")
        group_buy = NewConversionFlagFromEvidence (FindConversionEvidence $Sources "$($CN.groupbuy)|团购|券|套餐|核销|抖音团")
        private_message = NewConversionFlagFromEvidence (FindConversionEvidence $Sources "$($CN.private)|私聊|私我|私信|加我|微信")
        follow = NewConversionFlagFromEvidence (FindConversionEvidence $Sources "$($CN.follow)|点关注|关注我|主页橱窗")
    }
}

function AuthOnlyFields {
    return @(
        "authorized_play_count",
        "authorized_like_count",
        "authorized_comment_count",
        "authorized_favorite_count",
        "authorized_share_count",
        "fan_profile",
        "traffic_source",
        "completion_rate",
        "five_second_play_rate",
        "engagement_rate",
        "follower_gain",
        "profile_visit_count"
    )
}

function DataLevelForMode([string]$Mode) {
    if ($Mode -eq "authorized") { return "authorized_full_operational_diagnosis" }
    return "public_content_diagnosis"
}

function AuthorizationStatusForMode([string]$Mode) {
    if ($Mode -eq "authorized") { return "authorized_or_waiting_backend_data" }
    return "not_authorized_public_visible_only"
}

function ResolveCollectionStatus([string]$Mode, [string[]]$MissingDueToError, [string[]]$MissingDueToAuthorization) {
    if (@($MissingDueToError).Count -gt 0) { return "failed" }
    if ($Mode -eq "authorized" -and @($MissingDueToAuthorization).Count -gt 0) { return "auth_pending" }
    return "public_success"
}

function CaptureHomepageArtifacts([string]$PackageDir, [int]$Limit, $LogBox) {
    $homeShot = Join-Path $PackageDir "homepage_first_screen.png"
    Screenshot $homeShot
    $profileJson = Js @"
JSON.stringify((() => {
  const text = document.body ? document.body.innerText : '';
  const title = document.title || '';
  const normalized = text.replace(/\s+/g, ' ').trim();
  const profileHead = (() => {
    let s = normalized;
    const cutMarkers = [/作品\s*[0-9.万亿wWkK]+/, /热门：/, /广告投放/, /用户服务协议/, /网络谣言曝光台/, /京ICP备/, /京公网安备/];
    let cut = s.length;
    for (const re of cutMarkers) {
      const m = s.match(re);
      if (m && m.index >= 0) cut = Math.min(cut, m.index);
    }
    return s.slice(0, cut).trim();
  })();
  const profileScope = (() => {
    const starts = ['抖音号', 'IP属地'].map(k => normalized.indexOf(k)).filter(i => i >= 0);
    let start = starts.length ? Math.max(0, Math.min(...starts) - 180) : 0;
    let end = normalized.length;
    for (const re of [/作品\s*[0-9.万亿wWkK]+/, /热门：/, /暂时没有更多了/, /广告投放 用户服务协议/]) {
      const rest = normalized.slice(start);
      const m = rest.match(re);
      if (m && m.index >= 0) end = Math.min(end, start + m.index);
    }
    return normalized.slice(start, end).trim();
  })();
  const pickCount = label => {
    const re = new RegExp(label + '\\s*([0-9.万亿wWkK]+)');
    const m = normalized.match(re);
    return m ? m[1] : '';
  };
  const match = re => {
    const m = normalized.match(re);
    return m ? (m[1] || '').trim() : '';
  };
  const evidence = (re, scope = profileHead) => {
    const m = scope.match(re);
    if (!m) return '';
    const start = Math.max(0, m.index - 24);
    const value = scope.slice(start, Math.min(scope.length, m.index + 80)).trim();
    if (/备案|公网安备|ICP|用户服务协议|隐私政策|广告投放|营业执照/.test(value)) return '';
    return value;
  };
  const meta = {};
  for (const el of Array.from(document.querySelectorAll('meta')).slice(0, 80)) {
    const key = el.getAttribute('property') || el.getAttribute('name');
    const value = el.getAttribute('content') || '';
    if (key && value) meta[key] = value;
  }
  const nickname = (() => {
    const cleanName = v => (v || '').replace(/认证徽章|商家认证账号|企业认证账号/g, '').replace(/\s+/g, ' ').trim();
    const scoped = profileScope || normalized;
    let m = scoped.match(/(?:投稿\s+)?(.{2,80}?)\s+(?:认证徽章\s+)?(?:商家认证账号|企业认证账号)?\s*关注\s+[0-9.万亿wWkK]+/);
    if (m && m[1]) {
      const v = cleanName(m[1]);
      if (v && !/下载抖音|抖音电商|搜索|充钻石|客户端|壁纸|通知|投稿$/.test(v)) return v.replace(/^.*投稿\s+/, '').trim();
    }
    m = normalized.match(/投稿\s+(.{2,80}?)\s+(?:认证徽章\s+)?(?:商家认证账号|企业认证账号)?\s*关注\s+[0-9.万亿wWkK]+/);
    if (m && m[1]) return cleanName(m[1]);
    return ((title || '').replace(/\s*-\s*抖音.*$/, '').replace(/的抖音$/, '')).trim();
  })();
  const works = match(/作品\s*([0-9.万亿wWkK]+)/);
  const bio = (() => {
    const explicit = profileScope.match(/(?:简介|签名)[:：]\s*([^关注粉丝获赞作品]{2,160})/);
    if (explicit) return explicit[1].trim();
    const afterIp = profileScope.match(/IP属地[:：]\s*[^\s]+\s+(?:[0-9]{1,3}岁\s+)?(?:[^\s]{2,12}·[^\s]{2,20}\s+)?(.{6,180}?)(?:\s+更多|\s+分享主页|\s+私信|\s+下载电脑客户端|\s+下载)/);
    if (afterIp && afterIp[1] && !/备案|公网安备|ICP|用户服务协议|隐私政策|广告投放|营业执照/.test(afterIp[1])) return afterIp[1].trim();
    return '';
  })();
  const groupEntryEvidence = evidence(/团购|团购入口|团购活动|优惠券|券包|核销|立即抢购|到店团购/);
  const promoHits = [];
  const addPromo = hit => {
    hit = (hit || '').replace(/[🔥🥰🎑📍～~，,。；;#].*$/g, '').replace(/\s+/g, '').trim();
    hit = hit.replace(/🍺/g, '').replace(/水\+招牌菜品组合套餐性价比拉满.*/, '水+招牌菜品组合套餐');
    if (!hit || hit.length > 32) return;
    if (/备案|公网安备|ICP|用户服务协议|广告投放|作品|关注|粉丝|获赞|^\d+$/.test(hit)) return;
    if (!promoHits.includes(hit)) promoHits.push(hit);
  };
  if (/同城福利来袭/.test(normalized)) addPromo('同城福利来袭');
  if (/特色.{0,4}水\s*\+\s*招牌菜品组合套餐/.test(normalized)) addPromo('特色水+招牌菜品组合套餐');
  if (/性价比拉满/.test(normalized)) addPromo('性价比拉满');
  if (/提前预订/.test(normalized)) addPromo('提前预订');
  if (/母亲节免费送花束/.test(normalized)) addPromo('母亲节免费送花束');
  if (/每桌免费赠送/.test(normalized)) addPromo('每桌免费赠送');
  if (/限量\s*100\s*份/.test(normalized)) addPromo('限量100份');
  for (const m of normalized.matchAll(/(?:[¥￥]\s*[0-9]+|[0-9]+(?:\.[0-9]+)?\s*元|人均\s*[0-9]+|套餐(?:价|价格)?\s*[:：]?\s*[¥￥]?\s*[0-9]+)/g)) {
    addPromo(m[0]);
    if (promoHits.length >= 5) break;
  }
  const promoEvidence = promoHits.join(' / ');
  const bookingEvidence = evidence(/提前预订|预订|预约|订座|订位|锁定档期|到店时间|私信预留|私信客服/, normalized);
  const eventEvidence = evidence(/母亲节|生日|派对|520|求婚|儿童派对|新年|节日|活动|送花束|免费赠送|限量\s*100\s*份/, normalized);
  const ipLocation = match(/IP属地[:：]\s*([^\s]+)/);
  const locationHits = [];
  const addLocation = hit => {
    hit = (hit || '').replace(/^📍\s*/, '').replace(/\s+/g, '·').trim();
    if (!hit) return;
    if (/备案|公网安备|ICP|用户服务协议|隐私政策|广告投放|营业执照/.test(hit)) return;
    if (nickname && (hit === nickname || hit.replace(/[（）()]/g, '') === nickname.replace(/[（）()]/g, ''))) return;
    if (!locationHits.includes(hit)) locationHits.push(hit);
  };
  const profileCity = profileScope.match(/(?:IP属地[:：]\s*[^\s]+\s+)?(?:[0-9]{1,3}岁\s+)?([^\s]{2,12}·[^\s]{2,20})/);
  if (profileCity && profileCity[1]) addLocation(profileCity[1]);
  for (const re of [/西海岸广场·叁两酒馆/g, /西海岸广场\s*叁两酒馆/g, /📍\s*西海岸广场[·\s]*叁两酒馆/g]) {
    for (const m of normalized.matchAll(re)) {
      addLocation(m[0]);
      if (locationHits.length >= 3) break;
    }
    if (locationHits.length >= 3) break;
  }
  let locationEvidence = locationHits.join(' / ');
  if (!locationEvidence) locationEvidence = evidence(/西海岸广场·叁两酒馆|西海岸广场|地址|位置|导航|到店|[^\s]{1,12}(?:路|街|巷|号)/, normalized.replace(/京ICP备[\s\S]*$/,''));
  if (ipLocation && !/备案|公网/.test(ipLocation) && !locationEvidence) locationEvidence = ipLocation;
  let shopEvidence = evidence(/门店|店铺|商家|餐饮|酒馆|小酒馆|包厢/);
  if (!shopEvidence && /店|门店|店铺|商家|餐饮|酒馆|小酒馆|包厢/.test(nickname)) shopEvidence = nickname;
  return {
    url: location.href,
    page_title: title,
    nickname,
    douyin_id: match(/抖音号[:：]\s*([A-Za-z0-9_.-]+)/),
    following_count: pickCount('关注'),
    follower_count: pickCount('粉丝'),
    total_likes: pickCount('获赞'),
    works_count: works,
    ip_location: ipLocation,
    age_or_tag: match(/([0-9]{1,3}岁)/),
    bio,
    has_group_buy_entry: !!groupEntryEvidence,
    has_group_buy_entry_evidence: groupEntryEvidence,
    has_promo_content: !!promoEvidence,
    has_promo_content_evidence: promoEvidence,
    has_booking_content: !!bookingEvidence,
    has_booking_content_evidence: bookingEvidence,
    has_event_content: !!eventEvidence,
    has_event_content_evidence: eventEvidence,
    has_group_buy: !!groupEntryEvidence,
    has_group_buy_evidence: groupEntryEvidence,
    has_location: !!locationEvidence,
    has_location_evidence: locationEvidence,
    has_shop: !!shopEvidence,
    has_shop_evidence: shopEvidence,
    homepage_screenshot_path: 'homepage_first_screen.png',
    visible_text: text.replace(/\s+/g, ' ').trim().slice(0, 30000),
    meta
  };
})())
"@
    Set-Content -LiteralPath (Join-Path $PackageDir "account_profile.json") -Encoding UTF8 -Value $profileJson
    try {
        $profile = $profileJson | ConvertFrom-Json
        $visible = Compact ([string]$profile.visible_text)
        if ([string]::IsNullOrWhiteSpace([string]$profile.bio)) {
            $bioMatch = [Regex]::Match($visible, "IP属地[:：]\s*[^\s]+\s+(?:[0-9]{1,3}岁\s+)?(?:[^\s]{2,12}·[^\s]{2,20}\s+)?(.{6,180}?)(?:\s+更多|\s+分享主页|\s+私信|\s+下载电脑客户端|\s+下载)")
            if ($bioMatch.Success) {
                $bioText = Compact $bioMatch.Groups[1].Value
                if ($bioText -and $bioText -notmatch "备案|公网安备|ICP|用户服务协议|隐私政策|广告投放|营业执照|作品\s+[0-9]") {
                    $profile.bio = $bioText
                    Set-Content -LiteralPath (Join-Path $PackageDir "account_profile.json") -Encoding UTF8 -Value ($profile | ConvertTo-Json -Depth 20)
                }
            }
        }
        $worksText = $visible
        $worksStart = [Regex]::Match($worksText, "作品\s+[0-9.万亿wWkK]+")
        if ($worksStart.Success) { $worksText = $worksText.Substring($worksStart.Index) }
        else {
            $start = $worksText.IndexOf("作品 合集")
            if ($start -gt 0) { $worksText = $worksText.Substring($start) }
        }
        foreach ($marker in @("热门：", "广告投放 用户服务协议", "网络谣言曝光台")) {
            $idx = $worksText.IndexOf($marker)
            if ($idx -gt 0) { $worksText = $worksText.Substring(0, $idx) }
        }
        $Script:ProfileWorksText = $worksText
        $Script:TargetProfileName = ""
        $Script:TargetDouyinId = ""
        $Script:TargetProfilePath = ""
        $Script:TargetWorksCount = ToIntCount ([string]$profile.works_count)
        try {
            $profileUri = [Uri](NormalizeUrl $profile.url)
            $Script:TargetProfilePath = $profileUri.AbsolutePath
        } catch {}
        if (-not [string]::IsNullOrWhiteSpace([string]$profile.nickname)) {
            $Script:TargetProfileName = Compact ([string]$profile.nickname)
        }
        $nameMatch = [Regex]::Match($visible, "([^ ]{2,60})\s+关注\s+[0-9.万亿wWkK]+")
        if ([string]::IsNullOrWhiteSpace($Script:TargetProfileName) -and $nameMatch.Success) {
            $Script:TargetProfileName = Compact $nameMatch.Groups[1].Value
        } elseif ([string]::IsNullOrWhiteSpace($Script:TargetProfileName) -and -not [string]::IsNullOrWhiteSpace([string]$profile.page_title)) {
            $Script:TargetProfileName = Compact (([string]$profile.page_title -replace "\s*-\s*抖音.*$", ""))
        }
        $idMatch = [Regex]::Match($visible, "抖音号[:：]\s*([A-Za-z0-9_.-]+)")
        if ($idMatch.Success) { $Script:TargetDouyinId = Compact $idMatch.Groups[1].Value }
        Log $LogBox "已建立目标账号作品白名单文本，用于过滤底部热门/推荐视频。"
        Log $LogBox "目标账号身份：名称=$Script:TargetProfileName；抖音号=$Script:TargetDouyinId。"
        if ($Script:TargetWorksCount -gt 0) {
            Log $LogBox "主页显示作品总数：$Script:TargetWorksCount。"
        }
    } catch {
        $Script:ProfileWorksText = ""
        $Script:TargetProfileName = ""
        $Script:TargetDouyinId = ""
        $Script:TargetProfilePath = ""
        $Script:TargetWorksCount = 0
    }
    Log $LogBox "已保存主页第一屏截图和账号主页可见信息。"
}

function Keywords([string[]]$Comments) {
    $counts = @{}
    foreach ($m in [Regex]::Matches(($Comments -join " "), "[\u4e00-\u9fff]{2,6}|[A-Za-z0-9]{2,}")) {
        $w = $m.Value
        if (!$counts.ContainsKey($w)) { $counts[$w] = 0 }
        $counts[$w]++
    }
    return @($counts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20 | ForEach-Object { $_.Key })
}

function CommentQuestions([string[]]$Comments) {
    $text = $Comments -join " "
    [ordered]@{
        ask_address = ($text -match "$($CN.address)|在哪|位置|$($CN.nav)")
        ask_price = ($text -match "$($CN.howmuch)|$($CN.price)|人均|贵吗")
        ask_hours = ($text -match "营业|几点|开门|关门|时间")
        ask_booking = ($text -match "预约|预定|怎么订|排队|电话")
    }
}

function IsUsefulCommentItem($Comment) {
    if ($null -eq $Comment) { return $false }
    $text = Compact ([string]$Comment.text)
    $author = Compact ([string]$Comment.author_name)
    if ([string]::IsNullOrWhiteSpace($text)) { return $false }
    if ($text.Length -lt 2 -or $text.Length -gt 260) { return $false }
    if ($text -match "^[\d\s.,万亿wWkK赞点赞回复:：\-]+$") { return $false }
    if ($text -match "抢首评|暂无评论|还没有评论|说点什么|发一条友好的弹幕|发送|登录后|倍速|清屏|连播|听抖音|识别画面|TA的作品|相关推荐|相关搜索|大家都在搜|全部评论|^\s*评论\s*$") { return $false }
    if (-not [string]::IsNullOrWhiteSpace($author)) {
        if ($author -match "^[\d\s.,万亿wWkK赞点赞回复:：\-]+$") { return $false }
        if ($author -match "^(分享|评论|全部评论|回复|点赞|赞过|发送|更多)$") { return $false }
    }
    return $true
}

function GetJpegEncoder {
    return [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" } | Select-Object -First 1
}

function SaveJpegResized([string]$SourcePath, [string]$TargetPath, [int]$MaxWidth = 960, [long]$Quality = 76) {
    $src = [Drawing.Image]::FromFile($SourcePath)
    try {
        $scale = if ($src.Width -gt $MaxWidth) { $MaxWidth / [double]$src.Width } else { 1.0 }
        $w = [Math]::Max(1, [int][Math]::Round($src.Width * $scale))
        $h = [Math]::Max(1, [int][Math]::Round($src.Height * $scale))
        $bmp = [Drawing.Bitmap]::new($w, $h)
        try {
            $g = [Drawing.Graphics]::FromImage($bmp)
            try {
                $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
                $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $g.DrawImage($src, 0, 0, $w, $h)
            } finally {
                $g.Dispose()
            }
            $encoder = GetJpegEncoder
            $params = [Drawing.Imaging.EncoderParameters]::new(1)
            $params.Param[0] = [Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality, $Quality)
            $bmp.Save($TargetPath, $encoder, $params)
        } finally {
            if ($bmp) { $bmp.Dispose() }
        }
    } finally {
        $src.Dispose()
    }
}

function Screenshot([string]$Path) {
    $shot = Cdp "Page.captureScreenshot" @{ format = "png"; fromSurface = $true }
    [IO.File]::WriteAllBytes($Path, [Convert]::FromBase64String($shot.data))
}

function ScreenshotJpeg([string]$Path, [int]$MaxWidth = 960, [long]$Quality = 76) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("douyin_frame_" + [Guid]::NewGuid() + ".png")
    try {
        Screenshot $tmp
        SaveJpegResized $tmp $Path $MaxWidth $Quality
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

function GetVideoViewportRect {
    $json = Js @"
JSON.stringify((() => {
  const visible = el => {
    if (!el) return false;
    const r = el.getBoundingClientRect();
    if (r.width < 120 || r.height < 120 || r.bottom <= 0 || r.right <= 0 || r.left >= innerWidth || r.top >= innerHeight) return false;
    const s = getComputedStyle(el);
    return s.display !== 'none' && s.visibility !== 'hidden' && Number(s.opacity) !== 0;
  };
  const rectOf = (el, kind) => {
    const r = el.getBoundingClientRect();
    const left = Math.max(0, r.left);
    const top = Math.max(0, r.top);
    const right = Math.min(innerWidth, r.right);
    const bottom = Math.min(innerHeight, r.bottom);
    const width = Math.max(1, right - left);
    const height = Math.max(1, bottom - top);
    return { left, top, width, height, right, bottom, area: width * height, kind };
  };
  const candidates = [];
  for (const v of Array.from(document.querySelectorAll('video')).filter(visible)) {
    candidates.push(rectOf(v, 'video'));
  }
  for (const img of Array.from(document.querySelectorAll('img')).filter(visible)) {
    const r = img.getBoundingClientRect();
    const naturalOk = (img.naturalWidth || 0) >= 240 || (img.naturalHeight || 0) >= 240;
    if (!naturalOk && (r.width < 260 || r.height < 260)) continue;
    candidates.push(rectOf(img, 'image'));
  }
  for (const c of Array.from(document.querySelectorAll('canvas')).filter(visible)) {
    candidates.push(rectOf(c, 'canvas'));
  }
  if (!candidates.length) {
    const blocks = Array.from(document.querySelectorAll('div,section,main')).filter(el => {
      if (!visible(el)) return false;
      const r = el.getBoundingClientRect();
      if (r.width < 260 || r.height < 300 || r.width > innerWidth * 0.92 || r.height > innerHeight * 0.98) return false;
      const text = (el.innerText || '').replace(/\s+/g, ' ').trim();
      if (/搜索|分享主页|下载电脑客户端|全部评论|相关推荐|相关搜索|登录|验证码/.test(text) && text.length > 80) return false;
      return !!el.querySelector('img,video,canvas');
    }).map(el => rectOf(el, 'container'));
    candidates.push(...blocks);
  }
  candidates.sort((a,b) => b.area - a.area);
  if (!candidates.length) return null;
  const r = candidates[0];
  let left = Math.max(0, r.left);
  let top = Math.max(0, r.top);
  let right = Math.min(innerWidth, r.right);
  let bottom = Math.min(innerHeight, r.bottom);
  const w = Math.max(1, right - left);
  const h = Math.max(1, bottom - top);
  const rightTrim = r.kind === 'video' ? 0.16 : 0.04;
  const topTrim = r.kind === 'video' ? 0.08 : 0.03;
  const bottomTrim = r.kind === 'video' ? 0.10 : 0.04;
  left = left + w * 0.03;
  top = top + h * topTrim;
  right = right - w * rightTrim;
  bottom = bottom - h * bottomTrim;
  return { left, top, width: Math.max(1, right-left), height: Math.max(1, bottom-top), viewport_width: innerWidth, viewport_height: innerHeight, source_kind: r.kind };
})())
"@
    if ([string]::IsNullOrWhiteSpace($json) -or $json -eq "null") { return $null }
    return ($json | ConvertFrom-Json)
}

function SaveJpegCropResized([string]$SourcePath, [string]$TargetPath, $Rect, [int]$MaxWidth = 960, [long]$Quality = 76) {
    $src = [Drawing.Image]::FromFile($SourcePath)
    try {
        $scaleX = $src.Width / [double]$Rect.viewport_width
        $scaleY = $src.Height / [double]$Rect.viewport_height
        $x = [Math]::Max(0, [int][Math]::Floor([double]$Rect.left * $scaleX))
        $y = [Math]::Max(0, [int][Math]::Floor([double]$Rect.top * $scaleY))
        $w = [Math]::Min($src.Width - $x, [int][Math]::Ceiling([double]$Rect.width * $scaleX))
        $h = [Math]::Min($src.Height - $y, [int][Math]::Ceiling([double]$Rect.height * $scaleY))
        if ($w -lt 10 -or $h -lt 10) { throw "未识别到有效视频画面区域" }
        $scale = if ($w -gt $MaxWidth) { $MaxWidth / [double]$w } else { 1.0 }
        $tw = [Math]::Max(1, [int][Math]::Round($w * $scale))
        $th = [Math]::Max(1, [int][Math]::Round($h * $scale))
        $bmp = [Drawing.Bitmap]::new($tw, $th)
        try {
            $g = [Drawing.Graphics]::FromImage($bmp)
            try {
                $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
                $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $srcRect = [Drawing.Rectangle]::new($x, $y, $w, $h)
                $dstRect = [Drawing.Rectangle]::new(0, 0, $tw, $th)
                $g.DrawImage($src, $dstRect, $srcRect, [Drawing.GraphicsUnit]::Pixel)
            } finally {
                $g.Dispose()
            }
            $encoder = GetJpegEncoder
            $params = [Drawing.Imaging.EncoderParameters]::new(1)
            $params.Param[0] = [Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality, $Quality)
            $bmp.Save($TargetPath, $encoder, $params)
        } finally {
            if ($bmp) { $bmp.Dispose() }
        }
    } finally {
        $src.Dispose()
    }
}

function CaptureFramePair([string]$FullFramePath, [string]$VideoCropPath) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("douyin_frame_" + [Guid]::NewGuid() + ".png")
    try {
        $lastError = ""
        for ($attempt = 0; $attempt -lt 3; $attempt++) {
            try {
                Screenshot $tmp
                SaveJpegResized $tmp $FullFramePath 960 76
                $rect = GetVideoViewportRect
                if ($null -eq $rect) { throw "未识别到视频/图文主体区域" }
                SaveJpegCropResized $tmp $VideoCropPath $rect 960 76
                return [ordered]@{ ok = $true; rect = $rect; error = "" }
            } catch {
                $lastError = $_.Exception.Message
                Start-Sleep -Milliseconds 450
            }
        }
        return [ordered]@{ ok = $false; rect = $null; error = $lastError }
    } catch {
        return [ordered]@{ ok = $false; rect = $null; error = $_.Exception.Message }
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

function SeekVideo([double]$Second) {
    $secondText = $Second.ToString([Globalization.CultureInfo]::InvariantCulture)
    $jsCode = "(async()=>{const visible=v=>{const r=v.getBoundingClientRect();const s=getComputedStyle(v);return r.width>80&&r.height>80&&r.bottom>0&&r.right>0&&r.left<innerWidth&&r.top<innerHeight&&s.display!=='none'&&s.visibility!=='hidden'&&Number(s.opacity)!==0};const vids=Array.from(document.querySelectorAll('video')).filter(visible).sort((a,b)=>{const ar=a.getBoundingClientRect(),br=b.getBoundingClientRect();return br.width*br.height-ar.width*ar.height});const v=vids[0];if(!v)return false;try{v.pause()}catch(e){};await new Promise(resolve=>{const done=()=>{v.removeEventListener('seeked',done);resolve()};v.addEventListener('seeked',done);try{const d=Number.isFinite(v.duration)?v.duration:$secondText;const target=Math.max(0,Math.min($secondText,Math.max(0,d-0.8)));v.currentTime=target}catch(e){resolve()};setTimeout(resolve,2200)});try{v.pause()}catch(e){};return true})()"
    Js $jsCode | Out-Null
}

function VideoDuration {
    $d = Js "(()=>{const visible=v=>{const r=v.getBoundingClientRect();const s=getComputedStyle(v);return r.width>80&&r.height>80&&r.bottom>0&&r.right>0&&r.left<innerWidth&&r.top<innerHeight&&s.display!=='none'&&s.visibility!=='hidden'&&Number(s.opacity)!==0};const vids=Array.from(document.querySelectorAll('video')).filter(visible).sort((a,b)=>{const ar=a.getBoundingClientRect(),br=b.getBoundingClientRect();return br.width*br.height-ar.width*ar.height});const v=vids[0];return v&&Number.isFinite(v.duration)?v.duration:0})()"
    if ($null -eq $d) { return 0 }
    return [double]$d
}

function DetectCurrentMediaType {
    $value = Js "(()=>{const visible=e=>{const r=e.getBoundingClientRect();const s=getComputedStyle(e);return r.width>80&&r.height>80&&r.bottom>0&&r.right>0&&r.left<innerWidth&&r.top<innerHeight&&s.display!=='none'&&s.visibility!=='hidden'&&Number(s.opacity)!==0};const vids=Array.from(document.querySelectorAll('video')).filter(visible);if(vids.length)return 'video';const staticMedia=Array.from(document.querySelectorAll('img,canvas')).filter(visible);return staticMedia.length?'static_or_image_card':'unknown'})()"
    if ([string]::IsNullOrWhiteSpace([string]$value)) { return "unknown" }
    return [string]$value
}

function PauseAndLockCurrentWork([string]$ExpectedWorkId = "") {
    $idB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($(if ($null -eq $ExpectedWorkId) { "" } else { $ExpectedWorkId })))
    Js @"
(()=> {
  const expected = new TextDecoder('utf-8').decode(Uint8Array.from(atob('$idB64'), c => c.charCodeAt(0)));
  window.__douyinCodexExpectedWorkId = expected;
  const pauseAll = () => {
    try {
      for (const v of Array.from(document.querySelectorAll('video'))) {
        try {
          v.autoplay = false;
          v.loop = false;
          v.pause();
          v.removeAttribute('autoplay');
          v.onended = () => {
            try {
              if (Number.isFinite(v.duration) && v.duration > 1) v.currentTime = Math.max(0, v.duration - 1.2);
              v.pause();
            } catch(e) {}
          };
        } catch(e) {}
      }
      const btns = Array.from(document.querySelectorAll('button,div,span')).filter(el => {
        const t = (el.innerText || el.getAttribute('aria-label') || el.title || '').replace(/\s+/g,'').trim();
        return /连播|自动播放|自动连播/.test(t);
      });
      for (const b of btns) {
        try {
          const t = (b.innerText || b.getAttribute('aria-label') || b.title || '').replace(/\s+/g,'').trim();
          if (/已开启|开启|连播中|自动播放/.test(t) && !/关闭|不开启/.test(t)) b.click();
        } catch(e) {}
      }
    } catch(e) {}
    return true;
  };
  pauseAll();
  if (window.__douyinCodexPauseTimer) clearInterval(window.__douyinCodexPauseTimer);
  window.__douyinCodexPauseTimer = setInterval(pauseAll, 450);
  return true;
})()
"@ | Out-Null
}

function StopWorkLock {
    Js "(()=>{try{if(window.__douyinCodexPauseTimer){clearInterval(window.__douyinCodexPauseTimer);window.__douyinCodexPauseTimer=null}}catch(e){};return true})()" | Out-Null
}

function EnsureWorkStillOpen([string]$Url, [string]$ExpectedWorkId, $LogBox, [string]$Stage) {
    $currentUrl = Compact (Js "location.href")
    $currentId = GetWorkId $currentUrl
    if ($currentId -eq $ExpectedWorkId) {
        PauseAndLockCurrentWork $ExpectedWorkId
        return $true
    }
    if ([string]::IsNullOrWhiteSpace($Url)) {
        Log $LogBox "检测到作品在“$Stage”阶段不匹配，但缺少原作品链接，无法重新打开：当前=$currentId，目标=$ExpectedWorkId。"
        return $false
    }
    Log $LogBox "检测到作品在“$Stage”阶段自动跳转：当前=$currentId，目标=$ExpectedWorkId。正在重新打开目标作品。"
    for ($attempt = 0; $attempt -lt 2; $attempt++) {
        NavFast $Url
        for ($i = 0; $i -lt 18; $i++) {
            Start-Sleep -Milliseconds 250
            [Windows.Forms.Application]::DoEvents()
            PauseAndLockCurrentWork $ExpectedWorkId
            $currentId = GetWorkId (Compact (Js "location.href"))
            if ($currentId -eq $ExpectedWorkId) { return $true }
        }
    }
    Log $LogBox "重新打开后仍不是目标作品：当前=$currentId，目标=$ExpectedWorkId。"
    return $false
}

function GetFrameTargets([double]$Duration) {
    $targets = New-Object System.Collections.Generic.List[object]
    $targets.Add([ordered]@{ label = "cover"; second = 0; file = "cover.jpg"; kind = "cover" })
    foreach ($s in @(0,1,2,3)) {
        $targets.Add([ordered]@{ label = "${s}s"; second = [double]$s; file = "${s}s.jpg"; kind = "time" })
    }
    if ($Duration -ge 6) {
        $targets.Add([ordered]@{ label = "5s"; second = 5.0; file = "5s.jpg"; kind = "time" })
        for ($s = 8; $s -lt $Duration; $s += 3) {
            $targets.Add([ordered]@{ label = "${s}s"; second = [double]$s; file = "${s}s.jpg"; kind = "time" })
        }
    }
    $endSecond = if ($Duration -gt 1) { [Math]::Max(0, $Duration - 0.5) } else { 0 }
    $targets.Add([ordered]@{ label = "ending"; second = [double]$endSecond; file = "ending.jpg"; kind = "ending" })
    return @($targets.ToArray())
}

function GetTesseractExe {
    $local = Join-Path $Script:Root "local_ocr\Tesseract-OCR\tesseract.exe"
    if (Test-Path -LiteralPath $local) { return $local }
    foreach ($p in @(
        "C:\Program Files\Tesseract-OCR\tesseract.exe",
        "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe"
    )) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    $cmd = Get-Command tesseract -ErrorAction SilentlyContinue
    if ($null -ne $cmd) { return $cmd.Source }
    return ""
}

function GetPaddleOcrPython {
    if ($Script:PaddleOcrChecked) { return $Script:PaddleOcrPython }
    $Script:PaddleOcrChecked = $true
    foreach ($cmdName in @("python", "py")) {
        $cmd = Get-Command $cmdName -ErrorAction SilentlyContinue
        if ($null -eq $cmd) { continue }
        try {
            $check = & $cmd.Source -c "import paddleocr, json; print('ok')" 2>$null
            if (($check | Out-String).Trim() -eq "ok") {
                $Script:PaddleOcrPython = $cmd.Source
                return $Script:PaddleOcrPython
            }
        } catch {}
    }
    $Script:PaddleOcrPython = ""
    return ""
}

function CleanOcrText([string]$Text) {
    $line = Compact $Text
    if ([string]::IsNullOrWhiteSpace($line)) { return "" }
    $noise = @("搜索", "关注", "私信", "评论", "收藏", "分享", "点赞", "听抖音", "倍速", "清屏", "连播", "发送", "首页", "推荐", "精选", "不开启", "开启读屏", "字幕", "大家都在搜", "相关搜索")
    foreach ($n in $noise) {
        $line = Compact ($line -replace [Regex]::Escape($n), "")
    }
    $line = Compact ($line -replace "0\.75x|1\.0x|1\.25x|1\.5x|1\.75x|2\.0x|3\.0x", "")
    return $line
}

function ExtractPriorityOcrText([string]$Text) {
    $line = CleanOcrText $Text
    if ([string]::IsNullOrWhiteSpace($line)) { return "" }
    $hits = @()
    foreach ($m in [Regex]::Matches($line, "([^。；;，,]{0,18}(门店|地址|导航|电话|营业|时间|套餐|团购|价格|人均|菜|酒|活动|优惠|到店|预约|包间|西海岸|叁两)[^。；;，,]{0,32})")) {
        $hit = Compact $m.Groups[1].Value
        if ($hit -and -not ($hits -contains $hit)) { $hits += $hit }
    }
    if ($hits.Count) { return ($hits -join "；") }
    return $line
}

function CleanSummaryText([string]$Text) {
    $line = Compact $Text
    if ([string]::IsNullOrWhiteSpace($line)) { return "" }
    $patterns = @(
        "@[A-Za-z0-9_\-\u4e00-\u9fff]{1,30}",
        "字幕\s*不开启|不开启字幕|开启读屏|读屏标签|精选推荐|精选|推荐搜索|相关搜索|大家都在搜",
        "搜索你感兴趣的内容|搜索 Ta 的作品|TA的作品|下载电脑客户端|桌面快捷访问|分享主页",
        "关注|私信|评论|收藏|分享|点赞|听抖音|倍速|清屏|连播|发送|抢首评",
        "0\.75x|1\.0x|1\.25x|1\.5x|1\.75x|2\.0x|3\.0x|720P|540P|高清|标清|智能"
    )
    foreach ($p in $patterns) {
        $line = Compact ([Regex]::Replace($line, $p, " "))
    }
    return $line
}

function GetReliableVisualSummaryText([string]$Text) {
    $line = CleanSummaryText $Text
    if ([string]::IsNullOrWhiteSpace($line)) { return "" }
    if ($line -match "(?i)moonfiow|noonfiow|m00n|wm\s+F|Se\s+a\s+S|\\|[=_]{2,}|—{2,}") { return "" }
    $hanCount = [Regex]::Matches($line, "[\u4e00-\u9fff]").Count
    $latinCount = [Regex]::Matches($line, "[A-Za-z]").Count
    $symbolNoiseCount = [Regex]::Matches($line, "[\\/=~<>|]").Count
    if ($line.Length -ge 20 -and $hanCount -lt [Math]::Ceiling($line.Length * 0.25)) { return "" }
    if ($latinCount -gt 0 -and $latinCount -ge $hanCount) { return "" }
    if ($symbolNoiseCount -gt 2) { return "" }
    return $line
}

function NormalizeCompareText([string]$Text) {
    $line = CleanSummaryText $Text
    $line = [Regex]::Replace($line, "#[^\s#]+", " ")
    $line = [Regex]::Replace($line, "[^\u4e00-\u9fffA-Za-z0-9]+", "")
    return $line.ToLowerInvariant()
}

function TextSimilarityScore([string]$A, [string]$B) {
    $aText = NormalizeCompareText $A
    $bText = NormalizeCompareText $B
    if ([string]::IsNullOrWhiteSpace($aText) -or [string]::IsNullOrWhiteSpace($bText)) { return 0 }
    if ($aText.Contains($bText) -or $bText.Contains($aText)) { return 1.0 }
    $tokensA = New-Object System.Collections.Generic.HashSet[string]
    $tokensB = New-Object System.Collections.Generic.HashSet[string]
    foreach ($m in [Regex]::Matches($aText, "[\u4e00-\u9fff]{2,6}|[A-Za-z0-9]{3,}")) { [void]$tokensA.Add($m.Value) }
    foreach ($m in [Regex]::Matches($bText, "[\u4e00-\u9fff]{2,6}|[A-Za-z0-9]{3,}")) { [void]$tokensB.Add($m.Value) }
    if ($tokensA.Count -eq 0 -or $tokensB.Count -eq 0) {
        $max = [Math]::Max($aText.Length, $bText.Length)
        if ($max -eq 0) { return 0 }
        $common = 0
        foreach ($ch in $aText.ToCharArray()) {
            if ($bText.Contains([string]$ch)) { $common++ }
        }
        return [Math]::Round($common / [double]$max, 3)
    }
    $intersection = 0
    foreach ($t in $tokensA) { if ($tokensB.Contains($t)) { $intersection++ } }
    $union = $tokensA.Count + $tokensB.Count - $intersection
    if ($union -le 0) { return 0 }
    return [Math]::Round($intersection / [double]$union, 3)
}

function NewMappingCheck($CardInfo, [string]$OpenedModalId, [string]$DetailTitle) {
    $reasons = New-Object System.Collections.Generic.List[string]
    $cardModalId = ""
    $cardText = ""
    if ($CardInfo) {
        $cardModalId = Compact ([string]$CardInfo.modal_id)
        $cardText = Compact ([string]$CardInfo.card_text)
    }
    $score = TextSimilarityScore $cardText $DetailTitle
    if ([string]::IsNullOrWhiteSpace($cardModalId)) {
        $reasons.Add("card_modal_id 缺失")
    } elseif ($OpenedModalId -ne $cardModalId) {
        $reasons.Add("opened_modal_id 与 card_modal_id 不一致")
    }
    $titleConsistencyStatus = "ok"
    $titleConsistencyReason = "ok"
    if (-not [string]::IsNullOrWhiteSpace($cardText) -and -not [string]::IsNullOrWhiteSpace($DetailTitle) -and $score -lt 0.18) {
        $titleConsistencyStatus = "mismatch"
        $titleConsistencyReason = "card_text/detail_title 不一致"
    }
    $status = if ($reasons.Count -eq 0) { "ok" } else { "mismatch" }
    return [ordered]@{
        mapping_status = $status
        content_mapping_status = $status
        mapping_check_reason = $(if ($reasons.Count) { $reasons.ToArray() -join "；" } else { "ok" })
        title_consistency_status = $titleConsistencyStatus
        title_consistency_reason = $titleConsistencyReason
        title_similarity_score = $score
        opened_modal_id = $OpenedModalId
        card_modal_id = $cardModalId
    }
}

function ResolvePublicMetricStatus([string]$PublicCardLike, [string]$LikeMatchedState, $CommentResult) {
    $reasons = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($PublicCardLike)) {
        return [ordered]@{ status = "missing"; reason = "主页卡片心形数缺失" }
    } elseif ($LikeMatchedState -eq "missing") {
        return [ordered]@{ status = "card_only"; reason = "详情页未复核公开心形数，采用主页卡片心形数" }
    }
    if ($null -eq $CommentResult -or [string]::IsNullOrWhiteSpace([string]$CommentResult.comments_status)) {
        $reasons.Add("公开评论状态缺失")
    }
    if ($reasons.Count -gt 0) {
        return [ordered]@{ status = "mismatch"; reason = ($reasons.ToArray() -join "；") }
    }
    return [ordered]@{ status = "ok"; reason = "ok" }
}

function GetCommentCountMatchStatus($PublicCommentCount, [int]$ValidCommentItemsCount, [int]$ReplyItemsCount) {
    if ($null -eq $PublicCommentCount -or [string]::IsNullOrWhiteSpace([string]$PublicCommentCount)) {
        return "unknown_no_public_count"
    }
    $publicCount = 0
    if (-not [int]::TryParse([string]$PublicCommentCount, [ref]$publicCount)) {
        return "unknown_public_count_parse_failed"
    }
    if ($publicCount -le 0 -and $ValidCommentItemsCount -eq 0) { return "no_public_comments" }
    if ($ValidCommentItemsCount -eq $publicCount) { return "match" }
    if ($ValidCommentItemsCount -eq 0 -and $publicCount -gt 0) { return "visible_count_but_items_empty" }
    if ($ValidCommentItemsCount -lt $publicCount) {
        if (($ValidCommentItemsCount + $ReplyItemsCount) -ge $publicCount) {
            return "ok_with_reply_filtered"
        }
        return "partial"
    }
    if ($ValidCommentItemsCount -gt $publicCount) { return "over_collected" }
    return "unknown"
}

function AddCommentStats($CommentResult, $PublicCommentCount, [int]$ValidCommentItemsCount) {
    if ($null -eq $CommentResult) { return }
    $replyItemsCount = 0
    $n = 0
    if ($null -ne $CommentResult.filtered_author_reply_count -and [int]::TryParse([string]$CommentResult.filtered_author_reply_count, [ref]$n)) {
        $replyItemsCount = $n
    }
    $matchStatus = GetCommentCountMatchStatus $PublicCommentCount $ValidCommentItemsCount $replyItemsCount
    $CommentResult | Add-Member -NotePropertyName valid_comment_items_count -NotePropertyValue $ValidCommentItemsCount -Force
    $CommentResult | Add-Member -NotePropertyName reply_items_count -NotePropertyValue $replyItemsCount -Force
    $CommentResult | Add-Member -NotePropertyName comment_count_match_status -NotePropertyValue $matchStatus -Force
}

function IsLikelyUiText([string]$Text) {
    $line = Compact $Text
    if ([string]::IsNullOrWhiteSpace($line)) { return $false }
    return ($line -match "搜索|关注|私信|评论|收藏|分享|点赞|听抖音|倍速|清屏|连播|发送|0\.75x|1\.0x|1\.25x|1\.5x|1\.75x|2\.0x|3\.0x")
}

function InvokePaddleFrameOcr([string]$VideoCropPath) {
    $python = GetPaddleOcrPython
    if ([string]::IsNullOrWhiteSpace($python)) { return $null }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("paddle_ocr_" + [Guid]::NewGuid() + ".py")
    try {
        $py = @"
import json, sys
from paddleocr import PaddleOCR
path = sys.argv[1]
ocr = PaddleOCR(use_angle_cls=True, lang='ch', show_log=False)
res = ocr.ocr(path, cls=True)
items = []
def walk(x):
    if isinstance(x, list):
        if len(x) >= 2 and isinstance(x[1], (list, tuple)) and len(x[1]) >= 2 and isinstance(x[1][0], str):
            items.append({"text": x[1][0], "confidence": float(x[1][1] or 0)})
        else:
            for v in x:
                walk(v)
walk(res)
print(json.dumps(items, ensure_ascii=False))
"@
        Set-Content -LiteralPath $tmp -Encoding UTF8 -Value $py
        $raw = & $python $tmp $VideoCropPath 2>$null
        $json = ($raw | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($json)) { return $null }
        $items = @($json | ConvertFrom-Json)
        $text = Compact ((@($items) | ForEach-Object { $_.text }) -join " ")
        $confValues = @($items | ForEach-Object { [double]$_.confidence })
        $avgConf = if ($confValues.Count) { [Math]::Round((($confValues | Measure-Object -Average).Average) * 100, 1) } else { 0 }
        return [ordered]@{ text = $text; confidence = $avgConf; engine = "paddleocr" }
    } catch {
        return $null
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

function InvokeFrameOcr([string]$FullFramePath, [string]$VideoCropPath, [string]$FrameTime, [string]$PackageDir) {
    $sourceRel = RelPath $FullFramePath $PackageDir
    $cropRel = RelPath $VideoCropPath $PackageDir
    $paddle = InvokePaddleFrameOcr $VideoCropPath
    if ($null -ne $paddle -and -not [string]::IsNullOrWhiteSpace([string]$paddle.text)) {
        $text = Compact ([string]$paddle.text)
        $clean = ExtractPriorityOcrText $text
        return [ordered]@{
            frame_time = $FrameTime
            source_frame = $sourceRel
            cropped_video_frame_path = $cropRel
            text = $text
            confidence = $paddle.confidence
            is_ui_text = (IsLikelyUiText $text)
            clean_text = $clean
            ocr_engine = "paddleocr"
            ocr_status = "ok"
        }
    }
    $tesseract = GetTesseractExe
    if ([string]::IsNullOrWhiteSpace($tesseract) -or -not (Test-Path -LiteralPath $tesseract)) {
        return [ordered]@{
            frame_time = $FrameTime
            source_frame = $sourceRel
            cropped_video_frame_path = $cropRel
            text = ""
            confidence = 0
            is_ui_text = $false
            clean_text = ""
            ocr_status = "ocr_engine_unavailable"
        }
    }
    try {
        $tessdata = Join-Path (Split-Path -Parent $tesseract) "tessdata"
        $args = @($VideoCropPath, "stdout", "-l", "chi_sim+eng", "--psm", "6")
        if (Test-Path -LiteralPath $tessdata) {
            $args += @("--tessdata-dir", $tessdata)
        }
        $output = & $tesseract @args 2>$null
        $text = Compact (($output | Out-String))
        $clean = CleanOcrText $text
        $isUi = IsLikelyUiText $text
        return [ordered]@{
            frame_time = $FrameTime
            source_frame = $sourceRel
            cropped_video_frame_path = $cropRel
            text = $text
            confidence = $(if ([string]::IsNullOrWhiteSpace($text)) { 0 } else { 70 })
            is_ui_text = $isUi
            clean_text = (ExtractPriorityOcrText $clean)
            ocr_engine = "local_tesseract"
            ocr_status = "ok"
        }
    } catch {
        return [ordered]@{
            frame_time = $FrameTime
            source_frame = $sourceRel
            cropped_video_frame_path = $cropRel
            text = ""
            confidence = 0
            is_ui_text = $false
            clean_text = ""
            ocr_status = "failed: $($_.Exception.Message)"
        }
    }
}

function NewContactSheet([object[]]$Frames, [string]$OutputPath, [int]$ThumbWidth = 320) {
    if (@($Frames).Count -eq 0) { return }
    $loaded = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($f in $Frames) {
            if (-not (Test-Path -LiteralPath $f.path)) { continue }
            $img = [Drawing.Image]::FromFile($f.path)
            $scale = $ThumbWidth / [double]$img.Width
            $w = $ThumbWidth
            $h = [Math]::Max(1, [int][Math]::Round($img.Height * $scale))
            $loaded.Add([ordered]@{ img = $img; label = $f.label; width = $w; height = $h })
        }
        if ($loaded.Count -eq 0) { return }
        $padding = 12
        $labelHeight = 30
        $sheetWidth = $ThumbWidth + ($padding * 2)
        $sheetHeight = $padding + (($loaded | ForEach-Object { $_.height + $labelHeight + $padding }) | Measure-Object -Sum).Sum
        $sheet = [Drawing.Bitmap]::new($sheetWidth, [int]$sheetHeight)
        try {
            $g = [Drawing.Graphics]::FromImage($sheet)
            try {
                $g.Clear([Drawing.Color]::White)
                $font = [Drawing.Font]::new("Microsoft YaHei UI", 14, [Drawing.FontStyle]::Bold)
                $brush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(20,20,20))
                $y = $padding
                foreach ($entry in $loaded) {
                    $g.DrawString([string]$entry.label, $font, $brush, $padding, $y)
                    $y += $labelHeight
                    $g.DrawImage($entry.img, $padding, $y, $entry.width, $entry.height)
                    $y += $entry.height + $padding
                }
                $font.Dispose()
                $brush.Dispose()
            } finally {
                $g.Dispose()
            }
            $encoder = GetJpegEncoder
            $params = [Drawing.Imaging.EncoderParameters]::new(1)
            $params.Param[0] = [Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality, [long]76)
            $sheet.Save($OutputPath, $encoder, $params)
        } finally {
            if ($sheet) { $sheet.Dispose() }
        }
    } finally {
        foreach ($entry in $loaded) {
            try { $entry.img.Dispose() } catch {}
        }
    }
}

function NewVisualRhythmAnalysis([double]$Duration, $OcrItems) {
    $end = if ($Duration -gt 0) { [Math]::Ceiling($Duration) } else { 6 }
    $lines = New-Object System.Collections.Generic.List[string]
    for ($start = 0; $start -lt $end; $start += 3) {
        $stop = [Math]::Min($start + 3, $end)
        $texts = @($OcrItems | Where-Object {
            $t = 0.0
            $label = [string]$_.frame_time
            if ($label -eq "cover" -or $label -eq "ending") {
                $false
            } elseif ([double]::TryParse(($label -replace "s$",""), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$t)) {
                ($t -ge $start -and $t -lt $stop)
            } else {
                $false
            }
        } | ForEach-Object {
            $t = ExtractPriorityOcrText $(if ($_.clean_text) { $_.clean_text } else { $_.text })
            $t = GetReliableVisualSummaryText $t
            if ($t -match "门店|地址|导航|电话|营业|时间|套餐|团购|价格|人均|菜|酒|活动|优惠|到店|预约|包间|人物|西海岸|叁两") { $t } else { "" }
        } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
        $desc = if ($texts.Count) { Compact ($texts -join " / ") } else { "见对应关键帧，未提取到可稳定用于摘要的业务文字。" }
        $lines.Add("- $start-$stop 秒：$desc")
    }
    return ($lines.ToArray() -join "`r`n")
}

function CaptureWorkFrames([string]$Folder, [string]$FramesDir, [string]$PackageDir, [string]$WorkUrl = "", [string]$ExpectedWorkId = "", $LogBox = $null) {
    New-Item -ItemType Directory -Force -Path $FramesDir | Out-Null
    $fullDir = Join-Path $FramesDir "full_frame"
    $cropDir = Join-Path $FramesDir "video_crop"
    New-Item -ItemType Directory -Force -Path $fullDir, $cropDir | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($ExpectedWorkId)) {
        [void](EnsureWorkStillOpen $WorkUrl $ExpectedWorkId $LogBox "抽帧前")
    }
    $duration = VideoDuration
    $mediaType = DetectCurrentMediaType
    $targets = @(GetFrameTargets $duration)
    $frameRecords = New-Object System.Collections.Generic.List[object]
    $ocrItems = New-Object System.Collections.Generic.List[object]
    $frameErrors = New-Object System.Collections.Generic.List[string]
    $cropErrors = New-Object System.Collections.Generic.List[string]
    foreach ($target in $targets) {
        if (-not [string]::IsNullOrWhiteSpace($ExpectedWorkId) -and -not (EnsureWorkStillOpen $WorkUrl $ExpectedWorkId $LogBox "抽帧 $($target.label) 前")) {
            $frameErrors.Add("$($target.label): 作品已跳转，无法恢复到目标作品")
            $cropErrors.Add("$($target.label): 作品已跳转，无法恢复到目标作品")
            continue
        }
        if ($target.kind -ne "cover") { SeekVideo ([double]$target.second) }
        PauseAndLockCurrentWork $ExpectedWorkId
        $fullFramePath = Join-Path $fullDir $target.file
        $cropFramePath = Join-Path $cropDir $target.file
        $capture = CaptureFramePair $fullFramePath $cropFramePath
        if (-not $capture.ok) {
            $frameErrors.Add("$($target.label): $($capture.error)")
            $cropErrors.Add("$($target.label): $($capture.error)")
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace($ExpectedWorkId) -and -not (EnsureWorkStillOpen $WorkUrl $ExpectedWorkId $LogBox "抽帧 $($target.label) 后")) {
            $frameErrors.Add("$($target.label): 截图后检测到作品自动跳转，已丢弃该帧")
            $cropErrors.Add("$($target.label): 截图后检测到作品自动跳转，已丢弃该帧")
            Remove-Item -LiteralPath $fullFramePath, $cropFramePath -Force -ErrorAction SilentlyContinue
            continue
        }
        if ($target.kind -eq "cover") {
            Copy-Item -LiteralPath $cropFramePath -Destination (Join-Path $Folder "cover.jpg") -Force
        }
        $frameRecords.Add([ordered]@{
            label = [string]$target.label
            second = [double]$target.second
            full_frame_path = (RelPath $fullFramePath $PackageDir)
            video_crop_path = (RelPath $cropFramePath $PackageDir)
            path = (RelPath $cropFramePath $PackageDir)
            video_rect = $capture.rect
        })
        $ocrItems.Add((InvokeFrameOcr $fullFramePath $cropFramePath ([string]$target.label) $PackageDir))
    }
    $contactPath = Join-Path $Folder "frames_contact_sheet.jpg"
    $sheetFrames = @($frameRecords | ForEach-Object {
        [ordered]@{ label = $_.label; path = (Join-Path $PackageDir $_.video_crop_path) }
    })
    NewContactSheet $sheetFrames $contactPath 300
    Set-Content -LiteralPath (Join-Path $Folder "ocr_items.json") -Encoding UTF8 -Value (ConvertToJsonArray ($ocrItems.ToArray()) 20)
    $okOcr = @($ocrItems | Where-Object { $_.ocr_status -eq "ok" }).Count
    $cleanOcr = @($ocrItems | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.clean_text) }).Count
    $qualityOcr = @($ocrItems | Where-Object {
        $t = [string]$_.clean_text
        -not [string]::IsNullOrWhiteSpace($t) -and $t -match "门店|地址|导航|电话|营业|时间|套餐|团购|价格|人均|菜|酒|活动|优惠|到店|预约|包间|西海岸|叁两|[¥￥]\s*[0-9]|[0-9]+\s*元"
    }).Count
    $ocrStatusValue = if ($okOcr -gt 0) {
        if ($qualityOcr -gt 0) { "ok" }
        elseif ($cleanOcr -gt 0) { "ok_but_low_confidence" }
        else { "partial_low_quality" }
    } else {
        "failed"
    }
    $durationValue = if ($duration -gt 0) { [Math]::Round($duration, 2) } else { $null }
    $durationStatus = if ($duration -gt 0) {
        "ok"
    } elseif ($frameRecords.Count -gt 0 -and $cropErrors.Count -eq 0) {
        "unavailable_but_frames_ok"
    } else {
        "unavailable"
    }
    return [ordered]@{
        duration_seconds = $durationValue
        duration_status = $durationStatus
        media_type = $mediaType
        frame_strategy = "dense_first_5s_then_every_3s"
        frame_count = $frameRecords.Count
        contact_sheet_path = (RelPath $contactPath $PackageDir)
        full_frame_dir = (RelPath $fullDir $PackageDir)
        video_crop_dir = (RelPath $cropDir $PackageDir)
        frames = @($frameRecords.ToArray())
        ocr_items = @($ocrItems.ToArray())
        visual_rhythm_analysis = NewVisualRhythmAnalysis $duration ($ocrItems.ToArray())
        frame_status = $(if ($frameRecords.Count -gt 0 -and $frameErrors.Count -eq 0) { "ok" } elseif ($frameRecords.Count -gt 0) { "partial" } else { "failed" })
        video_crop_status = $(if ($frameRecords.Count -gt 0 -and $cropErrors.Count -eq 0) { "ok" } elseif ($frameRecords.Count -gt 0) { "partial" } else { "failed" })
        ocr_status = $ocrStatusValue
        frame_errors = @($frameErrors.ToArray())
        video_crop_errors = @($cropErrors.ToArray())
    }
}

function ClearFrameOutputs([string]$Folder, [string]$FramesDir) {
    foreach ($path in @(
        (Join-Path $FramesDir "full_frame"),
        (Join-Path $FramesDir "video_crop")
    )) {
        if (Test-Path -LiteralPath $path) {
            Get-ChildItem -LiteralPath $path -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    foreach ($file in @(
        (Join-Path $Folder "cover.jpg"),
        (Join-Path $Folder "frames_contact_sheet.jpg"),
        (Join-Path $Folder "ocr_items.json")
    )) {
        Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
    }
}

function WaitWorkMediaReady([string]$ExpectedWorkId, $LogBox, [int]$TimeoutMs = 8000) {
    $deadline = (Get-Date).AddMilliseconds($TimeoutMs)
    while ((Get-Date) -lt $deadline) {
        if (-not [string]::IsNullOrWhiteSpace($ExpectedWorkId)) {
            $currentId = GetWorkId (Compact (Js "location.href"))
            if ($currentId -ne $ExpectedWorkId) {
                Start-Sleep -Milliseconds 350
                continue
            }
        }
        $state = $null
        try {
            $state = Js @"
JSON.stringify((() => {
  const visible = el => {
    if (!el) return false;
    const r = el.getBoundingClientRect();
    if (r.width < 80 || r.height < 80 || r.bottom < 0 || r.right < 0 || r.top > innerHeight || r.left > innerWidth) return false;
    const s = getComputedStyle(el);
    return s.display !== 'none' && s.visibility !== 'hidden' && Number(s.opacity) !== 0;
  };
  const videos = Array.from(document.querySelectorAll('video')).filter(visible);
  const images = Array.from(document.querySelectorAll('img')).filter(visible).filter(img => img.naturalWidth > 180 && img.naturalHeight > 180);
  const canvases = Array.from(document.querySelectorAll('canvas')).filter(visible);
  const playable = videos.filter(v => v.readyState >= 1 || Number.isFinite(v.duration));
  const croppable = videos.length + images.length + canvases.length;
  return {
    video_count: videos.length,
    playable_video_count: playable.length,
    image_count: images.length,
    canvas_count: canvases.length,
    croppable_count: croppable,
    ready: playable.length > 0 || images.length > 0 || canvases.length > 0,
    duration: playable.length ? playable[0].duration : 0
  };
})())
"@ | ConvertFrom-Json
        } catch {}
        if ($null -ne $state -and $state.ready) {
            PauseAndLockCurrentWork $ExpectedWorkId
            return $true
        }
        Start-Sleep -Milliseconds 450
    }
    Log $LogBox "等待作品媒体加载超时，准备继续尝试抽帧。"
    return $false
}

function TestFrameCaptureUsable($FrameInfo, [string]$PackageDir) {
    if ($null -eq $FrameInfo) { return $false }
    if ([string]$FrameInfo.frame_status -eq "failed" -or [string]$FrameInfo.video_crop_status -eq "failed") { return $false }
    if ([string]::IsNullOrWhiteSpace([string]$FrameInfo.contact_sheet_path)) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $PackageDir ([string]$FrameInfo.contact_sheet_path)))) { return $false }
    $framePaths = @($FrameInfo.frames | ForEach-Object { [string]$_.video_crop_path })
    foreach ($core in @("cover.jpg","0s.jpg","1s.jpg","2s.jpg","3s.jpg","ending.jpg")) {
        $found = $false
        foreach ($p in $framePaths) {
            if ($p -and $p.Replace('\','/') -like "*/$core") { $found = $true; break }
        }
        if (-not $found) { return $false }
    }
    return $true
}

function CaptureWorkFramesWithRetry([string]$Folder, [string]$FramesDir, [string]$PackageDir, [string]$WorkUrl = "", [string]$ExpectedWorkId = "", $LogBox = $null) {
    $best = $null
    for ($attempt = 0; $attempt -lt 3; $attempt++) {
        if ($attempt -gt 0) {
            Log $LogBox "关键帧或视频裁剪不完整，重新打开原作品并重试第 $attempt 次。"
            ClearFrameOutputs $Folder $FramesDir
            if (-not [string]::IsNullOrWhiteSpace($WorkUrl)) {
                [void](EnsureWorkStillOpen $WorkUrl $ExpectedWorkId $LogBox "抽帧重试前")
                NavFast $WorkUrl
                Start-Sleep -Milliseconds 1400
            }
        }
        PauseAndLockCurrentWork $ExpectedWorkId
        if (-not [string]::IsNullOrWhiteSpace($ExpectedWorkId) -and -not [string]::IsNullOrWhiteSpace($WorkUrl)) {
            [void](EnsureWorkStillOpen $WorkUrl $ExpectedWorkId $LogBox "抽帧尝试 $attempt 前")
        }
        [void](WaitWorkMediaReady $ExpectedWorkId $LogBox $(if ($attempt -eq 0) { 12000 } else { 15000 }))
        $info = CaptureWorkFrames $Folder $FramesDir $PackageDir $WorkUrl $ExpectedWorkId $LogBox
        $info | Add-Member -NotePropertyName frame_retry_count -NotePropertyValue $attempt -Force
        if ($null -eq $best -or [int]$info.frame_count -gt [int]$best.frame_count) { $best = $info }
        if (TestFrameCaptureUsable $info $PackageDir) { return $info }
    }
    if ($null -eq $best) {
        return [ordered]@{
            duration_seconds = $null
            duration_status = "unavailable"
            media_type = "unknown"
            frame_strategy = "dense_first_5s_then_every_3s"
            frame_count = 0
            frame_retry_count = 2
            contact_sheet_path = ""
            full_frame_dir = (RelPath (Join-Path $FramesDir "full_frame") $PackageDir)
            video_crop_dir = (RelPath (Join-Path $FramesDir "video_crop") $PackageDir)
            frames = @()
            ocr_items = @()
            visual_rhythm_analysis = ""
            frame_status = "failed"
            video_crop_status = "failed"
            ocr_status = "failed"
            frame_errors = @("多次重试后仍未生成关键帧")
            video_crop_errors = @("多次重试后仍未生成视频裁剪帧")
        }
    }
    $errors = @($best.frame_errors) + @("多次重试后仍未生成完整核心关键帧或 frames_contact_sheet")
    $best | Add-Member -NotePropertyName frame_errors -NotePropertyValue $errors -Force
    $best | Add-Member -NotePropertyName frame_retry_count -NotePropertyValue 2 -Force
    return $best
}

function EnsureCommentsPanelOpen($LogBox, [string]$ExpectedLike = "") {
    $expectedLikeB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($(if ($null -eq $ExpectedLike) { "" } else { $ExpectedLike })))
    $stateJson = Js @"
JSON.stringify((() => {
  const expectedLike = atob('$expectedLikeB64');
  const toNumberText = t => {
    t = (t || '').replace(/\s+/g, '').trim();
    const m = t.match(/^([0-9.]+)(万|w)?$/i);
    if (!m) return '';
    const n = parseFloat(m[1]);
    if (!isFinite(n)) return '';
    return String(Math.round(n * (m[2] ? 10000 : 1)));
  };
  const visible = el => {
    if (!el) return false;
    const r = el.getBoundingClientRect();
    if (r.width < 8 || r.height < 8 || r.bottom < 0 || r.right < 0 || r.top > innerHeight || r.left > innerWidth) return false;
    const s = getComputedStyle(el);
    return s.display !== 'none' && s.visibility !== 'hidden' && Number(s.opacity) !== 0;
  };
    const videos = Array.from(document.querySelectorAll('video')).map(v => v.getBoundingClientRect())
      .filter(r => r.width > 240 && r.height > 240 && r.bottom > 0 && r.right > 0)
      .sort((a,b) => (b.width*b.height) - (a.width*a.height));
    const vr = videos[0] || { left: 0, right: innerWidth, top: 0, bottom: innerHeight, width: innerWidth, height: innerHeight };
    const rail = x => {
      const r = x.r;
      return r.left >= vr.left + vr.width * 0.55 &&
        r.right <= Math.min(innerWidth, vr.right + 180) &&
        r.top >= vr.top + vr.height * 0.24 &&
        r.top <= vr.top + vr.height * 0.86;
    };
    const els = Array.from(document.querySelectorAll('button,[role=button],a,div,span,svg'))
      .filter(visible)
      .map(el => {
        const r = el.getBoundingClientRect();
        const text = (el.innerText || el.getAttribute('aria-label') || el.getAttribute('title') || el.getAttribute('data-e2e') || el.getAttribute('class') || '').replace(/\s+/g, ' ').trim();
        return { el, r, text };
      })
      .filter(x => rail(x));
    const rawLabels = els
      .filter(x => /抢首评|^[0-9]+$|^[0-9.]+万$|^[0-9.]+w$/i.test(x.text) && !/点赞|喜欢|收藏|分享/.test(x.text))
      .filter(x => x.r.width <= 110 && x.r.height <= 58)
      .sort((a,b) => (a.r.top - b.r.top) || ((a.r.width*a.r.height) - (b.r.width*b.r.height)));
    const labels = [];
    for (const x of rawLabels) {
      const cx = x.r.left + x.r.width / 2;
      const duplicate = labels.some(y => {
        const ycx = y.r.left + y.r.width / 2;
        return Math.abs(y.r.top - x.r.top) < 9 && Math.abs(ycx - cx) < 12 && y.text === x.text;
      });
      if (!duplicate) labels.push(x);
    }
    let best = els
      .filter(x => /评论|comment|抢首评/i.test(x.text) && !/点赞|like|喜欢|收藏|favorite|分享|share/i.test(x.text))
      .sort((a,b) => (b.r.width*b.r.height) - (a.r.width*a.r.height))[0] || null;
    const expectedLikeNorm = toNumberText(expectedLike);
    const likeLabel = expectedLikeNorm ? labels.find(x => toNumberText(x.text) === expectedLikeNorm) : null;
    if (likeLabel) {
      const likeCx = likeLabel.r.left + likeLabel.r.width / 2;
      const below = labels
        .filter(x => x.r.top > likeLabel.r.top + 8 && Math.abs((x.r.left + x.r.width / 2) - likeCx) < 70)
        .sort((a,b) => a.r.top - b.r.top);
      if (below.length) best = below[0];
    } else if (best && !/抢首评|[0-9]/.test(best.text)) {
      const cx = best.r.left + best.r.width / 2;
      const nearLabel = labels.find(x => Math.abs((x.r.left + x.r.width / 2) - cx) < 52 && x.r.top >= best.r.top - 12 && x.r.top <= best.r.bottom + 72);
      if (nearLabel) best = nearLabel;
    }
    if (!best) {
      const firstNoComment = labels.find(x => /抢首评/.test(x.text));
      if (firstNoComment) {
        best = firstNoComment;
      } else if (labels.length >= 2) {
        best = labels[1];
      }
    }
    const label = best ? best.text : '';
    const m = label.match(/([0-9]+)/);
    return {
      label,
      count: /抢首评/.test(label) ? 0 : (m ? parseInt(m[1], 10) : null),
      has_comments: !!(m && parseInt(m[1], 10) > 0),
      no_comments: /抢首评/.test(label),
      can_open: !!best && !/抢首评/.test(label),
      like_matched: expectedLikeNorm ? !!likeLabel : true,
      video_rect: { left: vr.left, top: vr.top, right: vr.right, bottom: vr.bottom, width: vr.width, height: vr.height }
    };
})())
"@
    try {
        $state = $stateJson | ConvertFrom-Json
        if ($state.no_comments -or $state.count -eq 0) {
            $result = [pscustomobject]@{ opened = $false; skipped = $true; has_comments = $false; comment_count = 0; label = [string]$state.label; like_matched = [bool]$state.like_matched; text_hint = "评论按钮显示抢首评或0评论，不打开评论区" }
        } else {
            Js "try { if (document.activeElement) document.activeElement.blur(); document.body && document.body.focus && document.body.focus(); } catch(e) {}; true" | Out-Null
            Cdp "Input.dispatchKeyEvent" @{ type = "rawKeyDown"; windowsVirtualKeyCode = 88; nativeVirtualKeyCode = 88; code = "KeyX"; key = "x" } | Out-Null
            Cdp "Input.dispatchKeyEvent" @{ type = "char"; text = "x"; unmodifiedText = "x"; windowsVirtualKeyCode = 88; nativeVirtualKeyCode = 88; code = "KeyX"; key = "x" } | Out-Null
            Cdp "Input.dispatchKeyEvent" @{ type = "keyUp"; windowsVirtualKeyCode = 88; nativeVirtualKeyCode = 88; code = "KeyX"; key = "x" } | Out-Null
            Start-Sleep -Milliseconds 1400
            $openedJson = Js @"
JSON.stringify((() => {
  const txt = (document.body && document.body.innerText || '').replace(/\s+/g, ' ').trim();
  const candidates = Array.from(document.querySelectorAll('div,section,aside')).filter(el => {
    const r = el.getBoundingClientRect();
    const text = (el.innerText || '').replace(/\s+/g, ' ').trim();
    if (r.height < 120 || r.width < 220 || r.right < innerWidth * 0.45) return false;
    return /评论|全部评论|条评论|抢首评|暂无评论|还没有评论/.test(text) &&
      !/京ICP备|京公网安备|用户服务协议|广告投放|粉丝|获赞|作品\s*\d+|分享主页/.test(text);
  });
  const opened = candidates.length > 0 || /全部评论|评论区|条评论|暂无评论|还没有评论/.test(txt);
  return { opened, panel_count: candidates.length };
})())
"@
            $openedState = $openedJson | ConvertFrom-Json
            $result = [pscustomobject]@{ opened = [bool]$openedState.opened; skipped = $false; has_comments = [bool]$state.has_comments; comment_count = $state.count; label = [string]$state.label; like_matched = [bool]$state.like_matched; text_hint = $(if ($openedState.opened) { "已按键盘 X 打开评论区" } else { "已按键盘 X，但未检测到评论面板" }) }
        }
        if ($result.skipped) {
            Log $LogBox "评论按钮状态：$($result.label)，无评论，跳过评论面板。"
        } elseif ($result.opened) {
            Log $LogBox "已尝试打开评论面板：$($result.text_hint)"
        } else {
            Log $LogBox "未能确认评论面板已打开：$($result.text_hint)；评论按钮=$($result.label)"
        }
        return $result
    } catch {
        Log $LogBox "打开评论面板时出错：$($_.Exception.Message)"
        return [ordered]@{ opened = $false; skipped = $false; has_comments = $false; comment_count = $null; label = ""; like_matched = $false; text_hint = $_.Exception.Message }
    }
}

function CollectVisibleComments {
    $authorB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($(if ($Script:TargetProfileName) { $Script:TargetProfileName } else { "" })))
    $json = Js @"
(async () => {
  const fromB64 = s => new TextDecoder('utf-8').decode(Uint8Array.from(atob(s), c => c.charCodeAt(0)));
  let targetAuthor = fromB64('$authorB64');
  if (!targetAuthor) {
    targetAuthor = (document.title || '').replace(/\s*-\s*抖音.*$/, '').replace(/的抖音$/, '').replace(/\s+/g, ' ').trim();
  }
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const clean = t => (t || '').replace(/\s+/g, ' ').trim();
  const isBad = t => {
    t = clean(t);
    if (!t || t.length < 2 || t.length > 260) return true;
    if (/^[\d\s.,万亿wWkK赞点赞回复:：-]+$/.test(t)) return true;
    if (/抢首评|暂无评论|还没有评论|说点什么|发一条友好的弹幕|发送|登录后|倍速|清屏|连播|听抖音|识别画面|TA的作品|相关推荐|相关搜索|大家都在搜|汽水音乐|声明：|虚构演绎|热门|全部评论|^\s*评论\s*$|720P|540P|0\.75x|1\.0x|1\.25x|1\.5x|1\.75x|2\.0x|3\.0x|高清|标清|智能/.test(t)) return true;
    return false;
  };
  const candidates = Array.from(document.querySelectorAll('div,section,aside'))
    .filter(el => {
      const r = el.getBoundingClientRect();
      const txt = el.innerText || '';
      if (r.height < 120 || r.width < 220) return false;
      if (r.right < innerWidth * 0.45) return false;
      if (!/评论|全部评论|条评论|抢首评|暂无评论|还没有评论/.test(txt)) return false;
      if (/京ICP备|京公网安备|用户服务协议|广告投放|粉丝|获赞|作品\\s*\\d+|分享主页/.test(txt)) return false;
      return true;
    });
  const out = [];
  const seen = new Set();
  const rawCommentsDebug = [];
  let filteredAuthorReplyCount = 0;
  let filteredBadCount = 0;
  const scrollableCandidates = candidates.filter(el => (el.scrollHeight || 0) > (el.clientHeight || 0) + 40);
  const scroller = (scrollableCandidates.length ? scrollableCandidates : candidates)
    .sort((a,b)=>(b.scrollHeight-b.clientHeight)-(a.scrollHeight-a.clientHeight))[0] || null;
  const nestedScrollers = scroller ? Array.from(scroller.querySelectorAll('*'))
    .filter(el => (el.scrollHeight || 0) > (el.clientHeight || 0) + 40)
    .sort((a,b)=>(b.scrollHeight-b.clientHeight)-(a.scrollHeight-a.clientHeight)) : [];
  const scrollTarget = nestedScrollers[0] || scroller || null;
  const root = scroller || null;
  const addComment = (raw, sourceHint = '') => {
    raw = clean(raw);
    if (sourceHint === 'line_fallback') {
      rawCommentsDebug.push({ text: raw, source_hint: sourceHint, reason: 'line_fallback 未确认评论结构，未写入正式 comments.items' });
      return;
    }
    if (!raw || /作者回复|商家回复|店家回复|回复作者|作者.*回复/.test(raw)) { filteredAuthorReplyCount++; return; }
    let parts = raw.split(/\s+/).map(clean).filter(Boolean);
    let author = '';
    let created = '';
    let like = '';
    for (const p of parts) {
      if (!author && p.length >= 2 && p.length <= 24 && !/[？?。！，,!]/.test(p) && !/^\d/.test(p) && !/评论|回复|点赞|赞$|作者|商家|店家|展开|全部/.test(p)) author = p;
      if (!created && /(\d{1,2}[-月]\d{1,2}|20\d{2}[-年]\d{1,2}|\d+\s*(分钟前|小时前|天前|周前|月前|年前)|刚刚|昨天)/.test(p)) created = p;
      if (!like && /^([0-9.万亿wWkK]+)(赞|点赞)?$/.test(p)) like = p.replace(/赞|点赞/g,'');
    }
    if (!author || author === '...' || /^@/.test(author)) { filteredBadCount++; return; }
    if (/^(分享|评论|全部评论|回复|点赞|赞过|发送|更多)$/.test(author)) { filteredBadCount++; return; }
    if (/^#/.test(author) || /闽侯县甘蔗鑫满园餐饮店/.test(author)) { filteredBadCount++; return; }
    if (targetAuthor && author && (targetAuthor.includes(author) || author.includes(targetAuthor))) { filteredAuthorReplyCount++; return; }
    if (!created) { filteredBadCount++; return; }
    let text = raw;
    if (author) text = clean(text.replace(author, ''));
    if (created) text = clean(text.replace(created, ''));
    if (like) text = clean(text.replace(new RegExp(like.replace(/[\\^`$.*+?()[\]{}|]/g,'\\$&') + '(赞|点赞)?'), ''));
    if (!/[0-9]/.test(like || '')) like = '';
    text = clean(text.replace(/回复|作者|置顶|展开\d*条?回复|分享|赞过/g, ''));
    text = clean(text.replace(/赞过\s*[0-9.万亿wWkK]+$/g, '').replace(/[0-9.万亿wWkK]+$/g, ''));
    if (/^#/.test(text) || /^@/.test(text) || /科隆major|Team Spirit/i.test(text)) { filteredBadCount++; return; }
    if (isBad(text) || seen.has(text)) { filteredBadCount++; return; }
    seen.add(text);
    out.push({
      text,
      like_count: like || '',
      created_at_raw: created || '',
      author_name: author || '',
      is_author_reply: false,
      source_hint: sourceHint
    });
  };
  const collectFromLines = () => {
    if (!root) return;
    const lines = (root.innerText || '').split(/\n+/).map(clean).filter(Boolean);
    for (let i = 0; i < lines.length && out.length < 20; i++) {
      if (!/(\d{1,2}[-月]\d{1,2}|20\d{2}[-年]\d{1,2}|\d+\s*(分钟前|小时前|天前|周前|月前|年前)|刚刚|昨天)/.test(lines[i])) continue;
      const windowText = lines.slice(Math.max(0, i - 4), Math.min(lines.length, i + 3)).join(' ');
      if (/作者回复|商家回复|店家回复|回复作者|抢首评/.test(windowText)) continue;
      const before = lines.slice(Math.max(0, i - 4), i).filter(x => !isBad(x) && !/^[0-9.万亿wWkK]+(赞|点赞)?$/.test(x) && !/^回复$/.test(x));
      if (before.length < 2) continue;
      const author = before[0];
      const text = before.slice(1).join(' ');
      if (!author || !text || author.length > 24 || /^@/.test(author)) continue;
      addComment([author, text, lines[i]].join(' '), 'line_fallback');
    }
    const isMeta = x => /(\d{1,2}[-月]\d{1,2}|20\d{2}[-年]\d{1,2}|\d+\s*(分钟前|小时前|天前|周前|月前|年前)|刚刚|昨天|回复|展开\d*条?回复|^[0-9.万亿wWkK]+(赞|点赞)?$)/.test(x);
    const isAuthorLine = x => {
      x = clean(x);
      if (!x || x.length < 2 || x.length > 24) return false;
      if (isBad(x) || isMeta(x) || /^[@#]/.test(x)) return false;
      if (/[？?。！，,!：:]/.test(x)) return false;
      if (/大家都在搜|汽水音乐|同城福利来袭/.test(x)) return false;
      if (targetAuthor && (targetAuthor.includes(x) || x.includes(targetAuthor))) return false;
      return true;
    };
    for (let i = 0; i < lines.length - 1 && out.length < 20; i++) {
      const author = lines[i];
      const text = lines[i + 1];
      if (!isAuthorLine(author) || isBad(text) || isMeta(text)) continue;
      const created = (i + 2 < lines.length && isMeta(lines[i + 2])) ? lines[i + 2] : '';
      if (!created) continue;
      const windowText = lines.slice(Math.max(0, i - 2), Math.min(lines.length, i + 5)).join(' ');
      if (/作者回复|商家回复|店家回复|回复作者|抢首评/.test(windowText)) continue;
      addComment([author, text, created].join(' '), 'line_pair');
    }
  };
  const collectOnce = () => {
    if (!root) return;
    const nodes = Array.from(root.querySelectorAll('[data-e2e*=comment], [class*=comment], [class*=reply], li, div'))
      .filter(el => {
        const r = el.getBoundingClientRect();
        const t = clean(el.innerText);
        if (r.width < 120 || r.height < 18 || r.height > 280) return false;
        if (/京ICP备|京公网安备|用户服务协议|广告投放|粉丝|获赞|分享主页|下载电脑客户端|搜索 Ta 的作品|倍速|清屏|连播|听抖音|识别画面|TA的作品|相关推荐|相关搜索|声明：|虚构演绎|全部评论|720P|540P|高清|标清/.test(t)) return false;
        return t.length >= 2 && t.length < 650 && !isBad(t);
      });
    for (const el of nodes) {
      addComment(el.innerText, 'dom_node');
      if (out.length >= 20) break;
    }
    collectFromLines();
  };
  if (scroller) {
    try { if (scrollTarget) scrollTarget.scrollTop = 0; scroller.scrollTop = 0; } catch(e) {}
    await sleep(450);
    let noMove = 0;
    for (let i=0; i<60 && out.length < 20; i++) {
      collectOnce();
      if (out.length >= 20) break;
      const target = scrollTarget || scroller;
      const beforeTop = target.scrollTop;
      const step = Math.max(180, Math.floor((target.clientHeight || scroller.clientHeight || 520) * 0.55));
      try {
        if (target.setAttribute) target.setAttribute('tabindex','-1');
        if (target.focus) target.focus({ preventScroll: true });
        if (target.scrollBy) target.scrollBy({ top: step, behavior: 'instant' });
        target.scrollTop = Math.min(target.scrollHeight, target.scrollTop + step);
        const rr = target.getBoundingClientRect();
        const x = Math.max(8, Math.min(innerWidth - 8, rr.left + rr.width / 2));
        const y = Math.max(8, Math.min(innerHeight - 8, rr.top + Math.min(rr.height - 8, Math.max(20, rr.height / 2))));
        target.dispatchEvent(new WheelEvent('wheel', { bubbles:true, cancelable:true, clientX:x, clientY:y, deltaY: step }));
        if (target !== scroller) scroller.dispatchEvent(new WheelEvent('wheel', { bubbles:true, cancelable:true, clientX:x, clientY:y, deltaY: step }));
        target.dispatchEvent(new KeyboardEvent('keydown', { bubbles:true, cancelable:true, key:'PageDown', code:'PageDown' }));
        target.dispatchEvent(new Event('scroll', { bubbles:true }));
        if (target !== scroller) scroller.dispatchEvent(new Event('scroll', { bubbles:true }));
      } catch(e) {}
      await sleep(760);
      if (Math.abs(target.scrollTop - beforeTop) < 4) noMove++; else noMove = 0;
      if (noMove === 3) {
        try {
          target.dispatchEvent(new KeyboardEvent('keydown', { bubbles:true, cancelable:true, key:'End', code:'End' }));
          target.scrollTop = Math.min(target.scrollHeight, target.scrollTop + step * 2);
          target.dispatchEvent(new Event('scroll', { bubbles:true }));
        } catch(e) {}
        await sleep(900);
      }
      if (noMove >= 6) break;
    }
    collectOnce();
  }
  return JSON.stringify({
    comments_status: out.length ? 'ok' : (scroller ? 'empty' : 'auth_or_login_required'),
    comments_reason: out.length ? '' : (scroller ? '未检测到真实可用评论，已过滤纯数字/抢首评/占位文本。' : '未找到可滚动评论区，可能需要登录、作品评论权限或手动展开评论面板。'),
    items: out,
    raw_comments_debug: rawCommentsDebug,
    filtered_author_reply_count: filteredAuthorReplyCount,
    filtered_bad_count: filteredBadCount,
    source: 'dom_comment_panel'
  });
})()
"@
    if ([string]::IsNullOrWhiteSpace($json)) {
        return [ordered]@{ comments_status = "auth_or_login_required"; comments_reason = "评论脚本没有返回结果，可能需要登录或页面未展开评论。"; items = @() }
    }
    return ($json | ConvertFrom-Json)
}

function CollectApiComments([string]$VideoId) {
    if ([string]::IsNullOrWhiteSpace($VideoId)) {
        return [ordered]@{ comments_status = "api_unavailable"; comments_reason = "缺少作品 ID，无法尝试同源评论接口。"; items = @() }
    }
    $videoIdB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($VideoId))
    $authorB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($(if ($Script:TargetProfileName) { $Script:TargetProfileName } else { "" })))
    $json = Js @"
(async () => {
  const fromB64 = s => new TextDecoder('utf-8').decode(Uint8Array.from(atob(s), c => c.charCodeAt(0)));
  const videoId = fromB64('$videoIdB64');
  let targetAuthor = fromB64('$authorB64');
  if (!targetAuthor) {
    targetAuthor = clean((document.title || '').replace(/\s*-\s*抖音.*$/, '').replace(/的抖音$/, ''));
  }
  const clean = t => (t || '').replace(/\s+/g, ' ').trim();
  const badText = t => {
    t = clean(t);
    if (!t || t.length < 2 || t.length > 260) return true;
    if (/^[\d\s.,万亿wWkK赞点赞回复:：-]+$/.test(t)) return true;
    if (/抢首评|暂无评论|还没有评论|说点什么|发一条友好的弹幕|发送|登录后|倍速|清屏|连播|听抖音|识别画面|TA的作品|相关推荐|相关搜索|声明：|虚构演绎|热门|全部评论|^\s*评论\s*$|720P|540P|高清|标清|智能/.test(t)) return true;
    return false;
  };
  const isAuthorReply = (name, text) => {
    name = clean(name);
    text = clean(text);
    if (/作者回复|商家回复|店家回复|回复作者/.test(text)) return true;
    if (targetAuthor && name && targetAuthor.includes(name)) return true;
    if (targetAuthor && name && name.includes(targetAuthor)) return true;
    return false;
  };
  const makeUrl = (cursor) => {
    const p = new URLSearchParams({
      aweme_id: videoId,
      cursor: String(cursor || 0),
      count: '20',
      item_type: '0',
      aid: '6383',
      device_platform: 'webapp',
      channel: 'channel_pc_web',
      pc_client_type: '1',
      version_code: '190500',
      version_name: '19.5.0',
      cookie_enabled: String(navigator.cookieEnabled),
      browser_language: navigator.language || 'zh-CN',
      browser_platform: navigator.platform || 'Win32',
      browser_name: 'Edge',
      browser_online: String(navigator.onLine),
      engine_name: 'Blink',
      os_name: 'Windows',
      platform: 'PC',
      screen_width: String(screen.width || innerWidth),
      screen_height: String(screen.height || innerHeight)
    });
    return '/aweme/v1/web/comment/list/?' + p.toString();
  };
  const makeReplyUrl = (commentId, cursor) => {
    const p = new URLSearchParams({
      aweme_id: videoId,
      item_id: videoId,
      comment_id: String(commentId || ''),
      cursor: String(cursor || 0),
      count: '20',
      item_type: '0',
      aid: '6383',
      device_platform: 'webapp',
      channel: 'channel_pc_web',
      pc_client_type: '1',
      version_code: '190500',
      version_name: '19.5.0',
      cookie_enabled: String(navigator.cookieEnabled),
      browser_language: navigator.language || 'zh-CN',
      browser_platform: navigator.platform || 'Win32',
      browser_name: 'Edge',
      browser_online: String(navigator.onLine),
      engine_name: 'Blink',
      os_name: 'Windows',
      platform: 'PC',
      screen_width: String(screen.width || innerWidth),
      screen_height: String(screen.height || innerHeight)
    });
    return '/aweme/v1/web/comment/list/reply/?' + p.toString();
  };
  const pushComment = (c, sourceHint) => {
    const commentText = clean(c.text || c.text_extra_text || '');
    const author = clean((c.user && (c.user.nickname || c.user.unique_id || c.user.short_id)) || '');
    if (!author || badText(commentText)) { filtered_bad_count++; return false; }
    if (isAuthorReply(author, commentText)) { filtered_author_reply_count++; return false; }
    const key = author + '|' + commentText;
    if (seen.has(key)) return false;
    seen.add(key);
    const ts = Number(c.create_time || 0);
    const created = ts ? new Date(ts * 1000).toLocaleDateString('zh-CN') : '';
    out.push({
      text: commentText,
      like_count: c.digg_count == null ? '' : String(c.digg_count),
      created_at_raw: created,
      author_name: author,
      is_author_reply: false,
      source_hint: sourceHint
    });
    return true;
  };
  const out = [];
  const seen = new Set();
  const replyTargets = [];
  let raw_comment_count = 0;
  let raw_reply_count = 0;
  let filtered_author_reply_count = 0;
  let filtered_bad_count = 0;
  let cursor = 0;
  let lastStatus = '';
  let lastError = '';
  for (let page = 0; page < 4 && out.length < 20; page++) {
    try {
      const resp = await fetch(makeUrl(cursor), {
        credentials: 'include',
        headers: {
          'accept': 'application/json, text/plain, */*',
          'x-requested-with': 'XMLHttpRequest'
        },
        referrer: location.href
      });
      lastStatus = String(resp.status);
      const text = await resp.text();
      let data = null;
      try { data = JSON.parse(text); } catch(e) {
        lastError = '评论接口返回非 JSON：' + text.slice(0, 120);
        break;
      }
      const comments = Array.isArray(data.comments) ? data.comments : [];
      raw_comment_count += comments.length;
      for (const c of comments) {
        pushComment(c, 'web_comment_api');
        const cid = c.cid || c.comment_id || c.id_str || c.id;
        const replyTotal = Number(c.reply_comment_total || c.reply_comment_total_count || c.reply_count || 0);
        if (cid && replyTotal > 0) replyTargets.push({ cid: String(cid), replyTotal });
        if (out.length >= 20) break;
      }
      if (!data.has_more && !data.cursor) break;
      const nextCursor = Number(data.cursor || 0);
      if (!Number.isFinite(nextCursor) || nextCursor === cursor) break;
      cursor = nextCursor;
    } catch(e) {
      lastError = String(e && e.message ? e.message : e);
      break;
    }
  }
  for (const target of replyTargets) {
    if (out.length >= 20) break;
    let replyCursor = 0;
    for (let page = 0; page < 3 && out.length < 20; page++) {
      try {
        const resp = await fetch(makeReplyUrl(target.cid, replyCursor), {
          credentials: 'include',
          headers: {
            'accept': 'application/json, text/plain, */*',
            'x-requested-with': 'XMLHttpRequest'
          },
          referrer: location.href
        });
        lastStatus = String(resp.status);
        const text = await resp.text();
        let data = null;
        try { data = JSON.parse(text); } catch(e) {
          lastError = '评论回复接口返回非 JSON：' + text.slice(0, 120);
          break;
        }
        const replies = Array.isArray(data.comments) ? data.comments : [];
        raw_reply_count += replies.length;
        for (const reply of replies) {
          pushComment(reply, 'web_comment_reply_api');
          if (out.length >= 20) break;
        }
        if (!data.has_more && !data.cursor) break;
        const nextCursor = Number(data.cursor || 0);
        if (!Number.isFinite(nextCursor) || nextCursor === replyCursor) break;
        replyCursor = nextCursor;
      } catch(e) {
        lastError = String(e && e.message ? e.message : e);
        break;
      }
    }
  }
  return JSON.stringify({
    comments_status: out.length ? 'ok' : 'api_unavailable',
    comments_reason: out.length ? '' : ('同源评论接口不可用或未返回可用评论；status=' + lastStatus + '；' + lastError),
    items: out,
    api_status: lastStatus,
    raw_comment_count,
    raw_reply_count,
    filtered_author_reply_count,
    filtered_bad_count,
    source: 'web_comment_api'
  });
})()
"@
    if ([string]::IsNullOrWhiteSpace($json)) {
        return [ordered]@{ comments_status = "api_unavailable"; comments_reason = "同源评论接口脚本没有返回结果。"; items = @() }
    }
    try {
        return ($json | ConvertFrom-Json)
    } catch {
        return [ordered]@{ comments_status = "api_unavailable"; comments_reason = "同源评论接口结果解析失败：$($_.Exception.Message)"; items = @() }
    }
}

function CollectDetailMeta {
    $json = Js @"
JSON.stringify((() => {
  const pick = (sel, attr='content') => {
    const el = document.querySelector(sel);
    return el ? (attr === 'text' ? el.innerText : el.getAttribute(attr)) || '' : '';
  };
  const bodyText = document.body ? document.body.innerText : '';
  const metaTitle = pick('meta[property="og:title"]') || pick('meta[name="description"]') || document.title || '';
  const selectors = [
    '[data-e2e*=desc]', '[class*=desc]', '[class*=title]', '[class*=content]',
    'h1', 'h2', '[aria-label]'
  ];
  const titleCandidates = [];
  for (const sel of selectors) {
    for (const el of Array.from(document.querySelectorAll(sel)).slice(0,80)) {
      const text = (el.innerText || el.getAttribute('aria-label') || '').trim();
      if (text && text.length > 2 && text.length < 160) titleCandidates.push(text);
    }
  }
  const captions = Array.from(document.querySelectorAll('[class*=caption], [class*=subtitle], [class*=text], track'))
    .map(el => el.innerText || el.label || '').filter(t => t.trim().length > 2).slice(0, 80);
  return { bodyText, metaTitle, titleCandidates, captions, currentUrl: location.href };
})())
"@
    return ($json | ConvertFrom-Json)
}

function CollectLinks([string]$HomeUrl, [int]$Limit, $LogBox) {
    $requestedLimitForRunMode = $Limit
    Log $LogBox "打开主页：$HomeUrl"
    Nav $HomeUrl
    WaitManual $LogBox
    Log $LogBox "正在自动检查是否已进入账号主页和作品列表。"
    WaitProfileReady $HomeUrl $LogBox
    if ($Script:CurrentPackage -and (Test-Path $Script:CurrentPackage)) {
        CaptureHomepageArtifacts $Script:CurrentPackage $Limit $LogBox
    }
    if (-not $Script:IsTestMode -and $Script:TargetWorksCount -gt 0) {
        if ($Limit -lt 30) {
            $requestedLimit = [Math]::Min($Limit, $Script:TargetWorksCount)
            Log $LogBox "正式模式按指定数量采集：账号作品 $Script:TargetWorksCount 条，本次采集最近 $requestedLimit 条。"
            $Limit = $requestedLimit
        } else {
            $autoLimit = [Math]::Min(30, $Script:TargetWorksCount)
            if ($autoLimit -ne $Limit) {
                Log $LogBox "正式模式自动采集数量：账号作品 $Script:TargetWorksCount 条，本次采集最近 $autoLimit 条。"
            }
            $Limit = $autoLimit
        }
    } elseif ($Script:IsTestMode) {
        Log $LogBox "测试模式采集数量：$Limit 条。"
    }
    $Script:EffectiveWorkLimit = $Limit
    SetRunMode $requestedLimitForRunMode $Limit
    $works = New-Object System.Collections.Generic.List[string]
    Log $LogBox "为避免混入推荐视频，本次只通过主页作品卡片点击采集，并在打开后核验作者归属。"
    NavHardHome $HomeUrl
    Js "window.scrollTo(0,0); true" | Out-Null
    Start-Sleep -Milliseconds 900
    $clickedLinks = @(CollectLinksByClickingCards $HomeUrl $Limit $LogBox)
    if ($Script:CurrentPackage -and (Test-Path $Script:CurrentPackage)) {
        $cardRecords = @($Script:CardMetadata.Values | Sort-Object { [int]$_.visual_order } | ForEach-Object {
            [ordered]@{
                visual_order = $_.visual_order
                card_modal_id = $_.modal_id
                opened_modal_id_from_click = $_.opened_modal_id_from_click
                card_text = $_.card_text
                public_card_like_count = $_.public_card_like_count
                row = $_.row
                col = $_.col
                card_bbox = $_.card_bbox
                cover = $_.cover
            }
        })
        Set-Content -LiteralPath (Join-Path $Script:CurrentPackage "card_records.json") -Encoding UTF8 -Value (ConvertToJsonArray $cardRecords 20)
    }
    foreach ($clicked in $clickedLinks) {
        $cleanClicked = NormalizeUrl ([string]$clicked)
        if ([string]::IsNullOrWhiteSpace($cleanClicked)) { continue }
        if ((IsWorkUrl $cleanClicked) -and -not $works.Contains($cleanClicked)) {
            $works.Add($cleanClicked)
        }
        if ($works.Count -ge $Limit) { break }
    }
    return $works.ToArray()
}

function CollectWork([string]$Url, [int]$Index, [string]$PackageDir, $LogBox) {
    Log $LogBox "读取作品 $Index：$Url"
    $videoId = GetWorkId $Url
    $folder = Join-Path $PackageDir ("{0:D3}_{1}" -f $Index, $videoId)
    $frames = Join-Path $folder "frames"
    New-Item -ItemType Directory -Force -Path $frames | Out-Null
    $cardInfo = $null
    if ($Script:CardMetadata.ContainsKey($videoId)) { $cardInfo = $Script:CardMetadata[$videoId] }

    $failureReason = ""
    try {
        Nav $Url
        WaitManual $LogBox
        PauseAndLockCurrentWork $videoId
        if (-not (EnsureWorkStillOpen $Url $videoId $LogBox "打开作品后")) {
            throw "作品打开后发生自动跳转，无法锁定目标作品。"
        }
        if (-not (TestOpenedWorkBelongsToTarget $Url $LogBox)) {
            throw "作品作者与目标账号不一致，已跳过，避免混入推荐视频。"
        }
        Start-Sleep -Milliseconds 500
        PauseAndLockCurrentWork $videoId

        if (-not (EnsureWorkStillOpen $Url $videoId $LogBox "读取标题前")) {
            throw "读取标题前作品已自动跳转，无法锁定目标作品。"
        }
        $meta = CollectDetailMeta
        if (-not (TestOpenedWorkBelongsToTarget $Url $LogBox)) {
            throw "作品作者与目标账号不一致，已跳过，避免混入推荐视频。"
        }
        $openedModalId = GetWorkId (Compact (Js "location.href"))
        if ($openedModalId -eq "unknown") { $openedModalId = $videoId }
        $body = Compact $meta.bodyText
        $title = ""
        foreach ($candidate in @($meta.titleCandidates)) {
            $title = FirstUsefulTitle $candidate $body
            if (-not [string]::IsNullOrWhiteSpace($title)) { break }
        }
        if ([string]::IsNullOrWhiteSpace($title)) {
            $title = FirstUsefulTitle $meta.metaTitle $body
        }
        if ((IsBadExtractedTitle $title) -and $cardInfo -and -not [string]::IsNullOrWhiteSpace([string]$cardInfo.card_text)) {
            $cardTitle = CleanCardTitle ([string]$cardInfo.card_text)
            if (-not [string]::IsNullOrWhiteSpace($cardTitle)) { $title = $cardTitle }
        }
        $detailTitle = $title
        $canonicalTitle = ""
        if ($cardInfo -and -not [string]::IsNullOrWhiteSpace([string]$cardInfo.card_text)) {
            $canonicalTitle = CleanCardTitle ([string]$cardInfo.card_text)
        }
        if ([string]::IsNullOrWhiteSpace($canonicalTitle)) { $canonicalTitle = $detailTitle }
        if ([string]::IsNullOrWhiteSpace($detailTitle)) { $detailTitle = $canonicalTitle }

        $publicCardLike = $null
        if ($cardInfo -and $null -ne $cardInfo.public_card_like_count -and -not [string]::IsNullOrWhiteSpace([string]$cardInfo.public_card_like_count)) {
            $publicCardLike = [string]$cardInfo.public_card_like_count
        }

        if (-not (EnsureWorkStillOpen $Url $videoId $LogBox "抽帧开始前")) {
            throw "抽帧开始前作品已自动跳转，无法锁定目标作品。"
        }
        $frameInfo = CaptureWorkFramesWithRetry $folder $frames $PackageDir $Url $videoId $LogBox
        if (-not (EnsureWorkStillOpen $Url $videoId $LogBox "打开评论前")) {
            throw "打开评论前作品已自动跳转，无法锁定目标作品。"
        }
        $commentOpenState = EnsureCommentsPanelOpen $LogBox $publicCardLike
        $likeMatchedState = if ($null -eq $publicCardLike -or [string]::IsNullOrWhiteSpace([string]$publicCardLike)) { "unknown" } elseif ($commentOpenState.like_matched) { "ok" } else { "missing" }
        $mappingCheck = NewMappingCheck $cardInfo $openedModalId $detailTitle
        if ($commentOpenState.skipped -or $commentOpenState.comment_count -eq 0) {
            $commentResult = [ordered]@{
                comments_status = "empty"
                comments_reason = "评论按钮显示抢首评或0评论，未打开评论区。"
                comment_button_label = [string]$commentOpenState.label
                public_comment_count = 0
                items = @()
            }
        } else {
            if (-not (EnsureWorkStillOpen $Url $videoId $LogBox "采集评论前")) {
                throw "采集评论前作品已自动跳转，无法锁定目标作品。"
            }
            $apiCommentResult = CollectApiComments $videoId
            [void](EnsureWorkStillOpen $Url $videoId $LogBox "采集接口评论后")
            $domCommentResult = CollectVisibleComments
            [void](EnsureWorkStillOpen $Url $videoId $LogBox "采集可见评论后")
            $apiCount = @($apiCommentResult.items).Count
            $domCount = @($domCommentResult.items).Count
            $mergedComments = New-Object System.Collections.Generic.List[object]
            $seenComments = New-Object System.Collections.Generic.List[object]
            function NormalizeCommentKeyText([string]$Text) {
                $t = Compact $Text
                $t = [Regex]::Replace($t, "\[[^\]]+\]", "")
                $t = [Regex]::Replace($t, "[\p{P}\p{S}\s]+", "")
                if ([string]::IsNullOrWhiteSpace($t)) {
                    $t = Compact $Text
                }
                return $t
            }
            foreach ($src in @(@($apiCommentResult.items), @($domCommentResult.items))) {
                foreach ($c in @($src)) {
                    if (-not (IsUsefulCommentItem $c)) { continue }
                    $authorKey = Compact ([string]$c.author_name)
                    $textKey = NormalizeCommentKeyText ([string]$c.text)
                    if ([string]::IsNullOrWhiteSpace($authorKey) -or [string]::IsNullOrWhiteSpace($textKey)) { continue }
                    $isDuplicate = $false
                    foreach ($seen in $seenComments.ToArray()) {
                        if ($seen.author -ne $authorKey) { continue }
                        if ($seen.text -eq $textKey -or $seen.text.Contains($textKey) -or $textKey.Contains($seen.text)) {
                            $isDuplicate = $true
                            break
                        }
                    }
                    if ($isDuplicate) { continue }
                    $seenComments.Add([pscustomobject]@{ author = $authorKey; text = $textKey }) | Out-Null
                    $mergedComments.Add($c)
                    if ($mergedComments.Count -ge 20) { break }
                }
                if ($mergedComments.Count -ge 20) { break }
            }
            if ($apiCount -gt 0) {
                $commentResult = $apiCommentResult
                $commentResult | Add-Member -NotePropertyName items -NotePropertyValue @($mergedComments.ToArray()) -Force
                $commentResult | Add-Member -NotePropertyName comments_reason -NotePropertyValue "通过当前页面同源评论接口采集，并用评论面板可见内容补漏；未绕过登录或验证码。" -Force
                $commentResult | Add-Member -NotePropertyName api_comments_count -NotePropertyValue $apiCount -Force
                $commentResult | Add-Member -NotePropertyName dom_comments_count -NotePropertyValue $domCount -Force
            } else {
                $commentResult = $domCommentResult
                $commentResult | Add-Member -NotePropertyName items -NotePropertyValue @($mergedComments.ToArray()) -Force
                if ($apiCount -gt 0) {
                    $commentResult | Add-Member -NotePropertyName api_comments_count -NotePropertyValue $apiCount -Force
                } elseif ($apiCommentResult.comments_reason) {
                    $commentResult | Add-Member -NotePropertyName api_comments_reason -NotePropertyValue ([string]$apiCommentResult.comments_reason) -Force
                }
                $commentResult | Add-Member -NotePropertyName dom_comments_count -NotePropertyValue $domCount -Force
            }
            $filteredAuthorReplyCount = 0
            $n = 0
            if ($null -ne $apiCommentResult.filtered_author_reply_count -and [int]::TryParse([string]$apiCommentResult.filtered_author_reply_count, [ref]$n)) {
                $filteredAuthorReplyCount = $n
            }
            $filteredBadCount = 0
            $n = 0
            if ($null -ne $apiCommentResult.filtered_bad_count -and [int]::TryParse([string]$apiCommentResult.filtered_bad_count, [ref]$n)) {
                $filteredBadCount += $n
            }
            $n = 0
            if ($null -ne $domCommentResult.filtered_bad_count -and [int]::TryParse([string]$domCommentResult.filtered_bad_count, [ref]$n)) {
                $filteredBadCount += $n
            }
            if ($filteredAuthorReplyCount -gt 0) {
                $commentResult | Add-Member -NotePropertyName filtered_author_reply_count -NotePropertyValue $filteredAuthorReplyCount -Force
            }
            if ($filteredBadCount -gt 0) {
                $commentResult | Add-Member -NotePropertyName filtered_bad_count -NotePropertyValue $filteredBadCount -Force
            }
            $apiRawCommentCount = 0
            $apiRawReplyCount = 0
            [int]::TryParse([string]$apiCommentResult.raw_comment_count, [ref]$apiRawCommentCount) | Out-Null
            [int]::TryParse([string]$apiCommentResult.raw_reply_count, [ref]$apiRawReplyCount) | Out-Null
            $apiPublicCommentCount = $apiRawCommentCount + $apiRawReplyCount
            $finalPublicCommentCount = $null
            if ($apiPublicCommentCount -gt 0) {
                $finalPublicCommentCount = $apiPublicCommentCount
            } elseif ($mergedComments.Count -gt 0) {
                $finalPublicCommentCount = $mergedComments.Count
            } elseif ($null -ne $commentOpenState.comment_count) {
                $finalPublicCommentCount = $commentOpenState.comment_count
            }
            if ($null -ne $finalPublicCommentCount) {
                $commentResult | Add-Member -NotePropertyName public_comment_count -NotePropertyValue $finalPublicCommentCount -Force
                $commentResult | Add-Member -NotePropertyName comment_button_label -NotePropertyValue ([string]$finalPublicCommentCount) -Force
                $commentResult | Add-Member -NotePropertyName right_rail_candidate_label -NotePropertyValue ([string]$commentOpenState.label) -Force
            }
        }
        $commentsObjects = @($commentResult.items)
        $commentTexts = @($commentsObjects | ForEach-Object { Compact $_.text } | Where-Object { $_ } | Select-Object -First 20)
        $publicCommentCount = $null
        if ($null -ne $commentResult.public_comment_count -and -not [string]::IsNullOrWhiteSpace([string]$commentResult.public_comment_count)) {
            $parsedCommentCount = 0
            if ([int]::TryParse([string]$commentResult.public_comment_count, [ref]$parsedCommentCount)) { $publicCommentCount = $parsedCommentCount }
        }
        $transcriptRaw = ""
        $noSpeech = "unknown"
        $transcript = ""
        $transcriptFileContent = "speech_transcription_status: not_configured`r`ntranscript: `"`""
        $ocrLines = @($frameInfo.ocr_items | ForEach-Object {
            $line = if ($_.clean_text) { $_.clean_text } else { $_.text }
            if ([string]::IsNullOrWhiteSpace([string]$line)) { "" } else { "$($_.frame_time)：$line" }
        } | Where-Object { $_ })
        $ocrText = if ($ocrLines.Count) {
            $ocrLines -join "`r`n"
        } else {
            "OCR 状态：已逐帧生成 ocr_items.json；当前未检测到本机 OCR 输出或 OCR 引擎不可用。关键帧可上传给 ChatGPT 识别画面文字、价格、地址、活动和团购信息。"
        }
        $ocrSummaryText = CleanSummaryText (($frameInfo.ocr_items | ForEach-Object {
            $t = ExtractPriorityOcrText $(if ($_.clean_text) { $_.clean_text } else { $_.text })
            $t = GetReliableVisualSummaryText $t
            if ($t -match "门店|地址|导航|电话|营业|时间|套餐|团购|价格|人均|菜|酒|活动|优惠|到店|预约|包间|西海岸|叁两") { $t } else { "" }
        } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique) -join " ")
        $commentSummaryText = CleanSummaryText ($commentTexts -join " ")
        $transcriptSummaryText = CleanSummaryText $transcriptRaw
        $titleSummaryText = CleanSummaryText $canonicalTitle
        $visualSummarySource = Compact "$ocrSummaryText $transcriptSummaryText"
        if ([string]::IsNullOrWhiteSpace($visualSummarySource)) {
            $visualSummarySource = "需根据关键帧判断。"
        }
        $summarySource = Compact "$visualSummarySource"
        $summary = if ($summarySource.Length -gt 100) { $summarySource.Substring(0, 100) } else { $summarySource }
        if ([string]::IsNullOrWhiteSpace($summary)) {
            $summary = "当前可见页面未提取到足够文本。"
        }

        $play = $null
        $like = $null
        $commentCount = $null
        $favorite = $null
        $share = $null
        $publishedAt = ExtractTime $body

        $missingAuth = New-Object System.Collections.Generic.List[string]
        foreach ($field in (AuthOnlyFields)) {
            $value = ""
            switch ($field) {
                "authorized_play_count" { $value = $play }
                "authorized_like_count" { $value = $like }
                "authorized_comment_count" { $value = $commentCount }
                "authorized_favorite_count" { $value = $favorite }
                "authorized_share_count" { $value = $share }
                default { $value = "" }
            }
            if ([string]::IsNullOrWhiteSpace([string]$value)) { $missingAuth.Add($field) }
        }

        $missingError = New-Object System.Collections.Generic.List[string]
        if ([string]::IsNullOrWhiteSpace($canonicalTitle)) { $missingError.Add("title") }
        if (-not (Test-Path -LiteralPath (Join-Path $folder "cover.jpg"))) { $missingError.Add("cover_image") }
        foreach ($frameName in @("cover.jpg","0s.jpg","1s.jpg","2s.jpg","3s.jpg","ending.jpg")) {
            if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $frames "video_crop") $frameName))) { $missingError.Add("frames/video_crop/$frameName") }
        }
        if (-not (Test-Path -LiteralPath (Join-Path $PackageDir $frameInfo.contact_sheet_path))) { $missingError.Add("frames_contact_sheet") }
        if ([string]::IsNullOrWhiteSpace($summary)) { $missingError.Add("summary") }
        $frameStatus = [string]$frameInfo.frame_status
        $videoCropStatus = [string]$frameInfo.video_crop_status
        $ocrStatus = [string]$frameInfo.ocr_status
        $commentStatus = [string]$commentResult.comments_status
        $commentReason = [string]$commentResult.comments_reason
        if ($null -ne $publicCommentCount -and $publicCommentCount -gt 0) {
            $filteredAuthorReplyCountForStatus = 0
            if ($null -ne $commentResult.filtered_author_reply_count) {
                [int]::TryParse([string]$commentResult.filtered_author_reply_count, [ref]$filteredAuthorReplyCountForStatus) | Out-Null
            }
            $filteredBadCountForStatus = 0
            if ($null -ne $commentResult.filtered_bad_count) {
                [int]::TryParse([string]$commentResult.filtered_bad_count, [ref]$filteredBadCountForStatus) | Out-Null
            }
            $filteredTotalForStatus = $filteredAuthorReplyCountForStatus + $filteredBadCountForStatus
            $effectivePublicCommentCount = [Math]::Max(0, $publicCommentCount - $filteredTotalForStatus)
            $expectedVisibleComments = [Math]::Min(20, $effectivePublicCommentCount)
            if ($commentTexts.Count -eq 0) {
                $commentStatus = $(if ($filteredTotalForStatus -gt 0) { "visible_count_but_items_empty" } else { "partial_no_valid_comments_extracted" })
                $filterNote = if ($filteredTotalForStatus -gt 0) { "；已过滤作者回复 $filteredAuthorReplyCountForStatus 条、无效/占位评论 $filteredBadCountForStatus 条" } else { "" }
                $commentReason = "公开评论按钮显示 $publicCommentCount 条$filterNote，但没有提取到可写入 comments.items 的真实有效评论。"
                $commentResult | Add-Member -NotePropertyName comments_status -NotePropertyValue $commentStatus -Force
                $commentResult | Add-Member -NotePropertyName comments_reason -NotePropertyValue $commentReason -Force
                $commentResult | Add-Member -NotePropertyName comments_expected_count -NotePropertyValue $publicCommentCount -Force
            } elseif ($commentTexts.Count -lt $expectedVisibleComments) {
                $missingCommentCount = $expectedVisibleComments - $commentTexts.Count
                $totalGapFromPublic = [Math]::Max(0, $publicCommentCount - $commentTexts.Count)
                if ($filteredTotalForStatus -gt 0 -and $totalGapFromPublic -le $filteredTotalForStatus) {
                    $commentStatus = "ok_with_reply_filtered"
                    $commentReason = "公开评论按钮显示 $publicCommentCount 条，已采集有效用户评论 $($commentTexts.Count) 条；差异来自已过滤作者回复 $filteredAuthorReplyCountForStatus 条或无效/占位评论 $filteredBadCountForStatus 条。"
                } else {
                    $commentStatus = "partial"
                    $filterNote = if ($filteredTotalForStatus -gt 0) { "；已过滤作者回复 $filteredAuthorReplyCountForStatus 条、无效/占位评论 $filteredBadCountForStatus 条" } else { "" }
                    $commentReason = "公开评论按钮显示 $publicCommentCount 条$filterNote，当前成功采集有效用户评论 $($commentTexts.Count) 条；已下滑评论区，但仍有部分评论未加载、不可见或被页面权限限制。"
                }
                $commentResult | Add-Member -NotePropertyName comments_status -NotePropertyValue $commentStatus -Force
                $commentResult | Add-Member -NotePropertyName comments_reason -NotePropertyValue $commentReason -Force
                $commentResult | Add-Member -NotePropertyName comments_expected_count -NotePropertyValue $publicCommentCount -Force
            } elseif ($filteredTotalForStatus -gt 0 -and $commentTexts.Count -lt $publicCommentCount) {
                $commentStatus = "ok_with_reply_filtered"
                $commentReason = "已采集当前可见的有效用户评论；同时过滤作者回复 $filteredAuthorReplyCountForStatus 条、无效/占位评论 $filteredBadCountForStatus 条。"
                $commentResult | Add-Member -NotePropertyName comments_status -NotePropertyValue $commentStatus -Force
                $commentResult | Add-Member -NotePropertyName comments_reason -NotePropertyValue $commentReason -Force
            } elseif ($commentTexts.Count -gt 0 -and $commentStatus -ne "ok") {
                $commentStatus = "ok"
                $filterNote = if ($filteredAuthorReplyCountForStatus -gt 0) { "，已按要求过滤作者回复 $filteredAuthorReplyCountForStatus 条" } else { "" }
                $commentReason = "已采集当前可见的有效用户评论$filterNote。"
                $commentResult | Add-Member -NotePropertyName comments_status -NotePropertyValue $commentStatus -Force
                $commentResult | Add-Member -NotePropertyName comments_reason -NotePropertyValue $commentReason -Force
            }
        }
        $speechStatus = "not_available"
        $validCommentItemsCount = $commentTexts.Count
        $replyItemsCount = 0
        $n = 0
        if ($null -ne $commentResult.filtered_author_reply_count -and [int]::TryParse([string]$commentResult.filtered_author_reply_count, [ref]$n)) {
            $replyItemsCount = $n
        }
        $commentCountMatchStatus = GetCommentCountMatchStatus $publicCommentCount $validCommentItemsCount $replyItemsCount
        AddCommentStats $commentResult $publicCommentCount $validCommentItemsCount
        $publicMetricCheck = ResolvePublicMetricStatus $publicCardLike $likeMatchedState $commentResult
        $publicMetricStatus = [string]$publicMetricCheck.status
        $publicMetricReason = [string]$publicMetricCheck.reason
        $authorizedMetricStatus = "auth_pending"
        $fatalMissingError = @($missingError.ToArray() | Where-Object {
            $_ -notmatch "^frames/video_crop/" -and $_ -ne "cover_image" -and $_ -ne "frames_contact_sheet"
        })
        $status = if ($fatalMissingError.Count -gt 0 -or $frameStatus -eq "failed" -or $videoCropStatus -eq "failed") {
            "failed"
        } elseif ($mappingCheck.content_mapping_status -ne "ok" -or $publicMetricStatus -eq "mismatch") {
            "partial"
        } elseif ($missingError.Count -gt 0 -or $frameStatus -eq "partial" -or $videoCropStatus -eq "partial") {
            "partial"
        } elseif ($ocrStatus -eq "failed" -or $commentStatus -eq "failed" -or $commentStatus -eq "partial" -or $commentStatus -eq "auth_or_login_required" -or $commentStatus -eq "visible_count_but_items_empty" -or $commentStatus -eq "partial_no_valid_comments_extracted") {
            "partial"
        } else {
            "public_success"
        }
        if ($mappingCheck.content_mapping_status -ne "ok") {
            $failureReason = "card_modal_id/opened_modal_id 不一致：$($mappingCheck.mapping_check_reason)"
        } elseif ($publicMetricStatus -eq "mismatch") {
            $failureReason = "公开指标不一致：$publicMetricReason"
        }

        $item = [ordered]@{
            index = $Index
            video_id = $videoId
            url = $Url
            collection_mode = $Script:CollectionMode
            run_mode = $Script:RunMode
            sample_size = $Script:SampleSize
            formal_acceptance = $Script:FormalAcceptance
            authorization_status = AuthorizationStatusForMode $Script:CollectionMode
            data_level = DataLevelForMode $Script:CollectionMode
            visual_order = $(if ($cardInfo) { $cardInfo.visual_order } else { $Index })
            mapping_status = $mappingCheck.mapping_status
            content_mapping_status = $mappingCheck.content_mapping_status
            mapping_check_reason = $mappingCheck.mapping_check_reason
            title_consistency_status = $mappingCheck.title_consistency_status
            title_consistency_reason = $mappingCheck.title_consistency_reason
            title_similarity_score = $mappingCheck.title_similarity_score
            opened_modal_id = $mappingCheck.opened_modal_id
            is_pinned = $(if ($cardInfo) { [bool]$cardInfo.is_pinned } else { $false })
            card_text = $(if ($cardInfo) { $cardInfo.card_text } else { "" })
            card_modal_id = $mappingCheck.card_modal_id
            card_cover = $(if ($cardInfo) { $cardInfo.cover } else { "" })
            card_bbox = $(if ($cardInfo) { $cardInfo.card_bbox } else { $null })
            card_row = $(if ($cardInfo) { $cardInfo.row } else { $null })
            card_col = $(if ($cardInfo) { $cardInfo.col } else { $null })
            canonical_title = $canonicalTitle
            detail_title = $detailTitle
            title = $canonicalTitle
            published_at = $publishedAt
            published_at_raw = $publishedAt
            duration_seconds = $frameInfo.duration_seconds
            duration_status = $(if ($null -ne $frameInfo.duration_status) { $frameInfo.duration_status } else { "" })
            media_type = $(if ($null -ne $frameInfo.media_type) { $frameInfo.media_type } else { "" })
            frame_strategy = $frameInfo.frame_strategy
            frame_count = $frameInfo.frame_count
            frame_retry_count = $(if ($null -ne $frameInfo.frame_retry_count) { $frameInfo.frame_retry_count } else { 0 })
            contact_sheet_path = $frameInfo.contact_sheet_path
            full_frame_dir = $frameInfo.full_frame_dir
            video_crop_dir = $frameInfo.video_crop_dir
            visual_rhythm_analysis = $frameInfo.visual_rhythm_analysis
            public_card_like_count = $publicCardLike
            public_card_like_source = $(if ($null -ne $publicCardLike) { "homepage_card" } else { "" })
            authorized_play_count = $play
            authorized_like_count = $like
            authorized_comment_count = $commentCount
            authorized_favorite_count = $favorite
            authorized_share_count = $share
            play_count = $null
            like_count = $null
            comment_count = $null
            public_comment_count = $commentResult.public_comment_count
            comment_button_label = [string]$commentResult.comment_button_label
            comments_expected_count = $publicCommentCount
            favorite_count = $null
            share_count = $null
            fan_profile = ""
            traffic_source = ""
            completion_rate = ""
            five_second_play_rate = ""
            engagement_rate = ""
            follower_gain = ""
            profile_visit_count = ""
            cover_image = (RelPath (Join-Path $folder "cover.jpg") $PackageDir)
            frames_dir = (RelPath $frames $PackageDir)
            frames = @($frameInfo.frames)
            transcript = $transcript
            no_speech = $noSpeech
            speech_transcription_status = "not_configured"
            speech_status = $speechStatus
            ocr_text = $ocrText
            ocr_items = @($frameInfo.ocr_items)
            ocr_status = $ocrStatus
            summary = $summary
            conversion_flags = DetectConversion @{
                title = $canonicalTitle
                ocr = $ocrText
                transcript = $transcriptRaw
                comments = ($commentTexts -join " ")
            }
            comments = $commentTexts
            comments_count_collected = $commentTexts.Count
            valid_comment_items_count = $validCommentItemsCount
            reply_items_count = $replyItemsCount
            comment_count_match_status = $commentCountMatchStatus
            comments_status = $commentStatus
            comments_reason = $commentReason
            comment_status = $commentStatus
            comment_keywords = Keywords $commentTexts
            comment_questions = CommentQuestions $commentTexts
            frame_status = $frameStatus
            video_crop_status = $videoCropStatus
            frame_errors = @($frameInfo.frame_errors)
            video_crop_errors = @($frameInfo.video_crop_errors)
            public_metric_status = $publicMetricStatus
            public_metric_reason = $publicMetricReason
            authorized_metric_status = $authorizedMetricStatus
            status = $status
            failure_reason = $failureReason
            missing_due_to_authorization = @($missingAuth.ToArray())
            missing_due_to_error = @($missingError.ToArray())
            missing_fields = @(@($missingAuth.ToArray()) + @($missingError.ToArray()))
            folder = (RelPath $folder $PackageDir)
        }

        Set-Content -LiteralPath (Join-Path $folder "transcript.txt") -Encoding UTF8 -Value $transcriptFileContent
        Set-Content -LiteralPath (Join-Path $folder "ocr_text.txt") -Encoding UTF8 -Value $ocrText
        Set-Content -LiteralPath (Join-Path $folder "comments.json") -Encoding UTF8 -Value ($commentResult | ConvertTo-Json -Depth 20)
        Set-Content -LiteralPath (Join-Path $folder "meta.json") -Encoding UTF8 -Value ($item | ConvertTo-Json -Depth 30)
        Set-Content -LiteralPath (Join-Path $folder "summary.md") -Encoding UTF8 -Value (RenderWorkSummary $item)
        StopWorkLock
        return $item
    } catch {
        StopWorkLock
        $failureReason = $_.Exception.Message
        $item = [ordered]@{
            index = $Index
            video_id = $videoId
            url = $Url
            collection_mode = $Script:CollectionMode
            run_mode = $Script:RunMode
            sample_size = $Script:SampleSize
            formal_acceptance = $Script:FormalAcceptance
            authorization_status = AuthorizationStatusForMode $Script:CollectionMode
            data_level = DataLevelForMode $Script:CollectionMode
            visual_order = $(if ($cardInfo) { $cardInfo.visual_order } else { $Index })
            mapping_status = "failed"
            content_mapping_status = "failed"
            mapping_check_reason = $failureReason
            title_consistency_status = "mismatch"
            title_consistency_reason = $failureReason
            title_similarity_score = 0
            opened_modal_id = ""
            is_pinned = $(if ($cardInfo) { [bool]$cardInfo.is_pinned } else { $false })
            card_text = $(if ($cardInfo) { $cardInfo.card_text } else { "" })
            card_modal_id = $(if ($cardInfo) { $cardInfo.modal_id } else { $videoId })
            card_cover = $(if ($cardInfo) { $cardInfo.cover } else { "" })
            card_bbox = $(if ($cardInfo) { $cardInfo.card_bbox } else { $null })
            card_row = $(if ($cardInfo) { $cardInfo.row } else { $null })
            card_col = $(if ($cardInfo) { $cardInfo.col } else { $null })
            canonical_title = $(if ($cardInfo) { CleanCardTitle ([string]$cardInfo.card_text) } else { "" })
            detail_title = ""
            title = $(if ($cardInfo) { CleanCardTitle ([string]$cardInfo.card_text) } else { "" })
            published_at = ""
            published_at_raw = ""
            duration_seconds = $null
            duration_status = "unavailable"
            media_type = "unknown"
            frame_strategy = "dense_first_5s_then_every_3s"
            frame_count = 0
            frame_retry_count = 0
            contact_sheet_path = ""
            full_frame_dir = (RelPath (Join-Path $frames "full_frame") $PackageDir)
            video_crop_dir = (RelPath (Join-Path $frames "video_crop") $PackageDir)
            visual_rhythm_analysis = ""
            public_card_like_count = $(if ($cardInfo) { $cardInfo.public_card_like_count } else { $null })
            public_card_like_source = $(if ($cardInfo -and $cardInfo.public_card_like_count) { "homepage_card" } else { "" })
            authorized_play_count = $null
            authorized_like_count = $null
            authorized_comment_count = $null
            authorized_favorite_count = $null
            authorized_share_count = $null
            play_count = $null
            like_count = $null
            comment_count = $null
            public_comment_count = $null
            comment_button_label = ""
            comments_expected_count = $null
            favorite_count = $null
            share_count = $null
            fan_profile = ""
            traffic_source = ""
            completion_rate = ""
            five_second_play_rate = ""
            engagement_rate = ""
            follower_gain = ""
            profile_visit_count = ""
            cover_image = ""
            frames_dir = (RelPath $frames $PackageDir)
            frames = @()
            transcript = ""
            no_speech = "unknown"
            speech_transcription_status = "not_configured"
            speech_status = "not_available"
            ocr_text = ""
            ocr_items = @()
            ocr_status = "failed"
            summary = ""
            conversion_flags = @{}
            comments = @()
            comments_count_collected = 0
            valid_comment_items_count = 0
            reply_items_count = 0
            comment_count_match_status = "unknown_no_public_count"
            comments_status = "failed"
            comments_reason = $failureReason
            comment_status = "failed"
            comment_keywords = @()
            comment_questions = @{}
            frame_status = "failed"
            video_crop_status = "failed"
            frame_errors = @($failureReason)
            video_crop_errors = @($failureReason)
            public_metric_status = $(if ($cardInfo -and $cardInfo.public_card_like_count) { "card_only" } else { "missing" })
            public_metric_reason = $(if ($cardInfo -and $cardInfo.public_card_like_count) { "采集失败前已取得主页卡片心形数，详情页未复核" } else { "主页卡片心形数缺失" })
            authorized_metric_status = "auth_pending"
            status = "failed"
            failure_reason = $failureReason
            missing_due_to_authorization = @(AuthOnlyFields)
            missing_due_to_error = @("title","cover_image","frames","frames_contact_sheet","summary")
            missing_fields = @(@(AuthOnlyFields) + @("title","cover_image","frames","frames_contact_sheet","summary"))
            folder = (RelPath $folder $PackageDir)
        }
        Set-Content -LiteralPath (Join-Path $folder "meta.json") -Encoding UTF8 -Value ($item | ConvertTo-Json -Depth 30)
        Set-Content -LiteralPath (Join-Path $folder "comments.json") -Encoding UTF8 -Value (@{ comments_status = "failed"; comments_reason = $failureReason; items = @(); valid_comment_items_count = 0; reply_items_count = 0; comment_count_match_status = "unknown_no_public_count" } | ConvertTo-Json -Depth 10)
        Set-Content -LiteralPath (Join-Path $folder "transcript.txt") -Encoding UTF8 -Value "speech_transcription_status: not_configured`r`ntranscript: `"`""
        Set-Content -LiteralPath (Join-Path $folder "ocr_text.txt") -Encoding UTF8 -Value ""
        Set-Content -LiteralPath (Join-Path $folder "ocr_items.json") -Encoding UTF8 -Value "[]"
        Set-Content -LiteralPath (Join-Path $folder "summary.md") -Encoding UTF8 -Value (RenderWorkSummary $item)
        return $item
    }
}

function NewFailedWork([string]$Url, [int]$Index, [string]$PackageDir, [string]$Reason) {
    $videoId = GetWorkId $Url
    $folder = Join-Path $PackageDir ("{0:D3}_{1}" -f $Index, $videoId)
    $frames = Join-Path $folder "frames"
    New-Item -ItemType Directory -Force -Path $frames | Out-Null
    $item = [ordered]@{
        index = $Index
        video_id = $videoId
        url = $Url
        collection_mode = $Script:CollectionMode
        run_mode = $Script:RunMode
        sample_size = $Script:SampleSize
        formal_acceptance = $Script:FormalAcceptance
        authorization_status = AuthorizationStatusForMode $Script:CollectionMode
        data_level = DataLevelForMode $Script:CollectionMode
        visual_order = $Index
        mapping_status = "failed"
        content_mapping_status = "failed"
        mapping_check_reason = $Reason
        title_consistency_status = "mismatch"
        title_consistency_reason = $Reason
        title_similarity_score = 0
        opened_modal_id = ""
        is_pinned = $false
        card_text = ""
        card_modal_id = $videoId
        card_cover = ""
        card_bbox = $null
        card_row = $null
        card_col = $null
        canonical_title = ""
        detail_title = ""
        title = ""
        published_at = ""
        published_at_raw = ""
        duration_seconds = $null
        duration_status = "unavailable"
        media_type = "unknown"
        frame_strategy = "dense_first_5s_then_every_3s"
        frame_count = 0
        frame_retry_count = 0
        contact_sheet_path = ""
        full_frame_dir = (RelPath (Join-Path $frames "full_frame") $PackageDir)
        video_crop_dir = (RelPath (Join-Path $frames "video_crop") $PackageDir)
        visual_rhythm_analysis = ""
        public_card_like_count = $null
        public_card_like_source = ""
        authorized_play_count = $null
        authorized_like_count = $null
        authorized_comment_count = $null
        authorized_favorite_count = $null
        authorized_share_count = $null
        play_count = $null
        like_count = $null
        comment_count = $null
        public_comment_count = $null
        comment_button_label = ""
        comments_expected_count = $null
        favorite_count = $null
        share_count = $null
        fan_profile = ""
        traffic_source = ""
        completion_rate = ""
        five_second_play_rate = ""
        engagement_rate = ""
        follower_gain = ""
        profile_visit_count = ""
        cover_image = ""
        frames_dir = (RelPath $frames $PackageDir)
        frames = @()
        transcript = ""
        no_speech = "unknown"
        speech_transcription_status = "not_configured"
        speech_status = "not_available"
        ocr_text = ""
        ocr_items = @()
        ocr_status = "failed"
        summary = ""
        conversion_flags = @{}
        comments = @()
        comments_count_collected = 0
        valid_comment_items_count = 0
        reply_items_count = 0
        comment_count_match_status = "unknown_no_public_count"
        comments_status = "failed"
        comments_reason = $Reason
        comment_status = "failed"
        comment_keywords = @()
        comment_questions = @{}
        frame_status = "failed"
        video_crop_status = "failed"
        frame_errors = @($Reason)
        video_crop_errors = @($Reason)
        public_metric_status = "missing"
        public_metric_reason = "主页卡片心形数缺失"
        authorized_metric_status = "auth_pending"
        status = "failed"
        failure_reason = $Reason
        missing_due_to_authorization = @(AuthOnlyFields)
        missing_due_to_error = @("title","cover_image","frames","frames_contact_sheet","summary")
        missing_fields = @(@(AuthOnlyFields) + @("title","cover_image","frames","frames_contact_sheet","summary"))
        folder = (RelPath $folder $PackageDir)
    }
    Set-Content -LiteralPath (Join-Path $folder "meta.json") -Encoding UTF8 -Value ($item | ConvertTo-Json -Depth 30)
    Set-Content -LiteralPath (Join-Path $folder "comments.json") -Encoding UTF8 -Value (@{ comments_status = "failed"; comments_reason = $Reason; items = @(); valid_comment_items_count = 0; reply_items_count = 0; comment_count_match_status = "unknown_no_public_count" } | ConvertTo-Json -Depth 10)
    Set-Content -LiteralPath (Join-Path $folder "transcript.txt") -Encoding UTF8 -Value "speech_transcription_status: not_configured`r`ntranscript: `"`""
    Set-Content -LiteralPath (Join-Path $folder "ocr_text.txt") -Encoding UTF8 -Value ""
    Set-Content -LiteralPath (Join-Path $folder "ocr_items.json") -Encoding UTF8 -Value "[]"
    Set-Content -LiteralPath (Join-Path $folder "summary.md") -Encoding UTF8 -Value (RenderWorkSummary $item)
    return $item
}

function YesNo($b) { if ($b) { return "是" } return "否" }

function ConvertToJsonArray($Values, [int]$Depth = 30) {
    $parts = New-Object System.Collections.Generic.List[string]
    if ($null -eq $Values) { return "[]" }
    foreach ($value in @($Values)) {
        if ($null -eq $value) { continue }
        $parts.Add(($value | ConvertTo-Json -Depth $Depth))
    }
    return "[" + ($parts.ToArray() -join ",`r`n") + "]"
}

function RenderWorkSummary($Item) {
    $displayTitle = Compact $(if (-not [string]::IsNullOrWhiteSpace([string]$Item.canonical_title)) { [string]$Item.canonical_title } else { [string]$Item.title })
    if ([string]::IsNullOrWhiteSpace($displayTitle)) { $displayTitle = "未提取到标题" }
    $flags = if ($Item.conversion_flags -and $Item.conversion_flags.GetEnumerator) {
        ($Item.conversion_flags.GetEnumerator() | ForEach-Object {
            $v = $_.Value
            if ($v -and $null -ne $v.present) {
                "- $($_.Key): $(YesNo $v.present)；source=$($v.source)；evidence=$($v.evidence)"
            } else {
                "- $($_.Key): 否"
            }
        }) -join "`r`n"
    } else { "" }
    $questions = if ($Item.comment_questions -and $Item.comment_questions.GetEnumerator) { ($Item.comment_questions.GetEnumerator() | ForEach-Object { "- $($_.Key): $(YesNo $_.Value)" }) -join "`r`n" } else { "" }
    $comments = if ($Item.comments.Count) { (($Item.comments | ForEach-Object -Begin { $i=1 } -Process { "$($i++). $_" }) -join "`r`n") } else { "未采集到评论。" }
    $missingAuth = if ($Item.missing_due_to_authorization) { $Item.missing_due_to_authorization -join ", " } else { "无" }
    $missingError = if ($Item.missing_due_to_error) { $Item.missing_due_to_error -join ", " } else { "无" }
@"
# $displayTitle

- 采集状态：$($Item.status)
- 采集模式：$($Item.collection_mode)
- run_mode：$($Item.run_mode)
- sample_size：$($Item.sample_size)
- formal_acceptance：$($Item.formal_acceptance)
- 授权状态：$($Item.authorization_status)
- 数据层级：$($Item.data_level)
- 失败原因：$($Item.failure_reason)
- content_mapping_status：$($Item.content_mapping_status)
- mapping_status：$($Item.mapping_status)
- mapping_check_reason：$($Item.mapping_check_reason)
- title_consistency_status：$($Item.title_consistency_status)
- title_consistency_reason：$($Item.title_consistency_reason)
- title_similarity_score：$($Item.title_similarity_score)
- opened_modal_id：$($Item.opened_modal_id)
- card_modal_id：$($Item.card_modal_id)
- 授权后可补字段：$missingAuth
- 采集错误缺失：$missingError
- 作品ID：$($Item.video_id)
- 视觉顺序：$($Item.visual_order)
- 是否置顶：$(YesNo $Item.is_pinned)
- 链接：$($Item.url)
- 发布时间：$($Item.published_at)
- 视频时长：$($Item.duration_seconds) 秒
- duration_status：$($Item.duration_status)
- media_type：$($Item.media_type)
- 抽帧策略：$($Item.frame_strategy)
- 关键帧数量：$($Item.frame_count)
- 关键帧长图：$($Item.contact_sheet_path)
- frame_status：$($Item.frame_status)
- video_crop_status：$($Item.video_crop_status)
- ocr_status：$($Item.ocr_status)
- comment_status：$($Item.comment_status)
- speech_status：$($Item.speech_status)
- public_metric_status：$($Item.public_metric_status)
- public_metric_reason：$($Item.public_metric_reason)
- authorized_metric_status：$($Item.authorized_metric_status)
- 公开卡片心形数：$($Item.public_card_like_count)
- 授权播放量：$($Item.authorized_play_count)
- 授权点赞数：$($Item.authorized_like_count)
- 授权评论数：$($Item.authorized_comment_count)
- 授权收藏数：$($Item.authorized_favorite_count)
- 授权分享数：$($Item.authorized_share_count)
- no_speech：$($Item.no_speech)

## 作品标题

$displayTitle

## 视频画面简述

$($Item.summary)

## 主要场景

$($Item.visual_rhythm_analysis)

## 是否出现地址/价格/套餐/门店/人物

- 地址/位置：$(YesNo $Item.conversion_flags.address.present)
- 价格：$(YesNo $Item.conversion_flags.price.present)
- 套餐/团购：$(YesNo $Item.conversion_flags.group_buy.present)
- 门店/到店：$(YesNo ($Item.summary -match "门店|到店|店|酒馆"))
- 人物：$(YesNo ($Item.summary -match "人物|女孩|男|女|朋友|顾客|老板|店员"))

## 画面节奏分析

$($Item.visual_rhythm_analysis)

## 评论区反馈

$comments

## 转化引导

$flags

## 评论区问题识别

$questions

## 高频关键词

$($Item.comment_keywords -join ", ")

## 前20条评论

$comments

## Debug 信息

- canonical_title：$($Item.canonical_title)
- detail_title：$($Item.detail_title)
- title_consistency_status：$($Item.title_consistency_status)
"@
}

function RenderAccountSummary($Items) {
    $total = $Items.Count
    $collectionMode = $Script:CollectionMode
    $authorizationStatus = AuthorizationStatusForMode $collectionMode
    $dataLevel = DataLevelForMode $collectionMode
    $publicSuccess = @($Items | Where-Object { $_.status -eq "public_success" -and $_.content_mapping_status -eq "ok" -and $_.public_metric_status -ne "mismatch" }).Count
    $failed = @($Items | Where-Object { $_.status -eq "failed" }).Count
    $partial = @($Items | Where-Object { $_.status -eq "partial" }).Count
    $mappingMismatch = @($Items | Where-Object { $_.content_mapping_status -ne "ok" }).Count
    $publicMetricMismatch = @($Items | Where-Object { $_.public_metric_status -eq "mismatch" }).Count
    $contentCollectionPending = $partial
    $authorizedMetricPending = @($Items | Where-Object { $_.authorized_metric_status -eq "auth_pending" }).Count
    $missingAuthCounts = @{}
    $missingErrorCounts = @{}
    foreach ($it in $Items) {
        foreach ($field in @($it.missing_due_to_authorization)) {
            if (!$missingAuthCounts.ContainsKey($field)) { $missingAuthCounts[$field] = 0 }
            $missingAuthCounts[$field]++
        }
        foreach ($field in @($it.missing_due_to_error)) {
            if (!$missingErrorCounts.ContainsKey($field)) { $missingErrorCounts[$field] = 0 }
            $missingErrorCounts[$field]++
        }
    }
    $missingAuthLines = if ($missingAuthCounts.Count) {
        ($missingAuthCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "- $($_.Key)：$($_.Value)" }) -join "`r`n"
    } else {
        "无"
    }
    $missingErrorLines = if ($missingErrorCounts.Count) {
        ($missingErrorCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "- $($_.Key)：$($_.Value)" }) -join "`r`n"
    } else {
        "无"
    }
    $badRows = ($Items | Where-Object { $_.status -eq "failed" -or $_.content_mapping_status -ne "ok" -or $_.public_metric_status -eq "mismatch" } | ForEach-Object { "- $($_.index) / $($_.video_id) / $($_.status) / content_mapping=$($_.content_mapping_status) / public_metric=$($_.public_metric_status)：$($_.failure_reason) $($_.mapping_check_reason) $($_.public_metric_reason)" }) -join "`r`n"
    if ([string]::IsNullOrWhiteSpace($badRows)) { $badRows = "无" }
    $rows = ($Items | Sort-Object { [int]$_.visual_order } | ForEach-Object { "| $($_.visual_order) | $($_.video_id) | $($_.status) | $($_.content_mapping_status) | $($_.public_metric_status) | $($_.title_similarity_score) | $($_.opened_modal_id) | $($_.card_modal_id) | $($_.frame_status) | $($_.video_crop_status) | $($_.ocr_status) | $($_.comment_status) | $(YesNo $_.is_pinned) | $($_.title) | $($_.published_at_raw) | $($_.public_card_like_count) |" }) -join "`r`n"
@"
# 抖音账号分析资料包

- 生成时间：$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
- collection_mode：$collectionMode
- test_mode：$Script:IsTestMode
- run_mode：$Script:RunMode
- sample_size：$Script:SampleSize
- formal_acceptance：$Script:FormalAcceptance
- max_works：$Script:EffectiveWorkLimit
- output_zip_path：$(ProjectRelPath $Script:CurrentOutputZipPath)
- output_zip_rule：{店铺名称}-{作品数量}-{时间}.zip
- authorization_status：$authorizationStatus
- data_level：$dataLevel
- 作品总数：$total
- public_success_count：$publicSuccess
- partial_count：$partial
- content_collection_pending_count：$contentCollectionPending
- mapping_mismatch_count：$mappingMismatch
- public_metric_mismatch_count：$publicMetricMismatch
- authorized_metric_pending_count：$authorizedMetricPending
- failed_count：$failed
- 说明：本资料包由本机 Edge 当前可见页面整理，未绕过登录、验证码或权限限制。

## missing_due_to_authorization

$missingAuthLines

## missing_due_to_error

$missingErrorLines

## 异常作品列表

$badRows

## 作品概览

| 视觉顺序 | 作品ID | 状态 | content_mapping | public_metric | 标题相似度 | opened_modal_id | card_modal_id | frame | crop | OCR | 评论 | 置顶 | 标题 | 发布时间原始值 | 公开心形 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
$rows

## 给 ChatGPT 的建议分析方向

1. 识别账号内容定位、主要卖点和目标客群。
2. 对比高互动作品和低互动作品的标题、画面、口播、评论差异。
3. 总结评论区用户最关心的问题，例如地址、价格、营业时间、预约方式。
4. 优化后续选题、开头3秒、转化话术和评论区承接。
"@
}

function XmlEscape([string]$Text) {
    return [Security.SecurityElement]::Escape($Text)
}

function ColName([int]$N) {
    $s = ""
    while ($N -gt 0) {
        $m = ($N - 1) % 26
        $s = [char](65 + $m) + $s
        $N = [Math]::Floor(($N - $m) / 26)
    }
    return $s
}

function WriteXlsx([string]$Path, $Items) {
    $temp = Join-Path ([IO.Path]::GetTempPath()) ("xlsx_" + [Guid]::NewGuid())
    New-Item -ItemType Directory -Force -Path "$temp\xl\worksheets", "$temp\xl\_rels", "$temp\_rels" | Out-Null
    Set-Content -LiteralPath "$temp\[Content_Types].xml" -Encoding UTF8 -Value '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'
    Set-Content -LiteralPath "$temp\_rels\.rels" -Encoding UTF8 -Value '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
    Set-Content -LiteralPath "$temp\xl\workbook.xml" -Encoding UTF8 -Value '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="works" sheetId="1" r:id="rId1"/></sheets></workbook>'
    Set-Content -LiteralPath "$temp\xl\_rels\workbook.xml.rels" -Encoding UTF8 -Value '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>'
    $headers = @("index","visual_order","video_id","status","content_mapping_status","mapping_status","mapping_check_reason","title_consistency_status","title_consistency_reason","title_similarity_score","opened_modal_id","card_modal_id","frame_status","video_crop_status","ocr_status","comment_status","speech_status","public_metric_status","public_metric_reason","authorized_metric_status","collection_mode","run_mode","sample_size","formal_acceptance","authorization_status","data_level","is_pinned","card_row","card_col","card_bbox","card_cover","failure_reason","url","canonical_title","detail_title","title","card_text","published_at_raw","duration_seconds","duration_status","media_type","frame_strategy","frame_count","frame_retry_count","contact_sheet_path","frames_dir","full_frame_dir","video_crop_dir","public_card_like_count","public_card_like_source","authorized_play_count","authorized_like_count","authorized_comment_count","authorized_favorite_count","authorized_share_count","fan_profile","traffic_source","completion_rate","five_second_play_rate","engagement_rate","follower_gain","profile_visit_count","public_comment_count","comment_button_label","comments_expected_count","comments_count_collected","valid_comment_items_count","reply_items_count","comment_count_match_status","comments_status","comments_reason","no_speech","missing_due_to_authorization","missing_due_to_error","summary","conversion_flags","comment_keywords","folder")
    $rows = New-Object System.Collections.Generic.List[object]
    $rows.Add($headers)
    foreach ($it in $Items) {
        $rows.Add(@($it.index,$it.visual_order,$it.video_id,$it.status,$it.content_mapping_status,$it.mapping_status,$it.mapping_check_reason,$it.title_consistency_status,$it.title_consistency_reason,$it.title_similarity_score,$it.opened_modal_id,$it.card_modal_id,$it.frame_status,$it.video_crop_status,$it.ocr_status,$it.comment_status,$it.speech_status,$it.public_metric_status,$it.public_metric_reason,$it.authorized_metric_status,$it.collection_mode,$it.run_mode,$it.sample_size,$it.formal_acceptance,$it.authorization_status,$it.data_level,$it.is_pinned,$it.card_row,$it.card_col,($it.card_bbox | ConvertTo-Json -Compress),$it.card_cover,$it.failure_reason,$it.url,$it.canonical_title,$it.detail_title,$it.title,$it.card_text,$it.published_at_raw,$it.duration_seconds,$it.duration_status,$it.media_type,$it.frame_strategy,$it.frame_count,$it.frame_retry_count,$it.contact_sheet_path,$it.frames_dir,$it.full_frame_dir,$it.video_crop_dir,$it.public_card_like_count,$it.public_card_like_source,$it.authorized_play_count,$it.authorized_like_count,$it.authorized_comment_count,$it.authorized_favorite_count,$it.authorized_share_count,$it.fan_profile,$it.traffic_source,$it.completion_rate,$it.five_second_play_rate,$it.engagement_rate,$it.follower_gain,$it.profile_visit_count,$it.public_comment_count,$it.comment_button_label,$it.comments_expected_count,$it.comments_count_collected,$it.valid_comment_items_count,$it.reply_items_count,$it.comment_count_match_status,$it.comments_status,$it.comments_reason,$it.no_speech,($it.missing_due_to_authorization -join ", "),($it.missing_due_to_error -join ", "),$it.summary,($it.conversion_flags | ConvertTo-Json -Compress),($it.comment_keywords -join ", "),$it.folder))
    }
    $sb = [Text.StringBuilder]::new()
    for ($r = 0; $r -lt $rows.Count; $r++) {
        [void]$sb.Append("<row r=""$($r+1)"">")
        for ($c = 0; $c -lt $rows[$r].Count; $c++) {
            $col = ColName ($c + 1)
            $cell = XmlEscape ([string]$rows[$r][$c])
            [void]$sb.Append("<c r=""$col$($r+1)"" t=""inlineStr""><is><t>$cell</t></is></c>")
        }
        [void]$sb.Append("</row>")
    }
    Set-Content -LiteralPath "$temp\xl\worksheets\sheet1.xml" -Encoding UTF8 -Value "<?xml version=""1.0"" encoding=""UTF-8""?><worksheet xmlns=""http://schemas.openxmlformats.org/spreadsheetml/2006/main""><sheetData>$sb</sheetData></worksheet>"
    if (Test-Path $Path) { Remove-Item -LiteralPath $Path -Force }
    $fs = [IO.File]::Open($Path, [IO.FileMode]::CreateNew)
    $archive = [IO.Compression.ZipArchive]::new($fs, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in Get-ChildItem -LiteralPath $temp -Recurse -File) {
            $relative = $file.FullName.Substring($temp.Length).TrimStart('\','/').Replace('\','/')
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relative) | Out-Null
        }
    } finally {
        $archive.Dispose()
        $fs.Dispose()
    }
    Remove-Item -LiteralPath $temp -Recurse -Force
}

function CreateStandardZip([string]$SourceDir, [string]$ZipPath) {
    $tmpZip = Join-Path ([IO.Path]::GetTempPath()) ("douyin_package_" + [Guid]::NewGuid() + ".zip")
    if (Test-Path -LiteralPath $tmpZip) { Remove-Item -LiteralPath $tmpZip -Force }
    $fs = [IO.File]::Open($tmpZip, [IO.FileMode]::CreateNew)
    $archive = [IO.Compression.ZipArchive]::new($fs, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in Get-ChildItem -LiteralPath $SourceDir -Recurse -File) {
            if ($file.FullName -eq $ZipPath) { continue }
            if ($file.FullName -like "*\_zip_staging\*") { continue }
            $relative = $file.FullName.Substring($SourceDir.Length).TrimStart('\','/').Replace('\','/')
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relative, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    } finally {
        $archive.Dispose()
        $fs.Dispose()
    }
    if (Test-Path -LiteralPath $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
    Move-Item -LiteralPath $tmpZip -Destination $ZipPath -Force
}

function SanitizeFileNamePart([string]$Text, [string]$Fallback) {
    $value = Compact $Text
    if ([string]::IsNullOrWhiteSpace($value)) { $value = $Fallback }
    $invalid = [IO.Path]::GetInvalidFileNameChars()
    foreach ($ch in $invalid) {
        $value = $value.Replace([string]$ch, "_")
    }
    $value = ($value -replace "\s+", "")
    $value = ($value -replace "[\\/:*?""<>|]", "_")
    if ($value.Length -gt 40) { $value = $value.Substring(0, 40) }
    if ([string]::IsNullOrWhiteSpace($value)) { $value = $Fallback }
    return $value
}

function GetUniqueFilePath([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $Path }
    $dir = Split-Path -Parent $Path
    $name = [IO.Path]::GetFileNameWithoutExtension($Path)
    $ext = [IO.Path]::GetExtension($Path)
    for ($i = 2; $i -lt 1000; $i++) {
        $candidate = Join-Path $dir ("{0}-{1:D2}{2}" -f $name, $i, $ext)
        if (-not (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    throw "无法生成唯一输出文件名：$Path"
}

function GetDeliveryZipPath([int]$WorkCount) {
    New-Item -ItemType Directory -Force -Path $Script:OutputZipRoot | Out-Null
    $shopName = SanitizeFileNamePart $Script:TargetProfileName "douyin_account"
    $countPart = "{0:D3}" -f [Math]::Max(0, $WorkCount)
    $timePart = if ([string]::IsNullOrWhiteSpace($Script:RunTimestamp)) { (Get-Date).ToString("yyyyMMdd_HHmm") } else { $Script:RunTimestamp }
    $fileName = "$shopName-$countPart-$timePart.zip"
    return GetUniqueFilePath (Join-Path $Script:OutputZipRoot $fileName)
}

function ProjectRelPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    try {
        $rootFull = [IO.Path]::GetFullPath($Script:Root).TrimEnd('\','/')
        $pathFull = [IO.Path]::GetFullPath($Path)
        if ($pathFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
            return $pathFull.Substring($rootFull.Length).TrimStart('\','/').Replace('\','/')
        }
    } catch {}
    return $Path.Replace('\','/')
}

function AssertSelfTest([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "自检失败：$Message"
    }
}

function InvokeSelfTest {
    Write-Host "开始自检..."

    AssertSelfTest ((NormalizeUrl "https://www.douyin.com/video/123456") -eq "https://www.douyin.com/video/123456") "NormalizeUrl 标准链接"
    AssertSelfTest ((NormalizeUrl "/video/123456") -eq "https://www.douyin.com/video/123456") "NormalizeUrl 相对链接"
    AssertSelfTest ((GetWorkId "https://www.douyin.com/user/abc?modal_id=7278200516037905701") -eq "7278200516037905701") "GetWorkId modal_id"
    AssertSelfTest ((GetWorkId "https://www.douyin.com/video/123456789") -eq "123456789") "GetWorkId video path"
    AssertSelfTest ((IsWorkUrl "https://www.douyin.com/video/123456789") -eq $true) "IsWorkUrl video"
    AssertSelfTest ((IsWorkUrl "https://www.douyin.com/jingxuan") -eq $false) "IsWorkUrl 非作品链接"
    AssertSelfTest ((ToNumberString "收藏 1") -eq "1") "ToNumberString 收藏 1"
    AssertSelfTest ((ToNumberString "分享 2.5万") -eq "25000") "ToNumberString 万单位"
    AssertSelfTest ([string]::IsNullOrWhiteSpace((GetReliableVisualSummaryText "未满moonfiow优惠团购 了 re wm F \ ! : my — Se a S x 未满noonfiow优惠国购"))) "低质量 OCR 不进入摘要"
    AssertSelfTest ((GetReliableVisualSummaryText "套餐价格 99 元，营业时间 10:00-22:00") -match "套餐价格") "可靠 OCR 可进入摘要"
    $badFlags = DetectConversion @{ title = ""; ocr = "20s：未满moonfiow优惠团购 了 了 re wm F \ ! : my — Se a S x"; transcript = ""; comments = "" }
    AssertSelfTest ($badFlags.group_buy.present -eq $false) "低质量 OCR 不触发团购转化"
    $goodFlags = DetectConversion @{ title = ""; ocr = "套餐价格 99 元，营业时间 10:00-22:00"; transcript = ""; comments = "" }
    AssertSelfTest ($goodFlags.price.present -eq $true) "可靠 OCR 可触发价格转化"
    $fallbackFlags = DetectConversion @{ title = ""; ocr = "OCR 状态：已逐帧生成 ocr_items.json；当前未检测到本机 OCR 输出或 OCR 引擎不可用。关键帧可上传给 ChatGPT 识别画面文字、价格、地址、活动和团购信息。"; transcript = ""; comments = "" }
    AssertSelfTest (($fallbackFlags.address.present -eq $false) -and ($fallbackFlags.group_buy.present -eq $false)) "OCR fallback 提示不触发转化"

    $oldIsTestMode = $Script:IsTestMode
    try {
        $Script:IsTestMode = $false
        SetRunMode 5 5
        AssertSelfTest (($Script:RunMode -eq "sample_check") -and ($Script:SampleSize -eq 5) -and ($Script:FormalAcceptance -eq $false)) "run_mode 样本包"
        SetRunMode 30 10
        AssertSelfTest (($Script:RunMode -eq "formal_collection") -and ($null -eq $Script:SampleSize) -and ($Script:FormalAcceptance -eq $true)) "run_mode 正式包作品数不足30"
    } finally {
        $Script:IsTestMode = $oldIsTestMode
        SetRunMode 30 30
    }

    $jsonOne = ConvertToJsonArray @([ordered]@{ a = 1 }) 5
    AssertSelfTest ($jsonOne.Trim().StartsWith("[") -and $jsonOne.Trim().EndsWith("]")) "ConvertToJsonArray 单对象仍为数组"

    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("douyin_selftest_" + [Guid]::NewGuid())
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    try {
        $oldZipRoot = $Script:OutputZipRoot
        $oldTargetName = $Script:TargetProfileName
        $oldRunTimestamp = $Script:RunTimestamp
        try {
            $Script:OutputZipRoot = Join-Path $tmp "output_zip"
            $Script:TargetProfileName = "测试店/账号"
            $Script:RunTimestamp = "20260628_0123"
            $deliveryZip = GetDeliveryZipPath 5
            AssertSelfTest ($deliveryZip.EndsWith("测试店_账号-005-20260628_0123.zip")) "output_zip 命名规则"
            $rootZip = Join-Path $Script:Root "output_zip\测试店_账号-005-20260628_0123.zip"
            AssertSelfTest ((ProjectRelPath $rootZip) -eq "output_zip/测试店_账号-005-20260628_0123.zip") "output_zip 相对路径"
        } finally {
            $Script:OutputZipRoot = $oldZipRoot
            $Script:TargetProfileName = $oldTargetName
            $Script:RunTimestamp = $oldRunTimestamp
        }

        $failed = NewFailedWork "https://www.douyin.com/user/abc?modal_id=7278200516037905701" 1 $tmp "self test failure"
        $folder = Join-Path $tmp $failed.folder
        foreach ($name in @("meta.json","comments.json","transcript.txt","ocr_text.txt","ocr_items.json","summary.md")) {
            AssertSelfTest (Test-Path -LiteralPath (Join-Path $folder $name)) "失败作品目录缺少 $name"
        }
        AssertSelfTest (($failed.status -eq "failed") -and ($failed.video_id -eq "7278200516037905701")) "失败作品状态/ID"
        AssertSelfTest (($failed.frame_strategy -eq "dense_first_5s_then_every_3s") -and ($failed.frame_count -eq 0)) "失败作品抽帧字段"
        AssertSelfTest (($failed.duration_status -eq "unavailable") -and ($failed.media_type -eq "unknown")) "失败作品时长/媒体字段"
        AssertSelfTest (($failed.run_mode -eq "formal_collection") -and ($failed.formal_acceptance -eq $true)) "失败作品运行模式字段"
        AssertSelfTest (($failed.valid_comment_items_count -eq 0) -and ($failed.reply_items_count -eq 0) -and ($failed.comment_count_match_status -eq "unknown_no_public_count")) "失败作品评论统计字段"

        $xlsx = Join-Path $tmp "works.xlsx"
        WriteXlsx $xlsx @($failed)
        AssertSelfTest (Test-Path -LiteralPath $xlsx) "works.xlsx 生成"
        $zip = [IO.Compression.ZipFile]::OpenRead($xlsx)
        try {
            $entries = @($zip.Entries | ForEach-Object { $_.FullName })
            AssertSelfTest ($entries -contains "xl/workbook.xml") "xlsx workbook.xml"
            AssertSelfTest ($entries -contains "xl/worksheets/sheet1.xml") "xlsx sheet1.xml"
        } finally {
            $zip.Dispose()
        }

        $summary = RenderAccountSummary @($failed)
        AssertSelfTest ($summary -match "作品总数：1") "account_summary 作品总数"
        AssertSelfTest ($summary -match "failed_count：1") "account_summary failed_count"
        $workSummary = RenderWorkSummary $failed
        AssertSelfTest ($workSummary -match "画面节奏分析") "work summary 画面节奏分析"
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "自检通过。"
}

if ($SelfTest) {
    InvokeSelfTest
    exit 0
}

function RunCollect([string]$ProfileUrl, [int]$Limit, [string]$Mode, $LogBox, $OpenButton, $StartButton, $ProgressBar, $StatusLabel) {
    try {
        if ($Mode -ne "authorized") { $Mode = "public" }
        $Script:CollectionMode = $Mode
        $Script:CardMetadata = @{}
        $Script:TargetWorksCount = 0
        $Script:EffectiveWorkLimit = 0
        SetRunMode $Limit $Limit
        $Script:PreferredCdpUrl = NormalizeUrl $ProfileUrl
        SetStatus $StatusLabel "正在准备本地输出文件夹..."
        SetProgress $ProgressBar 0 1
        New-Item -ItemType Directory -Force -Path $Script:OutputRoot | Out-Null
        $Script:RunTimestamp = (Get-Date).ToString("yyyyMMdd_HHmm")
        $pkg = Join-Path $Script:OutputRoot ("douyin_package_" + (Get-Date).ToString("yyyyMMdd_HHmmss"))
        New-Item -ItemType Directory -Force -Path $pkg | Out-Null
        $Script:CurrentPackage = $pkg
        $Script:CurrentOutputZipPath = ""
        SetStatus $StatusLabel "正在使用已保存的登录状态打开 Edge..."
        $hadProfile = StartEdge $Script:PreferredCdpUrl
        if ($hadProfile) {
            Log $LogBox "已使用本地登录资料打开 Edge：$Script:EdgeProfile"
        } else {
            Log $LogBox "首次运行：登录状态会保存在 $Script:EdgeProfile"
        }
        Log $LogBox "当前采集模式：$Mode。public 模式不会把播放/点赞/评论等授权数据缺失判为失败。"
        Log $LogBox "如果抖音没有强制退出账号，后续一般不需要重新扫码。"
        ConnectCdp $Script:PreferredCdpUrl
        Cdp "Page.enable" @{} | Out-Null
        Cdp "Runtime.enable" @{} | Out-Null
        SetStatus $StatusLabel "正在打开主页，并自动检查登录状态和作品列表..."
        $links = @(CollectLinks $ProfileUrl $Limit $LogBox)
        if ($links.Count -eq 0) { throw "没有找到作品链接。请确认 Edge 中的主页作品列表已经正常显示。" }
        Log $LogBox "找到 $($links.Count) 条作品。"
        Log $LogBox ("前几条作品链接：" + (($links | Select-Object -First 5) -join " | "))
        SetProgress $ProgressBar 0 $links.Count
        $items = New-Object System.Collections.Generic.List[object]
        for ($i = 0; $i -lt $links.Count; $i++) {
            $current = $i + 1
            SetStatus $StatusLabel "正在采集第 $current / $($links.Count) 条作品"
            try {
                $items.Add((CollectWork $links[$i] ($items.Count + 1) $pkg $LogBox))
            } catch {
                Log $LogBox ("跳过第 " + $current + " 条作品链接：" + $_.Exception.Message)
                if ($_.Exception.Message -notmatch "作者与目标账号不一致") {
                    $items.Add((NewFailedWork $links[$i] ($items.Count + 1) $pkg $_.Exception.Message))
                }
            }
            SetProgress $ProgressBar $current $links.Count
        }
        if ($items.Count -eq 0) {
            throw "没有成功采集到有效作品。请确认主页中能看到可点击的视频作品。"
        }
        SetStatus $StatusLabel "正在写入 Markdown、JSON、XLSX 并打包 ZIP..."
        $Script:CurrentOutputZipPath = GetDeliveryZipPath $items.Count
        Set-Content -LiteralPath (Join-Path $pkg "account_summary.md") -Encoding UTF8 -Value (RenderAccountSummary $items)
        Set-Content -LiteralPath (Join-Path $pkg "works.json") -Encoding UTF8 -Value (ConvertToJsonArray ($items.ToArray()) 30)
        WriteXlsx (Join-Path $pkg "works.xlsx") $items
        $zip = $Script:CurrentOutputZipPath
        CreateStandardZip $pkg $zip
        SetStatus $StatusLabel "完成，分析包已生成。"
        Log $LogBox "完成：$zip"
        if ($null -ne $OpenButton) {
            if ($OpenButton.InvokeRequired) {
                $OpenButton.Invoke([Action]{ $OpenButton.Enabled = $true }) | Out-Null
            } else {
                $OpenButton.Enabled = $true
            }
        }
        if ($null -ne $StartButton) {
            [Windows.Forms.MessageBox]::Show("分析包已生成：`r`n$zip", "完成") | Out-Null
        }
    } catch {
        SetStatus $StatusLabel "失败，请查看下方日志。"
        Log $LogBox ("失败：" + $_.Exception.Message)
        if ($null -ne $StartButton) {
            [Windows.Forms.MessageBox]::Show($_.Exception.Message, "失败") | Out-Null
        }
    } finally {
        if ($Script:Socket) { $Script:Socket.Dispose(); $Script:Socket = $null }
        if ($null -ne $StartButton) {
            if ($StartButton.InvokeRequired) {
                $StartButton.Invoke([Action]{ $StartButton.Enabled = $true }) | Out-Null
            } else {
                $StartButton.Enabled = $true
            }
        }
    }
}

if ($TestMode) {
    if ([string]::IsNullOrWhiteSpace($ProfileUrl)) {
        throw "测试/采集需要传入 -ProfileUrl。"
    }
    $Script:IsTestMode = $true
    $limit = if ($PSBoundParameters.ContainsKey('MaxWorks')) { $MaxWorks } else { 1 }
    Write-Host "开始抖音采集，test_mode=$Script:IsTestMode，max_works=$limit"
    RunCollect $ProfileUrl $limit $CollectionMode $null $null $null $null $null
    Write-Host "抖音实际采集自检结束。"
    exit 0
}

if (-not [string]::IsNullOrWhiteSpace($ProfileUrl)) {
    $Script:IsTestMode = $false
    $limit = if ($PSBoundParameters.ContainsKey('MaxWorks')) { $MaxWorks } else { 30 }
    if ($limit -le 0) { $limit = 30 }
    Write-Host "开始抖音正式采集，test_mode=False，max_works=$limit"
    RunCollect $ProfileUrl $limit $CollectionMode $null $null $null $null $null
    Write-Host "抖音正式采集结束。"
    exit 0
}

if ($CardDebug) {
    if ([string]::IsNullOrWhiteSpace($ProfileUrl)) {
        throw "CardDebug 需要传入 -ProfileUrl。"
    }
    $Script:PreferredCdpUrl = NormalizeUrl $ProfileUrl
    Write-Host "开始页面卡片诊断..."
    StartEdge $Script:PreferredCdpUrl | Out-Null
    ConnectCdp $Script:PreferredCdpUrl
    Cdp "Page.enable" @{} | Out-Null
    Cdp "Runtime.enable" @{} | Out-Null
    Nav $ProfileUrl
    WaitProfileReady $ProfileUrl $null
    Js "window.scrollTo(0,0); true" | Out-Null
    Start-Sleep -Seconds 1
    $diag = Js "JSON.stringify((()=>{const out=[];const pick=(el)=>{let p=el;for(let i=0;i<5&&p;i++,p=p.parentElement){const r=p.getBoundingClientRect();out.push({tag:p.tagName,cls:(p.className||'').toString().slice(0,80),text:(p.innerText||'').replace(/\s+/g,' ').trim().slice(0,50),left:Math.round(r.left),top:Math.round(r.top),width:Math.round(r.width),height:Math.round(r.height),img:el.src||''})}};Array.from(document.querySelectorAll('img,video')).slice(0,40).forEach(pick);return out})())"
    Write-Host $diag
    $cards = Js (CardScanJs "[]")
    Write-Host "当前 CardScanJs 结果："
    Write-Host $cards
    if ($Script:Socket) { $Script:Socket.Dispose(); $Script:Socket = $null }
    exit 0
}

$form = [Windows.Forms.Form]::new()
$form.Text = U @(0x6296,0x97F3,0x8D26,0x53F7,0x5206,0x6790,0x5305,0x751F,0x6210,0x5668)
$form.Size = [Drawing.Size]::new(920, 680)
$form.MinimumSize = [Drawing.Size]::new(860, 620)
$form.StartPosition = "CenterScreen"
$form.BackColor = [Drawing.Color]::FromArgb(246, 248, 251)
$form.Font = [Drawing.Font]::new("Microsoft YaHei UI", 9)

$header = [Windows.Forms.Panel]::new()
$header.Dock = [Windows.Forms.DockStyle]::Top
$header.Height = 86
$header.BackColor = [Drawing.Color]::FromArgb(17, 24, 39)
$form.Controls.Add($header)

$title = [Windows.Forms.Label]::new()
$title.Text = U @(0x6296,0x97F3,0x8D26,0x53F7,0x5206,0x6790,0x5305,0x751F,0x6210,0x5668)
$title.ForeColor = [Drawing.Color]::White
$title.Font = [Drawing.Font]::new("Microsoft YaHei UI", 18, [Drawing.FontStyle]::Bold)
$title.Location = [Drawing.Point]::new(24, 14)
$title.Size = [Drawing.Size]::new(520, 34)
$header.Controls.Add($title)

$subtitle = [Windows.Forms.Label]::new()
$subtitle.Text = "粘贴一个抖音主页链接，工具会自动检查主页状态，采集可见作品并生成 ZIP。"
$subtitle.ForeColor = [Drawing.Color]::FromArgb(203, 213, 225)
$subtitle.Location = [Drawing.Point]::new(26, 52)
$subtitle.Size = [Drawing.Size]::new(780, 22)
$header.Controls.Add($subtitle)

$inputPanel = [Windows.Forms.Panel]::new()
$inputPanel.Location = [Drawing.Point]::new(18, 104)
$inputPanel.Size = [Drawing.Size]::new(866, 128)
$inputPanel.Anchor = "Top,Left,Right"
$inputPanel.BackColor = [Drawing.Color]::White
$inputPanel.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($inputPanel)

$label = [Windows.Forms.Label]::new()
$label.Text = U @(0x6296,0x97F3,0x8D26,0x53F7,0x4E3B,0x9875,0x94FE,0x63A5)
$label.Location = [Drawing.Point]::new(16, 14)
$label.Size = [Drawing.Size]::new(180, 22)
$label.Font = [Drawing.Font]::new("Microsoft YaHei UI", 9, [Drawing.FontStyle]::Bold)
$inputPanel.Controls.Add($label)

$urlBox = [Windows.Forms.TextBox]::new()
$urlBox.Location = [Drawing.Point]::new(16, 40)
$urlBox.Size = [Drawing.Size]::new(828, 25)
$urlBox.Anchor = "Top,Left,Right"
$inputPanel.Controls.Add($urlBox)

$countLabel = [Windows.Forms.Label]::new()
$countLabel.Text = "采集上限"
$countLabel.Location = [Drawing.Point]::new(16, 82)
$countLabel.Size = [Drawing.Size]::new(96, 24)
$inputPanel.Controls.Add($countLabel)

$countBox = [Windows.Forms.NumericUpDown]::new()
$countBox.Location = [Drawing.Point]::new(116, 79)
$countBox.Minimum = 1
$countBox.Maximum = 100
$countBox.Value = 30
$countBox.Size = [Drawing.Size]::new(78, 25)
$inputPanel.Controls.Add($countBox)

$modeLabel = [Windows.Forms.Label]::new()
$modeLabel.Text = "采集模式"
$modeLabel.Location = [Drawing.Point]::new(214, 82)
$modeLabel.Size = [Drawing.Size]::new(70, 24)
$inputPanel.Controls.Add($modeLabel)

$modeBox = [Windows.Forms.ComboBox]::new()
$modeBox.Location = [Drawing.Point]::new(282, 78)
$modeBox.Size = [Drawing.Size]::new(112, 26)
$modeBox.DropDownStyle = [Windows.Forms.ComboBoxStyle]::DropDownList
[void]$modeBox.Items.Add("public")
[void]$modeBox.Items.Add("authorized")
$modeBox.SelectedIndex = 0
$inputPanel.Controls.Add($modeBox)

$startButton = [Windows.Forms.Button]::new()
$startButton.Text = U @(0x5F00,0x59CB,0x751F,0x6210)
$startButton.Location = [Drawing.Point]::new(410, 75)
$startButton.Size = [Drawing.Size]::new(118, 34)
$startButton.BackColor = [Drawing.Color]::FromArgb(15, 118, 110)
$startButton.ForeColor = [Drawing.Color]::White
$startButton.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$inputPanel.Controls.Add($startButton)

$openButton = [Windows.Forms.Button]::new()
$openButton.Text = U @(0x6253,0x5F00,0x8F93,0x51FA,0x6587,0x4EF6,0x5939)
$openButton.Location = [Drawing.Point]::new(540, 75)
$openButton.Size = [Drawing.Size]::new(142, 34)
$openButton.Enabled = $false
$openButton.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$inputPanel.Controls.Add($openButton)

$hint = [Windows.Forms.Label]::new()
$hint.Text = "正式默认：小于30采全部，大于30采最近30。"
$hint.Location = [Drawing.Point]::new(700, 78)
$hint.Size = [Drawing.Size]::new(144, 38)
$hint.Anchor = "Top,Right"
$hint.ForeColor = [Drawing.Color]::FromArgb(82, 92, 108)
$inputPanel.Controls.Add($hint)

$statusPanel = [Windows.Forms.Panel]::new()
$statusPanel.Location = [Drawing.Point]::new(18, 246)
$statusPanel.Size = [Drawing.Size]::new(866, 92)
$statusPanel.Anchor = "Top,Left,Right"
$statusPanel.BackColor = [Drawing.Color]::White
$statusPanel.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($statusPanel)

$statusTitle = [Windows.Forms.Label]::new()
$statusTitle.Text = U @(0x5F53,0x524D,0x4EFB,0x52A1)
$statusTitle.Location = [Drawing.Point]::new(16, 12)
$statusTitle.Size = [Drawing.Size]::new(120, 22)
$statusTitle.Font = [Drawing.Font]::new("Microsoft YaHei UI", 9, [Drawing.FontStyle]::Bold)
$statusPanel.Controls.Add($statusTitle)

$statusValue = [Windows.Forms.Label]::new()
$statusValue.Text = U @(0x7B49,0x5F85,0x5F00,0x59CB)
$statusValue.Location = [Drawing.Point]::new(132, 12)
$statusValue.Size = [Drawing.Size]::new(700, 22)
$statusValue.Anchor = "Top,Left,Right"
$statusValue.ForeColor = [Drawing.Color]::FromArgb(15, 118, 110)
$statusPanel.Controls.Add($statusValue)

$progressBar = [Windows.Forms.ProgressBar]::new()
$progressBar.Location = [Drawing.Point]::new(18, 48)
$progressBar.Size = [Drawing.Size]::new(826, 22)
$progressBar.Anchor = "Top,Left,Right"
$progressBar.Minimum = 0
$progressBar.Maximum = 1
$progressBar.Value = 0
$statusPanel.Controls.Add($progressBar)

$logTitle = [Windows.Forms.Label]::new()
$logTitle.Text = U @(0x8FD0,0x884C,0x65E5,0x5FD7)
$logTitle.Location = [Drawing.Point]::new(18, 352)
$logTitle.Size = [Drawing.Size]::new(120, 22)
$logTitle.Font = [Drawing.Font]::new("Microsoft YaHei UI", 9, [Drawing.FontStyle]::Bold)
$form.Controls.Add($logTitle)

$logBox = [Windows.Forms.TextBox]::new()
$logBox.Location = [Drawing.Point]::new(18, 378)
$logBox.Size = [Drawing.Size]::new(866, 238)
$logBox.Anchor = "Top,Bottom,Left,Right"
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.ReadOnly = $true
$logBox.BackColor = [Drawing.Color]::FromArgb(15, 23, 42)
$logBox.ForeColor = [Drawing.Color]::FromArgb(209, 250, 229)
$logBox.Font = [Drawing.Font]::new("Consolas", 10)
$form.Controls.Add($logBox)

$startButton.Add_Click({
    $profileUrl = $urlBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($profileUrl)) {
        [Windows.Forms.MessageBox]::Show("请先粘贴抖音账号主页链接。", "提示") | Out-Null
        return
    }
    $startButton.Enabled = $false
    $openButton.Enabled = $false
    $logBox.Clear()
    $progressBar.Value = 0
    $progressBar.Maximum = 1
    $statusValue.Text = "正在启动..."
    Log $logBox "任务已开始，准备打开 Edge..."
    $limit = [int]$countBox.Value
    $mode = [string]$modeBox.SelectedItem
    $Script:IsTestMode = $false
    RunCollect $profileUrl $limit $mode $logBox $openButton $startButton $progressBar $statusValue
})

$openButton.Add_Click({
    if ($Script:CurrentPackage -and (Test-Path $Script:CurrentPackage)) {
        Start-Process explorer.exe $Script:CurrentPackage
    } else {
        Start-Process explorer.exe $Script:OutputRoot
    }
})

[void]$form.ShowDialog()
