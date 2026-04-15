local menuOpen = false
local activeToken = nil
local activeNonce = nil
local claimInFlight = false

local function resetClientState()
    menuOpen = false
    activeToken = nil
    activeNonce = nil
    claimInFlight = false
end

RegisterNetEvent('xyz_dailyreward:client:open', function(data)
    if type(data) ~= 'table' then
        return
    end

    menuOpen = true
    claimInFlight = false
    activeToken = data.token or nil
    activeNonce = data.nonce or nil

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'open',
        title = data.title or Config.Title,
        subtitle = data.subtitle or Config.Subtitle,
        accent = data.accent or Config.ThemeAccent,
        accent2 = data.accent2 or Config.ThemeAccent2,
        token = activeToken,
        nonce = activeNonce,
        currentDay = data.currentDay or 1,
        claimCount = data.claimCount or 0,
        month = data.month or 0,
        year = data.year or 0,
        realDate = data.realDate or '',
        monthLabel = data.monthLabel or '',
        days = data.days or {}
    })
end)

RegisterNetEvent('xyz_dailyreward:client:update', function(data)
    if type(data) ~= 'table' then
        return
    end

    claimInFlight = false
    activeToken = data.token or activeToken
    activeNonce = data.nonce or activeNonce

    SendNUIMessage({
        action = 'update',
        token = activeToken,
        nonce = activeNonce,
        currentDay = data.currentDay or 1,
        claimCount = data.claimCount or 0,
        month = data.month or 0,
        year = data.year or 0,
        realDate = data.realDate or '',
        monthLabel = data.monthLabel or '',
        days = data.days or {}
    })
end)

RegisterNetEvent('xyz_dailyreward:client:claimFailed', function()
    claimInFlight = false
end)

RegisterCommand(Config.Command, function()
    TriggerServerEvent('xyz_dailyreward:server:open')
end, false)

RegisterKeyMapping(Config.Command, 'Open Daily Reward', 'keyboard', Config.OpenKey)

RegisterNUICallback('close', function(_, cb)
    resetClientState()

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'close'
    })

    cb({})
end)

RegisterNUICallback('claim', function(data, cb)
    if claimInFlight or not menuOpen then
        cb({})
        return
    end

    claimInFlight = true

    TriggerServerEvent('xyz_dailyreward:server:claim', {
        day = tonumber(data.day or 0) or 0,
        token = activeToken,
        nonce = activeNonce
    })

    cb({})
end)