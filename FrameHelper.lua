--############################################
-- Namespace
--############################################
local _, addon = ...;

addon.ReportUI = {};
local ReportUI = addon.ReportUI;
ReportUI.ReportFrame = nil;

--Function to calculate the text coord
local function getClassTextCoord(x,y)
    return {
        ((4+(x*92))/512)+((1/512)/2),
        ((88+(x*92))/512)-((1/512)/2),
        ((65+(y*89))/512)+((1/512)/2),
        ((146+(y*89))/512)-((1/512)/2)
    };
end

addon.ReportUI.classTextureCoords = {
    ["WARRIOR"] =getClassTextCoord(1,3),
    ["PALADIN"] = getClassTextCoord(2,0),
    ["HUNTER"] = getClassTextCoord(0,3),
    ["ROGUE"] = getClassTextCoord(4,0),
    ["PRIEST"] = getClassTextCoord(3,0),
    ["DEATHKNIGHT"] = getClassTextCoord(0,0),
    ["SHAMAN"] = getClassTextCoord(1,1),
    ["MAGE"] = getClassTextCoord(0,4),
    ["WARLOCK"] = getClassTextCoord(1,2),
    ["MONK"] = getClassTextCoord(1,0),
    ["DRUID"] = getClassTextCoord(0,2),
    ["DEMONHUNTER"] = getClassTextCoord(0,1)
};


function ReportUI:deleteAllData()
    addon.DataToSave.charactersDatabase.characters = {};
    addon.CurrentCharacterInfo = {};
    addon:prepareCharacterDataBase();
    for name, frame in pairs(ReportUI.ReportFrame.charactersFrames) do
        frame:Hide();
    end
    addon:Print("All character data deleted!");
    ReportUI:updateFrameCharacterInfo();
end

function ReportUI:deleteCharacter()
    ReportUI.ReportFrame.charactersFrames[self.character]:Hide();
    wipe(addon.DataToSave.charactersDatabase.characters[self.character]);
    addon.DataToSave.charactersDatabase.characters[self.character] = nil;
end

function ReportUI:updateMissionsIcon()
    local needInfoUpdate = false;
    for name, info in pairs(ReportUI.ReportFrame.charactersFrames) do
        for i, v in pairs(info.infoFrame.BigInfoFrame.AvailableMissionsArray) do
            if(v.rewardsIndex ~= nil) then
                for index=1,v.rewardsIndex do
                    local RewardButton = v.Rewards[index];
                    if (RewardButton.itemID) then
                        local _, _, quality, _, _, _, _, _, _, itemTexture = GetItemInfo(RewardButton.itemID);
                        RewardButton.Icon:SetTexture(itemTexture);
                        SetItemButtonQuality(RewardButton, quality, RewardButton.itemID);
                        if(not quality or not itemTexture) then
                            needInfoUpdate = true;
                        end
                    end
                end
            end
        end
        for i, v in pairs(info.infoFrame.BigInfoFrame.ProgressMissionsArray) do
            if(v.rewardsIndex ~= nil) then
                for index=1,v.rewardsIndex do
                    local RewardButton = v.Rewards[index];
                    if (RewardButton.itemID) then
                        local _, _, quality, _, _, _, _, _, _, itemTexture = GetItemInfo(RewardButton.itemID);
                        RewardButton.Icon:SetTexture(itemTexture);
                        SetItemButtonQuality(RewardButton, quality, RewardButton.itemID);
                        if(not quality or not itemTexture) then
                            needInfoUpdate = true;
                        end
                    end
                end
            end
        end
    end
	if (needInfoUpdate) then
		if(not ReportUI.ReportFrame:IsEventRegistered("GET_ITEM_INFO_RECEIVED")) then
			ReportUI.ReportFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
		end
	else
		if (ReportUI.ReportFrame:IsEventRegistered("GET_ITEM_INFO_RECEIVED")) then
			ReportUI.ReportFrame:UnregisterEvent("GET_ITEM_INFO_RECEIVED");
		end
	end
end

function ReportUI:OnEvent(event, ...)
    if(event == "GET_ITEM_INFO_RECEIVED") then
        ReportUI:updateMissionsIcon();
    end
end

function ReportUI:createButton(point, parentFrame, relativeFrame, relativePoint, name, width, height, xOffSet, yOffSet, TextHeight)
    width = width or 140;
    height = height or 40;
    xOffSet = xOffSet or 0;
    yOffSet = yOffSet or 0;
    TextHeight = TextHeight or "";
    local button = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate");
    button:SetPoint(point, relativeFrame, relativePoint, xOffSet, yOffSet);
    button:SetSize(width,height);
    button:SetText(name);
    button:SetNormalFontObject("GameFontNormal"..TextHeight);
    button:SetHighlightFontObject("GameFontHighlight"..TextHeight);
    return button;
end

function ReportUI:RowClicked(button, down)
    for i,k in pairs(ReportUI.ReportFrame.charactersFrames) do
        if(k:GetParent() == self) then
            k:ClearAllPoints();
            if(not self.infoFrame.BigInfoFrame:IsShown()) then 
                k:SetPoint("TOPLEFT", self.infoFrame.BigInfoFrame, "BOTTOMLEFT", 0, select(5,self:GetPoint(1)) or -5);
            else
                k:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, select(5,self:GetPoint(1)) or -5);
            end
            break;
        end
    end
    self.BottomBar:SetShown(not self.BottomBar:IsShown());
    self.CornerRightBottom:SetShown(not self.CornerRightBottom:IsShown());
    self.CornerLeftBottom:SetShown(not self.CornerLeftBottom:IsShown());
    self.infoFrame.BigInfoFrame:SetShown(not self.infoFrame.BigInfoFrame:IsShown());
    local multiplier = 1;
    if(not self.infoFrame.BigInfoFrame:IsShown()) then
        multiplier = -1;
    end
    ReportUI.ReportFrame.characterList:GetScrollChild():SetHeight(ReportUI.ReportFrame.characterList:GetScrollChild():GetHeight() + (self.infoFrame.BigInfoFrame:GetHeight() * multiplier));
    -- Set the max vertical scroll range
    ReportUI.ReportFrame.characterList.ScrollBar:SetMinMaxValues(0, ReportUI.ReportFrame.characterList:GetVerticalScrollRange());
end

function ReportUI:createReportFrame()
    -- Create the Report Frame and set its size and position
    ReportUI.ReportFrame = CreateFrame("Frame", "CHARReportFrame", UIParent, "ButtonFrameTemplate");
    ReportUI.ReportFrame:SetSize(1109,540);
    ReportUI.ReportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150);
    ReportUI.ReportFrame:SetToplevel(true);

    -- Set Script
    ReportUI.ReportFrame:SetScript("OnEvent", ReportUI.OnEvent);

    --Set Closeable by ESC key
    tinsert(UISpecialFrames, ReportUI.ReportFrame:GetName());

    -- Set Title
    ReportUI.ReportFrame.TitleText:SetText("Class Hall Reporter");

    -- Set Portait Icon
    ReportUI.ReportFrame.portrait:SetTexture("Interface\\Garrison\\ClassHallFrame");
    ReportUI.ReportFrame.portrait:SetTexCoord(unpack(addon.ReportUI.classTextureCoords[select(2, UnitClass("player"))]));

    -- Make frame movable
    ReportUI.ReportFrame:SetMovable(true);
    ReportUI.ReportFrame:EnableMouse(true);
    ReportUI.ReportFrame:RegisterForDrag("RightButton");
    ReportUI.ReportFrame:SetScript("OnDragStart", ReportUI.ReportFrame.StartMoving);
    ReportUI.ReportFrame:SetScript("OnDragStop", ReportUI.ReportFrame.StopMovingOrSizing);

    -- Create refresh and delete all data button
    ReportUI.ReportFrame.RefreshDataButton = ReportUI:createButton("TOPRIGHT", ReportUI.ReportFrame, ReportUI.ReportFrame.Bg, "TOPRIGHT", "Refresh Data", 100, 25, -5, -8);
    ReportUI.ReportFrame.DeleeAllDataButton = ReportUI:createButton("TOPRIGHT", ReportUI.ReportFrame, ReportUI.ReportFrame.Bg, "TOPRIGHT", "Delete All Data", 110, 25, -125, -8);
    ReportUI.ReportFrame.RefreshDataButton:SetScript("OnClick", ReportUI.updateFrameCharacterInfo);
    ReportUI.ReportFrame.DeleeAllDataButton:SetScript("OnClick", ReportUI.deleteAllData);

    -- Create character list frame
    ReportUI.ReportFrame.characterList = CreateFrame("ScrollFrame", nil, CHARReportFrame, "UIPanelScrollFrameTemplate");
    ReportUI.ReportFrame.characterList:SetPoint("TOPRIGHT", ReportUI.ReportFrame.TopTileStreaks, "BOTTOMRIGHT", -6, -5);
    ReportUI.ReportFrame.characterList:SetPoint("BOTTOMLEFT", ReportUI.ReportFrame.leftBorderBar, "BOTTOMLEFT", 13, 19);
    scrollbar = CreateFrame("Slider", nil, ReportUI.ReportFrame.characterList, "UIPanelStretchableArtScrollBarTemplate");
    scrollbar:ClearAllPoints();
    scrollbar:SetPoint("TOPRIGHT", ReportUI.ReportFrame.characterList, "TOPRIGHT", -2, -20) ;
    scrollbar:SetPoint("BOTTOMRIGHT", ReportUI.ReportFrame.characterList, "BOTTOMRIGHT", 2, 16);
    scrollbar.Top:ClearAllPoints();
    scrollbar.Top:SetPoint("TOPLEFT", scrollbar.ScrollUpButton, "TOPLEFT", -4, 4);
    scrollbar.Bottom:ClearAllPoints();
    scrollbar.Bottom:SetPoint("BOTTOMLEFT", scrollbar.ScrollDownButton, "BOTTOMLEFT", -4, -1);
    scrollbar:SetMinMaxValues(0, 200);
    scrollbar:SetValueStep(30);
    scrollbar.scrollStep = 30;
    scrollbar:SetValue(0);
    scrollbar:SetWidth(16);
    scrollbar:SetScript("OnValueChanged", 
        function (self, value) 
            self:GetParent():SetVerticalScroll(value); 
        end
    ); 
    scrollbar.Background:SetColorTexture(0,0,0,0);
    ReportUI.ReportFrame.characterList.ScrollBar = scrollbar;

    -- Create the scroll child and set it to the scrollbar
    local scrollChild = CreateFrame("Frame", nil, ReportUI.ReportFrame.characterList);
    scrollChild:SetSize(ReportUI.ReportFrame:GetWidth()-35, 0);
    ReportUI.ReportFrame.characterList:SetScrollChild(scrollChild);
    ReportUI.ReportFrame.characterList:SetClipsChildren(true);

    --Checks if there is any character to show is there isnt any then just return the frmae ..
    if(addon.DataToSave.charactersDatabase.characters == nil or type(addon.DataToSave.charactersDatabase.characters) ~= "table") then
        ReportUI.ReportFrame:Hide();
        return ReportUI.ReportFrame;
    end


    --Create and set all the caracters frame
    local frame = scrollChild;
    ReportUI.ReportFrame.charactersFrames = {};
    for k,v in addon:SortcharacterList(addon.DataToSave.charactersDatabase.characters) do
        ReportUI.ReportFrame.charactersFrames[k] = CreateFrame("Button", nil, frame, "CHARCharacterRow");
        if(frame == scrollChild)then
            ReportUI.ReportFrame.charactersFrames[k]:ClearAllPoints();
            ReportUI.ReportFrame.charactersFrames[k]:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3);  
        end
        --Set the scroll child frame
        scrollChild:SetHeight(frame:GetHeight()+scrollChild:GetHeight()+math.abs(select(5,ReportUI.ReportFrame.charactersFrames[k]:GetPoint(1)) or 0));
        --Set on click event
        ReportUI.ReportFrame.charactersFrames[k]:SetScript("OnClick", ReportUI.RowClicked);

        frame = ReportUI.ReportFrame.charactersFrames[k].infoFrame;
        -- Set character info
        frame.ClassIcon:SetTexCoord(unpack(addon.ReportUI.classTextureCoords[v.pclassName]));
        frame.CharacterName:SetWidth(125);
        frame.CharacterName:SetWordWrap(false);
        frame.CharacterName:SetText("|c"..RAID_CLASS_COLORS[v.pclassName].colorStr .. k); 
        frame.CharacterLevel:SetText(v.plevel or "1");

        -- Currencies info of the characters
        ReportUI:UpdateCurrencies(frame, v);

        -- Set the troops info
        frame.troopHeads = {};
        local lastTroopFrame = frame;
        for troopName, troopInfo in pairs(v.troops) do
            frame.troopHeads[troopName] = CreateFrame("Frame", nil, lastTroopFrame, "CHARTroopsInfoDisplay");
            if(lastTroopFrame == frame) then
                frame.troopHeads[troopName]:ClearAllPoints();
                frame.troopHeads[troopName]:SetPoint("TOPLEFT", frame, "TOPLEFT", select(4,frame.TroopsText:GetPoint(1)), -21);
            end
            lastTroopFrame = frame.troopHeads[troopName];
        end

        -- Create the big info frame
        frame.BigInfoFrame = CreateFrame("Frame", nil, frame, "CHARCharacterInfoBox");

        --Create followers scroll frame
        frame.BigInfoFrame.FollowersListScrollFrame = CreateFrame("ScrollFrame", nil, frame.BigInfoFrame, "UIPanelScrollFrameTemplate");
        frame.BigInfoFrame.FollowersListScrollFrame:SetPoint("TOPLEFT", frame.BigInfoFrame, "TOPLEFT", 10, -20);
        frame.BigInfoFrame.FollowersListScrollFrame:SetPoint("BOTTOMLEFT", frame.BigInfoFrame, "BOTTOMLEFT", 5, 10);
        frame.BigInfoFrame.FollowersListScrollFrame.ScrollBar:SetPoint("TOPLEFT", frame.BigInfoFrame.FollowersListScrollFrame, "TOPRIGHT", -18, -16);
        frame.BigInfoFrame.FollowersListScrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", frame.BigInfoFrame.FollowersListScrollFrame, "BOTTOMRIGHT", -18, 25);
        frame.BigInfoFrame.FollowersListScrollFrame:SetSize(280,frame.BigInfoFrame:GetHeight()-20);
        local FollowersListscrollChild = CreateFrame("Frame", nil, frame.BigInfoFrame.FollowersListScrollFrame);
        FollowersListscrollChild:SetSize(260, 0);
        frame.BigInfoFrame.FollowersListScrollFrame:SetScrollChild(FollowersListscrollChild);
        frame.BigInfoFrame.FollowersListScrollFrame:SetClipsChildren(true);

        --Create In progresss mission scroll frame
        frame.BigInfoFrame.ProgresssMissionsScrollFrame = CreateFrame("ScrollFrame", nil, frame.BigInfoFrame, "UIPanelScrollFrameTemplate");
        frame.BigInfoFrame.ProgresssMissionsScrollFrame:SetPoint("TOP", frame.BigInfoFrame, "TOP", 0, -15);
        frame.BigInfoFrame.ProgresssMissionsScrollFrame:SetPoint("BOTTOM", frame.BigInfoFrame, "TOP", 0, -110);
        frame.BigInfoFrame.ProgresssMissionsScrollFrame.ScrollBar:SetPoint("TOPLEFT", frame.BigInfoFrame.ProgresssMissionsScrollFrame, "TOPRIGHT", -19, -16);
        frame.BigInfoFrame.ProgresssMissionsScrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", frame.BigInfoFrame.ProgresssMissionsScrollFrame, "BOTTOMRIGHT", -19, 16);
        frame.BigInfoFrame.ProgresssMissionsScrollFrame:SetSize(420,109);
        local ProgresssMissionsscrollChild = CreateFrame("Frame", nil, frame.BigInfoFrame.ProgresssMissionsScrollFrame);
        ProgresssMissionsscrollChild:SetSize(400, 0);
        frame.BigInfoFrame.ProgresssMissionsScrollFrame:SetScrollChild(ProgresssMissionsscrollChild);
        frame.BigInfoFrame.ProgresssMissionsScrollFrame:SetClipsChildren(true);

        --Create Available missions scroll frame
        frame.BigInfoFrame.AvailableMissionsScrollFrame = CreateFrame("ScrollFrame", nil, frame.BigInfoFrame, "UIPanelScrollFrameTemplate");
        frame.BigInfoFrame.AvailableMissionsScrollFrame:SetPoint("TOP", frame.BigInfoFrame, "TOP", 0, -161);
        frame.BigInfoFrame.AvailableMissionsScrollFrame:SetPoint("BOTTOM", frame.BigInfoFrame, "BOTTOM", 0, 10);
        frame.BigInfoFrame.AvailableMissionsScrollFrame.ScrollBar:SetPoint("TOPLEFT", frame.BigInfoFrame.AvailableMissionsScrollFrame, "TOPRIGHT", -19, -16) ;
        frame.BigInfoFrame.AvailableMissionsScrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", frame.BigInfoFrame.AvailableMissionsScrollFrame, "BOTTOMRIGHT", -19, 16);
        frame.BigInfoFrame.AvailableMissionsScrollFrame:SetSize(420,186);
        local AvailableMissionsscrollChild = CreateFrame("Frame", nil, frame.BigInfoFrame.AvailableMissionsScrollFrame);
        AvailableMissionsscrollChild:SetSize(400, 0);
        frame.BigInfoFrame.AvailableMissionsScrollFrame:SetScrollChild(AvailableMissionsscrollChild);
        frame.BigInfoFrame.AvailableMissionsScrollFrame:SetClipsChildren(true);

        -- Create the mission array of available missions
        frame.BigInfoFrame.AvailableMissionsArray = {};
        local lastMissionFrame = AvailableMissionsscrollChild;
        for i, miss in pairs(v.availableMissions) do
            if(not miss.offerEndTime or (miss.offerEndTime + miss.timeInfoCollected) > time()) then
                frame.BigInfoFrame.AvailableMissionsArray[miss.name] = CreateFrame("Frame", nil, lastMissionFrame, "CharGarrisonLandingPageReportMissionTemplate");
                if (lastMissionFrame == AvailableMissionsscrollChild) then
                    frame.BigInfoFrame.AvailableMissionsArray[miss.name]:ClearAllPoints();
                    frame.BigInfoFrame.AvailableMissionsArray[miss.name]:SetPoint("TOPLEFT", AvailableMissionsscrollChild, "TOPLEFT", 0, 0);
                end
                AvailableMissionsscrollChild:SetHeight(AvailableMissionsscrollChild:GetHeight()+frame.BigInfoFrame.AvailableMissionsArray[miss.name]:GetHeight()+math.abs(select(5,frame.BigInfoFrame.AvailableMissionsArray[miss.name]:GetPoint(1)) or 0));
                lastMissionFrame = frame.BigInfoFrame.AvailableMissionsArray[miss.name];
                lastMissionFrame.TimeLeft:Hide();
            end
        end

        -- Create the mission array of inprogres/completed missionss
        frame.BigInfoFrame.ProgressMissionsArray = {};
        lastMissionFrame = ProgresssMissionsscrollChild;
        local followersTimeLeftInMission = {};
        for i, miss in addon:SortMissions(v.activeMissions) do
            frame.BigInfoFrame.ProgressMissionsArray[miss.name] = CreateFrame("Frame", nil, lastMissionFrame, "CharGarrisonLandingPageReportMissionTemplate");
            if (lastMissionFrame == ProgresssMissionsscrollChild) then
                frame.BigInfoFrame.ProgressMissionsArray[miss.name]:ClearAllPoints();
                frame.BigInfoFrame.ProgressMissionsArray[miss.name]:SetPoint("TOPLEFT", ProgresssMissionsscrollChild, "TOPLEFT", 0, 0);
            end 
            ProgresssMissionsscrollChild:SetHeight(ProgresssMissionsscrollChild:GetHeight()+frame.BigInfoFrame.ProgressMissionsArray[miss.name]:GetHeight()+math.abs(select(5,frame.BigInfoFrame.ProgressMissionsArray[miss.name]:GetPoint(1)) or 0));
            lastMissionFrame = frame.BigInfoFrame.ProgressMissionsArray[miss.name];
            lastMissionFrame.TimeLeft:Hide();
            lastMissionFrame.Status:Hide();
        end
        
        --Create followers list
        frame.BigInfoFrame.FollowersArray = {};
        local lastFollowerFrame = FollowersListscrollChild;
        for fID,followerInfo in addon:SortFollowers(v.followers) do
            frame.BigInfoFrame.FollowersArray[fID] = CreateFrame("Frame", nil, lastFollowerFrame, "CharFollowerTemplate");
            if(lastFollowerFrame == FollowersListscrollChild) then
                frame.BigInfoFrame.FollowersArray[fID]:ClearAllPoints();
                frame.BigInfoFrame.FollowersArray[fID]:SetPoint("TOPRIGHT", lastFollowerFrame);
            end
            FollowersListscrollChild:SetHeight(FollowersListscrollChild:GetHeight()+frame.BigInfoFrame.FollowersArray[fID]:GetHeight()+math.abs(select(5,frame.BigInfoFrame.FollowersArray[fID]:GetPoint(1)) or 0));
            lastFollowerFrame = frame.BigInfoFrame.FollowersArray[fID];
            addon.FollowersHelper:SetUpFollowerFrame(lastFollowerFrame, followerInfo, fID, followersTimeLeftInMission[fID]);
            lastFollowerFrame:Show();
            
        end
        -- Create delete button
        frame.BigInfoFrame.deleteCharacter = ReportUI:createButton("BOTTOMRIGHT", frame.BigInfoFrame, frame.BigInfoFrame, "BOTTOMRIGHT", "Delete Character", 135, 35, -15, 15);
        frame.BigInfoFrame.deleteCharacter.character = k;
        frame.BigInfoFrame.deleteCharacter:SetScript("OnClick", ReportUI.deleteCharacter);
        -- Hide the frame 
        frame.BigInfoFrame:Hide();
        frame = ReportUI.ReportFrame.charactersFrames[k];
    end
    -- Set the max vertical scroll range
    ReportUI.ReportFrame.characterList.ScrollBar:SetMinMaxValues(0, ReportUI.ReportFrame.characterList:GetVerticalScrollRange());
    --hide the frame then return the frame
    ReportUI.ReportFrame:Hide();
    return ReportUI.ReportFrame;
end
