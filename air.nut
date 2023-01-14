//<
// ====================================================== 
// ====================================================== 
// 			   AAAA  	  II	  RRRRR  
// 			  A    A 	  II	  R   RR 
// 			  AAAAAA 	  II	  RRRRR  
//  		  A    A 	  II	  R   R  
//  		  A    A 	  II	  R    R 
// ====================================================== 
// ====================================================== 
//>
// ====================================================== 
//                   BUILD AIRPORT
// ====================================================== 

function CivilAI::Airportz() {


if (!(AIAirport.IsValidAirportType(AIAirport.AT_SMALL) || 
	 AIAirport.IsValidAirportType(AIAirport.AT_COMMUTER)) ||
	 (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_AIR) == true))
 {
 AILog.Info("No small airports are available, or I'm not allowed to build aircraft.")
 return;
 }
 
local dosh = AICompany.GetBankBalance(Me);
local planecost = 1000000000; 
local apcost = 1000000000;
 
if (AIAirport.IsValidAirportType(AIAirport.AT_COMMUTER)) {apcost = AIAirport.GetPrice(AIAirport.AT_COMMUTER)}
else if (AIAirport.IsValidAirportType(AIAirport.AT_SMALL)) {apcost = AIAirport.GetPrice(AIAirport.AT_SMALL)}	 

local p2b = PickAircraft(0, 0);
if (p2b != null) {planecost = AIEngine.GetPrice(p2b);} else {AILog.Info("No small aircraft are available."); return;}
local wants = ((apcost) + (planecost));

if (dosh < wants)
 {
 AILog.Info("I don't have the money to build an airport right now.")
 return;
 }	 
	 
	 
// 2.0 - check maintenance costs before building an airport

local infra = false;
if (AIGameSettings.IsValid("economy.infrastructure_maintenance")) { infra = AIGameSettings.GetValue("economy.infrastructure_maintenance"); }
if (infra)	
{
local income = ((AICompany.GetQuarterlyIncome(Me, 1) - AICompany.GetQuarterlyExpenses(Me, 1)) / 4); // monthly income
local apex;

if (AIAirport.IsValidAirportType(AIAirport.AT_COMMUTER)) {
apex = AIAirport.GetMonthlyMaintenanceCost(AIAirport.AT_COMMUTER);
} else {
apex = AIAirport.GetMonthlyMaintenanceCost(AIAirport.AT_SMALL);
}

//AILog.Info("income = " + income + " apex = " + apex + ".")

if (income < (apex * 4))
 {
 AILog.Info("I don't have the income to maintain an airport right now.")
 return;
 }	 
}	 
	 
AILog.Info("Looking for an airport site...")	

// make a speculative townlist

// find a town
local townlist = AIList();
townlist.AddList(Cachedtowns);
townlist.AddList(Exclaves);
townlist.Valuate(AITown.GetPopulation);
townlist.RemoveBelowValue(MinPop);

foreach (town,z in townlist) {
if (
((AITown.GetLastMonthSupplied(town, 0) * 10) > AITown.GetPopulation(town)) ||
(((AITown.GetAllowedNoise(town)) < 4) && (AIGameSettings.GetValue("economy.station_noise_level") == true))
) {
townlist.RemoveItem(town);  // discard town
} else {

local aplist = AIStationList(AIStation.STATION_AIRPORT);
foreach (stat,z in aplist) {
if (AIStation.GetNearestTown(stat) == (town)) {
townlist.RemoveItem(town);  // discard self-serviced towns
//AILog.Info("Discarding " + AITown.GetName(town) + " as self-serviced.");
break;
} else {
local airdist = AIMap.DistanceManhattan(AITown.GetLocation(town),AIBaseStation.GetLocation(stat));
if (airdist < MinAirRange * 0.5) {
townlist.RemoveItem(town);  // discard town too close to existing airport
break;
}
}
}
}
}

if (AltMethod) { // build an airport that's not attached to a bus stop

if (townlist.Count() > 0) {
townlist.Valuate(AIBase.RandItem); // shuffle the town list
local newtown = townlist.Begin();

AILog.Info("attempting to build an airport at " + AITown.GetName(newtown) + "."); 
BuildAirport(AIStation.STATION_NEW,AITown.GetLocation(newtown)); // try to build an airport
}

} else {
local aplist = AIStationList(AIStation.STATION_AIRPORT); 
local bslist = AIStationList(AIStation.STATION_BUS_STOP); 
local airdist;

bslist.Valuate(AIStation.GetCargoWaiting, 0); //order by pax waiting
bslist.RemoveBelowValue(150);

foreach (stop,z in bslist) {
if (
((AITown.GetAllowedNoise(AIStation.GetNearestTown(stop))) < 4) &&
(AIGameSettings.GetValue("economy.station_noise_level") == true)
) {
bslist.RemoveItem(stop);		// remove towns with insufficent noise allowance
}
}

// now added in 1.6 - don't build airports too close to all existing airports.
// I stuffed this up in 1.7 - now it doesn't build too close to *any* existing airport. Might still be a good change?

if (aplist.Count() > 0) {
foreach (airport,z in aplist) { // remove stops in serviced towns, or too close to existing airports
foreach (stop,z in bslist) {
if ((AIStation.GetNearestTown(stop)) == (AIStation.GetNearestTown(airport))) {
bslist.RemoveItem(stop);
}
airdist = AIMap.DistanceManhattan(AIBaseStation.GetLocation(stop),AIBaseStation.GetLocation(airport));
if (airdist < MinAirRange * 0.5) {
bslist.RemoveItem(stop);
}
}
}
}

local newapsite;

if (bslist.Count() > 1) { // demand
bslist.Valuate(AIBase.RandItem); // shuffle the list
newapsite = bslist.Begin();

AILog.Info("attempting to build an airport at " + AIBaseStation.GetName(newapsite) + "."); 

BuildAirport(newapsite,AIBaseStation.GetLocation(newapsite)); // try to build an airport attached to this bus stop

} else if (townlist.Count() > 0) { // speculative
townlist.Valuate(AIBase.RandItem); // shuffle the town list
local newtown = townlist.Begin();

bslist = AIStationList(AIStation.STATION_BUS_STOP);
bslist.Valuate(AIStation.GetNearestTown);
bslist.KeepValue(newtown);

if (bslist.Count() > 1) {
bslist.Valuate(AIBase.RandItem);
newapsite = bslist.Begin();

AILog.Info("attempting to build an airport at " + AIBaseStation.GetName(newapsite) + " (Speculative)."); 

BuildAirport(newapsite,AIBaseStation.GetLocation(newapsite)); // try to build an airport attached to this bus stop
}
}
}
 // end standard construction method


// upgrade old airports
if (AIAirport.IsValidAirportType(AIAirport.AT_COMMUTER)) {
UpgradeAirports();
}
}

function CivilAI::UpgradeAirports() {

local aplist = AIStationList(AIStation.STATION_AIRPORT); 
foreach (ap, z in aplist) {
if (AIAirport.GetAirportType(AIAirport.GetHangarOfAirport(AIBaseStation.GetLocation(ap))) == AIAirport.AT_SMALL && ((AITown.GetAllowedNoise(AIStation.GetNearestTown(ap)) > 3) || (AIGameSettings.GetValue("economy.station_noise_level") == false))) {
//AILog.Info(AIBaseStation.GetName(ap) + " is upgradable.")

} else {
//AILog.Info(AIBaseStation.GetName(ap) + " is not upgradable.")
aplist.RemoveItem(ap);
}
}
if (aplist.Count() > 0) {
aplist.Valuate(AIBase.RandItem); // shuffle the list
local upgradeap = aplist.Begin();
AILog.Info("Looking for a replacement site for " + AIBaseStation.GetName(upgradeap) + ".")

if (AltMethod) {

} else {

local bslist = AIStationList(AIStation.STATION_BUS_STOP); 
bslist.Valuate(AIStation.GetNearestTown);
bslist.KeepValue(AIStation.GetNearestTown(upgradeap));

foreach (bs, z in bslist) {
if (AIStation.HasStationType(bs,AIStation.STATION_AIRPORT)) { bslist.RemoveItem(bs); } // remove stops with airports (ie the one being replaced)
}
bslist.Valuate(AIStation.GetCargoWaiting, 0); //order by pax waiting
bslist.RemoveBelowValue(100);

if (bslist.Count() > 0) {
bslist.Valuate(AIBase.RandItem); // shuffle the list
local newapsite = bslist.Begin();
AILog.Info("Attempting to build a replacement airport at " + AIBaseStation.GetName(newapsite) + "."); 

BuildAirport(newapsite,AIBaseStation.GetLocation(newapsite)); // try to build an airport attached to this bus stop


if (AIStation.HasStationType(newapsite,AIStation.STATION_AIRPORT)) {
BusDetransfer(upgradeap); // remove bus transfer orders from the old airport

// redirect all old aircraft to the new airport
local relist = AIVehicleList_Station(upgradeap)
foreach (veh,z in relist) {
if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_AIR) {
relist.RemoveItem(veh);
} else {

if (AIStation.GetStationID(AIOrder.GetOrderDestination(veh,0)) == upgradeap) 
{
AIOrder.RemoveOrder(veh, 0);
} else {
AIOrder.RemoveOrder(veh, 1);
}
AIOrder.AppendOrder(veh, AIBaseStation.GetLocation(newapsite),(AIOrder.OF_FULL_LOAD_ANY))
}
}


// delete the old airport when we can
AILog.Info("Removing old airport, stand by...");
while (AIStation.HasStationType(upgradeap,AIStation.STATION_AIRPORT)) {
AITile.DemolishTile(AIAirport.GetHangarOfAirport(AIBaseStation.GetLocation(upgradeap)));

local alist = AIVehicleList_Group(Groups[4])
alist.AddList(AIVehicleList_Group(Groups[5]))

foreach (a, z in alist) {
if  (AIVehicle.IsStoppedInDepot(a)) {
	AIVehicle.SellVehicle(a);
	}
	}
}




} else {
return;
}
} else {
AILog.Info("I couldn't find one.")
}
}
}
}

// ====================================================== 
//                   SPIRAL AIRPORT
// ====================================================== 
function CivilAI::BuildAirport(station,location) {
// clockwise spiral out
local trytilegrid = [AIMap.GetTileX(location),AIMap.GetTileY(location)]
local trytile;
local x = 0
local y = 0
local i = 0
local s = AIGameSettings.GetValue("station.station_spread")

if (AltMethod) {s = 20}
local done = false;


// commuter

if (AIAirport.IsValidAirportType(AIAirport.AT_COMMUTER)) {

while (i < s) {

// check town approval before levelling mountains!
if ((AITown.GetRating(AIStation.GetNearestTown(station), Me) < 4) && (AITown.GetRating(AIStation.GetNearestTown(station), Me) != -1)) {
AILog.Info("My local authority rating isn't high enough.")
return;
}

//y--
for (;y >= 0-i;y--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsBuildableRectangle(trytile, 5, 4) && ((i + 5) < s)) {
done = BuildComAp(station,trytile);
if (done) {break;}
}
} 
if (done) {break;}
//x--;
for (;x >= 0-i;x--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsBuildableRectangle(trytile, 5, 4)) {
done = BuildComAp(station,trytile);
if (done) {break;}
}
} 
if (done) {break;}
//y++;
for (;y <= i;y++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsBuildableRectangle(trytile, 5, 4)) {
done = BuildComAp(station,trytile);
if (done) {break;}
}
} 
if (done) {break;}
//x++;
for (;x <= i;x++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsBuildableRectangle(trytile, 5, 4) && ((i + 4) < s)) {
done = BuildComAp(station,trytile);
if (done) {break;}
}
} 
if (done) {break;}
i=i+1
}
if (i == s) {
AILog.Info("I failed to find an airport site at " + AIBaseStation.GetName(station) + "."); 
}
} else if (AIAirport.IsValidAirportType(AIAirport.AT_SMALL)) {

while (i < s) {

// check town approval before levelling mountains!
if ((AITown.GetRating(AIStation.GetNearestTown(station), Me) < 4) && (AITown.GetRating(AIStation.GetNearestTown(station), Me) != -1)) {
AILog.Info("My local authority rating isn't high enough (" + AITown.GetRating(AIStation.GetNearestTown(station), Me) + ").")
return;
}

//y--
for (;y >= 0-i;y--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, "y-");
if (AITile.IsBuildableRectangle(trytile, 4, 3) && ((i + 4) < s)) {
done = BuildSmAp(station,trytile);
if (done) {break;}
}
}
if (done) {break;} 
//x--;
for (;x >= 0-i;x--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, "x-");
if (AITile.IsBuildableRectangle(trytile, 4, 3)) {
done = BuildSmAp(station,trytile);
if (done) {break;}
}
} 
if (done) {break;}
//y++;
for (;y <= i;y++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, "y+");
if (AITile.IsBuildableRectangle(trytile, 4, 3)) {
done = BuildSmAp(station,trytile);
if (done) {break;}
}
} 
if (done) {break;}
//x++;
for (;x <= i;x++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, "x+");
if (AITile.IsBuildableRectangle(trytile, 4, 3) && ((i + 3) < s)) {
done = BuildSmAp(station,trytile);
if (done) {break;}
}
} 
if (done) {break;}
i=i+1
}
if (i == s) {
AILog.Info("I failed to find an airport site at " + AIBaseStation.GetName(station) + "."); 
}
}
}

function CivilAI::BuildComAp(station,location) {

// level the land as a matter of course now
// flatten land from the center

local tg = [AIMap.GetTileX(location),AIMap.GetTileY(location)]
local ct = AIMap.GetTileIndex(tg[0]+2,tg[1]+2)

if (NoWater(location, 5, 4)) {
AITile.LevelTiles(ct,AIMap.GetTileIndex(tg[0],tg[1]));
AITile.LevelTiles(ct,AIMap.GetTileIndex(tg[0],tg[1]+4));
AITile.LevelTiles(ct,AIMap.GetTileIndex(tg[0]+5,tg[1]));
AITile.LevelTiles(ct,AIMap.GetTileIndex(tg[0]+5,tg[1]+4));
}

if (AIAirport.BuildAirport(location,AIAirport.AT_COMMUTER,station)) {
AILog.Info("Built a commuter airport.");
return true;
} else {return false;}
}

function CivilAI::BuildSmAp(station,location) {

// level the land as a matter of course now
// flatten land from the center

local tg = [AIMap.GetTileX(location),AIMap.GetTileY(location)]
local ct = AIMap.GetTileIndex(tg[0]+2,tg[1]+1)

if (NoWater(location, 4, 3)) {
AITile.LevelTiles(ct,AIMap.GetTileIndex(tg[0],tg[1]));
AITile.LevelTiles(ct,AIMap.GetTileIndex(tg[0],tg[1]+3));
AITile.LevelTiles(ct,AIMap.GetTileIndex(tg[0]+4,tg[1]));
AITile.LevelTiles(ct,AIMap.GetTileIndex(tg[0]+4,tg[1]+3));
}

if (AIAirport.BuildAirport(location,AIAirport.AT_SMALL,station)) {
AILog.Info("Built a small airport.");
return true;
} else {return false;}
}

// ====================================================== 
//                   BUILD AIR ROUTES
// ====================================================== 
function CivilAI::AirReview() {

// rewritten in v20
AILog.Info("I'm thinking about aircraft...")

local aplist = AIStationList(AIStation.STATION_AIRPORT);
local aplist2 = AIList();
local pc = FindCargo("PASS");
local mc = FindCargo("MAIL");
local cargo;

// remove saturated airports
		foreach (airport,z in aplist) { 
			local vlist = (AIVehicleList_Group(Groups[4]));
			vlist.AddList(AIVehicleList_Group(Groups[5]));
			vlist.KeepList(AIVehicleList_Station(airport));
		if (
				((AIAirport.GetAirportType(AIBaseStation.GetLocation(airport)) == AIAirport.AT_SMALL) && vlist.Count() >= 4 ) 
			||  ((AIAirport.GetAirportType(AIBaseStation.GetLocation(airport)) == AIAirport.AT_COMMUTER) && vlist.Count() >= 8 )) {
			aplist.RemoveItem(airport);
			}
	}
	

	
aplist.Valuate(AIBase.RandItem);
aplist2.AddList(aplist);	

if (aplist.Count() < 1) {
//AILog.Info ("I couldn't find any potential airport connections.")
return;}

foreach (ap1, z1 in aplist) {
	foreach (ap2, z2 in aplist2) {
	local ok = false;
//	AILog.Info ("Considering " + AIBaseStation.GetName(ap1) + "->" + AIBaseStation.GetName(ap2) + ".")
		local airdist = AIMap.DistanceManhattan(AIBaseStation.GetLocation(ap1),AIBaseStation.GetLocation(ap2));
			if (airdist > MinAirRange) {	
				// check for unprofitable aircraft already on this route
				local vlist = (AIVehicleList_Group(Groups[4]));
				vlist.AddList(AIVehicleList_Group(Groups[5]));
				vlist.KeepList(AIVehicleList_Station(ap1));
				vlist.KeepList(AIVehicleList_Station(ap2));
				vlist.Valuate(AIVehicle.GetProfitLastYear);
				vlist.Sort(AIList.SORT_BY_VALUE, true);
				
			if (vlist.Count() == 0 || AIVehicle.GetProfitLastYear(vlist.Begin()) > AIEngine.GetPrice(AIVehicle.GetEngineType(vlist.Begin())) / 4) { 
						ok = true;
							if 	 	(AIStation.GetCargoWaiting(ap1,pc) > (vlist.Count() * 250) && AIStation.GetCargoWaiting(ap2,pc) > (vlist.Count() * 250))  { cargo = pc; }
							else if (AIStation.GetCargoWaiting(ap1,mc) > (vlist.Count() * 100) && AIStation.GetCargoWaiting(ap2,mc) > (vlist.Count() * 100))  { cargo = mc; }
							else	{ok = false;
						//	AILog.Info("There is insufficient demand.")
							}
			}// else {AILog.Info(AIVehicle.GetName(vlist.Begin()) + "is unprofitable (" + AIVehicle.GetProfitLastYear(vlist.Begin()) + ").");}	
			}// else {AILog.Info("They are too close together.");}										
	
		if (ok == true) {GoFlight(ap1, ap2, cargo);}
	
	}
}

// do we want to remove unprofitable and old aircraft?

local plist = AIVehicleList();
foreach (veh,z in plist) {
if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_AIR) {
plist.RemoveItem(veh);
}
}

for (local v = plist.Begin(); !(plist.IsEnd()); v = plist.Next()) {
if  ((AIVehicle.GetProfitLastYear(v) < 0) &&
	(AIVehicle.GetProfitThisYear(v) < 0) &&
	(AIVehicle.GetAge(v) > (365*2))) {
	AIVehicle.SendVehicleToDepot(v);
	AILog.Info(AIVehicle.GetName(v) + " is losing money, so I'm sending it to the hangar.")
	
			// v24 - remove bus transfer orders from an unprofitable air route
					local o = 0;
					while(AIOrder.IsValidVehicleOrder(v, o)) {					
					BusDetransfer(AIOrder.GetOrderDestination(v, o));
					o++;
					}
	
	}
if  (AIVehicle.GetAgeLeft(v) < (365 * 5)) {
	AIVehicle.SendVehicleToDepot(v);
	AILog.Info(AIVehicle.GetName(v) + " is getting old, so I'm sending it to the hangar.")	
	}	
}



}


function CivilAI::GoFlight(ap1, ap2, cargo) {

local airdist = AIMap.DistanceManhattan(AIBaseStation.GetLocation(ap1),AIBaseStation.GetLocation(ap2));
local acid = PickAircraft(airdist, cargo);

if (acid != null) {
local hangar = AIAirport.GetHangarOfAirport(AIBaseStation.GetLocation(ap1));
local newplane = (AIVehicle.BuildVehicle(hangar,acid));

if (AIVehicle.IsValidVehicle(newplane)) {
// refit and add to group

AIVehicle.RefitVehicle(newplane, cargo);
if (cargo == FindCargo("PASS")) { AIGroup.MoveVehicle(Groups[4], newplane); } else { AIGroup.MoveVehicle(Groups[5], newplane); }


// set orders
AIOrder.AppendOrder(newplane, AIBaseStation.GetLocation(ap1),(AIOrder.OF_FULL_LOAD_ANY))
AIOrder.AppendOrder(newplane, AIBaseStation.GetLocation(ap2),(AIOrder.OF_FULL_LOAD_ANY))

// name the plane
// ac names
local tn1 = AITown.GetName(AIStation.GetNearestTown(ap1))
local tn2 = AITown.GetName(AIStation.GetNearestTown(ap2))

local acnames = [
"Spirit of " + tn1,
"Flying " + tn1 + "er",
tn1 + " Adventurer",
tn1 + " Rocket",
tn1 + " Star",
tn1 + " Comet",
tn1 + " Prince",
tn1 + " Princess",
"Queen of " + tn1,
"Pride of " + tn1,
"Duke of " + tn1,
tn1 + " Ambassador",
"Wings over " + tn1,
tn1 + " Flash",
tn1 + " Baby",
tn1 + " Wanderer",
"Spirit of " + tn2,
"Flying " + tn2 + "er",
tn2 + " Adventurer",
tn2 + " Rocket",
tn2 + " Star",
tn2 + " Comet",
tn2 + " Prince",
tn2 + " Princess",
"Queen of " + tn2,
"Pride of " + tn2,
"Duke of " + tn2,
tn2 + " Ambassador",
"Wings over " + tn2,
tn2 + " Flash",
tn2 + " Baby",
tn2 + " Wanderer"
]


local nx = 0
local name = null
local changename = false
while (!changename && (nx < 20)) {
nx++ 
name = (acnames[AIBase.RandRange(32)])
changename = AIVehicle.SetName(newplane,name)
}

// start it up

AILog.Info("I bought a new " + AIEngine.GetName(acid) + " at " + AIBaseStation.GetName(ap1) + " (" + AIVehicle.GetName(newplane) + ").")
AIVehicle.StartStopVehicle(newplane);
} else {
AILog.Info("For some reason (probably not enough money), I couldn't buy an aircraft at " + AIBaseStation.GetName(ap1) + ".")
}

} else {
//AILog.Info("I can't find any suitable aircraft to buy...")
}
}
