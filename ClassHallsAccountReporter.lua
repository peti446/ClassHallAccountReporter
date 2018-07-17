--############################################
-- Namespace
--############################################
local _, addon = ...;
addon.version = 1.5;
addon.DataToSave = {};
addon.DataToSave.charactersDatabase = {};
addon.DataToSave.options = {};
addon.CurrentCharacterInfo = {};

--Function that gets the time where the server resets
function addon:WeekResetTime() 
    --Get the second left for the reset of today
    local timeLeftForQuestReset = time() + GetQuestResetTime();
    local weeklyResetDays = {["us"] = 2, ["eu"] = 3, ["cn"] = 4, ["kr"] = 4, ["tw"] = 4};
    --Check if already on the reset day
    if(tonumber(date("%w", timeLeftForQuestReset)) ~= weeklyResetDays[GetCVar("portal"):lower()]) then
        --Not on reset day )= (You need to wait more to raid again T.T)
        --Time travel incoming :D
        repeat
            -- Add a day to the current time until we are at the reset day
            timeLeftForQuestReset = timeLeftForQuestReset + (24 * 60 * 60);
        until(tonumber(date("%w", timeLeftForQuestReset)) == weeklyResetDays[GetCVar("portal"):lower()]);
        -- Yep we are now on the time where the server resets are executed! (timeLeftForQuestReset is now on the exact date and houer)
    end
    return timeLeftForQuestReset;
end

--##########################################################################################################################
--                                  Helper Functions
--##########################################################################################################################

-- Checks if table contains a value.
function addon:tableContains(t, value)
    for i,v in ipairs(t) do
        if(type(v) == "table") then
            addon:tableContains(v, value);
        else
            return v == value;
        end
    end
end

-- Function to print a debug message
function addon:Debug(...)
    if(addon.DataToSave.options.debug) then
        addon:Print(string.join(" ", "|cFFFF0000(DEBUG)|r", tostringall(... or "nil")));
    end
end

-- Function to print a message to the chat.
function addon:Print(...)
    local msg = string.join(" ","|cFF029CFC[ClassHallsAccountReporter]|r", tostringall(... or "nil"));
    DEFAULT_CHAT_FRAME:AddMessage(msg);
end

-- Function to add the src table info to the dst talbe info, if dest already has this info overwrite it
function addon:addMissingFields(base, t)
    if(type(t) ~= "table") then
        return base;
    end

    if(type(base) ~= "table") then
        return t;
    end

    for k,v in pairs(base) do
        if(t[k] == nil and k ~= nil) then
            t[k] = v;
        end
    end
    return t;
end

function addon:SortcharacterList(t)
    local keys = {};
    --Adds all the names to a table
    for n,k in pairs(t) do
        if(n ~= nil) then
            table.insert(keys, n);
        end
    end
    --Sorts them by server and then by name.
    table.sort(keys, function(a,b)
        local name1,server1 = strsplit("-", a, 2) or "", "";
        local name2,server2 = strsplit("-", b, 2) or "", "";
        if(server1 == server2) then
            --Short by name
            local ComputF8 = strcmputf8i(name1, name2);
            return ComputF8 < 0;
        else
            --Different server so yhea put all the same server together (?)
            return true;
        end
    end);

    -- Returns the iterator
    local i = 0;
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- Function to sort the followers
function addon:SortFollowers(t)
    local statusTextsPriotities = {
        [GARRISON_FOLLOWER_IN_PARTY] = 1,
        [GARRISON_FOLLOWER_WORKING] = 2,
        [GARRISON_FOLLOWER_ON_MISSION] = 3,
        [GARRISON_FOLLOWER_COMBAT_ALLY] = 4,
        [GARRISON_FOLLOWER_EXHAUSTED] = 5,
        [GARRISON_FOLLOWER_INACTIVE] = 6
    };

    -- Add The keys to the keys.
    local keys = {};
    for n,k in pairs(t) do
        table.insert(keys, n);
    end
    
    -- Sort the followers by different values
    table.sort(keys, function(a,b)
        -- Sort by status if possible
        if(t[a]["status"] and not t[b]["status"]) then
            return false;
        elseif(not t[a]["status"] and t[b]["status"]) then
            return true;
        end
        if(t[a]["status"] ~= t[b]["status"]) then
            return statusTextsPriotities[t[a]["status"]] < statusTextsPriotities[t[b]["status"]];
        end

        -- Sort by level if status is not available or the same
        if(t[a]["level"] ~= t[b]["level"]) then
            return t[a]["level"] > t[b]["level"];
        elseif(t[a]["ilvl"] ~= t[b]["ilvl"]) then
            return t[a]["ilvl"] > t[b]["ilvl"];
        end
        -- Sort by quality
        if(t[a]["quality"] ~= t[b]["quality"]) then
            return t[a]["quality"] > t[b]["quality"];
        end

        -- Sort by current xp
        if(t[a]["xp"] > 0 and t[b]["xp"] > 0) then
            return t[a]["xp"] > t[b]["xp"];
        end
        -- Lastly short by ID.
        return t[a]["garrFollowerID"] > t[b]["garrFollowerID"];
    end);

    -- return iterator function.
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- Function to sort the missions by the end time.
function addon:SortMissions(t)
    local keys = {};
    for n,k in pairs(t) do
        table.insert(keys, n);
    end
    table.sort(keys, function(a,b)
        return t[a].missionEndTime < t[b].missionEndTime;
    end);

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- Returns a string of the time formated
function addon:convertSecondToTimeStr(s)
    return SecondsToTime(s);
end

-- Fixes the info about shipments and save it again
function addon:fixShipmentsInfo(shipment)
    local currentFinishedShipmentsTime = shipment.creationTime + (shipment.duration*shipment.shipmentsReady);
           
    while(currentFinishedShipmentsTime + shipment.duration < time() and shipment.shipmentsReady < shipment.shipmentsTotal)  do
        currentFinishedShipmentsTime = currentFinishedShipmentsTime +  shipment.duration;
        shipment.shipmentsReady = shipment.shipmentsReady +1;
    end
end

function addon:prepareCharacterDataBase()
    local name = select(1, UnitName("player")).."-"..GetRealmName();
    -- Check if the current character already exits in the table if not create a table for him
    if(addon.DataToSave.charactersDatabase.characters[name] == nil or type(addon.DataToSave.charactersDatabase.characters[name]) ~= "table") then
       addon.DataToSave.charactersDatabase.characters[name] = {};
    end

    -- Fix the current table database to add missing fields to have all the required fields 
    addon.DataToSave.charactersDatabase.characters[name] = addon:addMissingFields(
    {
        pclassName = select(2, UnitClass("player")),
        pclassID = select(3, UnitClass("player")),
        plevel =  UnitLevel("player"),
        pilvl = select(2, GetAverageItemLevel()),
        lastTimeUpdated = time(),
        showKeystone = false,
        currency = {},
        troops = {},
        followers = {},
        activeMissions = {},
        availableMissions = {},
        troopsInTraining = {},
        shipments = {},
        mSumarryFrame = "cook",
        mytics = {
            ["ChestAvailable"] = false,
            ["Keystone"] = {},
            ["list"] = {},
        }
    } , addon.DataToSave.charactersDatabase.characters[name]);

    -- Set the info of the current character
    addon.CurrentCharacterInfo = addon.DataToSave.charactersDatabase.characters[name];
end

--Function to get a keystone from the bags
-- Returns the full link for the key
function addon:GetKeystoneFromBags()
    for bag = 0, NUM_BAG_SLOTS + 1 do
        for bagSlot = 1, GetContainerNumSlots(bag) do
            local currentItemInSlotID = GetContainerItemID(bag, bagSlot);
            if(currentItemInSlotID) then
                if(currentItemInSlotID == 138019) then
                    return GetContainerItemLink(bag, bagSlot);
                end
            end
        end
    end
    return nil;
end

--##########################################################################################################################
--                                  Functions to get Players Info
--##########################################################################################################################

function addon:StoreKeyInformation(forced)
    -- Prepare the character if 
    if(UnitLevel('player') ~= 110) then
        return;
    end
    addon:prepareCharacterDataBase();
    -- Example of a key link :|cffa335ee|Hkeystone:209:15:8:12:10|h[Keystone: The Arcway (15)]|h|r
    -- Patter matching to extract usefull data  link:gsub('\124', '\124\124'):match(':(%d+):(%d+):(%d+):(%d+):(%d+)');
    -- MAPID, level, afix1, afix2, afix3
    -- C_ChallengeMode.GetMapInfo(id);
    local keyStoneLink = addon:GetKeystoneFromBags();
    if(keyStoneLink ~= nil) then
        if(keyStoneLink:find('keystone')) then
            local mapid, level, afix1, afix2, afix3 = keyStoneLink:gsub('\124', '\124\124'):match(':(%d+):(%d+):(%d+):(%d+):(%d+)');
            addon.CurrentCharacterInfo.mytics.Keystone = {
                ["mapID"] = mapid,
                ["level"] = level,
                ["afix1"] = afix1,
                ["afix2"] = afix2,
                ["afix3"] = afix3
            };
            if(addon.main_frame:IsEventRegistered("BAG_UPDATE")) then 
                addon.main_frame:UnregisterEvent("BAG_UPDATE");
            end
        end
    else
        if(not addon.main_frame:IsEventRegistered("BAG_UPDATE") and forced ~= "commandSearch") then 
            addon.main_frame:RegisterEvent("BAG_UPDATE");
        end
    end
end

-- Function to get the info about mitics+!
function addon:StoreCompletedMytic()
    if(not addon.mytics.CurrentID) then
        return;
    end
    -- Prepare the character if necesary
    addon:prepareCharacterDataBase();
    local mapID, level, timeN, onTime, keystoneUpgradeLevels = C_ChallengeMode.GetCompletionInfo();
    if(addon.CurrentCharacterInfo.mytics.list[addon.mytics.CurrentID] == nil or type(addon.CurrentCharacterInfo.mytics.list[addon.mytics.CurrentID]) ~= "table") then
        addon.CurrentCharacterInfo.mytics.list[addon.mytics.CurrentID] = {};
    end
    
    addon:Debug("Mytic + compleated. Info: ".. addon.mytics.CurrentID .. " " .. mapID .. " " .. level .. " " .. timeN .. " " .. tostring(onTime) .. " " .. keystoneUpgradeLevels);
    table.insert(addon.CurrentCharacterInfo.mytics.list[addon.mytics.CurrentID], {
        ["mapID"] = mapID,
        ["level"] = level,
        ["TimeToComplete"] = timeN,
        ["onTime"] = onTime,
        ["Upgrades"] = keystoneUpgradeLevels,
    });
end

-- Function to get the order resources and broken seals
function addon:storeCurrencyInfo()
    if (not C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 )) then
        return;
    end
    addon:Debug("Storing currencies information.")
    -- Prepare the character if necesary
    addon:prepareCharacterDataBase();
    -- Get resources,Seals of Broken Fate and other currencies for the character
    local _, amountResources = GetCurrencyInfo(1220);
    local _, amountSeal =  GetCurrencyInfo(1273);
    local _, amountWakeningEssence = GetCurrencyInfo(1533);
    local _, amountcuriouscoin = GetCurrencyInfo(1275);
    local _, amountveiledargunite = GetCurrencyInfo(1508);
    addon.CurrentCharacterInfo.currency =  {
        ["HallResources"] = amountResources,
        ["SealsOfBrokenFate"] = amountSeal,
        ["bloodOfSargeras"] = GetItemCount(124124, true),
        ["gold"] = (GetMoney()/100)/100,
        ["WakeningEssence"] = amountWakeningEssence,
        ["curiouscoin"] = amountcuriouscoin,
        ["veiledargunite"] = amountveiledargunite,
        ["SealsMissionsCompleted"] = {}
    };
    -- Array of all seals missions currently in the game
    local BrokenFateQuests = { [43892] = {
                                            ["name"] = "Sealing Fate: Order Resources",
                                            ["costStr"] = "1000 Order Resources" 
                                       },
                               [43893] = {
                                            ["name"] = "Sealing Fate: Stashed Order Resources",
                                            ["costStr"] = "2000 Order Resources" 
                                       },
                               [43894] = {
                                            ["name"] = "Sealing Fate: Extraneous Order Resources",
                                            ["costStr"] = "4000 Order Resources" 
                                       },
                               [43895] = {
                                            ["name"] = "Sealing Fate: Gold",
                                            ["costStr"] = "1000 gold" 
                                       },
                               [43896] = {
                                            ["name"] = "Sealing Fate: Piles of Gold",
                                            ["costStr"] = "2000 gold" 
                                       },
                               [43897] = {
                                            ["name"] = "Sealing Fate: Immense Fortune of Gold",
                                            ["costStr"] = "4000 gold" 
                                       },
                               [47851] = {
                                            ["name"] = "Sealing Fate: Marks of Honor",
                                            ["costStr"] = "5 Marks of Honor" 
                                       },
                               [47864] = {
                                            ["name"] = "Sealing Fate: Additional Marks of Honor",
                                            ["costStr"] = "10 Marks of Honor" 
                                       },
                               [47865] = {
                                            ["name"] = "Sealing Fate: Piles of Marks of Honor",
                                            ["costStr"] = "20 Marks Of Honor" 
                                       }
                               };
    -- Check for the currently completed quests.
    addon.CurrentCharacterInfo.currency.SealsMissionsCompleted = {};
    for qid,info in pairs(BrokenFateQuests) do
        if(IsQuestFlaggedCompleted(qid)) then
            addon.CurrentCharacterInfo.currency.SealsMissionsCompleted[qid] = info;
        end
    end
    addon.CurrentCharacterInfo.lastTimeUpdated = time();
end

-- Function to get the class troop info
function addon:storeClassTroopInfo()
    -- Get info from the followers in you class hall
    addon:Debug("Storing class based troop info.")
    local temp =  C_Garrison.GetClassSpecCategoryInfo(LE_FOLLOWER_TYPE_GARRISON_7_0);
    if(temp ~= nil and type(temp) == "table") then
        addon.CurrentTroopsClassInfo = temp;
        addon:storeFollowersAndTroopsInfo();
    end
end

--Function to store troops in training
function addon:storeToopsInTrainingInfo()
    if (not C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 )) then
        return;
    end
    -- Prepare the character if necesary
    addon:prepareCharacterDataBase();

    -- Get training troops
    addon:Debug("Storing troops in training info");
    local TrainingTroops = C_Garrison.GetFollowerShipments(LE_GARRISON_TYPE_7_0);
    if(TrainingTroops ~= nil and type(TrainingTroops) == "table") then
        wipe(addon.CurrentCharacterInfo.troopsInTraining);
        for i, troopTrainingID in ipairs(TrainingTroops) do
            local  name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, _, _, _, _, followerID = C_Garrison.GetLandingPageShipmentInfoByContainerID(troopTrainingID);
            if(name ~= nil) then
                addon.CurrentCharacterInfo.troopsInTraining[troopTrainingID] = {
                    ["name"] = name,
                    ["texture"] = texture,
                    ["shipmentCapacity"] = shipmentCapacity,
                    ["shipmentsReady"] = shipmentsReady,
                    ["shipmentsTotal"] = shipmentsTotal,
                    ["creationTime"] = creationTime,
                    ["duration"] = duration
                };
            end
        end
    end
    addon.CurrentCharacterInfo.lastTimeUpdated = time();
end

-- Function to get the followers and troops info
function addon:storeFollowersAndTroopsInfo()
    if (not C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 )) then
        return;
    end
    -- Prepare the character if necesary
    addon:prepareCharacterDataBase();
    -- Set the minimum required info to the troops
    addon:Debug("Storing troops.")
    if(addon.CurrentTroopsClassInfo ~= nil and type(addon.CurrentTroopsClassInfo) == "table") then
        wipe(addon.CurrentCharacterInfo.troops);
        for i,info in pairs(addon.CurrentTroopsClassInfo) do
            if(addon.CurrentCharacterInfo.troops[info.name] == nil) then
                addon.CurrentCharacterInfo.troops[info.name] = {
                        ["quality"] = nil,
                        ["maxDurability"] = nil,
                        ["maxCount"] = nil,
                        ["description"] = nil,
                        ["currentCount"] = nil,
                        ["classSpec"] = nil,
                        ["iconID"] = nil,
                        ["troopsArray"] = {}
                };
            end
            addon.CurrentCharacterInfo.troops[info.name].maxCount = info.limit;
            addon.CurrentCharacterInfo.troops[info.name].currentCount = info.count;
            addon.CurrentCharacterInfo.troops[info.name].description = info.description;
            addon.CurrentCharacterInfo.troops[info.name].iconID = info.icon;
            addon.CurrentCharacterInfo.troops[info.name].classSpec = info.classSpec;
        end
    end
    -- Get Followrs and troops, in case of the troops get the durability and if they are in a missions
    addon:Debug("Storing followers.")
    local followersAllData = C_Garrison.GetFollowers(LE_FOLLOWER_TYPE_GARRISON_7_0);
    if(followersAllData ~= nil and type(followersAllData) == "table") then
        wipe(addon.CurrentCharacterInfo.followers);
        for i, follower in ipairs(followersAllData) do
            if(follower.isCollected) then
                if(not follower.isTroop) then
                    addon.CurrentCharacterInfo.followers[follower.followerID] = {
                        ["garrFollowerID"] = follower.garrFollowerID,
                        ["name"] = follower.name,
                        ["level"] = follower.level,
                        ["xp"] = follower.xp,
                        ["levelXP"] = follower.levelXP,
                        ["quality"] = follower.quality,
                        ["ilvl"] = follower.iLevel,
                        ["isMaxLevel"] = follower.isMaxLevel,
                        ["status"] = follower.status,
                        ["classAtlas"] = follower.classAtlas,
                        ["iconID"] = follower.portraitIconID
                    };
                else
                    if(addon.CurrentCharacterInfo.troops[follower.name] ~= nil and type(addon.CurrentCharacterInfo.troops[follower.name]) == "table") then
                        if(addon.CurrentCharacterInfo.troops[follower.name].quality == nil) then
                            addon.CurrentCharacterInfo.troops[follower.name].quality = follower.quality;
                        end
                        if(addon.CurrentCharacterInfo.troops[follower.name].maxDurability == nil) then
                            addon.CurrentCharacterInfo.troops[follower.name].maxDurability = follower.maxDurability;
                        end

                        addon.CurrentCharacterInfo.troops[follower.name].troopsArray[follower.followerID] ={
                            ["garrFollowerID"] = follower.garrFollowerID,
                            ["currentDurability"] = follower.durability,
                            ["status"] = follower.status,
                            ["classAtlas"] =  follower.classAtlas
                        };
                    end
                end
            end
        end
    end
    addon:storeToopsInTrainingInfo();
    addon.CurrentCharacterInfo.lastTimeUpdated = time();
end

function addon:storeShipmentsInfo()
    if (not C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 )) then
        return;
    end
    -- Prepare the character if necesary
    addon:prepareCharacterDataBase();
    --Get Acive missions (Name, Reward, Time left to complete, ILVL, Followers/troops in the mission)
    addon:Debug("Storing active missions")
    wipe(addon.CurrentCharacterInfo.activeMissions);
    local missionsInProgress = C_Garrison.GetLandingPageItems(LE_GARRISON_TYPE_7_0);
    local tempMissionInProgress = {};
    for i, v in ipairs(missionsInProgress) do
        v["timeInfoCollected"] = time();
        tempMissionInProgress[v.name] = v;
    end
    addon.CurrentCharacterInfo.activeMissions = tempMissionInProgress;

    -- Get Available missions (Name, Reward , Time to complete, Time to expire, ILVL)
    addon:Debug("Storing available missions")
    wipe(addon.CurrentCharacterInfo.availableMissions);
    local missionsAvailableToStart = C_Garrison.GetAvailableMissions(4);
    local tempMission = {};
    for i, v in ipairs(missionsAvailableToStart) do
        v["timeInfoCollected"] = time();
        tempMission[v.name] = v;
    end
    addon.CurrentCharacterInfo.availableMissions = tempMission;

    addon:storeToopsInTrainingInfo();

    -- Get shipments
    addon:Debug("Storing shipments missions")
    wipe(addon.CurrentCharacterInfo.shipments);
    local allShipments = C_Garrison.GetLooseShipments(LE_GARRISON_TYPE_7_0);
    if(allShipments ~= nil and type(allShipments) == "table") then
        for i, shipmentID in ipairs(allShipments) do
            local name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration = C_Garrison.GetLandingPageShipmentInfoByContainerID(shipmentID);
            if(name ~= nil) then
                addon.CurrentCharacterInfo.shipments[shipmentID] = {
                    ["name"] = name,
                    ["texture"] = texture,
                    ["shipmentCapacity"] = shipmentCapacity,
                    ["shipmentsReady"] = shipmentsReady,
                    ["shipmentsTotal"] = shipmentsTotal,
                    ["creationTime"] = creationTime,
                    ["duration"] = duration
                };
                if(shipmentID == 122) then
                    addon.CurrentCharacterInfo.shipments[122].QuestCompleated = true; 
                end
            end
        end
    end
    if(addon.CurrentCharacterInfo.shipments[122] == nil) then
        addon.CurrentCharacterInfo.shipments[122] = {
            ["QuestCompleated"] = IsQuestFlaggedCompleted(40991);
        };
    end
    if(addon.CurrentCharacterInfo.shipments[122].QuestCompleated == nil) then
        addon.CurrentCharacterInfo.shipments[122].QuestCompleated  = IsQuestFlaggedCompleted(40991);
    end
    addon.CurrentCharacterInfo.lastTimeUpdated = time();
end


-- Function to store the characters hall class info
function addon:allInfoUpdater()
    if (C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 )) then
        -- Prepare the character if necesary then call the landing page shipment info
        addon:prepareCharacterDataBase();
        -- Update all possible information on exit
        addon:Debug("Trying to store all characte information");
        addon.storeShipmentsInfo();
        addon.storeFollowersAndTroopsInfo();
        addon.storeCurrencyInfo();
        addon.CurrentCharacterInfo.mytics.ChestAvailable = C_MythicPlus.IsWeeklyRewardAvailable();
        addon.CurrentCharacterInfo.plevel =  UnitLevel("player");
        addon.CurrentCharacterInfo.pilvl = select(2, GetAverageItemLevel());

    end
end

--##########################################################################################################################
--                                  Update Function
--##########################################################################################################################

-- Reset the weekly data such as the completed seals missions.
function addon:resetAllCharactersWeeklyData()
    addon.DataToSave.charactersDatabase.nextReset = addon:WeekResetTime();
    for name,v in pairs(addon.DataToSave.charactersDatabase.characters) do
        addon:Debug("Doing the weekly reset on: " .. name);
        wipe(v["currency"]["SealsMissionsCompleted"]);
        if(next(v.mytics.list) ~= nil) then
            v.mytics.ChestAvailable = true;
        end
        wipe(v["mytics"]["list"]);
        wipe(v["mytics"]["Keystone"]);
        v["lastTimeUpdated"] = time();
    end
    
end

--Update the current files so no errors occur when a new version changes the way info is stored in the file
function addon:Update()
    local oldVersionOptions = addon.DataToSave.options.Version;
    local options = addon.DataToSave.options;

    local oldVersionDatabase = addon.DataToSave.charactersDatabase.Version;
    local database = addon.DataToSave.charactersDatabase;

    local currentVersion = addon.version;

    if(type(oldVersionOptions) == "string") then
        oldVersionOptions = tonumber(oldVersionOptions);
    end
    if(type(oldVersionDatabase) == "string") then
        oldVersionDatabase = tonumber(oldVersionDatabase);
    end

    if(oldVersionDatabase ~= currentVersion) then
        addon:Print("Old saved settings detected, updating them...!");
        -- Version 0.2 options does not change
        -- Version 0.3 Mytics where added
        -- Version 0.6 Demon Hunter fixed
        -- Version 0.7 Fixed Crash and fixed the update function was not updating anything Y.Y
        -- Version 1.0 Fixed error with mitic+ showing a different ilvl
        for name, value in pairs(addon.DataToSave.charactersDatabase.characters) do
            if(oldVersionDatabase < 0.7) then
                if(value.pclassName == "DEMON HUNTER") then
                    value.pclassName = "DEMONHUNTER";
                end
                if(value.mytics == nil or type(value.mytics) ~= "table") then
                    value.mytics = {};
                    value.mytics.list = {};
                    value.mytics.ChestAvailable = false;
                end
            end
            if(oldVersionDatabase < 1.0) then
                if(value.currency.WakeningEssence == nil) then
                    value.currency.WakeningEssence = 0;
                end
            end
            if(oldVersionDatabase < 1.1) then
                if(value.mytics.Keystone == nil or type(value.mytics.Keystone) ~= "table") then
                    value.mytics.Keystone = {};
                end
                if(value.showKeystone == nil) then
                    value.showKeystone = false;
                end
            end
            if(oldVersionDatabase < 1.4) then
                if(value.mSumarryFrame == nil) then
                    value.mSumarryFrame = "cook";
                end
                if(value.showKeystone ~= nil) then
                    value.showKeystone = nil;
                end
            end
        end
        database.Version = addon.version;
    end


    if(oldVersionOptions ~= currentVersion) then
        addon:Print("Old Character settings detected, updating them...!");
        if(oldVersionOptions < 0.7) then
            if(options.debug == nil) then
                options.debug = false;
            end
        end
        if(oldVersionOptions < 1.4) then
            if(options.frameInfo == nil or type(options.frameInfo)~= "table") then
                options.frameInfo = {};
            end
            if(options.frameInfo.frameX == nil) then
                options.frameInfo.frameX = 0;
            end
            if(options.frameInfo.frameY == nil) then
                options.frameInfo.frameY = 0;
            end
            if(options.frameInfo.relativePoint == nil) then
                options.frameInfo.relativePoint = "CENTER";
            end
            if(options.frameInfo.point == nil) then
                options.frameInfo.point = "CENTER";
            end
        end
        options.Version = addon.version;
    end
end