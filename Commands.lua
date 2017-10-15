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
    addon:Print("--------- List of commands: ---------");
    addon:Print("/char help - Shows all commands");
    addon:Print("/char show - Shows the Report frame");
	addon:Print("/char reset - Resets all the information");
	addon:Print("/char debug - Enables Debug mode");
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

--##########################################################################################################################
--                                  Commands handling
--##########################################################################################################################

Commands.List = {
    ["help"] = Commands.helpOutput,
    ["show"] = addon.ReportUI.toggleFrame,
	["reset"] = addon.ReportUI.deleteAllData,
	["debug"] = Commands.toggleDebug,
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
					-- all remaining args passed to our function!
					path[arg](select(id + 1, unpack(args))); 
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg]; -- another sub-table found!
				end
			else
				-- does not exist!
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