function AddPlayer(args){
	var unit = args.unit;
	var name = Entities.GetUnitName(unit);
	var isAlive = Entities.IsAlive(unit);
	var image = $.CreatePanel("DOTAHeroImage", $.("#PlayerTable"), "");
	image.heroname = name;
	image.heroimagestyle="portrait";
	image.SetHasClass("PlayerDead", !isAlive);
}

(function () {
	GameEvents.Subscribe("hero_spawned", AddPlayer);
})();