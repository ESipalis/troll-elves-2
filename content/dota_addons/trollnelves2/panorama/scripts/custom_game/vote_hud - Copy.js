

function ChooseTeam (args) {
	var PlayerID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer( "player_vote", { "pID":PlayerID,"team":args } );
}

function OnLockAndStartPressed()
{
	// Don't allow a forced start if there are unassigned players
	if ( Game.GetUnassignedPlayerIDs().length > 0  )
		return;

	// Lock the team selection so that no more team changes can be made
	Game.SetTeamSelectionLocked( true );
	
	// Disable the auto start count down
	Game.SetAutoLaunchEnabled( false );

	// Set the remaining time before the game starts
	Game.SetRemainingSetupTime( 3 ); 
}


//--------------------------------------------------------------------------------------------------
// Handler for when the Cancel and Unlock button is pressed
//--------------------------------------------------------------------------------------------------
function OnCancelAndUnlockPressed()
{
	// Unlock the team selection, allowing the players to change teams again
	Game.SetTeamSelectionLocked( false );

	// Stop the countdown timer
	Game.SetRemainingSetupTime( -1 ); 
}