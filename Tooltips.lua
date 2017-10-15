--############################################
-- Namespace
--############################################
local _, addon = ...;

addon.Tooltips = {};
local Tooltips = addon.Tooltips;
CHARTOOLTIPSGLOBAL = addon.Tooltips;

function Tooltips:on_EnterToopHead(self)
	GameTooltip:SetOwner(self, "ANCHOR_NONE");
	GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 5);
    GameTooltip:SetText("|cFFFFFFFF"..self.name);
    GameTooltip:AddLine(" ");
    local count = 0;
    if(self.tooltip.shipment) then
        GameTooltip:AddLine("Training troops:");
        GameTooltip:AddLine("Ready to Colect: |cFF3AFF00" .. self.tooltip.shipment.ready .. "|r");
        count = count + self.tooltip.shipment.total;
        if(self.tooltip.shipment.total-self.tooltip.shipment.ready > 0) then
            GameTooltip:AddLine("Total in training: |cFFff6600" .. self.tooltip.shipment.total .. "|r");
        end
        GameTooltip:AddLine(" ");
    end


    for fid, das in pairs(self.tooltip.durability) do
        count = count + 1;
        local durabilityColorStr = "|cFF3AFF00";
        if(das.durability == 1) then
            durabilityColorStr = "|cFFFF0000";
        elseif(das.durability < self.tooltip.maxDurability) then
            durabilityColorStr = "|cFFFF8F00";
        end
        GameTooltip:AddLine("Durability: " .. durabilityColorStr .. das.durability .. "/" .. self.tooltip.maxDurability .. " |r- |cFF42ebf4" .. ((self.tooltip.timeLeft[fid]) or "|r|cFF3AFF00Standby") .. "|r"); 
    end
    
    if(count == 0) then
        GameTooltip:AddLine("No Troops Available...");
        GameTooltip:AddLine("Recruit more troops!")
    elseif(count < self.tooltip.maxCount) then
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine("You can recruit |cFFff0000" .. (self.tooltip.maxCount-count) .. "|r more troop".. (count == 1 and "" or "s") .."!");
        GameTooltip:AddLine("Visit you Class Hall to start the recuitment")
    end
	GameTooltip:Show();
end

function Tooltips:on_EnterSealsInfo(self)
	GameTooltip:SetOwner(self, "ANCHOR_NONE");
	GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 5);
    GameTooltip:SetText("|cFFFFFFFF Seals of Broken Fate");
    local qcompleted = 0;
    if(self.canGetSeals) then
        if(self.questCompleated ~= nil and next(self.questCompleated) ~= nil) then
            GameTooltip:AddLine(" ");
            GameTooltip:AddLine("Missions Compleated:");
            for id, info in pairs(self.questCompleated) do
                qcompleted = qcompleted +1;
                GameTooltip:AddLine("|cFFFFFFFF" .. info.name .. "|r - " .. info.costStr);
            end
        end
        if(qcompleted < 3) then
            GameTooltip:AddLine(" ");
            local questLeftToCompleat = 3 - qcompleted;
            GameTooltip:AddLine("You can obtain: |cFF3AFF00" .. questLeftToCompleat .. " |rmore seals this week.");
            if(self.seals < 6) then
                GameTooltip:AddLine("Get to dalaran and get those seals!");
                if(self.seals > (6 - questLeftToCompleat)) then
                    GameTooltip:AddLine(" ");
                    GameTooltip:AddLine("You only have space for: |cFF3AFF00" .. (6-self.seals) .. "|r seals.");
                end
            else
                GameTooltip:AddLine("You are full of seals, spend some and restock you seals!");
                GameTooltip:AddLine("If not you will lose |cFFFF0000" .. questLeftToCompleat .. " |rseals...!");
            end
        end
    else
        GameTooltip:AddLine("You can currently not ger any seals!");
        GameTooltip:AddLine("Maybe this character is not lvl 110 :P!")
    end
    GameTooltip:Show();
end

function Tooltips:on_EnterMissionReward(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if (self.itemID) then
        GameTooltip:SetItemByID(self.itemID);
        return;
    end
    if (self.currencyID and self.currencyID ~= 0) then
        GameTooltip:SetCurrencyByID(self.currencyID);
        return;
    end
    if (self.title) then
        GameTooltip:SetText(self.title);
    end
    if (self.tooltip) then
        GameTooltip:AddLine(self.tooltip, 1, 1, 1, true);
    end
end

function Tooltips:on_Leave()
    GameTooltip:Hide();
end