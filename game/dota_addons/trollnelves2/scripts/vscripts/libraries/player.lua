Player = Player or {}

require('libraries/team')

local goldGainedImportance = 12
local goldGivenImportance = 12
local lumberGainedImportance = 12
local lumberGivenImportance = 12
local rankImportance = 25

function CDOTA_PlayerResource:setGold(hero,gold)
    local pID = hero:GetPlayerOwnerID()
    gold = math.floor(string.match(gold,"[-]?%d+")) or 0
    gold = gold <= 1000000 and gold or 1000000
    GameRules.gold[pID] = gold
    CustomNetTables:SetTableValue("resources", tostring(pID), { gold = PlayerResource:getGold(pID),lumber = PlayerResource:getLumber(pID) })
end

function CDOTA_PlayerResource:modifyGold(hero,gold,noGain)
    noGain = noGain or false
    local pID = hero:GetPlayerOwnerID()
    gold = math.floor(string.match(gold,"[-]?%d+")) or 0
    PlayerResource:setGold(hero,math.floor(PlayerResource:getGold(pID) + gold))
    if gold > 0 and not noGain then
      PlayerResource:modifyGoldGained(pID,gold)
    end
    if GameRules.test then
      PlayerResource:setGold(hero,1000000)
    end
end

function CDOTA_PlayerResource:getGold(pID)
  return math.floor(GameRules.gold[pID] or 0)
end





function CDOTA_PlayerResource:setLumber(hero,lumber)
    local pID = hero:GetPlayerOwnerID()
    lumber = math.floor(string.match(lumber,"[-]?%d+")) or 0
    lumber = lumber <= 1000000 and lumber or 1000000
    GameRules.lumber[pID] = lumber
    CustomNetTables:SetTableValue("resources", tostring(pID), { gold = PlayerResource:getGold(pID),lumber = PlayerResource:getLumber(pID) })
end

function CDOTA_PlayerResource:modifyLumber(hero,lumber,noGain)
    noGain = noGain or false
    local pID = hero:GetPlayerOwnerID()
    lumber = math.floor(string.match(lumber,"[-]?%d+")) or 0
    PlayerResource:setLumber(hero,PlayerResource:getLumber(pID) + lumber)
    if lumber > 0 and not noGain then
      PlayerResource:modifyLumberGained(pID,lumber)
    end
    if GameRules.test then
      PlayerResource:setLumber(hero,1000000)
    end
end

function CDOTA_PlayerResource:getLumber(pID)
  return math.floor(GameRules.lumber[pID] or 0)
end

function CDOTA_PlayerResource:modifyGoldGained(pID,amount)
  GameRules.goldGained[pID] = PlayerResource:getGoldGained(pID) + amount
end

function CDOTA_PlayerResource:getGoldGained(pID)
  return GameRules.goldGained[pID] or 0
end

function CDOTA_PlayerResource:modifyGoldGiven(pID,amount)
  GameRules.goldGiven[pID] = PlayerResource:getGoldGiven(pID) + amount
end

function CDOTA_PlayerResource:getGoldGiven(pID)
  return GameRules.goldGiven[pID] or 0
end



function CDOTA_PlayerResource:modifyLumberGained(pID,amount)
  GameRules.lumberGained[pID] =PlayerResource:getLumberGained(pID) + amount
end

function CDOTA_PlayerResource:getLumberGained(pID)
  return GameRules.lumberGained[pID] or 0
end

function CDOTA_PlayerResource:modifyLumberGiven(pID,amount)
  GameRules.lumberGiven[pID] = PlayerResource:getLumberGiven(pID) + amount
end

function CDOTA_PlayerResource:getLumberGiven(pID)
  return GameRules.lumberGiven[pID] or 0
end

function CDOTA_PlayerResource:GetAllStats(pID)
	local sum = 0
	sum = sum + PlayerResource:getGoldGained(pID) + PlayerResource:getGoldGiven(pID) + PlayerResource:getLumberGiven(pID) + PlayerResource:getLumberGained(pID)
	return sum
end	

function CDOTA_PlayerResource:modifyFood(hero,food)
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
	local playerSum = PlayerResource:getGoldGained(pID)
	local teamAvg = PlayerResource:GetPlayerCountForTeam(team) > 1 and (Team.getGoldGained(team) - playerSum)/(PlayerResource:GetPlayerCountForTeam(team)-1) or playerSum
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
	local playerSum = PlayerResource:getGoldGiven(pID)
	local teamAvg = PlayerResource:GetPlayerCountForTeam(team) > 1 and (Team.getGoldGiven(team) - playerSum)/(PlayerResource:GetPlayerCountForTeam(team)-1) or playerSum
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
	local playerSum = PlayerResource:getLumberGained(pID)
	local teamAvg = PlayerResource:GetPlayerCountForTeam(team) > 1 and (Team.getLumberGained(team) - playerSum)/(PlayerResource:GetPlayerCountForTeam(team)-1) or playerSum
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
	local playerSum = PlayerResource:getLumberGiven(pID)
	local teamAvg = PlayerResource:GetPlayerCountForTeam(team) > 1 and (Team.getLumberGiven(team) - playerSum)/(PlayerResource:GetPlayerCountForTeam(team)-1) or playerSum
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

function CDOTA_PlayerResource:CheckTrollVictory()
    for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) do
        local playerID = PlayerResource:GetNthPlayerIDOnTeam(2, i)
        local hero = PlayerResource:GetSelectedHeroEntity(playerID) or false
        if hero and hero.alive then
            return false
        end
    end
    return true
end