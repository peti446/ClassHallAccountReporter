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
	addon:Print("|cff188E01/char showKeyInfo <character>|r - Toggles between showing the characters keystone or nomi's burned food order :) in the summary frame.");
	addon:Print("|cff188E01/char showKeyInfo all <true/false>|r - Active or desactive the keystone information for all characters.");
	addon:Print("|cff188E01/char showKeyInfo this|r - Toggles between showing the characters keystone or nomi's burned food order :) in the summary frame for this character.");
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

function Commands:ActivateShowKeystone(character, active)
	--Check if character is given
	if(not character) then
		addon:Print("|cffff0000Invalid command argument....|r");
		Commands:helpOutput();
		return;
	end

	if(character ~= "all" and character ~= "this") then
		--Check if character is valid
		if(type(addon.DataToSave.charactersDatabase.characters[character]) ~= "table") then
			addon:Print("Character not found in the database... Please type a valid charcater name.");
			addon:Print("Remember that te format is: name-server.");
			addon:Print("You can always open the sumary frame of the addon and copy the name as its there.");
			addon:Print("If the character exists but is not been shown in the frame, log-in with the character first and then log out, then try the command again.");
			return;
		end

		--Show the keystone for the character
		addon.DataToSave.charactersDatabase.characters[character].showKeystone = not addon.DataToSave.charactersDatabase.characters[character].showKeystone;
	else
		if(character == "all") then
			for name, v in pairs(addon.DataToSave.charactersDatabase.characters) do
				local bool = false;
				if(active == "true") then
					bool = true;
				end
				v.showKeystone = bool;
			end
		elseif(character == "this") then
			local name = select(1, UnitName("player")).."-"..GetRealmName();
			addon.DataToSave.charactersDatabase.characters[name].showKeystone = not addon.DataToSave.charactersDatabase.characters[name].showKeystone;
		end
	end
	--Update character info
	addon.ReportUI:updateFrameCharacterInfo(true);

end

function Commands:ToggleMinimapIcon()
	local boolIsShown = addon.MinimapIcon.frame:IsShown();
	addon.MinimapIcon.frame:SetShown(not boolIsShown);
	addon.DataToSave.options.showMinimapIcon = addon.MinimapIcon.frame:IsShown();
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
	["showkeyinfo"] = Commands.ActivateShowKeystone,
	["toggleMinimapIcon"] = Commands.ToggleMinimapIcon
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