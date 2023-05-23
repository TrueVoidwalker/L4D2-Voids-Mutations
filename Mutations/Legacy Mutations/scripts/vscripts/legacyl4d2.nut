//=============================================================================
Msg("Activating Mutation L4D2\n");

if ( !IsModelPrecached( "models/infected/smoker.mdl" ) )
	PrecacheModel( "models/infected/smoker.mdl" );
if ( !IsModelPrecached( "models/infected/boomer.mdl" ) )
	PrecacheModel( "models/infected/boomer.mdl" );
if ( !IsModelPrecached( "models/infected/hunter.mdl" ) )
	PrecacheModel( "models/infected/hunter.mdl" );
if ( !IsModelPrecached( "models/infected/hulk.mdl" ) )
	PrecacheModel( "models/infected/hulk.mdl" );

DirectorOptions <-
{
	ActiveChallenge = 1

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
}

function OnGameEvent_round_start_post_nav( params )
{
	EntFire( "weapon_*", "AddOutput", "skin 0" );
	EntFire( "weapon_*", "AddOutput", "weaponskin -1" );

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

	local ItemstoRemove_ModelPaths =
	[
		"models/weapons/melee/w_pitchfork.mdl",
		"models/weapons/melee/w_shovel.mdl",
		"models/w_models/weapons/w_knife_t.mdl",
	]

	foreach( modelpath in ItemstoRemove_ModelPaths )
	{
		local weapon_ent = null
		while( weapon_ent = Entities.FindByModel(weapon_ent, modelpath) )
			weapon_ent.Kill()
	}
}

if ( HasPlayerControlledZombies() )
{
	if ( !IsModelPrecached( "models/v_models/weapons/v_claw_smoker.mdl" ) )
		PrecacheModel( "models/v_models/weapons/v_claw_smoker.mdl" );
	if ( !IsModelPrecached( "models/v_models/weapons/v_claw_boomer.mdl" ) )
		PrecacheModel( "models/v_models/weapons/v_claw_boomer.mdl" );
	if ( !IsModelPrecached( "models/v_models/weapons/v_claw_hunter.mdl" ) )
		PrecacheModel( "models/v_models/weapons/v_claw_hunter.mdl" );
	if ( !IsModelPrecached( "models/v_models/weapons/v_claw_hulk.mdl" ) )
		PrecacheModel( "models/v_models/weapons/v_claw_hulk.mdl" );

	function OnGameEvent_item_pickup( params )
	{
		local player = GetPlayerFromUserID( params["userid"] );

		if ( ( !player ) || ( player.IsSurvivor() ) )
			return;

		local modelName = player.GetModelName();
		if ( ( modelName.find( "l4d1" ) == null ) || ( modelName == "models/infected/hulk_dlc3.mdl" ) )
			return;

		local function SetClawModel( modelName )
		{
			local claw = player.GetActiveWeapon();
			local viewmodel = NetProps.GetPropEntity( player, "m_hViewModel" );

			if ( ( !claw ) || ( !viewmodel ) )
				return;

			claw.SetModel( modelName );
			NetProps.SetPropInt( viewmodel, "m_nModelIndex", NetProps.GetPropInt( claw, "m_nModelIndex" ) );
			NetProps.SetPropString( viewmodel, "m_ModelName", modelName );
		}

		switch( player.GetZombieType() )
		{
			case 1:
			{
				player.SetModel( "models/infected/smoker.mdl" );
				SetClawModel( "models/v_models/weapons/v_claw_smoker.mdl" );
				break;
			}
			case 2:
			{
				player.SetModel( "models/infected/boomer.mdl" );
				SetClawModel( "models/v_models/weapons/v_claw_boomer.mdl" );
				break;
			}
			case 3:
			{
				player.SetModel( "models/infected/hunter.mdl" );
				SetClawModel( "models/v_models/weapons/v_claw_hunter.mdl" );
				break;
			}
			case 8:
			{
				player.SetModel( "models/infected/hulk.mdl" );
				SetClawModel( "models/v_models/weapons/v_claw_hulk.mdl" );
				break;
			}
			default:
				break;
		}
	}
}

function OnGameEvent_player_spawn( params )
{
	local player = GetPlayerFromUserID( params["userid"] );

	if ( ( !player ) || ( player.IsSurvivor() ) )
		return;

	local modelName = player.GetModelName();
	if ( ( modelName.find( "l4d1" ) == null ) || ( modelName == "models/infected/hulk_dlc3.mdl" ) )
		return;

	switch( player.GetZombieType() )
	{
		case 1:
			player.SetModel( "models/infected/smoker.mdl" ); break;
		case 2:
			player.SetModel( "models/infected/boomer.mdl" ); break;
		case 3:
			player.SetModel( "models/infected/hunter.mdl" ); break;
		case 8:
			player.SetModel( "models/infected/hulk.mdl" ); break;
		default:
			break;
	}
}