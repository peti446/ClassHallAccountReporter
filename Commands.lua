--############################################
-- Namespace
--############################################
local _, addon = ...;

addon.Commands = {};

local Commands = addon.Commands;

--##########################################################################################################################
--                                  Commands Fnctions
--##########################################################################################################################

function Commands:helpOutput()
    addon:Print("--------- |cff00F3FFList of commands:|r ---------");
    addon:Print("|cff188E01/char help|r - Shows all commands");
    addon:Print("|cff188E01/char show|r - Shows the Report frame");
	addon:Print("|cff188E01/char reset|r - Resets all the information");
	addon:Print("|cff188E01/char debug|r - Enables Debug mode");
	addon:Print("|cff188E01/char searchKey|r - Search for a keystone in you inventory. Use it if the addon did not auto detect it.");
	addon:Print("|cff188E01/char setsummary <cook/keystone/hallmissions> <this/character/all>|r - Changes the summary frame to display nomies cooking order, the keystone information or hallmissions sumarry for this character, a specific character or all of them.");
	addon:Print("|cff188E01/char toggleMinimapIcon|r - Toggles the miniamp icon.");
	addon:Print("-------------------------------------");
end

function Commands:toggleDebug()
	addon.DataToSave.options.debug = not addon.DataToSave.options.debug;
	local str;
	if(addon.DataToSave.options.debug) then
		str = " |cFF3AFF00ENABLED|r";
	else
		str = "|cFFFF0000DISABLED|r";
	end
	addon:Print("Addon debuging is now: " .. str); 
end

function Commands:KeystoneFindWrapper()
	addon:StoreKeyInformation("commandSearch");
end

function Commands:ToggleMinimapIconFunc()
	local boolIsShown = not addon.DataToSave.options.showMinimapIcon;
	addon.DataToSave.options.showMinimapIcon = boolIsShown;
	if(boolIsShown) then
		addon.MinimapIcon.frame:Show();
	else
		addon.MinimapIcon.frame:Hide();
	end
end

function Commands:SetSummaryStatus(sumType, character)
	--Check if character and the type is given
	sumType = sumType:lower();
	if(not character or not sumType or (sumType ~= "cook" and sumType ~= "keystone" and sumType ~= "hallmissions")) then
		addon:Print("|cffff0000Invalid command argument....|r");
		Commands:helpOutput();
		return;
	end

	--Checks if we are ussing a character name or a shorcut
	if(character ~= "all" and character ~= "this") then
		--Check if character is valid
		if(type(addon.DataToSave.charactersDatabase.characters[character]) ~= "table") then
			addon:Print("Character not found in the database... Please type a valid charcater name.");
			addon:Print("Remember that te format is: name-server.");
			addon:Print("You can always open the sumary frame of the addon and copy the name as its there.");
			addon:Print("If the character exists but is not been shown in the frame, log-in with the character first and then log out, then try the command again.");
			return;
		end
		addon.DataToSave.charactersDatabase.characters[character].mSummaryFrame = sumType;
	else
		if(character == "all") then
			for name, v in pairs(addon.DataToSave.charactersDatabase.characters) do
				v.mSummaryFrame = sumType;
			end
		else
			addon.DataToSave.charactersDatabase.characters[select(1,UnitName("player")).."-"..GetRealmName()].mSummaryFrame = sumType;
		end
	end
	addon.ReportUI:updateFrameCharacterInfo(true);
end

--
--##########################################################################################################################
--                                  Commands handling
--##########################################################################################################################

Commands.List = {
    ["help"] = Commands.helpOutput,
    ["show"] = addon.ReportUI.toggleFrame,
	["reset"] = addon.ReportUI.deleteAllData,
	["debug"] = Commands.toggleDebug,
	["searchkey"] = Commands.KeystoneFindWrapper,
	["setsummary"] = Commands.SetSummaryStatus,
	["toggleminimapicon"] = Commands.ToggleMinimapIconFunc
	};

local function HandleSlashCommands(str)
	if (#str == 0) then	
		-- User entered command without any args
		Commands.List.help();
		return;		
	end	
	
	local args = {};
	for _, arg in ipairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end
	
	local path = Commands.List; -- required for updating found table.
	
	for id, arg in ipairs(args) do
		if (#arg > 0) then -- if string length is greater than 0.
			arg = arg:lower();			
			if (path[arg]) then
				if (type(path[arg]) == "function") then				
					-- all remaining args passed to our function
					path[arg](addon, select(id + 1, unpack(args)));
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg]; -- another sub-table found!
				end
			else
				-- does not exist!
				addon:Print("|cffff0000Command does not exist.|r");
				Commands.List.help();
				return;
			end
		end
	end
end

function Commands:initCommands()
    -- For debugin prepuses
    SLASH_FRAMESTAK1 = "/fs";
    SlashCmdList.FRAMESTAK = function()
        LoadAddOn("Blizzard_DebugTools");
        FrameStackTooltip_Toggle();    
    end

    SLASH_ClassHallAccountReporter1 = "/char";
    SLASH_ClassHallAccountReporter2 = "/classhallaccountreporter";
    SlashCmdList.ClassHallAccountReporter = HandleSlashCommands;
end