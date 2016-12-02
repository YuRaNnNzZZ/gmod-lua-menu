
/*
lua_run for i=0, 64 do for j=0,70 do local a = ents.Create("prop_physics") a:SetPos(Vector(i*70, j*70, 0)) a:SetModel("models/hunter/plates/plate1x1.mdl") a:Spawn() a:PhysicsDestroy() end end
lua_run Awd = 0 for i=0, 24 do for j=0,24 do local a = ents.Create("prop_physics") a:SetPos(Vector(-1500 + i*128, j*128-1000, -12735)) a:SetModel("models/hunter/plates/plate1x1.mdl") a:Spawn() a:PhysicsDestroy() Awd = (Awd or 0)+1 end end print(Awd)
*/

ScreenScale = function( size ) return size * ( ScrW() / 640.0 ) end

include( 'getmaps.lua' )
include( 'addons.lua' )
include( 'new_game.lua' )
include( 'achievements.lua' )
include( 'main.lua' )
include( '_errors.lua' )
include( '../background.lua' )
//include( 'enumdump.lua' )

pnlMainMenu = nil

local PANEL = {}

function PANEL:SetSpecial( b )
	self.Special = b
end

local matGradientUp = Material( "gui/gradient_up" )
function PANEL:Paint( w, h )
	if ( !self.Special ) then
		self:SetFGColor( color_black )
		local clr =  color_white
		if ( self.Hovered ) then clr =  Color( 255, 255, 220 ) end
		if ( self.Depressed ) then self:SetFGColor( color_white ) clr = Color( 35, 150, 255 ) end
		draw.RoundedBox( 4, 0, 0, w, h, clr )
	else
		self:SetFGColor( color_white )
		local clr = Color( 0, 134, 204 )
		if ( self.Hovered ) then clr = Color( 34, 168, 238 ) end
		if ( self.Depressed ) then clr = Color( 0, 134, 204 ) end
		//draw.RoundedBox( 4, 0, 0, w, h, clr )

		surface.SetDrawColor( clr )
		surface.DrawRect( 1, 1, w - 2, h - 2 )

		surface.SetDrawColor( Color( 0, 85, 204 ) )
		if ( self.Hovered ) then clr = surface.SetDrawColor( Color( 34, 119, 238 ) ) end
		surface.SetMaterial( matGradientUp )
		surface.DrawTexturedRect( 1, 1, w - 2, h - 2 )

		surface.SetDrawColor( Color( 0, 85, 204 ) )
		//surface.DrawOutlinedRect( 0, 0, w, h )

		surface.DrawLine( 1, 0, w-1, 0 ) -- top
		surface.DrawLine( 0, 1, 0, h - 1 ) -- left
		surface.DrawLine( w - 1, 1, w - 1, h - 1 ) -- right

		surface.SetDrawColor( Color( 0, 53, 128 ) )
		surface.DrawLine( 1, h - 1, w-1, h - 1 ) -- bottom

		local clr = Color( 52, 160, 214 )
		if ( self.Hovered ) then clr = Color( 79, 187, 241 ) end
		if ( self.Depressed ) then clr = Color( 52, 160, 214 ) end
		surface.SetDrawColor( clr )
		surface.DrawLine( 1, 1, w - 1, 1 )
	end
end

vgui.Register( "DMenuButton", PANEL, "DButton" )

local PANEL = {}

function PANEL:Init()

	self:Dock( FILL )
	self:SetKeyboardInputEnabled( true )
	self:SetMouseInputEnabled( true )

	local lowerPanel = vgui.Create( "DPanel", self )
	function lowerPanel:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 220 ) )
	end
	lowerPanel:SetTall( 50 )
	lowerPanel:Dock( BOTTOM )

	local BackButton = vgui.Create( "DMenuButton", lowerPanel )
	BackButton:Dock( LEFT )
	BackButton:SetText( "#back_to_main_menu" )
	BackButton:SetIcon( "icon16/arrow_left.png" )
	BackButton:SetContentAlignment( 6 )
	BackButton:SetTextInset( BackButton.m_Image:GetWide() + 20, 0 )
	BackButton:SizeToContents()
	BackButton:SetVisible( false )
	BackButton:DockMargin( 5, 5, 5, 5 )
	BackButton.DoClick = function()
		self:Back()
	end
	function BackButton:PerformLayout()
		if ( IsValid( self.m_Image ) ) then
			self.m_Image:SetPos( 5, ( self:GetTall() - self.m_Image:GetTall() ) * 0.5 )
			self:SetTextInset( 10, 0 )
		end
		DLabel.PerformLayout( self )
	end
	self.BackButton = BackButton

	local Gamemodes = vgui.Create( "DMenuButton", lowerPanel )
	Gamemodes:Dock( RIGHT )
	Gamemodes:DockMargin( 5, 5, 5, 5 )
	Gamemodes:SetContentAlignment( 6 )
	Gamemodes.DoClick = function()
		self:OpenGamemodesList( Gamemodes )
	end
	function Gamemodes:PerformLayout()
		if ( IsValid( self.m_Image ) ) then
			self.m_Image:SetPos( 5, ( self:GetTall() - self.m_Image:GetTall() ) * 0.5 )
			self:SetTextInset( 10, 0 )
		end
		DLabel.PerformLayout( self )
	end
	self.GamemodeList = Gamemodes
	self:RefreshGamemodes()

	local MountedGames = vgui.Create( "DMenuButton", lowerPanel )
	MountedGames:Dock( RIGHT )
	MountedGames:DockMargin( 5, 5, 0, 5 )
	MountedGames:SetText( "" )
	MountedGames:SetWide( 48 )
	MountedGames:SetIcon( "../html/img/back_to_game.png" )
	MountedGames.DoClick = function()
		self:OpenMountedGamesList( MountedGames )
	end
	function MountedGames:PerformLayout()
		if ( IsValid( self.m_Image ) ) then
			self.m_Image:SetPos( ( self:GetWide() - self.m_Image:GetWide() ) * 0.5, ( self:GetTall() - self.m_Image:GetTall() ) * 0.5 )
		end
		DLabel.PerformLayout( self )
	end
	self.MountedGames = MountedGames

	local Languages = vgui.Create( "DMenuButton", lowerPanel )
	Languages:Dock( RIGHT )
	Languages:DockMargin( 5, 5, 0, 5 )
	Languages:SetText( "" )
	Languages:SetWide( 40 )
	Languages:SetIcon( "../resource/localization/" .. GetConVarString( "gmod_language" ) .. ".png" )
	Languages.DoClick = function()
		self:OpenLanguages( Languages )
	end
	function Languages:PerformLayout()
		if ( IsValid( self.m_Image ) ) then
			self.m_Image:SetSize( 16, 11 )
			self.m_Image:SetPos( ( self:GetWide() - self.m_Image:GetWide() ) * 0.5, ( self:GetTall() - self.m_Image:GetTall() ) * 0.5 )
		end
		DLabel.PerformLayout( self )
	end
	self.Languages = Languages

	self:MakePopup()
	self:SetPopupStayAtBack( true )

	self:OpenMainMenu()

end

function PANEL:Paint()

	if ( !IsValid( self.NewGameFrame ) && !IsValid( self.AddonsFrame )&& !IsValid( self.AchievementsFrame ) ) then
		self.BackButton:SetVisible( false )
	else
		self.BackButton:SetVisible( true )
	end

	if ( self.IsInGame != IsInGame() ) then

		self.IsInGame = IsInGame()

		self:OpenMainMenu() -- To update the buttons

	end

	DrawBackground()

end

function PANEL:ClosePopups( b )
	if ( IsValid( self.LanguageList ) ) then self.LanguageList:Remove() end
	if ( !b && IsValid( self.MountedGamesList ) ) then self.MountedGamesList:Remove() end // The ugly 'b' hack
	if ( IsValid( self.GamemodesList ) ) then self.GamemodesList:Remove() end
end

function PANEL:CloseAllMenus()
	if ( IsValid( self.MainMenuPanel ) ) then self.MainMenuPanel:Remove() end
	if ( IsValid( self.NewGameFrame ) ) then self.NewGameFrame:Remove() end
	if ( IsValid( self.AddonsFrame ) ) then self.AddonsFrame:Remove() end
	if ( IsValid( self.AchievementsFrame ) ) then self.AchievementsFrame:Remove() end
end

function PANEL:Back()
	self:CloseAllMenus()
	self:OpenMainMenu()
end

function PANEL:OpenMainMenu( b )
	self:CloseAllMenus()
	self:ClosePopups( b )

	local frame = vgui.Create( "MainMenuScreenPanel", self )
	self.MainMenuPanel = frame
end

function PANEL:OpenAddonsMenu( b )
	self:CloseAllMenus()
	self:ClosePopups( b )

	local frame = vgui.Create( "AddonsPanel", self )
	self.AddonsFrame = frame
end

function PANEL:OpenAchievementsMenu( b )
	self:CloseAllMenus()
	self:ClosePopups( b )

	local frame = vgui.Create( "AchievementsPanel", self )
	self.AchievementsFrame = frame
end

function PANEL:OpenNewGameMenu( b )
	self:CloseAllMenus()
	self:ClosePopups( b )

	local frame = vgui.Create( "NewGamePanel", self )
	self.NewGameFrame = frame

	hook.Run( "MenuStart" )
end

function PANEL:OpenLanguages( pnl )
	if ( IsValid( self.LanguageList ) ) then self.LanguageList:Remove() return end
	self:ClosePopups()

	local panel = vgui.Create( "DScrollPanel", self )
	panel:SetSize( 157, 90 )
	panel:SetPos( pnl:GetPos() - panel:GetWide() / 2 + pnl:GetWide() / 2, ScrH() - 55 - panel:GetTall() )
	self.LanguageList = panel

	function panel:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w - 5, h, Color( 0, 0, 0, 220 ) )
	end

	local p = vgui.Create( "DIconLayout", panel )
	p:Dock( FILL )
	p:SetBorder( 5 )
	p:SetSpaceY( 5 )
	p:SetSpaceX( 5 )

	for id, flag in pairs( file.Find( "resource/localization/*.png", "GAME" ) ) do
		local f = p:Add( "DImageButton" )
		f:SetImage( "../resource/localization/" .. flag )
		f:SetSize( 16, 12 )
		f.DoClick = function() RunConsoleCommand( "gmod_language", string.StripExtension( flag ) ) /*LanguageChanged( string.StripExtension( flag ) )*/ end
	end

end


function PANEL:OpenMountedGamesList( pnl )
	if ( IsValid( self.MountedGamesList ) ) then self.MountedGamesList:Remove() return end
	self:ClosePopups()

	local p = vgui.Create( "DPanelList", self )
	p:EnableVerticalScrollbar( true )
	p:SetSize( 276, 256 )
	p:SetPos( math.min( pnl:GetPos() - p:GetWide() / 2 + pnl:GetWide() / 2, ScrW() - p:GetWide() - 5 ), ScrH() - 55 - p:GetTall() )
	p:SetSpacing( 5 )
	p:SetPadding( 5 )
	self.MountedGamesList = p

	function p:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 220 ) )
	end
	
	local function add( t )
		local a = p:Add( "DCheckBoxLabel" )
		a:SetText( t.title )
		if ( !t.installed ) then a:SetText( t.title .. " ( not installed )" ) end
		if ( !t.owned ) then a:SetText( t.title .. " ( not owned )" ) end

		p:AddItem( a )
		a:SetChecked( t.mounted )
		a.OnChange = function( panel ) engine.SetMounted( t.depot, a:GetChecked() ) end
		if ( !t.owned || !t.installed ) then
			a:SetDisabled( true )
		end
	end

	for id, t in SortedPairsByMemberValue( engine.GetGames(), "title" ) do
		add( t )
	end
	/*for id, t in SortedPairsByMemberValue( engine.GetGames(), "title" ) do
		if ( t.installed && t.owned ) then add( t ) end
	end

	for id, t in SortedPairsByMemberValue( engine.GetGames(), "title" ) do
		if ( !t.installed && t.owned ) then add( t ) end
	end

	for id, t in SortedPairsByMemberValue( engine.GetGames(), "title" ) do
		if ( !t.installed && !t.owned ) then add( t ) end
	end*/

end

function PANEL:OpenGamemodesList( pnl )
	if ( IsValid( self.GamemodesList ) ) then self.GamemodesList:Remove() return end
	self:ClosePopups()

	local p = vgui.Create( "DPanelList", self )
	p:EnableVerticalScrollbar( true )
	p:SetSpacing( 5 )
	p:SetPadding( 5 )
	self.GamemodesList = p

	function p:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 220 ) )
	end

	local w = 100
	local h = 5

	for id, t in SortedPairsByMemberValue( engine.GetGamemodes(), "title" ) do
		if ( !t.menusystem ) then continue end
		local Gamemode = p:Add( "DMenuButton" )
		Gamemode:SetContentAlignment( 6 )
		Gamemode:SetText( t.title )
		if ( Material( "../gamemodes/" .. t.name .. "/icon24.png" ):IsError() ) then
			Gamemode:SetIcon( "../gamemodes/base/icon24.png" )
		else
			Gamemode:SetIcon( "../gamemodes/" .. t.name .. "/icon24.png" )
		end
		Gamemode:SetTextInset( Gamemode.m_Image:GetWide() + 25, 0 )
		Gamemode:SizeToContents()
		Gamemode:SetTall( 40 )
		Gamemode.DoClick = function()
			RunConsoleCommand( "gamemode", t.name )
			self:ClosePopups()
		end
		function Gamemode:PerformLayout()
			if ( IsValid( self.m_Image ) ) then
				self.m_Image:SetPos( 5, ( self:GetTall() - self.m_Image:GetTall() ) * 0.5 )
				self:SetTextInset( 10, 0 )
			end
			DLabel.PerformLayout( self )
		end

		p:AddItem( Gamemode )

		w = math.max( w, Gamemode:GetWide() + 20 )
		h = h + 45
	end

	//p:SetWide( w, h )

	p:SetSize( w, math.min( h, ScrH() / 1.5 ) )
	p:SetPos( math.min( pnl:GetPos() - p:GetWide() / 2 + pnl:GetWide() / 2, ScrW() - p:GetWide() - 5 ), ScrH() - 55 - p:GetTall() )
end

function PANEL:RefreshGamemodes( b )

	for id, gm in pairs( engine.GetGamemodes() ) do
		if ( gm.name == engine.ActiveGamemode() ) then self.GamemodeList:SetText( gm.title ) end
	end

	if ( Material( "../gamemodes/"..engine.ActiveGamemode().."/icon24.png" ):IsError() ) then
		self.GamemodeList:SetIcon( "../gamemodes/base/icon24.png" )
	else
		self.GamemodeList:SetIcon( "../gamemodes/" .. engine.ActiveGamemode() .. "/icon24.png" )
	end

	self.GamemodeList:SetTextInset( self.GamemodeList.m_Image:GetWide() + 25, 0 )
	self.GamemodeList:SizeToContents()

	self:UpdateBackgroundImages()

	if ( IsValid( self.NewGameFrame ) ) then self.NewGameFrame:Update() end
	if ( IsValid( self.AddonsFrame ) ) then self.AddonsFrame:Update() end
	//if ( IsValid( self.NewGameFrame ) ) then self:OpenNewGameMenu( b ) end
	//if ( IsValid( self.AddonsFrame ) ) then self:OpenAddonsMenu( b ) end
	//if ( IsValid( self.MainMenuPanel ) ) then self:OpenMainMenu( b ) end
	//if ( IsValid( self.AchievementsFrame ) ) then self:OpenAchievementsMenu( b ) end

	if ( IsValid( self.MountedGamesList ) ) then self.MountedGamesList:MoveToFront() end

end

function PANEL:RefreshAddons()
	if ( !IsValid( self.AddonsFrame ) ) then return end

	self.AddonsFrame:RefreshAddons()

end

function PANEL:RefreshContent()

	self:RefreshGamemodes( true )
	self:RefreshAddons()

end

function PANEL:ScreenshotScan( folder )

	local bReturn = false

	local Screenshots = file.Find( folder .. "*.jpg", "GAME" )
	for k, v in RandomPairs( Screenshots ) do

		AddBackgroundImage( folder .. v )
		bReturn = true

	end

	return bReturn

end


function PANEL:UpdateBackgroundImages()

	ClearBackgroundImages()

	--
	-- If there's screenshots in gamemodes/<gamemode>/backgrounds/*.jpg use them
	--
	if ( !self:ScreenshotScan( "gamemodes/" .. engine.ActiveGamemode() .. "/backgrounds/" ) ) then

		--
		-- If there's no gamemode specific here we'll use the default backgrounds
		--
		self:ScreenshotScan( "backgrounds/" )

	end

	ChangeBackground( engine.ActiveGamemode() )

end

vgui.Register( "MainMenuPanel", PANEL, "EditablePanel" )

--
-- Called from the engine any time the language changes
--
function LanguageChanged( lang )
	if ( !IsValid( pnlMainMenu ) ) then return end

	local self = pnlMainMenu
	if ( IsValid( self.NewGameFrame ) ) then self.NewGameFrame:UpdateLanguage() end
	if ( IsValid( self.AddonsFrame ) ) then self:OpenAddonsMenu() end
	if ( IsValid( self.MainMenuPanel ) ) then self:OpenMainMenu() end
	if ( IsValid( self.AchievementsFrame ) ) then self:OpenAchievementsMenu() end

	self.Languages:SetIcon( "../resource/localization/" .. lang .. ".png" )
end

function UpdateMapList()
	if ( !IsValid( pnlMainMenu ) ) then return end

	local self = pnlMainMenu

	if ( IsValid( self.NewGameFrame ) ) then self.NewGameFrame:Update() end
	/*if ( IsValid( self.NewGameFrame ) ) then self:OpenNewGameMenu() end
	if ( IsValid( self.AddonsFrame ) ) then self:OpenAddonsMenu() end
	if ( IsValid( self.MainMenuPanel ) ) then self:OpenMainMenu() end
	if ( IsValid( self.AchievementsFrame ) ) then self:OpenAchievementsMenu() end*/
end

hook.Add( "GameContentChanged", "RefreshMainMenu", function()
	if ( !IsValid( pnlMainMenu ) ) then return end

	pnlMainMenu:RefreshContent()
end )

timer.Simple( 0, function()
	if ( IsValid( pnlMainMenu ) ) then pnlMainMenu:Remove() end

	pnlMainMenu = vgui.Create( "MainMenuPanel" )

	hook.Run( "GameContentChanged" )
end )

// A hack to bring the console to front when menu_reload is ran
timer.Simple( 1, function()
	if ( gui.IsConsoleVisible() ) then gui.ShowConsole() end
end )

/*

--
-- Get the player list for this server
--
function GetPlayerList( serverip )

	serverlist.PlayerList( serverip, function( tbl )

		local json = util.TableToJSON( tbl )
		pnlMainMenu:Call( "SetPlayerList( '"..serverip.."', "..json..")" )

	end )

end

local Servers = {}

function GetServers( type, id )


	local data =
	{
		Finished = function()

		end,

		Callback = function( ping , name, desc, map, players, maxplayers, botplayers, pass, lastplayed, address, gamemode, workshopid )

			name	= string.JavascriptSafe( name )
			desc	= string.JavascriptSafe( desc )
			map		= string.JavascriptSafe( map )
			address = string.JavascriptSafe( address )
			gamemode = string.JavascriptSafe( gamemode )
			workshopid = string.JavascriptSafe( workshopid )

			if ( pass ) then pass = "true" else pass = "false" end

			pnlMainMenu:Call( "AddServer( '"..type.."', '"..id.."', "..ping..", \""..name.."\", \""..desc.."\", \""..map.."\", "..players..", "..maxplayers..", "..botplayers..", "..pass..", "..lastplayed..", \""..address.."\", \""..gamemode.."\", \""..workshopid.."\" )" )

		end,

		Type = type,
		GameDir = 'garrysmod',
		AppID = 4000,
	}

	serverlist.Query( data )

end
*/
