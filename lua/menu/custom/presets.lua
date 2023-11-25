local presetCache = {}

local function EnsurePresetsLoaded()
	if ( table.IsEmpty( presetCache ) ) then
		presetCache = util.JSONToTable( LoadAddonPresets() || "", true, true ) || {}
	end
end

function CreateNewAddonPreset( json )
	EnsurePresetsLoaded()

	local data = util.JSONToTable( json )
	presetCache[ data.name ] = data

	SaveAddonPresets( util.TableToJSON( presetCache ) )
end

function ImportAddonPreset( id, json )
	EnsurePresetsLoaded()

	steamworks.FileInfo( id, function( fileInfo )

		if ( !fileInfo.children || #fileInfo.children < 1 ) then
			OnImportPresetFailed()
			return
		end

		local data = util.JSONToTable( json )
		presetCache[ data.name ] = data
		presetCache[ data.name ].enabled = fileInfo.children

		SaveAddonPresets( util.TableToJSON( presetCache ) )
		ListAddonPresets()
	end )
end

function DeleteAddonPreset( name )
	EnsurePresetsLoaded()

	presetCache[ name ] = {}
	presetCache[ name ] = nil

	SaveAddonPresets( util.TableToJSON( presetCache ) )

	ListAddonPresets()
end

function ListAddonPresets()
	EnsurePresetsLoaded()

	return presetCache
end

function OnImportPresetFailed()
	Derma_Query( "#addons.import_preset_notcollection", "Warning", "OK", function() end )
end

-- Create Preset
local PANEL = {}

function PANEL:Init()
	self:SetWide( 320 )
	self:SetTall( 295 )

	local Cancel = vgui.Create( "DButton", self )
	Cancel:Dock( BOTTOM )
	Cancel:SetText( "Cancel" )
	Cancel:SetTall( 30 )
	Cancel:DockMargin( 5, 0, 5, 5 )
	Cancel.DoClick = function() self:Remove() end

	local frame = vgui.Create( "DPanel", self )
	frame:Dock( FILL )
	frame:DockMargin( 5, 5, 5, 5 )
	function frame:Paint( w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 225 ) )
	end

	local windowLabel = vgui.Create( "DLabel", frame )
	windowLabel:Dock( TOP )
	windowLabel:SetTall( 30 )
	windowLabel:DockMargin( 10, 5, 10, 0 )
	windowLabel:SetText( "Create Preset" )

	self.PresetName = vgui.Create( "DTextEntry", frame )
	self.PresetName:Dock( TOP )
	self.PresetName:SetTall( 30 )
	self.PresetName:DockMargin( 5, 5, 5, 0 )
	self.PresetName:SetPlaceholderText( "Preset name" )
	self.PresetName.OnChange = function() self:UpdateActionButton() end

	self.AddEnabled = vgui.Create( "DCheckBoxLabel", frame )
	self.AddEnabled:Dock( TOP )
	self.AddEnabled:SetTall( 16 )
	self.AddEnabled:DockMargin( 5, 5, 5, 0 )
	self.AddEnabled:SetText( "Save currently enabled addons" )
	self.AddEnabled:SetChecked( true )

	self.AddDisabled = vgui.Create( "DCheckBoxLabel", frame )
	self.AddDisabled:Dock( TOP )
	self.AddDisabled:SetTall( 16 )
	self.AddDisabled:DockMargin( 5, 5, 5, 0 )
	self.AddDisabled:SetText( "Save currently disabled addons" )
	self.AddDisabled:SetChecked( true )

	local actionLabel = vgui.Create( "DLabel", frame )
	actionLabel:Dock( TOP )
	actionLabel:SetTall( 30 )
	actionLabel:DockMargin( 10, 5, 10, 0 )
	actionLabel:SetText( "What to do with addons not in the preset?" )

	self.NotPresentAction = vgui.Create( "DComboBox", frame )
	self.NotPresentAction:Dock( TOP )
	self.NotPresentAction:SetTall( 30 )
	self.NotPresentAction:DockMargin( 5, 5, 5, 0 )

	self.NotPresentAction:AddChoice( "Do Nothing", "" )
	self.NotPresentAction:AddChoice( "Set Disabled", "disable", true )
	self.NotPresentAction:AddChoice( "Set Enabled", "enable" )

	self.CreatePreset = vgui.Create( "DButton", frame )
	self.CreatePreset:Dock( TOP )
	self.CreatePreset:SetText( "Create Preset" )
	self.CreatePreset:SetTall( 60 )
	self.CreatePreset:DockMargin( 5, 5, 5, 5 )
	self.CreatePreset:SetEnabled( false )
	self.CreatePreset.DoClick = function()
		local name = self.PresetName:GetValue()
		if ( name == "" ) then return end

		local preset = {
			enabled = {},
			disabled = {},
			name = name,
			newAction = self.NotPresentAction:GetOptionData( self.NotPresentAction:GetSelectedID() )
		}
	
		for _, addon in ipairs( engine.GetAddons() ) do
			table.insert( addon.mounted && preset.enabled || preset.disabled, addon.wsid )
		end
	
		CreateNewAddonPreset( util.TableToJSON( preset ) )
		
		self:Remove()
	end

	self:Center()
	self:MakePopup()
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 4, 0, 0, w, h, Color( 255, 255, 255, 255 ) )
end

function PANEL:UpdateActionButton()
	self.CreatePreset:SetEnabled( self.PresetName:GetValue() != "" )
end

vgui.Register( "CreatePresetPanel", PANEL, "EditablePanel" )

-- Load Preset
local PANEL = {}

function PANEL:Init()
	self:SetMultiSelect( false )
	self:SetSortable( false )

	self:AddColumn( "Preset Name" )

	self:RefreshPresetsList()
end

function PANEL:RefreshPresetsList()
	for i = 1, #self:GetLines() do
		self:RemoveLine( i )
	end

	for name, preset in pairs( ListAddonPresets() ) do
		self:AddLine( name ):SetSortValue( 1, preset )
	end

	self:ClearSelection()
end

function PANEL:OnRowSelected( rowIndex, row )
	if ( IsValid( self.MainPanel ) ) then
		self.MainPanel:SelectPreset( row:GetValue( 1 ), row:GetSortValue( 1 ) )
	end
end

vgui.Register( "PresetsListPanel", PANEL, "DListView" )

local PANEL = {}

function PANEL:Init()
	self:SetupPresetInfo()
end

function PANEL:SetupPresetInfo( preset )
	if ( IsValid( self.PresetName ) ) then self.PresetName:Remove() end
	if ( IsValid( self.CountEnabled ) ) then self.CountEnabled:Remove() end
	if ( IsValid( self.CountDisabled ) ) then self.CountDisabled:Remove() end
	if ( IsValid( self.InstallMissing ) ) then self.InstallMissing:Remove() end
	if ( IsValid( self.ActionLabel ) ) then self.ActionLabel:Remove() end
	if ( IsValid( self.NotPresentAction ) ) then self.NotPresentAction:Remove() end
	if ( IsValid( self.LoadPreset ) ) then self.LoadPreset:Remove() end
	if ( IsValid( self.CopyPreset ) ) then self.CopyPreset:Remove() end
	if ( IsValid( self.DeletePreset ) ) then self.DeletePreset:Remove() end

	if ( preset == nil ) then
		return
	end

	self.PresetName = vgui.Create( "DLabel", self )
	self.PresetName:Dock( TOP )
	self.PresetName:SetTall( 15 )
	self.PresetName:DockMargin( 10, 5, 10, 0 )
	self.PresetName:SetText( "Name: " .. preset.name )
	
	self.CountEnabled = vgui.Create( "DLabel", self )
	self.CountEnabled:Dock( TOP )
	self.CountEnabled:SetTall( 15 )
	self.CountEnabled:DockMargin( 10, 5, 10, 0 )
	self.CountEnabled:SetText( "Enabled: " .. #preset.enabled )
	
	self.CountDisabled = vgui.Create( "DLabel", self )
	self.CountDisabled:Dock( TOP )
	self.CountDisabled:SetTall( 15 )
	self.CountDisabled:DockMargin( 10, 5, 10, 0 )
	self.CountDisabled:SetText( "Disabled: " .. #preset.disabled )
	
	self.InstallMissing = vgui.Create( "DCheckBoxLabel", self )
	self.InstallMissing:Dock( TOP )
	self.InstallMissing:SetTall( 16 )
	self.InstallMissing:DockMargin( 5, 5, 5, 5 )
	self.InstallMissing:SetText( "Install addons that are no longer installed" )
	self.InstallMissing:SetChecked( false )

	self.ActionLabel = vgui.Create( "DLabel", self )
	self.ActionLabel:Dock( TOP )
	self.ActionLabel:SetTall( 15 )
	self.ActionLabel:DockMargin( 10, 5, 10, 5 )
	self.ActionLabel:SetText( "What to do with addons not in the preset?" )

	self.NotPresentAction = vgui.Create( "DComboBox", self )
	self.NotPresentAction:Dock( TOP )
	self.NotPresentAction:SetTall( 30 )
	self.NotPresentAction:DockMargin( 5, 5, 5, 0 )

	self.NotPresentAction:AddChoice( "Do Nothing", "" )
	self.NotPresentAction:AddChoice( "Set Disabled", "disable", true )
	self.NotPresentAction:AddChoice( "Set Enabled", "enable" )

	self.LoadPreset = vgui.Create( "DButton", self )
	self.LoadPreset:Dock( TOP )
	self.LoadPreset:SetText( "Load Preset" )
	self.LoadPreset:SetTall( 60 )
	self.LoadPreset:DockMargin( 5, 5, 5, 0 )
	self.LoadPreset.DoClick = function()
		local newAct = preset.newAction

		if ( self.InstallMissing:GetChecked() ) then
			for _, id in ipairs( preset.disabled ) do
				if ( !steamworks.IsSubscribed( id ) ) then
					steamworks.Subscribe( id )
				end
			end

			for _, id in ipairs( preset.enabled ) do
				if ( !steamworks.IsSubscribed( id ) ) then
					steamworks.Subscribe( id )
				end
			end

			steamworks.ApplyAddons()
		end

		local idsDone = {}
		for _, id in ipairs( preset.disabled ) do
			steamworks.SetShouldMountAddon( id, false )
			idsDone[ id ] = true
		end
		for _, id in ipairs( preset.enabled ) do
			steamworks.SetShouldMountAddon( id, true )
			idsDone[ id ] = true
		end

		if ( newAct != "" ) then
			for _, addon in ipairs( engine.GetAddons() ) do
				if ( !idsDone[ addon.wsid ] ) then
					steamworks.SetShouldMountAddon( addon.wsid, newAct == "enable" )
				end
			end
		end

		steamworks.ApplyAddons()

		if ( IsValid( self.MainPanel ) ) then
			self.MainPanel:Remove()
		end
	end
	
	self.CopyPreset = vgui.Create( "DButton", self )
	self.CopyPreset:Dock( TOP )
	self.CopyPreset:SetText( "Copy Preset To Clipboard" )
	self.CopyPreset:SetTall( 30 )
	self.CopyPreset:DockMargin( 5, 5, 5, 0 )
	self.CopyPreset.DoClick = function()
		SetClipboardText( util.TableToJSON( preset ) )
	end
	
	self.DeletePreset = vgui.Create( "DButton", self )
	self.DeletePreset:Dock( TOP )
	self.DeletePreset:SetText( "Delete Preset" )
	self.DeletePreset:SetTall( 30 )
	self.DeletePreset:DockMargin( 5, 35, 5, 0 )
	self.DeletePreset.DoClick = function()
		Derma_Query( "Are you sure you want to delete the preset?\n" .. preset.name, "Warning!", "Confirm", function()
			DeleteAddonPreset( preset.name )

			if ( IsValid( self.MainPanel ) ) then
				self.MainPanel:RefreshPresetsList()
			end

			self:SetupPresetInfo()
		end, "Cancel", function() end )
	end
end

vgui.Register( "PresetInfoPanel", PANEL, "EditablePanel" )

local PANEL = {}

function PANEL:Init()
	self:SetWide( 640 )
	self:SetTall( 395 )

	local Cancel = vgui.Create( "DButton", self )
	Cancel:Dock( BOTTOM )
	Cancel:SetText( "Cancel" )
	Cancel:SetTall( 30 )
	Cancel:DockMargin( 5, 0, 5, 5 )
	Cancel.DoClick = function() self:Remove() end

	local frame = vgui.Create( "DPanel", self )
	frame:Dock( FILL )
	frame:DockMargin( 5, 5, 5, 5 )
	function frame:Paint( w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 225 ) )
	end

	local windowLabel = vgui.Create( "DLabel", frame )
	windowLabel:Dock( TOP )
	windowLabel:SetTall( 30 )
	windowLabel:DockMargin( 10, 5, 10, 0 )
	windowLabel:SetText( "Load Preset" )

	self.PresetList = vgui.Create( "PresetsListPanel", frame )
	self.PresetList:Dock( LEFT )
	self.PresetList:SetWide( 300 )
	self.PresetList:DockMargin( 5, 5, 0, 5 )
	self.PresetList.MainPanel = self
	
	self.PresetInfo = vgui.Create( "PresetInfoPanel", frame )
	self.PresetInfo:Dock( FILL )
	self.PresetInfo.MainPanel = self

	self:Center()
	self:MakePopup()
end

function PANEL:SelectPreset( name, preset )
	self.PresetInfo:SetupPresetInfo( preset )
end

function PANEL:RefreshPresetsList()
	self.PresetList:RefreshPresetsList()
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 4, 0, 0, w, h, Color( 255, 255, 255, 255 ) )
end

vgui.Register( "LoadPresetPanel", PANEL, "EditablePanel" )

-- Import Preset
local PANEL = {}

function PANEL:Init()
	self:SetWide( 320 )
	self:SetTall( 310 )

	local Cancel = vgui.Create( "DButton", self )
	Cancel:Dock( BOTTOM )
	Cancel:SetText( "Cancel" )
	Cancel:SetTall( 30 )
	Cancel:DockMargin( 5, 0, 5, 5 )
	Cancel.DoClick = function() self:Remove() end

	local frame = vgui.Create( "DPanel", self )
	frame:Dock( FILL )
	frame:DockMargin( 5, 5, 5, 5 )
	function frame:Paint( w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 225 ) )
	end

	local windowLabel = vgui.Create( "DLabel", frame )
	windowLabel:Dock( TOP )
	windowLabel:SetTall( 30 )
	windowLabel:DockMargin( 10, 5, 10, 0 )
	windowLabel:SetText( "Import Preset" )

	self.PresetData = vgui.Create( "DTextEntry", frame )
	self.PresetData:Dock( TOP )
	self.PresetData:SetTall( 30 )
	self.PresetData:DockMargin( 5, 05, 5, 0 )
	self.PresetData:SetPlaceholderText( "URL to a workshop collection or copied preset" )
	self.PresetData.OnChange = function() self:UpdateActionButton() end

	self.PresetName = vgui.Create( "DTextEntry", frame )
	self.PresetName:Dock( TOP )
	self.PresetName:SetTall( 30 )
	self.PresetName:DockMargin( 5, 25, 5, 0 )
	self.PresetName:SetPlaceholderText( "Preset name" )
	self.PresetName.OnChange = function() self:UpdateActionButton() end

	local actionLabel = vgui.Create( "DLabel", frame )
	actionLabel:Dock( TOP )
	actionLabel:SetTall( 30 )
	actionLabel:DockMargin( 10, 5, 10, 0 )
	actionLabel:SetText( "What to do with addons not in the preset?" )

	self.NotPresentAction = vgui.Create( "DComboBox", frame )
	self.NotPresentAction:Dock( TOP )
	self.NotPresentAction:SetTall( 30 )
	self.NotPresentAction:DockMargin( 5, 5, 5, 0 )

	self.NotPresentAction:AddChoice( "Do Nothing", "" )
	self.NotPresentAction:AddChoice( "Set Disabled", "disable", true )
	self.NotPresentAction:AddChoice( "Set Enabled", "enable" )

	self.ImportPreset = vgui.Create( "DButton", frame )
	self.ImportPreset:Dock( TOP )
	self.ImportPreset:SetText( "Import Preset" )
	self.ImportPreset:SetTall( 60 )
	self.ImportPreset:DockMargin( 5, 5, 5, 5 )
	self.ImportPreset:SetEnabled( false )
	self.ImportPreset.DoClick = function()
		local name = self.PresetName:GetValue()
		if ( name == "" ) then return end

		local data = self.PresetData:GetValue()

		if ( data:StartsWith( "http" ) || data:find( "^(%d+)$" ) ) then
			local _, match = data:match( "https?://steamcommunity%.com/sharedfiles/filedetails/%?(.*)id=(%d+)(.*)" )

			if ( !match ) then
				match = data:match( "^(%d+)$" )
			end

			if ( !match ) then
				OnImportPresetFailed()
			else
				local preset = {
					enabled = {},
					disabled = {},
					name = name,
					newAction = self.NotPresentAction:GetOptionData( self.NotPresentAction:GetSelectedID() )
				}

				ImportAddonPreset( data, util.TableToJSON( preset ) )
		
				self:Remove()
			end
		else
			local importedPreset = util.JSONToTable( data )

			if ( !importedPreset ) then
				OnImportPresetFailed()
				return
			end

			local preset = {
				enabled = importedPreset.enabled || {},
				disabled = importedPreset.disabled || {},
				name = name,
				newAction = self.NotPresentAction:GetOptionData( self.NotPresentAction:GetSelectedID() )
			}
	
			CreateNewAddonPreset( util.TableToJSON( preset ) )
		
			self:Remove()
		end
	end

	self:Center()
	self:MakePopup()
end

function PANEL:UpdateActionButton()
	self.ImportPreset:SetEnabled( self.PresetData:GetValue() != "" && self.PresetName:GetValue() != "" )
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 4, 0, 0, w, h, Color( 255, 255, 255, 255 ) )
end

vgui.Register( "ImportPresetPanel", PANEL, "EditablePanel" )
