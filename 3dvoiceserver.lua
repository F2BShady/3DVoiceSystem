setElementData(resourceRoot,"accountnamekey","1jhlkopiuejdk")
voiceColElements = {}
voiceCols = {}
function updateVoice(playerSource)
	if not isElement(playerSource) then return end
	if not getPlayerAccount(playerSource) then return end
	if isGuestAccount(getPlayerAccount(playerSource)) then return end
	if getElementData(playerSource,"voiceactivated") ~= true then return end
	local accountname = getAccountName(getPlayerAccount(playerSource))
	if not getAccountPlayer(getAccount(accountname)) == playerSource then return end
	if not voiceColElements[accountname] then
		voiceColElements[accountname] = {}
		voiceCols[accountname] = {}
	end
	if not isElement(voiceColElements[accountname][1]) then
		local x,y,z = getElementPosition(playerSource)
		voiceColElements[accountname][1] = createColCircle(x,y,20)
		attachElements(voiceColElements[accountname][1],playerSource)
		voiceCols[accountname][1] = {voiceColElements[accountname][1],playerSource}
		setElementData(resourceRoot,"voiceCols",voiceCols)
	end
	setPlayerVoiceBroadcastTo(playerSource,getElementsWithinColShape(voiceColElements[accountname][1],"player"))
	setTimer(updateVoice,100,1,playerSource)
end

function mutePlayers(mutedPlayersAccName)
	local mutedPlayersTable = {}
	if mutedPlayersAccName then
		for key2,mutedplayer in pairs(mutedPlayersAccName) do
			if getAccountPlayer(getAccount(mutedplayer)) then
				mutedPlayersTable[#mutedPlayersTable + 1] = getAccountPlayer(getAccount(mutedplayer))
			end
		end
	end
	setPlayerVoiceIgnoreFrom(client,mutedPlayersTable)
end
addEvent("mutePlayersEvent",true)
addEventHandler("mutePlayersEvent",resourceRoot,mutePlayers)

function voiceBind(playerSource,keybind,keystate)
	setPlayerVoiceBroadcastTo(playerSource,{})
	if not getPlayerAccount(playerSource) then return end
	if isGuestAccount(getPlayerAccount(playerSource)) then return end
	if keystate == "down" then
		if getElementData(playerSource,"voiceactivated") ~= true then
			setElementData(playerSource,"voiceactivated",true)
			updateVoice(playerSource)
		end
	elseif keystate == "up" then
		if getElementData(playerSource,"voiceactivated") then
			local accountname = getAccountName(getPlayerAccount(playerSource))
			if not getAccountPlayer(getAccount(accountname)) == playerSource then return end
			if not voiceColElements[accountname] then return end
			if isElement(voiceColElements[accountname][1]) then
				destroyElement(voiceColElements[accountname][1])
				voiceColElements[accountname] = {}
				voiceCols[accountname] = {}
				setElementData(resourceRoot,"voiceCols",voiceCols)
			end
			removeElementData(playerSource,"voiceactivated")
		end
	end
end

for key,player in pairs(getElementsByType("player")) do
	bindKey(player,"z","both",voiceBind)
	setPlayerVoiceBroadcastTo(player,{})
end

function bindLogin()
	bindKey(source,"z","both",voiceBind)
	setPlayerVoiceBroadcastTo(source,{})
end
addEventHandler("onPlayerJoin",root,bindLogin)
addEventHandler("onPlayerLogin",root,bindLogin)
