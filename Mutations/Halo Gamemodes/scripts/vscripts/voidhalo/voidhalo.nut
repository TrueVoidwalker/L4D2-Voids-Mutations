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

local player = null;

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
	player = GetPlayerFromUserID( params["subject"] );

	local HealTotal = (player.GetHealth() + 70);

	if ( HealTotal > player.GetMaxHealth() )
		HealTotal = player.GetMaxHealth();

	player.SetHealth( HealTotal );
}

function OnGameEvent_pills_used( params )
{
	player = GetPlayerFromUserID( params["subject"] );

	local playerHealth = player.GetHealth();
	local playerBufferHealth = player.GetHealthBuffer();
	local HealTotal = (player.GetHealth() + 70);

	if ( playerHealth >= 45 )
	{
		HealTotal = ( player.GetMaxHealth() - playerHealth );

		player.SetHealthBuffer( HealTotal );
	}
	else
	{
		local playerShieldMod = (playerBufferHealth + 70 + floor( (playerHealth - 45) * 1.5555));

		if ( playerShieldMod > 70 )
			playerShieldMod = 70;

		player.SetHealth( 45 );
		player.SetHealthBuffer( playerShieldMod );
	}
}

function OnGameEvent_adrenaline_used( params )
{
	player = GetPlayerFromUserID( params["subject"] );

	local playerHealth = player.GetHealth();
	local playerBufferHealth = player.GetHealthBuffer();
	local HealTotal = player.GetHealthBuffer();

	if ( playerHealth >= 45 )
	{
		HealTotal = ( playerHealth + playerBufferHealth + 45 );

		if ( HealTotal > player.GetMaxHealth() )
		{
			HealTotal = (player.GetMaxHealth() - playerHealth);

			player.SetHealthBuffer( HealTotal );
		}
		else
		{
			HealTotal = (HealTotal - playerHealth);

			player.SetHealthBuffer( HealTotal );
		}
	}
	else if ( playerHealth >= 30 )
		player.SetHealth( 45 );
	else if ( playerHealth >= 15 )
		player.SetHealth( 30 );
	else
		player.SetHealth( 15 );
}

function OnGameEvent_revive_success( params )
{
	player = GetPlayerFromUserID( params["subject"] );

	player.SetHealth( 45 );
	player.SetHealthBuffer( 70 );
}

function CheckDifficultyForSpecialStats( difficulty )
{
	SessionState.CurrentDifficulty = difficulty;

	local health = 0;
	if ( Director.GetGameModeBase() == "versus" )
		health = [6000, 6000, 6000, 6000];
	else
		health = [3000, 4000, 5000, 6000];
	
	SessionState.TankHealth = health[difficulty];
}

function OnGameEvent_tank_spawn( params )
{
	local tank = GetPlayerFromUserID( params["userid"] );
	if ( !tank )
		return;
	
	tank.SetMaxHealth( SessionState.TankHealth );
	tank.SetHealth( SessionState.TankHealth );
}

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
						damageTable.DamageDone = ( SessionState.FixSpecialClaw * 2 ); break;
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

	// Spitter acid damage
	if  ( damageTable.DamageType == 265216 || damageTable.DamageType == 263168 )
	{
		if ( damageTable.Attacker.GetZombieType() == 4 && damageTable.Victim.IsSurvivor() )
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