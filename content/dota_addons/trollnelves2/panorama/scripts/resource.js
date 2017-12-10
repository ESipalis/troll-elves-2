"use strict";

function OnPlayerLumberChanged ( args ) {
	var iPlayerID = Players.GetLocalPlayer();
	var lumber = args.lumber;
	$('#LumberText').text = lumber;
}

function OnPlayerGoldChanged ( args ) {
	var iPlayerID = Players.GetLocalPlayer();
	var gold = args.gold;
	$('#GoldText').text = gold;
}

function OnPlayerFoodChanged ( args ) {
	var iPlayerID = Players.GetLocalPlayer();
	var food = args.food;
	var maxFood = args.maxFood;
	$('#CheeseText').text = food + "/" + maxFood;
}

function OnPlayerLumberPriceChanged ( args ){
	var lumberPrice = args.lumberPrice;
	$("#LumberPriceText").text = lumberPrice;
	
}

function HideCheesePanel(){
	$("#CheeseLumberPricePanel").style.opacity = "0";
}

function ChooseSide( teamNumber){
	var pID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer( "choose_help_side", { team:teamNumber,playerID:pID });
	$("#ChooseHelpContainer").style.visibility = "collapse";
}

function ShowHelperOptions(){
	$("#ChooseHelpContainer").style.visibility = "visible";
	$.Schedule(30,function(){
		$("#ChooseHelpContainer").style.visibility = "collapse";
	});
}

(function () {
	GameEvents.Subscribe("player_lumber_changed", OnPlayerLumberChanged);
	GameEvents.Subscribe("player_custom_gold_changed",OnPlayerGoldChanged);
	GameEvents.Subscribe("player_food_changed",OnPlayerFoodChanged);
	GameEvents.Subscribe("player_lumber_price_changed",OnPlayerLumberPriceChanged);
	GameEvents.Subscribe("show_helper_options",ShowHelperOptions);
	GameEvents.Subscribe("hide_cheese_panel",HideCheesePanel);
})();