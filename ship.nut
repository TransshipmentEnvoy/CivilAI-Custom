// ========================================================================
// ========================================================================
//				SSSS	H	  H		I	PPPPP 	 SSSS	
//			   S	S   H	  H		I	P	 P  S	 S   
//				SS		H	  H		I	P	 P	 SS					
//				  SS	HHHHHHH		I	PPPPP 	   SS			  )>
//			   S	S	H	  H		I	P       S	 S			  )} )
//				SSSS	H	  H		I	P     	 SSSS		   [- |__|\_ 
// ==========================================================~~\_o_o_/~~	
// =========================================================~~~~~~~~~~~~~~


function CivilAI::Shipping() {

if (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_WATER)) {
AILog.Info("I'm not allowed to build ships, boo.");
return; // no ships for us
}


AILog.Info("I'm thinking about ships...")

// review ferries

FerryReview();


// new docks:
// Find maritime towns

local marilist = AIList();

local townlist = AIList();
townlist.AddList(Cachedtowns);
townlist.AddList(Exclaves);

foreach (town, z in townlist) {
if(false) {

} else {
local tile = AITown.GetLocation(town);
local tilegrid = [AIMap.GetTileX(tile), AIMap.GetTileY(tile)];
for (local x = -2; x < 3; x++) {
for (local y = -2; y < 3; y++) {

local testtile = AIMap.GetTileIndex(tilegrid[0] + (x * 7), tilegrid[1] + (y * 7));

//AISign.BuildSign(testtile, "~");

if (AITile.IsWaterTile(testtile)) {
marilist.AddItem(town, 0);
y = 100;
x = 100; // we can stop checking this town
}	
}
}
}
}

// let's pop in some docks

foreach (town, z in marilist) {

local bslist = AIStationList(AIStation.STATION_BUS_STOP); 
bslist.Valuate(AIStation.GetNearestTown);
bslist.KeepValue(town);
local dcount = 0;

foreach (bs, z in bslist) {
local vlist = AIVehicleList_Station(bs);
if (AIStation.HasStationType(bs,AIStation.STATION_DOCK) ||
	vlist.Count() == 0) { // only include serviced stops
bslist.RemoveItem(bs);
dcount++; // count docks - max 2 per town?
}
}

if (bslist.Count() == 0 || dcount > 1) {} else {
foreach (bs, z in bslist) {
if (BuildADock(bs)) {break;}
}
}
}

for (local c = 0; c < 3; c++) {FerryRoute();}

return;
} // end func

function CivilAI::FerryRoute() {
// =============================
// build a new ferry line

local docklist = AIStationList(AIStation.STATION_DOCK); 

local finddock = null;
local dock1 = null;
local depot = null;


docklist.Valuate(AIStation.GetCargoWaiting, 0);
docklist.KeepAboveValue(100); // only consider populated docks
docklist.Valuate(AIBase.RandItem); // shuffle the list
foreach(dock, z in docklist) {
depot = FindShipDepot(dock)
if (
PaxDock(dock) &&
(depot != null)
) {
dock1 = dock;
break;
}
}

if (dock1 == null) {return;} // no docks today

docklist.RemoveItem(dock1);
docklist.Valuate(AIBase.RandItem); // shuffle the list

local beams1 = AIList();
local beams2 = AIList();

foreach (dock2, z in docklist) {
if (
(AIMap.DistanceManhattan(AIBaseStation.GetLocation(dock2), AIBaseStation.GetLocation(dock1)) > ShipRange) ||
!(PaxDock(dock2)) ||
(EnoughShips(dock1, dock2))
) {docklist.RemoveItem(dock2);} else {
//AILog.Info("I'm looking for a ferry route between " + AIStation.GetName(dock1)+ " and " + AIStation.GetName(dock2) + ".");
if (beams1.Count() == 0) {beams1 = Beamage(dock1, false);}
beams2 = Beamage(dock2, false);

// find intersection
local intersects = AIList();
intersects.AddList(beams2);
intersects.KeepList(beams1);

//AILog.Info(intersects.Count() + " intersects found.");
//if (intersects.Count() == 0) {AILog.Info("No route found.");}

if (intersects.Count() > 0) {
intersects.Valuate(AIMap.DistanceManhattan, AIBaseStation.GetLocation(dock1));
intersects.Sort(AIList.SORT_BY_VALUE, true);
local intersect1 = intersects.Begin();
local idist1 = AIMap.DistanceManhattan(intersect1,AIBaseStation.GetLocation(dock1))

intersects.Valuate(AIMap.DistanceManhattan, AIBaseStation.GetLocation(dock2));
intersects.Sort(AIList.SORT_BY_VALUE, true);
local intersect2 = intersects.Begin();
local idist2 = AIMap.DistanceManhattan(intersect2,AIBaseStation.GetLocation(dock2))

local intersect;
if (idist2 < idist1) {intersect = intersect2;} else {intersect = intersect1;}

//AISign.BuildSign(intersect, "<o>");

// do we have the money?

local dosh = AICompany.GetBankBalance(Me);
local cost = BuyAFerry(dock1, dock2, beams1, beams2, intersect, depot, true, null);
if (cost == null) {AILog.Info("There are no ferries available to buy"); return;} // there are no ferries available
cost = cost + (AIMarine.GetBuildCost(AIMarine.BT_BUOY) * 10);
if (cost > dosh) {AILog.Info("I don't have enough money to buy a ferry between " + AIStation.GetName(dock1)+ " and " + AIStation.GetName(dock2) + "."); return;}

BuyAFerry(dock1, dock2, beams1, beams2, intersect, depot, false, null);
return;
}
}
}
} // end func

function CivilAI::FerryReview() {

local ferrylist = AIVehicleList();
foreach (veh,z in ferrylist) {
if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_WATER || AIVehicle.GetCapacity(veh, 0) == 0) {ferrylist.RemoveItem(veh);}
}

//review ships
foreach (ship,z in ferrylist) {

// send old and money-losing ships to the depot

if (AIVehicle.GetAgeLeft(ship) < (365 * 1)) {
					AILog.Info (AIVehicle.GetName(ship) + " is getting old, so I'm sending it to the depot.");
					AIOrder.SetOrderFlags(ship, 0, AIOrder.OF_STOP_IN_DEPOT);
} else if ((AIVehicle.GetAge(ship) > (365 * 3)) && 
			(AIVehicle.GetProfitLastYear(ship) < 0) &&
			(AIVehicle.GetProfitThisYear(ship) < 0)) {
					AILog.Info (AIVehicle.GetName(ship) + " is losing money, so I'm sending it to the depot.");
					AIOrder.SetOrderFlags(ship, 0, AIOrder.OF_STOP_IN_DEPOT);
					AIOrder.SkipToOrder(ship,0);
				
}		// 1.9, we don't upgrade ferries any more
}
}

//==================
function CivilAI::BuildADock(station) {

// clockwise spiral out
local trytilegrid = [AIMap.GetTileX(AIBaseStation.GetLocation(station)),AIMap.GetTileY(AIBaseStation.GetLocation(station))]
local trytile;
local x = 0
local y = 0
local i = 0
local s = AIGameSettings.GetValue("station.station_spread")

if (s > 5) {s = 5} // maxspread

while ((i < s) && !(AIStation.HasStationType(station,AIStation.STATION_DOCK))) {

//y--
for (;y >= 0-i;y--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsCoastTile(trytile) && AIRoad.IsRoadTile(trytile) && !AIRoad.IsDriveThroughRoadStationTile(trytile) && AIRoad.GetNeigbourRoadCount(trytile) == 1) {AITile.DemolishTile(trytile)} // clear road spur
if (AITile.IsCoastTile(trytile) && AITile.IsBuildable(trytile)) {
if (BuildDock(station,trytile)) return true;
}
} 
//x--;
for (;x >= 0-i;x--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsCoastTile(trytile) && AIRoad.IsRoadTile(trytile) && !AIRoad.IsDriveThroughRoadStationTile(trytile) && AIRoad.GetNeigbourRoadCount(trytile) == 1) {AITile.DemolishTile(trytile)} // clear road spur
if (AITile.IsCoastTile(trytile) && AITile.IsBuildable(trytile)) {
if (BuildDock(station,trytile)) return true;
}
} 
//y++;
for (;y <= i;y++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsCoastTile(trytile) && AIRoad.IsRoadTile(trytile) && !AIRoad.IsDriveThroughRoadStationTile(trytile) && AIRoad.GetNeigbourRoadCount(trytile) == 1) {AITile.DemolishTile(trytile)} // clear road spur
if (AITile.IsCoastTile(trytile) && AITile.IsBuildable(trytile)) {
if (BuildDock(station,trytile)) return true;
}
} 
//x++;
for (;x <= i;x++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITile.IsCoastTile(trytile) && AIRoad.IsRoadTile(trytile) && !AIRoad.IsDriveThroughRoadStationTile(trytile) && AIRoad.GetNeigbourRoadCount(trytile) == 1) {AITile.DemolishTile(trytile)} // clear road spur
if (AITile.IsCoastTile(trytile) && AITile.IsBuildable(trytile)) {
if (BuildDock(station,trytile)) return true;
}
} 
i=i+1
}
if (i == s) {
//AILog.Info("I failed to find a dock site at " + AIBaseStation.GetName(station) + "."); return false; 
} else {return true;}
}

function CivilAI::BuildDock(station, tile) {
local tg = [AIMap.GetTileX(tile),AIMap.GetTileY(tile)]
		if (AITile.GetSlope(tile) == AITile.SLOPE_NW) {
			// dock facing y+
			
			if (
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]+1)) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]+2)) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]+3)) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]+4)) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]+5)) &&
			ClearDock(tile)
			) {
							local a = [AIMap.GetTileIndex(tg[0],tg[1]-1)]
							local b	= [AITown.GetLocation(AITile.GetClosestTown(tile))]		
			
				if(AIMarine.BuildDock(tile, station)) {				
							AIRoad.BuildRoad(a[0], tile);
							BuildARoad(a,b,-1,100);
							
							// build depot							
							local deptile1 = AIMap.GetTileIndex(tg[0]+1,tg[1]+2);
							local deptile2 = AIMap.GetTileIndex(tg[0]+2,tg[1]+2);
							local deptile3 = AIMap.GetTileIndex(tg[0]-1,tg[1]+2);
							local deptile4 = AIMap.GetTileIndex(tg[0]-3,tg[1]+2);
							local deptile5 = AIMap.GetTileIndex(tg[0]-1,tg[1]+3);
							
							if (AIMarine.BuildWaterDepot(deptile2,deptile1)) { }				
							else if (AIMarine.BuildWaterDepot(deptile4,deptile3)) { }
							else if (AIMarine.BuildWaterDepot(deptile5,deptile3)) { }								
						
				return true;}
						
			}
			
			
		} else if (AITile.GetSlope(tile) == AITile.SLOPE_SE) {
			// dock facing y-
			
			
			if (
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]-1)) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]-2)) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]-3)) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]-4)) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0],tg[1]-5)) &&
			ClearDock(tile)
			) {
							local a = [AIMap.GetTileIndex(tg[0],tg[1]+1)]
							local b	= [AITown.GetLocation(AITile.GetClosestTown(tile))]		
		
				if(AIMarine.BuildDock(tile, station)) {
							AIRoad.BuildRoad(a[0], tile);	
							BuildARoad(a,b,-1,100);
							
							// build depot							
							local deptile1 = AIMap.GetTileIndex(tg[0]+1,tg[1]-2);
							local deptile2 = AIMap.GetTileIndex(tg[0]+2,tg[1]-2);
							local deptile3 = AIMap.GetTileIndex(tg[0]-1,tg[1]-2);
							local deptile4 = AIMap.GetTileIndex(tg[0]-3,tg[1]-2);
							local deptile5 = AIMap.GetTileIndex(tg[0]-1,tg[1]-3);							
							
							if (AIMarine.BuildWaterDepot(deptile2,deptile1)) { }				
							else if (AIMarine.BuildWaterDepot(deptile4,deptile3)) { }
							else if (AIMarine.BuildWaterDepot(deptile5,deptile3)) { }									
							
				return true;}
						
			}			
			
			
		} else if (AITile.GetSlope(tile) == AITile.SLOPE_NE) {
			// dock facing x+
			
			
			if (
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]+1,tg[1])) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]+2,tg[1])) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]+3,tg[1])) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]+4,tg[1])) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]+5,tg[1])) &&
			ClearDock(tile)
			) {
							local a = [AIMap.GetTileIndex(tg[0]-1,tg[1])]
							local b	= [AITown.GetLocation(AITile.GetClosestTown(tile))]	
		
				if(AIMarine.BuildDock(tile, station)) {
							AIRoad.BuildRoad(a[0], tile);	
							BuildARoad(a,b,-1,100);
							
							// build depot							
							local deptile1 = AIMap.GetTileIndex(tg[0]+2,tg[1]+1);
							local deptile2 = AIMap.GetTileIndex(tg[0]+2,tg[1]+2);
							local deptile3 = AIMap.GetTileIndex(tg[0]+2,tg[1]-1);
							local deptile4 = AIMap.GetTileIndex(tg[0]+2,tg[1]-3);
							local deptile5 = AIMap.GetTileIndex(tg[0]+3,tg[1]-1);							
							
							if (AIMarine.BuildWaterDepot(deptile2,deptile1)) { }				
							else if (AIMarine.BuildWaterDepot(deptile4,deptile3)) { }	
							else if (AIMarine.BuildWaterDepot(deptile5,deptile3)) { }								
							
				return true;}
						
			}			
			


		} else if (AITile.GetSlope(tile) == AITile.SLOPE_SW) {
			// dock facing x-
			
						
			if (
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]-1,tg[1])) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]-2,tg[1])) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]-3,tg[1])) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]-4,tg[1])) &&
			AITile.IsWaterTile(AIMap.GetTileIndex(tg[0]-5,tg[1])) &&
			ClearDock(tile)
			) {
							local a = [AIMap.GetTileIndex(tg[0]+1,tg[1])]
							local b	= [AITown.GetLocation(AITile.GetClosestTown(tile))]		
											
				if(AIMarine.BuildDock(tile, station)) {
							AIRoad.BuildRoad(a[0], tile);
							BuildARoad(a,b,-1,100);
							
							// build depot							
							local deptile1 = AIMap.GetTileIndex(tg[0]-2,tg[1]+1);
							local deptile2 = AIMap.GetTileIndex(tg[0]-2,tg[1]+2);
							local deptile3 = AIMap.GetTileIndex(tg[0]-2,tg[1]-1);
							local deptile4 = AIMap.GetTileIndex(tg[0]-2,tg[1]-3);
							local deptile5 = AIMap.GetTileIndex(tg[0]-3,tg[1]-1);								
							
							if (AIMarine.BuildWaterDepot(deptile2,deptile1)) { }				
							else if (AIMarine.BuildWaterDepot(deptile4,deptile3)) { }	
							else if (AIMarine.BuildWaterDepot(deptile5,deptile3)) { }		
							
				return true;}
						
			}
			
			
			
			
						
		} else { return false; }


}

function CivilAI::ClearDock(tile) {

local tilegrid = [AIMap.GetTileX(tile), AIMap.GetTileY(tile)];

for (local x = -4; x < 5; x++) {
for (local y = -4; y < 5; y++) {

local testtile = AIMap.GetTileIndex(tilegrid[0] + x, tilegrid[1] + y);
//AISign.BuildSign(testtile, "?");
if (AIMarine.IsDockTile(testtile)) {
//	AISign.BuildSign(testtile, "!!!!!!!!!!");
	return false; // we found another dock too close
} 	
}
}
return true; // no dock found
}

function CivilAI::Beamage(dock, oilrig) {

local BeamList = AIList();
local beamtile;
local bg;
local bdist;


if (oilrig) {
beamtile = dock;
bg = [AIMap.GetTileX(beamtile), AIMap.GetTileY(beamtile)]
if (((bg[0] + bg[1]) % 2) != 0) {bg[0]--;}
beamtile = AIMap.GetTileIndex(bg[0], bg[1]);
} else {

// find the beamtile
bdist = 3; // how far out from the dock the beam origin is

local dtlist = AITileList_StationType(dock, AIStation.STATION_DOCK);
if (dtlist.Count() != 2) {AILog.Info("Something went wrong assessing the dock..."); return null;}

local docktile;
local dockslope;

foreach (tile, z in dtlist) {
if (AITile.GetSlope(tile) == AITile.SLOPE_FLAT) {docktile = tile}
else (dockslope = tile)
}

local doffset = [AIMap.GetTileX(docktile) - AIMap.GetTileX(dockslope), AIMap.GetTileY(docktile) - AIMap.GetTileY(dockslope)];
bg = [AIMap.GetTileX(docktile) + (doffset[0] * bdist), AIMap.GetTileY(docktile) + (doffset[1] * bdist)];

// make sure we're on the white tiles, so the diagonals intersect
if (((bg[0] + bg[1]) % 2) != 0) {
bdist++
bg = [AIMap.GetTileX(docktile) + (doffset[0] * bdist), AIMap.GetTileY(docktile) + (doffset[1] * bdist)];
}

beamtile = AIMap.GetTileIndex(bg[0], bg[1]);
}

// And now...
//AISign.BuildSign(beamtile, "^*^");

bg = [AIMap.GetTileX(beamtile), AIMap.GetTileY(beamtile)];
local beam = -1;
local beamprev = -1;
local beamprevprev = -1;
local beamid = 0;
for (local d = 0; d < 8; d++) // 8 directions of beamage
{
local offx;
local offy;
local x;
local y;
local px;
local py;

//AILog.Info("Drawing beam " + d);

// set the x and y offsets for the beam. we could do this with trickymaths but we'll spell it out to be clear.


	 if (d == 0) {offx = 0-0; offy = 0+1;}
else if( d == 1) {offx = 0-0; offy = 0-1;}	 
else if( d == 2) {offx = 0-1; offy = 0+0;}
else if( d == 3) {offx = 0+1; offy = 0+0;}
else if( d == 4) {offx = 0-1; offy = 0-1;}
else if( d == 5) {offx = 0-1; offy = 0+1;}
else if( d == 6) {offx = 0+1; offy = 0+1;}
else if( d == 7) {offx = 0+1; offy = 0-1;}

beam = -1;
beamprev = -1;
beamprevprev = -1;
local xsto = 0;
local ysto = 0;
local corner = false;

for (local c = 0; c < ShipRange; c++) {

beamprevprev = beamprev;
beamprev = beam;
beam = AIMap.GetTileIndex(bg[0] + (c * offx) + xsto, bg[1] + (c * offy) + ysto);

// we've hit land
if (AIMap.IsValidTile(beamprevprev) && !(
(beamprevprev == beamtile) ||
AITile.IsWaterTile(beamprevprev)||
AIMarine.IsWaterDepotTile(beamprevprev)||
AIMarine.IsDockTile(beamprevprev)||
AIMarine.IsBuoyTile(beamprevprev) ||
AIMarine.IsCanalTile(beamprevprev) ||
AIMarine.IsLockTile(beamprevprev) ||
AIIndustry.IsBuiltOnWater(AIIndustry.GetIndustryID(beamprevprev))
)) {break;}


// we've hit the edge of the map
if (!AIMap.IsValidTile(beam)) {

beam = beamprevprev; // backtrack onto the map

	if (d < 4) {corner = true;}

else if (
AIMap.IsValidTile(AIMap.GetTileIndex(AIMap.GetTileX(beam) + 2, AIMap.GetTileY(beam))) &&	
AIMap.IsValidTile(AIMap.GetTileIndex(AIMap.GetTileX(beam) - 2, AIMap.GetTileY(beam)))) // hit the y edge
{
//AILog.Info("Hit Y Edge")
ysto = AIMap.GetTileY(beam) - bg[1];
offy = 0;
beamprevprev = -1;
beamprev = -1;
} else if (
AIMap.IsValidTile(AIMap.GetTileIndex(AIMap.GetTileX(beam), AIMap.GetTileY(beam) + 2)) &&	
AIMap.IsValidTile(AIMap.GetTileIndex(AIMap.GetTileX(beam), AIMap.GetTileY(beam) - 2))) // hit the y edge
{
//AILog.Info("Hit X Edge")
xsto = AIMap.GetTileX(beam) - bg[0];
offx = 0;
beamprevprev = -1;
beamprev = -1;
} else corner = true; // hit a corner, save the tile before breaking to allow pathing around the outside of the map
}

// save the beam to the list
if (AIMap.IsValidTile(beamprevprev)) {
beamid = (d * 10000) + c;
//AISign.BuildSign(beamprevprev, beamid + "");
BeamList.AddItem(beamprevprev, beamid);
}

if (corner) {break;} 

} // end beam
} // end beams

return (BeamList);

} // end func

function CivilAI::FindShipDepot(dock) {

// find the flat dock tile
local dtlist = AITileList_StationType(dock, AIStation.STATION_DOCK);
if (dtlist.Count() != 2) {AILog.Info("Something went wrong assessing the dock..."); return null;}

local docktile;
foreach (tile, z in dtlist) {
if (AITile.GetSlope(tile) == AITile.SLOPE_FLAT) {docktile = tile}
}

local dg = [AIMap.GetTileX(docktile), AIMap.GetTileY(docktile)];
// check the standard depot spots
local tile;

tile = AIMap.GetTileIndex(dg[0] - 1, dg[1] + 2);
if (AIMarine.IsWaterDepotTile(tile)){ return tile;}
tile = AIMap.GetTileIndex(dg[0] - 1, dg[1] - 2);                            
if (AIMarine.IsWaterDepotTile(tile)){ return tile;}
tile = AIMap.GetTileIndex(dg[0] - 2, dg[1] + 1);                            
if (AIMarine.IsWaterDepotTile(tile)){ return tile;}
tile = AIMap.GetTileIndex(dg[0] - 2, dg[1] - 1);                            
if (AIMarine.IsWaterDepotTile(tile)){ return tile;}
tile = AIMap.GetTileIndex(dg[0] + 1, dg[1] + 2);                            
if (AIMarine.IsWaterDepotTile(tile)){ return tile;}
tile = AIMap.GetTileIndex(dg[0] + 1, dg[1] - 2);                            
if (AIMarine.IsWaterDepotTile(tile)){ return tile;}
tile = AIMap.GetTileIndex(dg[0] + 2, dg[1] + 1);                            
if (AIMarine.IsWaterDepotTile(tile)){ return tile;}
tile = AIMap.GetTileIndex(dg[0] + 2, dg[1] - 1);                            
if (AIMarine.IsWaterDepotTile(tile)){ return tile;}

return null;
}


function CivilAI::BuyAFerry(dock1, dock2, beams1, beams2, intersect, depot, costing, copycat) {

local buoylist = AIList();
if (!costing) {

AILog.Info("I'm considering a ferry between " + AIStation.GetName(dock1)+ " and " + AIStation.GetName(dock2) + ".");

if (copycat == null) {

// first, check the route is profitable
local profits = 0;
local avgage = 0;
local shiplist = AIVehicleList_Station(dock1);
shiplist.KeepList(AIVehicleList_Station(dock2));
foreach (v, z in shiplist) {
if (AIVehicle.GetVehicleType(v) != AIVehicle.VT_WATER) {shiplist.RemoveItem(v);} else {avgage = avgage + AIVehicle.GetAge(v); profits = (profits + AIVehicle.GetProfitLastYear(v) + AIVehicle.GetProfitThisYear(v) - AIEngine.GetRunningCost(AIVehicle.GetEngineType(v)));}
}

if (shiplist.Count() == 0) {avgage = 50} else {avgage = ((avgage / shiplist.Count()) / 365);}

if (profits < 0) {AILog.Info("I won't build another ship for " + AIStation.GetName(dock1) + " -> " + AIStation.GetName(dock2) + " because the route is unprofitable."); return null;}
else if (avgage < 3) {AILog.Info("I won't build another ship for " + AIStation.GetName(dock1) + " -> " + AIStation.GetName(dock2) + " because the current ships are too new."); return null;}


// no existing ferries - build a new route with our route data

local buoyspacing = 20; // distance between buoys

// find which beams the intersect is on

local beam1 = beams1.GetValue(intersect) / 10000;
local beam1dist = beams1.GetValue(intersect) % 10000;
//AILog.Info("Beam 1 = " + beam1 + " dist " + beam1dist);
local beam2 = beams2.GetValue(intersect) / 10000;
local beam2dist = beams2.GetValue(intersect) % 10000;
//AILog.Info("Beam 2 = " + beam2 + " dist " + beam2dist);

local b;
local btile;
local blist = AIList();

b = 1;
while (beam1dist > (buoyspacing * 5 / 4)) {
blist.Clear();
blist.AddList(beams1);
blist.KeepValue((beam1 * 10000) + (b * buoyspacing));
btile = blist.Begin();
AIMarine.BuildBuoy(btile);
buoylist.AddItem(btile, b);
//AILog.Info("Placed a buoy." + beam1dist)
beam1dist = beam1dist - buoyspacing;
b++
}

b = 1;
while (beam2dist > (buoyspacing * 5 / 4)) {
blist.Clear();
blist.AddList(beams2);
blist.KeepValue((beam2 * 10000) + (b * buoyspacing));
btile = blist.Begin();
AIMarine.BuildBuoy(btile);
buoylist.AddItem(btile, 1000 - b);
//AILog.Info("Placed a buoy." + beam2dist)
beam2dist = beam2dist - buoyspacing;
b++
}
}
}

// pick a ferry
local ship = null;
local route = AIMap.DistanceManhattan(AIBaseStation.GetLocation(dock1),AIBaseStation.GetLocation(dock2));

ship = PickShip(route);

if (ship == null) {return null}
else if (costing) {return AIEngine.GetPrice(ship)} else {

local newship;
if (newship = (AIVehicle.BuildVehicle(depot,ship))) {

if (copycat != null) {AIOrder.CopyOrders(newship, copycat)} else {

// =====
local fullflag;
if (route > 32) {fullflag = AIOrder.OF_FULL_LOAD_ANY} else {fullflag = AIOrder.OF_NONE}

AIOrder.AppendOrder(newship, depot, AIOrder.OF_SERVICE_IF_NEEDED);
AIOrder.AppendOrder(newship, AIBaseStation.GetLocation(dock1),fullflag);

local c;
local b;
local o = buoylist.Count();
buoylist.Sort(AIList.SORT_BY_VALUE, true);
b = buoylist.Begin();
for(c = 0; c < o; c++) {AIOrder.AppendOrder(newship, b ,AIOrder.OF_NONE); b = buoylist.Next();}
AIOrder.AppendOrder(newship, AIBaseStation.GetLocation(dock2),fullflag);
buoylist.Sort(AIList.SORT_BY_VALUE, false);
b = buoylist.Begin();
for(c = 0; c < o; c++) {AIOrder.AppendOrder(newship, b ,AIOrder.OF_NONE); b = buoylist.Next();}

// =====

}
// name the ship

local tna = [AITown.GetName(AIStation.GetNearestTown(dock1)), AITown.GetName(AIStation.GetNearestTown(dock2))];
local tn = tna[AIBase.RandRange(2)];


local prefix;
if (AIDate.GetYear(AIEngine.GetDesignDate(AIVehicle.GetEngineType(newship))) < 1950) {prefix = "SS ";} else {prefix = "MV ";}

local smallshipnames = [ //8
"Turtle",
"Aurora",
"George",
"Comet",
"Puffer",
"Otter",
"Dolphin",
"Penguin"
]

local medshipnames = [ //8
"Flying " + tn + "er",
tn + " Star",
tn + " Wanderer",
tn + " Ferry"
tn + " Trader"
tn + " Packet"
tn + " Captain"
tn + " Admiral"
]

local bigshipnames = [ //8
prefix + "Spirit of " + tn,
prefix + tn + " Ambassador",
prefix + "Duke of " + tn,
prefix + tn + " Prince",
prefix + tn + " Princess",
prefix + "Queen of " + tn,
prefix + tn,
prefix + AICompany.GetPresidentName(Me),
]

local shipsize = (AIVehicle.GetCapacity(newship, 0) - 1) / 50;
local namesize;

if (shipsize < 2) {
namesize = 0;
}
else if (shipsize < 4) {
namesize = AIBase.RandRange(2);
}
else if (shipsize < 6) {
namesize = 1;
}
else if (shipsize < 10) {
namesize = AIBase.RandRange(2) + 1;
}
else {
namesize = 2;
}

local nx = 0
local name = null
local shipname = null
local changename = false


// smallnames

if (namesize == 0) {

shipname = smallshipnames[AIBase.RandRange(8)]
while (!changename) {
nx++ 
if (nx < 2) {
name = (shipname)
} else {
name = (shipname + " " + nx)
}
changename = AIVehicle.SetName(newship,name)
}
}

else if (namesize == 1) {

while (!changename) {
shipname = medshipnames[AIBase.RandRange(8)]
nx++ 
if (nx < 20) { // only add suffixes if we get desperate
name = (shipname)
} else {
name = (shipname + " " + (nx / 10))
}
changename = AIVehicle.SetName(newship,name)
}

} else {

while (!changename) {
shipname = bigshipnames[AIBase.RandRange(8)]
nx++ 
if (nx < 10) { // only add suffixes if we get desperate
name = (shipname)
} else {
name = (shipname + " " + (nx / 10))
}
changename = AIVehicle.SetName(newship,name)
}
}

AILog.Info("I bought a " + AIEngine.GetName(ship) + " (" + AIVehicle.GetName(newship) + ") for " + AIStation.GetName(dock1) + " -> " + AIStation.GetName(dock2) + ".");

AIVehicle.StartStopVehicle(newship); // honk honk!


} else {AILog.Info("For some reason, I couldn't build a new ship."); return null;}



}
return null;
}// end func

function CivilAI::FerryPax(dock1, dock2) {

local paxa;
local paxb;
local pax1 = AIStation.GetCargoWaiting(dock1,0);
local pax2 = AIStation.GetCargoWaiting(dock2,0);

if (pax1 > pax2) {paxa = pax1; paxb = pax2;} else {paxa = pax2, paxb = pax1;}

return ((paxa / 2) + (paxb / 2 * 3));
}

function CivilAI::EnoughShips(dock1, dock2) {

local shiplist = AIVehicleList_Station(dock1);
shiplist.KeepList(AIVehicleList_Station(dock2));

foreach (v, z in shiplist) {
if (AIVehicle.GetVehicleType(v) != AIVehicle.VT_WATER) shiplist.RemoveItem(v);
}

local route = AIMap.DistanceManhattan(AIBaseStation.GetLocation(dock1),AIBaseStation.GetLocation(dock2));

//AILog.Info(shiplist.Count() + " / " + (1 + (route / 30)) + " ships currently on this route.");

if (shiplist.Count() < (1 + (route / 30))) {return false;} else {return true;}
}

function CivilAI::PaxDock(dock) {
local clist = AICargoList_StationAccepting(dock)
if (clist.HasItem(0)) {return true;} else {return false;}
}