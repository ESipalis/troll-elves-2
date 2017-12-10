function SetName(args){
	name = args.name;
}

function SetHours(args){
	hours = args.hours;
}

function SetMinutes(args){
	minutes = args.minutes;	
}

function SetSeconds(args){
	seconds = args.seconds;	
}

function UpdateTimer(){
	$.Schedule(1.0,UpdateTimer);
	$("#TimerText").text = name + ":" + hours + ":" + minutes + ":" + seconds;
}

function UpdateTimer2(args){
	$("#Timer").style.opacity = "1";
	var name = args.name || "Timer:"
	var hours = args.hours || 0
	var minutes = args.minutes || 0
	var seconds = args.seconds || 0
	$("#TimerText").text = name + ":" + hours + ":" + minutes + ":" + seconds;
	var overallSeconds = hours + minutes + seconds;
	if(overallSeconds == 0){
		$("#Timer").style.opacity = "0";
	}else{
		var args2 = {
		name : name,
		hours : Math.floor(overallSeconds/3600),
		minutes : Math.floor(overallSeconds/60),
		seconds : seconds - 1
		};
		$.Schedule(1.0,function(){
			UpdateTimer2(args2);
		});
	}
	
}

(function () {
	GameEvents.Subscribe("update_timer",UpdateTimer2);
})();