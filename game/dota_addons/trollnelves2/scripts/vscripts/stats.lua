Stats = Stats or {}

Stats.server = "http://tnelves2.com/backend/"

function Stats.SubmitMatchData(winner,callback)
	local data = {}
	data.players = {}
	data.matchID = tostring(GameRules:GetMatchID())
	data.winner = winner
	data.duration = GameRules:GetGameTime() - GameRules.startTime
	data.map = GetMapName()
	for pID=1,24 do
		if PlayerResource:IsValidPlayer(pID) then
			local playerData = {}
			playerData.steamID = tostring(PlayerResource:GetSteamID(pID) or 0)
			playerData.name = PlayerResource:GetPlayerName(pID) or "defaultName"
			playerData.team = PlayerResource:GetTeam(pID) or 0
			playerData.team = playerData.team == DOTA_TEAM_GOODGUYS and 2 or playerData.team == DOTA_TEAM_BADGUYS and 3 or 0
			playerData.type = PlayerResource:GetType(pID)
			playerData.goldGained = PlayerResource:GetGoldGained(pID) or 0
			playerData.goldGiven = PlayerResource:GetGoldGiven(pID) or 0
			playerData.lumberGained = PlayerResource:GetLumberGained(pID) or 0
			playerData.lumberGiven = PlayerResource:GetLumberGiven(pID) or 0
			playerData.kills = PlayerResource:GetKills(pID)
			playerData.deaths = PlayerResource:GetDeaths(pID)
			playerData.score = PlayerResource:GetTeam(pID) == winner and (100 + PlayerResource:GetScoreBonus(pID)) or (-100 + PlayerResource:GetScoreBonus(pID))
			table.insert(data.players,playerData)
		end
	end
	Stats.SendData("saveData.php",data,callback)
end

function Stats.SendData(url,data,callback)
	local req = CreateHTTPRequest("POST",Stats.server .. url)
	local encData = json.encode(data)
	DebugPrint("***********************************************")
	DebugPrint(Stats.server .. url)
	DebugPrint(encData)
	DebugPrint("***********************************************")
	req:SetHTTPRequestGetOrPostParameter('data',encData)

	req:Send(function(res)
		DebugPrint("***********************************************")
		DebugPrint(res.Body)
		DebugPrint("Response code: " .. res.StatusCode)
		DebugPrint("***********************************************")
		if res.StatusCode ~= 200 then
			DebugPrint("Error connecting")
			return
		end

		if callback then
			local obj,pos,err = json.decode(res.Body)
			callback(obj)
		end

	end)
end

function Stats.RequestData(url,callback)
	local req = CreateHTTPRequest("GET",Stats.server .. url)
	req:Send(function(res)
		if res.StatusCode ~= 200 then
			DebugPrint("Connection failed!")
			return -1
		end

		local obj,pos,err = json.decode(res.Body)
		return obj

	end)
end