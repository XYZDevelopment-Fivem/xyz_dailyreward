local Sessions = {}
local LastOpen = {}
local LastClaim = {}
local ClaimInProgress = {}
local ProcessedClaims = {}

local function nowMs()
    return GetGameTimer()
end

local function getIdentifier(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    if license and license ~= '' then
        return license
    end

    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier and identifier ~= '' then
            return identifier
        end
    end

    return nil
end

local function getNowTable()
    if Config.UseUTC then
        return os.date('!*t')
    end

    return os.date('*t')
end

local function getCurrentYearMonthDay()
    local t = getNowTable()
    return t.year, t.month, t.day
end

local function getDisplayDate()
    if Config.UseUTC then
        return os.date('!%d.%m.%Y')
    end

    return os.date('%d.%m.%Y')
end

local function getDisplayMonthLabel(year, month)
    local timestamp = os.time({
        year = year,
        month = month,
        day = 1,
        hour = 12,
        min = 0,
        sec = 0
    })

    if Config.UseUTC then
        return os.date('!%B %Y', timestamp)
    end

    return os.date('%B %Y', timestamp)
end

local function jsonEncode(data)
    return json.encode(data or {})
end

local function jsonDecode(data)
    if not data or data == '' then
        return {}
    end

    local ok, decoded = pcall(json.decode, data)
    if not ok or type(decoded) ~= 'table' then
        return {}
    end

    return decoded
end

local function createSecureValue()
    local a = math.random(100000, 999999)
    local b = math.random(100000, 999999)
    local c = math.random(100000, 999999)
    local d = math.random(100000, 999999)
    return ('%s:%s:%s:%s:%s'):format(os.time(), GetGameTimer(), a, b, c + d)
end

local function notify(src, title, description, ntype, duration)
    TriggerClientEvent('ox_lib:notify', src, {
        title = title,
        description = description,
        type = ntype or 'info',
        duration = duration or 4500
    })
end

local function buildEmbedColor(kind)
    if kind == 'success' then
        return 8388863
    end

    if kind == 'warning' then
        return 16753920
    end

    if kind == 'danger' then
        return 16724787
    end

    return 9109503
end

local function sendWebhook(title, kind, fields)
    local webhook = XYZServer and XYZServer.Webhook or nil
    if not webhook or webhook == '' then
        return
    end

    local embedFields = {}

    for i = 1, #fields do
        local field = fields[i]
        embedFields[#embedFields + 1] = {
            name = tostring(field.name or 'Field'),
            value = tostring(field.value or 'None'),
            inline = field.inline == true
        }
    end

    local payload = {
        username = 'XYZ Daily Reward',
        embeds = {
            {
                title = title,
                color = buildEmbedColor(kind),
                fields = embedFields,
                footer = {
                    text = ('XYZ Daily Reward • %s'):format(getDisplayDate())
                },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
    }

    PerformHttpRequest(webhook, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

local function ensureRow(identifier, year, month)
    local row = MySQL.single.await(
        'SELECT * FROM xyz_daily_rewards WHERE identifier = ? AND reward_year = ? AND reward_month = ? LIMIT 1',
        { identifier, year, month }
    )

    if row then
        return row
    end

    MySQL.insert.await(
        'INSERT INTO xyz_daily_rewards (identifier, reward_year, reward_month, claimed_days, last_claim_day, streak, updated_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
        { identifier, year, month, '[]', 0, 0 }
    )

    return MySQL.single.await(
        'SELECT * FROM xyz_daily_rewards WHERE identifier = ? AND reward_year = ? AND reward_month = ? LIMIT 1',
        { identifier, year, month }
    )
end

local function hasClaimedDay(claimedDays, day)
    local target = tonumber(day)
    for i = 1, #claimedDays do
        if tonumber(claimedDays[i]) == target then
            return true
        end
    end
    return false
end

local function getMonthClaimCount(claimedDays)
    return #claimedDays
end

local function canClaimDay(claimedDays, currentDay, requestedDay)
    if requestedDay < 1 or requestedDay > Config.MonthDays then
        return false, 'invalid_day'
    end

    if hasClaimedDay(claimedDays, requestedDay) then
        return false, 'already_claimed'
    end

    if Config.RequireOneByOneClaim then
        if Config.AllowCatchupClaims then
            local nextDay = 1

            for day = 1, Config.MonthDays do
                if not hasClaimedDay(claimedDays, day) then
                    nextDay = day
                    break
                end
            end

            if requestedDay ~= nextDay then
                return false, 'not_next_day'
            end

            if requestedDay > currentDay then
                return false, 'future_day'
            end

            return true
        end

        if requestedDay ~= currentDay then
            return false, 'not_today'
        end

        return true
    end

    if Config.AllowCatchupClaims then
        if requestedDay > currentDay then
            return false, 'future_day'
        end

        return true
    end

    if requestedDay ~= currentDay then
        return false, 'not_today'
    end

    return true
end

local function buildDaysPayload(claimedDays, currentDay)
    local days = {}

    for day = 1, Config.MonthDays do
        local rewardEntry = Config.Rewards[day] or {
            label = ('Day %s'):format(day),
            rewards = {}
        }

        local claimed = hasClaimedDay(claimedDays, day)
        local state = 'locked'

        if claimed then
            state = 'claimed'
        elseif day == currentDay then
            state = 'claimable'
        elseif day < currentDay then
            if Config.AllowCatchupClaims then
                state = 'claimable'
            else
                state = 'missed'
            end
        end

        days[#days + 1] = {
            day = day,
            label = rewardEntry.label or ('Day %s'):format(day),
            state = state,
            rewards = rewardEntry.rewards or {}
        }
    end

    return days
end

local function validateReward(reward)
    if type(reward) ~= 'table' then
        return false, 'invalid_reward_data'
    end

    if reward.type ~= 'item' then
        return false, 'unsupported_reward_type'
    end

    local name = tostring(reward.name or '')
    local count = tonumber(reward.count or 0) or 0

    if name == '' or count < 1 then
        return false, 'invalid_item_reward'
    end

    return true
end

local function canCarryAllRewards(src, rewards)
    for i = 1, #rewards do
        local reward = rewards[i]
        local ok, reason = validateReward(reward)
        if not ok then
            return false, reason
        end

        local canCarry = exports.ox_inventory:CanCarryItem(src, reward.name, reward.count)
        if not canCarry then
            return false, 'inventory_full'
        end
    end

    return true
end

local function grantAllRewards(src, rewards)
    local granted = {}

    for i = 1, #rewards do
        local reward = rewards[i]
        local added = exports.ox_inventory:AddItem(src, reward.name, reward.count)
        if not added then
            for x = 1, #granted do
                local prev = granted[x]
                exports.ox_inventory:RemoveItem(src, prev.name, prev.count)
            end

            return false, 'add_item_failed'
        end

        granted[#granted + 1] = {
            name = reward.name,
            count = reward.count
        }
    end

    return true
end

local function getPlayerLogData(src)
    return {
        name = GetPlayerName(src) or 'unknown',
        identifier = getIdentifier(src) or 'unknown'
    }
end

local function logSuspicious(src, reason, extra)
    if not Config.LogSuspicious then
        return
    end

    local player = getPlayerLogData(src)

    sendWebhook('Suspicious Daily Reward Request', 'danger', {
        { name = 'Player', value = player.name, inline = true },
        { name = 'Identifier', value = player.identifier, inline = false },
        { name = 'Reason', value = reason or 'unknown', inline = true },
        { name = 'Extra', value = extra or 'none', inline = false }
    })
end

local function buildRewardText(rewards)
    local parts = {}

    for i = 1, #rewards do
        local reward = rewards[i]
        if reward.type == 'item' then
            parts[#parts + 1] = ('%sx %s'):format(reward.count, reward.name)
        end
    end

    if #parts == 0 then
        return 'No rewards'
    end

    return table.concat(parts, ', ')
end

local function createSession(src, identifier, year, month)
    Sessions[src] = {
        identifier = identifier,
        token = createSecureValue(),
        nonce = createSecureValue(),
        expires = os.time() + Config.TokenLifetimeSeconds,
        year = year,
        month = month
    }

    return Sessions[src]
end

local function clearPlayerState(src)
    Sessions[src] = nil
    LastOpen[src] = nil
    LastClaim[src] = nil
    ClaimInProgress[src] = nil
    ProcessedClaims[src] = nil
end

local function openDailyReward(src)
    local identifier = getIdentifier(src)
    if not identifier then
        notify(src, 'Daily Reward', 'Your identifier could not be loaded.', 'error')
        return
    end

    local currentTick = nowMs()
    if LastOpen[src] and currentTick - LastOpen[src] < Config.RequestCooldownMs then
        return
    end
    LastOpen[src] = currentTick

    local year, month, currentDay = getCurrentYearMonthDay()
    local row = ensureRow(identifier, year, month)
    local claimedDays = jsonDecode(row.claimed_days)
    local session = createSession(src, identifier, year, month)

    TriggerClientEvent('xyz_dailyreward:client:open', src, {
        title = Config.Title,
        subtitle = Config.Subtitle,
        accent = Config.ThemeAccent,
        accent2 = Config.ThemeAccent2,
        token = session.token,
        nonce = session.nonce,
        currentDay = currentDay,
        claimCount = getMonthClaimCount(claimedDays),
        days = buildDaysPayload(claimedDays, currentDay),
        month = month,
        year = year,
        realDate = getDisplayDate(),
        monthLabel = getDisplayMonthLabel(year, month)
    })

    if Config.LogMenuOpen then
        local player = getPlayerLogData(src)

        sendWebhook('Daily Reward Menu Opened', 'info', {
            { name = 'Player', value = player.name, inline = true },
            { name = 'Identifier', value = player.identifier, inline = false },
            { name = 'Date', value = getDisplayDate(), inline = true },
            { name = 'Period', value = ('%s / %s'):format(month, year), inline = true }
        })
    end
end

RegisterCommand(Config.Command, function(src)
    if src <= 0 then
        return
    end

    openDailyReward(src)
end, false)

RegisterNetEvent('xyz_dailyreward:server:open', function()
    openDailyReward(source)
end)

RegisterNetEvent('xyz_dailyreward:server:claim', function(payload)
    local src = source
    local identifier = getIdentifier(src)

    if not identifier then
        notify(src, 'Daily Reward', 'Your identifier could not be loaded.', 'error')
        logSuspicious(src, 'identifier_missing', 'claim_without_identifier')
        TriggerClientEvent('xyz_dailyreward:client:claimFailed', src)
        return
    end

    local currentTick = nowMs()
    if LastClaim[src] and currentTick - LastClaim[src] < Config.ClaimCooldownMs then
        notify(src, 'Daily Reward', 'Please wait a moment before trying again.', 'warning')
        TriggerClientEvent('xyz_dailyreward:client:claimFailed', src)
        return
    end
    LastClaim[src] = currentTick

    if ClaimInProgress[src] then
        logSuspicious(src, 'claim_in_progress', 'parallel_claim_attempt')
        notify(src, 'Daily Reward', 'Request already in progress.', 'warning')
        TriggerClientEvent('xyz_dailyreward:client:claimFailed', src)
        return
    end

    ClaimInProgress[src] = true

    local function finishFailure(title, description, ntype, suspiciousReason, suspiciousExtra)
        if title and description then
            notify(src, title, description, ntype or 'error')
        end

        if suspiciousReason then
            logSuspicious(src, suspiciousReason, suspiciousExtra)
        end

        ClaimInProgress[src] = nil
        TriggerClientEvent('xyz_dailyreward:client:claimFailed', src)
    end

    if type(payload) ~= 'table' then
        finishFailure('Daily Reward', 'Invalid request.', 'error', 'payload_invalid', 'payload_not_table')
        return
    end

    local session = Sessions[src]
    if not session then
        finishFailure('Daily Reward', 'Session expired. Open the menu again.', 'error', 'session_missing', 'no_active_session')
        return
    end

    if session.identifier ~= identifier then
        Sessions[src] = nil
        finishFailure('Daily Reward', 'Session mismatch. Reopen the menu.', 'error', 'session_identifier_mismatch', 'identifier_changed')
        return
    end

    if os.time() > session.expires then
        Sessions[src] = nil
        finishFailure('Daily Reward', 'Session expired. Open the menu again.', 'error', 'session_expired', 'expired_token')
        return
    end

    local token = tostring(payload.token or '')
    local nonce = tostring(payload.nonce or '')
    local requestedDay = tonumber(payload.day or 0) or 0

    if token == '' or token ~= session.token then
        finishFailure('Daily Reward', 'Invalid reward token.', 'error', 'token_invalid', ('day=%s'):format(requestedDay))
        return
    end

    if nonce == '' or nonce ~= session.nonce then
        finishFailure('Daily Reward', 'Invalid reward session.', 'error', 'nonce_invalid', ('day=%s'):format(requestedDay))
        return
    end

    local uniqueClaimKey = ('%s:%s:%s:%s:%s'):format(identifier, session.year, session.month, requestedDay, nonce)
    if ProcessedClaims[uniqueClaimKey] then
        finishFailure('Daily Reward', 'This claim request was already used.', 'error', 'duplicate_claim_key', uniqueClaimKey)
        return
    end
    ProcessedClaims[uniqueClaimKey] = true

    local year, month, currentDay = getCurrentYearMonthDay()

    if session.year ~= year or session.month ~= month then
        Sessions[src] = nil
        finishFailure('Daily Reward', 'Reward period changed. Reopen the menu.', 'error', 'period_changed', ('session=%s/%s current=%s/%s'):format(session.month, session.year, month, year))
        return
    end

    local rewardConfig = Config.Rewards[requestedDay]
    if not rewardConfig or type(rewardConfig.rewards) ~= 'table' then
        finishFailure('Daily Reward', 'This reward is not configured.', 'error', 'reward_not_configured', ('day=%s'):format(requestedDay))
        return
    end

    local row = ensureRow(identifier, year, month)
    local claimedDays = jsonDecode(row.claimed_days)

    local canClaim, reason = canClaimDay(claimedDays, currentDay, requestedDay)
    if not canClaim then
        local reasons = {
            invalid_day = 'Invalid day.',
            already_claimed = 'You already claimed this reward.',
            not_next_day = 'You must claim rewards in order.',
            future_day = 'You cannot claim a future reward.',
            not_today = 'You can only claim today reward.'
        }

        finishFailure('Daily Reward', reasons[reason] or 'You cannot claim this reward right now.', 'error')
        return
    end

    local carryOk, carryReason = canCarryAllRewards(src, rewardConfig.rewards)
    if not carryOk then
        if carryReason == 'inventory_full' then
            finishFailure('Daily Reward', 'You do not have enough inventory space.', 'error')
            return
        end

        finishFailure('Daily Reward', 'Reward configuration is invalid.', 'error', 'reward_validation_failed', tostring(carryReason))
        return
    end

    local grantOk, grantReason = grantAllRewards(src, rewardConfig.rewards)
    if not grantOk then
        finishFailure('Daily Reward', 'Reward delivery failed.', 'error', 'grant_failed', tostring(grantReason))
        return
    end

    claimedDays[#claimedDays + 1] = requestedDay

    table.sort(claimedDays, function(a, b)
        return tonumber(a) < tonumber(b)
    end)

    local streak = tonumber(row.streak or 0) or 0
    if requestedDay == 1 then
        streak = 1
    else
        streak = streak + 1
    end

    MySQL.update.await(
        'UPDATE xyz_daily_rewards SET claimed_days = ?, last_claim_day = ?, streak = ?, updated_at = NOW() WHERE identifier = ? AND reward_year = ? AND reward_month = ?',
        {
            jsonEncode(claimedDays),
            requestedDay,
            streak,
            identifier,
            year,
            month
        }
    )

    local newSession = createSession(src, identifier, year, month)

    TriggerClientEvent('xyz_dailyreward:client:update', src, {
        token = newSession.token,
        nonce = newSession.nonce,
        currentDay = currentDay,
        claimCount = getMonthClaimCount(claimedDays),
        days = buildDaysPayload(claimedDays, currentDay),
        month = month,
        year = year,
        realDate = getDisplayDate(),
        monthLabel = getDisplayMonthLabel(year, month)
    })

    notify(src, 'Daily Reward', ('You claimed day %s reward.'):format(requestedDay), 'success')

    if Config.LogClaims then
        local player = getPlayerLogData(src)

        sendWebhook('Daily Reward Claimed', 'success', {
            { name = 'Player', value = player.name, inline = true },
            { name = 'Identifier', value = player.identifier, inline = false },
            { name = 'Claimed Day', value = tostring(requestedDay), inline = true },
            { name = 'Streak', value = tostring(streak), inline = true },
            { name = 'Rewards', value = buildRewardText(rewardConfig.rewards), inline = false },
            { name = 'Date', value = getDisplayDate(), inline = true },
            { name = 'Period', value = getDisplayMonthLabel(year, month), inline = true }
        })
    end

    ClaimInProgress[src] = nil
end)

AddEventHandler('playerDropped', function()
    clearPlayerState(source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS xyz_daily_rewards (
            id INT NOT NULL AUTO_INCREMENT,
            identifier VARCHAR(90) NOT NULL,
            reward_year INT NOT NULL,
            reward_month INT NOT NULL,
            claimed_days LONGTEXT NULL,
            last_claim_day INT NOT NULL DEFAULT 0,
            streak INT NOT NULL DEFAULT 0,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY unique_reward_period (identifier, reward_year, reward_month)
        )
    ]])

    sendWebhook('Daily Reward Resource Started', 'info', {
        { name = 'Resource', value = GetCurrentResourceName(), inline = true },
        { name = 'Status', value = 'Successfully started', inline = true },
        { name = 'Time', value = os.date('%d.%m.%Y %H:%M:%S'), inline = false }
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    sendWebhook('Daily Reward Resource Stopped', 'info', {
        { name = 'Resource', value = GetCurrentResourceName(), inline = true },
        { name = 'Status', value = 'Resource stopped', inline = true },
        { name = 'Time', value = os.date('%d.%m.%Y %H:%M:%S'), inline = false }
    })

    for src in pairs(Sessions) do
        clearPlayerState(src)
    end
end)