ScriptName OArousedPlayerAliasScript Extends ReferenceAlias


OArousedScript oaroused
actor playerref
OSexIntegrationMain ostim

bool nakedMode
Event OnInit()
	oaroused = OArousedScript.GetOAroused()

	playerref = game.GetPlayer()

	ostim = OUtils.GetOStim()

	nakedMode = false
EndEvent

Function ProcessEquip()
	if !oaroused.EnableNudityBroadcast
		nakedMode = false
		return 
	endif 

	if IsNaked(playerref) && !(ostim.AnimationRunning() && ostim.IsPlayerInvolved())
		nakedMode = true 
		RegisterForSingleUpdate(5.0)
		;OUtils.Console("Player is naked")
	else 
		nakedmode = false 
	endif 

EndFunction


Event OnUpdate()
	if !nakedMode
		return 
	endif 



	IncreaseNearbyArousalBy(20.0)



	RegisterForSingleUpdate(120.0)
EndEvent

Function IncreaseNearbyArousalBy(float amount)
	actor[] nearby = MiscUtil.ScanCellNPCs(playerref, oaroused.ScanDistance) 
	nearby = PapyrusUtil.RemoveActor(nearby, playerref)


	float forceDetectDist = oaroused.ScanDistance / 8

	int i = 0
	int max = nearby.Length
	while i < max 
		if playerref.IsDetectedBy(nearby[i]) || (playerref.GetDistance(nearby[i]) < forceDetectDist)
			;OUtils.Console("Increasing: " + nearby[i].GetDisplayName())

			oaroused.ModifyArousal(nearby[i], amount)
		endif 

		i += 1
	endwhile
EndFunction

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
	ProcessEquip()
EndEvent
Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
	ProcessEquip()
EndEvent

Bool Function IsNaked(Actor NPC) 
	form chest = NPC.GetWornForm(0x00000004)
	Return (!chest as Bool) || (chest.HasKeyword(oaroused.EroticArmor))
EndFunction