--############################################
-- Namespace
--############################################
local _, addon = ...;
addon.FollowersHelper = {};
local FollowersHelper = addon.FollowersHelper;


function FollowersHelper:SetUpFollowerFrame(frame, followerInfo, ID, timeLeftInMission)
    frame.Name:SetText(followerInfo.name);
    frame.Class:SetDesaturated(false);
    FollowersHelper:SetupPortrait(frame.PortraitFrame, followerInfo, isTroop);
    local nameOffsetY = 0;
	FollowersHelper:SetStatusText(frame, followerInfo.status, timeLeftInMission);
	frame.Class:SetAtlas(followerInfo.classAtlas);
	if (frame.PortraitFrame.quality ~= 6) then
		frame.PortraitFrame.PortraitRingQuality:Show();
	end
	if(followerInfo.status == GARRISON_FOLLOWER_INACTIVE) then
		frame.Status:SetTextColor(1, 0.1, 0.1);
		frame.PortraitFrame.PortraitRingCover:Show();
		frame.PortraitFrame.PortraitRingCover:SetAlpha(0.5);
		frame.BusyFrame:Show();
		frame.BusyFrame.Texture:SetColorTexture(0.22, 0.06, 0, 0.44);
	elseif(followerInfo.status) then
		frame.Status:SetTextColor(0.698, 0.941, 1);
		frame.PortraitFrame.PortraitRingCover:Show();
		frame.PortraitFrame.PortraitRingCover:SetAlpha(0.5);
		frame.BusyFrame:Show();
		frame.BusyFrame.Texture:SetColorTexture(0, 0.06, 0.22, 0.44);
	else
		frame.PortraitFrame.PortraitRingCover:Hide();
		frame.BusyFrame:Hide();
	end
	if(followerInfo.isMaxLevel) then
		nameOffsetY = nameOffsetY + 9;
		frame.ILevel:SetPoint("TOPLEFT", frame.Name, "BOTTOMLEFT", 0, -4);
		frame.Status:SetPoint("TOPLEFT", frame.ILevel, "BOTTOMLEFT", -1, -2);
		frame.ILevel:SetText("iLvL "..followerInfo.ilvl);
		frame:Show();
	else
		frame.ILevel:SetText(nil);
		frame.ILevel:Hide();
		frame.Status:SetPoint("TOPLEFT", frame.Name, "BOTTOMLEFT", 0, -2);
	end

    if (followerInfo.status or (ownedtroops and ownedTroop.status)) then
		nameOffsetY = nameOffsetY + 8;
	end
    
    frame.Name:SetPoint("LEFT", frame.PortraitFrame, "LEFT", 66, nameOffsetY);
	frame.Status:SetPoint("RIGHT", -5, 0);
	if (followerInfo.xp == 0 or followerInfo.levelXP == 0 or isTroop) then
		frame.XPBar:Hide();
	else
		frame.XPBar:Show();
		frame.XPBar:SetWidth((followerInfo.xp/followerInfo.levelXP) * 205);
	end
end

function FollowersHelper:SetStatusText(frame, status, timeLeftInMission)
	if(not timeLeftInMission) then
		frame.Status:SetText(status or "");
	else
		frame.Status:SetText(status or "On Mission"  .. " - " .. timeLeftInMission);
	end
end

function FollowersHelper:SetPortraitIcon(frame, iconFileID)
	if (iconFileID == nil or iconFileID == 0) then
		-- unknown icon file ID; use the default silhouette portrait
		frame.Portrait:SetTexture("Interface\\Garrison\\Portraits\\FollowerPortrait_NoPortrait");
	else
		frame.Portrait:SetTexture(iconFileID);
	end
end

function FollowersHelper:SetQuality(frame, quality)
	frame.quality = quality;
	
	if (quality == 6) then
		frame.LevelBorder:SetAtlas("legionmission-portraitring_levelborder_epicplus", true);
		frame.PortraitRing:SetAtlas("legionmission-portraitring-epicplus", true);
		frame.PortraitRingQuality:Hide();
		FollowersHelper:SetQualityColor(frame, 1, 1, 1);
	else
		frame.LevelBorder:SetAtlas("GarrMission_PortraitRing_LevelBorder", true);
		frame.PortraitRing:SetAtlas("GarrMission_PortraitRing_Quality", true);
		frame.PortraitRingQuality:Show();
        local color = nil;
        if (quality == 6) then
            color = ITEM_QUALITY_COLORS[4];
        elseif(quality > 0 and quality < 6) then
            color = ITEM_QUALITY_COLORS[quality];
        end
		if (color) then
			FollowersHelper:SetQualityColor(frame, color.r, color.g, color.b);
		else
			FollowersHelper:SetQualityColor(frame, 1, 1, 1);
		end
	end
end

function FollowersHelper:SetQualityColor(frame, r, g, b)
	frame.LevelBorder:SetVertexColor(r, g, b);
	frame.PortraitRingQuality:SetVertexColor(r, g, b);
end

function FollowersHelper:SetNoLevel(frame)
	frame.LevelBorder:Hide();
	frame.Level:Hide();
end

function FollowersHelper:SetLevel(frame, level)
	if (frame.quality == 6) then
		frame.LevelBorder:SetAtlas("legionmission-portraitring_levelborder_epicplus", true);
	else
		frame.LevelBorder:SetAtlas("GarrMission_PortraitRing_LevelBorder");
	end
	frame.LevelBorder:SetWidth(58);
	frame.LevelBorder:Show();
	frame.Level:Show();
	frame.Level:SetText(level);
end

function FollowersHelper:SetILevel(frame, iLevel)
	frame.LevelBorder:SetAtlas("GarrMission_PortraitRing_iLvlBorder");
	frame.LevelBorder:SetWidth(70);
	frame.LevelBorder:Show();
	frame.Level:Show();
	frame.Level:SetFormattedText("iLvl %d", iLevel);
end

function FollowersHelper:SetupPortrait(frame, followerInfo, isTroop, showILevel)
	FollowersHelper:SetPortraitIcon(frame, followerInfo.iconID);
	FollowersHelper:SetQuality(frame, followerInfo.quality);
	local hideLevelOnFollower = isTroop or (followerInfo.quality < LE_ITEM_QUALITY_POOR);

	if (hideLevelOnFollower) then
		FollowersHelper:SetNoLevel(frame);
	elseif (showILevel) then
		FollowersHelper:SetILevel(frame, followerInfo.iLevel);
	else
		FollowersHelper:SetLevel(frame, followerInfo.level);
	end
end