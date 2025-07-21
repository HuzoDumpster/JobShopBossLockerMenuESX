A simple all-in-one GUI for job or gang management, featuring a **gun locker**, **gun shop**, and **boss menu**.  
Only dependencies are [`ox_lib`](https://github.com/overextended/ox_lib) and [`es_extended`](https://github.com/esx-framework/es_extended).

> ⚠️ This is a performance-heavy resource due to frequent data updates.  
> If preferred, you can rework it to fetch data less often by caching and updating only when necessary.

---

## Menu Structure

### Boss Menu
- **Manage Employees**
  - View employee details:
    - Name
    - Status
    - Age
  - Actions:
    - Promote Employee
    - Demote Employee
    - Kick Employee

- **Hire New Employees**
  - Select a nearby player by looking at them and pressing **left-click**.
  - This system relies on a private resource that is not included.  
    You'll need to modify the method at [`client/client.lua:247`](./client/client.lua#L247) to suit your own hiring logic.
  - Once a player is selected, trigger the event: `JobMenu:hire` with parameters that have player data as the first (ESX.GetPlayerData()) and the job name to assign the player to as the second one.

- **Freeze Funds**
  - Toggle ON/OFF to prevent spending from the society funds (players can still deposit).

- **Monitor Center**
  - Displays a log of recent actions:
    - Weapon withdrawals
    - Money deposits
    - Fund freezes  
  - *Note: Resets on server restart.*

---

### Weapon Shop
- Shows current **society money**
- **Deposit Money** into the society account
- **Buy Weapons** from a predefined list

---

### Weapon Locker
- **Withdraw Weapons** from the shared locker

---

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [es_extended](https://github.com/esx-framework/es_extended)

---

## Notes

- Resource is designed for frequent data refresh, which may impact performance.  
  You're welcome to refactor the data system for better efficiency.
- **Minor bugs** (like missing return buttons) **will not be fixed**.
- If you encounter **breaking issues**, feel free to create an issue and I'll try to fix them.
- Modification is allowed and encouraged.
- Getting this perfectly working **FOR YOUR SERVER**, might be challenging without any knowledge.
- For testing I made the menu open when "H" is pressed, and the player HAS a job. You need to modify when/how it opens, according to your own needs. It's on [`client/client.lua:34`](./client/client.lua#L34)

---

## Screenshots
![Main Menu Image.](https://github.com/HuzoDumpster/JobShopBossLockerMenuESX/blob/main/Screenshots/MainMenuu.png?raw=true)
![Shop Menu Image.](https://github.com/HuzoDumpster/JobShopBossLockerMenuESX/blob/main/Screenshots/ShopMenu.png?raw=true)
![Locker Menu Image.](https://github.com/HuzoDumpster/JobShopBossLockerMenuESX/blob/main/Screenshots/LockerMenu.png?raw=true)
![Boss Menu Image.](https://github.com/HuzoDumpster/JobShopBossLockerMenuESX/blob/main/Screenshots/BossMenu.png?raw=true)
![Manager Menu Image.](https://github.com/HuzoDumpster/JobShopBossLockerMenuESX/blob/main/Screenshots/ManageEmployee.png?raw=true)
![History Menu Image.](https://github.com/HuzoDumpster/JobShopBossLockerMenuESX/blob/main/Screenshots/ActionsHistory.png?raw=true)
