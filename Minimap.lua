--############################################
-- Namespace
--############################################
local _, addon = ...;

addon.MinimapIcon = {};
local MinimapIcon = addon.MinimapIcon;
local iconFrame = nil;

--Function executed when icon is clicked
function MinimapIcon:onClick()
	addon.ReportUI:toggleFrame();
end


local MinimapShapes = {
	["ROUND"] 			        = {true, true, true, true},
	["SQUARE"] 			        = {false, false, false, false},
	["CORNER-TOPLEFT"] 		    = {true, false, false, false},
	["CORNER-TOPRIGHT"] 		= {false, false, true, false},
	["CORNER-BOTTOMLEFT"] 		= {false, true, false, false},
	["CORNER-BOTTOMRIGHT"]	 	= {false, false, false, true},
	["SIDE-LEFT"] 			    = {true, true, false, false},
	["SIDE-RIGHT"] 			    = {false, false, true, true},
	["SIDE-TOP"] 			    = {true, false, true, false},
	["SIDE-BOTTOM"] 		    = {false, true, false, true},
	["TRICORNER-TOPLEFT"] 		= {true, true, true, false},
	["TRICORNER-TOPRIGHT"] 		= {true, false, true, true},
	["TRICORNER-BOTTOMLEFT"] 	= {true, true, false, true},
	["TRICORNER-BOTTOMRIGHT"] 	= {false, true, true, true},
};

--Repositiones the icon to the correct position based on the angle given
function MinimapIcon:RepositionIcon()
	local radius = 80;
	local xoff = math.cos(math.rad(addon.DataToSave.options.minimapPos or 45));
	local yoff = math.sin(math.rad(addon.DataToSave.options.minimapPos or 45));
	local q = 1;
	if xoff < 0 then
		q = q + 1;	-- lower
	end
	if yoff > 0 then
		q = q + 2;	-- right
	end
	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND";
	local quadTable = MinimapShapes[minimapShape];
	if quadTable[q] then
		xoff = xoff*radius;
		yoff = yoff*radius;
	else
		local diagRadius = math.sqrt(2*(radius)^2)-10;
		xoff = math.max(-radius, math.min(xoff*diagRadius, radius));
		yoff = math.max(-radius, math.min(yoff*diagRadius, radius));
	end
	iconFrame:SetPoint("CENTER", xoff, yoff);
end


-- Updates the position of the minimap icon
function MinimapIcon:DragrginFrame_OnUpdate()

	local xpos,ypos = GetCursorPosition();
	local xmin,ymin = Minimap:GetCenter();
	local scale = UIParent:GetEffectiveScale();

	xpos = (xpos / scale) - xmin;
	ypos = (ypos / scale) - ymin;

	addon.DataToSave.options.minimapPos = math.deg(math.atan2(ypos,xpos)) % 360;
	MinimapIcon:RepositionIcon();
end

--Functions when drag starts and drag ends
function MinimapIcon:OnDragStart()
	self:LockHighlight();
	self:SetScript("OnUpdate", MinimapIcon.DragrginFrame_OnUpdate);
end

function MinimapIcon:OnDragStop()
	self:UnlockHighlight();
	self:SetScript("OnUpdate", nil);
end

--Functions to show and hide (and ofc update) the tooltip when enter
function MinimapIcon:onEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE");
	GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 5);
	GameTooltip:SetText("|cFF029CFCClass Halls Account Reporter");
	GameTooltip:AddLine("|cFF3AFF00Hint:");
	GameTooltip:AddLine("|cFFE1A000Left Click |cFF3AFF00or |cFFE1A000Right Click |cFF3AFF00to open the report frame");
	GameTooltip:AddLine("|cFFE1A000Click and drag |cFF3AFF00to move the minimap icon.")
	GameTooltip:Show();
end

function MinimapIcon:onLeave()
	GameTooltip:Hide();
end

-- Init the minimap frame and set all the correct functions to the specific events and set the currecnt class texture coord
function MinimapIcon:initIcon()
	iconFrame = CreateFrame("BUTTON", nil, Minimap, "CHARMinimapIconTemplate");
	MinimapIcon:RepositionIcon();
	iconFrame:RegisterForClicks("LeftButtonUp","RightButtonUp");
	iconFrame:RegisterForDrag("LeftButton", "RightButton");
	iconFrame:SetScript("OnDragStart", MinimapIcon.OnDragStart);
	iconFrame:SetScript("OnDragStop", MinimapIcon.OnDragStop);
	iconFrame:SetScript("OnClick", MinimapIcon.onClick);
	iconFrame:SetScript("OnEnter", MinimapIcon.onEnter);
	iconFrame:SetScript("OnLeave", MinimapIcon.onLeave);
	iconFrame.icon:SetTexCoord(unpack(addon.ReportUI.classTextureCoords[select(2, UnitClass("player"))]));
	if(addon.DataToSave.options.showMinimapIcon) then
		iconFrame:Hide();
	end
	MinimapIcon.frame = iconFrame;
end

