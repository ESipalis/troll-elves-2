Player = Player or {}

require('libraries/team')

local goldGainedImportance = 12
local goldGivenImportance = 12
local lumberGainedImportance = 12
local lumberGivenImportance = 12
local rankImportance = 25

function CDOTA_PlayerResource:SetGold(hero,gold)
    local pID = hero:GetPlayerOwnerID()
    gold = math.floor(string.match(gold,"[-]?%d+")) or 0
    gold = gold <= 1000000 and gold or 1000000
    GameRules.gold[pID] = gold
    CustomNetTables:SetTableValue("resources", tostring(pID), { gold = PlayerResource:GetGold(pID),lumber = PlayerResource:GetLumber(pID) })
end

function CDOTA_PlayerResource:ModifyGold(hero,gold,noGain)
    noGain = noGain or false
    local pID = hero:GetPlayerOwnerID()
    gold = math.floor(string.match(gold,"[-]?%d+")) or 0
    PlayerResource:SetGold(hero,math.floor(PlayerResource:GetGold(pID) + gold))
    if gold > 0 and not noGain then
      PlayerResource:ModifyGoldGained(pID,gold)
    end
    if GameRules.test then
      PlayerResource:SetGold(hero,1000000)
    end
end

function CDOTA_PlayerResource:GetGold(pID)
  return math.floor(GameRules.gold[pID] or 0)
end





function CDOTA_PlayerResource:SetLumber(hero,lumber)
    local pID = hero:GetPlayerOwnerID()
		lumber = lumber or 0
    lumber = lumber <= 1000000 and lumber or 1000000
    GameRules.lumber[pID] = lumber
    CustomNetTables:SetTableValue("resources", tostring(pID), { gold = PlayerResource:GetGold(pID),lumber = PlayerResource:GetLumber(pID) })
end

function CDOTA_PlayerResource:ModifyLumber(hero,lumber,noGain)
    noGain = noGain or false
    local pID = hero:GetPlayerOwnerID()
    lumber = lumber or 0
    PlayerResource:SetLumber(hero,PlayerResource:GetLumber(pID) + lumber)
    if lumber > 0 and not noGain then
      PlayerResource:ModifyLumberGained(pID,lumber)
    end
    if GameRules.test then
      PlayerResource:SetLumber(hero,1000000)
    end
end

function CDOTA_PlayerResource:GetLumber(pID)
  return GameRules.lumber[pID] or 0
end

function CDOTA_PlayerResource:ModifyGoldGained(pID,amount)
  GameRules.goldGained[pID] = PlayerResource:GetGoldGained(pID) + amount
end

function CDOTA_PlayerResource:GetGoldGained(pID)
  return GameRules.goldGained[pID] or 0
end

function CDOTA_PlayerResource:ModifyGoldGiven(pID,amount)
  GameRules.goldGiven[pID] = PlayerResource:GetGoldGiven(pID) + amount
end

function CDOTA_PlayerResource:GetGoldGiven(pID)
  return GameRules.goldGiven[pID] or 0
end



function CDOTA_PlayerResource:ModifyLumberGained(pID,amount)
  GameRules.lumberGained[pID] =PlayerResource:GetLumberGained(pID) + amount
end

function CDOTA_PlayerResource:GetLumberGained(pID)
  return GameRules.lumberGained[pID] or 0
end

function CDOTA_PlayerResource:ModifyLumberGiven(pID,amount)
  GameRules.lumberGiven[pID] = PlayerResource:GetLumberGiven(pID) + amount
end

function CDOTA_PlayerResource:GetLumberGiven(pID)
  return GameRules.lumberGiven[pID] or 0
end

function CDOTA_PlayerResource:GetAllStats(pID)
	local sum = 0
	sum = sum + PlayerResource:GetGoldGained(pID) + PlayerResource:GetGoldGiven(pID) + PlayerResource:GetLumberGiven(pID) + PlayerResource:GetLumberGained(pID)
	return sum
end	

function CDOTA_PlayerResource:ModifyFood(hero,food)
    food = string.match(food,"[-]?%d+") or 0
    local playerID = hero:GetMainControllingPlayer()
    hero.food = hero.food + food
    local player = hero:GetPlayerOwner()
    if player then
      CustomGameEventManager:Send_ServerToPlayer(player, "player_food_changed", { food = math.floor(hero.food) , maxFood = GameRules.max_food })
    end
end


function CDOTA_PlayerResource:GetScore(pID)
	if not GameRules.scores[pID] then
		local steamID = PlayerResource:GetSteamID(pID)
		local data = Stats.RequestData("requestData.php?steamid="..tostring(steamID))
		GameRules.scores[pID] = {}
		GameRules.scores[pID].troll = data and data.troll or 1000
		GameRules.scores[pID].elf = data and data.elf or 1000
		GameRules.scores[pID].wolf = data and data.wolf or 1000
		GameRules.scores[pID].angel = data and data.angel or 1000
	end
	return GameRules.scores[pID][PlayerResource:GetType(pID)]
end

function CDOTA_PlayerResource:GetType(pID)
	local heroName = PlayerResource:GetSelectedHeroName(pID)
	return string.match(heroName,"troll") and "troll" or string.match(heroName,"crystal") and "angel" or string.match(heroName,"lycan") and "wolf" or "elf"
end

function CDOTA_PlayerResource:GetScoreBonus(pID)	
	local scoreBonus = PlayerResource:GetScoreBonusGoldGained(pID) + PlayerResource:GetScoreBonusGoldGiven(pID) + PlayerResource:GetScoreBonusLumberGained(pID) + PlayerResource:GetScoreBonusLumberGiven(pID) + PlayerResource:GetScoreBonusRank(pID)
	return math.floor(scoreBonus)
end

function CDOTA_PlayerResource:GetScoreBonusGoldGained(pID)
	local team = PlayerResource:GetTeam(pID)
	local playerSum = PlayerResource:GetGoldGained(pID)
	local teamAvg = PlayerResource:GetPlayerCountForTeam(team) > 1 and (Team.GetGoldGained(team) - playerSum)/(PlayerResource:GetPlayerCountForTeam(team)-1) or playerSum
	playerSum = playerSum == 0 and 1 or playerSum
	teamAvg = teamAvg == 0 and 1 or teamAvg
	if playerSum == teamAvg then
		return 0
	end
	local sign = playerSum > teamAvg and 1 or -1
	local add = playerSum/teamAvg > 0 and 0 or 1
	playerSum = math.abs(playerSum)
	teamAvg = math.abs(teamAvg)
	local value = math.floor((math.max(playerSum,teamAvg)/math.min(playerSum,teamAvg)*goldGainedImportance/10)+add)
	value = math.min(goldGainedImportance,value)
	return (value*sign)
	
end
function CDOTA_PlayerResource:GetScoreBonusGoldGiven(pID)
	local team = PlayerResource:GetTeam(pID)
	local playerSum = PlayerResource:GetGoldGiven(pID)
	local teamAvg = PlayerResource:GetPlayerCountForTeam(team) > 1 and (Team.GetGoldGiven(team) - playerSum)/(PlayerResource:GetPlayerCountForTeam(team)-1) or playerSum
	playerSum = playerSum == 0 and 1 or playerSum
	teamAvg = teamAvg == 0 and 1 or teamAvg
	if playerSum == teamAvg then
		return 0
	end
	local sign = playerSum > teamAvg and 1 or -1
	local add = playerSum/teamAvg > 0 and 0 or 1
	playerSum = math.abs(playerSum)
	teamAvg = math.abs(teamAvg)
	local value = math.floor((math.max(playerSum,teamAvg)/math.min(playerSum,teamAvg)*goldGivenImportance/10)+add)
	value = math.min(goldGivenImportance,value)
	return (value*sign)
end
function CDOTA_PlayerResource:GetScoreBonusLumberGained(pID)
	local team = PlayerResource:GetTeam(pID)
	local playerSum = PlayerResource:GetLumberGained(pID)
	local teamAvg = PlayerResource:GetPlayerCountForTeam(team) > 1 and (Team.GetLumberGained(team) - playerSum)/(PlayerResource:GetPlayerCountForTeam(team)-1) or playerSum
	playerSum = playerSum == 0 and 1 or playerSum
	teamAvg = teamAvg == 0 and 1 or teamAvg
	if playerSum == teamAvg then
		return 0
	end
	local sign = playerSum > teamAvg and 1 or -1
	local add = playerSum/teamAvg > 0 and 0 or 1
	playerSum = math.abs(playerSum)
	teamAvg = math.abs(teamAvg)
	local value = math.floor((math.max(playerSum,teamAvg)/math.min(playerSum,teamAvg)*lumberGainedImportance/10)+add)
	value = math.min(lumberGainedImportance,value)
	return (value*sign)
end
function CDOTA_PlayerResource:GetScoreBonusLumberGiven(pID)
	local team = PlayerResource:GetTeam(pID)
	local playerSum = PlayerResource:GetLumberGiven(pID)
	local teamAvg = PlayerResource:GetPlayerCountForTeam(team) > 1 and (Team.GetLumberGiven(team) - playerSum)/(PlayerResource:GetPlayerCountForTeam(team)-1) or playerSum
	playerSum = playerSum == 0 and 1 or playerSum
	teamAvg = teamAvg == 0 and 1 or teamAvg
	if playerSum == teamAvg then
		return 0
	end
	local sign = playerSum > teamAvg and 1 or -1
	local add = playerSum/teamAvg > 0 and 0 or 1
	playerSum = math.abs(playerSum)
	teamAvg = math.abs(teamAvg)
	local value = math.floor((math.max(playerSum,teamAvg)/math.min(playerSum,teamAvg)*lumberGivenImportance/10)+add)
	value = math.min(lumberGivenImportance,value)
	return (value*sign)
end

function CDOTA_PlayerResource:GetScoreBonusRank(pID)
	local allyTeam = PlayerResource:GetTeam(pID)
	local enemyTeam = allyTeam == DOTA_TEAM_GOODGUYS and DOTA_TEAM_BADGUYS or DOTA_TEAM_GOODGUYS
	local allyTeamScore = Team.GetScore(allyTeam)
	local enemyTeamScore = Team.GetScore(enemyTeam)
	local sign = allyTeamScore > enemyTeamScore and -1 or 1
	local value = math.floor((math.abs(enemyTeamScore - allyTeamScore))*rankImportance/500)
	value = math.min(rankImportance,value)
	return (value*sign)
end	



function CDOTA_PlayerResource:IsElf(hero)
    return string.match(hero:GetUnitName(),"wisp")
end
function CDOTA_PlayerResource:IsTroll(hero)
    return string.match(hero:GetUnitName(),"troll_warlord")
end
function CDOTA_PlayerResource:IsAngel(hero)
    return string.match(hero:GetUnitName(),"crystal_maiden")
end
function CDOTA_PlayerResource:IsWolf(hero)
    return string.match(hero:GetUnitName(),"lycan")
end
