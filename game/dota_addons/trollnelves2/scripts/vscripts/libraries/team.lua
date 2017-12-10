Team = Team or {}


function Team.getGoldGained(team)
	local sum = 0
	for i=1,PlayerResource:GetPlayerCountForTeam(team) do
		local pID = PlayerResource:GetNthPlayerIDOnTeam(team,i)
		sum = sum + PlayerResource:getGoldGained(pID)
	end
	return sum
end

function Team.getGoldGiven(team)
	local sum = 0
	for i=1,PlayerResource:GetPlayerCountForTeam(team) do
		local pID = PlayerResource:GetNthPlayerIDOnTeam(team,i)
		sum = sum + PlayerResource:getGoldGiven(pID)
	end
	return sum
end

function Team.GetAverageGoldGained(team)
	return Team.getGoldGained(team)/PlayerResource:GetPlayerCountForTeam(team)
end

function Team.GetAverageGoldGiven(team)
	return Team.getGoldGiven(team)/PlayerResource:GetPlayerCountForTeam(team)
end



function Team.getLumberGained(team)
	local sum = 0
	for i=1,PlayerResource:GetPlayerCountForTeam(team) do
		local pID = PlayerResource:GetNthPlayerIDOnTeam(team,i)
		sum = sum + PlayerResource:getLumberGained(pID)
	end
	return sum
end

function Team.getLumberGiven(team)
	local sum = 0
	for i=1,PlayerResource:GetPlayerCountForTeam(team) do
		local pID = PlayerResource:GetNthPlayerIDOnTeam(team,i)
		sum = sum + PlayerResource:getLumberGiven(pID)
	end
	return sum
end

function Team.GetAverageLumberGained(team)
	return Team.getLumberGained(team)/PlayerResource:GetPlayerCountForTeam(team)
end

function Team.GetAverageLumberGiven(team)
	return Team.getLumberGiven(team)/PlayerResource:GetPlayerCountForTeam(team)
end

function Team.GetScore(team)
	local sum = 0
	for i=1,PlayerResource:GetPlayerCountForTeam(team) do
		local pID = PlayerResource:GetNthPlayerIDOnTeam(team,i)
		sum = sum + PlayerResource:GetScore(pID)
	end
	return sum
end

function Team.GetAverageScore(team)
	return Team.GetScore(team)/PlayerResource:GetPlayerCountForTeam(team)
end

function Team.GetAllAverages(team)
	local sum = 0
	sum = sum + Team.GetAverageGoldGained(team) + Team.GetAverageGoldGiven(team) + Team.GetAverageLumberGained(team) + Team.GetAverageLumberGiven(team)
	return sum
end

function Team.GetAllAveragesAverage(team)
	return Team.GetAllAverages/4
end	