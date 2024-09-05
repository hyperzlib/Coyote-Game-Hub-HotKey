global CoyoteControllerURL
global CoyoteTargetClientId

HttpGet(url) {
    ; https://learn.microsoft.com/en-us/windows/win32/winhttp/winhttprequest
    web := ComObject('WinHttp.WinHttpRequest.5.1')
    web.Open("GET", url, false)
    web.Send()
    return web.ResponseText
}

HttpPost(url, body) {
    ; https://learn.microsoft.com/en-us/windows/win32/winhttp/winhttprequest
    web := ComObject('WinHttp.WinHttpRequest.5.1')
    web.Open("POST", url, false)
    web.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    web.Send(body)
    return web.ResponseText
}

CoyoteUpdateGameConfig(paramStr)
{
    global CoyoteControllerURL, CoyoteTargetClientId

    url := CoyoteControllerURL . "/api/game/" . CoyoteTargetClientId . "/strength_config"
    return HttpPost(url, paramStr)
}

CoyoteAddStrength(value)
{
    return CoyoteUpdateGameConfig("strength.add=" . value)
}

CoyoteSubStrength(value)
{
    return CoyoteUpdateGameConfig("strength.sub=" . value)
}

CoyoteSetStrength(value)
{
    return CoyoteUpdateGameConfig("strength.set=" . value)
}

CoyoteAddRandomStrength(value)
{
    return CoyoteUpdateGameConfig("randomStrength.add=" . value)
}

CoyoteSubRandomStrength(value)
{
    return CoyoteUpdateGameConfig("randomStrength.sub=" . value)
}

CoyoteSetRandomStrength(value)
{
    return CoyoteUpdateGameConfig("randomStrength.set=" . value)
}

CoyoteFire(strength, time)
{
    global CoyoteControllerURL, CoyoteTargetClientId

    timeMs := time * 1000
    url := CoyoteControllerURL . "/api/game/" . CoyoteTargetClientId . "/fire"
    return HttpPost(url, "strength=" . strength . "&time=" . timeMs)
}

CoyoteGetStrength()
{
    global CoyoteControllerURL, CoyoteTargetClientId

    url := CoyoteControllerURL . "/api/game/" . CoyoteTargetClientId . "/strength_config"
    return HttpGet(url)
}

CoyoteGetPulseList()
{
    global CoyoteControllerURL, CoyoteTargetClientId

    url := CoyoteControllerURL . "/api/game/" . CoyoteTargetClientId . "/pulse_list"
    return HttpGet(url)
}

CoyoteGetPulseId()
{
    global CoyoteControllerURL, CoyoteTargetClientId

    url := CoyoteControllerURL . "/api/game/" . CoyoteTargetClientId . "/pulse_id"
    return HttpGet(url)
}

CoyoteSetPulseId(pulseId)
{
    global CoyoteControllerURL, CoyoteTargetClientId

    url := CoyoteControllerURL . "/api/game/" . CoyoteTargetClientId . "/pulse_id"
    return HttpPost(url, "pulseId=" . pulseId)
}