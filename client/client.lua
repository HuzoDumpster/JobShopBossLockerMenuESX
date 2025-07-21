---@diagnostic disable: undefined-global, undefined-field, lowercase-global

-- Get the basic stuff, esx object handle and the info of the player and check if theyre the boss of the group/job/gang.
ESX = nil
pDT = nil
IsCurrentPlayerTheBoss = false
CreateThread(function()
    while not ESX do
        Wait(0)
        ESX = exports['es_extended']:getSharedObject()
    end

    while not ESX.GetPlayerData().job do
        Wait(100)
    end
    
    pDT = ESX.GetPlayerData()
    IsCurrentPlayerTheBoss = (pDT.job.grade_name == Config.BossGradeName)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()    
    pDT = ESX.GetPlayerData()
    IsCurrentPlayerTheBoss = (pDT.job.grade_name == Config.BossGradeName)
end)

-- Just variables
SocietyCurrentMoney  = 0
CurrentJobLockerGuns = {}
SocietyMoneyFrozen   = false
GradesCache          = {}
HistoryCache         = nil

-- Just for testing I created here a thread to get input
CreateThread(function()
    while true do
        Wait(1)
        if IsControlJustPressed(0, 74) then
            pDT = ESX.GetPlayerData()
            IsCurrentPlayerTheBoss = (pDT.job.grade_name == Config.BossGradeName)
            ShopBossStashMenu()
    	end
    end
end)


-- Client events to store the server callback data, show notifications etc.
RegisterNetEvent('huzo:SaveCurrentMoney')
AddEventHandler('huzo:SaveCurrentMoney', function(money, isFrozen)
    SocietyCurrentMoney = money
    if isFrozen == 1 then
        SocietyMoneyFrozen = true
    else
        SocietyMoneyFrozen = false
    end
end)

RegisterNetEvent('huzo:SaveActionHistory')
AddEventHandler('huzo:SaveActionHistory', function(History)
    HistoryCache = History
end)

function NotifyClient(message, type)
    lib.notify({
        description = message,
        type = type or 'success',
        duration = 3000,
        position = Config.DefaultPositionMenu,
        icon = type == 'error' and 'ban' or 'check',
        iconColor = type == 'error' and '#C53030' or '#ffa500',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = { color = '#909296' }
        }
    })
end


RegisterNetEvent('huzo:Notify')
AddEventHandler('huzo:Notify', function(type, msg)
    NotifyClient(msg, type)
end)


RegisterNetEvent('huzo:GiveWeapon')
AddEventHandler('huzo:GiveWeapon', function(weaponmodel)
    GiveWeaponToPed(PlayerPedId(), GetHashKey(weaponmodel), Config.DefaultAmmo, false, false)
end)


RegisterNetEvent('esx:setJob', function(job)
    pDT.job = job
    IsCurrentPlayerTheBoss = (job.grade_name == Config.BossGradeName)
end)

RegisterNetEvent('huzo:UpdateGradesCache')
AddEventHandler('huzo:UpdateGradesCache', function(data)
    GradesCache = data
end)


-- please dont touch, nor ask
function ShopMenuOptions()
    local ShopMenuOptionss = {
        {
            title = Config.IsGangMenu and (Locales.DirtyMoney .. ": " .. tostring(SocietyCurrentMoney) .. Config.Currency) or (Locales.CleanMoney .. ": " .. tostring(SocietyCurrentMoney) .. Config.Currency),
            icon = "dollar-sign",
            readOnly = true,
            iconAnimation = "spin",
        },
        {
            title = Config.IsGangMenu and Locales.DepositDirtyMoney or Locales.DepositCleanMoney,
            icon = "plus",
            iconAnimation = "spin",
            onSelect = function()
                pDT = ESX.GetPlayerData()
                local UsersMoney
                for _, ac in ipairs(pDT.accounts) do
                    if ac.name == Config.MoneyToBeUsed then
                        UsersMoney = ac.money
                        break
                    end
                end
                if not UsersMoney then
                    NotifyClient(Locales.InvalidMoneyType:format(Config.MoneyToBeUsed), "error")
                    return
                end
                local DepositAmount = AskHowMany2(UsersMoney)
                TriggerServerEvent("huzo:AddMoney", DepositAmount)
            end,
        },
    }

    -- if the job's shop account is frozen, don't even bother rendering the buying options
    if SocietyMoneyFrozen then
        table.insert(ShopMenuOptionss, {
            title = Locales.CantBuyCuzFrozenTitle,
            description = Locales.CantBuyCuzFrozen,
            icon = "xmark",
            readOnly = true,
        })
        return ShopMenuOptionss
    end

    local GunsSuccess = WaitForGuns(3000)

    if not GunsSuccess or #CurrentJobLockerGuns == 0 then
        print("[ERROR] ShopMenuOptions: Failed to load gun data or it returned empty.")
        return {}
    end

    for i, weaponInfo in ipairs(Config.WeaponsForSocietySlashGang) do
        local countOfGuns = CurrentJobLockerGuns[i] and CurrentJobLockerGuns[i].c or 0
        local maxavailable = weaponInfo.maxInLocker - countOfGuns
        table.insert(ShopMenuOptionss, {
            title = countOfGuns .. "/" .. weaponInfo.maxInLocker .. " | " .. weaponInfo.label,
            description = Locales.Price .. ": " .. weaponInfo.price .. Config.Currency,
            icon = "gun",
            onSelect = function()
                local amount
                if countOfGuns == weaponInfo.maxInLocker then
                    NotifyClient(Locales.LockerFullOfThisGun, "error")
                    lib.showContext("ShopMenu")
                else
                    amount = AskHowMany(weaponInfo.label, i, maxavailable)
                    CurrentJobLockerGuns = {} -- Clear the list. Server will revalue it once it's done. WaitForGunsRefreshing() will wait max 3 sec for the value change
                    local SocietyCurrentMoneyTemp = SocietyCurrentMoney -- Almost same thing, but this is **passed** to the WaitForGunsRefreshing()
                    TriggerServerEvent("huzo:BuyWeapon", amount, i)
                    WaitForGunsRefreshing(SocietyCurrentMoneyTemp)
                    local NewOptions = ShopMenuOptions()
                    lib.registerContext({
                        id = 'ShopMenu',
                        title = pDT.job.label .. " | " .. Locales.MainShopTitle,
                        position = Config.DefaultPositionMenu,
                        options = NewOptions,
                    })
                    lib.showContext("ShopMenu")
                end
            end,
        })
    end

    return ShopMenuOptionss
end



function LockerMenuOptions()
    
    local LockerMenuOptionss = {}

    local GunsSuccess = WaitForGuns(3000)

    if not GunsSuccess or #CurrentJobLockerGuns == 0 then
        return {}
    end

    for i, weaponInfo in ipairs(Config.WeaponsForSocietySlashGang) do
        local GunsAvailable = CurrentJobLockerGuns[i] and CurrentJobLockerGuns[i].c or 0
        local MaxAvailable  = weaponInfo.maxInLocker
        if GunsAvailable == 0  then
            goto continue
        end
        -- print(("[DEBUG] Adding weapon to locker menu: %s | count: %d / %d"):format(weaponInfo.label, GunsAvailable, MaxAvailable))
        table.insert(LockerMenuOptionss, {
            title = GunsAvailable .. "/" .. MaxAvailable .. " | " .. weaponInfo.label,
            description = Locales.LockerSubmenuDescription,
            icon = "person-rifle",
            onSelect = function()
                TriggerServerEvent("huzo:TakeWeapon", weaponInfo.model, weaponInfo.label)
            end,
        })
        ::continue::
    end
    if #LockerMenuOptionss == 0 then
        table.insert(LockerMenuOptionss, {
            title = Config.IsGangMenu and Locales.NoWeaponsGang or Locales.NoWeaponsSociety,
            icon = "xmark",
            readOnly = true,
            iconAnimation = "spin",
        })
    end
    return LockerMenuOptionss
end



function BossMenuOptions()
    local BossMenuOptionss = {
        {
            title = Locales.ManageEmployees,
            icon = "users-between-lines",
            iconAnimation = "spin",
            description = Locales.ManageEmployeesDescription,
            onSelect = function ()
                lib.hideContext(false)
                ManagerMenu()
            end
        },
        {
            title = Locales.HireNew,
            icon = "user-plus",
            iconAnimation = "spin",
            description = Locales.HireNewDescription,
            onSelect = function ()
                exports["SelectionScript"]:StartSelection("JobMenu:hire", pDT.job.name)
                TriggerServerEvent("huzo:GetEmployeeList")
            end,
        },
        {
            title = SocietyMoneyFrozen and Locales.FreezeFundsON or Locales.FreezeFundsOFF,
            icon = "money-bills",
            iconAnimation = "spin",
            description = Locales.FreezeFundsDescription,
            onSelect = function ()
                TriggerServerEvent("huzo:FreezeFunds")
                SocietyMoneyFrozen = not SocietyMoneyFrozen
                lib.registerContext({
                    id = 'BossMenu',
                    title = pDT.job.label .. " | " .. Locales.BossMenuTitle,
                    position = Config.DefaultPositionMenu,
                    options = BossMenuOptions(),
                })
                lib.showContext("BossMenu")
            end
        },
    }
    if Config.EnableBossMonitorCenter then
        TriggerServerEvent("huzo:GetLatestHistory")
        local alertData = ""
        local timewaited = 0
        while HistoryCache == nil and timewaited < 3000 do
            Wait(10)
            timewaited = timewaited + 10
        end
        table.insert(BossMenuOptionss, {
            title = Locales.MonitorCenter,
            icon = "binoculars",
            iconAnimation = "spin",
            description = Locales.MonitorCenterDescription,
            onSelect = function()
                if #HistoryCache ~= 0 then
                    for _, historyItem in ipairs(HistoryCache) do
                        alertData = alertData .. "\n" .. (
                            ( historyItem.Action == 1 and (Locales.MonitorTakeGun):format(historyItem.Time, historyItem.Name, historyItem.TakenGun) ) or
                            ( historyItem.Action == 2 and (historyItem.FreezeType == 1 and Locales.MonitorFundFreeze or Locales.MonitorFundFreeze2):format(historyItem.Time, historyItem.Name) ) or
                            ( historyItem.Action == 3 and (Locales.MonitorDeposited):format(historyItem.Time, historyItem.Name, historyItem.Deposited) )
                        )
                    end
                    lib.alertDialog({
                        header = Locales.ActionTitle,
                        content = alertData,
                        cancel = false,
                        labels = {
                            confirm = Locales.Back
                        }
                    })
                else
                    lib.alertDialog({
                        header = Locales.ActionTitle,
                        content = '\n' .. Locales.NoActionData,
                        cancel = false,
                        labels = {
                            confirm = Locales.Back
                        }
                    })
                end

                -- Rebuild the boss menu to get updated value
                lib.registerContext({
                    id = 'BossMenu',
                    title = pDT.job.label .. " | " .. Locales.BossMenuTitle,
                    position = Config.DefaultPositionMenu,
                    options = BossMenuOptions(),
                })
                lib.showContext("BossMenu")
            end,
        })
    end

    return BossMenuOptionss
end


-- Ox Menu for employee management
local EmployeesFetched = false
local EmployeeList = {}
RegisterNetEvent("huzo:UpdateEmployeeList")
AddEventHandler("huzo:UpdateEmployeeList", function(elist)
    EmployeeList = elist
    EmployeesFetched = true
end)
function ManagerMenu()
    TriggerServerEvent("huzo:GetEmployeeList")
    local MaxTime = 3000
    while MaxTime > 0 and EmployeesFetched == false do
        Wait(10)
        MaxTime = MaxTime - 10
    end
    EmployeesFetched = false



    -- Build options lists
    local EmpolyeeOptionsData = {}
    for _, EmployeeData in ipairs(EmployeeList) do
        table.insert(EmpolyeeOptionsData, {
            label = EmployeeData.CharacterName,
            description = Locales.OpenPlayerManaging,
            icon = "user-tie",
            iconColor = EmployeeData.OnlineStatus and Locales.OnlineColor or Locales.OfflineColor,
        })
    end
    lib.registerMenu({
        id = 'EmployeeMenuID',
        title = Locales.ManagementTitle,
        position = 'top-left',
        options = EmpolyeeOptionsData,
        onClose = function()
            lib.showContext('ShopBossStashMenu')
        end,
        }, function(selected, scrollIndex, args)
        local ActionOptionsData = {
            {
                label = Locales.EmployeeName .. ": " .. EmployeeList[selected].CharacterName,
                icon = "id-card",
                iconColor = "#ffffff",
                disableInput = true,
                close = false,
            },
            {
                label = Locales.OnlineStatus .. ": " .. (EmployeeList[selected].OnlineStatus and Locales.Online or Locales.Offline),
                icon = "circle-notch",
                iconColor = "#ffffff",
                disableInput = true,
                close = false,
            },
            {
                label = Locales.EmployeeAge .. ": " .. EmployeeList[selected].DateOfBirth,
                icon = "cake-candles",
                iconColor = "#ffffff",
                disableInput = true,
                close = false,
            },
        }

        if Config.EnableSalaryChangeOption then
            table.insert(ActionOptionsData, {
                label = Locales.ChangeSalaryTitle,
                icon  = "money-bill-wave",
                iconColor = "#fffb0a",
            })
        end

        table.insert(ActionOptionsData, {
            label = Locales.PromoteTitle,
            icon  = "arrows-up-to-line",
            iconColor = "#77ff00",
        })

        table.insert(ActionOptionsData, {
            label = Locales.DemoteTitle,
            icon  = "arrows-down-to-line",
            iconColor = "#ff0051",
        })

        table.insert(ActionOptionsData, {
            label = Locales.KickTitle,
            icon  = "user-minus",
            iconColor = "#ff1100",
        })

        lib.registerMenu({
            id = 'ActionsMenu',
            title = Locales.ManagePlayerTitle .. ": " .. EmployeeList[selected].CharacterName,
            position = 'top-left',
            options = ActionOptionsData,
            onClose = function ()
                lib.showMenu('EmployeeMenuID')
            end
        }, function(SelectedAction)
            local IndexRaise = 0
            if Config.EnableSalaryChangeOption then
                IndexRaise = 1
                if SelectedAction == 4 then
                    -- Raise employee salary
                    local SalaryInput = lib.inputDialog(Locales.InputDialogTitle, {
                        {type = 'slider', required = true, label = Locales.InputDialogDesc .. ' ( 0' .. Config.Currency .. ' - ' .. Config.MaxSalaryPossible .. ' )', min = 1, max = Config.MaxSalaryPossible, step = 5},
                    })
                    Config.SalaryChangeFunction(SalaryInput, EmployeeList[selected].FullIdentifier)
                end
            end
            if SelectedAction == 4 + IndexRaise then
                -- Promote. Shit way I can't lie, but here it is.
                if #GradesCache == 0 then

                    TriggerServerEvent("huzo:FetchGradesForJob")
                    local waited = 0
                    while #GradesCache == 0 and waited < 3000 do
                        Wait(20)
                        waited = waited + 20
                    end
                end
                table.sort(GradesCache, function(a, b)
                    return a.Grade < b.Grade
                end)



                -- UI
                local Grades = {}
                for _, item in ipairs(GradesCache) do
                    if tonumber(item.Grade) > tonumber(EmployeeList[selected].CurrentGrade) then
                        table.insert(Grades, item.Label)
                    end
                end
                local Options = {}
                if #Grades == 0 then
                    table.insert(Options, {
                        label = Locales.AlreadyHighestGrade, description = Locales.ChangeUnavailable, close = false
                    })
                else
                    table.insert(Options, {
                        label = Locales.PromotionInputTitle, values = Grades, defaultIndex = 1, description = Locales.SelectPromoteGrade
                    })
                end
                lib.registerMenu({
                    id = 'Promoter',
                    title = Locales.PromotionMenuTitle,
                    position = 'top-left',
                    onClose = function()
                        lib.showMenu('EmployeeMenuID')
                    end,
                    options = Options
                }, function(selected2, scrollIndex, args)
                    for x, obj in ipairs(GradesCache) do
                        if obj.Label == Grades[scrollIndex] then
                            TriggerServerEvent("huzo:ChangeEmployeeGrade", obj.Grade, EmployeeList[selected].FullIdentifier, obj.Label, EmployeeList[selected].CharacterName, true)
                            lib.hideMenu(false)
                            lib.showContext("BossMenu")
                        end
                    end
                end)
                lib.showMenu('Promoter')
            elseif SelectedAction == 5 + IndexRaise then
                -- Demote. Again, same way, pretty shit, feel free to modify.
                if #GradesCache == 0 then
                    TriggerServerEvent("huzo:FetchGradesForJob")
                    local waited = 0
                    while #GradesCache == 0 and waited < 3000 do
                        Wait(20)
                        waited = waited + 20
                    end
                end
                table.sort(GradesCache, function(a, b)
                    return a.Grade < b.Grade
                end)



                -- UI
                local Grades = {}
                for _, item in ipairs(GradesCache) do
                    if tonumber(item.Grade) < tonumber(EmployeeList[selected].CurrentGrade) then
                        table.insert(Grades, item.Label)
                    end
                end
                local Options = {}
                if #Grades == 0 then
                    table.insert(Options, {
                        label = Locales.AlreadyLowestGrade, description = Locales.ChangeUnavailable, close = false
                    })
                else
                    table.insert(Options, {
                        label = Locales.DemotionInputTitle, values = Grades, defaultIndex = 1, description = Locales.SelectDemoteGrade
                    })
                end
                lib.registerMenu({
                    id = 'Demoter',
                    title = Locales.DemotionMenuTitle,
                    position = 'top-left',
                    onClose = function()
                        lib.showMenu('EmployeeMenuID')
                    end,
                    options = Options
                }, function(selected2, scrollIndex, args)
                    for x, obj in ipairs(GradesCache) do
                        if obj.Label == Grades[scrollIndex] then
                            TriggerServerEvent("huzo:ChangeEmployeeGrade", obj.Grade, EmployeeList[selected].FullIdentifier, obj.Label, EmployeeList[selected].CharacterName, false)
                            lib.hideMenu(false)
                            lib.showContext("BossMenu")
                        end
                    end
                end)
                lib.showMenu('Demoter')
            elseif SelectedAction == 6 + IndexRaise then
                -- Kick. Probably shit way again, but whatever.
                TriggerServerEvent("huzo:KickEmployee", EmployeeList[selected].FullIdentifier, EmployeeList[selected].CharacterName)
                lib.showContext("BossMenu")
            end
        end)
        lib.showMenu('ActionsMenu')
    end)
    lib.showMenu('EmployeeMenuID')
end



-- the main context menu.
function ShopBossStashMenu()
    if pDT.job == "unemployed" then
        return
    end
    -- just a quick update on the society money + weapon list, incase it's yet to be set
	if SocietyCurrentMoney == 0 or #CurrentJobLockerGuns then
    	TriggerServerEvent("huzo:GetSocietyMoney")
        TriggerServerEvent("huzo:GetWeapons")
        Wait(500)
    end
    Wait(300)
    local optionsdata  = ShopMenuOptions()
    local optionsdata2 = LockerMenuOptions()
    local optionsdata3 = BossMenuOptions()
    local InitialMenuOptions = {
        {
            title = Locales.InitialBossMenuTitle,
            icon = "crown",
            iconAnimation = "spin",
            menu = "BossMenu",
            disabled = not IsCurrentPlayerTheBoss,
            description = IsCurrentPlayerTheBoss and Locales.InitialBossMenuDescription or Locales.InitialBossMenuDescriptionDisabled,
        },
        {
            title = Locales.InitialShopTitle,
            icon = "person-rifle",
            iconAnimation = "spin",
            menu = "ShopMenu",
            description = Locales.InitialShopDescription,
            onSelect = function()
                TriggerServerEvent("huzo:GetSocietyMoney")
                lib.showContext("ShopMenu")
                CreateThread(function()
                    local oldValue = SocietyCurrentMoney
                    while true do
                        if lib.getOpenContextMenu() ~= "ShopMenu" then
                            break
                        end
                        TriggerServerEvent("huzo:GetSocietyMoney")
                        Wait(1000)
                        if SocietyCurrentMoney ~= oldValue then
                            oldValue = SocietyCurrentMoney
                            lib.registerContext({
                                id = 'ShopMenu',
                                title = pDT.job.label .. " | " .. Locales.MainShopTitle,
                                position = Config.DefaultPositionMenu,
                                options = optionsdata
                            })
                            lib.showContext("ShopMenu")
                        end
                    end
                end)
            end,
        },
        {
            title = Locales.MainWeaponLockerTitle,
            icon = "box-archive",
            iconAnimation = "spin",
            menu = "LockerMenu",
            description = Locales.MainWeaponLockerDescription,
            onSelect = function()
                TriggerServerEvent("huzo:GetSocietyMoney")
                lib.showContext("LockerMenu")
                CreateThread(function()
                    local oldValue = SocietyCurrentMoney
                    while true do
                        if lib.getOpenContextMenu() ~= "LockerMenu" then
                            break
                        end
                        TriggerServerEvent("huzo:GetSocietyMoney")
                        Wait(1000)
                        if SocietyCurrentMoney ~= oldValue then
                            oldValue = SocietyCurrentMoney
                            lib.registerContext({
                                id = 'LockerMenu',
                                title = pDT.job.label .. " | " .. Locales.WeaponLockerTitle,
                                position = Config.DefaultPositionMenu,
                                options = optionsdata2
                            })
                            lib.showContext("LockerMenu")
                        end
                    end
                end)
            end,
        },
    }






    -- Register all of the context UIs. Though, not sure how I'll integrate oxmenu to this yet.
    lib.registerContext({
        id = 'ShopBossStashMenu',
        title = pDT.job.label .. " | " .. Locales.MainMenuTitle,
        position = Config.DefaultPositionMenu,
        options = InitialMenuOptions,
    })
    lib.registerContext({
        id = 'BossMenu',
        title = pDT.job.label .. " | " .. Locales.BossMenuTitle,
        position = Config.DefaultPositionMenu,
        options = optionsdata3,
    })
    lib.registerContext({
        id = 'ShopMenu',
        title = pDT.job.label .. " | " .. Locales.ShopMenuTitle,
        position = Config.DefaultPositionMenu,
        options = optionsdata,
    })
    lib.registerContext({
        id = 'LockerMenu',
        title = pDT.job.label .. " | " .. Locales.WeaponLockerTitle,
        position = Config.DefaultPositionMenu,
        options = optionsdata2,
    })

    lib.showContext('ShopBossStashMenu')
end
