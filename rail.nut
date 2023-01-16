// ====================================================== 
// ====================================================== 
// 			  RRRR     A    I  L
// 			  R   R   A A   I  L
// 			  R  R   A   A  I  L
//  		  RRRR   AAAAA  I  L
//  		  R   R  A   A  I  LLLLL
// ===========================================ChooChoo!== 
// ====================================================== 
// ===================
// identify industries we want to service

function CivilAI::ServeIndustries() {

local indtypes = AIIndustryTypeList();
local industries = AIIndustryList();
local indlist = AIList();

foreach (ind, z in indtypes) {
local cargos = AIIndustryType.GetProducedCargo(ind);

if (cargos.Count() > 0) {

local good = FindCargo("GOOD");
if (good != null) {
if (cargos.HasItem(good)) {
//AILog.Info (AIIndustryType.GetName(ind) + " is a valid industry (produces Goods).")

	industries = AIIndustryList();
	industries.Valuate(AIIndustry.GetIndustryType);
	industries.KeepValue(ind);
	indlist.AddList(industries);
}
}

local food = FindCargo("FOOD");
if (food != null) {
if (cargos.HasItem(food)) {
//AILog.Info (AIIndustryType.GetName(ind) + " is a valid industry (produces Food).")

	industries = AIIndustryList();
	industries.Valuate(AIIndustry.GetIndustryType);
	industries.KeepValue(ind);
	indlist.AddList(industries);
}
}

} else {
//AILog.Info (AIIndustryType.GetName(ind) + " is a valid industry (no production).")

	industries = AIIndustryList();
	industries.Valuate(AIIndustry.GetIndustryType);
	industries.KeepValue(ind);
	indlist.AddList(industries);

}
}

return indlist;

}

// ===================!
// build freight line
// ===================!


function CivilAI::CargoLine() {

local dest = null;
local src = null;
local cargo = null;
local carg2 = null;
local suptile = null;
local go = false;
local loopline = false;
local farm = false;

local trainstobuy = 1;
local maxtrainlength = 5;
local mintrainlength = 3;
local trainlength = 3;
local tracks = 1;

// find an industry to build a terminus at (or whose terminus we shall reuse)
// first, examine existing termini

local tslist = AIStationList(AIStation.STATION_TRAIN); 
tslist.RemoveList(DudTerminus); // remove known unreachables

foreach (ts, z in tslist) {
if (FindTrainDepot(ts) == null)  { tslist.RemoveItem(ts); DudTerminus.AddItem(ts, 0); } // not a terminus station
else if (gotile(ts) == null)     { tslist.RemoveItem(ts); DudTerminus.AddItem(ts, 0); } // no second track space
}

if (tslist.Count() > 0 ) {

tslist.Valuate(AIBase.RandItem); // shuffle the list


foreach (ts, z in tslist) {

local supdist = 10000000;
suptile = null;

AILog.Info("Identifying industries which can supply "  + AIBaseStation.GetName(ts) + ".");

	local clist = AICargoList_StationAccepting(ts)
		foreach (c, z in clist) {
		local suplist = AIIndustryList_CargoProducing(c);
		suplist.RemoveList(DudIndustries); // remove known unconnectables
		suplist.RemoveList(ConnectedPInds); // remove industries we already serve
				foreach (s, z in suplist) {
					local d = ScoreRoute(AIBaseStation.GetLocation(ts),AIIndustry.GetLocation(s));	
					//AILog.Info("Assessing " + AIIndustry.GetName(s) + " (" + d + " tiles).");
								
				
					if (d < TrainRange
					&& AIIndustry.GetLastMonthProduction(s, c) > 60
					&& AIIndustry.GetLastMonthTransportedPercentage(s, c) == 0
					&& !AIIndustry.IsBuiltOnWater(s)) {
				
					if (d < supdist) {
					supdist = d; // this is the nearest supplier
					suptile = (AIIndustry.GetLocation(s));
					cargo = c;
					carg2 = c;
					
						// check for industries which don't have a tile in their top left corner (PITA)
						local i = 0;
						while (!AIIndustry.IsValidIndustry(AIIndustry.GetIndustryID(suptile)) && i < 10) {
						suptile = AIMap.GetTileIndex((AIMap.GetTileX(suptile) + 1),(AIMap.GetTileY(suptile) + 1));
						//AILog.Info(AIIndustry.GetName(AIIndustry.GetIndustryID(suptile)))
						i++
					}
					
					

			
}
} else {
suplist.RemoveItem(s);
}
}	
if (suptile != null) {dest = ts; break;}
}
if (suptile != null) {dest = ts; break;}
}

if (dest != null && suptile != null) { // We found a suitable terminus, so build a line
AILog.Info("I could connect " + AIIndustry.GetName(AIIndustry.GetIndustryID(suptile)) + " to " + AIBaseStation.GetName(dest) + ".");
// check we have dosh

AIRail.SetCurrentRailType(AIRail.GetRailType(AITileList_StationType(dest, AIStation.STATION_TRAIN).Begin())); // set the current railtype to the railtype of the destination station

local dosh = AICompany.GetBankBalance(Me);
local cost;
//First, let's check if we want a simple 1-train service, or a multi-train line.

//AILog.Info("Checking distance: " + AIMap.DistanceManhattan((AIBaseStation.GetLocation(dest)),suptile) + " cargo: " + AIIndustry.GetLastMonthProduction(AIIndustry.GetIndustryID(suptile), cargo))

// ------ v20: are we a double-supplier? (ie a farm)
local c2list = AICargoList_StationAccepting(dest);
	  c2list.KeepList(AICargoList_IndustryProducing(AIIndustry.GetIndustryID(suptile)));

	if (c2list.Count() > 1) {
//	AILog.Info("Moo!")		
		foreach (c, z in c2list) {
				 if (c != cargo) {carg2 = c; tracks = 2; trainstobuy++; farm = true; break;}
				}
	}
// --------

local destlength = GetStatLength(dest);
local statest = ((AIMap.DistanceManhattan((AIBaseStation.GetLocation(dest)),suptile) + 
				 AIIndustry.GetLastMonthProduction(AIIndustry.GetIndustryID(suptile), cargo))
				 / 100);
				 
			// AILog.Info(statest);
if (statest < mintrainlength) { trainlength = mintrainlength; }				 
if (statest >= mintrainlength * 2) { trainlength = statest / 2; tracks = 2; trainstobuy = 2; }		 
if (trainlength > maxtrainlength) { trainlength = maxtrainlength; }
if (trainlength > destlength) {trainlength = destlength; if (!farm) {trainstobuy++; if (tracks ==1) {tracks = 2}}} // don't build longer than the terminus


// check funds allow for the connection, and a bit left over to maintain the network

cost = (
(AIRail.GetBuildCost(AIRail.GetCurrentRailType(), AIRail.BT_TRACK) * AIMap.DistanceManhattan((AIBaseStation.GetLocation(dest)),suptile) * tracks) +
(AITile.GetBuildCost(AITile.BT_CLEAR_FIELDS) * AIMap.DistanceManhattan((AIBaseStation.GetLocation(dest)),suptile)) +
(AIRail.GetBuildCost(AIRail.GetCurrentRailType(), AIRail.BT_STATION) * trainlength * trainstobuy) +
(BuyATrain(0, 0, cargo, 0, trainlength, true, 0) * trainstobuy)
)


if (dosh < cost) {
AILog.Info("I can't afford to build a railway right now. Perhaps later.");
return;
}

//AISign.BuildSign(gotile, "C " + AIBaseStation.GetName(dest))


local s;
local o;

local t2x = AIMap.GetTileX(AIBaseStation.GetLocation(dest));
local t2y = AIMap.GetTileY(AIBaseStation.GetLocation(dest));
local t1x = AIMap.GetTileX(suptile);
local t1y = AIMap.GetTileY(suptile);

local rx = t2x - t1x;
local ry = t2y - t1y;

if (ry > 0) {
	if (rx > 0) {
					// south
			if (rx > ry) {
				s = 1
				o = 3			
			} else {
				s = 3
				o = 1			
			}
	} else {
					// east
			if (-rx > ry) {
				s = 1
				o = 2			
			} else {
				s = 2
				o = 1			
			}	
	}

} else {

	if (rx > 0) {
					// west
			if (rx > -ry) {
				s = 0
				o = 3			
			} else {
				s = 3
				o = 0			
			}
	} else {
					// north
			if (-rx > -ry) {
				s = 0
				o = 2			
			} else {
				s = 2
				o = 0			
			}	
	}
}


	if (src = TrainPickup(AIIndustry.GetIndustryID(suptile), s, o, cargo, tracks, trainlength)) {
	go = true;
	
//	AILog.Info ("go!")
	
	} else { DudIndustries.AddItem(AIIndustry.GetIndustryID(suptile), 0);}
}	
} 


if (!go) {
//=================================
//We need a new terminus. create a list of goods/food producing industries near our network, with no current production.

local BuildList = ServeIndustries();
local townlist = AIList();
townlist.AddList(Cachedtowns);
townlist.AddList(Exclaves);
BuildList.RemoveList(DudIndustries); // remove known unconnectables


local tslist = AIStationList(AIStation.STATION_TRAIN); 
foreach (i, z in BuildList) {
local catchment = AITileList_IndustryAccepting(i, 4);
foreach (stat, z in tslist) {
if (catchment.HasItem(AIStation.GetLocation(stat))) {
BuildList.RemoveItem(i); // remove industries with existing stations
}
}
}

foreach (i, z in BuildList) {
local tiletown = AITile.GetClosestTown(AIIndustry.GetLocation(i));

if (!(townlist.HasItem(tiletown))) { // remove industries not near our towns
BuildList.RemoveItem(i);
} else if (AIIndustry.IsBuiltOnWater(i)) {
BuildList.RemoveItem(i);
}
}

//Now check for nearby suppliers

foreach (i, z in BuildList) {

//AILog.Info("Contemplating " + AIIndustry.GetName(i) + ".");

// Find the nearest resource supplier
local suplist = AIList();
local cslist = AIList();
cslist = AIIndustryType.GetAcceptedCargo(AIIndustry.GetIndustryType(i));
local supcount = 0;

if (cslist != null) { // added because we crashed here for some reason
foreach (c, z in cslist) {
suplist = AIIndustryList_CargoProducing(c);
suplist.RemoveList(DudIndustries); // remove known unconnectables
suplist.RemoveList(ConnectedPInds); // remove industries we already serve
foreach (s, z in suplist) {
local d = ScoreRoute(AIIndustry.GetLocation(i),AIIndustry.GetLocation(s));	
// AILog.Info("Assessing " + AIIndustry.GetName(s) + " (" + d + " tiles).");



if (d < TrainRange
&& AIIndustry.GetLastMonthProduction(s, c) > 60
&& AIIndustry.GetLastMonthTransportedPercentage(s, c) == 0
&& !AIIndustry.IsBuiltOnWater(s)) {
supcount++ // this is an appropriate supplier
} else {
suplist.RemoveItem(s);
}
}
}
}
if (supcount == 0) {
//AILog.Info("No suppliers found in range.");
BuildList.RemoveItem(i);
} else {
//AILog.Info(supcount + " suppliers found.");
}
}

if (BuildList.Count() > 0) {
BuildList.Valuate(AIBase.RandItem); // shuffle the list
local Ind = BuildList.Begin();

AILog.Info("Contemplating " + AIIndustry.GetName(Ind) + ".");

// now we check again, to get the correct direction for the station
// Find the nearest resource supplier
local suplist = AIList();
local cslist  = AIList();
cslist = AIIndustryType.GetAcceptedCargo(AIIndustry.GetIndustryType(Ind));
local supdist = 10000000;
suptile = null;

foreach (c, z in cslist) {
suplist = AIIndustryList_CargoProducing(c);
suplist.RemoveList(DudIndustries); // remove known unconnectables
suplist.RemoveList(ConnectedPInds); // remove industries we already serve
foreach (s, z in suplist) {
local d = ScoreRoute(AIIndustry.GetLocation(Ind),AIIndustry.GetLocation(s));	

//AILog.Info("Assessing " + AIIndustry.GetName(s) + " (" + d + " tiles).");

if (d < TrainRange
&& AIIndustry.GetLastMonthProduction(s, c) > 60
&& AIIndustry.GetLastMonthTransportedPercentage(s, c) == 0
&& !AIIndustry.IsBuiltOnWater(s)) {

if (d < supdist) {
supdist = d; // this is the nearest supplier
suptile = (AIIndustry.GetLocation(s));

// check for industries which don't have a tile in their top left corner (PITA)
local i = 0;
while (!AIIndustry.IsValidIndustry(AIIndustry.GetIndustryID(suptile)) && i < 10) {
suptile = AIMap.GetTileIndex((AIMap.GetTileX(suptile) + 1),(AIMap.GetTileY(suptile) + 1));
//AILog.Info(AIIndustry.GetName(AIIndustry.GetIndustryID(suptile)))
i++
}

cargo = c;
carg2 = c;
}
} else {
suplist.RemoveItem(s);
}
}
}

// didn't find a supplier

if (suptile == null) {
AILog.Info("I failed to find a supplier.")
return;
}



//Now pick where to put the station, and in what orientation
// updated to v20 standard

AILog.Info("Supplier found at " + AIIndustry.GetName(AIIndustry.GetIndustryID(suptile)) + ".");

local s;
local o;

local t1x = AIMap.GetTileX(AIIndustry.GetLocation(Ind));
local t1y = AIMap.GetTileY(AIIndustry.GetLocation(Ind));
local t2x = AIMap.GetTileX(suptile);
local t2y = AIMap.GetTileY(suptile);

local rx = t2x - t1x;
local ry = t2y - t1y;

if (ry > 0) {
	if (rx > 0) {
					// south
			if (rx > ry) {
				s = 1
				o = 3			
			} else {
				s = 3
				o = 1			
			}
	} else {
					// east
			if (-rx > ry) {
				s = 1
				o = 2			
			} else {
				s = 2
				o = 1			
			}	
	}

} else {

	if (rx > 0) {
					// west
			if (rx > -ry) {
				s = 0
				o = 3			
			} else {
				s = 3
				o = 0			
			}
	} else {
					// north
			if (-rx > -ry) {
				s = 0
				o = 2			
			} else {
				s = 2
				o = 0			
			}	
	}
}

// Let's build the route! (if we have the money)

//First, let's check if we want a simple 1-train service, or a two-train loopline.
//AILog.Info("Checking distance: " + AIMap.DistanceManhattan((AIIndustry.GetLocation(Ind)),(AIIndustry.GetLocation(AIIndustry.GetIndustryID(suptile)))) + " cargo: " + AIIndustry.GetLastMonthProduction(AIIndustry.GetIndustryID(suptile), cargo))


// ------ v20: are we a double-supplier? (ie a farm)
local c2list = AICargoList_IndustryAccepting(Ind);
	  c2list.KeepList(AICargoList_IndustryProducing(AIIndustry.GetIndustryID(suptile)));

	if (c2list.Count() > 1) {
//	AILog.Info("Moo!")		
		foreach (c, z in c2list) {
				 if (c != cargo) {carg2 = c; tracks = 2; trainstobuy++; farm = true; break;}
				}
	}
// --------

local dosh = AICompany.GetBankBalance(Me);
local cost;

local statest = ((AIMap.DistanceManhattan(AIIndustry.GetLocation(Ind),suptile) + 
				 AIIndustry.GetLastMonthProduction(AIIndustry.GetIndustryID(suptile), cargo))
				 / 20);
				 
			//	 AILog.Info(statest);
if (statest < mintrainlength) { trainlength = mintrainlength; }						 
if (statest >= mintrainlength * 2) { trainlength = statest / 2; tracks = 2; trainstobuy = 2; }			 
if (trainlength > maxtrainlength) { trainlength = maxtrainlength; }

// check funds allow for the connection, and a bit left over to maintain the network

cost = (
(AIRail.GetBuildCost(AIRail.GetCurrentRailType(), AIRail.BT_TRACK) * AIMap.DistanceManhattan(AIIndustry.GetLocation(Ind),suptile) * tracks) +
(AITile.GetBuildCost(AITile.BT_CLEAR_FIELDS) * AIMap.DistanceManhattan(AIIndustry.GetLocation(Ind),suptile)) +
(AIRail.GetBuildCost(AIRail.GetCurrentRailType(), AIRail.BT_STATION) * trainlength * trainstobuy) +
(BuyATrain(0, 0, cargo, 0, trainlength, true, 0) * trainstobuy)
)

if (dosh < cost){
AILog.Info("I can't afford to build a railway right now. Perhaps later.");
return;
}

if (dest = SmallStation(Ind, s, o, cargo, tracks, trainlength)) {
if (s % 2 == 0) {s++;} else {s--;}
if (o % 2 == 0) {o++;} else {o--;}

	if (src = TrainPickup(AIIndustry.GetIndustryID(suptile), s, o, cargo, tracks, trainlength)) {
	go = true;
	} else { DudIndustries.AddItem(AIIndustry.GetIndustryID(suptile), 0);}
	}

} else {
AILog.Info("I couldn't find an appropriate industry to serve.");

DudCounter++

if (DudCounter > 3) {
DudIndustries.Valuate(AIBase.RandItem); // shuffle the list
DudIndustries.RemoveTop(1);// remove a random industry from the dud list
DudCounter = 0;
}

// see if we can't find a nearby industry in a smaller town

local xoilist = ServeIndustries();
local hq = AICompany.GetCompanyHQ(Me);
xoilist.Valuate(AIIndustry.GetDistanceManhattanToTile, hq);
xoilist.Sort(AIList.SORT_BY_VALUE,true);
foreach (i, z in xoilist) {

local tiletown = AITile.GetClosestTown(AIIndustry.GetLocation(i));
if (!(townlist.HasItem(tiletown))) {

IndTownList.AddItem(tiletown, 0); // add this town to the list to connect even if it's not big enough
AILog.Info("But " + AIIndustry.GetName(i) + " is intriguing...")
return;
}
}
}
}

if (tracks > 1) {loopline = true;}

if (go && BuildLine(dest, src, loopline)) {

local depot = FindTrainDepot(dest);
if (depot != null) {
		BuyATrain(dest, src, carg2, depot, trainlength, false, 0);
	for (local c = 1; c < trainstobuy; c++) {
		BuyATrain(dest, src, cargo, depot, trainlength, false, 0);
		}
}

if (suptile != null && AIIndustry.GetIndustryID(suptile) != null) {ConnectedPInds.AddItem(AIIndustry.GetIndustryID(suptile), 0);}

} else if (suptile != null && AIIndustry.GetIndustryID(suptile) != null) {DudIndustries.AddItem(AIIndustry.GetIndustryID(suptile), 0);}
}

// =============
// build a line between the stations
// =============

function CivilAI::BuildLine(stat1, stat2, loopline) {
HillClimb = 0; // reset global vars
BackTrackCounter = 0;

local ok = false;

// identify connecting tiles
local goa = gotile(stat1);
local gob = gotile(stat2);

	if (goa != null && gob != null) {
		if (BuildALine([goa],[gob])) {
			
				if (loopline) {TwinTrack(goa,gob,GetStatLength(stat2));} 
				if (AttachLine(goa) && AttachLine(gob)) { ok = true; } 				
				else { DemoWalk(goa[0], 0, false); DemoWalk(gob[0], 0, false); }
				
				if (!loopline) {AIRail.BuildSignal(goa[1],goa[0],AIRail.SIGNALTYPE_PBS);}
				
			}
				
			
		} 
	
	return ok;
		
}

//===================================
//build a small drop-off station
//===================================

function CivilAI::SmallStation(ind, side, orientation, cargo, tracks, trainlength) {

local xof;
local yof;
local indloc = AIIndustry.GetLocation(ind);

// updated to v20 standard

if (side == 1) {
xof = 0 // SE
yof = 4
} else if (side == 3) {
xof = 4 // SW
yof = 0
} else if (side == 0) {
xof = 0 // NW
yof = -3
} else {
xof = -3 // NE
yof = 0
}

// clockwise spiral out
local trytilegrid = [AIMap.GetTileX(indloc) + xof,AIMap.GetTileY(indloc) + yof] // we're making assumptions about industry size here
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
if (AITileList_IndustryAccepting(ind, 4).HasItem(trytile)) {
NewStat = BuildSmallStation(trytile, orientation, cargo, ind, tracks, trainlength);
if (NewStat != null) { return NewStat; } 
}
} 
//x--;
for (;x >= 0-i;x--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITileList_IndustryAccepting(ind, 4).HasItem(trytile)) {
NewStat = BuildSmallStation(trytile, orientation, cargo, ind, tracks, trainlength);
if (NewStat != null) { return NewStat; } 
}
} 
//y++;
for (;y <= i;y++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITileList_IndustryAccepting(ind, 4).HasItem(trytile)) {
NewStat = BuildSmallStation(trytile, orientation, cargo, ind, tracks, trainlength);
if (NewStat != null) { return NewStat; } 
}
} 
//x++;
for (;x <= i;x++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITileList_IndustryAccepting(ind, 4).HasItem(trytile)) {
NewStat = BuildSmallStation(trytile, orientation, cargo, ind, tracks, trainlength);
if (NewStat != null) { return NewStat; } 
}
}
i=i+1
}

// failed to build, so -

DudIndustries.AddItem(ind, 0);
return false;

}
//======
 function CivilAI::BuildSmallStation(tile, face, cargo, ind, tracks, trainlength) {
 //=====
 // updated to v20 spec!
 
local go = false;
local tg = [AIMap.GetTileX(tile),AIMap.GetTileY(tile)]
local tt = null;
 
// v20 - updated station design/placement

if (face < 2) { // station oriented on y axis
			if (!(AITile.IsBuildableRectangle(AIMap.GetTileIndex(tg[0]-1,tg[1]-3), tracks + 1, trainlength + 4))) { return null; }
			if (!NoWater(AIMap.GetTileIndex(tg[0]-1,tg[1]-3), tracks+1, 7)) { return null; }
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]+tracks,tg[1] + trainlength));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]-1,tg[1] + trainlength));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0] + tracks,tg[1]-2));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]-1,tg[1]-2));
			
			// check it's flattish
			if (!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]+tracks,tg[1] + trainlength))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]-1,tg[1] + trainlength - 1))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]+tracks,tg[1]-2))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]-1,tg[1]-1)))) { return null; }
			
			//AISign.BuildSign(AIMap.GetTileIndex(tg[0]+1,tg[1]+trainlength), "+");
			//AISign.BuildSign(AIMap.GetTileIndex(tg[0]-1,tg[1]-3), "-");
			//AISign.BuildSign(tile "C" + face);

			if (face == 0) {
			tt = AIMap.GetTileIndex(tg[0],tg[1]);
			if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NW_SE, tracks, trainlength, AIStation.STATION_NEW, cargo, AIIndustryType.INDUSTRYTYPE_UNKNOWN, AIIndustry.GetIndustryType(ind), 64, false)) {
			
			go = true; }
			} else {
			
			tt = AIMap.GetTileIndex(tg[0],tg[1] + 1 - trainlength);
			if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NW_SE, tracks, trainlength, AIStation.STATION_NEW, cargo, AIIndustryType.INDUSTRYTYPE_UNKNOWN, AIIndustry.GetIndustryType(ind), 64, false)) {
			
			go = true; }
			}

} else {
			if (!(AITile.IsBuildableRectangle(AIMap.GetTileIndex(tg[0]-3,tg[1]-1), 7, tracks+1))) { return null; }
			if (!NoWater(AIMap.GetTileIndex(tg[0]-3,tg[1]-1), 7, tracks+1)) { return null; }
			
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]+3,tg[1]+tracks));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]+3,tg[1]-1));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]-2,tg[1]+tracks));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]-2,tg[1]-1));
			
			// check it's flattish
			if (!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] + trainlength,tg[1]+tracks))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] + trainlength - 1,tg[1]-1))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]-2,tg[1]+tracks))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]-1,tg[1]-1)))) { return null; }
			
			//AISign.BuildSign(AIMap.GetTileIndex(tg[0]+trainlength,tg[1]+tracks), "+");
			//AISign.BuildSign(AIMap.GetTileIndex(tg[0]-3,tg[1]-1), "-");
			//AISign.BuildSign(tile,"C" + face);
			
			if (face == 2) {

			tt = AIMap.GetTileIndex(tg[0],tg[1]);
			if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NE_SW, tracks, trainlength, AIStation.STATION_NEW, cargo, AIIndustryType.INDUSTRYTYPE_UNKNOWN, AIIndustry.GetIndustryType(ind), 64, false)) {
			
			go = true; }
			} else {
			
			tt = AIMap.GetTileIndex(tg[0] + 1 - trainlength,tg[1]);
			if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NE_SW, tracks, trainlength, AIStation.STATION_NEW, cargo, AIIndustryType.INDUSTRYTYPE_UNKNOWN, AIIndustry.GetIndustryType(ind), 64, false)) {
			
			go = true; }
			}
}

if (go) { 
if (face == 0) {
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]-1), AIRail.RAILTRACK_NW_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]-2), AIRail.RAILTRACK_NE_SE)

				AIRail.BuildRailDepot(AIMap.GetTileIndex(tg[0]-1,tg[1]-2), AIMap.GetTileIndex(tg[0]+0,tg[1]-2))

				AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+0,tg[1]-1),AIMap.GetTileIndex(tg[0]+0,tg[1]),AIRail.SIGNALTYPE_PBS);
if(tracks == 2) { // limited to 2 tracks for now, but we could theoretically extend this
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]-1), AIRail.RAILTRACK_NW_SE)
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+1,tg[1]-1),AIMap.GetTileIndex(tg[0]+1,tg[1]),AIRail.SIGNALTYPE_PBS);				
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]-2), AIRail.RAILTRACK_SW_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]-2), AIRail.RAILTRACK_NE_SW)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]-2), AIRail.RAILTRACK_NE_SE)
				}
} else if (face == 1) {
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]+1), AIRail.RAILTRACK_NW_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]+2), AIRail.RAILTRACK_NW_NE)
				
				AIRail.BuildRailDepot(AIMap.GetTileIndex(tg[0]-1,tg[1]+2), AIMap.GetTileIndex(tg[0]+0,tg[1]+2))
				
				AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+0,tg[1]+1),AIMap.GetTileIndex(tg[0]+0,tg[1]),AIRail.SIGNALTYPE_PBS);
if(tracks == 2) { // limited to 2 tracks for now, but we could theoretically extend this
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]+1), AIRail.RAILTRACK_NW_SE)				
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIMap.GetTileIndex(tg[0]+1,tg[1]),AIRail.SIGNALTYPE_PBS);				
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]+2), AIRail.RAILTRACK_NW_SW)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]+2), AIRail.RAILTRACK_NE_SW)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]+2), AIRail.RAILTRACK_NW_NE)
				}
} else if (face == 2) {
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-1,tg[1]+0), AIRail.RAILTRACK_NE_SW)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-2,tg[1]+0), AIRail.RAILTRACK_NW_SW)
				
				AIRail.BuildRailDepot(AIMap.GetTileIndex(tg[0]-2,tg[1]-1), AIMap.GetTileIndex(tg[0]-2,tg[1]+0))
				
				AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]-1,tg[1]+0),AIMap.GetTileIndex(tg[0],tg[1]+0),AIRail.SIGNALTYPE_PBS);
if(tracks == 2) { // limited to 2 tracks for now, but we could theoretically extend this
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-1,tg[1]+1), AIRail.RAILTRACK_NE_SW)				
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]-1,tg[1]+1),AIMap.GetTileIndex(tg[0],tg[1]+1),AIRail.SIGNALTYPE_PBS);			
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-2,tg[1]+0), AIRail.RAILTRACK_SW_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-2,tg[1]+0), AIRail.RAILTRACK_NW_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-2,tg[1]+1), AIRail.RAILTRACK_NW_SW)
				}
} else {
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]+0), AIRail.RAILTRACK_NE_SW)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+2,tg[1]+0), AIRail.RAILTRACK_NW_NE)
				
				AIRail.BuildRailDepot(AIMap.GetTileIndex(tg[0]+2,tg[1]-1), AIMap.GetTileIndex(tg[0]+2,tg[1]+0))
				
				AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+1,tg[1]+0),AIMap.GetTileIndex(tg[0],tg[1]+0),AIRail.SIGNALTYPE_PBS);
if(tracks == 2) { // limited to 2 tracks for now, but we could theoretically extend this
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]+1), AIRail.RAILTRACK_NE_SW)				
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIMap.GetTileIndex(tg[0],tg[1]+1),AIRail.SIGNALTYPE_PBS);		
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+2,tg[1]+0), AIRail.RAILTRACK_NE_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+2,tg[1]+0), AIRail.RAILTRACK_NW_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+2,tg[1]+1), AIRail.RAILTRACK_NW_NE)
				}
}

return AIStation.GetStationID(tt) } else { return null; }
}

//==========
function CivilAI::TrainPickup(ind, side, orientation, cargo, tracks, trainlength) {
//===========
// rewritten in v20
local xof;
local yof;
local indloc = AIIndustry.GetLocation(ind);

// updated to v20 standard

if (side == 1) {
xof = 0 // SE
yof = 4
} else if (side == 3) {
xof = 4 // SW
yof = 0
} else if (side == 0) {
xof = 0 // NW
yof = -3
} else {
xof = -3 // NE
yof = 0
}

// clockwise spiral out
local trytilegrid = [AIMap.GetTileX(indloc) + xof,AIMap.GetTileY(indloc) + yof] // we're making assumptions about industry size here
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
if (AITileList_IndustryProducing(ind, 4).HasItem(trytile)) {
NewStat = BuildPickup(trytile, orientation, cargo, ind, tracks, trainlength);
if (NewStat != null) { return NewStat; } 
}
} 
//x--;
for (;x >= 0-i;x--) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITileList_IndustryProducing(ind, 4).HasItem(trytile)) {
NewStat = BuildPickup(trytile, orientation, cargo, ind, tracks, trainlength);
if (NewStat != null) { return NewStat; } 
}
} 
//y++;
for (;y <= i;y++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITileList_IndustryProducing(ind, 4).HasItem(trytile)) {
NewStat = BuildPickup(trytile, orientation, cargo, ind, tracks, trainlength);
if (NewStat != null) { return NewStat; } 
}
} 
//x++;
for (;x <= i;x++) {
trytile = AIMap.GetTileIndex(trytilegrid[0]+x,trytilegrid[1]+y);
//AISign.BuildSign(trytile, ".");
if (AITileList_IndustryProducing(ind, 4).HasItem(trytile)) {
NewStat = BuildPickup(trytile, orientation, cargo, ind, tracks, trainlength);
if (NewStat != null) { return NewStat; } 
}
}
i=i+1
}

// failed to build, so -
return false;

}

//======
 function CivilAI::BuildPickup(tile, face, cargo, ind, tracks, trainlength) {
 //=====
 // updated to v20 spec!
 
local go = false;
local tg = [AIMap.GetTileX(tile),AIMap.GetTileY(tile)]
local tt = null;
 
// v20 - updated station design/placement

if (face < 2) { // station oriented on y axis
			if (!(AITile.IsBuildableRectangle(AIMap.GetTileIndex(tg[0]-1,tg[1]-3), tracks+1, trainlength + 4))) { return null; }
			if (!NoWater(AIMap.GetTileIndex(tg[0]-1,tg[1]-3), tracks+1, trainlength + 4)) { return null; }
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]+tracks,tg[1] + trainlength));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]-0,tg[1] + trainlength));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]+tracks,tg[1]-2));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]-0,tg[1]-2));
			
			// check it's flattish
			if (!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]+tracks,tg[1] + trainlength))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]-0,tg[1] + trainlength - 1))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]+tracks,tg[1]-2))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]-0,tg[1]-1)))) { return null; }
			
			//AISign.BuildSign(AIMap.GetTileIndex(tg[0]+tracks,tg[1] + trainlength), "+");
			//AISign.BuildSign(AIMap.GetTileIndex(tg[0]-0,tg[1]-3), "-");
			//AISign.BuildSign(tile "C" + face);

			if (face == 0) {
			tt = AIMap.GetTileIndex(tg[0],tg[1]);
			if (AIRail.BuildNewGRFRailStation(tt ,AIRail.RAILTRACK_NW_SE,tracks,trainlength,AIStation.STATION_NEW,cargo,AIIndustry.GetIndustryType(ind), AIIndustryType.INDUSTRYTYPE_UNKNOWN, 64, true)) {
			
			go = true; }
			} else {
			
			tt = AIMap.GetTileIndex(tg[0],tg[1] + 1 - trainlength);
			if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NW_SE,tracks,trainlength,AIStation.STATION_NEW,cargo,AIIndustry.GetIndustryType(ind), AIIndustryType.INDUSTRYTYPE_UNKNOWN, 64, true)) {
			
			go = true; }
			}

} else {
			if (!(AITile.IsBuildableRectangle(AIMap.GetTileIndex(tg[0]-3,tg[1]-1), trainlength + 4, tracks+1))) { return null; }
			if (!NoWater(AIMap.GetTileIndex(tg[0]-3,tg[1]-1), trainlength + 4, tracks+1)) { return null; }
			
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]+trainlength,tg[1]+tracks));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]+trainlength,tg[1]-0));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]-2,tg[1]+tracks));
			AITile.LevelTiles(tile,AIMap.GetTileIndex(tg[0]-2,tg[1]-0));
			
			// check it's flattish
			if (!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]+trainlength,tg[1]+tracks))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]+trainlength-1,tg[1]-0))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]-2,tg[1]+tracks))) ||
				!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0]-1,tg[1]-0)))) { return null; }
			
			//AISign.BuildSign(AIMap.GetTileIndex(tg[0] + trainlength,tg[1]+tracks), "+");
			//AISign.BuildSign(AIMap.GetTileIndex(tg[0]-3,tg[1]-0), "-");
			//AISign.BuildSign(tile,"C" + face);
			
			if (face == 2) {

			tt = AIMap.GetTileIndex(tg[0],tg[1]);
			if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NE_SW,tracks,trainlength,AIStation.STATION_NEW,cargo,AIIndustry.GetIndustryType(ind), AIIndustryType.INDUSTRYTYPE_UNKNOWN, 64, true)) {
			
			go = true; }
			} else {
			
			tt = AIMap.GetTileIndex(tg[0] + 1 - trainlength,tg[1]);
			if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NE_SW,tracks,trainlength,AIStation.STATION_NEW,cargo,AIIndustry.GetIndustryType(ind), AIIndustryType.INDUSTRYTYPE_UNKNOWN, 64, true)) {
			
			go = true; }
			}
}

if (go) { 
if (face == 0) {
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]-1), AIRail.RAILTRACK_NW_SE)
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+0,tg[1]-1),AIMap.GetTileIndex(tg[0]+0,tg[1]),AIRail.SIGNALTYPE_PBS);
				
				if(tracks == 2) { // limited to 2 tracks for now, but we could theoretically extend this
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]-1), AIRail.RAILTRACK_NW_SE)
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+1,tg[1]-1),AIMap.GetTileIndex(tg[0]+1,tg[1]),AIRail.SIGNALTYPE_PBS);				
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]-2), AIRail.RAILTRACK_SW_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]-2), AIRail.RAILTRACK_NE_SE)
				}
} else if (face == 1) {
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]+1), AIRail.RAILTRACK_NW_SE)				
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+0,tg[1]+1),AIMap.GetTileIndex(tg[0]+0,tg[1]),AIRail.SIGNALTYPE_PBS);

				if(tracks == 2) { // limited to 2 tracks for now, but we could theoretically extend this
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]+1), AIRail.RAILTRACK_NW_SE)				
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIMap.GetTileIndex(tg[0]+1,tg[1]),AIRail.SIGNALTYPE_PBS);				
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+0,tg[1]+2), AIRail.RAILTRACK_NW_SW)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]+2), AIRail.RAILTRACK_NW_NE)
				}
} else if (face == 2) {
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-1,tg[1]+0), AIRail.RAILTRACK_NE_SW)				
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]-1,tg[1]+0),AIMap.GetTileIndex(tg[0],tg[1]+0),AIRail.SIGNALTYPE_PBS);

				if(tracks == 2) { // limited to 2 tracks for now, but we could theoretically extend this
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-1,tg[1]+1), AIRail.RAILTRACK_NE_SW)				
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]-1,tg[1]+1),AIMap.GetTileIndex(tg[0],tg[1]+1),AIRail.SIGNALTYPE_PBS);			
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-2,tg[1]+0), AIRail.RAILTRACK_SW_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]-2,tg[1]+1), AIRail.RAILTRACK_NW_SW)
				}
} else {
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]+0), AIRail.RAILTRACK_NE_SW)				
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+1,tg[1]+0),AIMap.GetTileIndex(tg[0],tg[1]+0),AIRail.SIGNALTYPE_PBS);
				if(tracks == 2) { // limited to 2 tracks for now, but we could theoretically extend this
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+1,tg[1]+1), AIRail.RAILTRACK_NE_SW)				
				   AIRail.BuildSignal(AIMap.GetTileIndex(tg[0]+1,tg[1]+1),AIMap.GetTileIndex(tg[0],tg[1]+1),AIRail.SIGNALTYPE_PBS);		
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+2,tg[1]+0), AIRail.RAILTRACK_NE_SE)
				AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0]+2,tg[1]+1), AIRail.RAILTRACK_NW_NE)
				}
}

return AIStation.GetStationID(tt) } else { return null; }
}




// ====================================================== 
//                  BUILD RAIL CONNECTIONS
// ====================================================== 

function CivilAI::BuildALine(a,b) {

AILog.Info("I'm building a rail line!")


local p1 = null;
local p2 = null;
local bx = null;
local by = null;
local p1a = null;
local p2a = null;
local p1s = null;
local p2s = null;
local p2sig = null;
local p2sig2 = null;
local pcount = 0;
local uphill = 0;
local uptick = 10;
local hoick = null;

//AISign.BuildSign(a[0][0], "a")
//AISign.BuildSign(b[0][0], "b " + BackTrackCounter)

local buildrail = RailPF();
buildrail._max_cost = 10000000;
buildrail._cost_tile = 100;
buildrail._cost_diagonal_tile = 100; // 70;
buildrail._cost_turn = 40; // 50;
buildrail._cost_slope = 300; // 100;
buildrail._cost_bridge_per_tile = 300;
buildrail._cost_tunnel_per_tile = 110; // 120;
buildrail._cost_coast = 100; // 20;
buildrail._max_bridge_length = 60; // 6; !!
buildrail._max_tunnel_length = 20; // 6;

buildrail.InitializePath(a, b);

local built = false;
local path = false;
local i = 0;
local maxtime = TrainRange * 20; // increase max time
local percount = 0;

// cash down
CashDown();

while (path == false) {
  path = buildrail.FindPath(20);
  AIController.Sleep(1);
//AILog.Info(i)
   i++
   
if (((i * 10) / maxtime) > percount) {percount++; AILog.Info(percount * 10 + "%");}
   if (i > maxtime) {
   AILog.Info("I couldn't find a path.")
   return;  
   }  
}

// cash up
CashUp();


local prev = null;
local prevprev = null;
local prevprevprev = null;
local p4prev = null; //!
local p5prev = null; //!


while (path != null) {
  if (prevprev != null) {
    if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
      if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
        AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev);
      } else {
        local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
        bridge_list.Valuate(AIBridge.GetMaxSpeed);
        bridge_list.Sort(AIList.SORT_BY_VALUE, false);
        AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile());
      }
      prevprev = prev;
      prev = path.GetTile();
      path = path.GetParent();
    } else {
      if (AIRail.BuildRail(prevprev, prev, path.GetTile())) {
	  
	  built = true; // we actually managed to build something!
	// AILog.Info("All is fine")
	
	// calculate the hillclimb
	if (hoick == null) {hoick = AITile.GetMaxHeight(prev);}
	if ((AITile.GetMaxHeight(prev) > hoick) &&
		((AIRail.GetRailTracks(prev) == AIRail.RAILTRACK_NE_SW) ||
		(AIRail.GetRailTracks(prev) == AIRail.RAILTRACK_NW_SE))
	) {	
			uphill = uphill + uptick + 5;
			uptick = 10;
			hoick = AITile.GetMaxHeight(prev);
	}
	if ((AITile.GetMaxHeight(prev) < hoick) &&
		((AIRail.GetRailTracks(prev) == AIRail.RAILTRACK_NE_SW) ||
		(AIRail.GetRailTracks(prev) == AIRail.RAILTRACK_NW_SE))	
	) {hoick = AITile.GetMaxHeight(prev);}
	if (uptick > 0) {uptick--;} else {uphill = 0;}
	if (uphill > HillClimb) 
			{HillClimb = uphill; 
			//AISign.BuildSign(prev, HillClimb + "");
	}	
	  } else {
			if (AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY) {
			AILog.Info("A vehicle was in the way!")
			local c = 0;
			
			while (c < 10) {			
			AIController.Sleep(10);
			AILog.Info("Retrying...")
			c++;
			if (AIRail.BuildRail(prevprev, prev, path.GetTile())) {break;}			
			}
			if (c == 10) {AILog.Info("It's all gone wrong..."); return false;}
			
			} else {
			
			if (AIError.GetLastError() == AIError.ERR_AREA_NOT_CLEAR) {
			AITile.DemolishTile(prev);
			//AISign.BuildSign(prev, "boom");
			}
			
			if ((BackTrackCounter < 5) && (p5prev != null)) {
									BackTrackCounter++;	
									AITile.DemolishTile(prevprev);
									AITile.DemolishTile(prevprevprev);
									AITile.DemolishTile(p4prev);
									
						// abort if we're going to end at bridge or tunnel
							if(AITunnel.IsTunnelTile(p4prev) || AIBridge.IsBridgeTile(p4prev)){
									BackTrackCounter = 0;
									AILog.Info("It's all gone wrong...");
									return false;	
								}
									
									
						local retar;			
						local p4grid = [AIMap.GetTileX(p4prev),AIMap.GetTileY(p4prev)];
						local p5grid = [AIMap.GetTileX(p5prev),AIMap.GetTileY(p5prev)];			
								
						if (p4grid[0] == p5grid[0]) {
								// retrying on the x axis
								AIRail.BuildRailTrack(p4prev, AIRail.RAILTRACK_NW_SE)
								if (p4grid[1] > p5grid[1]) {
								retar = AIMap.GetTileIndex(p4grid[0],p4grid[1] + 1);
								} else {
								retar = AIMap.GetTileIndex(p4grid[0],p4grid[1] - 1);
								}
						} else {
								// retrying on the y axis
								AIRail.BuildRailTrack(p4prev, AIRail.RAILTRACK_NE_SW)
								if (p4grid[0] > p5grid[0]) {
								retar = AIMap.GetTileIndex(p4grid[0] + 1,p4grid[1]);
								} else {                            
								retar = AIMap.GetTileIndex(p4grid[0] - 1,p4grid[1]);
								}
						}		
									
									if (BuildALine(a, [[retar, p4prev]])) {return true;} else {return false;} // recursive much?
									} else {			
									BackTrackCounter = 0;
									AILog.Info("It's all gone wrong...");
									return false;	
			}
		}	
	  }
	}

  }
  if (path != null) {
	p5prev = p4prev;
  	p4prev = prevprevprev;
	prevprevprev = prevprev;
    prevprev = prev;
    prev = path.GetTile();
    path = path.GetParent();
  }
}

//AILog.Info("I've finished rail building for now.")
return built;
}



 // That's all folks.



