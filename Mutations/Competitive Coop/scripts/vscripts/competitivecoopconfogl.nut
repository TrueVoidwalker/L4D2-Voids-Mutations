//-----------------------------------------------------
Msg("Activating CompCo-op: Confogl\n");

DirectorOptions <-
{
	ActiveChallenge = 1
	cm_SpecialRespawnInterval = 25
	cm_MaxSpecials = 4

	weaponsToConvert =
	{
		weapon_autoshotgun		= "weapon_pumpshotgun_spawn"
		weapon_shotgun_spas		= "weapon_shotgun_chrome_spawn"
		weapon_rifle			= "weapon_smg_spawn"
		weapon_rifle_desert		= "weapon_smg_spawn"
		weapon_rifle_sg552		= "weapon_smg_mp5_spawn"
		weapon_rifle_ak47		= "weapon_smg_silenced_spawn"
		// weapon_hunting_rifle		= "weapon_smg_silenced_spawn"
		weapon_sniper_military	= "weapon_shotgun_chrome_spawn"
		weapon_sniper_awp		= "weapon_shotgun_chrome_spawn"
		weapon_sniper_scout		= "weapon_pumpshotgun_spawn"
		// weapon_first_aid_kit		= "weapon_pain_pills_spawn"
	}

	function ConvertWeaponSpawn( classname )
	{
		if ( classname in weaponsToConvert )
		{
			return weaponsToConvert[classname];
		}
		return 0;
	}

	weaponsToRemove =
	{
		// weapon_defibrillator = 0
		weapon_grenade_launcher = 0
		weapon_upgradepack_explosive = 0
		weapon_upgradepack_incendiary = 0
		weapon_chainsaw = 0
		weapon_propanetank = 0
		weapon_oxygentank = 0
		weapon_rifle_m60 = 0
		upgrade_item = 0
	}

	function AllowWeaponSpawn( classname )
	{
		if ( classname in weaponsToRemove )
		{
			return false;
		}
		return true;
	}

	function ShouldAvoidItem( classname )
	{
		if ( classname in weaponsToRemove )
		{
			return true;
		}
		return false;
	}
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
		if ( SessionState.TankCount >= 4 && !DirectorOptions.cm_MaxSpecials == 0 )
			DirectorOptions.cm_MaxSpecials = 0;
		else if ( SessionState.TankCount == 3 && !DirectorOptions.cm_MaxSpecials == 1 )
			DirectorOptions.cm_MaxSpecials = 1;
		else if ( SessionState.TankCount == 2 && !DirectorOptions.cm_MaxSpecials == 2 )
			DirectorOptions.cm_MaxSpecials = 2;
		else if ( !DirectorOptions.cm_MaxSpecials == 3 )
			DirectorOptions.cm_MaxSpecials = 3;
	}
	else if ( DirectorOptions.cm_MaxSpecials < 4 && SessionState.SpecialsDisabled == 0 )
		DirectorOptions.cm_MaxSpecials = 4;
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

function OnGameEvent_round_start_post_nav( params )
{
	foreach( wep, val in DirectorOptions.weaponsToRemove )
		EntFire( wep + "_spawn", "Kill" );
	foreach( wep, val in DirectorOptions.weaponsToConvert )
	{
		local wep_spawner = null;
		while ( wep_spawner = Entities.FindByClassname( wep_spawner, wep + "_spawn" ) )
		{
			if ( wep_spawner.IsValid() )
			{
				local spawnTable =
				{
					origin = wep_spawner.GetOrigin(),
					angles = wep_spawner.GetAngles().ToKVString(),
					targetname = wep_spawner.GetName(),
					count = NetProps.GetPropInt( wep_spawner, "m_itemCount" ),
					spawnflags = NetProps.GetPropInt( wep_spawner, "m_spawnflags" )
				}
				wep_spawner.Kill();
				SpawnEntityFromTable(val, spawnTable);
			}
		}
	}

	if ( Director.GetMapName() == "c5m5_bridge" || Director.GetMapName() == "c6m3_port" )
		SessionState.SpecialsDisabled = 1;
		DirectorOptions.cm_MaxSpecials = 0;

	CheckDifficultyForSpecialStats( GetDifficulty() );
}

function OnGameEvent_difficulty_changed( params )
{
	CheckDifficultyForSpecialStats( params["newDifficulty"] );
}

function OnGameEvent_finale_start( params )
{
	if ( Director.GetMapName() == "c6m3_port" )
		SessionState.SpecialsDisabled = 0;
		DirectorOptions.cm_MaxSpecials = 4;
}

function OnGameEvent_gauntlet_finale_start( params )
{
	if ( Director.GetMapName() == "c5m5_bridge" )
		SessionState.SpecialsDisabled = 0;
		DirectorOptions.cm_MaxSpecials = 4;
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
	if ( !damageTable.Attacker || !damageTable.Victim )
		return true;

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

	// Spitter acid damage
	if  ( damageTable.DamageType == 265216 || damageTable.DamageType == 263168 )
	{
		if ( damageTable.Attacker.GetZombieType() == 4 )
		{
			local spitSingleProcDmg = floor( damageTable.DamageDone );

			if ( spitSingleProcDmg > 0 )
			{
				switch ( SessionState.CurrentDifficulty )
				{
					case 1:	// Normal
						damageTable.DamageDone = 3; break;
					case 2:	// Advanced
						damageTable.DamageDone = 4; break;
					case 3:	// Expert
						damageTable.DamageDone = 5; break;
					default:	// Easy/Other
						damageTable.DamageDone = 2; break;
				}
			}
		}
	}
	return true;
}