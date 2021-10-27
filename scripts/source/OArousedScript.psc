ScriptName OArousedScript Extends ostimaddon 

oarousedscript Function GetOAroused() Global
	return game.GetFormFromFile(0x800, "oaroused.esp") as OArousedScript
EndFunction

import outils 

ODatabaseScript odatabase

osexbar bar


string CheckTimeKey
string arousalkey
string arousalmultkey

float Property ScanDistance = 5120.0 AutoReadOnly

keyword property EroticArmor auto

int Property CheckKey
	int Function Get()
		return StorageUtil.GetIntValue(none, "oaroused.key")
	EndFunction

	Function Set(int val)
		StorageUtil.SetIntValue(none, "oaroused.key", val)
	EndFunction
EndProperty

bool Property emptyArousalBeforeEnd
	bool Function Get()
		return StorageUtil.GetIntValue(none, "oaroused.emptybeforeend") as bool
	EndFunction

	Function Set(bool val)
		StorageUtil.SetIntValue(none, "oaroused.emptybeforeend", val as int)
	EndFunction
EndProperty

bool Property modStats
	bool Function Get()
		return StorageUtil.GetIntValue(none, "oaroused.modifystats") as bool
	EndFunction

	Function Set(bool val)
		StorageUtil.SetIntValue(none, "oaroused.modifystats", val as int)
	EndFunction
EndProperty

bool Property EnableNudityBroadcast
	bool Function Get()
		return StorageUtil.GetIntValue(none, "oaroused.EnableNudityBroadcast") as bool
	EndFunction

	Function Set(bool val)
		StorageUtil.SetIntValue(none, "oaroused.EnableNudityBroadcast", val as int)
	EndFunction
EndProperty

spell horny 
spell relieved 

float function GetArousal(actor npc)
	float lastCheckTime = GetNPCDataFloat(npc, CheckTimeKey)
	float currTime = utility.GetCurrentGameTime()
	float timePassed = currtime - lastCheckTime
	
	StoreNPCDataFloat(npc, CheckTimeKey, currtime); Save last check time to NPC

	float value
	if (lastCheckTime < 0.0) || ((timePassed) > 3.0) ;never calculated, or very old data
		value = OSANative.RandomFloat(0.0, 75.0)
		
		if (lastCheckTime < 0.0)
			StoreNPCDataFloat(npc, arousalmultkey, OSANative.RandomFloat(0.75, 1.25))
		endif 
	else 

		float currentVal = GetNPCDataFloat(npc, arousalkey)

		float arousalMultiplier = GetNPCDataFloat(npc, arousalmultkey)
		value = currentVal + ((timePassed * 25.0) * arousalMultiplier)
	endif 
	
	return SetArousal(npc, value, false)
EndFunction

float Function SetArousal(actor npc, float value, bool updateAccessTime = true)
	if updateAccessTime
		StoreNPCDataFloat(npc, CheckTimeKey, utility.GetCurrentGameTime())
	endif 

	value = papyrusutil.ClampFloat(value, 0.0, 100.0)
	
	StoreNPCDataFloat(npc, arousalkey, value)

	if npc == playerref
		bar.SetPercent(value / 100.0)

		if modStats
			ApplyArousedEffects(value as int)
		else  
			RemoveAllArousalSpells()
		endif
	endif 

	return value
EndFunction

float Function ModifyArousal(actor npc, float by)
	if by > 0.0 
		by *= GetNPCDataFloat(npc, arousalmultkey)
	endif 

	return SetArousal(npc, GetArousal(npc) + by, false)
EndFunction


Event OnUpdate()
	if ostim.AnimationRunning()

		if odatabase.IsSexAnimation(ostim.GetCurrentAnimationOID())
			modifyarousalmultiple(actors, 1.5 * ostim.SexExcitementMult)

			actor[] nearby = MiscUtil.ScanCellNPCs(actors[0], ScanDistance)
			float closeEnough  = ScanDistance / 8

			int i = 0
			int max = nearby.Length
			while i < max
				if (!actors[0].IsDetectedBy(nearby[i]) && (actors[0].GetDistance(nearby[i]) > closeEnough)) || ostim.IsActorInvolved(nearby[i])
					nearby[i] = none
				endif 

				i += 1
			EndWhile

			modifyarousalmultiple(PapyrusUtil.RemoveActor(nearby, none), 5.0 * ostim.SexExcitementMult)
		endif 

		RegisterForSingleUpdate(15.0)
	endif 
EndEvent

Event OnUpdateGameTime()
	GetArousal(playerref)

	RegisterForSingleUpdateGameTime(6)	
EndEvent

Function ModifyArousalMultiple(actor[] acts, float amount)
	{increase arousal by the amount}
	int i = 0 
	int max = acts.Length
	while i < max 
		ModifyArousal(acts[i], (amount))
		;Console(acts[i].getdisplayname())

		i += 1
	EndWhile
endfunction

actor[] actors

Event OStimOrgasm(String EventName, String Args, Float Nothing, Form Sender)
	actor orgasmer = ostim.GetMostRecentOrgasmedActor()

	float reduceBy = (ostim.GetTimeSinceStart() / 120) * ostim.SexExcitementMult
		reduceBy = papyrusutil.ClampFloat(reduceBy, 0.75, 1.5)
		reduceBy = reduceBy * 55.0
		reduceBy = reduceBy + OSANative.RandomFloat(-5.0, 5.0)
		reduceBy = -reduceBy 

	ModifyArousal(orgasmer, reduceBy)

	CalculateStimMultipliers()

	if orgasmer == playerref
		if GetArousal(playerref) < 15
			if bEndOnDomOrgasm
				ostim.EndOnDomOrgasm = true 
			endif 
			if bEndOnSubOrgasm
				ostim.EndOnSubOrgasm = true
			endif 
		endif 

		TempDisplayBar()
	endif 
EndEvent

bool bEndOnDomOrgasm
bool bEndOnSubOrgasm
Event OStimStart(String EventName, String Args, Float Nothing, Form Sender)
	actors = ostim.GetActors()

	previousModifiers = PapyrusUtil.FloatArray(3)
	CalculateStimMultipliers()

	modifyarousalmultiple(actors, 5.0 * ostim.SexExcitementMult)

	if emptyArousalBeforeEnd && ostim.IsPlayerInvolved() && !ostim.HasSceneMetadata("SpecialEndConditions") && !(ostim.isvictim(playerref))
		if playerref == ostim.GetDomActor()
			bEndOnDomOrgasm = ostim.EndOnDomOrgasm
			ostim.EndOnDomOrgasm = false 
		elseif playerref == ostim.GetSubActor()
			bEndOnSubOrgasm = ostim.EndOnSubOrgasm
			ostim.EndOnSubOrgasm = false 
		endif 
	endif 

	RegisterForSingleUpdate(1.0)
endevent

Event OStimEnd(String EventName, String Args, Float Nothing, Form Sender)

	; increase arousal for actors that did not orgasm
	int i = 0 
	int max = actors.Length
	while i < max 
		if ostim.GetTimesOrgasm(actors[i]) < 1
			ModifyArousal(actors[i], 20.0)
		endif 

		i += 1
	endwhile

	if bEndOnDomOrgasm
		bEndOnDomOrgasm = false 
		ostim.EndOnDomOrgasm = true 
	endif 
	if bEndOnSubOrgasm
		bEndOnSubOrgasm = false 
		ostim.EndOnSubOrgasm = true 
	endif 
endevent

float[] previousModifiers
Function CalculateStimMultipliers()

	int i = 0
	int max = actors.Length
	while i < max 
		float arousal = GetArousal(actors[i])

		float modifyBy

		if arousal >= 95
			modifyBy = 1.25
		elseif arousal <= 5
			modifyBy = -0.35
		elseif arousal <= 40 
			modifyBy = 0.0
		else 
			arousal -= 40.0
			modifyBy = (arousal/100.0)
		endif 



		ostim.ModifyStimMult(actors[i], modifyBy - previousModifiers[i])
		;console("Modding stim mult for: " + actors[i] + ": " + (modifyBy - previousModifiers[i]))
		previousModifiers[i] = modifyBy



		i += 1
	endwhile

EndFunction

function TempDisplayBar()
	RegisterForSingleUpdateGameTime(6)	


	float amount = GetArousal(playerref)
	console("Current arousal for player: " + amount)
	bar.SetBarVisible( true)
	Utility.wait(10)
	bar.SetBarVisible(false)
Endfunction

Function InitBar(Osexbar theBar)
	theBar.HAnchor = "left"
	theBar.VAnchor = "bottom"
	theBar.X = 980.0
	theBar.Alpha = 0.0
	theBar.SetPercent(0.0)
	theBar.FillDirection = "Left"

	
	theBar.Y = 160.0

	theBar.SetColors(0xdc143c, 0xF6C4CE)


	bar.SetBarVisible(False)
EndFunction



Event OnKeyDown(int keyCode)
	if OUtils.MenuOpen()
		return 
	endif
	if keyCode == CheckKey
		TempDisplayBar()
	endif 	
EndEvent

Event OnInit()
	InstallAddon("OAroused")

	odatabase = ostim.GetODatabase()

	CheckTimeKey = "ArouLastTime"
	arousalkey = "oarou"
	arousalmultkey = "oaroumul"

	bar = ((self as quest) as OSexBar)

	InitBar(bar)

	RegisterForSingleUpdateGameTime(1)	


	horny = game.GetFormFromFile(0x805, "oaroused.esp") as spell
	relieved = game.GetFormFromFile(0x806, "oaroused.esp") as spell

	CheckKey = 157 
	emptyArousalBeforeEnd = true
	modStats = true 
	EnableNudityBroadcast = false

	EroticArmor = Keyword.GetKeyword("EroticArmor")

	if GetNPCDataFloat(playerref, CheckTimeKey) < 0.0
		Console("Initializing player arousal stats")

		GetArousal(playerref)

		StoreNPCDataFloat(playerref, arousalmultkey, 1.0)
	endif 

	
	OnGameLoad()

EndEvent

Function ApplyArousedEffects(int arousal)
	if arousal >= 40
		arousal -= 40
		float percent = arousal / 60.0
		ApplyHornySpell((percent * 25) as int)
	elseif arousal <= 10
		ApplyReliefSpell(10)
	else 
		RemoveAllArousalSpells()
	endif 
	
EndFunction

Function ApplyHornySpell(int magnitude)
	horny.SetNthEffectMagnitude(0, magnitude)
	horny.SetNthEffectMagnitude(1, magnitude)

	playerref.RemoveSpell(relieved)
	playerref.RemoveSpell(horny)
	playerref.AddSpell(horny, false)
EndFunction

Function ApplyReliefSpell(int magnitude)
	relieved.SetNthEffectMagnitude(0, magnitude)
	relieved.SetNthEffectMagnitude(1, magnitude)

	playerref.RemoveSpell(horny)
	playerref.RemoveSpell(relieved)
	playerref.AddSpell(relieved, false)
EndFunction

Function RemoveAllArousalSpells()
	playerref.RemoveSpell(horny)
	playerref.RemoveSpell(relieved)
EndFunction


Event OnGameLoad()
	RegisterForModEvent("ostim_orgasm", "OStimOrgasm")
	RegisterForModEvent("ostim_start", "OStimStart")
	RegisterForModEvent("ostim_end", "OStimEnd")
	RegisterForKey(CheckKey)

	GetArousal(playerref)
EndEvent