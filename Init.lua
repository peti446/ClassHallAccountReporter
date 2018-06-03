--############################################
-- Namespace
--############################################
local Aname_, addon = ...;


--##########################################################################################################################
--                                  Default values for options and characterDatabase
--##########################################################################################################################

function addon:getCHARdefaultCharacterDatabase()
    return {
        ["Version"] = addon.version,
        ["nextReset"] = addon.WeekResetTime(),
        ["characters"] = {}
    };
end

--Defaults options for character
function addon:getCHARdefaultOptions()
    return {
        ["Version"] = addon.version,
        ["showMinimapIcon"] = false,
        ["debug"] = false,
        ["minimapPos"] = 145,
        ["frameInfo"] = {
            ["frameX"] = 0,
            ["frameY"] = 150,
            ["relativePoint"] = "CENTER",
            ["point"] = "CENTER",
        }
    };
end

--##########################################################################################################################
--                                  Event handling
--##########################################################################################################################

function addon:eventHandling(event, arg1)
    addon:Debug(event);
    if (event == "ADDON_LOADED") then
        if(arg1 ~= Aname_) then
            return;
        end
        if(ClassHallsAccountReporterData == nil) then
            ClassHallsAccountReporterData = addon:getCHARdefaultCharacterDatabase();
        end

        if(ClassHallsAccountReporterCharacterOptions == nil) then
            ClassHallsAccountReporterCharacterOptions = addon:getCHARdefaultOptions();
        end
        addon.DataToSave.charactersDatabase = ClassHallsAccountReporterData;
        addon.DataToSave.options = ClassHallsAccountReporterCharacterOptions;

        --Check if obligatory values exits
        if(addon.DataToSave.charactersDatabase.Version == nil) then
            addon.DataToSave.charactersDatabase.Version = addon.version;
        end
        if(addon.DataToSave.charactersDatabase.nextReset == nil) then
            addon.DataToSave.charactersDatabase.nextReset = addon:WeekResetTime();
        end
        if(addon.DataToSave.charactersDatabase.characters == nil) then
            addon.DataToSave.charactersDatabase.characters = {};
        end
        addon:Update();
        self:UnregisterEvent(event);
    elseif(event == "PLAYER_LOGIN") then
        --Reset weekly stuff so its done for all characters
        if(addon.DataToSave.charactersDatabase.nextReset < time()) then
            -- We already passed the reset time so reset all the weekly stuff !
            addon:resetAllCharactersWeeklyData();
        end
        --Load commands
        addon.Commands:initCommands();
        --Get all data about mitics +
        C_ChallengeMode.RequestMapInfo();
        C_ChallengeMode.RequestRewards();
        addon.MinimapIcon:initIcon();
        self:UnregisterEvent(event);
    elseif(event == "GARRISON_LANDINGPAGE_SHIPMENTS") then
         -- Update all as nearly all is available
         addon:allInfoUpdater();
    elseif(event == "GARRISON_MISSION_LIST_UPDATE" or event == "GARRISON_MISSION_STARTED") then
        --Update missions
        addon:storeShipmentsInfo()
    elseif(event == "GARRISON_FOLLOWER_ADDED" or event == "GARRISON_FOLLOWER_REMOVED") then
        -- Update followers
        addon:storeFollowersAndTroopsInfo();
    elseif(event == "GARRISON_FOLLOWER_CATEGORIES_UPDATED") then
        -- Get follower count and info
        addon:storeClassTroopInfo();
    elseif(event == "CHAT_MSG_CURRENCY" or event == "BONUS_ROLL_RESULT" or event == "CHAT_MSG_LOOT") then
        -- Update currency
        addon:storeCurrencyInfo();
        if(event == "CHAT_MSG_LOOT") then
            local itemLooted = arg1;
            if (string.lower(itemLooted):find('keystone')) then
                addon:StoreKeyInformation();
            end
        end
    elseif(event == "BAG_UPDATE") then
        addon:StoreKeyInformation();
    elseif(event == "CHALLENGE_MODE_COMPLETED") then
        -- Store mytic mode
        addon:StoreCompletedMytic();
        -- Get the Info about the new key after a short interval
        C_Timer.After(3, addon.StoreKeyInformation);
    elseif(event == "CHALLENGE_MODE_START") then
        if(addon.mytics == nil or type(addon.mytics) ~= "table") then
            addon.mytics = {};
        end
        addon.mytics.CurrentID = C_ChallengeMode.GetActiveChallengeMapID();
    else
        if (C_Garrison.HasGarrison(LE_GARRISON_TYPE_7_0)) then
	        C_Garrison.RequestClassSpecCategoryInfo(LE_FOLLOWER_TYPE_GARRISON_7_0);
        end
    end

end


-- Event handling frame
addon.main_frame = CreateFrame("Frame");
-- Set Scripts
addon.main_frame:SetScript("OnEvent", addon.eventHandling);
-- Register events
addon.main_frame:RegisterEvent("ADDON_LOADED");
addon.main_frame:RegisterEvent("PLAYER_LOGIN");
addon.main_frame:RegisterEvent("GARRISON_FOLLOWER_CATEGORIES_UPDATED");
addon.main_frame:RegisterEvent("GARRISON_FOLLOWER_ADDED");
addon.main_frame:RegisterEvent("GARRISON_FOLLOWER_REMOVED");
addon.main_frame:RegisterEvent("GARRISON_LANDINGPAGE_SHIPMENTS");
addon.main_frame:RegisterEvent("GARRISON_MISSION_LIST_UPDATE");
addon.main_frame:RegisterEvent("GARRISON_MISSION_STARTED");
addon.main_frame:RegisterEvent("GARRISON_SHOW_LANDING_PAGE");
addon.main_frame:RegisterEvent("CHAT_MSG_CURRENCY");
addon.main_frame:RegisterEvent("BONUS_ROLL_RESULT");
addon.main_frame:RegisterEvent("CHAT_MSG_LOOT");
addon.main_frame:RegisterEvent("CHALLENGE_MODE_COMPLETED");
addon.main_frame:RegisterEvent("CHALLENGE_MODE_START");