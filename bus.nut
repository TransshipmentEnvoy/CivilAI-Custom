//<
// ====================================================== 
// ====================================================== 
//      		   BBBB     U    U    SSSS
//     			   B   BB   U    U   SS   S
//      		   BBBBB    U    U     SS
//       		   B   BB   U    U   S   SS
//       		   BBBB      UUUU     SSSS
// ====================================================== 
// ====================================================== 
//>
// ====================================================== 
//                     BUILD BUS ROUTE
// ====================================================== 

function CivilAI::BuildBuses(town, depot) {
    AILog.Info("I'm going to provide local bus services in " + AITown.GetName(town) + ".");

    local HasBus;
    local statc = null;
    local statn = null;
    local state = null;
    local statw = null;
    local stats = null;

    local statcount = 0;
    local route1;
    local route2;

    // check if we have buses

    HasBus = IdentifyBus(false, false, FindCargo("PASS"));
    if (HasBus == null) {
        return
    }

    // build central bus stop

    statc = BuildBusStop(0, 0, 2, 3, town, false, false);

    if (statc == null) {
        AILog.Info("I've failed to build a central bus stop in " + AITown.GetName(town) + ". Better luck next decade, perhaps.");
        DudBusNetwork.AddItem(town, AIDate.GetYear(AIDate.GetCurrentDate()));

        return
    } else {
        AILog.Info("I've built a central bus stop: " + AIBaseStation.GetName(statc) + ".");
    }


    // build outer bus stops

    local bias;

    bias = AIBase.RandRange(10) - 5;
    statn = BuildBusStop(-10, bias, 1, 6, town, false, true);

    if (statn != null) {
        AILog.Info("I've built a northern bus stop: " + AIBaseStation.GetName(statn) + ".");
        statcount++
    }

    bias = AIBase.RandRange(10) - 5;
    state = BuildBusStop(bias, 10, 1, 6, town, false, true);

    if (state != null) {
        AILog.Info("I've built an eastern bus stop: " + AIBaseStation.GetName(state) + ".");
        statcount++
    }

    bias = AIBase.RandRange(10) - 5;
    stats = BuildBusStop(10, bias, 1, 6, town, false, true);

    if (stats != null) {
        AILog.Info("I've built a southern bus stop: " + AIBaseStation.GetName(stats) + ".");
        statcount++
    }

    bias = AIBase.RandRange(10) - 5;
    statw = BuildBusStop(bias, -10, 1, 6, town, false, true);

    if (statw != null) {
        AILog.Info("I've built a western bus stop: " + AIBaseStation.GetName(statw) + ".");
        statcount++
    }

    // okay, let's see what we've got here; time to construct some routes!

    if (statcount == 4) {

        AILog.Info("I've built five bus stops in " + AITown.GetName(town) + " - great!");

        CreateRoute(HasBus, 1, [statn, statc, stats, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        CreateRoute(HasBus, 1, [statw, statc, state, statc], depot, (AITown.GetName(town)), false, 0, 0, false);

    } else if (statcount == 3) {

        AILog.Info("Four stops, that's nice.");

        //identify the missing stop and do routes
        if (statn == null) {
            CreateRoute(HasBus, 2, [state, statc, statw, statc, stats, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        } else if (state == null) {
            CreateRoute(HasBus, 2, [statn, statc, statw, statc, stats, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        } else if (statw == null) {
            CreateRoute(HasBus, 2, [statn, statc, state, statc, stats, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        } else {
            CreateRoute(HasBus, 2, [state, statc, statw, statc, statn, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        }

    } else if (statcount == 2) {

        AILog.Info("I can make a route out of these three stops.");

        if (statn == null && state == null) {
            CreateRoute(HasBus, 1, [statw, statc, stats, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        } else if (statn == null && statw == null) {
            CreateRoute(HasBus, 1, [stats, statc, state, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        } else if (statn == null && stats == null) {
            CreateRoute(HasBus, 1, [statw, statc, state, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        } else if (state == null && statw == null) {
            CreateRoute(HasBus, 1, [statn, statc, stats, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        } else if (state == null && stats == null) {
            CreateRoute(HasBus, 1, [statw, statc, statn, statc], depot, (AITown.GetName(town)), false, 0, 0, false);
        } else if (statw == null && stats == null) {
            CreateRoute(HasBus, 1, [state, statc, statn, statc], depot, (AITown.GetName(town)), false, 0, 0, false);

        }

    } else {
        AILog.Info("I couldn't build enough bus stops in " + AITown.GetName(town) + ". Better luck next decade, perhaps.");
        DudBusNetwork.AddItem(town, (AIDate.GetYear(AIDate.GetCurrentDate())) + 10);
    }
}

// ====================================================== 
//                  BUY INTERCITY BUS
// ====================================================== 

function CivilAI::InterCity() {

    //v20 - we only build intercity buses if both trains and planes are disabled
    //if (!(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_RAIL) && AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_AIR))) { return; }

    local dosh = AICompany.GetBankBalance(Me);
    local nbus = IdentifyBus(true, true, FindCargo("PASS"));

    if (nbus == null) {
        return;
    } else if (dosh > (AIEngine.GetPrice(nbus) * 2)) {

        // check we don't have MaxBus
        if (GroupCount(0) < MaxBus) {

            local HasBus = IdentifyBus(false, true, FindCargo("PASS"));
            if (HasBus == null) {
                return
            }
            AILog.Info("I'm looking for an intercity bus route.");

            local bslist = AIStationList(AIStation.STATION_BUS_STOP);
            bslist.Valuate(AIStation.GetCargoWaiting, 0); //order by pax waiting
            bslist.RemoveBelowValue(10);
            bslist.Valuate(AIBase.RandItem); // shuffle the list

            foreach(stop, z in bslist) {

                if (Exclaves.HasItem(AIStation.GetNearestTown(stop))) { // don't build intercity to exclaves
                    bslist.RemoveItem(stop);
                }

                local vlist = AIVehicleList_Station(stop);
                foreach(veh, z in vlist) {
                    if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_ROAD) {
                        vlist.RemoveItem(veh);
                    }
                }
                if (vlist.Count() > 30) { // remove saturated stops
                    //AILog.Info(AIBaseStation.GetName(stop) + " has too many buses already.");
                    bslist.RemoveItem(stop);
                }
            }
            if (bslist.Count() < 2) {
                AILog.Info("I couldn't find one.");
                return
            }
            local stat1 = bslist.Begin();
            local stat2 = null;
            bslist.RemoveTop(1);
            foreach(stop, z in bslist) {
                if ((AIStation.GetNearestTown(stop)) != (AIStation.GetNearestTown(stat1))) {
                    stat2 = stop
                    break;
                }
            }
            if (stat2 == null) {
                AILog.Info("I couldn't find one.");
                return
            }
            local paxo = (((AIStation.GetCargoWaiting(stat1, 0) + AIStation.GetCargoWaiting(stat2, 0)) / 100) + 1)
            if (paxo > 20) {
                paxo = 20;
            }

            if (paxo == 1) {
                AILog.Info("I'm buying " + paxo + " bus to run from " + (AIBaseStation.GetName(stat1)) + " to " + (AIBaseStation.GetName(stat2)) + ".");
            } else {
                AILog.Info("I'm buying " + paxo + " buses to run from " + (AIBaseStation.GetName(stat1)) + " to " + (AIBaseStation.GetName(stat2)) + ".");
            }

            local depot = HomeDepot;
            local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
            dlist.Valuate(AITile.GetClosestTown);
            dlist.KeepValue(AIStation.GetNearestTown(stat1));
            depot = dlist.Begin();

            CreateRoute(HasBus, paxo, [stat1, stat2], depot, (AITown.GetName(AIStation.GetNearestTown(stat1))), false, 0, 0, false);

        } else {
            AILog.Info("I've already got my maximum number of buses, so I won't build more.")
        }
    } else {
        AILog.Info("I don't have the money for new buses at the moment.")
    }


    return
}


// ====================================================== 
//                BUILD/REMOVE BUS STOP
// ====================================================== 

function CivilAI::BuildBusStop(xoff, yoff, count, spread, town, rem, spike) {

    // clockwise spiral out
    local trytilegrid = [((AIMap.GetTileX(AITown.GetLocation(town))) + xoff), ((AIMap.GetTileY(AITown.GetLocation(town))) + yoff)]
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
    local stat = AIStation.STATION_NEW

    local statcount = 0

    while ((i < spread) && (statcount < count)) {
        //y--
        for (; y >= 0 - i; y--) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y);
            aimx = AIMap.GetTileIndex(trytilegrid[0] + x + 1, trytilegrid[1] + y);
            aimy = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y + 1);
            aimxm = AIMap.GetTileIndex(trytilegrid[0] + x - 1, trytilegrid[1] + y);
            aimym = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y - 1);

            testroad.InitializePath([trytile], [AITown.GetLocation(town)]);
            local path = false;
            while (path == false) {
                path = testroad.FindPath(20);
                AIController.Sleep(1);
            }

            if (rem) {
                AIRoad.RemoveRoadStation(trytile)
            } else
            if ((path != null) && (statcount < count) && (AITile.GetCargoAcceptance(trytile, 0, 1, 1, 3) > 11) && (AIRoad.IsRoadTile(trytile))) {
                if (!AIBridge.IsBridgeTile(aimx) && !AIBridge.IsBridgeTile(aimxm) &&
                    //	(AITile.GetSlope(aimx) == AITile.SLOPE_FLAT) &&
                    //	(AITile.GetSlope(aimxm) == AITile.SLOPE_FLAT) &&
                    ((count > 1) || Clearstop(trytile)) &&
                    AIRoad.BuildDriveThroughRoadStation(trytile, aimx, AIRoad.ROADVEHTYPE_BUS, stat)) {
                    stat = AIStation.GetStationID(trytile), statcount = statcount + 1
                    if (spike) {
                        SpikeX(trytile, town);
                    }
                } else if (!AIBridge.IsBridgeTile(aimy) && !AIBridge.IsBridgeTile(aimym) &&
                    //	(AITile.GetSlope(aimy) == AITile.SLOPE_FLAT) &&
                    //	(AITile.GetSlope(aimym) == AITile.SLOPE_FLAT) &&
                    ((count > 1) || Clearstop(trytile)) &&
                    AIRoad.BuildDriveThroughRoadStation(trytile, aimy, AIRoad.ROADVEHTYPE_BUS, stat)) {
                    stat = AIStation.GetStationID(trytile), statcount = statcount + 1
                    if (spike) {
                        SpikeY(trytile, town);
                    }
                } else if (AIError.GetLastError() == 2310) {
                    AILog.Info("Current Road Type appears to be invalid.");
                    BannedRoadTypes.AddItem(AIRoad.GetCurrentRoadType(), 0);
                    HaveRoadType = SelectRoadType(false);
                }
            }
        }

        //x--;
        for (; x >= 0 - i; x--) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y);
            aimx = AIMap.GetTileIndex(trytilegrid[0] + x + 1, trytilegrid[1] + y);
            aimy = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y + 1);
            aimxm = AIMap.GetTileIndex(trytilegrid[0] + x - 1, trytilegrid[1] + y);
            aimym = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y - 1);

            testroad.InitializePath([trytile], [AITown.GetLocation(town)]);
            local path = false;
            while (path == false) {
                path = testroad.FindPath(20);
                AIController.Sleep(1);
            }
            if (rem) {
                AIRoad.RemoveRoadStation(trytile)
            } else
            if ((path != null) && (statcount < count) && (AITile.GetCargoAcceptance(trytile, 0, 1, 1, 3) > 11) && (AIRoad.IsRoadTile(trytile))) {
                if (!AIBridge.IsBridgeTile(aimx) && !AIBridge.IsBridgeTile(aimxm) &&
                    //	(AITile.GetSlope(aimx) == AITile.SLOPE_FLAT) &&
                    //	(AITile.GetSlope(aimxm) == AITile.SLOPE_FLAT) &&
                    ((count > 1) || Clearstop(trytile)) &&
                    AIRoad.BuildDriveThroughRoadStation(trytile, aimx, AIRoad.ROADVEHTYPE_BUS, stat)) {
                    stat = AIStation.GetStationID(trytile), statcount = statcount + 1
                    if (spike) {
                        SpikeX(trytile, town);
                    }
                } else if (!AIBridge.IsBridgeTile(aimy) && !AIBridge.IsBridgeTile(aimym) &&
                    //	(AITile.GetSlope(aimy) == AITile.SLOPE_FLAT) &&
                    //	(AITile.GetSlope(aimym) == AITile.SLOPE_FLAT) &&
                    ((count > 1) || Clearstop(trytile)) &&
                    AIRoad.BuildDriveThroughRoadStation(trytile, aimy, AIRoad.ROADVEHTYPE_BUS, stat)) {
                    stat = AIStation.GetStationID(trytile), statcount = statcount + 1
                    if (spike) {
                        SpikeY(trytile, town);
                    }
                } else if (AIError.GetLastError() == 2310) {
                    AILog.Info("Current Road Type appears to be invalid.");
                    BannedRoadTypes.AddItem(AIRoad.GetCurrentRoadType(), 0);
                    HaveRoadType = SelectRoadType(false);
                }
            }
        }

        //y++;
        for (; y <= i; y++) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y);
            aimx = AIMap.GetTileIndex(trytilegrid[0] + x + 1, trytilegrid[1] + y);
            aimy = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y + 1);
            aimxm = AIMap.GetTileIndex(trytilegrid[0] + x - 1, trytilegrid[1] + y);
            aimym = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y - 1);

            testroad.InitializePath([trytile], [AITown.GetLocation(town)]);
            local path = false;
            while (path == false) {
                path = testroad.FindPath(20);
                AIController.Sleep(1);
            }
            if (rem) {
                AIRoad.RemoveRoadStation(trytile)
            } else
            if ((path != null) && (statcount < count) && (AITile.GetCargoAcceptance(trytile, 0, 1, 1, 3) > 11) && (AIRoad.IsRoadTile(trytile))) {
                if (!AIBridge.IsBridgeTile(aimx) && !AIBridge.IsBridgeTile(aimxm) &&
                    //	(AITile.GetSlope(aimx) == AITile.SLOPE_FLAT) &&
                    //	(AITile.GetSlope(aimxm) == AITile.SLOPE_FLAT) &&
                    ((count > 1) || Clearstop(trytile)) &&
                    AIRoad.BuildDriveThroughRoadStation(trytile, aimx, AIRoad.ROADVEHTYPE_BUS, stat)) {
                    stat = AIStation.GetStationID(trytile), statcount = statcount + 1
                    if (spike) {
                        SpikeX(trytile, town);
                    }
                } else if (!AIBridge.IsBridgeTile(aimy) && !AIBridge.IsBridgeTile(aimym) &&
                    //	(AITile.GetSlope(aimy) == AITile.SLOPE_FLAT) &&
                    //	(AITile.GetSlope(aimym) == AITile.SLOPE_FLAT) &&
                    ((count > 1) || Clearstop(trytile)) &&
                    AIRoad.BuildDriveThroughRoadStation(trytile, aimy, AIRoad.ROADVEHTYPE_BUS, stat)) {
                    stat = AIStation.GetStationID(trytile), statcount = statcount + 1
                    if (spike) {
                        SpikeY(trytile, town);
                    }
                } else if (AIError.GetLastError() == 2310) {
                    AILog.Info("Current Road Type appears to be invalid.");
                    BannedRoadTypes.AddItem(AIRoad.GetCurrentRoadType(), 0);
                    HaveRoadType = SelectRoadType(false);
                }

            }
        }

        //x++;
        for (; x <= i + 1; x++) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y);
            aimx = AIMap.GetTileIndex(trytilegrid[0] + x + 1, trytilegrid[1] + y);
            aimy = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y + 1);
            aimxm = AIMap.GetTileIndex(trytilegrid[0] + x - 1, trytilegrid[1] + y);
            aimym = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y - 1);

            testroad.InitializePath([trytile], [AITown.GetLocation(town)]);
            local path = false;
            while (path == false) {
                path = testroad.FindPath(20);
                AIController.Sleep(1);
            }
            if (rem) {
                AIRoad.RemoveRoadStation(trytile)
            } else
            if ((path != null) && (statcount < count) && (AITile.GetCargoAcceptance(trytile, 0, 1, 1, 3) > 11) && (AIRoad.IsRoadTile(trytile))) {
                if (!AIBridge.IsBridgeTile(aimx) && !AIBridge.IsBridgeTile(aimxm) &&
                    //	(AITile.GetSlope(aimx) == AITile.SLOPE_FLAT) &&
                    //	(AITile.GetSlope(aimxm) == AITile.SLOPE_FLAT) &&
                    ((count > 1) || Clearstop(trytile)) &&
                    AIRoad.BuildDriveThroughRoadStation(trytile, aimx, AIRoad.ROADVEHTYPE_BUS, stat)) {
                    stat = AIStation.GetStationID(trytile), statcount = statcount + 1
                    if (spike) {
                        SpikeX(trytile, town);
                    }
                } else if (!AIBridge.IsBridgeTile(aimy) && !AIBridge.IsBridgeTile(aimym) &&
                    //	(AITile.GetSlope(aimy) == AITile.SLOPE_FLAT) &&
                    //	(AITile.GetSlope(aimym) == AITile.SLOPE_FLAT) &&
                    ((count > 1) || Clearstop(trytile)) &&
                    AIRoad.BuildDriveThroughRoadStation(trytile, aimy, AIRoad.ROADVEHTYPE_BUS, stat)) {
                    stat = AIStation.GetStationID(trytile), statcount = statcount + 1
                    if (spike) {
                        SpikeY(trytile, town);
                    }
                } else if (AIError.GetLastError() == 2310) {
                    AILog.Info("Current Road Type appears to be invalid.");
                    BannedRoadTypes.AddItem(AIRoad.GetCurrentRoadType(), 0);
                    HaveRoadType = SelectRoadType(false);
                }

            }
        }
        i = i + 1
    }
    if (statcount > 0) {

        // try and put a truckstop for water, if required
        local c = FindCargo("WATR");
        if (c != null) {
            local towerlist = AIIndustryList_CargoAccepting(c);
            foreach(tower, z in towerlist) {
                if (AITileList_IndustryAccepting(tower, 3).HasItem(AIBaseStation.GetLocation(stat))) {
                    BuildTruckStop(stat, AIBaseStation.GetLocation(stat))
                }
            }
        }


        return stat
    } else {
        return null
    }
}


function CivilAI::Clearstop(tile) {

    local tilegrid = [AIMap.GetTileX(tile), AIMap.GetTileY(tile)];

    for (local x = -4; x < 5; x++) {
        for (local y = -4; y < 5; y++) {

            local testtile = AIMap.GetTileIndex(tilegrid[0] + x, tilegrid[1] + y);
            //AISign.BuildSign(testtile, "?");
            if ((AIRoad.IsRoadStationTile(testtile) ||
                    AIRoad.IsDriveThroughRoadStationTile(testtile))) {
                //	AISign.BuildSign(testtile, "!!!!!!!!!!");
                return null; // we found another bus stop too close
            }
        }
    }
    return true; // no bus stop found
}


// ====================================================== 
//                BUILD TURNAROUND SPIKES
// ====================================================== 

function CivilAI::SpikeX(tile, town) {
    local x = AIMap.GetTileX(tile)
    local y = AIMap.GetTileY(tile)
    local townx = AIMap.GetTileX(AITown.GetLocation(town))

    if (true) {

        AIRoad.BuildRoad(
            AIMap.GetTileIndex(x + 1, y),
            tile
        );
        AIRoad.BuildRoad(
            AIMap.GetTileIndex(x - 1, y),
            tile
        );

        BuildARoad([AIMap.GetTileIndex(x + 1, y)], [AITown.GetLocation(town)], -1, 3000, false);
        BuildARoad([AIMap.GetTileIndex(x - 1, y)], [AITown.GetLocation(town)], -1, 3000, false);


    } else {
        // fallback to old cross building

        if (x >= townx) {
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x + 1, y + 1),
                AIMap.GetTileIndex(x + 1, y)
            );
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x + 1, y - 1),
                AIMap.GetTileIndex(x + 1, y)
            );
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x + 2, y),
                tile
            );
        } else {
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x - 1, y + 1),
                AIMap.GetTileIndex(x - 1, y)
            );
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x - 1, y - 1),
                AIMap.GetTileIndex(x - 1, y)
            );
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x - 2, y),
                tile
            );
        }
    }
    return;
}

function CivilAI::SpikeY(tile, town) {
    local x = AIMap.GetTileX(tile)
    local y = AIMap.GetTileY(tile)
    local towny = AIMap.GetTileY(AITown.GetLocation(town))

    // new: try and loop back to the center tile of town
    if (true) {

        AIRoad.BuildRoad(
            AIMap.GetTileIndex(x, y + 1),
            tile
        );
        AIRoad.BuildRoad(
            AIMap.GetTileIndex(x, y - 1),
            tile
        );

        BuildARoad([AIMap.GetTileIndex(x, y + 1)], [AITown.GetLocation(town)], -1, 3000, false);
        BuildARoad([AIMap.GetTileIndex(x, y - 1)], [AITown.GetLocation(town)], -1, 3000, false);

    } else {
        // fallback to old cross building

        if (y >= towny) {
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x + 1, y + 1),
                AIMap.GetTileIndex(x, y + 1)
            );
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x - 1, y + 1),
                AIMap.GetTileIndex(x, y + 1)
            );
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x, y + 2),
                tile
            );
        } else {
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x + 1, y - 1),
                AIMap.GetTileIndex(x, y - 1)
            );
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x - 1, y - 1),
                AIMap.GetTileIndex(x, y - 1)
            );
            AIRoad.BuildRoadFull(
                AIMap.GetTileIndex(x, y - 2),
                tile
            );
        }
    }
    return;
}



// ====================================================== 
//                 REVIEW BUS SERVICES
// ====================================================== 

function CivilAI::BusReview() {

    AILog.Info("I'm reviewing my bus services.");
    local depot = HomeDepot;


    // remove unused stops
    local bslist = AIStationList(AIStation.STATION_BUS_STOP);
    local vlist
    foreach(stop, z in bslist) {
        if (
            !AIStation.HasStationType(stop, AIStation.STATION_TRAIN) &&
            !AIStation.HasStationType(stop, AIStation.STATION_TRUCK_STOP) &&
            !AIStation.HasStationType(stop, AIStation.STATION_AIRPORT) &&
            !AIStation.HasStationType(stop, AIStation.STATION_DOCK)
        ) { // do not remove stops that have other transport modes attached


            vlist = AIVehicleList_Station(stop)
            foreach(veh, z in vlist) {
                if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_ROAD) {
                    vlist.RemoveItem(veh);
                }
            }
            if (vlist.Count() == 0) {
                AILog.Info((AIBaseStation.GetName(stop)) + " has no service. I'll remove the stop.")
                if (!AIRoad.RemoveRoadStation(AIBaseStation.GetLocation(stop))) {
                    BuildBusStop(0, 0, 4, 3, (AIStation.GetNearestTown(stop)), true, false); // remove central stops.
                }
            }
        }
    }

    local dosh = AICompany.GetBankBalance(Me);
    local nbus = IdentifyBus(true, false, FindCargo("PASS"));

    if (nbus == null) {

        return;
    } else if (dosh > (AIEngine.GetPrice(nbus) * 2)) {


        // replacing old buses?
        local buslist = AIVehicleList_Group(Groups[0]);

        foreach(v, z in buslist) {
            if (AIVehicle.GetAgeLeft(v) < (365 * 1)) {

                // clone the old bus

                local upbus;

                // compare orders; if first two orders are in different towns, build a coach instead of a bus
                local order1 = AIOrder.GetOrderDestination(v, 0)
                local order2 = AIOrder.GetOrderDestination(v, 1)
                if (AITile.GetClosestTown(order1) == AITile.GetClosestTown(order2)) {
                    upbus = IdentifyBus(true, false, FindCargo("PASS"));
                } else {
                    upbus = IdentifyBus(true, true, FindCargo("PASS"));
                }

                // pick random depot in the town to build in (1.9, allows functioning with no road network)
                depot = HomeDepot;
                local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
                dlist.Valuate(AITile.GetClosestTown);
                dlist.KeepValue(AITile.GetClosestTown(order1));
                depot = dlist.Begin();


                local clonebus = AIVehicle.BuildVehicle(depot, upbus)
                if (AIVehicle.IsValidVehicle(clonebus)) {
                    //AILog.Info("I've bought a replacement for " + (AIVehicle.GetName(v)) + ".")
                    AIOrder.ShareOrders(clonebus, v);
                    local nx = 0
                    local name = null
                    local changename = false

                    local stopp = (AIStation.GetStationID(AIOrder.GetOrderDestination(v, 0)));

                    while (!changename && (nx < 1000)) {
                        nx++
                        name = ((AITown.GetName(AIStation.GetNearestTown(stopp))) + " " + nx)
                        changename = AIVehicle.SetName(clonebus, name)
                    }
                    AIOrder.SkipToOrder(clonebus, AIBase.RandRange(6));
                    AIGroup.MoveVehicle(Groups[0], clonebus); // add to appropriate group
                    AIVehicle.StartStopVehicle(clonebus);

                    AIVehicle.SendVehicleToDepot(v);
                    AILog.Info(AIVehicle.GetName(v) + " is getting old, so I'm replacing it.")

                } else {
                    AILog.Info("For some reason (probably not enough money), I couldn't buy a replacement for " + (AIVehicle.GetName(v)) + ".")
                }
            }
        }



        // do we want to add more buses?

        // check we don't have MaxBus
        if (GroupCount(0) < MaxBus) {


            local blist
            local clonebus
            local obus
            local upbus
            local bslist = AIStationList(AIStation.STATION_BUS_STOP);

            // bus review
            foreach(stop, z in bslist) {
                if ((AIStation.GetCargoWaiting(stop, 0) > 500) &&
                    AIStation.GetCargoRating(stop, 0) < 60
                ) {
                    // find a bus that uses this stop and copy it
                    //AILog.Info("Assessing " + AIStation.GetName(stop) + ".")
                    blist = AIVehicleList_Group(Groups[0]);
                    blist.KeepList(AIVehicleList_Station(stop));

                    foreach(b, z in blist) {
                        // don't duplicate buses which are transferring to here!

                        local o = 0;

                        while (AIOrder.IsValidVehicleOrder(b, o)) {
                            if (AIStation.GetStationID(AIOrder.GetOrderDestination(b, o)) == stop &&
                                (AIOrder.GetOrderFlags(b, o) & AIOrder.OF_TRANSFER) == AIOrder.OF_TRANSFER) {
                                //AILog.Info(AIVehicle.GetName(b) + " is transferring.")
                                blist.RemoveItem(b);
                            }
                            o++
                        }
                    }



                    if (blist.Count() < 10) { // don't build more in saturated stops	
                        if (blist.Count() > 0) {
                            foreach(b, z in blist) {

                                // remove coaches from the list, to bias towards adding local buses
                                local order1 = AIOrder.GetOrderDestination(b, 0)
                                local order2 = AIOrder.GetOrderDestination(b, 1)

                                if ((AITile.GetClosestTown(order1) != AITile.GetClosestTown(order2))
                                    //&& (AIBase.RandRange(4) == 0) 
                                    &&
                                    (blist.Count() > 1)) {
                                    blist.RemoveItem(b);
                                }
                            }

                            blist.Valuate(AIBase.RandItem); // shuffle the list
                            obus = blist.Begin();
                            // compare orders; if first two orders are in different towns, build a coach instead of a bus
                            local order1 = AIOrder.GetOrderDestination(obus, 0)
                            local order2 = AIOrder.GetOrderDestination(obus, 1)
                            if (AITile.GetClosestTown(order1) == AITile.GetClosestTown(order2)) {
                                upbus = IdentifyBus(true, false, FindCargo("PASS"));
                            } else {
                                upbus = IdentifyBus(true, true, FindCargo("PASS"));
                            }

                            // pick random depot in the town to build in (1.9, allows functioning with no road network)
                            depot = HomeDepot;
                            local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
                            dlist.Valuate(AITile.GetDistanceManhattanToTile, AITown.GetLocation(AITile.GetClosestTown(order1)));
                            dlist.Sort(AIList.SORT_BY_VALUE, true);
                            depot = dlist.Begin();


                            if (AIVehicle.IsValidVehicle(obus)) {
                                clonebus = AIVehicle.BuildVehicle(depot, upbus)
                                if (AIVehicle.IsValidVehicle(clonebus)) {
                                    AILog.Info("I've bought another vehicle for " + AITown.GetName(AIStation.GetNearestTown(stop)) + ".")
                                    AIOrder.ShareOrders(clonebus, obus);
                                    local nx = 0
                                    local name = null
                                    local changename = false

                                    while (!changename && (nx < 1000)) {
                                        nx++
                                        name = ((AITown.GetName(AIStation.GetNearestTown(stop))) + " " + nx)
                                        changename = AIVehicle.SetName(clonebus, name)
                                    }
                                    AIOrder.SkipToOrder(clonebus, AIBase.RandRange(6));
                                    AIGroup.MoveVehicle(Groups[0], clonebus); // add to appropriate group
                                    if (AIOrder.IsValidVehicleOrder(clonebus, 1)) { // Since the mail truck update, occasionally we built an intercity bus with no orders. I could find the bug, but easier just to quietely sell the vehicles back.
                                        AIVehicle.StartStopVehicle(clonebus);
                                    } else {
                                        AILog.Info("Oops");
                                        AIVehicle.SellVehicle(clonebus);
                                    }
                                }
                            } else {
                                AILog.Info("For some reason (probably not enough money), I couldn't buy a vehicle for " + AITown.GetName(AIStation.GetNearestTown(stop)) + ".")
                            }
                        } else {
                            //AILog.Info("No buses to duplicate at " + AITown.GetName(AIStation.GetNearestTown(stop)) + ".")
                        }
                    } else {
                        // AILog.Info("I won't buy another vehicle for " + (AIBaseStation.GetName(stop)) + ", because it's already crowded.")
                    }
                }
            }
        } else {
            AILog.Info("I've already got my maximum number of buses, so I won't build more.")
        }
    } else {
        AILog.Info("I don't have the money for new buses at the moment.")
    }


    // do we want to remove unprofitable buses?

    local rvlist = AIVehicleList();
    foreach(veh, z in rvlist) {
        if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_ROAD) {
            rvlist.RemoveItem(veh);
        }
    }

    for (local v = rvlist.Begin(); !(rvlist.IsEnd()); v = rvlist.Next()) {
        if ((AIVehicle.GetProfitLastYear(v) < 0) &&
            (AIVehicle.GetProfitThisYear(v) < 0) &&
            //	(AIVehicle.GetCapacity(v,0) > 9) &&
            (AIVehicle.GetAge(v) > (365 * 2))) {
            AIVehicle.SendVehicleToDepot(v);
            AILog.Info(AIVehicle.GetName(v) + " is losing money, so I'm sending it to the depot.")
        }
    }

    if (AICargo.GetDistributionType(FindCargo("PASS")) == AICargo.DT_MANUAL) {
        BusTransfers();
    }

    return;
}




// ====================================================== 
//               BUILD ADDITIONAL NETWORKS
// ====================================================== 

function CivilAI::NewNetwork() {

    local dosh = AICompany.GetBankBalance(Me);
    local nbus = IdentifyBus(true, false, FindCargo("PASS"));

    if (nbus == null) {
        return;
    } else if (dosh > (AIEngine.GetPrice(nbus) * 3)) {

        // check we don't have MaxBus
        if (GroupCount(0) < MaxBus) {

            AILog.Info("I'm looking for a town to build a new bus network in.");

            // find a town

            local townlist = AIList();
            townlist.AddList(Cachedtowns);
            townlist.AddList(Exclaves);
            townlist.Valuate(AITown.GetPopulation);
            townlist.RemoveBelowValue(MinPop);

            foreach(town, year in DudBusNetwork) {
                if (AIDate.GetYear(AIDate.GetCurrentDate()) < year) {
                    //AILog.Info ("I won't try " + AITown.GetName(town) + " again until " + year +".");
                    townlist.RemoveItem(town);
                } else {
                    //AILog.Info ("I might try " + AITown.GetName(town) + " again.");
                    DudBusNetwork.RemoveItem(town);
                }
            }

            foreach(town, z in townlist) {
                if ((AITown.GetLastMonthSupplied(town, 0) * 20) > AITown.GetPopulation(town)) {
                    townlist.RemoveItem(town); // discard sufficiently serviced towns
                    //AILog.Info("Discarding " + AITown.GetName(town) + " as sufficiently serviced.");

                    // build a depot anyway for our towncars
                    local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
                    foreach(depot, z in dlist) {
                        if (AITile.GetClosestTown(depot) != town) {
                            dlist.RemoveItem(depot);
                        }
                    }
                    if (dlist.Count() == 0) {
                        NewDepot(town, false, 0, 0);
                        //AILog.Info("Building a depot only (for towncars) in " + AITown.GetName(town) + ".");
                    }

                } else {
                    local bslist = AIStationList(AIStation.STATION_BUS_STOP);
                    local bc = 0;
                    foreach(stat, z in bslist) {
                        if (AIStation.GetNearestTown(stat) == (town)) {
                            bc++
                        }
                    }
                    if (bc > 1) { // if we only have one bus stop (eg an airport) we can still build a network.
                        townlist.RemoveItem(town); // discard self-serviced towns
                        //AILog.Info("Discarding " + AITown.GetName(town) + " as self-serviced.");
                    }

                }
            }

            if (townlist.Count() > 0) {
                townlist.Valuate(AIBase.RandItem); // shuffle the town list
                local newtown = townlist.Begin();

                // build a new network. First, check for an existing depot


                local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
                foreach(depot, z in dlist) {
                    if (AITile.GetClosestTown(depot) != newtown) {
                        dlist.RemoveItem(depot);
                    }
                }
                if (dlist.Count() == 0) {
                    NewDepot(newtown, true, 0, 0);
                } else {
                    BuildBuses(newtown, dlist.Begin());
                }

            } else {
                AILog.Info("I couldn't find one.");
            }
        } else {
            AILog.Info("I've already got my maximum number of buses, so I won't build a new network.")
        }
    } else {
        AILog.Info("I don't have the money for a new network at the moment.")
    }
    return
}

//====
function CivilAI::BigCityDepots() {

    local townlist = AIList();
    townlist.AddList(Cachedtowns);
    townlist.AddList(Exclaves);

    //AILog.Info("Building extra depots")

    townlist.Valuate(AITown.GetPopulation);
    townlist.RemoveBelowValue(10000);

    foreach(town, z in townlist) {

        local dlist = AIDepotList(AITile.TRANSPORT_ROAD);
        foreach(depot, z in dlist) {
            if (AITile.GetClosestTown(depot) != town) {
                dlist.RemoveItem(depot);
            }
        }
        if ((dlist.Count() < AITown.GetPopulation(town) / 5000) &&
            (dlist.Count() < 5)) {
            //AILog.Info("Building another depot in " + AITown.GetName(town) + ".")

            local a = AIBase.RandRange(20) - 10;
            local b = AIBase.RandRange(20) - 10;

            NewDepot(town, false, a, b);
        }
    }


}

// ====================================================== 
//          BUILD ADDITIONAL DEPOT FOR NETWORK
// ====================================================== 

function CivilAI::NewDepot(town, buildbuses, offx, offy) {

    // clockwise spiral out
    local trytilegrid = [AIMap.GetTileX(AITown.GetLocation(town)) + offx, AIMap.GetTileY(AITown.GetLocation(town)) + offy]
    local trytile;
    local x = 1
    local y = 1
    local i = 0
    local depot = null;
    while ((depot == null) && (i < 20)) {
        //y--
        for (; y >= 0 - i; y--) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y);
            //AISign.BuildSign(trytile, "?");
            //AILog.Info("testing tile at " + x + "," + y);
            if (AIRoad.IsRoadTile(trytile) &&
                !AIRoad.IsRoadDepotTile(trytile) &&
                !AIRoad.IsRoadStationTile(trytile) &&
                !AIRoad.IsDriveThroughRoadStationTile(trytile) &&
                !AIBridge.IsBridgeTile(trytile) &&
                !depot)
                depot = BuildDepot(trytile, town);
        }
        //x--;
        for (; x >= 0 - i; x--) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y);
            //AISign.BuildSign(trytile, "?");
            //AILog.Info("testing tile at " + x + "," + y);
            if (AIRoad.IsRoadTile(trytile) &&
                !AIRoad.IsRoadDepotTile(trytile) &&
                !AIRoad.IsRoadStationTile(trytile) &&
                !AIRoad.IsDriveThroughRoadStationTile(trytile) &&
                !AIBridge.IsBridgeTile(trytile) &&
                !depot)
                depot = BuildDepot(trytile, town);
        }
        //y++;
        for (; y <= i; y++) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y);
            //AISign.BuildSign(trytile, "?");
            //AILog.Info("testing tile at " + x + "," + y);
            if (AIRoad.IsRoadTile(trytile) &&
                !AIRoad.IsRoadDepotTile(trytile) &&
                !AIRoad.IsRoadStationTile(trytile) &&
                !AIRoad.IsDriveThroughRoadStationTile(trytile) &&
                !AIBridge.IsBridgeTile(trytile) &&
                !depot)
                depot = BuildDepot(trytile, town);
        }
        //x++;
        for (; x <= i; x++) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + x, trytilegrid[1] + y);
            //AISign.BuildSign(trytile, "?");
            //AILog.Info("testing tile at " + x + "," + y);
            if (AIRoad.IsRoadTile(trytile) &&
                !AIRoad.IsRoadDepotTile(trytile) &&
                !AIRoad.IsRoadStationTile(trytile) &&
                !AIRoad.IsDriveThroughRoadStationTile(trytile) &&
                !AIBridge.IsBridgeTile(trytile) &&
                !depot)
                depot = BuildDepot(trytile, town);
        }
        i++
    }

    if (depot != null) {
        //AISign.BuildSign(depot, "!");
        AILog.Info("I've built a new depot in " + AITown.GetName(town) + ".");
        if (buildbuses) {
            BuildBuses(town, depot);
        }
        return depot;
    } else {
        AILog.Info("I couldn't find a suitable location for a depot in " + AITown.GetName(town) + " (Road Type " + AIRoad.GetCurrentRoadType() + ").");
        return null;
    }
}