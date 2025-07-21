Config = {}
Locales = {}

Config.IsGangMenu                 = true -- this is just to choose if the term/value "dirty money" shall be used, rather than just "society money."
Config.Currency                   = "€" -- obvious
Config.DefaultAmmo                = 200 -- how much should a gun have ammo when givem
Config.MoneyToBeUsed              = "black_money" --obvious
Config.BossGradeName              = "boss" -- obvious
Config.DefaultGradeToSetEmployee  = 1 -- The default grade integer which the hired person will be set to. Bosses can change it later on.
Config.DefaultPositionMenu        = 'top-right' -- Where do you want the menu to appear
Config.UnemployedJobName          = 'unemployed'
Config.EnableBossMonitorCenter    = true -- Choose if the boss has an option to view latest activity since last server restart. Old data is in Discord, if logging is true, but on the server-side I made a feature to store data inside a table for bosses to view. It resets on server restart.
Config.UnemployedGrade            = 0
Config.WeaponsForSocietySlashGang = { -- https://docs.fivem.net/docs/game-references/weapon-models/
	-- shotgun list
    { model = "WEAPON_PUMPSHOTGUN",        label = "Pump Shotgun",           maxInLocker = 8,  price = 3000 },
    { model = "WEAPON_PUMPSHOTGUN_MK2",    label = "Pump Shotgun Mk II",     maxInLocker = 5,  price = 5000 },
    { model = "WEAPON_SAWNOFFSHOTGUN",     label = "Sawed-Off Shotgun",      maxInLocker = 10, price = 2500 },
    { model = "WEAPON_BULLPUPSHOTGUN",     label = "Bullpup Shotgun",        maxInLocker = 6,  price = 4500 },
    { model = "WEAPON_DBSHOTGUN",          label = "Double Barrel Shotgun",  maxInLocker = 6,  price = 3500 },
    
    -- sniper list
    { model = "WEAPON_SNIPERRIFLE",        label = "Sniper Rifle",           maxInLocker = 2,  price = 10000 },
    { model = "WEAPON_MARKSMANRIFLE_MK2",  label = "Marksman Rifle Mk II",   maxInLocker = 3,  price = 8000 },
    { model = "WEAPON_MUSKET",             label = "Musket",                 maxInLocker = 5,  price = 1500 },
    { model = "WEAPON_MARKSMANRIFLE",      label = "Marksman Rifle",         maxInLocker = 4,  price = 6000 },
    
    -- pistols
    { model = "WEAPON_VINTAGEPISTOL",      label = "Vintage Pistol",         maxInLocker = 50, price = 1000 },
    { model = "WEAPON_APPISTOL",           label = "AP Pistol",              maxInLocker = 20, price = 3500 },
    { model = "WEAPON_DOUBLEACTION",       label = "Double-Action Revolver", maxInLocker = 10, price = 3000 },
}




-- Here you can choose if in the managament menu there is a option to change employee's salary/payout.
-- BUT DO NOTE; You HAVE to write the logic yourself! Below is just the function to be called!
Config.EnableSalaryChangeOption   = false
Config.MaxSalaryPossible          = 1000 -- What shall be the max amount of money a boss can add as one's salary?
Config.SalaryChangeFunction = function(SalaryToChangeTo, ID)
    -- WRITE HERE YOURSELF THE LOGIC, PEOPLE OFTEN USE DIFFERENT ONES.
    -- SalaryToChangeTo: is the salary the boss selected (max he can select is Config.MaxSalaryPossible)
    -- ID: is the idenitifier defined in the users table for this user.
end





-- NOTE; Discord logs config in server/sConfig.lua




-- Basic Locales
Locales.MainMenuTitle = "Locker & Shop & Boss Menu"
Locales.BossMenuTitle = "Boss Options"
Locales.ShopMenuTitle = "Shop Menu"
Locales.WeaponLockerTitle = "Locker Menu"
Locales.FrozenSociety = 'Society funds are now frozen. Others can add money, but only you can use them for purchases.'
Locales.YouDeposited = 'You deposited  %d to the job\'s shop account!'
Locales.UserDeposited = 'The user deposited %s dirty money to the job\'s shop account.'
Locales.TookWeapon = 'You took %s from the locker!'
Locales.Bought = 'Bought %sx %s'
Locales.CantAffordOne = 'Your society does not have enough money to even buy one piece of this gun!'
Locales.FreezeFundsON = 'Freeze funds: TURNED ON'
Locales.FreezeFundsOFF = 'Freeze funds: TURNED OFF'
Locales.FreezeFundsDescription = 'Freeze the funds of the society, meaning they cannot be used, but members can still add to it.'
Locales.HireNew = 'Hire new employees'
Locales.HireNewDescription = 'Hire people to the organization. They shall be standing close to you.'
Locales.MonitorCenter = 'Monitor Center'
Locales.MonitorCenterDescription = 'Here you can review recent events captured by the CCTV system.'
Locales.ManageEmployees = 'Manage Employees'
Locales.ManageEmployeesDescription = 'Here you can kick / remove / (promote/demote) employees.'
Locales.InitialShopTitle = "Buy Weapons"
Locales.MainWeaponLockerTitle = "Locker"
Locales.InitialShopDescription = "Buy weapons to the job's locker. Uses society's money."
Locales.MainWeaponLockerDescription = "Pick weapons from the locker. Actions MAY be recorded by the CCTV."
Locales.MainShopTitle = "Shop"
Locales.DepositDirtyMoney = "Deposit Dirty Money"
Locales.DepositCleanMoney = "Deposit Money"
Locales.DirtyMoney = "Dirty Money"
Locales.CleanMoney = "Society Money"
Locales.InitialBossMenuTitle = "Boss Menu"
Locales.InitialBossMenuDescription = "Here you can manage your employees and view their action history."
Locales.InitialBossMenuDescriptionDisabled = "Disabled for you since you're not the boss!"
Locales.LockerSubmenuDescription = "Take gun from locker."
Locales.NoWeaponsGang = "Your gang does not have any guns!"
Locales.NoWeaponsSociety = "Your society does not have any guns!"
Locales.LockerFullOfThisGun = "The locker already has the max amount of this gun, as possible."
Locales.Price = "Price"
Locales.CantBuyCuzFrozenTitle = "No guns available!"
Locales.CantBuyCuzFrozen = "Sorry, but we can't fulfill orders at the moment. Your job's account money is frozen by the boss. You may still deposit though!"
Locales.InvalidMoneyType = "Not sure what '%s' is, but tell your dev to actually add a valid money type name."

Locales.MonitorTakeGun     = '\n\n[%s] Employee %s took %s from the locker.'
Locales.MonitorFundFreeze  = '\n\n[%s] Boss (%s) enabled fund freezing.'
Locales.MonitorFundFreeze2 = '\n\n[%s] Boss (%s) disabled fund freeze.'
Locales.MonitorDeposited   = '\n\n[%s] Employee %s deposited %s€.'


-- Player Manager Locales
Locales.OpenPlayerManaging = 'Open player\'s managing view.'
Locales.ManagementTitle = 'Employee Management'
Locales.ManagePlayerTitle = 'Manage' -- note; to this it will append the name, so It'll become "Manage: <Player Name>"
Locales.OnlineColor  = "#00ff62"
Locales.OfflineColor = "#ff1100"


Locales.EmployeeName = 'Employee Name'
Locales.OnlineStatus = 'Status'
Locales.Online  = 'Online'
Locales.Offline = 'Offline'
Locales.EmployeeAge = 'Age'
Locales.GenderM = 'Male'
Locales.GenderF = 'Female'

Locales.ChangeSalaryTitle = 'Change Employee Salary' -- You can ignore this if Config.EnableSalaryChangeOption = false
Locales.InputDialogTitle  = 'Change Payout'          -- You can ignore this if Config.EnableSalaryChangeOption = false
Locales.InputDialogDesc   = 'Salary'                 -- You can ignore this if Config.EnableSalaryChangeOption = false
Locales.PromoteTitle      = 'Promote Employee'
Locales.DemoteTitle       = 'Demote Employee'
Locales.KickTitle         = 'Kick Employee'


Locales.EmployeeKickedNotification = 'Employee %s has been successfully KICKED!'
Locales.NoManagerPermissions = 'You don\'t have permission to view or manage the employees.'

Locales.PromotionInputTitle = 'Promotion Grade:'
Locales.PromotionMenuTitle = 'Promote Employee'
Locales.Promotion = 'Employee %s promoted up to %s' -- 1st %s = employee's character name, 2nd %s = job label
Locales.AlreadyHighestGrade = 'You can\'t promote this employee, he already is the highest grade possible!'
Locales.SelectPromoteGrade = 'Press [ENTER] to select the grade you want to promote the employee to!'

Locales.DemotionInputTitle = 'Demotion Grade:'
Locales.DemotionMenuTitle = 'Demote Employee'
Locales.Demotion = 'Employee %s demoted down to %s' -- 1st %s = employee's character name, 2nd %s = job label
Locales.AlreadyLowestGrade = 'You can\'t demote this employee, he already is the lowest grade possible!'
Locales.SelectDemoteGrade = 'Press [ENTER] to select the grade you want to demote the employee to!'

Locales.ChangeUnavailable = 'Changing unavailable!'
Locales.NoActionData      = 'No action history was found at this time!'
Locales.ActionTitle       = 'Actions History:'
Locales.Back              = 'BACK'


-- Errors
Locales.DatabaseUpdateFail = 'Database update failed'
Locales.NoSocietyDataFound = 'Society data not found'
Locales.FreezeFundsPermissionError = 'How did you even end up here since you\'re not even a boss!?!?'
Locales.NoJobError              = 'Well that\'s odd... you don\'t even seem to have a job?'
Locales.TooMuchDefinedMoneyError = 'Well that\'s odd... you don\'t have as much money as you defined to be deposited?'
Locales.FailedToParseData = 'Failed to parse data.'
Locales.SuchWeaponDontExist = 'Nice try buddy!'
Locales.NoSuchWeaponInLocker = 'Weapon not found in locker!'
Locales.ImpossibleAction = 'What the hell are you trying to do...?'
Locales.InvalidWeaponSelect = 'Invalid weapon selected.'
