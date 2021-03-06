--############################################
-- Namespace
--############################################
local _, addon = ...;

local ReportUI = addon.ReportUI;

local myticsChestRewards = {
    [0] = "|cFFFF0000NONE|r",
    [2] = 905,
    [3] = 910,
    [4] = 915,
    [5] = 920,
    [6] = 920,
    [7] = 925,
    [8] = 925,
    [9] = 930,
    [10] = 935,
    [11] = 940,
    [12] = 945,
    [13] = 950,
    [14] = 955,
    [15] = 960,
};

function ReportUI:updateFrameCharacterInfo(silent)
    if(type(silent) ~= "boolean") then
        silent = false;
    end
    if(not ReportUI.ReportFrame) then
        return;
    end
    for name, values in pairs(ReportUI.ReportFrame.charactersFrames) do
        if(values:IsShown()) then
            local frame = values.infoFrame;
            local characterInfo = addon.DataToSave.charactersDatabase.characters[name];

            --We only need to update currencies if we are online with the caracters, as oflines caharacters currencies will never change
            if(characterInfo == addon.CurrentCharacterInfo) then
                ReportUI:UpdateCurrencies(frame, characterInfo);
                addon:StoreKeyInformation("commandSearch");
            end


            --Update in progress Missions
            local InProgressSummaryData = {
                ["total"] = 0,
                ["available"] = 0,
                ["compeated"] = 0,
                ["lowestDuration"] = -1
            };

            local activeMissionsCount = 0;
            local followersTimeLeftInMission = {};
            for i, misFrame in pairs(frame.BigInfoFrame.ProgressMissionsArray) do
                if(not characterInfo.activeMissions[i])then
                    local nextFrame = misFrame.childMissFrame;
                    local parent = misFrame:GetParent();
                    local framePoint = misFrame; 
                    while not parent:IsShown() do
                        if(parent:GetParent() == nil) then
                            break;
                        end
                        framePoint = parent;
                        parent = parent:GetParent();
                    end
                    if(nextFrame ~= nil) then
                        nextFrame:ClearAllPoints();
                        nextFrame:SetParent(parent);
                        local point, relativeTo, relativePoint, x, y = framePoint:GetPoint(1);
                        nextFrame:SetPoint(point, parent, relativePoint, x, y);
                    end
                    misFrame:Hide();
                    frame.BigInfoFrame.ProgressMissionsArray[i] = nil;
                end
            end
            
            --Create new Missions frames if necessary
            local lastMissionFrame = frame.BigInfoFrame.ProgressMissionsArray[#frame.BigInfoFrame.ProgressMissionsArray];
            local ProgresssMissionsscrollChild = frame.BigInfoFrame.ProgresssMissionsScrollFrame;
            if(#frame.BigInfoFrame.ProgressMissionsArray <= 0) then
                lastMissionFrame = ProgresssMissionsscrollChild;
            end
            for i, miss in addon:SortMissions(characterInfo.activeMissions) do
                --Only create new frame if it does not exists
                if(frame.BigInfoFrame.ProgressMissionsArray[miss.name] == nil) then
                    frame.BigInfoFrame.ProgressMissionsArray[miss.name] = ReportUI:CreateMissionFrame(lastMissionFrame);
                    if (lastMissionFrame == ProgresssMissionsscrollChild) then
                        frame.BigInfoFrame.ProgressMissionsArray[miss.name]:ClearAllPoints();
                        frame.BigInfoFrame.ProgressMissionsArray[miss.name]:SetPoint("TOPLEFT", ProgresssMissionsscrollChild, "TOPLEFT", 0, 0);
                    end 
                    ProgresssMissionsscrollChild:SetHeight(ProgresssMissionsscrollChild:GetHeight()+frame.BigInfoFrame.ProgressMissionsArray[miss.name]:GetHeight()+math.abs(select(5,frame.BigInfoFrame.ProgressMissionsArray[miss.name]:GetPoint(1)) or 0));
                    lastMissionFrame = frame.BigInfoFrame.ProgressMissionsArray[miss.name];
                    lastMissionFrame.TimeLeft:Hide();
                    lastMissionFrame.Status:Hide();
                end
                ReportUI:updateMission(frame.BigInfoFrame.ProgressMissionsArray[miss.name], characterInfo.activeMissions[miss.name], followersTimeLeftInMission, InProgressSummaryData);
                activeMissionsCount = activeMissionsCount +1;
            end
            
            --Update troops heads
            for Troopname, troopHead in pairs(frame.troopHeads) do
                local troopInfo = characterInfo.troops[Troopname];
                ReportUI:updateTroopsHead(troopHead, Troopname, troopInfo, followersTimeLeftInMission);
            end

            for id, ttable in pairs(characterInfo.troopsInTraining) do
                if(frame.troopHeads[ttable.name] ~= nil) then
                    ReportUI:updateTroopsHeadTooltip(frame.troopHeads[ttable.name], ttable);
                end
            end

            --Update available Missions
            local amountOfMissions = 0;
            for i, misFrame in pairs(frame.BigInfoFrame.AvailableMissionsArray) do
                if(characterInfo.availableMissions[i]) then
                    ReportUI:UpdateAvlMissions(misFrame, characterInfo.availableMissions[i]);
                else
                    local nextFrame = misFrame.childMissFrame;
                    local parent = misFrame:GetParent();
                    local framePoint = misFrame; 
                    while not parent:IsShown() do
                        if(parent:GetParent() == nil) then
                            break;
                        end
                        framePoint = parent;
                        parent = parent:GetParent();
                    end
                    if(nextFrame ~= nil) then
                        nextFrame:ClearAllPoints();
                        nextFrame:SetParent(parent);
                        local point, relativeTo, relativePoint, x, y = framePoint:GetPoint(1);
                        nextFrame:SetPoint(point, parent, relativePoint, x, y);
                    end
                    misFrame:Hide();
                    frame.BigInfoFrame.AvailableMissionsArray[i] = nil;
                end
                if(misFrame:IsShown()) then
                    amountOfMissions = amountOfMissions +1;
                end
            end

            --Create new available Missions frame if neccecary
            lastMissionFrame = frame.BigInfoFrame.AvailableMissionsScrollFrame;
            if(#frame.BigInfoFrame.AvailableMissionsArray > 0) then
                lastMissionFrame = frame.BigInfoFrame.AvailableMissionsArray[#frame.BigInfoFrame.AvailableMissionsArray];
            end
            local availableMissionsCount = 0;
            for i, miss in pairs(characterInfo.availableMissions) do
                if(frame.BigInfoFrame.AvailableMissionsArray[miss.name] == nil) then
                    if(not miss.offerEndTime or (miss.offerEndTime + miss.timeInfoCollected) > time()) then
                        frame.BigInfoFrame.AvailableMissionsArray[miss.name] = ReportUI:CreateMissionFrame(lastMissionFrame);
                        if (lastMissionFrame == AvailableMissionsscrollChild) then
                            frame.BigInfoFrame.AvailableMissionsArray[miss.name]:ClearAllPoints();
                            frame.BigInfoFrame.AvailableMissionsArray[miss.name]:SetPoint("TOPLEFT", AvailableMissionsscrollChild, "TOPLEFT", 0, 0);
                        end
                        AvailableMissionsscrollChild:SetHeight(AvailableMissionsscrollChild:GetHeight()+frame.BigInfoFrame.AvailableMissionsArray[miss.name]:GetHeight()+math.abs(select(5,frame.BigInfoFrame.AvailableMissionsArray[miss.name]:GetPoint(1)) or 0));
                        lastMissionFrame = frame.BigInfoFrame.AvailableMissionsArray[miss.name];
                        lastMissionFrame.TimeLeft:Hide();
                        ReportUI:UpdateAvlMissions(lastMissionFrame, characterInfo.availableMissions[i]);
                        if(lastMissionFrame:IsShown()) then
                            amountOfMissions = amountOfMissions +1;
                        end
                    end
                end
                availableMissionsCount = availableMissionsCount +1;
            end

            frame.BigInfoFrame.AvailableText:SetText("Available Missions".." (".. availableMissionsCount.."):");
            frame.BigInfoFrame.ProgressText:SetText("Missions Inprogress".." (".. activeMissionsCount.."):");
            --Update followers text
            for fid, followerFrame in pairs(frame.BigInfoFrame.FollowersArray) do
                addon.FollowersHelper:SetStatusText(followerFrame, characterInfo.followers[fid].status,followersTimeLeftInMission[fid])  
            end

            --Todo check  value.mSummaryFrame
            if(characterInfo.mSummaryFrame == "cook") then
                frame.SumarryText:SetText("Cooking Orders:");
                ReportUI:updateCooking(frame.mSummaryFrame, characterInfo);
            elseif(characterInfo.mSummaryFrame == "keystone") then
                frame.SumarryText:SetText("Keystone in Bag:");
                ReportUI:updateKeystoneInfo(frame.mSummaryFrame, characterInfo.mytics.Keystone);
            elseif(characterInfo.mSummaryFrame == "hallmissions") then
                frame.SumarryText:SetText("Missions Summary:");
                InProgressSummaryData.total = activeMissionsCount;
                InProgressSummaryData.available = availableMissionsCount;
                ReportUI:updateInProgressMissions(frame.mSummaryFrame, InProgressSummaryData);
            end

            --Update Mytics +
            local higestLevel = 0;
            local name = nil;
            for id, subtable in pairs(characterInfo.mytics.list) do
                for i, minfo in ipairs(subtable) do
                    if(higestLevel < minfo.level) then
                        higestLevel = minfo.level;
                        name = C_ChallengeMode.GetMapUIInfo(id);
                    end
                end
            end
            if(higestLevel > 15) then
                frame.BigInfoFrame.WeeklyReward:SetText("Min Chest Reward: |cFFffb600" .. myticsChestRewards[15] .. "|r");
            else 
                frame.BigInfoFrame.WeeklyReward:SetText("Min Chest Reward: |cFFffb600" .. myticsChestRewards[higestLevel] .. "|r");     
            end
            if(higestLevel == 0) then
                higestLevel = "|cFFFF0000NONE|r";
                name = "|cFFFF0000NONE|r";
            end
            frame.BigInfoFrame.BestName:SetText("Name: |cFFffb600"..(name or "Invalid ID ?").. "|r");
            frame.BigInfoFrame.Bestlvl:SetText("Mytic lvl: |cFFffb600"..higestLevel.."|r");
            frame.BigInfoFrame.chestTexture:SetShown(characterInfo.mytics.ChestAvailable);

        end
    end
    --Update all missions icons
    ReportUI:updateMissionsIcon();
    if(silent) then
        return;
    end
    addon:Print("Data Refreshed!");
end

function ReportUI:toggleFrame()
    local frame = ReportUI.ReportFrame or ReportUI:createReportFrame();
    ReportUI:updateFrameCharacterInfo(true);
    frame:SetShown(not frame:IsShown());
end


function ReportUI:UpdateCurrencies(frame, v)
    frame.CharacterIlvl:SetText(tonumber(string.format("%." .. (0) .. "f", v.pilvl or 0)));
    frame.GoldQuantity:SetText(tonumber(string.format("%." .. (0) .. "f", v.currency.gold or 0)));
    frame.OrderResourcesQuantity:SetText(v.currency.HallResources or "0");
    frame.sealFrame.SealsQuantity:SetText((v.currency.SealsOfBrokenFate or "0").."/6");
    frame.sealFrame.questCompleated = v.currency.SealsMissionsCompleted;
    frame.sealFrame.seals = (v.currency.SealsOfBrokenFate or 0);
    frame.sealFrame.canGetSeals = (v.plevel == 110);
    frame.BloodOfSargerasQuantity:SetText(v.currency.bloodOfSargeras or "0");
    frame.WakeningEssenceQuantity:SetText(v.currency.WakeningEssence or "0");
    frame.CuriousCoinQuantity:SetText(v.currency.curiouscoin or "0");
    frame.VeiledArguniteQuantity:SetText(v.currency.veiledargunite or "0");
end

function ReportUI:UpdateMissionsReward(f, reward, index)
    local RewardButton = f.Rewards[index];
    RewardButton.Quantity:Hide();
    RewardButton.Quantity:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
    RewardButton.bonusAbilityID = nil;
    RewardButton.bonusAbilityDuration = nil;
    RewardButton.bonusAbilityIcon = nil;
    RewardButton.bonusAbilityName = nil;
    RewardButton.bonusAbilityDescription = nil;
    RewardButton.currencyID = nil;
    RewardButton.currencyQuantity = nil;
    if (reward.itemID) then
        RewardButton.itemID = reward.itemID;
        local _, _, quality, _, _, _, _, _, _, itemTexture = GetItemInfo(reward.itemID);
        RewardButton.Icon:SetTexture(itemTexture);
        --SetItemButtonQuality(RewardButton, quality, reward.itemID);					
        if (reward.quantity > 1) then
            RewardButton.Quantity:SetText(reward.quantity);
            RewardButton.Quantity:Show();
        end					
    else
        RewardButton.itemID = nil;
        RewardButton.Icon:SetTexture(reward.icon);
        RewardButton.title = reward.title
        if (reward.currencyID and reward.quantity) then
            if (reward.currencyID == 0) then
                RewardButton.tooltip = GetMoneyString(reward.quantity);
                RewardButton.Quantity:SetText(BreakUpLargeNumbers(floor(reward.quantity / COPPER_PER_GOLD)));
                RewardButton.Quantity:Show();
            else
                local _, _, currencyTexture = GetCurrencyInfo(reward.currencyID);
                RewardButton.tooltip = BreakUpLargeNumbers(reward.quantity).." |T"..currencyTexture..":0:0:0:-1|t ";
                RewardButton.currencyID = reward.currencyID;
                RewardButton.currencyQuantity = reward.quantity;
                RewardButton.Quantity:SetText(reward.quantity);
                local currencyColor = GetColorForCurrencyReward(reward.currencyID, reward.quantity);
                RewardButton.Quantity:SetTextColor(currencyColor:GetRGB());
                RewardButton.Quantity:Show();
            end
        elseif (reward.bonusAbilityID) then
            RewardButton.bonusAbilityID = reward.bonusAbilityID;
            RewardButton.bonusAbilityDuration = reward.duration;
            RewardButton.bonusAbilityIcon = reward.icon;
            RewardButton.bonusAbilityName = reward.name;
            RewardButton.bonusAbilityDescription = reward.description;
        else
            RewardButton.tooltip = reward.tooltip;
            if ( reward.followerXP ) then
                RewardButton.Quantity:SetText(reward.followerXP);
                RewardButton.Quantity:Show();
            end		
        end
    end
    RewardButton:Show();
end

function ReportUI:updateMission(lastMissionFrame, miss, followersTimeLeftInMission, missionsData)
    --Set title
    lastMissionFrame.Title:SetText(miss.name);
    --Set atlas icon
    lastMissionFrame.MissionTypeIcon:SetAtlas(miss.typeAtlas);
    lastMissionFrame.MissionTypeIcon:SetSize(40, 40);
    lastMissionFrame.MissionTypeIcon:SetPoint("TOPLEFT", 5, -3);

    --Set rewards
    local rewardIndex = 1;
    lastMissionFrame.rewardsIndex = 1;
    for id, reward in pairs(miss.rewards) do
        ReportUI:UpdateMissionsReward(lastMissionFrame, reward, rewardIndex);
        rewardIndex = rewardIndex +1;
    end
    lastMissionFrame.rewardsIndex = rewardIndex;
    --Set the background atlas for the current mission status
    if (miss.missionEndTime <= time()) then
        missionsData.compeated = missionsData.compeated + 1;
        lastMissionFrame.BG:SetAtlas("GarrLanding-Mission-Complete");
        lastMissionFrame.MissionType:SetTextColor(1, 1, 0);
        lastMissionFrame.MissionType:SetText("Mission completed!");
        for i = 1, #lastMissionFrame.Rewards do
            lastMissionFrame.Rewards[i]:Hide();
        end
        for int, fid in ipairs(miss.followers) do
            followersTimeLeftInMission[fid] = "Finished.";
        end
    else
        lastMissionFrame.BG:SetAtlas("GarrLanding-Mission-InProgress");
        -- Set missions time left to complete
        local seconds = miss.missionEndTime - time();
        if(missionsData.lowestDuration == -1 or missionsData.lowestDuration > seconds) then
            missionsData.lowestDuration = seconds;
        end
        --Set mission duration
        lastMissionFrame.MissionType:SetTextColor(0.78, 0.75, 0.73);
        lastMissionFrame.MissionType:SetText("Completed in: " .. addon:convertSecondToTimeStr(seconds));
        for int, fid in ipairs(miss.followers) do
            followersTimeLeftInMission[fid] = addon:convertSecondToTimeStr(seconds);
        end
    end
end

function ReportUI:UpdateAvlMissions(lastMissionFrame, miss)
    if(miss.offerEndTime == nil or miss.offerEndTime+miss.timeInfoCollected >= time()) then
        lastMissionFrame.Title:SetText(miss.name);
        --Set atlas icon
        lastMissionFrame.MissionTypeIcon:SetAtlas(miss.typeAtlas);
        lastMissionFrame.MissionTypeIcon:SetSize(40, 40);
        lastMissionFrame.MissionTypeIcon:SetPoint("TOPLEFT", 5, -3);

        --Set mission duration
        lastMissionFrame.MissionType:SetTextColor(0.78, 0.75, 0.73);
        if (miss.durationSeconds >= 28800) then
            lastMissionFrame.MissionType:SetFormattedText("|cffff7d1a%s|r", miss.duration);
        else
            lastMissionFrame.MissionType:SetText(miss.duration);
        end

        if(miss.offerEndTime) then
            -- Set expire time
            local secondsToExpire = (miss.offerEndTime+miss.timeInfoCollected) - time();
            lastMissionFrame.Status:SetText("Expires in:" .. addon:convertSecondToTimeStr(secondsToExpire));
        else
            lastMissionFrame.Status:SetText("Never Expires");
        end

        --Set rewards
        local rewardIndex = 1;
        lastMissionFrame.rewardsIndex = 0;
        for id, reward in pairs(miss.rewards) do
            ReportUI:UpdateMissionsReward(lastMissionFrame, reward, rewardIndex);
            rewardIndex = rewardIndex + 1;
        end
        lastMissionFrame.rewardsIndex = rewardIndex;
    else
        lastMissionFrame:Hide();
    end
end

function ReportUI:updateTroopsHead(lastTroopFrame, troopName, troopInfo, timeLeft)
    lastTroopFrame.TroopInfoIcon:SetTexture(troopInfo.iconID);
    local troopsColorString = "|cFF3AFF00";
    if(troopInfo.currentCount == 0) then
        troopsColorString = "|cFFFF0000";
    elseif(troopInfo.currentCount < troopInfo.maxCount) then
        troopsColorString = "|cFFFF8F00";
    end
    lastTroopFrame.TroopInfoString:SetText(troopsColorString .. troopInfo.currentCount.."/"..troopInfo.maxCount);
    lastTroopFrame.name = troopName;
    lastTroopFrame.tooltip = lastTroopFrame.tooltip or {};
    wipe(lastTroopFrame.tooltip);
    if(type(lastTroopFrame.tooltip) ~= "table") then
        lastTroopFrame.tooltip = {};
    end
    lastTroopFrame.tooltip.maxCount = troopInfo.maxCount;
    lastTroopFrame.tooltip.maxDurability = troopInfo.maxDurability;
    lastTroopFrame.tooltip.durability = {};
    lastTroopFrame.tooltip.timeLeft = {};
    for fid, tinfo in pairs (troopInfo.troopsArray) do
        lastTroopFrame.tooltip.timeLeft[fid] = timeLeft[fid];
        lastTroopFrame.tooltip.durability[fid] = {};
        lastTroopFrame.tooltip.durability[fid].durability = tinfo.currentDurability;
        lastTroopFrame.tooltip.durability[fid].status = tinfo.status or nil;
    end
end

function ReportUI:updateTroopsHeadTooltip(f, ttable)
    addon:fixShipmentsInfo(ttable);
    local troopFrameTooltip = f.tooltip;
    troopFrameTooltip.shipment = {};
    troopFrameTooltip.shipment.total = ttable.shipmentsTotal;
    troopFrameTooltip.shipment.creationTime = ttable.creationTime;
    troopFrameTooltip.shipment.duration = ttable.duration;
    troopFrameTooltip.shipment.ready = ttable.shipmentsReady;
    troopFrameTooltip.shipment.max = ttable.shipmentCapacity;
    
    if(ttable.shipmentsTotal ~= ttable.shipmentsReady) then
        f.Swipe:Show();
        f.Done:Hide();
        f.Swipe:SetCooldownUNIX(ttable.creationTime, ttable.duration*(ttable.shipmentsTotal - ttable.shipmentsReady));
    else
        f.Done:Show();
        f.Swipe:Hide();
    end
end

function ReportUI:updateCooking(frame , v)
    frame.Icon:SetTexture("Interface\\ICONS\\INV_RECIPE_70_ Scroll3Star");
    frame.firstLine:SetText(" ");
    frame.secondLine:SetText(" ");
    frame.thirdLine:SetText(" ");
    --Set the cooking shipments
    if(v.shipments[122].QuestCompleated == true) then
        if(v.shipments[122].shipmentsReady ~= nil) then
            addon:fixShipmentsInfo(v.shipments[122]);
            local ordersmsg = v.shipments[122].shipmentsReady.."/"..v.shipments[122].shipmentsTotal.. " ready Orders.";
            if(timeLeft == "" or v.shipments[122].duration == 0 or v.shipments[122].shipmentsTotal == 0) then
                frame.thirdLine:SetText("All Ready!");
            else
                frame.thirdLine:SetText(addon:convertSecondToTimeStr((v.shipments[122].shipmentsTotal*v.shipments[122].duration)-(v.shipments[122].shipmentsReady*v.shipments[122].duration)));
            end
            if(v.shipments[122].shipmentsTotal < v.shipments[122].shipmentCapacity) then
                frame.firstLine:SetText(ordersmsg);
                frame.secondLine:SetText((v.shipments[122].shipmentCapacity-v.shipments[122].shipmentsTotal) .. " orders ready to start.");
            else
                frame.secondLine:SetText(ordersmsg);
            end
        else
            frame.secondLine:SetText("24 orders ready to start.");
        end
    else
        frame.secondLine:SetText("Complete quest first!");
    end
end


function ReportUI:updateKeystoneInfo(frame, keystoneInfo)
    --Update icon
    frame.Icon:SetTexture("Interface\\ICONS\\INV_Relics_Hourglass");
    frame.firstLine:SetText(" ");
    frame.secondLine:SetText(" ");
    frame.thirdLine:SetText(" ");

    --If no mapID is available, there will be no other information so no keystone stored )=
    if(keystoneInfo.mapID == nil) then
        frame.firstLine:SetText("");
        frame.secondLine:SetText("|cFFFF0000No keystone.|r");
        frame.thirdLine:SetText("");
        return;
    end

    --There is a keystone lets print the information
    frame.firstLine:SetText("|cffa335ee".. C_ChallengeMode.GetMapUIInfo(keystoneInfo.mapID) .. "|r");
    frame.secondLine:SetText("Level " .. keystoneInfo.level);
    name1, description1 = C_ChallengeMode.GetAffixInfo(keystoneInfo.afix1);
    name2, description2 = C_ChallengeMode.GetAffixInfo(keystoneInfo.afix2);
    name3, description3 = C_ChallengeMode.GetAffixInfo(keystoneInfo.afix3);
    local finalString = "No affixes :)!";
    if(name1) then
        finalString = name1;
        if(name2) then
            finalString = finalString .. ", " .. name2;
            if(name3) then
                finalString = finalString .. ", " .. name3;
            end
        end
    end
    frame.thirdLine:SetText(finalString);

end

function ReportUI:updateInProgressMissions(frame, InProgressMissions)
    --Update icon
    frame.Icon:SetTexture("Interface\\ICONS\\INV_Bijou_Bronze");
    frame.firstLine:SetText(" ");
    frame.secondLine:SetText(" ");
    frame.thirdLine:SetText(" ");
    if(InProgressMissions.total ~= 0) then
        frame.secondLine:SetText("Compleated: " .. InProgressMissions.compeated .. " / " .. InProgressMissions.total);
        if(InProgressMissions.lowestDuration > 0 ) then
            frame.thirdLine:SetText("Next finishes in: " .. addon:convertSecondToTimeStr(InProgressMissions.lowestDuration));
            if(InProgressMissions.lowestDuration > 18000) then
                frame.Icon:SetTexture("Interface\\ICONS\\INV_Bijou_Red");
            elseif(InProgressMissions.lowestDuration > 10800) then 
                frame.Icon:SetTexture("Interface\\ICONS\\INV_Bijou_Orange");
            else
                frame.Icon:SetTexture("Interface\\ICONS\\INV_Bijou_Yellow");
            end
        end
    else 
        frame.secondLine:SetText("No missions in progress.");
        frame.thirdLine:SetText("Available missions: " .. InProgressMissions.available);
    end
    if(InProgressMissions.total == InProgressMissions.compeated) then
        frame.Icon:SetTexture("Interface\\ICONS\\INV_Bijou_Green");
    end
end