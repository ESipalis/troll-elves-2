"use strict";

function ChooseTeam(args) {
	var PlayerID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("player_team_choose", { "playerID": PlayerID, "team": args });
}

//--------------------------------------------------------------------------------------------------
// Update the state for the transition timer periodically
//--------------------------------------------------------------------------------------------------
var timer = 10;
function UpdateTimer() {
	$("#TeamChoiceWrapper").SetDialogVariableInt("countdown_timer_seconds", timer);
	if (timer-- > 0) {
		$.Schedule(1, UpdateTimer);
	}
}

//--------------------------------------------------------------------------------------------------
// Entry point called when the team select panel is created
//--------------------------------------------------------------------------------------------------
(function () {
	var mapInfo = Game.GetMapInfo();
	$("#MapInfo").SetDialogVariable("map_name", mapInfo.map_display_name);
	UpdateTimer();
	Game.AutoAssignPlayersToTeams();
})();
