//-----------------------------------------------------
Msg("Activating CompCo-op\n");

DirectorOptions <-
{
	ActiveChallenge = 1
	cm_SpecialRespawnInterval = 25
	cm_MaxSpecials = 4
	cm_AggressiveSpecials = 1
}

EntFire( "worldspawn", "RunScriptFile", "anv_versus" );

MutationState <-
{
	SpecialsDisabled = 0
	TankHealth = 6000
	TankCount = 0
	CurrentDifficulty = 1
	FixSpecialClaw = 4
}

function Update()
{
	if ( Director.IsTankInPlay() )
	{
		if ( SessionState.TankCount >= 4 && DirectorOptions.cm_MaxSpecials != 0 )
			DirectorOptions.cm_MaxSpecials = 0;
		else if ( SessionState.TankCount == 3 && DirectorOptions.cm_MaxSpecials != 1 )
			DirectorOptions.cm_MaxSpecials = 1;
		else if ( SessionState.TankCount == 2 && DirectorOptions.cm_MaxSpecials != 2 )
			DirectorOptions.cm_MaxSpecials = 2;
		else if ( !DirectorOptions.cm_MaxSpecials == 3 )
			DirectorOptions.cm_MaxSpecials = 3;
	}
	else if ( DirectorOptions.cm_MaxSpecials < 4 && SessionState.SpecialsDisabled == 0 )
		DirectorOptions.cm_MaxSpecials = 4;
}

function OnGameEvent_round_start_post_nav( params )
{
	if ( Director.GetMapName() == "c5m5_bridge" || Director.GetMapName() == "c6m3_port" )
		SessionState.SpecialsDisabled = 1; DirectorOptions.cm_MaxSpecials = 0;

	CheckDifficultyForSpecialStats( GetDifficulty() );
}

function OnGameEvent_tank_spawn( params )
{
	local tank = GetPlayerFromUserID( params["userid"] );
	if ( !tank )
		return;

	SessionState.TankCount++;
	tank.SetMaxHealth( SessionState.TankHealth );
	tank.SetHealth( SessionState.TankHealth );
}

function OnGameEvent_tank_killed( params )
{
	SessionState.TankCount--;
}

function OnGameEvent_difficulty_changed( params )
{
	CheckDifficultyForSpecialStats( params["newDifficulty"] );
}

function OnGameEvent_finale_start( params )
{
	if ( Director.GetMapName() == "c6m3_port" )
		SessionState.SpecialsDisabled = 0; DirectorOptions.cm_MaxSpecials = 4;
}

function OnGameEvent_gauntlet_finale_start( params )
{
	if ( Director.GetMapName() == "c5m5_bridge" )
		SessionState.SpecialsDisabled = 0; DirectorOptions.cm_MaxSpecials = 4;
}

function CheckDifficultyForSpecialStats( difficulty )
{
	SessionState.CurrentDifficulty = difficulty;

	local health = [4500, 6000, 12000, 12000];
	SessionState.TankHealth = health[difficulty];
}

// Fix Special Infected damage to mimic VS.
function AllowTakeDamage( damageTable )
{
	if ( !damageTable.Attacker || !damageTable.Victim || !damageTable.Inflictor )
		return true;

	if ( damageTable.Attacker.IsPlayer() && damageTable.Victim.IsPlayer() )
	{
		if ( damageTable.Attacker.IsSurvivor() && damageTable.Victim.GetZombieType() == 6 )
		{
			local ChargeAbility = NetProps.GetPropEntityArray( damageTable.Victim, "m_customAbility", 0 );

			if ( NetProps.GetPropIntArray( ChargeAbility, "m_isCharging", 0 ) > 0 )
			{
				damageTable.DamageDone = floor( (damageTable.DamageDone + 1) * 3 );
				return true;
			}
		}
	}

	if ( damageTable.DamageType == 128 )
	{
		if ( damageTable.Attacker.IsPlayer() && damageTable.Victim.IsPlayer() )
		{
			if ( damageTable.Victim.IsSurvivor() )
			{
				if ( damageTable.Attacker.IsStaggering() )
					return false;
				else if ( damageTable.Victim.GetSpecialInfectedDominatingMe() == damageTable.Attacker )
					return true;

				switch ( damageTable.Attacker.GetZombieType() )
				{
					case 1:	// Smoker
						SessionState.FixSpecialClaw = Convars.GetFloat( "smoker_pz_claw_dmg" ); break;
					case 2:	// Boomer
						SessionState.FixSpecialClaw = Convars.GetFloat( "boomer_pz_claw_dmg" ); break;
					case 3:	// Hunter
						SessionState.FixSpecialClaw = Convars.GetFloat( "hunter_pz_claw_dmg" ); break;
					case 4:	// Spitter
						SessionState.FixSpecialClaw = Convars.GetFloat( "spitter_pz_claw_dmg" ); break;
					case 5:	// Jockey
						SessionState.FixSpecialClaw = Convars.GetFloat( "jockey_pz_claw_dmg" ); break;
					case 6:	// Charger
						SessionState.FixSpecialClaw = Convars.GetFloat( "charger_pz_claw_dmg" ); break;
					case 8:	// Tank
						SessionState.FixSpecialClaw = Convars.GetFloat( "vs_tank_damage" ); break;
				}

				switch ( SessionState.CurrentDifficulty )
				{
					case 1:	// Normal
						damageTable.DamageDone = SessionState.FixSpecialClaw; break;
					case 2:	// Advanced
						damageTable.DamageDone = ( SessionState.FixSpecialClaw * 1.5 ); break;
					case 3:	// Expert
					{
						if ( damageTable.Attacker.GetZombieType() == 8 )
							damageTable.DamageDone = 100;
						else
							damageTable.DamageDone = ( SessionState.FixSpecialClaw * 4 );
	
						break
					}
					default:	// Easy/Other
						damageTable.DamageDone = ( SessionState.FixSpecialClaw / 2 ); break;
				}
			}
		}
	}
	return true;
}