-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

require('internal/util')
require('trollnelves2')
require("libraries/buildinghelper")

function Precache( context )
--[[
  This function is used to precache resources/units/items/abilities that will be needed
  for sure in your game and that will not be precached by hero selection.  When a hero
  is selected from the hero selection screen, the game will precache that hero's assets,
  any equipped cosmetics, and perform the data-driven precaching defined in that hero's
  precache{} block, as well as the precache{} block for any equipped abilities.

  See trollnelves2:PostLoadPrecache() in trollnelves2.lua for more information
  ]]

  DebugPrint("[TROLLNELVES2] Performing pre-load precache")

  -- Particles can be precached individually or by folder
  -- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
  -- Models can also be precached by folder or individually
  -- PrecacheModel should generally used over PrecacheResource for individual models
  -- Sounds can precached here like anything else

  -- Entire items can be precached by name
  -- Abilities can also be precached in this way despite the name
  PrecacheItemByNameSync("item_root_ability", context)
  PrecacheItemByNameSync("item_silence_ability", context)
  PrecacheItemByNameSync("item_glyph_ability", context)

  -- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
  -- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
  PrecacheUnitByNameSync("npc_dota_hero_wisp", context)
  PrecacheUnitByNameSync("npc_dota_hero_troll_warlord", context)
  PrecacheUnitByNameSync("npc_dota_hero_lycan", context)
  PrecacheUnitByNameSync("npc_dota_hero_crystal_maiden", context)
  PrecacheUnitByNameSync("tent", context)
  PrecacheUnitByNameSync("tent_2", context)
  PrecacheUnitByNameSync("tent_3", context)
  PrecacheUnitByNameSync("tent_4", context)
  PrecacheUnitByNameSync("tent_5", context)
  PrecacheUnitByNameSync("tent_6", context)
  PrecacheUnitByNameSync("tent_7", context)
  PrecacheUnitByNameSync("barracks_1", context)
  PrecacheUnitByNameSync("barracks_2", context)
  PrecacheUnitByNameSync("barracks_3", context)
  PrecacheUnitByNameSync("rock_1", context)
  PrecacheUnitByNameSync("rock_2", context)
  PrecacheUnitByNameSync("rock_3", context)
  PrecacheUnitByNameSync("rock_4", context)
  PrecacheUnitByNameSync("rock_5", context)
  PrecacheUnitByNameSync("ultra_wall_1", context)
  PrecacheUnitByNameSync("ultra_wall_2", context)
  PrecacheUnitByNameSync("ultra_wall_3", context)
  PrecacheUnitByNameSync("ultra_wall_4", context)
  PrecacheUnitByNameSync("ultra_wall_5", context)
  PrecacheUnitByNameSync("demonic_wall_1", context)
  PrecacheUnitByNameSync("demonic_wall_2", context)
  PrecacheUnitByNameSync("demonic_wall_3", context)
  PrecacheUnitByNameSync("demonic_wall_4", context)
  PrecacheUnitByNameSync("demonic_wall_5", context)
  PrecacheUnitByNameSync("dragon_wall_1", context)
  PrecacheUnitByNameSync("dragon_wall_2", context)
  PrecacheUnitByNameSync("golden_dragon_wall", context)
  PrecacheUnitByNameSync("tower_1", context)
  PrecacheUnitByNameSync("tower_2", context)
  PrecacheUnitByNameSync("tower_3", context)
  PrecacheUnitByNameSync("tower_4", context)
  PrecacheUnitByNameSync("tower_5", context)
  PrecacheUnitByNameSync("tower_6", context)
  PrecacheUnitByNameSync("tower_7", context)
  PrecacheUnitByNameSync("tower_8", context)
  PrecacheUnitByNameSync("tower_9", context)
  PrecacheUnitByNameSync("tower_10", context)
  PrecacheUnitByNameSync("tower_11", context)
  PrecacheUnitByNameSync("tower_12", context)
  PrecacheUnitByNameSync("tower_13", context)
  PrecacheUnitByNameSync("true_sight_tower", context)
  PrecacheUnitByNameSync("trader_1", context)
  PrecacheUnitByNameSync("trader_2", context)
  PrecacheUnitByNameSync("trader_3", context)
  PrecacheUnitByNameSync("workers_guild", context)
  PrecacheUnitByNameSync("mother_of_nature", context)
  PrecacheUnitByNameSync("research_lab", context)
  PrecacheUnitByNameSync("worker_1", context)
  PrecacheUnitByNameSync("worker_2", context)
  PrecacheUnitByNameSync("worker_3", context)
  PrecacheUnitByNameSync("worker_4", context)
  PrecacheUnitByNameSync("worker_5", context)
  PrecacheUnitByNameSync("gold_mine_1", context)
  PrecacheUnitByNameSync("wisp_1", context)

  PrecacheResource("particle_folder", "particles/buildinghelper", context)
  PrecacheResource("particle","particles/econ/events/league_teleport_2014/teleport_end_league.vpcf",context)
  PrecacheResource("soundfile","soundevents/game_sounds_heroes/game_sounds_sven.vsndevts",context)
  PrecacheResource("particle","particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",context)
  PrecacheResource("particle","particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf",context)
  PrecacheResource("particle","particles/generic_gameplay/generic_stunned.vpcf",context)

end

-- Create the game mode when we activate
function Activate()
  GameRules.MapSpeed = string.match(GetMapName(),"%d+") or 1
  GameRules.lumber_price = 150
  GameRules.max_food = 20
  GameRules.TrollWin = false
  GameRules.heroes = {}
  GameRules.players = {}
  GameRules.firstHero = true
  GameRules.stunHeroes = true
  GameRules.trollSpawned = false
  GameRules.dcedChoosers = {}
  GameRules.trollTps = {Vector(-320,0,256),Vector(0,0,256),Vector(320,0,256),Vector(-320,-320,256),Vector(0,-320,256),Vector(320,-320,256),Vector(-320,-640,256),Vector(0,-640,256),Vector(320,-640,256)}
  GameRules.trollTimer = 30
  GameRules.angel_spawn_points = Entities:FindAllByName("angel_spawn_point")
  GameRules.shops = Entities:FindAllByClassname("trigger_shop")
  GameRules.playersColors = {{0, 102, 255},{0, 204, 255},{153, 0, 204},{225,0,255},{255, 255, 0},{255, 153, 51},{51, 204, 51},{0, 105, 0},{128, 0, 0},{176, 0, 0},{60,20,74}}
  GameRules.startTime = 0
  GameRules.colorCounter = 1
  GameRules.gold = {}
  GameRules.lumber = {}
  GameRules.goldGained = {}
  GameRules.lumberGained = {}
  GameRules.goldGiven = {}
  GameRules.lumberGiven = {}
  GameRules.scores = {}
  GameRules.types = {}
  GameRules.playerCount = 0
  
  GameRules.test = false
  if GameRules.test then
    GameRules.trollTimer = 1
  end

  GameRules.trollnelves2 = trollnelves2()
  GameRules.trollnelves2:Inittrollnelves2()
end
