//-----------------------------------------------------
Msg("Activating Mutation\n");

DirectorOptions <-
{
	ActiveChallenge = 1

	cm_SpecialRespawnInterval = 30
	cm_MaxSpecials = 4
}

MutationState <-
{
	BotTankCount = 0
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

	tank.SetMaxHealth( 4000 );
	tank.SetHealth( 4000 );
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