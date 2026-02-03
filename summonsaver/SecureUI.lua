SummonSaver = SummonSaver or {}
SummonSaver.SecureUI = SummonSaver.SecureUI or {}

local SummonSaver = SummonSaver
local SecureUI = SummonSaver.SecureUI

SecureUI.MAX_BUTTONS = 5
SecureUI.BUTTON_WIDTH = 190
SecureUI.BUTTON_HEIGHT = 30
SecureUI.BUTTON_SPACING = 4

function SecureUI:Initialize()
  if self.initialized then
    return
  end
  self.initialized = true

  local anchor = CreateFrame("Frame", "SummonSaver_Anchor", UIParent)
  anchor:SetSize(32, 32)
  anchor:SetClampedToScreen(true)
  anchor:EnableMouse(true)
  anchor:SetMovable(true)
  anchor:RegisterForDrag("LeftButton")

  anchor:SetScript("OnDragStart", function()
    if InCombatLockdown and InCombatLockdown() then
      return
    end
    anchor:StartMoving()
  end)

  anchor:SetScript("OnDragStop", function()
    anchor:StopMovingOrSizing()
    local point, _, relPoint, x, y = anchor:GetPoint()
    SummonSaverDB.anchor.point = point
    SummonSaverDB.anchor.relPoint = relPoint
    SummonSaverDB.anchor.x = math.floor((x or 0) + 0.5)
    SummonSaverDB.anchor.y = math.floor((y or 0) + 0.5)
  end)

  local anchorTexture = anchor:CreateTexture(nil, "BACKGROUND")
  anchorTexture:SetAllPoints()
  anchorTexture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
  anchorTexture:SetVertexColor(0.4, 0.8, 1, 0.85)

  local anchorText = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  anchorText:SetPoint("CENTER")
  anchorText:SetText("SummonSaver")

  self.anchor = anchor

  local anchorData = SummonSaverDB.anchor
  anchor:ClearAllPoints()
  anchor:SetPoint(anchorData.point or "BOTTOM", UIParent, anchorData.relPoint or "BOTTOM", anchorData.x or 0, anchorData.y or 180)
  anchor:Hide()

  local toggle = CreateFrame("Button", "SummonSaver_Toggle", UIParent, "SecureHandlerClickTemplate")
  toggle:SetSize(1, 1)
  toggle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", -1000, -1000)
  toggle:SetAttribute("open", false)

  toggle:SetAttribute("showAll", [[
    local i = 1
    while true do
      local btn = self:GetFrameRef("btn" .. i)
      if not btn then
        break
      end
      if btn:GetAttribute("enabled") then
        btn:Show()
      end
      i = i + 1
    end
    self:SetAttribute("open", true)
  ]])

  toggle:SetAttribute("hideAll", [[
    local i = 1
    while true do
      local btn = self:GetFrameRef("btn" .. i)
      if not btn then
        break
      end
      btn:Hide()
      i = i + 1
    end
    self:SetAttribute("open", false)
  ]])

  toggle:SetAttribute("_onclick", [[
    local open = self:GetAttribute("open")
    if open then
      self:RunAttribute("hideAll")
    else
      self:RunAttribute("showAll")
    end
  ]])

  self.toggle = toggle
  self.buttons = {}

  for i = 1, self.MAX_BUTTONS do
    local button = CreateFrame("Button", "SummonSaver_MenuButton" .. i, UIParent, "SecureActionButtonTemplate,SecureHandlerClickTemplate")
    button:SetSize(self.BUTTON_WIDTH, self.BUTTON_HEIGHT)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")

    if i == 1 then
      button:SetPoint("BOTTOM", anchor, "TOP", 0, self.BUTTON_SPACING)
    else
      button:SetPoint("BOTTOM", self.buttons[i - 1], "TOP", 0, self.BUTTON_SPACING)
    end

    button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")

    local normal = button:GetNormalTexture()
    if normal then
      normal:SetAllPoints()
    end
    local pushed = button:GetPushedTexture()
    if pushed then
      pushed:SetAllPoints()
    end
    local highlight = button:GetHighlightTexture()
    if highlight then
      highlight:SetAllPoints()
    end

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(22, 22)
    button.icon:SetPoint("LEFT", 6, 0)

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("LEFT", button.icon, "RIGHT", 6, 0)
    button.label:SetWidth(self.BUTTON_WIDTH - 50)
    button.label:SetJustifyH("LEFT")
    button.label:SetWordWrap(false)

    button.number = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    button.number:SetPoint("TOPLEFT", 4, -4)

    button:SetFrameRef("toggle", toggle)
    button:SetAttribute("_onclick", [[
      local close = self:GetAttribute("closeOnSelect")
      if close then
        local toggle = self:GetFrameRef("toggle")
        if toggle then
          toggle:RunAttribute("hideAll")
        end
      end
    ]])

    button:Hide()

    toggle:SetFrameRef("btn" .. i, button)
    self.buttons[i] = button
  end
end

function SecureUI:SetAnchorVisible(show)
  if not self.anchor then
    return
  end

  if show then
    self.anchor:Show()
  else
    self.anchor:Hide()
  end
end

function SecureUI:ApplyOrder(orderedDemons)
  for i = 1, self.MAX_BUTTONS do
    local button = self.buttons[i]
    local spellID = orderedDemons[i]

    if spellID then
      local name, _, icon = GetSpellInfo(spellID)
      local spellToken = name or spellID
      button:SetAttribute("type", "spell")
      button:SetAttribute("spell", spellToken)
      button:SetAttribute("type1", "spell")
      button:SetAttribute("spell1", spellToken)
      button:SetAttribute("enabled", 1)
      button:SetAttribute("closeOnSelect", SummonSaverDB.settings.closeOnSelect and 1 or nil)

      button.icon:SetTexture(icon)
      button.label:SetText(name or "Unknown")
      if SummonSaverDB.settings.showNumbers then
        button.number:SetText(tostring(i))
      else
        button.number:SetText("")
      end
    else
      button:SetAttribute("enabled", nil)
      button:SetAttribute("spell", nil)
      button:SetAttribute("spell1", nil)
      button:SetAttribute("type", nil)
      button:SetAttribute("type1", nil)
      button:SetAttribute("closeOnSelect", nil)
      button.icon:SetTexture(nil)
      button.label:SetText("")
      button.number:SetText("")
    end

    button:Hide()
  end

  if self.toggle then
    self.toggle:SetAttribute("open", false)
  end
end
