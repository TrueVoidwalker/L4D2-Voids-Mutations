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
	if ( !damageTable.Attacker || !damageTable.Victim || !damageTable.Inflictor )
		return true;

	if ( damageTable.Attacker.IsPlayer() && damageTable.Victim.IsPlayer() )
	{
		if ( damageTable.Attacker.IsSurvivor() && damageTable.Victim.GetZombieType() == 6 )
		{
			local ChargeAbility = NetProps.GetPropEntityArray( damageTable.Victim, "m_customAbility", 0 );

			if ( !IsPlayerABot( damageTable.Victim ) && NetProps.GetPropIntArray( ChargeAbility, "m_isCharging", 0 ) > 0 )
				damageTable.DamageDone = floor( (damageTable.DamageDone / 3) - 1 );
		}
	}

	return true;
}