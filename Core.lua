local ADDON, NS = ...

local TEXROOT = "Interface\\AddOns\\" .. ADDON .. "\\Textures\\"
local PVP_HEADER_TEX_W = 512
local PVP_HEADER_TEX_H = 512
local PVP_HEADER_CONTENT_H = 32
local PVP_HEADER_CONTENT_W = PVP_HEADER_CONTENT_H + 4
NS.tex = {
  header = TEXROOT .. "header",
  questTitle = TEXROOT .. "zonetext",
  divider = TEXROOT .. "UI-HorizontalBreak",
  titleHL = TEXROOT .. "UI-QuestTitleHighlight",
  itemBG = TEXROOT .. "UI-QuestItem",
  itemHL = TEXROOT .. "UI-QuestItemHighlight",
  pvpHeaderAlliance = TEXROOT .. "pvp_header_a",
  pvpHeaderHorde = TEXROOT .. "pvp_header_h",
}

NS.defaults = {
  enabled = true,
}

local function CopyDefaults(dst, src)
  for key, value in pairs(src) do
    if type(value) == "table" then
      dst[key] = dst[key] or {}
      CopyDefaults(dst[key], value)
    elseif dst[key] == nil then
      dst[key] = value
    end
  end
end

QWWDB = QWWDB or {}
CopyDefaults(QWWDB, NS.defaults)
NS.db = QWWDB

local function ThemeValue(key, fallback)
  if NS.theme and NS.theme[key] ~= nil then
    return NS.theme[key]
  end
  return fallback
end

local function ThemeColor(key, fallback)
  local value = NS.theme and NS.theme[key]
  if type(value) == "table" then
    return value[1], value[2], value[3]
  end
  if type(fallback) == "table" then
    return fallback[1], fallback[2], fallback[3]
  end
  return 1, 1, 1
end

local function GetAccentColor()
  if NS.theme and NS.theme.accent then
    return NS.theme.accent[1], NS.theme.accent[2], NS.theme.accent[3]
  end
  return 0.9, 0.75, 0.35
end

local function GetPvpHeaderTexture()
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  if faction == "Horde" then
    return NS.tex.pvpHeaderHorde
  end
  if faction == "Alliance" then
    return NS.tex.pvpHeaderAlliance
  end
  return NS.tex.pvpHeaderAlliance
end

local function StripPvpIcon(text)
  if not text or not text:find("pvp_header_") then
    return text
  end
  local cleaned = text:gsub("|T.-pvp_header_.-|t", "")
  return cleaned:gsub("%s%s+", " "):gsub("^%s+", "")
end

local function IsAddOnLoadedSafe(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then
    return C_AddOns.IsAddOnLoaded(name)
  end
  return IsAddOnLoaded(name)
end

local function GetModule(name)
  if not QuestieLoader or not QuestieLoader.ImportModule then
    return nil
  end
  return QuestieLoader:ImportModule(name)
end

local function EnsureTexture(frame, key, layer)
  if not frame or not frame.CreateTexture then return nil end
  frame._qwwTextures = frame._qwwTextures or {}
  if not frame._qwwTextures[key] then
    frame._qwwTextures[key] = frame:CreateTexture(nil, layer or "BACKGROUND")
  end
  return frame._qwwTextures[key]
end

local function GetBaseFrame()
  local trackerBase = GetModule("TrackerBaseFrame")
  if trackerBase and trackerBase.baseFrame then
    return trackerBase.baseFrame
  end
  return _G.Questie_BaseFrame
end

local function GetHeaderFrame()
  local trackerHeader = GetModule("TrackerHeaderFrame")
  if trackerHeader and trackerHeader.headerFrame then
    return trackerHeader.headerFrame
  end
  return _G.Questie_HeaderFrame
end

local function GetQuestFrame()
  local trackerQuest = GetModule("TrackerQuestFrame")
  if trackerQuest and trackerQuest.questFrame then
    return trackerQuest.questFrame
  end
  return _G.TrackedQuests
end

local function StyleBaseFrame(baseFrame)
  if not baseFrame then return end
  if baseFrame._qwwBackdrop then
    baseFrame._qwwBackdrop:Hide()
  end
end

local function StyleHeaderFrame(headerFrame)
  if not headerFrame then return end

  local bg = EnsureTexture(headerFrame, "headerBG", "BACKGROUND")
  if bg then
    bg:SetTexture(NS.tex.header)
    bg:ClearAllPoints()
    local baseFrame = headerFrame:GetParent() or GetBaseFrame()
    if baseFrame then
      bg:SetPoint("LEFT", baseFrame, "LEFT", -10, 0)
      bg:SetPoint("RIGHT", baseFrame, "RIGHT", 10, 0)
    else
      bg:SetPoint("LEFT", headerFrame, "LEFT", -10, 0)
      bg:SetPoint("RIGHT", headerFrame, "RIGHT", 10, 0)
    end
    bg:SetPoint("TOP", headerFrame, "TOP", 0, 6)
    bg:SetPoint("BOTTOM", headerFrame, "BOTTOM", 0, -6)
    local r, g, b = ThemeColor("accent", {1, 1, 1})
    bg:SetVertexColor(r, g, b, ThemeValue("headerAlpha", 0.9))
    bg:SetShown(NS.db.enabled)
  end

  if headerFrame.trackedQuests and headerFrame.trackedQuests.label then
    local label = headerFrame.trackedQuests.label
    if not label._qwwShadow then
      label:SetShadowColor(0, 0, 0, 0.8)
      label:SetShadowOffset(1, -1)
      label._qwwShadow = true
    end
  end
end

local function StyleLine(line)
  if not line then return end

  local isZone = line.mode == "zone"
  local isQuestTitle = line.mode == "quest" or line.mode == "achieve"
  local isPvpQuest = false

  if line.mode == "quest" then
    local questId = line.Quest and line.Quest.Id or (line.expandQuest and line.expandQuest.questId)
    local QuestieDB = questId and GetModule("QuestieDB")
    if QuestieDB and QuestieDB.IsPvPQuest then
      isPvpQuest = QuestieDB.IsPvPQuest(questId)
    end
  end

  if line.SetHighlightTexture then
    local target = isQuestTitle and NS.tex.questTitle or NS.tex.titleHL
    if line._qwwHighlightTexture ~= target then
      line:SetHighlightTexture(target, "ADD")
      local hl = line:GetHighlightTexture()
      if hl then
        hl:SetAllPoints(line)
        hl:SetVertexColor(1, 1, 1, ThemeValue("highlightAlpha", 0.22))
      end
      line._qwwHighlightTexture = target
    end
  end
  if line._qwwTextures then
    if line._qwwTextures.titleBG then
      line._qwwTextures.titleBG:Hide()
    end
    if line._qwwTextures.objectiveBG then
      line._qwwTextures.objectiveBG:Hide()
    end
  end

  local pvpBg = EnsureTexture(line, "pvpBG", "BACKGROUND")
  if pvpBg then
    pvpBg:Hide()
  end

  if line.label then
    local text = line.label:GetText()
    if text and text:find("pvp_header_") then
      line.label:SetText(StripPvpIcon(text))
    end
  end

  local pvpIcon = EnsureTexture(line, "pvpIcon", "ARTWORK")
  if pvpIcon then
    if isPvpQuest and isQuestTitle and NS.db.enabled then
      local target = GetPvpHeaderTexture()
      if pvpIcon._qwwTexture ~= target then
        pvpIcon:SetTexture(target)
        pvpIcon._qwwTexture = target
      end

      local cropW = ThemeValue("pvpIconCropW", PVP_HEADER_CONTENT_W)
      local cropH = ThemeValue("pvpIconCropH", PVP_HEADER_CONTENT_H)
      local uMax = cropW / PVP_HEADER_TEX_W
      local vMax = cropH / PVP_HEADER_TEX_H
      if pvpIcon._qwwTexCoordU ~= uMax or pvpIcon._qwwTexCoordV ~= vMax then
        pvpIcon:SetTexCoord(0, uMax, 0, vMax)
        pvpIcon._qwwTexCoordU = uMax
        pvpIcon._qwwTexCoordV = vMax
      end

      local size = ThemeValue("pvpIconSize", 12)
      pvpIcon:SetSize(size, size)
      pvpIcon:SetVertexColor(1, 1, 1, ThemeValue("pvpIconAlpha", 1))
      pvpIcon:ClearAllPoints()
      local offsetX = ThemeValue("pvpIconOffsetX", -6)
      local offsetY = ThemeValue("pvpIconOffsetY", 0)
      if line.expandQuest then
        pvpIcon:SetPoint("RIGHT", line.expandQuest, "LEFT", offsetX, offsetY)
      else
        pvpIcon:SetPoint("LEFT", line, "LEFT", offsetX, offsetY)
      end
      pvpIcon:Show()
    else
      pvpIcon:Hide()
    end
  end

  local zoneBg = EnsureTexture(line, "zoneBG", "BACKGROUND")
  if zoneBg then
    zoneBg:SetTexture(NS.tex.header)
    zoneBg:ClearAllPoints()
    local baseFrame = GetBaseFrame() or line:GetParent()
    if baseFrame then
      zoneBg:SetPoint("LEFT", baseFrame, "LEFT", 0, 0)
      zoneBg:SetPoint("RIGHT", baseFrame, "RIGHT", 0, 0)
    else
      zoneBg:SetPoint("LEFT", line, "LEFT", -8, 0)
      zoneBg:SetPoint("RIGHT", line, "RIGHT", 8, 0)
    end
    zoneBg:SetPoint("TOP", line, "TOP", 0, 2)
    zoneBg:SetPoint("BOTTOM", line, "BOTTOM", 0, -2)
    local ar, ag, ab = GetAccentColor()
    zoneBg:SetVertexColor(ar, ag, ab, ThemeValue("zoneAlpha", 0.75))
    zoneBg:SetShown(isZone and NS.db.enabled)
  end

  local divider = EnsureTexture(line, "divider", "BACKGROUND")
  if divider then
    divider:SetTexture(NS.tex.divider)
    divider:SetHeight(1)
    divider:SetPoint("LEFT", line, "LEFT", 6, 0)
    divider:SetPoint("RIGHT", line, "RIGHT", -6, 0)
    divider:SetPoint("BOTTOM", line, "BOTTOM", 0, -2)
    local dr, dg, db = GetAccentColor()
    divider:SetVertexColor(dr, dg, db, ThemeValue("dividerAlpha", 0.12))
    divider:SetShown(isZone and NS.db.enabled)
  end

  if line.label and not line.label._qwwShadow then
    line.label:SetShadowColor(0, 0, 0, 0.7)
    line.label:SetShadowOffset(1, -1)
    line.label._qwwShadow = true
  end
end

local function StyleItemIcon(button)
  if not button then return end

  local normal = button.GetNormalTexture and button:GetNormalTexture()
  if normal then
    normal:ClearAllPoints()
    normal:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    normal:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    normal:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end

  local pushed = button.GetPushedTexture and button:GetPushedTexture()
  if pushed then
    pushed:ClearAllPoints()
    pushed:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    pushed:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
    pushed:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end
end

local function ResetItemIcon(button)
  if not button then return end

  local normal = button.GetNormalTexture and button:GetNormalTexture()
  if normal then
    normal:ClearAllPoints()
    normal:SetAllPoints(button)
    normal:SetTexCoord(0, 1, 0, 1)
  end

  local pushed = button.GetPushedTexture and button:GetPushedTexture()
  if pushed then
    pushed:ClearAllPoints()
    pushed:SetAllPoints(button)
    pushed:SetTexCoord(0, 1, 0, 1)
  end
end

local function StyleItemButton(button)
  if not button then return end

  local bg = EnsureTexture(button, "itemBG", "BACKGROUND")
  if bg then
    bg:SetTexture(NS.tex.itemBG)
    bg:SetAllPoints(button)
    bg:SetVertexColor(1, 1, 1, ThemeValue("itemBGAlpha", 0.7))
    bg:SetShown(NS.db.enabled)
  end

  if button.SetHighlightTexture then
    button:SetHighlightTexture(NS.tex.itemHL, "ADD")
    local hl = button:GetHighlightTexture()
    if hl then
      hl:SetAllPoints(button)
      hl:SetVertexColor(1, 1, 1, ThemeValue("itemHLAlpha", 0.85))
    end
  end

  StyleItemIcon(button)

  button._qwwStyled = true
end

local function StyleItemButtons()
  local maxButtons = 25
  if C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then
    maxButtons = C_QuestLog.GetMaxNumQuestsCanAccept()
  end

  for i = 1, maxButtons do
    local button = _G["Questie_ItemButton" .. i]
    if button then
      StyleItemButton(button)
    end
  end
end

local function StyleLines()
  local linePool = GetModule("TrackerLinePool")
  if not linePool or not linePool.GetLine then
    return
  end

  local maxIndex = linePool.GetHighestIndex and linePool.GetHighestIndex() or 0
  if not maxIndex or maxIndex < 1 then
    return
  end

  for i = 1, maxIndex do
    local line = linePool.GetLine(i)
    if not line then
      break
    end
    StyleLine(line)
  end
end

function NS.HideSkin()
  local baseFrame = GetBaseFrame()
  if baseFrame and baseFrame._qwwBackdrop then
    baseFrame._qwwBackdrop:Hide()
  end

  local headerFrame = GetHeaderFrame()
  if headerFrame and headerFrame._qwwTextures and headerFrame._qwwTextures.headerBG then
    headerFrame._qwwTextures.headerBG:Hide()
  end

  local linePool = GetModule("TrackerLinePool")
  if linePool and linePool.GetLine then
    for i = 1, 250 do
      local line = linePool.GetLine(i)
      if not line then
        break
      end
      if line._qwwTextures and line._qwwTextures.zoneBG then
        line._qwwTextures.zoneBG:Hide()
      end
      if line._qwwTextures and line._qwwTextures.titleBG then
        line._qwwTextures.titleBG:Hide()
      end
      if line._qwwTextures and line._qwwTextures.objectiveBG then
        line._qwwTextures.objectiveBG:Hide()
      end
      if line._qwwTextures and line._qwwTextures.divider then
        line._qwwTextures.divider:Hide()
      end
      if line._qwwTextures and line._qwwTextures.pvpBG then
        line._qwwTextures.pvpBG:Hide()
      end
      if line._qwwTextures and line._qwwTextures.pvpIcon then
        line._qwwTextures.pvpIcon:Hide()
      end
      if line._qwwHighlightTexture and line.SetHighlightTexture then
        line:SetHighlightTexture(nil)
        line._qwwHighlightTexture = nil
      end
    end
  end

  local maxButtons = 25
  if C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then
    maxButtons = C_QuestLog.GetMaxNumQuestsCanAccept()
  end
  for i = 1, maxButtons do
    local button = _G["Questie_ItemButton" .. i]
    if button then
      if button._qwwTextures and button._qwwTextures.itemBG then
        button._qwwTextures.itemBG:Hide()
      end
      if button.SetHighlightTexture then
        button:SetHighlightTexture(nil)
      end
      ResetItemIcon(button)
      button._qwwStyled = false
    end
  end
end

function NS.ApplySkin()
  if not NS.db.enabled then
    NS.HideSkin()
    return
  end

  local baseFrame = GetBaseFrame()
  if not baseFrame then
    return
  end

  StyleBaseFrame(baseFrame)
  StyleHeaderFrame(GetHeaderFrame())
  StyleLines()
  StyleItemButtons()
end

function NS.QueueApply(delay)
  if NS.applyPending then return end
  NS.applyPending = true
  local function run()
    NS.applyPending = false
    NS.ApplySkin()
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(delay or 0, run)
  else
    run()
  end
end

local function HookFunc(obj, name)
  if not obj or type(obj[name]) ~= "function" then
    return false
  end
  hooksecurefunc(obj, name, function()
    if NS.db.enabled then
      NS.QueueApply(0)
    end
  end)
  return true
end

function NS.HookQuestie()
  if NS.hooked then return end
  if not IsAddOnLoadedSafe("Questie") then
    return
  end

  local QuestieTracker = GetModule("QuestieTracker")
  local TrackerBaseFrame = GetModule("TrackerBaseFrame")
  local TrackerHeaderFrame = GetModule("TrackerHeaderFrame")
  local TrackerQuestFrame = GetModule("TrackerQuestFrame")
  local TrackerLinePool = GetModule("TrackerLinePool")

  local hookCount = 0
  if HookFunc(QuestieTracker, "Update") then hookCount = hookCount + 1 end
  if HookFunc(QuestieTracker, "UpdateFormatting") then hookCount = hookCount + 1 end
  if HookFunc(TrackerBaseFrame, "Update") then hookCount = hookCount + 1 end
  if HookFunc(TrackerHeaderFrame, "Update") then hookCount = hookCount + 1 end
  if HookFunc(TrackerQuestFrame, "Update") then hookCount = hookCount + 1 end
  if HookFunc(TrackerLinePool, "HideUnusedLines") then hookCount = hookCount + 1 end

  NS.hooked = hookCount > 0
end

local function OnEvent(self, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON then
      NS.QueueApply(0.1)
    elseif arg1 == "Questie" then
      NS.HookQuestie()
      NS.QueueApply(0.2)
    end
  elseif event == "PLAYER_LOGIN" then
    NS.HookQuestie()
    NS.QueueApply(0.5)
  elseif event == "QUEST_LOG_UPDATE" then
    if NS.db.enabled then
      NS.QueueApply(0.1)
    end
  end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:SetScript("OnEvent", OnEvent)
