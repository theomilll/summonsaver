SummonSaver = SummonSaver or {}
local SummonSaver = SummonSaver

BINDING_HEADER_SUMMONSAVER = "SummonSaver"
BINDING_NAME_SUMMONSAVER_TOGGLE = "Toggle Summon Menu"

SummonSaver.ALL_SPELL_IDS = { 697, 712, 691, 688, 30146 }
SummonSaver.DEFAULT_ORDER = { 697, 712, 691, 688, 30146 }

SummonSaver.inCombat = false
SummonSaver.pendingSecureUpdate = false
SummonSaver.anchorVisible = false
SummonSaver.knownDemons = {}
SummonSaver.orderedDemons = {}

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function SummonSaver:Print(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff8be9fdSummonSaver:|r " .. tostring(message))
  end
end

function SummonSaver:IsSupportedClient()
  if WOW_PROJECT_ID and WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
    return WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
  end
  return true
end

function SummonSaver:IsWarlock()
  local _, class = UnitClass("player")
  return class == "WARLOCK"
end

function SummonSaver:ApplyDefaults()
  if type(SummonSaverDB) ~= "table" then
    SummonSaverDB = {}
  end

  if type(SummonSaverDB.order) ~= "table" then
    SummonSaverDB.order = {}
    for i, spellID in ipairs(self.DEFAULT_ORDER) do
      SummonSaverDB.order[i] = spellID
    end
  end

  if type(SummonSaverDB.anchor) ~= "table" then
    SummonSaverDB.anchor = { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 180 }
  end

  if type(SummonSaverDB.settings) ~= "table" then
    SummonSaverDB.settings = {}
  end

  if SummonSaverDB.settings.closeOnSelect == nil then
    SummonSaverDB.settings.closeOnSelect = true
  end

  if SummonSaverDB.settings.showNumbers == nil then
    SummonSaverDB.settings.showNumbers = true
  end
end

function SummonSaver:ResetDefaults()
  SummonSaverDB.order = {}
  for i, spellID in ipairs(self.DEFAULT_ORDER) do
    SummonSaverDB.order[i] = spellID
  end
  SummonSaverDB.settings = { closeOnSelect = true, showNumbers = true }
end

function SummonSaver:IsSpellKnownById(spellID)
  if IsSpellKnown then
    return IsSpellKnown(spellID)
  end

  local name = GetSpellInfo(spellID)
  if not name then
    return false
  end

  local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 0
  for tab = 1, numTabs do
    local _, _, offset, numSlots = GetSpellTabInfo(tab)
    for i = 1, numSlots do
      local slot = offset + i
      local spellName = GetSpellBookItemName(slot, BOOKTYPE_SPELL)
      if spellName == name then
        return true
      end
    end
  end

  return false
end

function SummonSaver:BuildKnownDemons()
  self.knownDemons = {}
  self.knownSet = {}

  for _, spellID in ipairs(self.ALL_SPELL_IDS) do
    if self:IsSpellKnownById(spellID) then
      table.insert(self.knownDemons, spellID)
      self.knownSet[spellID] = true
    end
  end
end

function SummonSaver:NormalizeOrder()
  local order = SummonSaverDB.order or {}
  local newOrder = {}
  local seen = {}

  for _, spellID in ipairs(order) do
    if self.knownSet[spellID] and not seen[spellID] then
      table.insert(newOrder, spellID)
      seen[spellID] = true
    end
  end

  for _, spellID in ipairs(self.knownDemons) do
    if not seen[spellID] then
      table.insert(newOrder, spellID)
      seen[spellID] = true
    end
  end

  SummonSaverDB.order = newOrder
  self.orderedDemons = newOrder
end

function SummonSaver:RequestSecureRefresh()
  if not self.secureReady then
    return
  end

  if InCombatLockdown and InCombatLockdown() then
    self.pendingSecureUpdate = true
    if self.ConfigUI and self.ConfigUI.RefreshStatus then
      self.ConfigUI:RefreshStatus()
    end
    return
  end

  self.pendingSecureUpdate = false
  self.SecureUI:ApplyOrder(self.orderedDemons)
  if self.ConfigUI and self.ConfigUI.RefreshStatus then
    self.ConfigUI:RefreshStatus()
  end
end

function SummonSaver:Rebuild()
  self:BuildKnownDemons()
  self:NormalizeOrder()
  if self.ConfigUI and self.ConfigUI.Refresh then
    self.ConfigUI:Refresh()
  end
  self:RequestSecureRefresh()
end

function SummonSaver:MoveSpell(spellID, direction)
  if not spellID then
    return
  end

  local order = SummonSaverDB.order or {}
  local index

  for i, id in ipairs(order) do
    if id == spellID then
      index = i
      break
    end
  end

  if not index then
    return
  end

  local target = index + direction
  if target < 1 or target > #order then
    return
  end

  order[index], order[target] = order[target], order[index]
  self:NormalizeOrder()
  if self.ConfigUI and self.ConfigUI.Refresh then
    self.ConfigUI:Refresh()
  end
  self:RequestSecureRefresh()
end

function SummonSaver:SetAnchorVisible(show)
  self.anchorVisible = show and true or false
  if self.SecureUI and self.SecureUI.SetAnchorVisible then
    self.SecureUI:SetAnchorVisible(self.anchorVisible)
  end
end

function SummonSaver:InstallMacro()
  if InCombatLockdown and InCombatLockdown() then
    self:Print("Cannot install macro during combat.")
    return
  end

  local macroName = "Summon Demon"
  local macroBody = "/click SummonSaver_Toggle"
  local macroIcon = "Spell_Shadow_SummonImp"
  local index = GetMacroIndexByName(macroName)

  if index == 0 then
    if MAX_CHARACTER_MACROS then
      local _, numCharacter = GetNumMacros()
      if numCharacter >= MAX_CHARACTER_MACROS then
        self:Print("No free character macro slots.")
        return
      end
    end

    local created = CreateMacro(macroName, macroIcon, macroBody, true)
    if created then
      self:Print("Macro created: drag 'Summon Demon' to your action bar.")
    else
      self:Print("Failed to create macro.")
    end
    return
  end

  EditMacro(index, macroName, macroIcon, macroBody, 1)
  self:Print("Macro updated: 'Summon Demon'.")
end

function SummonSaver:HandleSlash(message)
  local cmd = trim(message):lower()

  if self.disabled then
    self:Print("Only available for warlocks in TBC Classic.")
    return
  end

  if cmd == "" or cmd == "config" or cmd == "settings" then
    if self.ConfigUI and self.ConfigUI.Show then
      self.ConfigUI:Show()
    end
    return
  end

  if cmd == "installmacro" then
    self:InstallMacro()
    return
  end

  if cmd == "anchor" then
    self:SetAnchorVisible(not self.anchorVisible)
    if self.anchorVisible then
      self:Print("Anchor shown. Drag to reposition.")
    else
      self:Print("Anchor hidden.")
    end
    return
  end

  if cmd == "reset" then
    self:ResetDefaults()
    self:Rebuild()
    self:Print("Settings reset to defaults.")
    return
  end

  self:Print("Commands: /summonsaver, /summonsaver installmacro, /summonsaver anchor, /summonsaver reset")
end

SLASH_SUMMONSAVER1 = "/summonsaver"
SlashCmdList["SUMMONSAVER"] = function(message)
  SummonSaver:HandleSlash(message)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "summonsaver" then
    SummonSaver:ApplyDefaults()
    return
  end

  if event == "PLAYER_LOGIN" then
    if not SummonSaver:IsSupportedClient() or not SummonSaver:IsWarlock() then
      SummonSaver.disabled = true
      return
    end

    if SummonSaver.SecureUI and SummonSaver.SecureUI.Initialize then
      SummonSaver.SecureUI:Initialize()
      SummonSaver.secureReady = true
    end

    if SummonSaver.ConfigUI and SummonSaver.ConfigUI.Initialize then
      SummonSaver.ConfigUI:Initialize()
    end

    SummonSaver:Rebuild()
    SummonSaver:SetAnchorVisible(false)
    return
  end

  if SummonSaver.disabled then
    return
  end

  if event == "SPELLS_CHANGED" then
    SummonSaver:Rebuild()
    return
  end

  if event == "PLAYER_REGEN_DISABLED" then
    SummonSaver.inCombat = true
    if SummonSaver.ConfigUI and SummonSaver.ConfigUI.RefreshStatus then
      SummonSaver.ConfigUI:RefreshStatus()
    end
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    SummonSaver.inCombat = false
    if SummonSaver.pendingSecureUpdate then
      SummonSaver:RequestSecureRefresh()
    end
    if SummonSaver.ConfigUI and SummonSaver.ConfigUI.RefreshStatus then
      SummonSaver.ConfigUI:RefreshStatus()
    end
  end
end)
