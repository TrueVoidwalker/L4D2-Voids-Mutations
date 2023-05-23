//-----------------------------------------------------
Msg("Activating Mutation\n");

DirectorOptions <-
{
	ActiveChallenge = 1

	cm_SpecialRespawnInterval = 30
	cm_MaxSpecials = 4
	cm_AutoSpawnInfectedGhosts = 0

	function ConvertZombieClass( zombieClass )
	{
		if ( SessionState.TankQueue > 0 )
			return 8;
		else
			return zombieClass;
	}
}

MutationState <-
{
	NonBotPZCount = 0
	TankQueue = 0
	SpawnTankPOS = null
	SpawnTankLOS = null
}

function Update()
{
	if ( SessionState.TankQueue > 0 && SessionState.NonBotPZCount > 0 && Convars.GetFloat( "director_allow_infected_bots" ) == 1 )
	{
		DirectorOptions.cm_AutoSpawnInfectedGhosts = 1;
		Convars.SetValue( "director_allow_infected_bots", 0 );
	}
}

function OnGameEvent_round_start_post_nav( params )
{
	if ( Director.GetMapName() == "c5m5_bridge" || Director.GetMapName() == "c6m3_port" )
		DirectorOptions.cm_MaxSpecials = 0;

	GetInfectedPlayerCount();
}

function OnGameEvent_finale_start( params )
{
	if ( Director.GetMapName() == "c6m3_port" )
		DirectorOptions.cm_MaxSpecials = 4;
}

function OnGameEvent_gauntlet_finale_start( params )
{
	if ( Director.GetMapName() == "c5m5_bridge" )
		DirectorOptions.cm_MaxSpecials = 4;
}

function OnGameEvent_tank_spawn( params )
{
	local tank = GetPlayerFromUserID( params["userid"] );
	if ( !tank )
		return;
	
	GetInfectedPlayerCount();

	if ( IsPlayerABot( tank ) && SessionState.NonBotPZCount > 0 )
	{
		SessionState.SpawnTankPOS = tank.GetOrigin();
		SessionState.SpawnTankLOS = tank.EyeAngles();
		SessionState.TankQueue++;
		tank.Kill();
	}
	else if ( !IsPlayerABot( tank ) && SessionState.TankQueue > 0 )
	{
		tank.SetOrigin( SessionState.SpawnTankPOS );
		tank.SetAngles( SessionState.SpawnTankLOS );
		SessionState.TankQueue--;
	}

	tank.SetMaxHealth( 4000 );
	tank.SetHealth( 4000 );

	if ( SessionState.TankQueue == 0 && Convars.GetFloat( "director_allow_infected_bots" ) == 0 )
	{
		DirectorOptions.cm_AutoSpawnInfectedGhosts = 0;
		Convars.SetValue( "director_allow_infected_bots", 1 );
	}
}

function GetInfectedPlayerCount()
{
	SessionState.NonBotPZCount = 0
	local ent = null;

	while (ent = Entities.FindByClassname(ent, "player")){
		if (!ent.IsSurvivor() && !IsPlayerABot(ent)){
			SessionState.NonBotPZCount++;
		}
	}

	printl( "Current number of non-bot Special Infected is: " + SessionState.NonBotPZCount + "\n" );
}

// Buff certain SI for player use.
function AllowTakeDamage( damageTable )
{
	if ( !damageTable.Attacker || !damageTable.Victim )
		return true;

	else if ( damageTable.DamageType == 2 || damageTable.DamageType == -2147483646 || damageTable.DamageType == -1610612734 )
	{
		if ( damageTable.Attacker.IsPlayer() && damageTable.Victim.IsPlayer() )
		{
			if ( damageTable.Victim.GetZombieType() == 6 && damageTable.Attacker.IsSurvivor() )
			{
				if ( !IsPlayerABot( damageTable.Victim ) )
					damageTable.DamageDone = damageTable.DamageDone * 0.78;
			}
		}
	}
	return true;
}