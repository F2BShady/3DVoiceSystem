local g_screenX,g_screenY = guiGetScreenSize()
local BONE_ID = 8
local WORLD_OFFSET = 0.4
local ICON_PATH = "voice.png"
local ICON_WIDTH = 0.35*g_screenX
local iconHalfWidth = ICON_WIDTH/2
local ICON_DIMENSIONS = 16
local ICON_LINE = 20
local ICON_TEXT_SHADOW = tocolor(0,0,0,255)
local color = tocolor(getPlayerNametagColor(localPlayer))
mutedPlayersAccName = {}

function createIconsForPlayers()
	voiceCols = getElementData(resourceRoot,"voiceCols")
	if voiceCols then
		local keycount = 0
		for key,innertable in pairs(voiceCols) do
			if innertable[1] then
				keycount = keycount + 1
				local voicecol = innertable[1][1]
				local player = innertable[1][2]
				themutedplayer = false
				if isElement(voicecol) and isElement(player) then
					if mutedPlayersAccName then
						for key2,mutedplayer in pairs(mutedPlayersAccName) do
							if getElementData(player,"accountname") == mutedplayer then
								themutedplayer = player
							end
						end
					end
					if isElementWithinColShape(localPlayer,voicecol) and player ~= themutedplayer then
						if isElementOnScreen(player) then 
							local headX,headY,headZ = getPedBonePosition(player,BONE_ID)
							headZ = headZ + WORLD_OFFSET
							local absX,absY = getScreenFromWorldPosition(headX,headY,headZ)
							if absX and absY then
								local camX,camY,camZ = getCameraMatrix()
								dxDrawVoice(player,(keycount-1),absX,absY,getDistanceBetweenPoints3D(camX,camY,camZ,headX,headY,headZ))
							else
								dxDrawVoice(player,(keycount-1),false,false,false,true)
							end
						else
							dxDrawVoice(player,(keycount-1),false,false,false,true)
						end
					end
				end
			end
		end
	end
end
addEventHandler("onClientRender",root,createIconsForPlayers)

function dxDrawVoice ( player,index,posX, posY, distance, onlytext )
	local sx,sy = guiGetScreenSize()
	local scale = sy / 800
	local spacing = (ICON_LINE*scale)
	local px,py = sx-200,sy*0.7+spacing*index
	local icon = ICON_DIMENSIONS*scale
	local playername = getPlayerName(player)
	dxDrawImage(px,py,icon,icon,ICON_PATH,0,0,0,color,false)
	px = px+spacing
	dxDrawText(playername,px+1,py+1,px,py,ICON_TEXT_SHADOW,scale)
	dxDrawText(playername,px,py,px,py,color,scale)
	if not onlytext then
		distance = 1/distance
		dxDrawImage ( posX - iconHalfWidth*distance, posY - iconHalfWidth*distance, ICON_WIDTH*distance, ICON_WIDTH*distance, ICON_PATH, 0, 0, 0, color, false )
	end
end

function muteButtonClicked()
	if guiGridListGetSelectedItem(mutePlayersGridlist) then
		if xmlLoadFile("mutedplayers.xml") then
			RootNode = xmlLoadFile("mutedplayers.xml")
		end
		if RootNode then
			local accountkeys = xmlNodeGetChildren(RootNode)
			local accountname = guiGridListGetItemData(mutePlayersGridlist,guiGridListGetSelectedItem(mutePlayersGridlist),1)
			local accountnameexist = false
			if #accountkeys > 0 then
				for key,accountkey in pairs(accountkeys) do
					accountkeyname = teaDecode(xmlNodeGetAttribute(accountkey,"Key"),getElementData(resourceRoot,"accountnamekey"))
					if accountkeyname == accountname then
						accountnameexist = accountkey
						break
					end
				end
			end
			if guiGridListGetItemText(mutePlayersGridlist,guiGridListGetSelectedItem(mutePlayersGridlist),2) == "Unmuted" then
				guiGridListSetItemText(mutePlayersGridlist,guiGridListGetSelectedItem(mutePlayersGridlist),2,"Muted",false,false)
				guiGridListSetItemColor(mutePlayersGridlist,guiGridListGetSelectedItem(mutePlayersGridlist),2,255,0,0,255)
				if not accountnameexist then
					xmlNodeSetAttribute(xmlCreateChild(RootNode,"NameKey"),"Key",teaEncode(accountname,getElementData(resourceRoot,"accountnamekey")))
					mutedPlayersAccName[#mutedPlayersAccName + 1] = accountname
					triggerServerEvent("mutePlayersEvent",resourceRoot,mutedPlayersAccName)
				end
			elseif guiGridListGetItemText(mutePlayersGridlist,guiGridListGetSelectedItem(mutePlayersGridlist),2) == "Muted" then
				guiGridListSetItemText(mutePlayersGridlist,guiGridListGetSelectedItem(mutePlayersGridlist),2,"Unmuted",false,false)
				guiGridListSetItemColor(mutePlayersGridlist,guiGridListGetSelectedItem(mutePlayersGridlist),2,0,255,0,255)
				if accountnameexist then
					xmlDestroyNode(accountnameexist)
					for key,accname in pairs(mutedPlayersAccName) do
						if accname == accountname then
							mutedPlayersAccName[key] = nil
							break
						end
					end
					triggerServerEvent("mutePlayersEvent",resourceRoot,mutedPlayersAccName)
				end
			end
			xmlSaveFile(RootNode)
			xmlUnloadFile(RootNode)
			RootNode = nil
		end
	end
end

function toggleMuteGui()
	if guiGetVisible(muteWindow) then
		destroyElement(mutePlayersGridlist)
		guiSetVisible(muteWindow,false)
		guiSetVisible(muteButton,false)
		guiSetVisible(closeButton,false)
		showCursor(false,false)
		guiSetInputMode("allow_binds")
	else
		if xmlLoadFile("mutedplayers.xml") then
			RootNode = xmlLoadFile("mutedplayers.xml")
		end
		if RootNode then
			guiSetVisible(muteWindow,true)
			guiSetVisible(muteButton,true)
			guiSetVisible(closeButton,true)
			mutePlayersGridlist = guiCreateGridList(0,0.07,1,0.85,true,muteWindow)
			guiGridListSetSelectionMode(mutePlayersGridlist,0)
			guiGridListSetScrollBars(mutePlayersGridlist,false,true)
			guiGridListAddColumn(mutePlayersGridlist,"Playername",0.6)
			guiGridListAddColumn(mutePlayersGridlist,"Muted",0.3)
			guiSetProperty(mutePlayersGridlist,"ColumnsSizable","False")
			guiSetProperty(mutePlayersGridlist,"ColumnsMovable","False")
			local accountkeys = xmlNodeGetChildren(RootNode)
			for key,player in pairs(getElementsByType("player")) do
				if getElementData(player,"loggedin") and (player ~= localPlayer) then
					if getElementData(player,"accountname") then
						local row = guiGridListAddRow(mutePlayersGridlist)
						guiGridListSetItemText(mutePlayersGridlist,row,1,getPlayerName(player),false,false)
						guiGridListSetItemData(mutePlayersGridlist,row,1,getElementData(player,"accountname"))
						local mutedplayer = false
						for key2,accountkey in pairs(accountkeys) do
							local accountname = teaDecode(xmlNodeGetAttribute(accountkey,"Key"),getElementData(resourceRoot,"accountnamekey"))
							if getElementData(player,"accountname") == accountname then
								guiGridListSetItemText(mutePlayersGridlist,row,2,"Muted",false,false)
								guiGridListSetItemColor(mutePlayersGridlist,row,2,255,0,0,255)
								mutedplayer = true
								accountname = nil
								break
							end
						end
						if not mutedplayer then
							guiGridListSetItemText(mutePlayersGridlist,row,2,"Unmuted",false,false)
							guiGridListSetItemColor(mutePlayersGridlist,row,2,0,255,0,255)
						end
					end
				end
			end
			xmlUnloadFile(RootNode)
			RootNode = nil
			showCursor(true,true)
			guiSetInputMode("no_binds")
		end
	end
end
muteWindow = guiCreateWindow(0.3,0.2,0.3,0.5,"Voice Mute Menu",true)
muteButton = guiCreateButton(0.1,0.925,0.2,0.1,"Mute Player",true,muteWindow)
closeButton = guiCreateButton(0.5,0.925,0.2,0.1,"Close",true,muteWindow)
addEventHandler("onClientGUIClick",muteButton,muteButtonClicked)
addEventHandler("onClientGUIClick",closeButton,toggleMuteGui)
guiWindowSetSizable(muteWindow,false)
guiSetVisible(muteWindow,false)
guiSetVisible(muteButton,false)
guiSetVisible(closeButton,false)
if not xmlLoadFile("mutedplayers.xml") then
	RootNode = xmlCreateFile("mutedplayers.xml","MutedPlayers")
	xmlSaveFile(RootNode)
	xmlUnloadFile(RootNode)
	RootNode = nil
else
	if getElementData(localPlayer,"accountname") then
		mutedPlayers = {}
		mutedPlayers[getElementData(localPlayer,"accountname")] = {}
		mutedPlayersAccName = mutedPlayers[getElementData(localPlayer,"accountname")]
		RootNode = xmlLoadFile("mutedplayers.xml")
		local accountkeys = xmlNodeGetChildren(RootNode)
		if #accountkeys > 0 then
			for key,accountkey in pairs(accountkeys) do
				mutedPlayersAccName[#mutedPlayersAccName + 1] = teaDecode(xmlNodeGetAttribute(accountkey,"Key"),getElementData(resourceRoot,"accountnamekey"))
			end
			triggerServerEvent("mutePlayersEvent",resourceRoot,mutedPlayersAccName)
		end
		xmlUnloadFile(RootNode)
		RootNode = nil
	end
end
addCommandHandler("mute",toggleMuteGui)

fileDelete("3dvoicegui.lua")
