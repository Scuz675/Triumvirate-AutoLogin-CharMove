Autologin_Table = {}

-- Triumvirate character-order storage helpers.
-- Character order is kept OUT of accountName/password data.
-- It is stored in the separate saved account-list string using: #CO:Name1,Name2;
function Triumvirate_StripCharacterOrderMarker(raw)
	raw = raw or "";
	raw = string.gsub(raw, "#CO:[^;]*;", "");
	return raw;
end

function Triumvirate_GetSavedCharacterOrderMarker()
	local raw = GetSavedAccountList() or "";
	return string.match(raw, "#CO:[^;]*;") or "";
end

function Triumvirate_SaveCharacterOrderMarker(marker)
	local list = GetSavedAccountList() or "";
	list = Triumvirate_StripCharacterOrderMarker(list);
	if marker and marker ~= "" then
		list = list .. marker;
	end
	SetSavedAccountList(list);
end

function Triumvirate_MigrateCharacterOrderMarker()
	local accountRaw = GetSavedAccountName() or "";
	local marker = string.match(accountRaw, "#CO:[^;]*;");
	if marker and marker ~= "" then
		accountRaw = Triumvirate_StripCharacterOrderMarker(accountRaw);
		SetSavedAccountName(accountRaw);
		Triumvirate_SaveCharacterOrderMarker(marker);
	end
end


Autologin_SelectedIdx = nil;
Autologin_CurrentPage = 0;
Autologin_PageSize = 4;
Autologin_LimitReached = false;

-- === Local-only obfuscation helpers (do NOT leak to _G) ===
do
  local b ='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local function b64enc(data)
    return ((data:gsub('.', function(x)
      local r,byte='',x:byte()
      for i=8,1,-1 do r = r .. (byte%2^i-byte%2^(i-1)>0 and '1' or '0') end
      return r
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
      if #x < 6 then return '' end
      local c=0; for i=1,6 do c=c+((x:sub(i,i)=='1') and 2^(6-i) or 0) end
      return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
  end
  local function b64dec(data)
    data = data:gsub('[^'..b..'=]','')
    return (data:gsub('.', function(x)
      if x=='=' then return '' end
      local r,f='', (b:find(x)-1)
      for i=6,1,-1 do r = r .. (f%2^i-f%2^(i-1)>0 and '1' or '0') end
      return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
      if #x~=8 then return '' end
      local c=0; for i=1,8 do c=c+((x:sub(i,i)=='1') and 2^(8-i) or 0) end
      return string.char(c)
    end))
  end
  local function xor_bytes(s, key)
    local out,kl={}, #key
    for i=1,#s do out[i]=string.char(bit.bxor(s:byte(i), key:byte(((i-1)%kl)+1))) end
    return table.concat(out)
  end

  -- >>> Change this per-user. Keep it local in code. <<<
  local LOCAL_KEY = "CHANGE THIS TO A LONG RANDOM STRING ON EACH UPDATE"

  local function derive(name)
    local key = LOCAL_KEY .. ":" .. (name or "")
    while #key < 64 do key = key .. key end
    return key
  end

  -- local-only helpers for this file:
  local function EAL_EncodePassword(plain, name)
    return "!e:" .. b64enc(xor_bytes(plain, derive(name)))
  end
  local function EAL_DecodePassword(token, name)
    if not token or token:sub(1,3) ~= "!e:" then return token end
    return xor_bytes(b64dec(token:sub(4)), derive(name))
  end

  -- expose to the rest of THIS file via upvalues
  _EAL_EncodePassword = EAL_EncodePassword
  _EAL_DecodePassword = EAL_DecodePassword
end

function Autologin_Load()
  if Triumvirate_MigrateCharacterOrderMarker then Triumvirate_MigrateCharacterOrderMarker(); end
  if next(AutoLoginAccounts) then
    Autologin_Table = AutoLoginAccounts
    AutologinRemoveAccountButton:Disable()
    AutologinClearCharacterButton:Disable()
    return
  end

  local val = Triumvirate_StripCharacterOrderMarker and Triumvirate_StripCharacterOrderMarker(GetSavedAccountName() or "") or (GetSavedAccountName() or "")
  Autologin_Table = {}

-- Triumvirate character-order storage helpers.
-- Character order is kept OUT of accountName/password data.
-- It is stored in the separate saved account-list string using: #CO:Name1,Name2;
function Triumvirate_StripCharacterOrderMarker(raw)
	raw = raw or "";
	raw = string.gsub(raw, "#CO:[^;]*;", "");
	return raw;
end

function Triumvirate_GetSavedCharacterOrderMarker()
	local raw = GetSavedAccountList() or "";
	return string.match(raw, "#CO:[^;]*;") or "";
end

function Triumvirate_SaveCharacterOrderMarker(marker)
	local list = GetSavedAccountList() or "";
	list = Triumvirate_StripCharacterOrderMarker(list);
	if marker and marker ~= "" then
		list = list .. marker;
	end
	SetSavedAccountList(list);
end

function Triumvirate_MigrateCharacterOrderMarker()
	local accountRaw = GetSavedAccountName() or "";
	local marker = string.match(accountRaw, "#CO:[^;]*;");
	if marker and marker ~= "" then
		accountRaw = Triumvirate_StripCharacterOrderMarker(accountRaw);
		SetSavedAccountName(accountRaw);
		Triumvirate_SaveCharacterOrderMarker(marker);
	end
end


local changed = false

  for n, p, c in string.gmatch(val, "([^%s]+)%s+([^%s]+)%s*(%d*);") do
    if c == "" then c = "-" end

    -- Legacy: resolve "~j" refs (old compressed saves)
    if type(p) == "string" and p:sub(1,1) == "~" then
      local refIndex = tonumber(p:sub(2))
      if refIndex and Autologin_Table[refIndex] then
        p = Autologin_Table[refIndex].password
      end
    end

    -- Migrate plaintext to encoded (salted by account name)
    if type(p) == "string" and p:sub(1,3) ~= "!e:" then
      p = _EAL_EncodePassword(p, n)
      changed = true
    end

    table.insert(Autologin_Table, { name = n, password = p, character = c })
  end

  -- If we migrated anything, rewrite the CVar (no compression)
  if changed then
    local parts = {}
    for i = 1, #Autologin_Table do
      local r = Autologin_Table[i]
      parts[#parts+1] = r.name .. " " .. r.password .. (r.character == "-" and ";" or (" " .. r.character .. ";"))
    end
    local savedVar = table.concat(parts, "")
    Autologin_LimitReached = string.len(savedVar) > 240
    SetSavedAccountName(savedVar)
  end
end


function Autologin_Save(name, password)
  if next(AutoLoginAccounts) then return end
  -- add/update in-memory table (store encoded token, salted by account name)
  if (name ~= nil and name ~= "" and password ~= nil and password ~= "") then
    local exists = false
    for i = 1, table.getn(Autologin_Table) do
      if (Autologin_Table[i].name == name) then
        exists = true
        local token = password
        if token:sub(1,3) ~= "!e:" then
          token = _EAL_EncodePassword(password, name) -- salt = account name
        end
        Autologin_Table[i].password = token
      end
    end
    if (not exists) then
      local token = (password:sub(1,3) == "!e:") and password or _EAL_EncodePassword(password, name)
      table.insert(Autologin_Table, { name = name, password = token, character = "-" })
    end
  end

  -- serialize to CVar (NO duplicate compression)
  local savedVar = ""
  for i = 1, table.getn(Autologin_Table) do
    local r = Autologin_Table[i]
    local pw = r.password  -- already encoded token
    savedVar = savedVar .. r.name .. " " .. pw
    if (r.character == "-") then
      savedVar = savedVar .. ";"
    else
      savedVar = savedVar .. " " .. r.character .. ";"
    end
  end

  Autologin_LimitReached = string.len(savedVar) > 240
  SetSavedAccountName(savedVar)
end


function Autologin_SelectAccount(idx)
  idx = tonumber(idx);
  if not idx then return end

  -- Button IDs are page-local (1-4), but Autologin_SelectedIdx must be absolute.
  local absoluteIdx = idx;
  if idx <= Autologin_PageSize then
    absoluteIdx = Autologin_CurrentPage * Autologin_PageSize + idx;
  end

  local row = Autologin_Table[absoluteIdx];
  if not row then return end

  -- Critical fix: update the selected row immediately.
  -- Without this, the yellow highlight and Remove Account can stay on the last saved account.
  Autologin_SelectedIdx = absoluteIdx;

  AccountLoginAccountEdit:SetText(row.name);

  local token = row.password;
  local pwd = token;
  if type(token) == "string" and token:sub(1,3) == "!e:" then
    pwd = _EAL_DecodePassword(token, row.name); -- salt = account name
  end
  if AccountLoginPasswordEdit and pwd then
    AccountLoginPasswordEdit:SetText(pwd);
  end

  -- Re-assert after SetText in case editbox scripts run while selecting.
  Autologin_SelectedIdx = absoluteIdx;
  Autologin_UpdateUI();
end


function Autologin_OnNameUpdate(name)
  Autologin_SelectedIdx = nil;
  for i = 1, table.getn(Autologin_Table) do
    if (Autologin_Table[i].name == name) then
      Autologin_SelectedIdx = i;
      break;
    end
  end
  if (Autologin_SelectedIdx) then
    Autologin_CurrentPage = math.floor((Autologin_SelectedIdx - 1) /
                                           Autologin_PageSize);
  end
  Autologin_UpdateUI();
end

function Autologin_UpdateUI()
  local skip = Autologin_CurrentPage * Autologin_PageSize;
  for i = 1, Autologin_PageSize do
    getglobal("AutologinAccountButton" .. i):UnlockHighlight();
    if (skip + i > table.getn(Autologin_Table)) then
      getglobal("AutologinAccountButton" .. i):Hide();
    else
      local r = Autologin_Table[skip + i];
      getglobal("AutologinAccountButton" .. i):Show();
      getglobal("AutologinAccountButton" .. i .. "ButtonTextName"):SetText(
          r.name);
      getglobal("AutologinAccountButton" .. i .. "ButtonTextPassword"):SetText(
          'Password: ******');

      if (r.character == '-') then
        getglobal("AutologinAccountButton" .. i .. "ButtonTextCharacter"):SetText(
            "");
      else
        getglobal("AutologinAccountButton" .. i .. "ButtonTextCharacter"):SetText(
            'Character: ' .. r.character);
      end

      if (Autologin_SelectedIdx == skip + i) then
        getglobal("AutologinAccountButton" .. i):LockHighlight();
      end
    end
  end

  if (Autologin_LimitReached) then
    getglobal("AutologinSizeWarning"):Show();
  else
    getglobal("AutologinSizeWarning"):Hide();
  end

  if AutologinRemoveAccountButton then
    if Autologin_SelectedIdx and Autologin_Table[Autologin_SelectedIdx] then
      AutologinRemoveAccountButton:Enable();
    else
      AutologinRemoveAccountButton:Disable();
    end
  end

  if AutologinClearCharacterButton then
    if Autologin_SelectedIdx and Autologin_Table[Autologin_SelectedIdx] then
      AutologinClearCharacterButton:Enable();
    else
      AutologinClearCharacterButton:Disable();
    end
  end
end

function Autologin_OnLogin()
  local name = AccountLoginAccountEdit:GetText();
  local password = AccountLoginPasswordEdit:GetText();

  -- Autologin OnLogin
  Autologin_Save(name, password);
  Autologin_OnNameUpdate(name);
  DefaultServerLogin(name, password);
  Autologin_Load();
  Autologin_UpdateUI();
end

function AutologinAccountButton_OnClick() Autologin_SelectAccount(this:GetID()); end

function AutologinAccountButton_OnDoubleClick()
  Autologin_SelectAccount(this:GetID());
  AccountLogin_Login();
end

function Autologin_RemoveAccount()
  if (not Autologin_SelectedIdx) then return end
  if (not Autologin_Table[Autologin_SelectedIdx]) then
    Autologin_SelectedIdx = nil;
    Autologin_UpdateUI();
    return;
  end

  table.remove(Autologin_Table, Autologin_SelectedIdx);
  Autologin_Save();
  AccountLoginAccountEdit:SetText("");
  AccountLoginPasswordEdit:SetText("");

  Autologin_SelectedIdx = nil;

  if (Autologin_CurrentPage > 0 and Autologin_CurrentPage * Autologin_PageSize >
      table.getn(Autologin_Table) - 1) then
    Autologin_CurrentPage = Autologin_CurrentPage - 1;
  end

  Autologin_UpdateUI();
end

function Autologin_ClearCharacter()
  if (not Autologin_SelectedIdx) then return end

  Autologin_Table[Autologin_SelectedIdx].character = '-';
  Autologin_Save();
  Autologin_UpdateUI();
end

function Autologin_NextPage()
  if ((Autologin_CurrentPage + 1) * Autologin_PageSize >
      table.getn(Autologin_Table) - 1) then return end
  Autologin_CurrentPage = Autologin_CurrentPage + 1;
  Autologin_UpdateUI();
end

function Autologin_PrevPage()
  if (Autologin_CurrentPage == 0) then return end
  Autologin_CurrentPage = Autologin_CurrentPage - 1;
  Autologin_UpdateUI();
end

-- === End merged autologin helpers ===

FADE_IN_TIME = 2;
DEFAULT_TOOLTIP_COLOR = {0.8, 0.8, 0.8, 0.09, 0.09, 0.09};
MAX_PIN_LENGTH = 10;

function AccountLogin_OnLoad(self)
	TOSFrame.noticeType = "EULA";

	self:RegisterEvent("SHOW_SERVER_ALERT");
	self:RegisterEvent("SHOW_SURVEY_NOTIFICATION");
	self:RegisterEvent("CLIENT_ACCOUNT_MISMATCH");
	self:RegisterEvent("CLIENT_TRIAL");
	self:RegisterEvent("SCANDLL_ERROR");
	self:RegisterEvent("SCANDLL_FINISHED");

	local versionType, buildType, version, internalVersion, date = GetBuildInfo();
	AccountLoginVersion:SetFormattedText(VERSION_TEMPLATE, versionType, version, internalVersion, buildType, date);

	-- Color edit box backdrops
	local backdropColor = DEFAULT_TOOLTIP_COLOR;
	AccountLoginAccountEdit:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	AccountLoginAccountEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
	AccountLoginPasswordEdit:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	AccountLoginPasswordEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
	AccountLoginTokenEdit:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	AccountLoginTokenEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
	TokenEnterDialogBackgroundEdit:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	TokenEnterDialogBackgroundEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);

	--self:SetCamera(0);
	--self:SetSequence(0);
	
	ShowScene(AccountLogin);
	self:SetScript("OnUpdate", function(self, elapsed)
		if UpdateLoginClouds then
			UpdateLoginClouds(elapsed);
		end
	end);
	--if (IsStreamingTrial()) then
	--	AccountLoginCinematicsButton:Disable();
	--	AccountLogin:SetModel("Interface\\Glues\\Models\\UI_MainMenu\\UI_MainMenu.m2");
	--else
	--	AccountLogin:SetModel("Interface\\Glues\\Models\\UI_MainMenu_Northrend\\UI_MainMenu_Northrend.m2");
	--end
end

function AccountLogin_OnShow(self)
	-- Triumvirate custom: migrate old character-order marker out of accountName.
	if Triumvirate_MigrateCharacterOrderMarker then Triumvirate_MigrateCharacterOrderMarker(); end
	-- Triumvirate custom: hide autologin retry panel and removed options.
	if AutologinControlPanel then AutologinControlPanel:Hide(); end
	if AutologinRetryButton then AutologinRetryButton:Hide(); end
	if AutologinStatusBox then AutologinStatusBox:Hide(); end
	if AccountLoginForceLogin then AccountLoginForceLogin:Hide(); AccountLoginForceLogin:SetChecked(0); end
	if AccountLoginForceLoginText then AccountLoginForceLoginText:Hide(); end
	if AccountLoginShowLauncher then AccountLoginShowLauncher:Hide(); end
	--AccountLoginTestButton:Show();
	--ServerAlertFrame:Show();

	if VX_SOUNDBG then
		SetCVar("Sound_EnableSoundWhenGameIsInBG", VX_SOUNDBG);
		VX_SOUNDBG = nil;
	end

	self:SetSequence(0);
	--PlayGlueMusic(CurrentGlueMusic);
	--PlayGlueAmbience(GlueAmbienceTracks["DARKPORTAL"], 4.0);

	-- Try to show the EULA or the TOS
	AccountLogin_ShowUserAgreements();
	
	local serverName = GetServerName();
	if(serverName) then
		AccountLoginRealmName:SetText(serverName);
		AccountServerListButton:SetText("Triumvirate");
		AccountServerListButton:SetWidth(AccountServerListButton:GetTextWidth());
	else
		AccountLoginRealmName:Hide()
	end

	-- Merged account/password autologin support.
	-- This uses the old GlueXML autologin store, but keeps the newer AutoEnterLogin screen/layout.
	Autologin_Load();
	if (table.getn(Autologin_Table) ~= 0) then
		-- Triumvirate fix: saved Select Account records exist, so keep Remember Account Name checked.
		if AccountLoginSaveAccountName then
			AccountLoginSaveAccountName:SetChecked(1);
		end
		local currentAccountName = AccountLoginAccountEdit:GetText();
		if currentAccountName and currentAccountName ~= "" then
			Autologin_OnNameUpdate(currentAccountName);
		else
			Autologin_SelectAccount(1);
		end
	end
	Autologin_UpdateUI();

	local accountName = AccountLoginAccountEdit:GetText();
	-- If this is a first run and the CVar still contains a plain account name, keep old behaviour.
	if accountName == "" then
		local savedAccount = GetSavedAccountName() or "";
		if savedAccount ~= "" and not string.find(savedAccount, ";") and not string.find(savedAccount, " ") then
			accountName = savedAccount;
			AccountLoginAccountEdit:SetText(savedAccount);
		end
	end
	--AccountLoginPasswordEdit:SetText("");
	AccountLoginTokenEdit:SetText("");
	if ( accountName and accountName ~= "" and GetUsesToken() ) then
		AccountLoginTokenEdit:Show()
	else
		AccountLoginTokenEdit:Hide()
	end
	
	AccountLogin_SetupAccountListDDL();
	
	if ( accountName == "" ) then
		AccountLogin_FocusAccountName();
	else
		AccountLogin_FocusPassword();
	end

	if( IsTrialAccount() ) then
		AccountLoginUpgradeAccountButton:Show();
	else
		AccountLoginUpgradeAccountButton:Hide();
	end

	ACCOUNT_MSG_NUM_AVAILABLE = 0;
	ACCOUNT_MSG_PRIORITY = 0;
	ACCOUNT_MSG_HEADERS_LOADED = false;
	ACCOUNT_MSG_BODY_LOADED = false;
	ACCOUNT_MSG_CURRENT_INDEX = nil;
end

function AccountLogin_OnHide(self)
	--Stop the sounds from the login screen (like the dragon roaring etc)
	StopAllSFX( 1.0 );

	-- Triumvirate fix:
	-- Do not clear saved account state from this custom login screen on hide.
	-- The Select Account panel uses saved account data and should survive opening/closing.
end

function AccountLogin_FocusPassword()
	AccountLoginPasswordEdit:SetFocus();
end

function AccountLogin_FocusAccountName()
	AccountLoginAccountEdit:SetFocus();
end

function AccountLogin_OnKeyDown(key)
	if ( key == "ESCAPE" ) then
		if ( ConnectionHelpFrame:IsShown() ) then
			ConnectionHelpFrame:Hide();
			AccountLoginUI:Show();
		elseif ( SurveyNotificationFrame:IsShown() ) then
			-- do nothing
		else
			AccountLogin_Exit();
		end
	elseif ( key == "ENTER" ) then
		if ( not TOSAccepted() ) then
			return;
		elseif ( TOSFrame:IsShown() or ConnectionHelpFrame:IsShown() ) then
			return;
		elseif ( SurveyNotificationFrame:IsShown() ) then
			AccountLogin_SurveyNotificationDone(1);
		end
		AccountLogin_Login();
	elseif ( key == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function AccountLogin_OnEvent(event, arg1, arg2, arg3)
	if ( event == "SHOW_SERVER_ALERT" ) then
		ServerAlertText:SetText(arg1);
		ServerAlertFrame:Show();
	elseif ( event == "SHOW_SURVEY_NOTIFICATION" ) then
		AccountLogin_ShowSurveyNotification();
	elseif ( event == "CLIENT_ACCOUNT_MISMATCH" ) then
		local accountExpansionLevel = arg1;
		local installationExpansionLevel = arg2;
		if ( accountExpansionLevel == 1 ) then
			GlueDialog_Show("CLIENT_ACCOUNT_MISMATCH", CLIENT_ACCOUNT_MISMATCH_BC);	
		else
			GlueDialog_Show("CLIENT_ACCOUNT_MISMATCH", CLIENT_ACCOUNT_MISMATCH_LK);	
		end
	elseif ( event == "CLIENT_TRIAL" ) then
		GlueDialog_Show("CLIENT_TRIAL");
	elseif ( event == "SCANDLL_ERROR" ) then
		GlueDialog:Hide();
		ScanDLLContinueAnyway();
		AccountLoginUI:Show();
	elseif ( event == "SCANDLL_FINISHED" ) then
		if ( arg1 == "OK" ) then
			GlueDialog:Hide();
			AccountLoginUI:Show();
		else
			AccountLogin.hackURL = _G["SCANDLL_URL_"..arg1];
			AccountLogin.hackName = arg2;
			AccountLogin.hackType = arg1;
			local formatString = _G["SCANDLL_MESSAGE_"..arg1];
			if ( arg3 == 1 ) then
				formatString = _G["SCANDLL_MESSAGE_HACKNOCONTINUE"];
			end
			local msg = format(formatString, AccountLogin.hackName, AccountLogin.hackURL);
			if ( arg3 == 1 ) then
				GlueDialog_Show("SCANDLL_HACKFOUND_NOCONTINUE", msg);
			else
				GlueDialog_Show("SCANDLL_HACKFOUND", msg);
			end
			PlaySoundFile("Sound\\Creature\\MobileAlertBot\\MobileAlertBotIntruderAlert01.wav");
		end
	end
end

function AccountLogin_Login()
	-- AccountLoginLoginButton:Disable()
	--if not AccountLoginForceLogin:GetChecked() then PlaySound("gsLogin");end
	Autologin_OnLogin();

	-- Force Login option removed/disabled for this build.
	if AccountLoginForceLogin then
		AccountLoginForceLogin:SetChecked(0);
	end
end

function AccountLogin_TOS()
	if ( not GlueDialog:IsShown() ) then
		PlaySound("gsLoginNewAccount");
		AccountLoginUI:Hide();
		TOSFrame:Show();
		TOSScrollFrameScrollBar:SetValue(0);		
		TOSScrollFrame:Show();
		TOSFrameTitle:SetText(TOS_FRAME_TITLE);
		TOSText:Show();
	end
end

function AccountLogin_ManageAccount()
	PlaySound("gsLoginNewAccount");
	LaunchURL("https://triumvirate-wow.com/login");
end

function AccountLogin_LaunchCommunitySite()
	PlaySound("gsLoginNewAccount");
	LaunchURL("https://triumvirate-wow.com");
end

function AccountLogin_LaunchDiscord()
	PlaySound("gsLoginNewAccount");
	LaunchURL("https://discord.gg/efU2QtUuFb");
end

function CharacterSelect_UpgradeAccount()
	PlaySound("gsLoginNewAccount");
	LaunchURL("https://triumvirate-wow.com/login");
end

function AccountLogin_Credits()
	CreditsFrame.creditsType = 3;
	PlaySound("gsTitleCredits");
	SetGlueScreen("credits");
end

function AccountLogin_Cinematics()
	if ( not GlueDialog:IsShown() ) then
		PlaySound("gsLoginNewAccount");
		if ( CinematicsFrame.numMovies > 1 ) then
			CinematicsFrame:Show();
			GlueFrameFadeIn(CinematicsFrame, VX_FADE_REFRESH);
		else
			MovieFrame.version = 1;
			SetGlueScreen("movie");
		end
	end
end

function AccountLogin_Options()
	PlaySound("gsTitleOptions");
end

function AccountLogin_Exit()
--	PlaySound("gsTitleQuit");
	QuitGame();
end

function AccountLogin_ShowSurveyNotification()
	GlueDialog:Hide();
	AccountLoginUI:Hide();
	SurveyNotificationAccept:Enable();
	SurveyNotificationDecline:Enable();
	SurveyNotificationFrame:Show();
end

function AccountLogin_SurveyNotificationDone(accepted)
	SurveyNotificationFrame:Hide();
	SurveyNotificationAccept:Disable();
	SurveyNotificationDecline:Disable();
	SurveyNotificationDone(accepted);
	AccountLoginUI:Show();
end

function AccountLogin_ShowUserAgreements()
	TOSScrollFrame:Hide();
	EULAScrollFrame:Hide();
	TerminationScrollFrame:Hide();
	ScanningScrollFrame:Hide();
	ContestScrollFrame:Hide();
	TOSText:Hide();
	EULAText:Hide();
	TerminationText:Hide();
	ScanningText:Hide();
	if ( not EULAAccepted() ) then
		if ( ShowEULANotice() ) then
			TOSNotice:SetText(EULA_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "EULA";
		TOSFrameTitle:SetText(EULA_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		EULAScrollFrame:Show();
		EULAText:Show();
		TOSFrame:Show();
	elseif ( not TOSAccepted() ) then
		if ( ShowTOSNotice() ) then
			TOSNotice:SetText(TOS_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "TOS";
		TOSFrameTitle:SetText(TOS_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		TOSScrollFrame:Show();
		TOSText:Show();
		TOSFrame:Show();
	elseif ( not TerminationWithoutNoticeAccepted() and SHOW_TERMINATION_WITHOUT_NOTICE_AGREEMENT ) then
		if ( ShowTerminationWithoutNoticeNotice() ) then
			TOSNotice:SetText(TERMINATION_WITHOUT_NOTICE_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "TERMINATION";
		TOSFrameTitle:SetText(TERMINATION_WITHOUT_NOTICE_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		TerminationScrollFrame:Show();
		TerminationText:Show();
		TOSFrame:Show();
	elseif ( not ScanningAccepted() and SHOW_SCANNING_AGREEMENT ) then
		if ( ShowScanningNotice() ) then
			TOSNotice:SetText(SCANNING_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "SCAN";
		TOSFrameTitle:SetText(SCAN_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		ScanningScrollFrame:Show();
		ScanningText:Show();
		TOSFrame:Show();
	elseif ( not ContestAccepted() and SHOW_CONTEST_AGREEMENT ) then
		if ( ShowContestNotice() ) then
			TOSNotice:SetText(CONTEST_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "CONTEST";
		TOSFrameTitle:SetText(CONTEST_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		ContestScrollFrame:Show();
		ContestText:Show();
		TOSFrame:Show();
	elseif ( not IsScanDLLFinished() ) then
		AccountLoginUI:Hide();
		TOSFrame:Hide();
		local dllURL = "";
		if ( IsWindowsClient() ) then dllURL = SCANDLL_URL_WIN32_SCAN_DLL; end
		ScanDLLStart(SCANDLL_URL_LAUNCHER_TXT, dllURL);
	else
		AccountLoginUI:Show();
		TOSFrame:Hide();
	end
end

function AccountLogin_UpdateAcceptButton(scrollFrame, isAcceptedFunc, noticeType)
	local scrollbar = _G[scrollFrame:GetName().."ScrollBar"];
	local min, max = scrollbar:GetMinMaxValues();

	-- HACK: scrollbars do not handle max properly
	-- DO NOT CHANGE - without speaking to Mikros/Barris/Thompson
	if (scrollbar:GetValue() >= max - 20) then
		TOSAccept:Enable();
	else
		if ( not isAcceptedFunc() and TOSFrame.noticeType == noticeType ) then
			TOSAccept:Disable();
		end
	end
end																

function ChangedOptionsDialog_OnShow(self)
	if ( not ShowChangedOptionWarnings() ) then
		self:Hide();
		return;
	end

	local options = ChangedOptionsDialog_BuildWarningsString(GetChangedOptionWarnings());
	if ( options == "" ) then
		self:Hide();
		return;
	end

	-- set text
	ChangedOptionsDialogText:SetText(options);

	-- resize the background to fit the text
	local textHeight = ChangedOptionsDialogText:GetHeight();
	local titleHeight = ChangedOptionsDialogTitle:GetHeight();
	local buttonHeight = ChangedOptionsDialogOkayButton:GetHeight();
	ChangedOptionsDialogBackground:SetHeight(26 + titleHeight + 16 + textHeight + 8 + buttonHeight + 16);
	self:Raise();
end

function ChangedOptionsDialog_OnKeyDown(self,key)
	if ( key == "PRINTSCREEN" ) then
		Screenshot();
		return;
	end

	if ( key == "ESCAPE" or key == "ENTER" ) then
		ChangedOptionsDialogOkayButton:Click();
	end
end

function ChangedOptionsDialog_BuildWarningsString(...)
	local options = "";
	for i=1, select("#", ...) do
		if ( i == 1 ) then
			options = select(1, ...);
		else
			options = options.."\n\n"..select(i, ...);
		end
	end
	return options;
end

-- Virtual keypad functions
function VirtualKeypadFrame_OnEvent(event, ...)
	if ( event == "PLAYER_ENTER_PIN" ) then
		for i=1, 10 do
			_G["VirtualKeypadButton"..i]:SetText(select(i,...));
		end							
	end
	-- Randomize location to prevent hacking (yeah right)
	local xPadding = 5;
	local yPadding = 10;
	local xPos = random(xPadding, GlueParent:GetWidth()-VirtualKeypadFrame:GetWidth()-xPadding);
	local yPos = random(yPadding, GlueParent:GetHeight()-VirtualKeypadFrame:GetHeight()-yPadding);
	VirtualKeypadFrame:SetPoint("TOPLEFT", GlueParent, "TOPLEFT", xPos, -yPos);
	
	VirtualKeypadFrame:Show();
	VirtualKeypad_UpdateButtons();
end

function VirtualKeypadButton_OnClick(self)
	local text = VirtualKeypadText:GetText();
	if ( not text ) then
		text = "";
	end
	VirtualKeypadText:SetText(text.."*");
	VirtualKeypadFrame.PIN = VirtualKeypadFrame.PIN..self:GetID();
	VirtualKeypad_UpdateButtons();
end

function VirtualKeypadOkayButton_OnClick()
	local PIN = VirtualKeypadFrame.PIN;
	local numNumbers = strlen(PIN);
	local pinNumber = {};
	for i=1, MAX_PIN_LENGTH do
		if ( i <= numNumbers ) then
			pinNumber[i] = strsub(PIN,i,i);
		else
			pinNumber[i] = nil;
		end
	end
	PINEntered(pinNumber[1] , pinNumber[2], pinNumber[3], pinNumber[4], pinNumber[5], pinNumber[6], pinNumber[7], pinNumber[8], pinNumber[9], pinNumber[10]);
	VirtualKeypadFrame:Hide();
end

function VirtualKeypad_UpdateButtons()
	local numNumbers = strlen(VirtualKeypadFrame.PIN);
	if ( numNumbers >= 4 and numNumbers <= MAX_PIN_LENGTH ) then
		VirtualKeypadOkayButton:Enable();
	else
		VirtualKeypadOkayButton:Disable();
	end
	if ( numNumbers == 0 ) then
		VirtualKeypadBackButton:Disable();
	else
		VirtualKeypadBackButton:Enable();
	end
	if ( numNumbers >= MAX_PIN_LENGTH ) then
		for i=1, MAX_PIN_LENGTH do
			_G["VirtualKeypadButton"..i]:Disable();
		end
	else
		for i=1, MAX_PIN_LENGTH do
			_G["VirtualKeypadButton"..i]:Enable();
		end
	end
end

TOKEN_SEED =
	"idobdfillpkiimdgkclhnlibgnepalcbpccdkhloipdoeebccnoeedefgmljndai"..
	"epicgamehpoifjbggbcihfanenmhkemffilglaebddmbakkhblpencadlaiepoga"..
	"ecpjojaijcefflabhilmmpgjiecbhamoceponkbjiogaodhnagencenlaeljhbna"..
	"ciglpffdnfgaaidccjjgbgiihhnbbjcbanhfdjadljkhmfknfnmpjblnelbfnnjf"..
	"dpakjehajomgjahhljnmnhnpadfkbopppiicnkkkhblkbibgajfmemhhimpjgcoe"..
	"mbkpilkleedkmpnckkcdbhnoanhpjeneinehgknalgglcbdcjdcppbjhgkahamgk"..
	"gijkofghdhopbkjjghmndfdpiadcdigefikbgccfhgkkbmkollbhlkbdobhaofbh"..
	"adbiepfnpiibfkcpflpkjpfmmhbopkcbcblaadaoodnoodgfhjpedmpballngmoo"..
	"bbmkgghdgmhdngbfpmikijmdjgddkeahhidkofihemfmolbcojpiapfkogbdenfc"..
	"cmahmfhlclfkeijbndcllbnffbjbbkfgdboiffhpkfgjckliookjlonenifdbenn"..
	"epeicoloceldnilhlkameoeceiobfnpeccaihhgjdgagjhmeljacpfljlhgnlhkj"..
	"dbihegomcbifklmmhmbaodnaehnbkikcjkloebkhmkhejakcdklndeiinidlgdhc"..
	"ddfbafimcpddekndmbcfemcpfihngpkoccjniboomialmgejaalnfogjofbfgbdk"..
	"poibhankhndpgeldkkdjgbknnahfdbcjhkmaciajeadkfmjcgaipjcilhhlagjcp"..
	"lnbeodabfpofdabnhckmnbjnofopfhglgiociaehalfcclkmjmobmjdbillmompm"..
	"jfgppnfgfancjglolkhoejogfjljnknoeiniiiimcifhlpiefmkkmhonbnppdndl"..
	"hmgpgcniinbaanciifdggklbgoanaihndbjpnannabbmfjkdjfkhimpccelcpjed"..
	"kgmpmpfnbmleiejkgbbknnnhambkmomlbjbhpkegehdfacdnbdfcmfagadbcaemg"..
	"ddhpjoacekfnakamgafmkodcplnhbhblcllikeglfnedlmkcoiegldlhikoncmca"..
	"bloiejelafbjjgmhapobofongodoojelpnkgfjdgpfckjglfbgaipbdpmbpjlcje"..
	"jcpgagffnmappkacgacmokedaicjklinmemijkojchoojjandkcdmjigjeldpepl"..
	"ihpenljefeechdndbdjkcipajcajghnhjackcjnoofebnmhimajekangghkfgcjm"..
	"hndedmcpmdilipgljglplhppcogaidkfaeibkedaihckjodddfblfonfnnljgcbi"..
	"hmnojjolaljebgiegnmjcficnkjchoakajkdhnchbljhonghjffebdobdcahpdjp"..
	"bmhpmnamkgpfjfbfgghjnabakoilmlbkhjoiegldbcdlijakkmehoemokdeafgjl"..
	"khmdjmbkdckdlidapcigbomjikehjddpblijhdgooegdfeinhaiponemlnffcnif"..
	"bkbnihminfmkfhbdneaaegofpacckahbgnmobgehalklcfkncogkanff";

-- TOKEN SYSTEM
function TokenEntryOkayButton_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTER_TOKEN");
end

function TokenEntryOkayButton_OnEvent(self, event)
	if (event == "PLAYER_ENTER_TOKEN") then
		if ( AccountLoginSaveAccountName:GetChecked() ) then
			if ( GetUsesToken() ) then
				if ( AccountLoginTokenEdit:GetText() ~= "" ) then
					TokenEntered(AccountLoginTokenEdit:GetText());
					return;
				end
			else
				SetUsesToken(true);
			end
		end
		self:Show();
	end
end

function TokenEntryOkayButton_OnShow()
	TokenEnterDialogBackgroundEdit:SetText("");
	TokenEnterDialogBackgroundEdit:SetFocus();
end

function TokenEntryOkayButton_OnKeyDown(self, key)
	if ( key == "ENTER" ) then
		TokenEntry_Okay(self);
	elseif ( key == "ESCAPE" ) then
		TokenEntry_Cancel(self);
	end
end

function TokenEntry_Okay(self)
	TokenEntered(TokenEnterDialogBackgroundEdit:GetText());
	TokenEnterDialog:Hide();
end

function TokenEntry_Cancel(self)
	TokenEnterDialog:Hide();
	CancelLogin();
end

-- WOW Account selection
function WoWAccountSelect_OnLoad(self)
	self:RegisterEvent("GAME_ACCOUNTS_UPDATED");
	self:RegisterEvent("OPEN_STATUS_DIALOG");
	WoWAccountSelectDialogBackgroundContainerScrollFrame.offset = 0
	CURRENT_SELECTED_WOW_ACCOUNT = 1;
end

function WoWAccountSelect_OnShow (self)
	AccountLoginAccountEdit:SetFocus();
	AccountLoginAccountEdit:ClearFocus();
	CURRENT_SELECTED_WOW_ACCOUNT = 1;
	WoWAccountSelect_Update();
end

function WoWAccountSelectButton_OnClick(self)
	CURRENT_SELECTED_WOW_ACCOUNT = self:GetID();
	WoWAccountSelect_Update();
end

function WoWAccountSelectButton_OnDoubleClick(self)
	WoWAccountSelect_SelectAccount(self:GetID());
end

function WoWAccountSelect_OnEvent(self, event)
	if ( event == "GAME_ACCOUNTS_UPDATED" ) then
		local str, selectedIndex, selectedName = ""
		for i = 1, GetNumGameAccounts() do
			local name = GetGameAccountInfo(i);
			if ( name == GlueDropDownMenu_GetText(AccountLoginDropDown) ) then
				selectedName = name;
				selectedIndex = i;
			end
			str = str .. name .. "|";
		end
		
		if ( str == strreplace(GetSavedAccountList(), "!", "") and selectedIndex ) then
			WoWAccountSelect_SelectAccount(selectedIndex);
			return;
		else
			self:Show();
		end
	else
		self:Hide();
	end
end

function WoWAccountSelect_SelectAccount(index)
	if ( AccountLoginSaveAccountName:GetChecked() ) then
		WowAccountSelect_UpdateSavedAccountNames(index);
	else
		SetSavedAccountList("");
	end
	WoWAccountSelectDialog:Hide();
	SetGameAccount(index);
end

function WowAccountSelect_UpdateSavedAccountNames(selectedIndex)
	local count = GetNumGameAccounts();
	
	local str = ""
	for i = 1, count do
		local name = GetGameAccountInfo(i);
		if ( i == selectedIndex ) then
			str = str .. "!" .. name .. "|";
		else
			str = str .. name .. "|";
		end
	end
	SetSavedAccountList(str);
end

ACCOUNTNAME_BUTTON_HEIGHT = 20;

function WoWAccountSelect_OnVerticalScroll (self, offset)
	local scrollbar = _G[self:GetName().."ScrollBar"];
	scrollbar:SetValue(offset);
	WoWAccountSelectDialogBackgroundContainerScrollFrame.offset = floor((offset / ACCOUNTNAME_BUTTON_HEIGHT) + 0.5);
	WoWAccountSelect_Update();
end

MAX_ACCOUNTS_DISPLAYED = 8;
function WoWAccountSelect_Update()
    local count = GetNumGameAccounts();
	
	local offset = WoWAccountSelectDialogBackgroundContainerScrollFrame.offset;
	for index=1, MAX_ACCOUNTS_DISPLAYED do
		local button = _G["WoWAccountSelectDialogBackgroundContainerButton" .. index];
		local name, regionID = GetGameAccountInfo(index + offset);
		button:SetButtonState("NORMAL");
		button.BG_Highlight:Hide();
		if ( name ) then
			button:SetID(index + offset);
			button:SetText(name);
			button.regionID = regionID;
			button:Show();
			if ( index == CURRENT_SELECTED_WOW_ACCOUNT) then
				button.BG_Highlight:Show();
			end
		else
			button:Hide();
		end
	end
	
	GlueScrollFrame_Update(WoWAccountSelectDialogBackgroundContainerScrollFrame, count, MAX_ACCOUNTS_DISPLAYED, ACCOUNTNAME_BUTTON_HEIGHT);
end

function WoWAccountSelect_AccountButton_OnClick(self, button)
	CURRENT_SELECTED_WOW_ACCOUNT = self:GetID();
	WoWAccountSelect_Accept();
end

function WoWAccountSelect_OnKeyDown(self, key)
	if ( key == "ESCAPE" ) then
		WoWAccountSelect_OnCancel(self);
	elseif ( key == "UP" ) then
		CURRENT_SELECTED_WOW_ACCOUNT = max(1, CURRENT_SELECTED_WOW_ACCOUNT - 1);
		WoWAccountSelect_Update()
	elseif ( key == "DOWN" ) then
		CURRENT_SELECTED_WOW_ACCOUNT = min(GetNumGameAccounts(), CURRENT_SELECTED_WOW_ACCOUNT + 1);
		WoWAccountSelect_Update()
	elseif ( key == "ENTER" ) then
		WoWAccountSelect_SelectAccount(CURRENT_SELECTED_WOW_ACCOUNT);
	elseif ( key == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function WoWAccountSelect_OnCancel (self)
	self:Hide();
	GlueDialog:Hide();
	CancelLogin();
end

function WoWAccountSelect_Accept()
	WoWAccountSelect_SelectAccount(CURRENT_SELECTED_WOW_ACCOUNT);
end



function AccountListDropDown_OnClick(self)
	--GlueDropDownMenu_SetSelectedValue(AccountLoginDropDown, self.value);
	if strsub(self.value, 1, 3) == "rlm" then
		for i = 1, #vx.ServerList, 1 do
			if vx.ServerList[i].Host then
				if vx.ServerList[i].Host == GetCVar("realmlist") then
					AccountLoginAccountEdit:SetText(strrev(strsub(vx.ServerList[i].AccountList[tonumber(strsub(self.value, 4))].Login, 16)));
					AccountLoginPasswordEdit:SetText(strrev(strsub(vx.ServerList[i].AccountList[tonumber(strsub(self.value, 4))].Password, 19)));
				end
			end
		end
	elseif strsub(self.value, 1, 3) == "all" then
		AccountLoginAccountEdit:SetText(strrev(strsub(vx.AccountList[tonumber(strsub(self.value, 4))].Login, 16)));
		AccountLoginPasswordEdit:SetText(strrev(strsub(vx.AccountList[tonumber(strsub(self.value, 4))].Password, 19)));
	end
end

function AccountListDropDown_Initialize()
	local info = {};
	local count = 0;

	if vx.ServerList then
		for i = 1, #vx.ServerList, 1 do
			if vx.ServerList[i].Host then
				if vx.ServerList[i].Host == GetCVar("realmlist") then
					if vx.ServerList[i].AccountList then
						for j = 1, #vx.ServerList[i].AccountList, 1 do
							info.text = strrev(strsub(vx.ServerList[i].AccountList[j].Login, 16));
							info.value = "rlm"..j
							info.func = AccountListDropDown_OnClick;
							GlueDropDownMenu_AddButton(info);
							count = count + 1;
						end
					end
				end
			end
		end
	end

	if (vx.AccountList) and (#vx.AccountList>0) then
		if info.text then
			info.text = VX_ACCOUNT_SEPARATOR;
			info.disabled = 1;
			info.func = nil;
			GlueDropDownMenu_AddButton(info);
		end

		info={};

		for i = 1, #vx.AccountList do
			info.text = strrev(strsub(vx.AccountList[i].Login,16))
			info.value = "all"..i
			info.func = AccountListDropDown_OnClick;
			GlueDropDownMenu_AddButton(info);
			count = count + 1;
		end
	end
	if count > 0 then
		AccountListDropDown:Show();
	else
		AccountListDropDown:Hide();
	end
end



function AccountLoginDropDown_OnClick(self)
	GlueDropDownMenu_SetSelectedValue(AccountLoginDropDown, self.value);
end

function AccountLoginDropDown_Initialize()
	local selectedValue = GlueDropDownMenu_GetSelectedValue(AccountLoginDropDown);
	local info;

	for i = 1, #AccountList do
		AccountList[i].checked = (AccountList[i].text == selectedValue);
		GlueDropDownMenu_AddButton(AccountList[i]);
	end
end

AccountList = {};
function AccountLogin_SetupAccountListDDL()
	local savedAccountList = GetSavedAccountList() or "";
	if Triumvirate_StripCharacterOrderMarker then
		savedAccountList = Triumvirate_StripCharacterOrderMarker(savedAccountList);
	end

	if ( GetSavedAccountName() ~= "" and savedAccountList ~= "" ) then
		AccountLoginPasswordEdit:SetPoint("BOTTOM", 0, 255);
		AccountLoginLoginButton:SetPoint("BOTTOM", 0, 150);
		AccountLoginDropDown:Show();
	else
		AccountLoginPasswordEdit:SetPoint("BOTTOM", 0, 275);
		AccountLoginLoginButton:SetPoint("BOTTOM", 0, 170);
		AccountLoginDropDown:Hide();
		return;
	end

	AccountList = {};
	local i = 1;
	for str in string.gmatch(savedAccountList, "([%w!]+)|?") do
		local selected = false;
		if ( strsub(str, 1, 1) == "!" ) then
			selected = true;
			str = strsub(str, 2, #str);
			GlueDropDownMenu_SetSelectedName(AccountLoginDropDown, str);
			GlueDropDownMenu_SetText(str, AccountLoginDropDown);
		end
		AccountList[i] = { ["text"] = str, ["value"] = str, ["selected"] = selected, func = AccountLoginDropDown_OnClick };
		i = i + 1;
	end
end

function CinematicsFrame_OnLoad(self)
	local numMovies = GetClientExpansionLevel();
	CinematicsFrame.numMovies = numMovies;
	if ( numMovies < 2 ) then
		return;
	end
	
	for i = 1, numMovies do
		_G["CinematicsButton"..i]:Show();
	end
	CinematicsBackground:SetHeight(numMovies * 51 + 16 * 2 + 50);
	local maxbuttonwidth = CinematicsButton1:GetWidth();
	if CinematicsButton2:GetWidth() > maxbuttonwidth then maxbuttonwidth = CinematicsButton2:GetWidth(); end
	if CinematicsButton3:GetWidth() > maxbuttonwidth then maxbuttonwidth = CinematicsButton3:GetWidth(); end
	CinematicsBackground:SetWidth(maxbuttonwidth + 32);
end

function CinematicsFrame_OnKeyDown(key)
	if ( key == "PRINTSCREEN" ) then
		Screenshot();
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
		GlueFrameFadeOut(CinematicsFrame, VX_FADE_REFRESH, "HIDE");
		--CinematicsFrame:Hide();
	end	
end

function Cinematics_PlayMovie(self)
	CinematicsFrame:Hide();
	PlaySound("gsTitleOptionOK");
	CinematicsFrame.id = self:GetID();
	--GlueFrameFadeOut(AccountLogin, VX_FADE_UNLOAD, Cinematics_PlayMovie_Wait);
--end

--function Cinematics_PlayMovie_Wait()
	MovieFrame.version = CinematicsFrame.id;
	CinematicsFrame.id = nil;
	SetGlueScreen("movie");
end