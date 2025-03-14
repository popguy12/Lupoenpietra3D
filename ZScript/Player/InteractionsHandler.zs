class Lupo3D_PlayerHandler : EventHandler
{
	int kicktimer;
	const kickcooldown = 18;
	
    override void WorldTick()
    {
        PlayerInfo plyr = players[consoleplayer];

		if(kicktimer > 0)
			kicktimer--;
    }
	
	override void PlayerEntered(PlayerEvent e)
	{
        let steps = BD_Footsteps(Actor.Spawn("BD_Footsteps"));
		if (steps)
		{
			steps.Init(players[e.playerNumber].mo);
			steps.fplayer = players[e.playerNumber];
		}
		
		players[e.PlayerNumber].mo.A_GiveInventory("Z_NashMove", 1);
	}
	
    override void NetworkProcess(ConsoleEvent e)
    {
        let pl = players[e.Player].mo;
        if(!pl)
         return;

		if (e.Name ~== "KickEm")
		{	
			if(kicktimer == 0)
			{
				//pl.player.A_GiveInventory("DoKick");
			}
		}
	}
}

class BD_Footsteps : Actor
{
	Default {
		+NOINTERACTION
	}
	
	//the player footsteps are attached to.
	PlayerPawn toFollow;
	PlayerInfo fplayer;
	
	protected int updateTics;
	
	protected transient CVar f_enabled_cache;	
	protected transient CVar f_vol_cache;
	protected transient CVar f_delay_cache;
	protected bool f_enabled;	
	protected double f_vol;
	protected double f_delay;

	//attach PlayerPawn, load the texture/sound associated tables.
	void Init( PlayerPawn attached_player)
	{
		toFollow = attached_player;
	}
	
	override void Tick()
	{
		if (!toFollow) {
			destroy();
			return;
		}
		//Cache cvars:
		if (f_enabled_cache == null)
			f_enabled_cache = CVar.GetCVar('bdoom_fs_enabled',fplayer);
		if (f_vol_cache == null)
			f_vol_cache = CVar.GetCVar('bdoom_fs_volume_mul',fplayer);
		if (f_delay_cache == null)
			f_delay_cache = CVar.GetCVar('bdoom_fs_delay_mul',fplayer);
		f_enabled = f_enabled_cache.GetBool();
		f_vol = f_vol_cache.GetFloat();
		f_delay = f_delay_cache.GetFloat();
		
		updateTics--;
		
		//0) do nothing until updateTics is below 0
		if (updateTics > 0)
			return;
		
		//1) Update the Footstep actor to follow Player.
		SetOrigin(toFollow.pos, false);
		floorz = toFollow.floorz;
		   
		double playerVel2D = sqrt(toFollow.vel.x * toFollow.vel.x + toFollow.vel.y * toFollow.vel.y);
		
		//2) Only play footsteps when on ground, and if the player is moving fast enough.
		if (f_enabled && (playerVel2D > 0.1) && (toFollow.pos.z - toFollow.floorz <= 0)) {			
			
			sound stepsound;			
			//current floor texture for the player:
			name floortex = name(Texman.GetName(toFollow.floorpic));
			//no sound if steppin on sky
			if (floorpic == skyflatnum)
				stepsound = "none";
			else if (toFollow.CountInv("IsProne") || toFollow.CountInv("Kicking"))
				stepsound = "Prone/default";
			else
				stepsound = GetFlatSound(Texman.GetName(toFollow.floorpic));
			//sound volume is amplified by speed.
			double soundVolume = f_vol * playerVel2D * 0.12; //multiplied by 0.12 because raw value is too high to be used as volume
			//play the sound if it's non-null
			if (stepsound != "none")
			{
				toFollow.A_StartSound(stepsound, CHAN_AUTO, CHANF_LOCAL|CHANF_UI, volume:soundVolume);
				/*
				if(tofollow.GetCrouchFactor() <= 0.5)
				{
					toFollow.A_StartSound("crouch/default", CHAN_AUTO, CHANF_LOCAL|CHANF_UI, volume:soundVolume * 0.75);
				}
				if(tofollow.CountInv("COD_AT4"))
				{
					toFollow.A_StartSound("uni/gear/big", CHAN_AUTO, CHANF_LOCAL|CHANF_UI, volume:((soundVolume / 5) * tofollow.countinv("COD_AT4")));
				}
				if(tofollow.CountInv("COD_C4Ammo")) //[Pop] also check Claymore and Phone later.
				{
					toFollow.A_StartSound("uni/gear/medium", CHAN_AUTO, CHANF_LOCAL|CHANF_UI, volume:soundVolume / 4);
				}
				if(tofollow.CountInv("GrenadeAmmo") || tofollow.CountInv("BangAmmo"))
				{
					toFollow.A_StartSound("uni/gear/small", CHAN_AUTO, CHANF_LOCAL|CHANF_UI, volume:soundVolume);
				}
				*/
			}
			
			//delay CVAR value is inverted, where 1.0 is default, higher means more frequent, smaller means less frequent
			double dmul = (2.1 - Clamp(f_delay,0.1,2));
			updateTics = (gameinfo.normforwardmove[0] - playerVel2D) * dmul;   
		} else {
			// no need to poll for change too often
			updateTics = 1;
		}
	}
	
	// a totally ugly check for texture name:
	sound GetFlatSound(name texname) {
		//first check the all flat names array
		bool inlist = false;
		for (int i = 0; i < FLATS_NAMES.Size(); i++) {
			if (FLATS_NAMES[i] == texname) {
				inlist = true;
				break;
			}
		}
		// and return default sound if not found
		if (!inlist) {			
			return "step/default";
		}
		//if found, check against each array with the names of differently sounding floors
		for (int i = 0; i < FLATS_SLIME.Size(); i++) {
			if (FLATS_SLIME[i] == texname)
				return "step/slime";
		}
		for (int i = 0; i < FLATS_SLIMY.Size(); i++) {
			if (FLATS_SLIMY[i] == texname)
				return "step/slimy";
		}
		for (int i = 0; i < FLATS_LAVA.Size(); i++) {
			if (FLATS_LAVA[i] == texname)
				return "step/lava";
		}
		for (int i = 0; i < FLATS_ROCK.Size(); i++) {
			if (FLATS_ROCK[i] == texname)
				return "step/rock";
		}
		for (int i = 0; i < FLATS_WOOD.Size(); i++) {
			if (FLATS_WOOD[i] == texname)
				return "step/wood";
		}
		for (int i = 0; i < FLATS_TILEA.Size(); i++) {
			if (FLATS_TILEA[i] == texname)
				return "step/tile/a";
		}
		for (int i = 0; i < FLATS_TILEB.Size(); i++) {
			if (FLATS_TILEB[i] == texname)
				return "step/tile/b";
		}
		for (int i = 0; i < FLATS_HARD.Size(); i++) {
			if (FLATS_HARD[i] == texname)
				return "step/hard";
		}
		for (int i = 0; i < FLATS_CARPET.Size(); i++) {
			if (FLATS_CARPET[i] == texname)
				return "step/carpet";
		}
		for (int i = 0; i < FLATS_METALA.Size(); i++) {
			if (FLATS_METALA[i] == texname)
				return "step/metal/a";
		}
		for (int i = 0; i < FLATS_METALB.Size(); i++) {
			if (FLATS_METALB[i] == texname)
				return "step/metal/b";
		}
		for (int i = 0; i < FLATS_DIRT.Size(); i++) {
			if (FLATS_DIRT[i] == texname)
				return "step/dirt";
		}
		for (int i = 0; i < FLATS_GRAVEL.Size(); i++) {
			if (FLATS_GRAVEL[i] == texname)
				return "step/gravel";
		}
		return "step/default";
	}
	
	static const name FLATS_NAMES[] = {
			"FWATER1","FWATER2","FWATER3","FWATER4",
			"FLOOR0_1","FLOOR0_3","FLOOR1_7","FLOOR4_1","FLOOR4_5","FLOOR4_6",
			"TLITE6_1","TLITE6_5","CEIL3_1","CEIL3_2","CEIL4_2","CEIL4_3","CEIL5_1",
			"FLAT2","FLAT5","FLAT18",
			"FLOOR0_2","FLOOR0_5","FLOOR0_7",
			"FLAT5_3","CRATOP1","CRATOP2",
			"FLAT9","FLAT17","FLAT19",
			"COMP01","GRNLITE1","FLOOR1_1","FLAT14","FLAT5_5","FLOOR1_6",
			"CEIL4_1","GRASS1","GRASS2","RROCK16","RROCK19",
			"FLOOR6_1","FLOOR6_2","FLAT10",
			"MFLR8_3","MFLR8_4","RROCK17","RROCK18",
			"FLOOR0_6","FLOOR4_8","FLOOR5_1","FLOOR5_2","FLOOR5_3","FLOOR5_4",
			"TLITE6_4","TLITE6_6","FLOOR7_1","MFLR8_1","CEIL3_5",
			"CEIL5_2","CEIL3_6","FLAT8",
			"SLIME13","STEP1","STEP2",
			"GATE1","GATE2","GATE3",
			"CEIL1_2","CEIL1_3","SLIME14","SLIME15","SLIME16",
			"FLAT22","FLAT23","CONS1_1","CONS1_5","CONS1_7",
			"GATE4","FLAT4","FLAT1","FLAT5_4",
			"MFLR8_2","FLAT1_1","FLAT1_2","FLAT1_3","FLAT5_7","FLAT5_8",
			"GRNROCK","RROCK01","RROCK02","RROCK03","RROCK04","RROCK05","RROCK06","RROCK07","RROCK08","RROCK09","RROCK10","RROCK11","RROCK12","RROCK13","RROCK14","RROCK15","RROCK20",
			"SLIME09","SLIME10","SLIME11","SLIME12","FLAT5_6","FLOOR3_3","FLAT20",
			"CEIL3_3","CEIL3_4","FLAT3","FLOOR7_2",
			"DEM1_1","DEM1_2","DEM1_3","DEM1_4","DEM1_5","DEM1_6",
			"CEIL1_1","FLAT5_1","FLAT5_2",
			"NUKAGE1","NUKAGE2","NUKAGE3","BLOOD1","BLOOD2","BLOOD3","SLIME01","SLIME02","SLIME03","SLIME04","SLIME05","SLIME06","SLIME07","SLIME08",
			"SFLR6_1","SFLR6_4","SFLR7_1","SFLR7_4","LAVA1","LAVA2","LAVA3","LAVA4","F_SKY1","
			BDT_WFL","BDT_BFL","BDT_LFL","BDT_AFL","BDT_SFL1","BDT_SFL2"
		};
		
		//"step/slime"
		static const name FLATS_SLIME[] = {	"BDT_WFL", "BDT_BFL", "BDT_AFL", "BDT_SFL1", "BDT_SFL2", "BLOOD1", "BLOOD2", "BLOOD3", "NUKAGE1", "NUKAGE2", "NUKAGE3", "SLIME01", "SLIME02", "SLIME03", "SLIME04", "SLIME05", "SLIME06", "SLIME07", "SLIME08", "FWATER1", "FWATER2", "FWATER3", "FWATER4" };
		//"step/slimy"
		static const name FLATS_SLIMY[] = { "SFLR6_1","SFLR6_4","SFLR7_1","SFLR7_4" };
		//"step/lava"
		static const name FLATS_LAVA[]	= { "LAVA1","LAVA2","LAVA3","LAVA4","BDT_LFL" };
		//"step/rock"
		static const name FLATS_ROCK[]	= { "SLIME09","SLIME10","SLIME11","SLIME12","RROCK01","RROCK02","RROCK05","RROCK06","RROCK07","RROCK08","FLAT1","FLAT1_1","FLAT1_2","FLAT5_6","FLAT5_7","FLAT5_8","FLOOR5_4","GRNROCK","MFLR8_2","MFLR8_3","RROCK03","RROCK04","RROCK09","RROCK10","RROCK11","RROCK12","RROCK13","RROCK14","RROCK15","SLIME13" };
		//"step/wood"
		static const name FLATS_WOOD[]	= { "FLOOR0_2","CEIL1_1","CRATOP1","CRATOP2","FLAT5_1","FLAT5_2" };
		//"step/tile/a"
		static const name FLATS_TILEA[] = { "CEIL1_3","CEIL3_3","CEIL3_4","COMP01","FLAT2","FLAT3","FLAT8","FLAT9","FLAT17","FLAT18","FLAT19","FLOOR0_6","FLOOR0_7","FLOOR3_3","FLOOR4_1","FLOOR4_5","FLOOR4_6","FLOOR4_8","FLOOR5_1","FLOOR5_2","FLOOR5_3","TLITE6_1","TLITE6_4","TLITE6_5","TLITE6_6" };
		//"step/tile/b"
		static const name FLATS_TILEB[] = { "DEM1_1","DEM1_2","DEM1_3","DEM1_4","DEM1_5","DEM1_6","FLOOR7_2" };
		//"step/hard"
		static const name FLATS_HARD[]	= { "CEIL3_1","CEIL3_2","CEIL3_5","CEIL3_6","CEIL5_1","CEIL5_2","FLAT5","FLOOR0_1","FLOOR0_3","FLOOR1_6","FLOOR1_7","FLOOR7_1","GRNLITE1","MFLR8_1" };
		//"step/carpet"
		static const name FLATS_CARPET[] = { "CEIL4_1","CEIL4_2","CEIL4_3","FLAT5_3","FLAT5_4","FLAT5_5","FLAT14","FLOOR1_1" };
		//"step/metal/a"
		static const name FLATS_METALA[] = { "FLOOR0_5","CEIL1_2","FLAT1_3","FLAT20","GATE1","GATE2","GATE3","SLIME14","SLIME15","SLIME16","STEP1","STEP2" };
		//"step/metal/b"
		static const name FLATS_METALB[] = { "CONS1_1","CONS1_5","CONS1_7","FLAT4","FLAT22","FLAT23","GATE4" };
		//"step/dirt"
		static const name FLATS_DIRT[]	= { "FLAT10","GRASS1","GRASS2","MFLR8_4","RROCK16","RROCK17","RROCK18","RROCK19","RROCK20" };
		//"step/gravel"
		static const name FLATS_GRAVEL[] = { "FLOOR6_1","FLOOR6_2" };
}