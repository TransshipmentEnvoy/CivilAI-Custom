// ====================================================== 
//                  BUY VEHICLES FOR ROUTE
// ====================================================== 

function CivilAI::CreateRoute(vehicle,count,stops,depot,routename,fullload,cargo,group,roadupgrade) {

local obus
local clonebus
local stop
local nx
local name
local changename = false
local cload = true;


obus = (AIVehicle.BuildVehicle(depot,vehicle)); 
if (AIVehicle.IsValidVehicle(obus)) {
foreach (stop in stops) {
if (fullload) {
if (cload) {
AIOrder.AppendOrder(obus, AIBaseStation.GetLocation(stop),(AIOrder.OF_NON_STOP_INTERMEDIATE + AIOrder.OF_FULL_LOAD_ANY))
cload = false; // only full load at first station
} else {
AIOrder.AppendOrder(obus, AIBaseStation.GetLocation(stop),(AIOrder.OF_NON_STOP_INTERMEDIATE + AIOrder.OF_NO_LOAD))
}
} else {
AIOrder.AppendOrder(obus, AIBaseStation.GetLocation(stop),(AIOrder.OF_NON_STOP_INTERMEDIATE))
}
}
nx = 0
name = null
changename = false
while (!changename && (nx < 1000)) {
nx++ 
name = (routename + " " + nx)
changename = AIVehicle.SetName(obus,name)
}
AILog.Info("I've bought a vehicle for " + routename + ".")
AIGroup.MoveVehicle(Groups[group], obus); // add to appropriate group
AIVehicle.RefitVehicle(obus, cargo); // refit to correct cargo
AIVehicle.StartStopVehicle(obus);

if (roadupgrade) {
BuildARoad([AIBaseStation.GetLocation(stops[0])],[AIBaseStation.GetLocation(stops[1])],-1,200);
}

} else {
AILog.Info("For some reason (probably not enough money), I couldn't buy a vehicle for " + routename + ".")
}

for (local c = 1; c < count; c++) {
if (AIVehicle.IsValidVehicle(obus)) { // extra if check - don't try cloning if we failed the first time, produces buses with no orders.
clonebus = AIVehicle.BuildVehicle(depot,vehicle)
if (AIVehicle.IsValidVehicle(clonebus)) {
AIOrder.ShareOrders(clonebus,obus);

nx = 0
name = null
changename = false
while (!changename && (nx < 1000)) {
nx++ 
name = (routename + " " + nx)
changename = AIVehicle.SetName(clonebus,name)
}
AIOrder.SkipToOrder(clonebus,AIBase.RandRange(AIOrder.GetOrderCount(clonebus)));
AILog.Info("I've bought another vehicle for " + routename + ".")
AIGroup.MoveVehicle(Groups[group], clonebus); // add to appropriate group
AIVehicle.RefitVehicle(clonebus, cargo); // refit to correct cargo
AIVehicle.StartStopVehicle(clonebus);
}
} else {
AILog.Info("For some reason (probably not enough money), I couldn't buy a vehicle for " + routename + ".")

}
}

return;
}



//<
// ====================================================== 
// ====================================================== 
// 			  TTTTT RRRR   U   U    CCC   K   K
// 			    T   R   R  U   U   C   C  K  K
// 			    T   R  R   U   U  C       KK
//  		    T   RRRR   U   U   C   C  K  K
//  		    T   R   R   UUU     CCC   K   K
// ====================================================== 
// ====================================================== 
//>
// ====================================================== 
//                   DELIVER LOCAL GOODS
// ====================================================== 

function CivilAI::TruckOps() {

// depot old trucks

local trucklist = AIVehicleList_Group(Groups[2]);
local trucklis2 = AIVehicleList_Group(Groups[3]);
trucklist.AddList(trucklis2);

for (local v = trucklist.Begin(); !(trucklist.IsEnd()); v = trucklist.Next()) {
if  ((AIVehicle.GetAgeLeft(v) < (365 * 1)) && !(AIVehicle.IsStoppedInDepot(v)) && AIVehicle.IsValidVehicle(v)) {
AIVehicle.SendVehicleToDepot(v);
AILog.Info(AIVehicle.GetName(v) + " is getting old, so I'm sending it to the depot.")
}
}

// new mail stops (rewritten in 1.9 with dock code):

local rv = IdentifyBus(true, false, FindCargo("MAIL"));
if (rv != null) {
 

 // Find a mailcenter to build - max 2 per town
 AILog.Info("Looking for city truck stops to build.");
 
local townlist = AIList();
townlist.AddList(Cachedtowns);
townlist.AddList(Exclaves);
townlist.Valuate(AIBase.RandItem); // shuffle the list
 
foreach (town, z in townlist) {

local bslist = AIStationList(AIStation.STATION_BUS_STOP); 
bslist.Valuate(AIStation.GetNearestTown);
bslist.KeepValue(town);
local dcount = 0;

foreach (bs, z in bslist) {
local vlist = AIVehicleList_Station(bs);
if (AIStation.HasStationType(bs,AIStation.STATION_TRUCK_STOP) ||
	vlist.Count() == 0) { // only include serviced stops
bslist.RemoveItem(bs);
dcount++; // count stops - max 2 per town?
}
}

if (bslist.Count() == 0 || dcount > 1) {

} else {
bslist.Valuate(AIBase.RandItem); // shuffle the list
foreach (bs, z in bslist) {
if (BuildTruckStop(bs,AIBaseStation.GetLocation(bs))) {
AILog.Info("I built a new truck stop at " + AIBaseStation.GetName(bs) + ".");
if (AICargoList_StationAccepting(bs).HasItem(FindCargo("MAIL"))) { NewMailGo(bs); }
break;
}
}
}
} 
 

// build some new trucks for existing routes:
AILog.Info("I'm reviewing my mail services.");


local tslist = AIStationList(AIStation.STATION_TRUCK_STOP); 
tslist.Valuate(AIStation.GetCargoWaiting, FindCargo("MAIL")); //order by mail waiting
tslist.RemoveBelowValue(200);				
foreach (station, z in tslist) {

local vlist = AIVehicleList_Station(station);
foreach (veh,z in vlist) {
if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_ROAD) {
vlist.RemoveItem(veh);
}
}
if ((vlist.Count() < 30) && AICargoList_StationAccepting(station).HasItem(FindCargo("MAIL")))
{
NewMailGo(station);
}
}

// speculative unserviced stops

local tslist = AIStationList(AIStation.STATION_TRUCK_STOP); 
tslist.Valuate(AIStation.GetCargoWaiting, FindCargo("PASS")); //order by pass waiting
tslist.RemoveBelowValue(100);	
			
foreach (station, z in tslist) {
	local vlist = AIVehicleList_Station(station);
		foreach (veh,z in vlist) {
		if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_ROAD) {
		vlist.RemoveItem(veh);
		}
	local tlist = AIVehicleList_Group(Groups[0]);
		vlist.RemoveList(tlist);
	tlist = AIVehicleList_Group(Groups[3]);
		vlist.RemoveList(tlist);
		}	
	if (vlist.Count() == 0 && AICargoList_StationAccepting(station).HasItem(FindCargo("MAIL"))) {					// there are no mail trucks servicing a high-pax-volume truck stop, so speculatively build one.
	NewMailGo(station);
	} 
}



AILog.Info("I'm reviewing my cargo services.");

local c = FindCargo("GOOD");
if (c != null) {
local tslist = AIStationList(AIStation.STATION_TRUCK_STOP); 
tslist.Valuate(AIStation.GetCargoWaiting, c); //order by cargo waiting
tslist.RemoveBelowValue(300);				
foreach (station, z in tslist) {
NewCargoGo(station, c);
}
}

local c = FindCargo("FOOD");
if (c != null) {
local tslist = AIStationList(AIStation.STATION_TRUCK_STOP); 
tslist.Valuate(AIStation.GetCargoWaiting, c); //order by cargo waiting
tslist.RemoveBelowValue(300);				
foreach (station, z in tslist) {
NewCargoGo(station, c);
}
}

local c = FindCargo("WATR");
if (c != null) {
local tslist = AIStationList(AIStation.STATION_TRUCK_STOP); 
tslist.Valuate(AIStation.GetCargoWaiting, c); //order by cargo waiting
tslist.RemoveBelowValue(300);				
foreach (station, z in tslist) {
NewCargoGo(station, c);
}
}


CheckSupplyDepots(); // remove supply depot stops that are unused (ie have no vehicles assigned and cannot supply food, goods or water)

return;

}
}

// ====================================================== 
//                   SPIRAL TRUCK STOP
// ====================================================== 
function CivilAI::BuildTruckStop(station,location) {

// clockwise spiral out
local town = AIStation.GetNearestTown(station);
local trytilegrid = [AIMap.GetTileX(location),AIMap.GetTileY(location)]
// AILog.Info(trytilegrid[0] + ", " + trytilegrid[1]); 
local trytile;
local aimx; // aimtile
local aimy; // aimtile
local aimxm; // an additional aimtile, for bridge approach tests (we don't build on bridge approaches, because they send us on journeys)
local aimym; // an additional aimtile, for bridge approach tests (we don't build on bridge approaches, because they send us on journeys)
local testroad = RoadPF();
testroad.cost.no_existing_road = testroad.cost.max_cost;
local x = 0
local y = 0
local i = 0
local stat = station
local statcount = 0
local spread = 4 // footprint size
local count = 1 // number of stops to build

while ((i < spread) && (statcount < count)) {
//y--
for (;y >= 0-i;y--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
aimx  = AIMap.GetTileIndex(trytilegrid[0]+x+1,trytilegrid[1]+y);
aimy  = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y+1);
aimxm  = AIMap.GetTileIndex(trytilegrid[0]+x-1,trytilegrid[1]+y);
aimym  = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y-1);

//AISign.BuildSign(trytile, "?");

testroad.InitializePath([trytile], [AITown.GetLocation(town)]);
local path = false;
while (path == false) {
path = testroad.FindPath(20);
AIController.Sleep(1);
}

if ((path != null) && (statcount < count) && (AIRoad.IsRoadTile(trytile))) {
	if (!AIBridge.IsBridgeTile(aimx) && !AIBridge.IsBridgeTile(aimxm) && 
	(AITile.GetSlope(aimx) == AITile.SLOPE_FLAT) &&
	(AITile.GetSlope(aimxm) == AITile.SLOPE_FLAT) &&
	AIRoad.BuildDriveThroughRoadStation(trytile,aimx,AIRoad.ROADVEHTYPE_TRUCK,stat)) {
	stat = AIStation.GetStationID(trytile), statcount = statcount+1
		}
	else if (!AIBridge.IsBridgeTile(aimy) && !AIBridge.IsBridgeTile(aimym) && 
	(AITile.GetSlope(aimy) == AITile.SLOPE_FLAT) &&
	(AITile.GetSlope(aimym) == AITile.SLOPE_FLAT) &&
	AIRoad.BuildDriveThroughRoadStation(trytile,aimy,AIRoad.ROADVEHTYPE_TRUCK,stat)) {
	stat = AIStation.GetStationID(trytile), statcount = statcount+1
		}

}
}

//x--;
for (;x >= 0-i;x--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
aimx  = AIMap.GetTileIndex(trytilegrid[0]+x+1,trytilegrid[1]+y);
aimy  = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y+1);
aimxm  = AIMap.GetTileIndex(trytilegrid[0]+x-1,trytilegrid[1]+y);
aimym  = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y-1);

//AISign.BuildSign(trytile, "?");

testroad.InitializePath([trytile], [AITown.GetLocation(town)]);
local path = false;
while (path == false) {
path = testroad.FindPath(20);
AIController.Sleep(1);
}
if ((path != null) && (statcount < count) && (AIRoad.IsRoadTile(trytile))) {
	if (!AIBridge.IsBridgeTile(aimx) && !AIBridge.IsBridgeTile(aimxm) && 
	(AITile.GetSlope(aimx) == AITile.SLOPE_FLAT) &&
	(AITile.GetSlope(aimxm) == AITile.SLOPE_FLAT) &&
	AIRoad.BuildDriveThroughRoadStation(trytile,aimx,AIRoad.ROADVEHTYPE_TRUCK,stat)) {
	stat = AIStation.GetStationID(trytile), statcount = statcount+1
		}
	else if (!AIBridge.IsBridgeTile(aimy) && !AIBridge.IsBridgeTile(aimym) && 
	(AITile.GetSlope(aimy) == AITile.SLOPE_FLAT) &&
	(AITile.GetSlope(aimym) == AITile.SLOPE_FLAT) &&
	AIRoad.BuildDriveThroughRoadStation(trytile,aimy,AIRoad.ROADVEHTYPE_TRUCK,stat)) {
	stat = AIStation.GetStationID(trytile), statcount = statcount+1
		}
}
}

//y++;
for (;y <= i;y++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
aimx  = AIMap.GetTileIndex(trytilegrid[0]+x+1,trytilegrid[1]+y);
aimy  = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y+1);
aimxm  = AIMap.GetTileIndex(trytilegrid[0]+x-1,trytilegrid[1]+y);
aimym  = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y-1);

//AISign.BuildSign(trytile, "?");

testroad.InitializePath([trytile], [AITown.GetLocation(town)]);
local path = false;
while (path == false) {
path = testroad.FindPath(20);
AIController.Sleep(1);
}
if ((path != null) && (statcount < count) && (AIRoad.IsRoadTile(trytile))) {
	if (!AIBridge.IsBridgeTile(aimx) && !AIBridge.IsBridgeTile(aimxm) && 
	(AITile.GetSlope(aimx) == AITile.SLOPE_FLAT) &&
	(AITile.GetSlope(aimxm) == AITile.SLOPE_FLAT) &&
	AIRoad.BuildDriveThroughRoadStation(trytile,aimx,AIRoad.ROADVEHTYPE_TRUCK,stat)) {
	stat = AIStation.GetStationID(trytile), statcount = statcount+1
		}
	else if (!AIBridge.IsBridgeTile(aimy) && !AIBridge.IsBridgeTile(aimym) && 
	(AITile.GetSlope(aimy) == AITile.SLOPE_FLAT) &&
	(AITile.GetSlope(aimym) == AITile.SLOPE_FLAT) &&
	AIRoad.BuildDriveThroughRoadStation(trytile,aimy,AIRoad.ROADVEHTYPE_TRUCK,stat)) {
	stat = AIStation.GetStationID(trytile), statcount = statcount+1
		}
}
}

//x++;
for (;x <= i+1;x++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
aimx  = AIMap.GetTileIndex(trytilegrid[0]+x+1,trytilegrid[1]+y);
aimy  = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y+1);
aimxm  = AIMap.GetTileIndex(trytilegrid[0]+x-1,trytilegrid[1]+y);
aimym  = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y-1);

//AISign.BuildSign(trytile, "?");

testroad.InitializePath([trytile], [AITown.GetLocation(town)]);
local path = false;
while (path == false) {
path = testroad.FindPath(20);
AIController.Sleep(1);
}
if ((path != null) && (statcount < count) && (AIRoad.IsRoadTile(trytile))) {
	if (!AIBridge.IsBridgeTile(aimx) && !AIBridge.IsBridgeTile(aimxm) && 
	(AITile.GetSlope(aimx) == AITile.SLOPE_FLAT) &&
	(AITile.GetSlope(aimxm) == AITile.SLOPE_FLAT) &&
	AIRoad.BuildDriveThroughRoadStation(trytile,aimx,AIRoad.ROADVEHTYPE_TRUCK,stat)) {
	stat = AIStation.GetStationID(trytile), statcount = statcount+1
		}
	else if (!AIBridge.IsBridgeTile(aimy) && !AIBridge.IsBridgeTile(aimym) && 
	(AITile.GetSlope(aimy) == AITile.SLOPE_FLAT) &&
	(AITile.GetSlope(aimym) == AITile.SLOPE_FLAT) &&
	AIRoad.BuildDriveThroughRoadStation(trytile,aimy,AIRoad.ROADVEHTYPE_TRUCK,stat)) {
	stat = AIStation.GetStationID(trytile), statcount = statcount+1
		}
}
}
i=i+1
}
if (statcount > 0) { return stat+1 } else { return false }
}


// ====================================================== 
//                    MAIL SERVICE
// ======================================================  

function CivilAI::NewMailGo(station) {

// pick random depot in the town to build in (1.9, allows functioning with no road network)
local depot = HomeDepot;
local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
dlist.Valuate(AITile.GetClosestTown);
dlist.KeepValue(AIStation.GetNearestTown(station));
depot = dlist.Begin();

local dosh = AICompany.GetBankBalance(Me);
local nbus = IdentifyBus(true, true, FindCargo("MAIL"));

if (nbus == null) {
return;
}
else if (dosh > (AIEngine.GetPrice(nbus) * 2)) {


if (GroupCount(2) < MaxBus) {

local HasBus = IdentifyBus(true, true, FindCargo("MAIL"));
if (HasBus == null) {
return
}
//AILog.Info("Starting a new mail service.");

local bslist = AIStationList(AIStation.STATION_TRUCK_STOP); 

bslist.RemoveItem(station); // remove the first selected stop

bslist.Valuate(AIStation.GetNearestTown);

if (Exclaves.HasItem(AIStation.GetNearestTown(station))) {
bslist.KeepValue(AIStation.GetNearestTown(station)); // only build mail trucks within same town, if no road network
}

foreach (stop, z in bslist) {							
if (!AIStation.HasStationType(stop,AIStation.STATION_BUS_STOP)																	// remove non-city stops
|| (Exclaves.HasItem(AIStation.GetNearestTown(stop)) && (AIStation.GetNearestTown(station) != AIStation.GetNearestTown(stop)))	// remove stops in (other) exclaves
|| (!AICargoList_StationAccepting(stop).HasItem(FindCargo("MAIL")))																		// no mail acceptance
) {
bslist.RemoveItem(stop);
}
}

foreach (stop,z in bslist) {
local vlist = AIVehicleList_Station(stop);
foreach (veh,z in vlist) {
if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_ROAD) {
vlist.RemoveItem(veh);
}
}
if (vlist.Count() > 30) {					// remove saturated stops
//AILog.Info(AIBaseStation.GetName(stop) + " has too many buses already.");
bslist.RemoveItem(stop);
}
}

if (bslist.Count() < 1) {
//AILog.Info("I couldn't find a truck stop to connect.");
return
} else {
bslist.Valuate(AIStation.GetCargoWaiting, FindCargo("MAIL"));
local stat2 = bslist.Begin();
CreateRoute(HasBus,1,[station,stat2],depot,(AITown.GetName(AIStation.GetNearestTown(station))) + " Mail",false,FindCargo("MAIL"),2,true);
}

} else {
AILog.Info("I've already got my maximum number of trucks, so I won't build more.")
}
} else {
AILog.Info("I don't have the money for new trucks at the moment.")
}


return
}

// ====================================================== 
//                    CARGO SERVICE
// ====================================================== 


function CivilAI::NewCargoGo(station, cargo) {

local depot = HomeDepot;
local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
dlist.Valuate(AITile.GetDistanceManhattanToTile, AIBaseStation.GetLocation(station));
dlist.Sort(AIList.SORT_BY_VALUE, true);
depot = dlist.Begin();

local dosh = AICompany.GetBankBalance(Me);
local nbus = IdentifyBus(true, false, cargo);

if (nbus == null) {
return;
}
else if (dosh > (AIEngine.GetPrice(nbus) * 2)) {

if (GroupCount(3) < MaxBus) {

local HasBus = IdentifyBus(true, false, cargo);
if (HasBus == null) {
return
}
//AILog.Info("Adding more goods trucks.");

local cdlist = AIStationList_CargoWaitingByVia(station, cargo);
foreach (d, z in cdlist) {
//AILog.Info(station + " " + d +  " " + z);

if (d != 65535 && z > 200) { // add another truck
CreateRoute(HasBus,1,[station,d],depot,(AITown.GetName(AIStation.GetNearestTown(d))) + " Goods",true,cargo,3,true);
} else if (d == 65535 && z > 200) { // add another truck to a random route

local vlist = AIVehicleList_Station(station);

vlist.Valuate(AIBase.RandItem); // shuffle the list
local destlist = AIStationList_Vehicle(vlist.Begin());
destlist.RemoveItem(station); // take out this station
local dest = destlist.Begin(); // set next station as destination

if (AICargoList_StationAccepting(dest).HasItem(cargo)) {
CreateRoute(HasBus,1,[station,dest],depot,(AITown.GetName(AIStation.GetNearestTown(dest))) + " Goods",true,cargo,3,true);
}
}



}
} else {
AILog.Info("I've already got my maximum number of trucks, so I won't build more.")
}
} else {
AILog.Info("I don't have the money for new trucks at the moment.")
}


return
}




 
//=======================================================
// Cargo route planning
//=======================================================


function CivilAI::CargoPlan() {

AILog.Info("I'm coming up with a cargo plan...");

local food = FindCargo("FOOD");
if (food != null) {
MakeAPlan(food);
} else {
//AILog.Info("There is no food in this game.");
}

local watr = FindCargo("WATR");
if (watr != null) {
MakeAPlan(watr);
} else {
//AILog.Info("There is no water in this game.");
}


local good = FindCargo("GOOD");
if (good != null) {
MakeAPlan(good);
} else {
//AILog.Info("There are no goods in this game (which is odd...)");
}

}

function CivilAI::MakeAPlan(cargo) {

//=== First, find the destination

local tslist = AIStationList(AIStation.STATION_TRUCK_STOP); 
tslist.RemoveList(DontGoodsTruck);

foreach (stop, z in tslist) {
local tlist = AIVehicleList_Group(Groups[3]);
tlist.KeepList(AIVehicleList_Station(stop));

if (AICargoList_StationAccepting(stop).HasItem(cargo)
&& tlist.Count() == 0
// && (AITown.GetLastMonthReceived(AIStation.GetNearestTown(stop), AICargo.GetTownEffect(cargo)) == 0)
&& AIStation.HasStationType(stop,AIStation.STATION_BUS_STOP)) { // only consider stations with bus stops, ie not supply depots
	//this is a valid destination
} else {
tslist.RemoveItem(stop);
}
}
if (tslist.Count() > 0) {
tslist.Valuate(AIBase.RandItem); // shuffle the list
PlanDestination = tslist.Begin();
AILog.Info("Planning a cargo run to " + AIBaseStation.GetName(PlanDestination) + ".");

//=== Then, find the supplier

//=== do we happen to have a nearby existing supply?

local tslist = AIStationList(AIStation.STATION_TRUCK_STOP); 
foreach (stop, z in tslist) {
if ((AIStation.GetCargoWaiting(stop, cargo) > 64) 
&& (ScoreRoute(AIBaseStation.GetLocation(stop),AIBaseStation.GetLocation(PlanDestination)) < TrainRange)
&& (stop != PlanDestination)) // don't try and deliver to ourselves
{


AILog.Info("Existing supply depot found at " + AIBaseStation.GetName(stop) + ".");

local depot = HomeDepot;
local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
dlist.Valuate(AITile.GetDistanceManhattanToTile, AIBaseStation.GetLocation(stop));
dlist.Sort(AIList.SORT_BY_VALUE, true);
depot = dlist.Begin();


// build service

			local a = [AIBaseStation.GetLocation(stop)]
			local b	= [AIBaseStation.GetLocation(PlanDestination)]				
			if(!BuildARoad(a,b,-1,200)) { AILog.Info("I couldn't connect the supply."); DontGoodsTruck.AddItem(PlanDestination, 0); return;}

local HasBus = IdentifyBus(false, false, cargo);
if (HasBus == null) { return; } else {
CreateRoute(HasBus,2,[stop,PlanDestination],depot,(AITown.GetName(AIStation.GetNearestTown(PlanDestination))) + " Goods",true,cargo,3, true);
}

return;
}
}

AILog.Info("No existing supply depot found.");
//=== if not, is there an undertransported industry nearby?

local ilist = AIIndustryList();

foreach (i, z in ilist) {
	local prod = false;
	local clist = AIList();
	clist = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(i));
	if (clist != null) {
		if (clist.Count() > 0) {
			foreach (c, z in clist) {
				if (c == cargo) {
					prod = true;
					//AILog.Info(AIIndustry.GetName(i) + " looks promising...");
							}
						}
					}
				}
				
	if ((prod == false) ||
		(AIIndustry.IsBuiltOnWater(i)) ||
		(AIIndustry.GetLastMonthProduction(i, cargo) - AIIndustry.GetLastMonthTransported(i, cargo) < 64) ||
		(ScoreRoute((AIIndustry.GetLocation(i)),AIBaseStation.GetLocation(PlanDestination)) > TrainRange))
		
			{
				ilist.RemoveItem(i);
			}
}

if (ilist.Count() > 0) {
ilist.Valuate(AIBase.RandItem); // shuffle the list
PlanSource = ilist.Begin();
AILog.Info("Suitable supplier found at " + AIIndustry.GetName(PlanSource) + ".");

// do we already have a supply depot at this industry?

local search = AITileList_IndustryProducing(PlanSource, 3);
foreach (tile, z in search) {
//AISign.BuildSign(tile, ".");

if (AITile.IsStationTile(tile)) {
local station = AIStation.GetStationID(tile);

if (AIStation.IsValidStation(station)
&&  AIStation.HasStationType(station,AIStation.STATION_TRUCK_STOP)
&& !(AIStation.HasStationType(station,AIStation.STATION_BUS_STOP))
) {
// this is a valid supply depot
local stop = station;
AILog.Info("Existing supply depot found at " + AIBaseStation.GetName(stop) + ".");

// build service

			local a = [AIBaseStation.GetLocation(stop)]
			local b	= [AIBaseStation.GetLocation(PlanDestination)]				
			if(!BuildARoad(a,b,-1,200)) { AILog.Info("I couldn't connect the supply."); return;}

local HasBus = IdentifyBus(false, false, cargo);
if (HasBus == null) { return; } else {

local depot = HomeDepot;
local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
dlist.Valuate(AITile.GetDistanceManhattanToTile, AIBaseStation.GetLocation(stop));
dlist.Sort(AIList.SORT_BY_VALUE, true);
depot = dlist.Begin();

CreateRoute(HasBus,2,[stop,PlanDestination],depot,(AITown.GetName(AIStation.GetNearestTown(PlanDestination))) + " Goods",true,cargo,3, true);
}

return;
}
}
}


// build supply depot and service
local stop;
if (stop = SupplyDepot(PlanSource, cargo)) {		

			local a = [AIBaseStation.GetLocation(stop)]
			local b	= [AIBaseStation.GetLocation(PlanDestination)]				
			if(!BuildARoad(a,b,-1,200)) { AILog.Info("I couldn't connect the supply."); return;}

local HasBus = IdentifyBus(false, false, cargo);
if (HasBus == null) { return; } else {

local depot = HomeDepot;
local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
dlist.Valuate(AITile.GetDistanceManhattanToTile, AIBaseStation.GetLocation(stop));
dlist.Sort(AIList.SORT_BY_VALUE, true);
depot = dlist.Begin();

CreateRoute(HasBus,2,[stop,PlanDestination],depot,(AITown.GetName(AIStation.GetNearestTown(PlanDestination))) + " Goods",true,cargo,3, true);
}
}
return;
}
AILog.Info("I couldn't find a suitable supply.");

} else {
AILog.Info("I couldn't find a suitable destination.");
return;
}
}

//===============
// Build a supply depot
//===============

function CivilAI::SupplyDepot(ind, cargo) {

local rv = IdentifyBus(true, false, cargo);

local dosh = AICompany.GetBankBalance(Me);
if ((dosh) < (AIRoad.GetBuildCost(AIRoad.GetCurrentRoadType(), AIRoad.BT_ROAD) * 50) + (AIEngine.GetPrice(rv) * 2)) {
AILog.Info("I can't afford to build a supply depot right now. Perhaps later.")
return null;
}

// new in v31 - check for existing depot that has been removed and we can reuse

local depotlist = AIDepotList(AITile.TRANSPORT_ROAD);
depotlist.KeepList(AITileList_IndustryProducing(ind, 3));

foreach (depot, z in depotlist) {
			AILog.Info("Found an existing Depot, trying to rebuild...")
					local tg = [AIMap.GetTileX(depot), AIMap.GetTileY(depot)]
					local tx1 = (AIMap.GetTileIndex(tg[0]-1,tg[1]+0));
					local tx2 = (AIMap.GetTileIndex(tg[0]+1,tg[1]+0));
					local ty1 = (AIMap.GetTileIndex(tg[0]+0,tg[1]-1));
					local ty2 = (AIMap.GetTileIndex(tg[0]+0,tg[1]+1));
										if (AIRoad.GetRoadDepotFrontTile(depot) == tx2) {
													local stat = AIStation.STATION_NEW
													AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(tg[0]+0,tg[1]-1),AIMap.GetTileIndex(tg[0]+1,tg[1]-1),AIRoad.ROADVEHTYPE_TRUCK,stat);
													stat = AIStation.GetStationID(AIMap.GetTileIndex(tg[0]+0,tg[1]-1));
													if (AIStation.IsValidStation(stat)) { 
														AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(tg[0]+0,tg[1]+1),AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIRoad.ROADVEHTYPE_TRUCK,stat);	
														return stat;
														}
													}
										else if (AIRoad.GetRoadDepotFrontTile(depot) == ty2) {
													local stat = AIStation.STATION_NEW
													AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(tg[0]-1,tg[1]+0),AIMap.GetTileIndex(tg[0]-1,tg[1]+1),AIRoad.ROADVEHTYPE_TRUCK,stat);
													stat = AIStation.GetStationID(AIMap.GetTileIndex(tg[0]-1,tg[1]+0));
													if (AIStation.IsValidStation(stat)) { 
														AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(tg[0]+1,tg[1]+0),AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIRoad.ROADVEHTYPE_TRUCK,stat);
														return stat;
														}
													}													
								}
// --						
	

// clockwise spiral out
local trytilegrid = [AIMap.GetTileX(AIIndustry.GetLocation(ind)) + 1,AIMap.GetTileY(AIIndustry.GetLocation(ind)) + 1] // we're making assumptions about industry size here
local trytile;
local x = 0
local y = 0
local i = 0
local s = 4
local NewStat = null;


while ((i < s) && NewStat == null) {
//y--
for (;y >= 0-i;y--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsBuildableRectangle(trytile, 3, 3)) {
if (NewStat = BuildSupplyDepot(trytile,AIIndustry.GetLocation(ind))) {
return NewStat;
}
}
} 
//x--;
for (;x >= 0-i;x--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsBuildableRectangle(trytile, 3, 3)) {
if (NewStat = BuildSupplyDepot(trytile,AIIndustry.GetLocation(ind))) {
return NewStat;
}
}
} 
//y++;
for (;y <= i;y++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsBuildableRectangle(trytile, 3, 3)) {
if (NewStat = BuildSupplyDepot(trytile,AIIndustry.GetLocation(ind))) {
return NewStat;
}
}
} 
//x++;
for (;x <= i;x++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsBuildableRectangle(trytile, 3, 3)) {
if (NewStat = BuildSupplyDepot(trytile,AIIndustry.GetLocation(ind))) {
return NewStat;
}
}
} 
i=i+1
}

return NewStat;

}

function CivilAI::BuildSupplyDepot(tile,indloc) {

// check town approval before levelling mountains!
//AILog.Info(AITown.GetRating(AITile.GetClosestTown(tile), Me))
if (AITown.GetRating(AITile.GetClosestTown(tile), Me) < 4 && AITown.GetRating(AITile.GetClosestTown(tile), Me) > 0) {
TreePlant(AITile.GetClosestTown(tile));
if (AITown.GetRating(AITile.GetClosestTown(tile), Me) < 4 && AITown.GetRating(AITile.GetClosestTown(tile), Me) > 0) {
return null;
}
}

//AISign.BuildSign(tile, "?");

// check we're actually in range of the industry
local ind = AIIndustry.GetIndustryID(indloc);
if (AIIndustry.IsValidIndustry(ind)) {
local checktile = AIMap.GetTileIndex(AIMap.GetTileX(tile)+ 1,AIMap.GetTileY(tile) + 1);
	if (!AITileList_IndustryProducing(ind,3).HasItem(checktile)) {
//AILog.Info("The site I tried wasn't close enough to the industry.")	
return null;	
	} else {
//AILog.Info("...")	
	}
}



local tg = [AIMap.GetTileX(tile),AIMap.GetTileY(tile)]

// flatten land

if (!NoWater(tile, 3, 3)) {return null;}

AITile.LevelTiles(AIMap.GetTileIndex(tg[0]+1,tg[1]+1), tile);
AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]+3,tg[1]+3));

if ((AITile.GetSlope(AIMap.GetTileIndex(tg[0]+0,tg[1]+0)) != AITile.SLOPE_FLAT) ||
	(AITile.GetSlope(AIMap.GetTileIndex(tg[0]+2,tg[1]+0)) != AITile.SLOPE_FLAT) ||
	(AITile.GetSlope(AIMap.GetTileIndex(tg[0]+0,tg[1]+2)) != AITile.SLOPE_FLAT) ||
	(AITile.GetSlope(AIMap.GetTileIndex(tg[0]+2,tg[1]+2)) != AITile.SLOPE_FLAT) ||
	(AITile.GetSlope(AIMap.GetTileIndex(tg[0]+1,tg[1]+1)) != AITile.SLOPE_FLAT)
)
{return null;}

// cont.

AIRoad.BuildRoad (AIMap.GetTileIndex(tg[0],tg[1]    ),AIMap.GetTileIndex(tg[0],tg[1] +2));
AIRoad.BuildRoad (AIMap.GetTileIndex(tg[0],tg[1]    ),AIMap.GetTileIndex(tg[0] +2,tg[1]));
AIRoad.BuildRoad (AIMap.GetTileIndex(tg[0],tg[1] +2),AIMap.GetTileIndex(tg[0] +2,tg[1] +2));
AIRoad.BuildRoad (AIMap.GetTileIndex(tg[0] +2,tg[1]),AIMap.GetTileIndex(tg[0] +2,tg[1] +2));

local stat = AIStation.STATION_NEW

if (AIBase.RandRange(2) == 1) {

AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(tg[0]+1,tg[1]),AIMap.GetTileIndex(tg[0]+2,tg[1]),AIRoad.ROADVEHTYPE_TRUCK,stat);
stat = AIStation.GetStationID(AIMap.GetTileIndex(tg[0]+1,tg[1]));
AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(tg[0]+1,tg[1]+2),AIMap.GetTileIndex(tg[0]+2,tg[1]+2),AIRoad.ROADVEHTYPE_TRUCK,stat);
AIRoad.BuildRoadDepot(AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIMap.GetTileIndex(tg[0]+2,tg[1]+1));
AIRoad.BuildRoad (AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIMap.GetTileIndex(tg[0]+2,tg[1]+1));

} else {

AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(tg[0],tg[1]+1),AIMap.GetTileIndex(tg[0],tg[1]+2),AIRoad.ROADVEHTYPE_TRUCK,stat);
stat = AIStation.GetStationID(AIMap.GetTileIndex(tg[0],tg[1]+1));
AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(tg[0]+2,tg[1]+1),AIMap.GetTileIndex(tg[0]+2,tg[1]+2),AIRoad.ROADVEHTYPE_TRUCK,stat);
AIRoad.BuildRoadDepot(AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIMap.GetTileIndex(tg[0]+1,tg[1]+2));
AIRoad.BuildRoad (AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIMap.GetTileIndex(tg[0]+1,tg[1]+2));

}

AILog.Info("Built a Supply Depot.")
return stat;
}

//============
// remove supply depot stops that are unused (ie have no vehicles assigned and cannot supply food, goods or water)
//============

function CivilAI::CheckSupplyDepots() {
AILog.Info("Checking for unused supply depots...");

local tslist = AIStationList(AIStation.STATION_TRUCK_STOP);
local tlist = AIList();
local slist = AIList();

local g = FindCargo("GOOD");
local f = FindCargo("FOOD");
local w = FindCargo("WATR");

if (g == null) {g = 0;}
if (f == null) {f = 0;}
if (w == null) {w = 0;}


foreach (ts, z in tslist) {

tlist = AIVehicleList_Station(ts);

	if (
		!AIStation.HasStationType(ts,AIStation.STATION_BUS_STOP) &&
		(tlist.Count() == 0)
		)
	{
	AILog.Info("Removing " + AIBaseStation.GetName(ts) + " as it is unused.");
	
	slist = AITileList_StationType(ts, AIStation.STATION_TRUCK_STOP); 
	foreach (t, z in slist) {
	AIRoad.RemoveRoadStation(t)
	}
	}
}
}


