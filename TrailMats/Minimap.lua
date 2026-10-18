local _, T = ...

-- The button sits on the minimap ring at a saved angle, like other minimap buttons.
local function position(button)
    local angle=math.rad(T.settings.minimap.angle or T.defaults.minimap.angle)
    local radius=(T.Safe(Minimap.GetWidth,Minimap) or 140)/2+5
    button:ClearAllPoints()
    button:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
end

function T.UpdateMinimapButton()
    if T.minimapButton then position(T.minimapButton) end
end

local function follow(button)
    local mx,my=Minimap:GetCenter();local cx,cy=GetCursorPosition()
    if not mx or not cx then return end
    local scale=Minimap:GetEffectiveScale() or 1
    T.settings.minimap.angle=math.deg(math.atan2(cy/scale-my,cx/scale-mx))
    position(button)
end

function T.CreateMinimapButton()
    if T.minimapButton or not Minimap then return end
    local b=CreateFrame("Button","TrailMatsMinimapButton",Minimap)
    T.minimapButton=b
    b:SetSize(31,31);b:SetFrameStrata("MEDIUM");b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp");b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b.border=b:CreateTexture(nil,"OVERLAY");b.border:SetSize(53,53);b.border:SetPoint("TOPLEFT")
    b.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    b.icon=b:CreateTexture(nil,"BACKGROUND");b.icon:SetSize(18,18);b.icon:SetPoint("TOPLEFT",7,-6)
    b.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10");b.icon:SetTexCoord(0.08,0.92,0.08,0.92)
    b:SetScript("OnDragStart",function(self) self.dragging=true;self:SetScript("OnUpdate",follow) end)
    b:SetScript("OnDragStop",function(self) self.dragging=false;self:SetScript("OnUpdate",nil) end)
    b:SetScript("OnClick",function(self,mouse)
        if self.dragging then return end
        if IsShiftKeyDown and IsShiftKeyDown() then T.OpenOptions()
        elseif mouse=="RightButton" then T.ToggleTracker()
        else T.Command("") end
    end)
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT")
        GameTooltip:AddLine("TrailMats",1,0.82,0.5)
        local id=T.plan and T.SelectedProfession()
        if id then
            local s=T.skills[id]
            GameTooltip:AddLine(s.name.." "..s.rank.."/"..s.cap,0.9,0.9,0.9)
            GameTooltip:AddLine(T.NextAction(id).text,0.85,0.9,0.9,true)
        end
        GameTooltip:AddLine("Left-click: open or close. Right-click: pin the tracker. Shift-click: settings. Drag to move.",0.7,0.7,0.7,true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    position(b);b:SetShown(not T.settings.minimap.hide)
end
