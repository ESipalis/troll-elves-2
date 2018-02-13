-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function trollnelves2:_Inittrollnelves2()
  -- Setup rules
  GameRules:SetHeroRespawnEnabled( ENABLE_HERO_RESPAWN )
  GameRules:SetUseUniversalShopMode( UNIVERSAL_SHOP_MODE )
  GameRules:SetSameHeroSelectionEnabled( ALLOW_SAME_HERO_SELECTION )
  GameRules:SetHeroSelectionTime( HERO_SELECTION_TIME )
  GameRules:SetPreGameTime( PRE_GAME_TIME)
  GameRules:SetPostGameTime( POST_GAME_TIME )
  GameRules:SetTreeRegrowTime( TREE_REGROW_TIME )
  GameRules:SetUseCustomHeroXPValues ( USE_CUSTOM_XP_VALUES )
  GameRules:SetGoldPerTick(GOLD_PER_TICK)
  GameRules:SetGoldTickTime(GOLD_TICK_TIME)
  GameRules:SetRuneSpawnTime(RUNE_SPAWN_TIME)
  GameRules:SetUseBaseGoldBountyOnHeroes(USE_STANDARD_HERO_GOLD_BOUNTY)
  GameRules:SetHeroMinimapIconScale( MINIMAP_ICON_SIZE )
  GameRules:SetCreepMinimapIconScale( MINIMAP_CREEP_ICON_SIZE )
  GameRules:SetRuneMinimapIconScale( MINIMAP_RUNE_ICON_SIZE )

  GameRules:SetFirstBloodActive( ENABLE_FIRST_BLOOD )
  GameRules:SetHideKillMessageHeaders( HIDE_KILL_BANNERS )


  -- This is multiteam configuration stuff
  if USE_AUTOMATIC_PLAYERS_PER_TEAM then
    local num = math.floor(10 / MAX_NUMBER_OF_TEAMS)
    local count = 0
    for team,number in pairs(TEAM_COLORS) do
      if count >= MAX_NUMBER_OF_TEAMS then
        GameRules:SetCustomGameTeamMaxPlayers(team, 0)
      else
        GameRules:SetCustomGameTeamMaxPlayers(team, num)
      end
      count = count + 1
    end
  else
    local count = 0
    for team,number in pairs(CUSTOM_TEAM_PLAYER_COUNT) do
      if count >= MAX_NUMBER_OF_TEAMS then
        GameRules:SetCustomGameTeamMaxPlayers(team, 0)
      else
        GameRules:SetCustomGameTeamMaxPlayers(team, number)
      end
      count = count + 1
    end
  end

  if USE_CUSTOM_TEAM_COLORS then
    for team,color in pairs(TEAM_COLORS) do
      SetTeamCustomHealthbarColor(team, color[1], color[2], color[3])
    end
  end
  DebugPrint('[TROLLNELVES2] GameRules set')

  --InitLogFile( "log/trollnelves2.txt","")

  -- Event Hooks
  -- All of these events can potentially be fired by the game, though only the uncommented ones have had
  -- Functions supplied for them.  If you are interested in the other events, you can uncomment the
  -- ListenToGameEvent line and add a function to handle the event
  ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(trollnelves2, 'OnPlayerLevelUp'), self)
  ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(trollnelves2, 'OnAbilityChannelFinished'), self)
  ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(trollnelves2, 'OnPlayerLearnedAbility'), self)
  ListenToGameEvent('entity_killed', Dynamic_Wrap(trollnelves2, 'OnEntityKilled'), self)
  ListenToGameEvent('player_disconnect', Dynamic_Wrap(trollnelves2, 'OnDisconnect'), self)
  ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(trollnelves2, 'OnItemPurchased'), self)
  ListenToGameEvent('item_purchased', Dynamic_Wrap(trollnelves2, 'OnItemPurchased2'), self)
  ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(trollnelves2, 'OnItemPickedUp'), self)
  ListenToGameEvent('last_hit', Dynamic_Wrap(trollnelves2, 'OnLastHit'), self)
  ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(trollnelves2, 'OnNonPlayerUsedAbility'), self)
  ListenToGameEvent('player_changename', Dynamic_Wrap(trollnelves2, 'OnPlayerChangedName'), self)
  ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(trollnelves2, 'OnRuneActivated'), self)
  ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(trollnelves2, 'OnPlayerTakeTowerDamage'), self)
  ListenToGameEvent('tree_cut', Dynamic_Wrap(trollnelves2, 'OnTreeCut'), self)
  ListenToGameEvent('entity_hurt', Dynamic_Wrap(trollnelves2, 'OnEntityHurt'), self)
  ListenToGameEvent('player_connect', Dynamic_Wrap(trollnelves2, 'PlayerConnect'), self)
  ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(trollnelves2, 'OnAbilityUsed'), self)
  ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(trollnelves2, 'OnGameRulesStateChange'), self)
  ListenToGameEvent('npc_spawned', Dynamic_Wrap(trollnelves2, 'OnNPCSpawned'), self)
  ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(trollnelves2, 'OnPlayerPickHero'), self)
  ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(trollnelves2, 'OnTeamKillCredit'), self)
  ListenToGameEvent("player_reconnected", Dynamic_Wrap(trollnelves2, 'OnPlayerReconnect'), self)
  ListenToGameEvent("dota_action_item", Dynamic_Wrap(trollnelves2, 'OnActionItem'), self)

  ListenToGameEvent("dota_illusions_created", Dynamic_Wrap(trollnelves2, 'OnIllusionsCreated'), self)
  ListenToGameEvent("dota_item_combined", Dynamic_Wrap(trollnelves2, 'OnItemCombined'), self)
  ListenToGameEvent("dota_player_begin_cast", Dynamic_Wrap(trollnelves2, 'OnAbilityCastBegins'), self)
  ListenToGameEvent("dota_tower_kill", Dynamic_Wrap(trollnelves2, 'OnTowerKill'), self)
  ListenToGameEvent("dota_player_selected_custom_team", Dynamic_Wrap(trollnelves2, 'OnPlayerSelectedCustomTeam'), self)
  ListenToGameEvent("dota_npc_goal_reached", Dynamic_Wrap(trollnelves2, 'OnNPCGoalReached'), self)
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(trollnelves2, 'OnConnectFull'), self)
  ListenToGameEvent('inventory_updated', Dynamic_Wrap(trollnelves2, 'InventoryUpdated'), self)
  ListenToGameEvent('dota_inventory_changed', Dynamic_Wrap(trollnelves2, 'InventoryChanged'), self)

  ListenToGameEvent("player_chat", Dynamic_Wrap(trollnelves2, 'OnPlayerChat'), self)
  
  --ListenToGameEvent("dota_tutorial_shop_toggled", Dynamic_Wrap(trollnelves2, 'OnShopToggled'), self)

  --ListenToGameEvent('player_spawn', Dynamic_Wrap(trollnelves2, 'OnPlayerSpawn'), self)
  --ListenToGameEvent('dota_unit_event', Dynamic_Wrap(trollnelves2, 'OnDotaUnitEvent'), self)
  --ListenToGameEvent('nommed_tree', Dynamic_Wrap(trollnelves2, 'OnPlayerAteTree'), self)
  --ListenToGameEvent('player_completed_game', Dynamic_Wrap(trollnelves2, 'OnPlayerCompletedGame'), self)
  --ListenToGameEvent('dota_match_done', Dynamic_Wrap(trollnelves2, 'OnDotaMatchDone'), self)
  --ListenToGameEvent('dota_combatlog', Dynamic_Wrap(trollnelves2, 'OnCombatLogEvent'), self)
  --ListenToGameEvent('dota_player_killed', Dynamic_Wrap(trollnelves2, 'OnPlayerKilled'), self)
  --ListenToGameEvent('player_team', Dynamic_Wrap(trollnelves2, 'OnPlayerTeam'), self)

  --[[This block is only used for testing events handling in the event that Valve adds more in the future
  Convars:RegisterCommand('events_test', function()
      trollnelves2:StartEventTest()
    end, "events test", 0)]]

  local spew = 0
  if TROLLNELVES2_DEBUG_SPEW then
    spew = 1
  end
  Convars:RegisterConvar('trollnelves2_spew', tostring(spew), 'Set to 1 to start spewing trollnelves2 debug info.  Set to 0 to disable.', 0)

  -- Change random seed
  local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
  math.randomseed(tonumber(timeTxt))

  -- Initialized tables for tracking state
  self.bSeenWaitForPlayers = false
  self.vUserIds = {}

  DebugPrint('[TROLLNELVES2] Done loading trollnelves2 trollnelves2!\n\n')
end

mode = nil

-- This function is called as the first player loads and sets up the trollnelves2 parameters
function trollnelves2:_Capturetrollnelves2()
  if mode == nil then
    -- Set trollnelves2 parameters
    mode = GameRules:GetGameModeEntity()        
    mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED )
    mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
    mode:SetCustomBuybackCostEnabled( CUSTOM_BUYBACK_COST_ENABLED )
    mode:SetCustomBuybackCooldownEnabled( CUSTOM_BUYBACK_COOLDOWN_ENABLED )
    mode:SetBuybackEnabled( BUYBACK_ENABLED )
    mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
    mode:SetTopBarTeamValuesVisible( TOP_BAR_VISIBLE )
    mode:SetUseCustomHeroLevels ( USE_CUSTOM_HERO_LEVELS )
    mode:SetCustomHeroMaxLevel ( MAX_LEVEL )
    mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

    mode:SetBotThinkingEnabled( USE_STANDARD_DOTA_BOT_THINKING )
    mode:SetTowerBackdoorProtectionEnabled( ENABLE_TOWER_BACKDOOR_PROTECTION )

    mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
    mode:SetGoldSoundDisabled( DISABLE_GOLD_SOUNDS )
    mode:SetRemoveIllusionsOnDeath( REMOVE_ILLUSIONS_ON_DEATH )

    mode:SetAlwaysShowPlayerInventory( SHOW_ONLY_PLAYER_INVENTORY )
    mode:SetAnnouncerDisabled( DISABLE_ANNOUNCER )
    if FORCE_PICKED_HERO ~= nil then
      mode:SetCustomGameForceHero( FORCE_PICKED_HERO )
    end
    mode:SetFixedRespawnTime( FIXED_RESPAWN_TIME ) 
    mode:SetFountainConstantManaRegen( FOUNTAIN_CONSTANT_MANA_REGEN )
    mode:SetFountainPercentageHealthRegen( FOUNTAIN_PERCENTAGE_HEALTH_REGEN )
    mode:SetFountainPercentageManaRegen( FOUNTAIN_PERCENTAGE_MANA_REGEN )
    mode:SetLoseGoldOnDeath( LOSE_GOLD_ON_DEATH )
    mode:SetMaximumAttackSpeed( MAXIMUM_ATTACK_SPEED )
    mode:SetMinimumAttackSpeed( MINIMUM_ATTACK_SPEED )
    mode:SetStashPurchasingDisabled ( DISABLE_STASH_PURCHASING )

    for rune, spawn in pairs(ENABLED_RUNES) do
      mode:SetRuneEnabled(rune, spawn)
    end

    mode:SetUnseenFogOfWarEnabled(USE_UNSEEN_FOG_OF_WAR)

    self:OnFirstPlayerLoaded()
  end 
end
