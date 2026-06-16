function GetSceneName(vx_scene)
	if     vx_scene == "cl" then return "Interface\\Glues\\Models\\UI_MainMenu\\UI_MainMenu.m2", "GlueScreenIntro", "";
	elseif vx_scene == "bc" then return "Interface\\Glues\\Models\\UI_MainMenu_BurningCrusade\\UI_MainMenu_BurningCrusade.m2", "GlueScreenIntro", "";
	elseif vx_scene == "lk" then return "Interface\\Glues\\Models\\UI_MainMenu_Northrend\\UI_MainMenu_Northrend.m2", "GlueScreenIntro", "";
	elseif vx_scene == "be" then return "Interface\\Glues\\Models\\UI_BloodElf\\UI_BloodElf.m2", "GlueScreenBloodElf", "";
	elseif vx_scene == "dk" then return "Interface\\Glues\\Models\\UI_DeathKnight\\UI_DeathKnight.m2", "GlueScreenIntro", "";
	elseif vx_scene == "dr" then return "Interface\\Glues\\Models\\UI_Draenei\\UI_DRAENEI.M2", "GlueScreenDraenei", "";
	elseif vx_scene == "dg" then return "Interface\\Glues\\Models\\UI_Dwarf\\UI_Dwarf.m2", "GlueScreenDwarfGnome", "";
	elseif vx_scene == "hm" then return "Interface\\Glues\\Models\\UI_Human\\UI_Human.m2", "GlueScreenHuman", "";
	elseif vx_scene == "ne" then return "Interface\\Glues\\Models\\UI_NightElf\\UI_NightElf.m2", "GlueScreenNightElf", "";
	elseif vx_scene == "ot" then return "Interface\\Glues\\Models\\UI_Orc\\UI_Orc.m2", "GlueScreenOrcTroll", "";
	elseif vx_scene == "ud" then return "Interface\\Glues\\Models\\UI_Scourge\\UI_Scourge.m2", "GlueScreenUndead", "";
	elseif vx_scene == "tr" then return "Interface\\Glues\\Models\\UI_Tauren\\UI_Tauren.m2", "GlueScreenTauren", "";
	elseif vx_scene == "cs" then return "Interface\\Glues\\Models\\UI_CharacterSelect\\UI_CharacterSelect.M2", "GlueScreenIntro", "";
	elseif vx_scene == "blank" then return "Environments\\Stars\\Stars.m2", "GlueScreenIntro", "";
	elseif string.find(vx_scene, "\\") then
		if strsub(vx_scene, strlen(vx_scene) - 2) == ".m2" then
			return		    vx_scene, "GlueScreenIntro", "";
		else
			return		    "Environments\\Stars\\Stars.m2", "GlueScreenIntro", vx_scene;
		end
	else return 			    "Interface\\Glues\\Models\\UI_MainMenu\\UI_MainMenu.m2", "GlueScreenIntro", "";
	end
end

if vx.SceneList and #vx.SceneList > 0 then
	local ambience
	local bgtexture
	vx["Ambience"] = {};
	vx["BGTexture"] = {};
	for i = 1, #vx.SceneList, 1 do
		vx.SceneList[i], ambience, bgtexture = GetSceneName(vx.SceneList[i]);
		tinsert(vx.Ambience,ambience);
		tinsert(vx.BGTexture,bgtexture);
	end
else
	vx["SceneList"] = {"Interface\\Glues\\Models\\UI_MainMenu\\UI_MainMenu.m2"};
	vx["Ambience"] = {"GlueScreenIntro"};
	vx["BGTexture"] = {""};
end

function ShowScene(self)
	-- Triumvirate custom static background: login screen only.
	-- Character select / realm wizard keep the normal 3D scene behaviour below.
	if self == AccountLogin then
		if VXBGTextureAL then
			VXBGTextureAL:SetTexture("Interface\\Glues\\Common\\Triumvirate-Login-Background");
			VXBGTextureAL:SetTexCoord(0, 1, 0.218750, 0.781250);
			VXBGTextureAL:Show();
		end
		if Triumvirate_ShowLoginClouds then
			Triumvirate_ShowLoginClouds();
		end
		if VXBGTextureCS then VXBGTextureCS:Hide(); end
		if VXBGTextureRW then VXBGTextureRW:Hide(); end
		self:SetModel("Environments\\Stars\\Stars.m2");
		self:SetCamera(0);
		self:SetSequence(0);
		PlayGlueAmbience("GlueScreenIntro", 4.0);
		PlayLoginMusic();
		return;
	end

	if Triumvirate_HideLoginClouds then
		Triumvirate_HideLoginClouds();
	end

	local rnd = random(1,#vx.SceneList);
	if vx.BGTexture[rnd] == "" then
		if VXBGTextureAL then VXBGTextureAL:Hide(); end
		if VXBGTextureCS then VXBGTextureCS:Hide(); end
		if VXBGTextureRW then VXBGTextureRW:Hide(); end
	else
		if VXBGTextureAL then
			VXBGTextureAL:SetTexture(vx.BGTexture[rnd]);
			VXBGTextureAL:SetTexCoord(0, 1, 0, 1);
			VXBGTextureAL:Show();
		end
		if VXBGTextureCS then
			VXBGTextureCS:SetTexture(vx.BGTexture[rnd]);
			VXBGTextureCS:SetTexCoord(0, 1, 0, 1);
			VXBGTextureCS:Show();
		end
		if VXBGTextureRW then
			VXBGTextureRW:SetTexture(vx.BGTexture[rnd]);
			VXBGTextureRW:SetTexCoord(0, 1, 0, 1);
			VXBGTextureRW:Show();
		end
	end
	self:SetModel(vx.SceneList[rnd]);
	self:SetCamera(0);
	self:SetSequence(0);
	PlayGlueAmbience(vx.Ambience[rnd], 4.0);
	PlayLoginMusic();
end

if not VX_LOGO_TEXTURE then
	if VX_LOGO then
		if VX_LOGO == "encl" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WoW-Logo";
		elseif VX_LOGO == "enbc" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\GLUES-WOW-BCLOGO";
		elseif VX_LOGO == "enlk" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WoW-WotLKLogo";
		elseif VX_LOGO == "enLK" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WOW-WoltkLogo";
		elseif VX_LOGO == "chcl" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WoW-ChineseLogo";
		elseif VX_LOGO == "chbc" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WoW-ChineseBCLogo";
		elseif VX_LOGO == "chlk" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WoW-ChineseWotLKLogo";
		elseif VX_LOGO == "twcl" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WoW-TaiwanLogo";
		elseif VX_LOGO == "twbc" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\GLUES-WOW-TAIWANBCLOGO";
		elseif VX_LOGO == "twlk" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WoW-TaiwanWotLKLogo";
		elseif VX_LOGO == "encs" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-Logo";
		elseif VX_LOGO == "twcs" then
			VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-Logo-Taiwan";
		end
		VX_LOGO = nil;
	else
		VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WoW-Logo";
	end
end


function ConvertAccountString(account)
	if account.Login then
		account.Login = "VX_Login_string"..strrev(account.Login);
	else
		account.Login = "";
	end
	if account.Password then
		account.Password = "VX_Password_string"..strrev(account.Password);
	else
		account.Password = "";
	end
	return account
end

if vx.ServerList then
	for i = 1, #vx.ServerList, 1 do
		if vx.ServerList[i].AccountList then
			for j = 1, #vx.ServerList[i].AccountList, 1 do
				vx.ServerList[i].AccountList[j] = ConvertAccountString(vx.ServerList[i].AccountList[j]);
			end
		end
	end
end

if vx.AccountList then
	for i = 1, #vx.AccountList, 1 do
		vx.AccountList[i] = ConvertAccountString(vx.AccountList[i]);
	end
end

function GetMusicPath(track)
	if track.Duration and track.Track then
		track.Duration = tonumber(track.Duration);
	else
		if not track.Track then track["Track"] = "cl"; end
		if track.Track == "bc" then
			track["Duration"] = 227;
			track["Track"] = "Sound\\Music\\GlueScreenMusic\\BC_main_theme.mp3";
		elseif track.Track == "lk" then
			track["Duration"] = 544;
			track["Track"] = "Sound\\Music\\GlueScreenMusic\\WotLK_main_title.mp3";
		else
			track["Duration"] = 161;
			track["Track"] = "Sound\\Music\\GlueScreenMusic\\wow_main_theme.mp3";
		end
	end
	return track
end

if vx.LoginMusic and #vx.LoginMusic > 0 then
	for i = 1, #vx.LoginMusic, 1 do
		vx.LoginMusic[i] = GetMusicPath(vx.LoginMusic[i]);
	end
else
	vx["LoginMusic"] = {["Duration"] = 161, ["Track"] = "Sound\\Music\\GlueScreenMusic\\wow_main_theme.mp3"};
end

VX_CloudOffset1 = 0;
VX_CloudSpeed1 = 4.0; -- v4 visible drift

function Triumvirate_SetCloudTexture(tex, alpha)
	if not tex then return; end
	tex:SetTexture("Interface\\Glues\\Common\\Triumvirate-Login-Clouds");
	tex:SetTexCoord(0, 1, 0.218750, 0.781250);
	tex:SetBlendMode("BLEND");
	tex:SetVertexColor(1.0, 1.0, 1.0, alpha);
	tex:Show();
end

function Triumvirate_PositionCloud(tex, xOffset)
	if not tex then return; end
	tex:ClearAllPoints();
	tex:SetPoint("CENTER", AccountLogin, "CENTER", xOffset, 0);
end

function Triumvirate_ShowLoginClouds()
	Triumvirate_SetCloudTexture(VXCloudTextureAL1A, 0.42);
	Triumvirate_SetCloudTexture(VXCloudTextureAL1B, 0.42);
	VX_CloudOffset1 = 0;
	Triumvirate_PositionCloud(VXCloudTextureAL1A, 0);
	Triumvirate_PositionCloud(VXCloudTextureAL1B, 1024);
end

function Triumvirate_HideLoginClouds()
	if VXCloudTextureAL1A then VXCloudTextureAL1A:Hide(); end
	if VXCloudTextureAL1B then VXCloudTextureAL1B:Hide(); end
end

function UpdateLoginClouds(elapsed)
	if not VXCloudTextureAL1A or not VXCloudTextureAL1A:IsShown() then return; end
	if not elapsed then elapsed = 0.02; end

	VX_CloudOffset1 = VX_CloudOffset1 + VX_CloudSpeed1 * elapsed;
	if VX_CloudOffset1 >= 1024 then VX_CloudOffset1 = VX_CloudOffset1 - 1024; end


	Triumvirate_PositionCloud(VXCloudTextureAL1A, VX_CloudOffset1);
	Triumvirate_PositionCloud(VXCloudTextureAL1B, VX_CloudOffset1 - 1024);
end

function PlayLoginMusic()
	if VX_ONMUSIC then return; end
	local rnd = random(1,#vx.LoginMusic);
	StopGlueMusic();

	VX_MUSICTIMER = GetTime() + vx.LoginMusic[rnd].Duration;
	VX_ONMUSIC = true;
	PlayMusic(vx.LoginMusic[rnd].Track);
end

function StopLoginMusic()
	StopMusic();
	StopGlueMusic();
	VX_ONMUSIC = nil;
	VX_MUSICTIMER = nil;
end
