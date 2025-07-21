-- Helper functions, event handlers and functions to manage the buying and data processing.
RegisterNetEvent("huzo:Updateguns")
AddEventHandler("huzo:Updateguns", function (gunslist)
    local NormalFormat = json.decode(gunslist)
    CurrentJobLockerGuns = NormalFormat
end)

function AskHowMany(label, index, maxavailable)
    local input = lib.inputDialog('Buy ' .. label, {
        {
            type = 'slider',
            label = 'How many?',
            description = 'Choose how many you want to buy into the locker.',
            icon = 'hashtag',
            required = true,
            min = 1,
            max = maxavailable
        }
    })

    if input and input[1] then
        return tonumber(input[1])
    else
        return nil
    end
end

function AskHowMany2(MaxMoneyCount)
    local input = lib.inputDialog('Deposit', {
        {
            type = 'number',
            label = 'Deposit amount:',
            description = 'The most you can deposit, is ' .. MaxMoneyCount .. Config.Currency .. ". This action is *irreversible*!",
            icon = 'hashtag',
            required = true,
            min = 1,
            max = MaxMoneyCount
        }
    })

    if input and input[1] then
        return tonumber(input[1])
    else
        return nil
    end
end


function WaitForGuns(timeoutMs)
    timeoutMs = timeoutMs or 3000
    local waited = 0
    while #CurrentJobLockerGuns == 0 and waited < timeoutMs do
        Wait(10)
        waited = waited + 10
    end
    if #CurrentJobLockerGuns == 0 then
        print("Timeout waiting for guns data, good luck on debugging g")
        return false
    end
    return true
end

function WaitForGunsRefreshing(SocietyCurrentMoneyTemp)
    local timeoutMs = 3000
    local waited = 0

    print("[DEBUG] Waiting for CurrentJobLockerGuns to update...")

    -- Wait for the CurrentJobLockerGuns table to update
    while next(CurrentJobLockerGuns) == nil and waited < timeoutMs do
        Wait(1)
        waited = waited + 1
    end

    print("[DEBUG] Waited " .. waited .. "ms for guns update.")
    if CurrentJobLockerGunsOriginal == CurrentJobLockerGuns then
        print("[ERROR] CurrentJobLockerGuns has not changed.")
        return false
    else
        print("[DEBUG] CurrentJobLockerGuns successfully updated.")
    end

    -- Reset timer for the money update
    waited = 0
    print("[DEBUG] Triggering huzo:GetSocietyMoney...")

    TriggerServerEvent("huzo:GetSocietyMoney")

    while SocietyCurrentMoneyTemp == SocietyCurrentMoney and waited < timeoutMs do
        Wait(1)
        waited = waited + 1
    end

    print("[DEBUG] Waited " .. waited .. "ms for society money update.")
    if SocietyCurrentMoneyTemp == SocietyCurrentMoney then
        print("[ERROR] SocietyCurrentMoney has not changed.")
        return false
    else
        print("[DEBUG] SocietyCurrentMoney successfully updated.")
        return true
    end
end




