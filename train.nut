// ====================================================== 
// ====================================================== 
// 			  TTTTT RRRR     A    I  N   N
// 			    T   R   R   A A   I  NN  N
// 			    T   R  R   A   A  I  N N N
//  		    T   RRRR   AAAAA  I  N  NN
//  		    T   R   R  A   A  I  N   N
// ===========================================ChooChoo!== 
// ====================================================== 

function CivilAI::ChooChoo() {

if (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_RAIL)) {
AILog.Info("I'm not allowed to build trains, boo.");
return; // no trains for us
}


AILog.Info("I'm thinking about freight trains...");
// =================================================================
// review existing trains
// =================================================================


local trainlist = AIVehicleList();
foreach (v, z in trainlist) {
if (AIVehicle.GetVehicleType(v) != AIVehicle.VT_RAIL) {
trainlist.RemoveItem(v);
}
}

// trains getting old
foreach (v, z in trainlist) {
		if ((AIVehicle.GetAgeLeft(v) < (365 * 2)) && !(AIOrder.IsGotoDepotOrder(v, 0)) && AIVehicle.IsValidVehicle(v)) {
			AILog.Info(AIVehicle.GetName(v) + " is getting old")
			ReplaceATrain(v);
		}
}

// trains losing money
foreach (v, z in trainlist) {

local dest = (AIOrder.GetOrderDestination(v, 0));

if  ((AIVehicle.GetProfitLastYear(v) < 0) &&
	(AIVehicle.GetProfitThisYear(v) < 0) &&
	!(AIOrder.IsGotoDepotOrder(v, 0)) &&
	(AIVehicle.GetAge(v) > (365)) &&
	(AIVehicle.GetAgeLeft(v) > (365 * 1)))
	{
		AIOrder.InsertOrder(v,0,dest,(AIOrder.OF_NON_STOP_INTERMEDIATE + AIOrder.OF_GOTO_NEAREST_DEPOT + AIOrder.OF_STOP_IN_DEPOT));
		AIOrder.SkipToOrder(v,0);
		AILog.Info(AIVehicle.GetName(v) + " is losing money, so I'm sending it to the depot.")	
	}
}

// =================================================================
// BUILD NEW TRAINS :D
// =================================================================

CargoLine();

}

// ==========================================
// Replace a train
// ==========================================
// ------------------------------------------
 function CivilAI::ReplaceATrain(v) {

// replace the train before sending it to the depot
local dosh = AICompany.GetBankBalance(Me);
local dest = AIStation.GetStationID(AIOrder.GetOrderDestination(v, 1));
local src = AIStation.GetStationID(AIOrder.GetOrderDestination(v, 0));
local cargo = 0;
local clist = AICargoList();
foreach (c, z in clist) {
if (AIVehicle.GetCapacity(v, c) > 0) {
cargo = c;
}
}

local depot;
local oldHP = AIEngine.GetPower(AIVehicle.GetEngineType(v));

if (oldHP == -1) {return null;} // loose wagons!

//AILog.Info(AIVehicle.GetName(v) + " has " + oldHP + "hp.")

depot = FindTrainDepot(dest);

	if (dosh > BuyATrain(dest, src, cargo, depot, GetStatLength(src), true, oldHP) && AIRail.IsRailDepotTile(depot)) {
		local newtrain = BuyATrain(dest, src, cargo, depot, GetStatLength(src), false, oldHP);

			if (newtrain != null) {
				AIOrder.InsertOrder(v,0,depot,(AIOrder.OF_NON_STOP_INTERMEDIATE + AIOrder.OF_GOTO_NEAREST_DEPOT + AIOrder.OF_STOP_IN_DEPOT));
				AIOrder.SkipToOrder(v,0);
				AILog.Info("I replaced " + AIVehicle.GetName(v) + "."); return true;
			} else {
			AILog.Info("I can't afford to replace " + AIVehicle.GetName(v) + " (or something went wrong)."); return null;
			}
	} else {
AILog.Info("I can't afford to replace " + AIVehicle.GetName(v) + " (or something went wrong)."); return null;
}
}


