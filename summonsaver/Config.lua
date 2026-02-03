SummonSaver = SummonSaver or {}
SummonSaver.ConfigUI = SummonSaver.ConfigUI or {}

local SummonSaver = SummonSaver
local ConfigUI = SummonSaver.ConfigUI

ConfigUI.MAX_ROWS = 5
ConfigUI.ROW_HEIGHT = 26

function ConfigUI:Initialize()
  if self.frame then
    return
  end

  local frame = CreateFrame("Frame", "SummonSaver_ConfigFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(320, 300)
  frame:SetPoint("CENTER")
  frame:Hide()

  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.title:SetPoint("TOPLEFT", 12, -8)
  frame.title:SetText("SummonSaver Settings")

  self.rows = {}
  for i = 1, self.MAX_ROWS do
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(280, 24)
    row:SetPoint("TOPLEFT", 16, -40 - (i - 1) * self.ROW_HEIGHT)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", 0, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetJustifyH("LEFT")

    row.up = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.up:SetSize(32, 18)
    row.up:SetPoint("RIGHT", -44, 0)
    row.up:SetText("Up")

    row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.down:SetSize(44, 18)
    row.down:SetPoint("RIGHT", 0, 0)
    row.down:SetText("Down")

    row.up:SetScript("OnClick", function()
      SummonSaver:MoveSpell(row.spellID, -1)
    end)

    row.down:SetScript("OnClick", function()
      SummonSaver:MoveSpell(row.spellID, 1)
    end)

    self.rows[i] = row
  end

  local closeCheck = CreateFrame("CheckButton", "SummonSaver_CloseOnSelect", frame, "UICheckButtonTemplate")
  closeCheck:SetPoint("BOTTOMLEFT", 16, 48)
  closeCheck.text = _G[closeCheck:GetName() .. "Text"]
  closeCheck.text:SetText("Close menu on select")
  closeCheck:SetScript("OnClick", function(self)
    SummonSaverDB.settings.closeOnSelect = self:GetChecked() and true or false
    SummonSaver:RequestSecureRefresh()
  end)
  self.closeCheck = closeCheck

  local numbersCheck = CreateFrame("CheckButton", "SummonSaver_ShowNumbers", frame, "UICheckButtonTemplate")
  numbersCheck:SetPoint("BOTTOMLEFT", 16, 24)
  numbersCheck.text = _G[numbersCheck:GetName() .. "Text"]
  numbersCheck.text:SetText("Show numbers")
  numbersCheck:SetScript("OnClick", function(self)
    SummonSaverDB.settings.showNumbers = self:GetChecked() and true or false
    SummonSaver:RequestSecureRefresh()
  end)
  self.numbersCheck = numbersCheck

  self.statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.statusText:SetPoint("BOTTOMLEFT", 16, 8)

  local reset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  reset:SetSize(80, 22)
  reset:SetPoint("BOTTOMRIGHT", -92, 12)
  reset:SetText("Reset")
  reset:SetScript("OnClick", function()
    SummonSaver:ResetDefaults()
    SummonSaver:Rebuild()
  end)

  local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  close:SetSize(80, 22)
  close:SetPoint("BOTTOMRIGHT", -12, 12)
  close:SetText("Close")
  close:SetScript("OnClick", function()
    frame:Hide()
  end)

  frame:SetScript("OnShow", function()
    if SummonSaver then
      ConfigUI.anchorWasHidden = not SummonSaver.anchorVisible
      if ConfigUI.anchorWasHidden then
        SummonSaver:SetAnchorVisible(true)
      end
    end
    ConfigUI:Refresh()
  end)

  frame:SetScript("OnHide", function()
    if ConfigUI.anchorWasHidden then
      SummonSaver:SetAnchorVisible(false)
      ConfigUI.anchorWasHidden = false
    end
  end)

  self.frame = frame
end

function ConfigUI:Show()
  if not self.frame then
    self:Initialize()
  end
  self.frame:Show()
end

function ConfigUI:RefreshStatus()
  if not self.statusText then
    return
  end

  if InCombatLockdown and InCombatLockdown() then
    self.statusText:SetText("In combat: changes apply after combat.")
  else
    self.statusText:SetText("")
  end
end

function ConfigUI:Refresh()
  if not self.frame then
    return
  end

  local demons = SummonSaver.orderedDemons or {}
  local count = #demons

  for i = 1, self.MAX_ROWS do
    local row = self.rows[i]
    local spellID = demons[i]

    if spellID then
      local name, _, icon = GetSpellInfo(spellID)
      row.spellID = spellID
      row.icon:SetTexture(icon)
      row.name:SetText(name or "Unknown")
      row.up:SetEnabled(i > 1)
      row.down:SetEnabled(i < count)
      row:Show()
    else
      row.spellID = nil
      row:Hide()
    end
  end

  if self.closeCheck then
    self.closeCheck:SetChecked(SummonSaverDB.settings.closeOnSelect)
  end

  if self.numbersCheck then
    self.numbersCheck:SetChecked(SummonSaverDB.settings.showNumbers)
  end

  self:RefreshStatus()
end
