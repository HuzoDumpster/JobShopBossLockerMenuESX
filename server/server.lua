---@diagnostic disable: undefined-global
ESX = exports['es_extended']:getSharedObject()

HistoryCache = {} -- This will store the server-side history.

RegisterNetEvent("huzo:GetSocietyMoney")
AddEventHandler("huzo:GetSocietyMoney", function()
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    local UserJobName = zPlayer.getJob().name
    exports.oxmysql:query('SELECT money, isFrozen FROM huzo_societymoney WHERE job = ?', {UserJobName}, function(result)
        if result and result[1] then
            TriggerClientEvent('huzo:SaveCurrentMoney', pSRC, result[1].money, result[1].isFrozen)
        else
            TriggerClientEvent('huzo:Notify', pSRC, 'error')
        end
    end)
end)

function SendLogs(message)
    local preferences = {  
		{
			["color"] = ServerConfig.Color,
			["title"] = "**".. ServerConfig.Title .."**",
			["description"] = message,
			["footer"] = { ["text"] = os.date("%d.%m.%Y " .. ServerConfig.TimeString .. " %X"), }
		}
	}
    PerformHttpRequest(ServerConfig.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({username = ServerConfig.Username, embeds = preferences, avatar_url = nil}), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent("huzo:GetWeapons")
AddEventHandler("huzo:GetWeapons", function()
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    local UserJobName = zPlayer.getJob().name
    exports.oxmysql:query('SELECT ItemsAndGuns FROM huzo_societymoney WHERE job = ?', {UserJobName}, function(result)
        if result and result[1] then
            local storedGuns = result[1].ItemsAndGuns

            -- build the default table if none in db, though i am yet to think about what if the dev wants to remove their guns, idk it's their problem LOL
            if storedGuns == nil then
                local defaultWeapons = {}
                for _, weapon in ipairs(Config.WeaponsForSocietySlashGang) do
                    table.insert(defaultWeapons, {
                        m = weapon.model,
                        c = 0
                    })
                end
                local defaultWeaponsJSON = json.encode(defaultWeapons)

                -- add them to the db
                exports.oxmysql:update('UPDATE huzo_societymoney SET ItemsAndGuns = ? WHERE job = ?', {
                    defaultWeaponsJSON, UserJobName
                })
                TriggerClientEvent('huzo:Updateguns', pSRC, defaultWeaponsJSON)
            else
                TriggerClientEvent('huzo:Updateguns', pSRC, storedGuns)
            end
        else
            TriggerClientEvent('huzo:Notify', pSRC, Locales.NoSocietyDataFound)
        end
    end)
end)

RegisterNetEvent("huzo:BuyWeapon")
AddEventHandler("huzo:BuyWeapon", function(amount, indx)
    -- NOTE: Stuff like checking if there already is max amount of weapons, is already handled on client, but it's just an extra check, because I don't trust the client...
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    if not zPlayer then
        return
    end
    local UserJobName = zPlayer.getJob().name
    local WantedWeapon = Config.WeaponsForSocietySlashGang[indx]
    if not WantedWeapon then
        TriggerClientEvent('huzo:Notify', pSRC, Locales.InvalidWeaponSelect)
        return
    end
    local WantedModel = WantedWeapon.model

    exports.oxmysql:query('SELECT ItemsAndGuns, money FROM huzo_societymoney WHERE job = ?', {UserJobName}, function(result)
        if result and result[1] and result[1].ItemsAndGuns then
            local weaponsJSON = result[1].ItemsAndGuns
            local currentMoney = tonumber(result[1].money) or 0
            local priceSum = amount * WantedWeapon.price
            local ReCalcMoney = currentMoney - priceSum


            -- quick security checking
            if WantedWeapon.maxInLocker < amount then
                TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.ImpossibleAction)
                return
            end
            if WantedWeapon.price > currentMoney then
                TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.CantAffordOne)
                return
            else -- Here just check can he really afford all of the guns, if not, modify the "amount" value to max amount they can afford.
                if currentMoney < priceSum then
                    local maxCanAfford = math.floor(currentMoney / WantedWeapon.price)
                    amount = maxCanAfford
                    priceSum = maxCanAfford * WantedWeapon.price -- update the price
                    ReCalcMoney = currentMoney - priceSum

                end
            end
                



            local weaponsList = json.decode(weaponsJSON)

            if not weaponsList or type(weaponsList) ~= 'table' then
                TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.FailedToParseData)
                return
            end

            local weaponFound = false
            for i, weapon in ipairs(weaponsList) do
                if weapon.m == WantedModel then
                    weapon.c = weapon.c + amount
                    weaponFound = true
                    break
                end
            end

            if not weaponFound then
                TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoSuchWeaponInLocker)
                return
            end

            local updatedJSON = json.encode(weaponsList)
            exports.oxmysql:update('UPDATE huzo_societymoney SET ItemsAndGuns = ?, money = ? WHERE job = ?', { updatedJSON, ReCalcMoney, UserJobName }, function(affectedRows)
                if affectedRows > 0 then
                    TriggerClientEvent('huzo:Updateguns', pSRC, updatedJSON)
                    TriggerClientEvent('huzo:Notify', pSRC, 'success', Locales.Bought:format(amount, WantedWeapon.label))
                else
                    TriggerClientEvent('huzo:Notify', pSRC, "error", Locales.DatabaseUpdateFail)
                end
            end)
        else
            TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoSocietyDataFound)
        end
    end)
end)


RegisterNetEvent("huzo:TakeWeapon")
AddEventHandler("huzo:TakeWeapon", function(model, WantedGunLabel)
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    if not zPlayer then
        return
    end
    local UserJobName = zPlayer.getJob().name

    -- Not sure why, but I wanted to add a feature to drop the player if they're trying to get a weapon that's not on the list.
    local IsValidWeapon = false
    for o, mWeapon in ipairs(Config.WeaponsForSocietySlashGang) do
        if mWeapon.model == model then
            IsValidWeapon = true
        end
    end
    if IsValidWeapon ~= true then
        DropPlayer(pSRC, Locales.SuchWeaponDontExist)
    end




    exports.oxmysql:query('SELECT ItemsAndGuns FROM huzo_societymoney WHERE job = ?', {UserJobName}, function(result)
        if result and result[1] and result[1].ItemsAndGuns then
            local weaponsJSON = result[1].ItemsAndGuns
            local weaponsList = json.decode(weaponsJSON)
            if not weaponsList or type(weaponsList) ~= 'table' then
                TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.FailedToParseData)
                return
            end



            for _, weapon in ipairs(weaponsList) do
                if weapon.m == model then
                    weapon.c = weapon.c - 1
                    break
                end
            end



            local updatedJSON = json.encode(weaponsList)


            -- send logs if turned on
            if ServerConfig.UserDiscordLogs then
                if ServerConfig.DiscordWebhook ~= "" then
                    local CallerLicense = nil
                    local CallerName    = zPlayer.name
                    for _, id   in ipairs(GetPlayerIdentifiers(pSRC)) do
                        if string.sub(id, 1, 7) == "license" then
                            CallerLicense = string.sub(id, 7)
                            break
                        end
                    end
                    SendLogs((ServerConfig.TakeMessage):format(CallerName, CallerLicense, WantedGunLabel))
                end
            end
            if Config.EnableBossMonitorCenter then
                local timeTable = os.date("!*t", os.time(os.date("!*t")) + (3 * 60 * 60))
                local formattedTime = string.format("%02d:%02d:%02d", timeTable.hour, timeTable.min, timeTable.sec)
                table.insert(HistoryCache, {
                    JobName = UserJobName,
                    Name = zPlayer.name,
                    Action = 1,
                    Time = formattedTime,
                    TakenGun = WantedGunLabel
                })
            end
            exports.oxmysql:update('UPDATE huzo_societymoney SET ItemsAndGuns = ? WHERE job = ?', { updatedJSON, UserJobName }, function(affectedRows)
                if affectedRows > 0 then
                    TriggerClientEvent("huzo:GiveWeapon", pSRC, model)
                    TriggerClientEvent('huzo:Notify', pSRC, 'success', Locales.TookWeapon:format(WantedGunLabel))
                else
                    TriggerClientEvent('huzo:Notify', pSRC, "error", Locales.DatabaseUpdateFail)
                end
            end)
        else
            TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoSocietyDataFound)
        end
    end)
end)


RegisterNetEvent("huzo:AddMoney")
AddEventHandler("huzo:AddMoney", function(DepositAmount)
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    if not zPlayer then
        return
    end
    local UserJobName  = zPlayer.getJob().name
    local UserJobLabel = zPlayer.getJob().label
    local PlayerMoney  = zPlayer.getAccount(Config.MoneyToBeUsed).money
    if PlayerMoney < DepositAmount then
        TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.TooMuchDefinedMoneyError)
        return
    end
    if not UserJobName then
        TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoJobError)
        DropPlayer(pSRC, Locales.NoJobError)
        return
    end
    
    
    exports.oxmysql:query('SELECT money FROM huzo_societymoney WHERE job = ?', {UserJobName}, function(result)
        if result and result[1] and result[1].money then
            local CurrentJobMoney = tonumber(result[1].money) or 0
            local NewBalance = CurrentJobMoney + DepositAmount
            zPlayer.removeAccountMoney(Config.MoneyToBeUsed, DepositAmount, Locales.UserDeposited:format(tostring(DepositAmount)))
            exports.oxmysql:update('UPDATE huzo_societymoney SET money = ? WHERE job = ?', { NewBalance, UserJobName }, function(affectedRows)
                if affectedRows > 0 then
                    -- send logs if turned on
                    if ServerConfig.UserDiscordLogs then
                        if ServerConfig.DiscordWebhook ~= "" then
                            local CallerLicense = nil
                            local CallerName    = zPlayer.name
                            for _, id in ipairs(GetPlayerIdentifiers(pSRC)) do
                                if string.sub(id, 1, 7) == "license" then
                                    CallerLicense = string.sub(id, 7)
                                    break
                                end
                            end
                            SendLogs((ServerConfig.DepositMessage):format(CallerName, CallerLicense, DepositAmount, UserJobLabel))
                        end
                    end
                    if Config.EnableBossMonitorCenter then
                        local timeTable = os.date("!*t", os.time(os.date("!*t")) + (3 * 60 * 60))
                        local formattedTime = string.format("%02d:%02d:%02d", timeTable.hour, timeTable.min, timeTable.sec)
                        table.insert(HistoryCache, {
                            JobName = UserJobName,
                            Name = zPlayer.name,
                            Action = 3,
                            Time = formattedTime,
                            Deposited = DepositAmount
                        })
                    end
                    TriggerClientEvent('huzo:Notify', pSRC, 'success', Locales.YouDeposited:format(tostring(DepositAmount)))
                else
                    TriggerClientEvent('huzo:Notify', pSRC, "error", Locales.DatabaseUpdateFail)
                end
            end)
        else
            TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoSocietyDataFound)
        end
    end)
end)



RegisterNetEvent("JobMenu:hire")
AddEventHandler("JobMenu:hire", function (pData, jobname)
    local pSRC = source
    local xPlayer = ESX.GetPlayerFromId(pSRC)
    local GiverJob = xPlayer.job
    local targetPlayer = ESX.GetPlayerFromId(pData.serverID)

    -- Check if boss.
    if GiverJob.grade_name ~= "boss" then
        TriggerClientEvent('huzo:Notify', pSRC, 'error', 'Can\'t assign people to for the job, not boss!')
        return
    end


    -- Ask grades from db
    -- This gets all grades, but I didn't finish this, because I didn't find a fitting way to ask the boss what grade he wants the employee to have, sorry.
    -- exports.oxmysql:query('SELECT grade, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC', {GiverJob.name}, function(result)
    --     if result and #result > 0 then
    --         for _, row in ipairs(result) do
    --             local grade = row.grade
    --             local label = row.label
    --         end
    --     else
    --         TriggerClientEvent('huzo:Notify', pSRC, 'error', 'No job grades found for this job.')
    --     end
    -- end)


    -- setjob
    if targetPlayer then
        targetPlayer.setJob(jobname, Config.DefaultGradeToSetEmployee)
    end
end)



RegisterNetEvent("huzo:FreezeFunds")
AddEventHandler("huzo:FreezeFunds", function(DepositAmount)
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    if not zPlayer then
        return
    end
    local UserJobName  = zPlayer.getJob().name
    local IsBoss       = (zPlayer.getJob().grade_name == Config.BossGradeName)
    if not IsBoss then
        TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.FreezeFundsPermissionError)
        return
    end
    
    
    exports.oxmysql:query('SELECT isFrozen FROM huzo_societymoney WHERE job = ?', {UserJobName}, function(result)
        if result and result[1] and result[1].isFrozen then
            local Frozen = tonumber(result[1].isFrozen) == 1 and 0 or 1

            exports.oxmysql:update('UPDATE huzo_societymoney SET isFrozen = ? WHERE job = ?', { Frozen, UserJobName }, function(affectedRows)
                if affectedRows > 0 then
                    -- send logs if turned on
                    if ServerConfig.UserDiscordLogs then
                        if ServerConfig.DiscordWebhook ~= "" then
                            local CallerLicense = nil
                            local CallerName    = zPlayer.name
                            for _, id in ipairs(GetPlayerIdentifiers(pSRC)) do
                                if string.sub(id, 1, 7) == "license" then
                                    CallerLicense = string.sub(id, 7)
                                    break
                                end
                            end
                            SendLogs((ServerConfig.FrozeMessage):format(CallerName, CallerLicense, UserJobName))
                        end
                    end
                    if Config.EnableBossMonitorCenter then
                        local timeTable = os.date("!*t", os.time(os.date("!*t")) + (3 * 60 * 60))
                        local formattedTime = string.format("%02d:%02d:%02d", timeTable.hour, timeTable.min, timeTable.sec)
                        table.insert(HistoryCache, {
                            JobName = UserJobName,
                            Name = zPlayer.name,
                            Action = 2,
                            Time = formattedTime,
                            FreezeType = Frozen,
                        })
                    end
                    TriggerClientEvent('huzo:Notify', pSRC, 'success', Locales.FrozenSociety)
                else
                    TriggerClientEvent('huzo:Notify', pSRC, "error", Locales.DatabaseUpdateFail)
                end
            end)
        else
            TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoSocietyDataFound)
        end
    end)
end)


function IsOnline(PlayersList, License, Job)
    for _, player in ipairs(PlayersList) do
        local TargetPlayer = ESX.GetPlayerFromId(player)
        if TargetPlayer and TargetPlayer.getJob().name == Job then
            local identifiers = GetPlayerIdentifiers(player)
            for _, id in ipairs(identifiers) do
                if string.find(id, License) ~= nil then
                    return true
                end
            end
        end
    end
    return false
end

RegisterNetEvent("huzo:GetEmployeeList")
AddEventHandler("huzo:GetEmployeeList", function()
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    if not zPlayer then
        return
    end


    local UserJobName  = zPlayer.getJob().name
    local IsBoss       = (zPlayer.getJob().grade_name == Config.BossGradeName)
    if not IsBoss then
        TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoManagerPermissions)
        return
    end


    local employees = {}
    exports.oxmysql:query('SELECT firstname, lastname, dateofbirth, job_grade, identifier, sex FROM users WHERE job = ?', {UserJobName}, function(result)
        if result and #result ~= 0 then
            local OnlinePlayers = GetPlayers()
            for i, _ in ipairs(result) do
                print(result[i].firstname .. " " .. result[i].lastname)
                local ID = result[i].identifier
                if string.find(ID, 'char:') ~= nil then
                    ID = string.sub(ID, 6)
                end
                if string.find(ID, 'char') ~= nil then
                    ID = string.sub(ID, 7)
                end
                
                table.insert(employees, {
                    CharacterName  = result[i].firstname .. " " .. result[i].lastname,
                    OnlineStatus   = IsOnline(OnlinePlayers, ID, UserJobName),
                    DateOfBirth    = result[i].dateofbirth,
                    Identifier     = ID,
                    CurrentGrade   = result[i].job_grade,
                    FullIdentifier = result[i].identifier,
                    Gender         = result[i].sex == "m" and Locales.GenderM or Locales.GenderF,
                })
            end
        else
            TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoSocietyDataFound)
        end
        if #employees > 0 then
            TriggerClientEvent("huzo:UpdateEmployeeList", pSRC, employees)
        end
    end)
end)




RegisterNetEvent("huzo:FetchGradesForJob")
AddEventHandler("huzo:FetchGradesForJob", function()
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    if not zPlayer then
        return
    end


    local UserJobName  = zPlayer.getJob().name
    local IsBoss       = (zPlayer.getJob().grade_name == Config.BossGradeName)
    if not IsBoss then
        TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoManagerPermissions)
        return
    end


    local Ranks = {}
    exports.oxmysql:query('SELECT grade, label FROM job_grades WHERE job_name = ?', {UserJobName}, function(result)
        if result and #result ~= 0 then
            for i, _ in ipairs(result) do
                table.insert(Ranks, {
                    Grade = result[i].grade,
                    Label = result[i].label,
                })
            end
        else
            TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoSocietyDataFound)
        end
        -- send the grades back to the client
        TriggerClientEvent('huzo:UpdateGradesCache', pSRC, Ranks)
    end)
end)


RegisterNetEvent("huzo:ChangeEmployeeGrade")
AddEventHandler("huzo:ChangeEmployeeGrade", function(GRADE, ID, LABEL, NAME, isPromotion)
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    if not zPlayer then
        return
    end
    local UserJobName  = zPlayer.getJob().name
    local IsBoss       = (zPlayer.getJob().grade_name == Config.BossGradeName)
    if not IsBoss then
        TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoManagerPermissions)
        return
    end


    exports.oxmysql:update('UPDATE users SET job_grade = ? WHERE job = ? AND identifier = ?;', { GRADE, UserJobName, ID }, function(affectrows)
        if affectrows > 0 then
            TriggerClientEvent('huzo:Notify', pSRC, 'success', (isPromotion == true and (Locales.Promotion):format(NAME, LABEL)) or (Locales.Demotion):format(NAME, LABEL))
        else
            TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoSocietyDataFound)
        end
    end)
end)


RegisterNetEvent("huzo:KickEmployee")
AddEventHandler("huzo:KickEmployee", function(EmployeeID, EmployeeName)
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    if not zPlayer then
        return
    end
    local UserJobName  = zPlayer.getJob().name
    local IsBoss       = (zPlayer.getJob().grade_name == Config.BossGradeName)
    if not IsBoss then
        TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoManagerPermissions)
        return
    end


    exports.oxmysql:update('UPDATE users SET job = ?, job_grade = ? WHERE job = ? AND identifier = ?;', { Config.UnemployedJobName, Config.UnemployedGrade, UserJobName, EmployeeID }, function(affectrows)
        if affectrows > 0 then
            TriggerClientEvent('huzo:Notify', pSRC, 'success', (Locales.EmployeeKickedNotification):format(EmployeeName))
        else
            TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoSocietyDataFound)
        end
    end)
end)

RegisterNetEvent("huzo:GetLatestHistory")
AddEventHandler("huzo:GetLatestHistory", function()
    local pSRC = source
    local zPlayer = ESX.GetPlayerFromId(pSRC)
    if not zPlayer then
        return
    end
    local UserJobName  = zPlayer.getJob().name
    local IsBoss       = (zPlayer.getJob().grade_name == Config.BossGradeName)
    if not IsBoss then
        TriggerClientEvent('huzo:Notify', pSRC, 'error', Locales.NoManagerPermissions)
        return
    end

    local ReturningList = {}
    if #HistoryCache ~= 0 then
        for _, i in ipairs(HistoryCache) do
            if i.JobName == UserJobName then
                local record =
                    (i.Action == 1 and { Action = i.Action, Name = i.Name, Time = i.Time, TakenGun = i.TakenGun }) or
                    (i.Action == 2 and { Action = i.Action, Name = i.Name, Time = i.Time }) or
                    (i.Action == 3 and { Action = i.Action, Name = i.Name, Time = i.Time, Deposited = i.Deposited })
                table.insert(ReturningList, record)
            end
        end
    end
    TriggerClientEvent('huzo:SaveActionHistory', pSRC, ReturningList)
end)