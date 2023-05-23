DirectorOptions <-
{
	weaponsToConvert =
	{
		weapon_sniper_awp				= "weapon_sniper_military_spawn"
		weapon_sniper_scout				= "weapon_hunting_rifle_spawn"
		weapon_rifle_sg552				= "weapon_rifle_spawn"
		weapon_smg_mp5				= "weapon_smg_spawn"
	}

	function ConvertWeaponSpawn( classname )
	{
		if ( classname in weaponsToConvert )
		{
			return weaponsToConvert[classname];
		}
		return 0;
	}

	DefaultItems =
	[
		"weapon_pistol_magnum",
	]

	function GetDefaultItem( idx )
	{
		if ( idx < DefaultItems.len() )
		{
			return DefaultItems[idx];
		}
		return 0;
	}

	weaponsToRemove =
	{
		weapon_melee = 0
		weapon_upgradepack_explosive = 0
		weapon_upgradepack_incendiary = 0
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

MutationState <-
{
	CurrentDifficulty = 1
	TankHealth = 4000
	FixSpecialClaw = 4
}

// Script Local Vars
local player = null;
local HealTarget = null;
local HealTotal = 0;
// ------------------------

function OnGameEvent_player_spawn( params )
{
	player = GetPlayerFromUserID( params["userid"] );

	if ( player.IsSurvivor() )
	{
		if ( player.GetMaxHealth() < 115 )
		{
			local modifycurrenthealth = player.GetHealth() * 1.15;

			player.SetMaxHealth( 115 );
			player.SetHealth( modifycurrenthealth );
		}
		// Survivors spawn with medkits and pills in Survival
		if ( Director.GetGameModeBase() == "survival" )
		{
			player.GiveItem( "weapon_first_aid_kit" );
			player.GiveItem( "weapon_pain_pills" );
		}
		// Survivors spawn with defibs and pills in Helljumper
		else if ( Director.GetGameMode() == "voidhalocoophard" )
			player.GiveItem( "weapon_pain_pills" );
	}
}

function OnGameEvent_round_start_post_nav( params )
{
	CheckDifficultyForSpecialStats( GetDifficulty() );

	foreach( wep, val in DirectorOptions.weaponsToRemove )
		EntFire( wep + "_spawn", "Kill" );
	foreach( wep, val in DirectorOptions.weaponsToConvert )
	{
		for ( local wep_spawner; wep_spawner = Entities.FindByClassname( wep_spawner, wep + "_spawn" ); )
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

function OnGameEvent_difficulty_changed( params )
{
	CheckDifficultyForSpecialStats( params["newDifficulty"] );
}

function OnGameEvent_heal_success( params )
{
	HealTarget = GetPlayerFromUserID( params["subject"] );

	HealTotal = (HealTarget.GetHealth() + 70);

	if (HealTotal > HealTarget.GetMaxHealth())
		HealTotal = HealTarget.GetMaxHealth();

	HealTarget.SetHealth( HealTotal );
}

// Tank Health Changes
function CheckDifficultyForSpecialStats( difficulty )
{
	SessionState.CurrentDifficulty = difficulty;

	local health = 0;
	if ( Director.GetGameModeBase() == "versus" )
		health = 6000;
	else if ( difficulty == "easy" )
		health = 3000;
	else if ( difficulty == "normal" )
		health = 4000;
	else if ( difficulty == "hard" )
		health = 5000;
	else if ( difficulty == "impossible" )
		health = 6000;
	
	SessionState.TankHealth = health;
}

function OnGameEvent_tank_spawn( params )
{
	local tank = GetPlayerFromUserID( params["userid"] );
	if ( !tank )
		return;
	
	tank.SetMaxHealth( SessionState.TankHealth );
	tank.SetHealth( SessionState.TankHealth );
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
		else if ( damageTable.Attacker.GetClassname() == "infected" && damageTable.Victim.IsPlayer() )
		{
			if ( damageTable.Victim.IsSurvivor() )
			{
				switch ( SessionState.CurrentDifficulty )
				{
					case 1:	// Normal
						damageTable.DamageDone = 7; break;
					case 2:	// Advanced
						damageTable.DamageDone = 9; break;
					case 3:	// Expert
						damageTable.DamageDone = 13; break;
					default:	// Easy/Other
						damageTable.DamageDone = 1; break;
				}
			}
		}
	}
	return true;
}