
-- haven't foolproof! be careful when edit

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--|||| list of servers |||||||
vx = {
	["ServerList"] = {
		{
			["Host"] = "triumvirate-wow.com",
			["Portal"] = "en",
			["Description"] = "Triumvirate",
			["AccountList"] = {
			},
		},
	},
	["SceneList"] = {
			-- fixed scene: classic
			"cl", -- classic
			},
	["LoginMusic"] ={
		{["Track"] = "cl"}, -- duration for basic tracks is not required
		{["Track"] = "bc"}, -- if you don't want random selection after time of track is finished,
		{["Track"] = "lk"}, -- keep only one string
		
		--{["Duration"] = "74", ["Track"] = "Sound\\BT_IllidariWalkHero09.mp3"}		
		--{["Duration"] = "726", ["Track"] = "Sound\\Cataclysm_main_title.mp3"}
		-- use your own internal or external. you can use more - just add string like below
		-- duration required and must be in seconds, path must be with double slashes.
		-- like playlist x)
		--{["Duration"] = "197", ["Track"] = "Sound\\11-AudioTrack 11.mp3"}, -- i.e. "Sound" folder in wow root folder
		--{["Duration"] = "185", ["Track"] = "Sound\\Apocaliptica - Path.mp3"},
	}
}

--////////////////////////////

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--|||| logo banner |||||||||||
--"xxyy" there:
-- xx - locale ("en" - english, "ch" - chinese or "tw" - taiwan)
-- yy - type ("cl" - classic, "bc" - burning crusade or "lk" - lich king)
-- or "enLK" - alt english lich king logo, "encs" - english classic small, "twcs" - taiwan classic small
VX_LOGO = "enlk"
--you can set your own, just unrem and edit path. important - use double slashes in path, not single.
VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Triumvirate-WoW-Login-Logo";
--////////////////////////////

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--|||| fade times ||||||||||||
VX_FADE_LOAD = 0; -- time in seconds
VX_FADE_UNLOAD = 0; -- time in seconds
VX_FADE_REFRESH = 0; -- time in seconds
--////////////////////////////

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--||||| localization |||||||||
VX_SERVERLIST_SERVER_SELECTION = "Server Selection";
VX_SERVERLIST_SERVER_NAME = "Server Name";
VX_SERVERLIST_SERVER_DESCRIPTION = "Server Description";
VX_FORCE_LOGIN = "Force login";
VX_ACCOUNT_SEPARATOR = "---"

--VX_SERVERLIST_SERVER_SELECTION = "Выбор сервера";
--VX_SERVERLIST_SERVER_NAME = "Имя сервера";
--VX_SERVERLIST_SERVER_DESCRIPTION = "Описание сервера";
--VX_FORCE_LOGIN = "Ускоренный вход";
--VX_ACCOUNT_SEPARATOR = "--"
--////////////////////////////
