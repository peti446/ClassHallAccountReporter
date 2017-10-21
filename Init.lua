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
        ["minimapPos"] = 145
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
        self:UnregisterEvent("ADDON_LOADED");
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
    elseif(event == "GARRISON_FOLLOWER_ADDED" or event == "GARRISON_FOLLOWER_REMOVED") then
        -- Update followers
        addon:storeFollowersAndTroopsInfo();
    elseif(event == "GARRISON_FOLLOWER_CATEGORIES_UPDATED") then
        -- Get follower count and info
        addon:storeClassTroopInfo();
    elseif(event == "CHAT_MSG_CURRENCY" or event == "BONUS_ROLL_RESULT" or event == "CHAT_MSG_LOOT") then
        -- Update currency
        addon:storeCurrencyInfo();
    elseif(event == "CHALLENGE_MODE_COMPLETED") then
        addon:StoreCompletedMytic();
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
local main_frame = CreateFrame("Frame");
-- Set Scripts
main_frame:SetScript("OnEvent", addon.eventHandling);
-- Register events
main_frame:RegisterEvent("ADDON_LOADED");
main_frame:RegisterEvent("PLAYER_LOGIN");
main_frame:RegisterEvent("GARRISON_FOLLOWER_CATEGORIES_UPDATED");
main_frame:RegisterEvent("GARRISON_FOLLOWER_ADDED");
main_frame:RegisterEvent("GARRISON_FOLLOWER_REMOVED");
main_frame:RegisterEvent("GARRISON_LANDINGPAGE_SHIPMENTS");
main_frame:RegisterEvent("GARRISON_SHOW_LANDING_PAGE");
main_frame:RegisterEvent("CHAT_MSG_CURRENCY");
main_frame:RegisterEvent("BONUS_ROLL_RESULT");
main_frame:RegisterEvent("CHAT_MSG_LOOT");
main_frame:RegisterEvent("CHALLENGE_MODE_COMPLETED");
main_frame:RegisterEvent("CHALLENGE_MODE_START");