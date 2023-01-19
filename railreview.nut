// ====================================================== 
// ====================================================== 
// 			  RRRR     A    I  L
// 			  R   R   A A   I  L
// 			  R  R   A   A  I  L
//  		  RRRR   AAAAA  I  L
//  		  R   R  A   A  I  LLLLL
// ========================Review, upgrade and removal!== 
// ====================================================== 

function CivilAI::RailReview() {

    RailCleanUp();

    AILog.Info("I'm reviewing my train services...")
    ReviewTrains();
}

function CivilAI::ReviewTrains() {

    local dosh = AICompany.GetBankBalance(Me);
    local tslist = AIStationList(AIStation.STATION_TRAIN);
    foreach(stat, z in tslist) {

        local tlist = AIVehicleList_Station(stat);
        tlist.Valuate(AIVehicle.GetVehicleType);
        tlist.KeepValue(AIVehicle.VT_RAIL);

        if (tlist.Count() < 4 && tlist.Count() > 0 && GetPlatCount(stat) > 1) {
            local clist = AICargoList();
            foreach(c, z in clist) {
                if (AIStation.HasCargoRating(stat, c) &&
                    AIStation.GetCargoRating(stat, c) < 50 &&
                    c != FindCargo("MAIL")) {
                    tlist.Valuate(AIVehicle.GetCapacity, c);
                    tlist.KeepAboveValue(0);
                    tlist.Valuate(AIVehicle.GetProfitLastYear);
                    tlist.Sort(AIList.SORT_BY_VALUE, false);
                    local t = tlist.Begin();
                    if (AIVehicle.GetProfitLastYear(t) > AIEngine.GetPrice(AIVehicle.GetEngineType(t)) / 4 && !AIOrder.IsGotoDepotOrder(t, 0)) {
                        AILog.Info("I'm considering an additional train at " + AIStation.GetName(stat) + ".")
                        local a = AIStation.GetStationID(AIOrder.GetOrderDestination(t, 0));
                        local b = AIStation.GetStationID(AIOrder.GetOrderDestination(t, 1));
                        local depot = FindTrainDepot(b);
                        local tl = GetStatLength(a);

                        if (depot != null && dosh > BuyATrain(b, a, c, depot, tl, true, AIEngine.GetPower(AIVehicle.GetEngineType(t)))) {
                            local newtrain = BuyATrain(b, a, c, depot, tl, false, AIEngine.GetPower(AIVehicle.GetEngineType(t)))
                        }
                    }
                }
            }
        }
    }
}


//==================================================================
// Convert rail types
//==================================================================

function CivilAI::Electrify(depot, type) {
    AILog.Info("Upgrading tracks...")

    if (AIRail.IsRailDepotTile(depot)) {
        AIRail.ConvertRailType(depot, depot, type); // convert the depot
        PowerWalk(AIRail.GetRailDepotFrontTile(depot), type);
    } else if (AIRail.IsRailStationTile(depot)) {
        local stlist = AITileList_StationType(AIStation.GetStationID(depot), AIStation.STATION_TRAIN)
        foreach(t, z in stlist) {
            PowerWalk(t, type);
        }
    }

    AILog.Info("Upgrade complete!")
}

function CivilAI::PowerWalk(t, type) {

    local a = (AIMap.GetTileIndex(AIMap.GetTileX(t) + 0, AIMap.GetTileY(t) - 1));
    local b = (AIMap.GetTileIndex(AIMap.GetTileX(t) + 0, AIMap.GetTileY(t) + 1));
    local c = (AIMap.GetTileIndex(AIMap.GetTileX(t) - 1, AIMap.GetTileY(t) + 0));
    local d = (AIMap.GetTileIndex(AIMap.GetTileX(t) + 1, AIMap.GetTileY(t) + 0));

    if (AIRail.GetRailType(a) != type &&
        AITile.GetOwner(a) == Me && (
            (AITunnel.IsTunnelTile(a) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(a)) == AIMap.GetTileX(a)) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(a)) < AIMap.GetTileY(a))) ||
            (AIBridge.IsBridgeTile(a) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(a)) == AIMap.GetTileX(a)) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(a)) < AIMap.GetTileY(a))) ||
            (AIRail.IsRailTile(a) && ((AIRail.GetRailTracks(a) & (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_SW_SE + AIRail.RAILTRACK_NE_SE)) != 0)) ||
            AIRail.IsRailDepotTile(a) ||
            AIRail.IsRailStationTile(a))) {

        a = ConvertTrack(a, type);
        PowerWalk(a, type);
    }
    if (AIRail.GetRailType(b) != type &&
        AITile.GetOwner(b) == Me && (
            (AITunnel.IsTunnelTile(b) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(b)) == AIMap.GetTileX(b)) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(b)) > AIMap.GetTileY(b))) ||
            (AIBridge.IsBridgeTile(b) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(b)) == AIMap.GetTileX(b)) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(b)) > AIMap.GetTileY(b))) ||
            (AIRail.IsRailTile(b) && ((AIRail.GetRailTracks(b) & (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_NW_NE + AIRail.RAILTRACK_NW_SW)) != 0)) ||
            AIRail.IsRailDepotTile(b) ||
            AIRail.IsRailStationTile(b))) {

        b = ConvertTrack(b, type);
        PowerWalk(b, type);
    }
    if (AIRail.GetRailType(c) != type &&
        AITile.GetOwner(c) == Me && (
            (AITunnel.IsTunnelTile(c) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(c)) == AIMap.GetTileY(c)) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(c)) < AIMap.GetTileX(c))) ||
            (AIBridge.IsBridgeTile(c) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(c)) == AIMap.GetTileY(c)) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(c)) < AIMap.GetTileX(c))) ||
            (AIRail.IsRailTile(c) && ((AIRail.GetRailTracks(c) & (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_SW_SE + AIRail.RAILTRACK_NW_SW)) != 0)) ||
            AIRail.IsRailDepotTile(c) ||
            AIRail.IsRailStationTile(c))) {

        c = ConvertTrack(c, type);
        PowerWalk(c, type);
    }
    if (AIRail.GetRailType(d) != type &&
        AITile.GetOwner(d) == Me && (
            (AITunnel.IsTunnelTile(d) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(d)) == AIMap.GetTileY(d)) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(d)) > AIMap.GetTileX(d))) ||
            (AIBridge.IsBridgeTile(d) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(d)) == AIMap.GetTileY(d)) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(d)) > AIMap.GetTileX(d))) ||
            (AIRail.IsRailTile(d) && ((AIRail.GetRailTracks(d) & (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_NE_SE + AIRail.RAILTRACK_NW_NE)) != 0)) ||
            AIRail.IsRailDepotTile(d) ||
            AIRail.IsRailStationTile(d))) {

        d = ConvertTrack(d, type);
        PowerWalk(d, type);
    }

}

function CivilAI::ConvertTrack(t, type) {
    if (AITunnel.IsTunnelTile(t)) {
        t = AITunnel.GetOtherTunnelEnd(t);
        AIRail.ConvertRailType(t, t, type);
    } else if (AIBridge.IsBridgeTile(t)) {
        t = AIBridge.GetOtherBridgeEnd(t);
        AIRail.ConvertRailType(t, t, type);
    } // that was easy enough
    else {
        AIRail.ConvertRailType(t, t, type);
    }
    return t;
}



function CivilAI::RailCleanUp() {

    // =================================================================
    // clear up abandoned tracks
    // =================================================================

    // clear up unused stations

    local tslist = AIStationList(AIStation.STATION_TRAIN);
    foreach(ts, z in tslist) {
        local tlist = AIVehicleList_Station(ts);
        tlist.Valuate(AIVehicle.GetVehicleType);
        tlist.KeepValue(AIVehicle.VT_RAIL);

        local stlist = AITileList_StationType(ts, AIStation.STATION_TRAIN);
        if (tlist.Count() == 0) {
            if (stlist.Count() < 6) {
                // remove dest, depot and tracks

                local depot = FindTrainDepot(ts);
                if (depot != null && AIRail.IsRailDepotTile(depot)) { // finding a depot implies we are a destination station
                    RemoveTracksFrom(ts, true); // remove supply and track
                    AITile.DemolishTile(AIBaseStation.GetLocation(ts));
                    AITile.DemolishTile(depot);
                } else {
                    RemoveTracksFrom(ts, false); // remove supply and track
                    AITile.DemolishTile(AIBaseStation.GetLocation(ts));
                }
            } else {
                local depot = FindTrainDepot(ts);
                RemoveTracksFrom(ts, true); // remove supply and track
                DudRailCon.AddItem(AIStation.GetNearestTown(ts), AIDate.GetYear(AIDate.GetCurrentDate()));
                AILog.Info(AITown.GetName(AIStation.GetNearestTown(ts)) + " won't be eligible for passenger rail for 5 years.");
                local stlist = AITileList_StationType(ts, AIStation.STATION_TRAIN);

                if (depot != null) AITile.DemolishTile(depot);
                AITile.DemolishTile(stlist.Begin());
            }
        }
    }

    // review dud connections - 5 years should be enough?

    if (DudRailCon.Count() > 0) {
        foreach(town, year in DudRailCon) {

            if (year + 5 <= AIDate.GetYear(AIDate.GetCurrentDate())) {
                DudRailCon.RemoveItem(town);
                AILog.Info(AITown.GetName(town) + " is now eligible for passenger rail again.");

            }
        }
    }


}
// =================================================================
// find the train depot at a terminus or passenger station
// =================================================================
function CivilAI::FindTrainDepot(station) {
    local depot = 0;

    local tlist = AITileList_StationType(station, AIStation.STATION_TRAIN);
    tlist.Sort(AIList.SORT_BY_ITEM, true); // northernmost first
    local tile = tlist.Begin(); // northernmost tile of the station
    local tg = [AIMap.GetTileX(tile), AIMap.GetTileY(tile)]

    local statlength = GetStatLength(station);

    if (AIRail.GetRailStationDirection(tile) == AIRail.RAILTRACK_NW_SE) {
        // station is on y axis
        if (AIRail.GetRailTracks(AIMap.GetTileIndex(tg[0] + 0, tg[1] - 1)) == AIRail.RAILTRACK_NW_SE) {
            // facing direction 0
            depot = AIMap.GetTileIndex(tg[0] - 1, tg[1] - 2);
        } else {
            depot = AIMap.GetTileIndex(tg[0] - 1, tg[1] + statlength + 1);
        }
    } else {
        // station is on x axis
        if (AIRail.GetRailTracks(AIMap.GetTileIndex(tg[0] - 1, tg[1] + 0)) == AIRail.RAILTRACK_NE_SW) {
            // facing direction 0
            depot = AIMap.GetTileIndex(tg[0] - 2, tg[1] - 1);
        } else {
            depot = AIMap.GetTileIndex(tg[0] + statlength + 1, tg[1] - 1);
        }

    }

    //AISign.BuildSign(depot, "D");

    if (AIRail.IsRailDepotTile(depot) && AITile.GetOwner(depot) == Me) {
        return depot
    } else {
        return null;
    }
}

// =================================================================
// get station length
// =================================================================

function CivilAI::GetStatLength(station) {
    local tlist = AITileList_StationType(station, AIStation.STATION_TRAIN);
    tlist.Sort(AIList.SORT_BY_ITEM, true); // northernmost first
    local tile = tlist.Begin(); // northernmost tile of the station
    local tg = [AIMap.GetTileX(tile), AIMap.GetTileY(tile)]

    local tlen = 1;
    local xo;
    local yo;

    if (AIRail.GetRailStationDirection(tile) == AIRail.RAILTRACK_NW_SE) {
        xo = 0;
        yo = 1; // station is on y axis
    } else {
        xo = 1;
        yo = 0; // station is on x axis
    }

    while (true) {
        tile = AIMap.GetTileIndex(tg[0] + (tlen * xo), tg[1] + (tlen * yo));
        if (!AIRail.IsRailStationTile(tile) || (AIStation.GetStationID(tile) != station)) {
            return tlen;
        }
        tlen++;
    }


}

// =================================================================
// get station platform count
// =================================================================

function CivilAI::GetPlatCount(station) {
    local tlist = AITileList_StationType(station, AIStation.STATION_TRAIN);
    local plats = tlist.Count() / GetStatLength(station);

    return plats;
}

// =================================================================
// pull up rails
// =================================================================
function CivilAI::RemoveTracksFrom(station, blitz) {

    blitz = true; // the "blitz" option will ignore junction restrictions for the first few operations, to allow removing the junction in front of a terminus.
    // ... and we always want to do it! sometimes our lines get tangled.

    AILog.Info("Removing tracks...")

    local stlist = AITileList_StationType(station, AIStation.STATION_TRAIN);
    foreach(t, z in stlist) {
        //AISign.BuildSign(t, "!");
        DemoWalk(t, 0, blitz);
    }

    AILog.Info("Demolition complete!")
}

function CivilAI::DemoWalk(t, o, blitz) {

    local a = (AIMap.GetTileIndex(AIMap.GetTileX(t) + 0, AIMap.GetTileY(t) - 1));
    local b = (AIMap.GetTileIndex(AIMap.GetTileX(t) + 0, AIMap.GetTileY(t) + 1));
    local c = (AIMap.GetTileIndex(AIMap.GetTileX(t) - 1, AIMap.GetTileY(t) + 0));
    local d = (AIMap.GetTileIndex(AIMap.GetTileX(t) + 1, AIMap.GetTileY(t) + 0));

    if ((AITunnel.IsTunnelTile(a) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(a)) == AIMap.GetTileX(a)) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(a)) < AIMap.GetTileY(a))) ||
        (AIBridge.IsBridgeTile(a) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(a)) == AIMap.GetTileX(a)) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(a)) < AIMap.GetTileY(a))) ||
        (AIRail.IsRailTile(a) && !AIRail.IsRailDepotTile(a) && !AIRail.IsRailStationTile(a) &&
            ((AIRail.GetRailTracks(a) & (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_SW_SE + AIRail.RAILTRACK_NE_SE)) != 0))) {
        //AISign.BuildSign(a, " " + o);

        if (!blitz || o > 5) {
            if (CheckJunction(a, 0)) return;
        }
        a = DemoTrack(a);
        o++;
        DemoWalk(a, o, blitz);
    }
    if ((AITunnel.IsTunnelTile(b) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(b)) == AIMap.GetTileX(b)) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(b)) > AIMap.GetTileY(b))) ||
        (AIBridge.IsBridgeTile(b) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(b)) == AIMap.GetTileX(b)) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(b)) > AIMap.GetTileY(b))) ||
        (AIRail.IsRailTile(b) && !AIRail.IsRailDepotTile(b) && !AIRail.IsRailStationTile(b) &&
            ((AIRail.GetRailTracks(b) & (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_NW_NE + AIRail.RAILTRACK_NW_SW)) != 0))) {
        //AISign.BuildSign(b, " " + o);

        if (!blitz || o > 5) {
            if (CheckJunction(b, 1)) return;
        }
        b = DemoTrack(b);
        o++;
        DemoWalk(b, o, blitz);
    }
    if ((AITunnel.IsTunnelTile(c) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(c)) == AIMap.GetTileY(c)) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(c)) < AIMap.GetTileX(c))) ||
        (AIBridge.IsBridgeTile(c) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(c)) == AIMap.GetTileY(c)) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(c)) < AIMap.GetTileX(c))) ||
        (AIRail.IsRailTile(c) && !AIRail.IsRailDepotTile(c) && !AIRail.IsRailStationTile(c) &&
            ((AIRail.GetRailTracks(c) & (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_SW_SE + AIRail.RAILTRACK_NW_SW)) != 0))) {
        //AISign.BuildSign(c, " " + o);

        if (!blitz || o > 5) {
            if (CheckJunction(c, 2)) return;
        }
        c = DemoTrack(c);
        o++;
        DemoWalk(c, o, blitz);
    }
    if ((AITunnel.IsTunnelTile(d) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(d)) == AIMap.GetTileY(d)) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(d)) > AIMap.GetTileX(d))) ||
        (AIBridge.IsBridgeTile(d) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(d)) == AIMap.GetTileY(d)) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(d)) > AIMap.GetTileX(d))) ||
        (AIRail.IsRailTile(d) && !AIRail.IsRailDepotTile(d) && !AIRail.IsRailStationTile(d) &&
            ((AIRail.GetRailTracks(d) & (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_NE_SE + AIRail.RAILTRACK_NW_NE)) != 0))) {
        //AISign.BuildSign(d, " " + o);

        if (!blitz || o > 5) {
            if (CheckJunction(d, 3)) return;
        }
        d = DemoTrack(d);
        o++;
        DemoWalk(d, o, blitz);
    }

}

function CivilAI::DemoTrack(t) {
    if (AITile.GetOwner(t) != Me) {
        return t;
    } else if (AIRail.IsLevelCrossingTile(t)) {
        AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NE_SW);
        AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NW_SE);
    } else if (AITunnel.IsTunnelTile(t)) {
        t = AITunnel.GetOtherTunnelEnd(t);
        AITile.DemolishTile(t);
    } else if (AIBridge.IsBridgeTile(t)) {
        t = AIBridge.GetOtherBridgeEnd(t);
        AITile.DemolishTile(t);
    } // that was easy enough
    else {
        AITile.DemolishTile(t);
    }
    return t;
}

function CivilAI::CheckJunction(t, dir) {

    if (AITunnel.IsTunnelTile(t) || AIBridge.IsBridgeTile(t)) {
        return false;
    } // tunnel or bridge, carry on regardless

    if ((AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NE_SW) ||
        (AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NW_SE) ||
        (AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NW_NE) ||
        (AIRail.GetRailTracks(t) == AIRail.RAILTRACK_SW_SE) ||
        (AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NW_SW) ||
        (AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NE_SE)) {
        return false;
    } // not a junction, carry on regardless

    if (dir == 0) {
        if ((AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_SW_SE)) ||
            (AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_NE_SE)) ||
            (AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_SW_SE + AIRail.RAILTRACK_NE_SE))) {
            return false;
        } // a trailing junction which is presumably the start of a passing place. Remove and continue.
        else {
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NW_SE);
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_SW_SE);
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NE_SE);
            return true;
        } // remove our spur tracks and end demolition.

    }
    if (dir == 1) {
        if ((AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_NW_SW)) ||
            (AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_NW_NE)) ||
            (AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NW_SW + AIRail.RAILTRACK_NW_NE))) {
            return false;
        } // a trailing junction which is presumably the start of a passing place. Remove and continue.
        else {
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NW_SE);
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NW_SW);
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NW_NE);
            return true;
        } // remove our spur tracks and end demolition.

    }
    if (dir == 2) {
        if ((AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_NW_SW)) ||
            (AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_SW_SE)) ||
            (AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NW_SW + AIRail.RAILTRACK_SW_SE))) {
            return false;
        } // a trailing junction which is presumably the start of a passing place. Remove and continue.
        else {
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NE_SW);
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NW_SW);
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_SW_SE);
            return true;
        } // remove our spur tracks and end demolition.

    }
    if (dir == 3) {
        if ((AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_NE_SE)) ||
            (AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_NW_NE)) ||
            (AIRail.GetRailTracks(t) == (AIRail.RAILTRACK_NW_NE + AIRail.RAILTRACK_NE_SE))) {
            return false;
        } // a trailing junction which is presumably the start of a passing place. Remove and continue.
        else {
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NE_SW);
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NW_NE);
            AIRail.RemoveRailTrack(t, AIRail.RAILTRACK_NE_SE);
            return true;
        } // remove our spur tracks and end demolition.

    }
    return true; // should never get here anyway
}

// =============
// patient builder for adding connections into potentially in-use tracks
// =============
function CivilAI::PBuild(t, track) {

    local c = 0;

    while (!AIRail.IsRailTile(t) || ((AIRail.GetRailTracks(t) & track) != track)) {
        if (AIRoad.IsRoadTile(t) || AITile.GetOwner(t) != Me) {
            AITile.DemolishTile(t);
        }
        AIRoad.RemoveRoad(AIMap.GetTileIndex(AIMap.GetTileX(t) - 1, AIMap.GetTileY(t)), AIMap.GetTileIndex(AIMap.GetTileX(t) + 1, AIMap.GetTileY(t)));
        AIRoad.RemoveRoad(AIMap.GetTileIndex(AIMap.GetTileX(t), AIMap.GetTileY(t) - 1), AIMap.GetTileIndex(AIMap.GetTileX(t), AIMap.GetTileY(t) + 1));

        AIRail.BuildRailTrack(t, track);

        if (!AIRail.IsRailTile(t) || AIRail.IsRailDepotTile(t) || AIRail.IsRailStationTile(t) || AITile.GetOwner(t) != Me) {
            return false;
        } // trying to pbuild on an unbuildable tile could take forever...
        if (((AIRail.GetRailTracks(t) & track) != track) && (!FlatRail(t, 0) || !FlatRail(t, 2))) {
            return false;
        } // trying to pbuild a junction on a non-flat tile?
        AIController.Sleep(1);
        c++;
        if (c > 100) {
            return false;
        }
    }
    return true;
}

// =============
// test if a straight track built on this tile would be flat
// =============
function CivilAI::FlatRail(tile, dir) {

    local isflat = false;

    if (dir == 1) dir = 0; // y
    if (dir == 3) dir = 2; // x

    local slope = AITile.GetSlope(tile);

    if (slope == AITile.SLOPE_FLAT) isflat = true;
    if (slope == AITile.SLOPE_EW) isflat = true;
    if (slope == AITile.SLOPE_NS) isflat = true;
    if (slope == AITile.SLOPE_NWS) isflat = true;
    if (slope == AITile.SLOPE_WSE) isflat = true;
    if (slope == AITile.SLOPE_SEN) isflat = true;
    if (slope == AITile.SLOPE_ENW) isflat = true;
    if (slope == AITile.SLOPE_SW && dir == 0) isflat = true;
    if (slope == AITile.SLOPE_NE && dir == 0) isflat = true;
    if (slope == AITile.SLOPE_NW && dir == 2) isflat = true;
    if (slope == AITile.SLOPE_SE && dir == 2) isflat = true;

    //if (isflat) {AISign.BuildSign(tile, "flat");} else {AISign.BuildSign(tile, "slope");}

    return isflat;
}

//=====================
// find available go tiles at a station
//=====================

function CivilAI::gotile(stat) {
    local j = null;
    local g = null;
    local tt = null;
    local intile = null;
    local gotile = null;

    local tlist = AITileList_StationType(stat, AIStation.STATION_TRAIN);
    local tg = [];
    local pig = AIList(); // potential forward-facing intiles
    local sig = AIList(); // potential side-facing intiles

    foreach(tile, z in tlist) {
        tg = [AIMap.GetTileX(tile), AIMap.GetTileY(tile)]

        if (AIRail.GetRailStationDirection(tile) == AIRail.RAILTRACK_NW_SE) {
            // station is on y axis
            tt = AIMap.GetTileIndex(tg[0] + 0, tg[1] - 1);
            if (!AIRail.IsRailStationTile(tt) && AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_SE) // station end facing direction 0
            {
                pig.AddItem(AIMap.GetTileIndex(tg[0] + 0, tg[1] - 3), 0)
                if (!AIRail.IsRailTile(AIMap.GetTileIndex(tg[0] + 1, tg[1] - 2))) {
                    sig.AddItem(AIMap.GetTileIndex(tg[0] + 1, tg[1] - 2), 3);
                }
                if (!AIRail.IsRailTile(AIMap.GetTileIndex(tg[0] - 1, tg[1] - 2))) {
                    sig.AddItem(AIMap.GetTileIndex(tg[0] - 1, tg[1] - 2), 2);
                }
            }
            tt = AIMap.GetTileIndex(tg[0] + 0, tg[1] + 1);
            if (!AIRail.IsRailStationTile(tt) && AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_SE) // station end facing direction 1
            {
                pig.AddItem(AIMap.GetTileIndex(tg[0] + 0, tg[1] + 3), 1)
                if (!AIRail.IsRailTile(AIMap.GetTileIndex(tg[0] + 1, tg[1] + 2))) {
                    sig.AddItem(AIMap.GetTileIndex(tg[0] + 1, tg[1] + 2), 3);
                }
                if (!AIRail.IsRailTile(AIMap.GetTileIndex(tg[0] - 1, tg[1] + 2))) {
                    sig.AddItem(AIMap.GetTileIndex(tg[0] - 1, tg[1] + 2), 2);
                }
            }
        } else {
            // station is on x axis
            tt = AIMap.GetTileIndex(tg[0] - 1, tg[1] + 0);
            if (!AIRail.IsRailStationTile(tt) && AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NE_SW) // station end facing direction 2
            {
                pig.AddItem(AIMap.GetTileIndex(tg[0] - 3, tg[1] + 0), 2)
                if (!AIRail.IsRailTile(AIMap.GetTileIndex(tg[0] - 2, tg[1] + 1))) {
                    sig.AddItem(AIMap.GetTileIndex(tg[0] - 2, tg[1] + 1), 1);
                }
                if (!AIRail.IsRailTile(AIMap.GetTileIndex(tg[0] - 2, tg[1] - 1))) {
                    sig.AddItem(AIMap.GetTileIndex(tg[0] - 2, tg[1] - 1), 0);
                }
            }
            tt = AIMap.GetTileIndex(tg[0] + 1, tg[1] + 0);
            if (!AIRail.IsRailStationTile(tt) && AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NE_SW) // station end facing direction 3
            {
                pig.AddItem(AIMap.GetTileIndex(tg[0] + 3, tg[1] + 0), 3)
                if (!AIRail.IsRailTile(AIMap.GetTileIndex(tg[0] + 2, tg[1] + 1))) {
                    sig.AddItem(AIMap.GetTileIndex(tg[0] + 2, tg[1] + 1), 1);
                }
                if (!AIRail.IsRailTile(AIMap.GetTileIndex(tg[0] + 2, tg[1] - 1))) {
                    sig.AddItem(AIMap.GetTileIndex(tg[0] + 2, tg[1] - 1), 0);
                }
            }
        }
    }

    foreach(i, dir in pig) { // check if an end connection is clear

        if (dir == 0) {
            g = AIMap.GetTileIndex(AIMap.GetTileX(i), AIMap.GetTileY(i) - 1);
        }
        if (dir == 1) {
            g = AIMap.GetTileIndex(AIMap.GetTileX(i), AIMap.GetTileY(i) + 1);
        }
        if (dir == 2) {
            g = AIMap.GetTileIndex(AIMap.GetTileX(i) - 1, AIMap.GetTileY(i));
        }
        if (dir == 3) {
            g = AIMap.GetTileIndex(AIMap.GetTileX(i) + 1, AIMap.GetTileY(i));
        }

        //	AISign.BuildSign(g, "g");
        //	AISign.BuildSign(i, "i");

        if (
            AITile.GetOwner(g) != Me &&
            AITile.GetOwner(i) != Me &&
            (AITile.IsBuildable(g) || AITile.DemolishTile(g)) &&
            (AITile.IsBuildable(i) || AITile.DemolishTile(i))) {
            gotile = g;
            intile = i;
            break;
        }
    }

    if (gotile == null) {
        foreach(i, dir in sig) { // couldn't find one, check any side connections

            if (dir == 0) {
                g = AIMap.GetTileIndex(AIMap.GetTileX(i), AIMap.GetTileY(i) - 1);
            }
            if (dir == 1) {
                g = AIMap.GetTileIndex(AIMap.GetTileX(i), AIMap.GetTileY(i) + 1);
            }
            if (dir == 2) {
                g = AIMap.GetTileIndex(AIMap.GetTileX(i) - 1, AIMap.GetTileY(i));
            }
            if (dir == 3) {
                g = AIMap.GetTileIndex(AIMap.GetTileX(i) + 1, AIMap.GetTileY(i));
            }

            //	AISign.BuildSign(g, "g");
            //	AISign.BuildSign(i, "i");

            if (
                AITile.GetOwner(g) != Me &&
                AITile.GetOwner(i) != Me &&
                (AITile.IsBuildable(g) || AITile.DemolishTile(g)) &&
                (AITile.IsBuildable(i) || AITile.DemolishTile(i))) {
                gotile = g;
                intile = i;
                break;
            }

        }
    }
    if (gotile != null) {
        //AISign.BuildSign(gotile, "gotile");
        //AISign.BuildSign(intile, "intile");
        return [gotile, intile];
    } else {
        return null;
    }
}

// =============
// Attach a goline to a station junction
// =============
function CivilAI::AttachLine(gi) {

    local g = gi[0];
    local i = gi[1];

    if (AITile.GetOwner(i) == Me && AIRail.IsRailTile(i)) {
        return false
    } // abort if we built through the intile - it's not navigable due to PBS.

    local e0 = false;
    local e1 = false;
    local e2 = false;
    local e3 = false;

    local xof = AIMap.GetTileX(i) - AIMap.GetTileX(g);
    local yof = AIMap.GetTileY(i) - AIMap.GetTileY(g);

    local j = AIMap.GetTileIndex(AIMap.GetTileX(i) + xof, AIMap.GetTileY(i) + yof);

    if (AITile.GetSlope(j) != AITile.SLOPE_NWS &&
        AITile.GetSlope(j) != AITile.SLOPE_WSE &&
        AITile.GetSlope(j) != AITile.SLOPE_SEN &&
        AITile.GetSlope(j) != AITile.SLOPE_ENW &&
        AITile.GetSlope(j) != AITile.SLOPE_FLAT) return false; // somehow our junction tile got sloped (another player, probably) - abort



    if (AIRail.IsRailTile(j)) { // identify existing edge connections on the junction tile

        if ((AIRail.GetRailTracks(j) & AIRail.RAILTRACK_NE_SW) == AIRail.RAILTRACK_NE_SW) {
            e2 = true;
            e3 = true;
        }
        if ((AIRail.GetRailTracks(j) & AIRail.RAILTRACK_NW_SE) == AIRail.RAILTRACK_NW_SE) {
            e0 = true;
            e1 = true;
        }
        if ((AIRail.GetRailTracks(j) & AIRail.RAILTRACK_NW_NE) == AIRail.RAILTRACK_NW_NE) {
            e0 = true;
            e2 = true;
        }
        if ((AIRail.GetRailTracks(j) & AIRail.RAILTRACK_SW_SE) == AIRail.RAILTRACK_SW_SE) {
            e3 = true;
            e1 = true;
        }
        if ((AIRail.GetRailTracks(j) & AIRail.RAILTRACK_NW_SW) == AIRail.RAILTRACK_NW_SW) {
            e0 = true;
            e3 = true;
        }
        if ((AIRail.GetRailTracks(j) & AIRail.RAILTRACK_NE_SE) == AIRail.RAILTRACK_NE_SE) {
            e2 = true;
            e1 = true;
        }
    }

    local jg = [AIMap.GetTileX(j), AIMap.GetTileY(j)];
    if (AIRail.IsRailTile(AIMap.GetTileIndex(jg[0], jg[1] - 1)) && (AIRail.GetRailTracks(AIMap.GetTileIndex(jg[0], jg[1] - 1)) & AIRail.RAILTRACK_NW_SE) == AIRail.RAILTRACK_NW_SE) {
        e0 = true;
    }
    if (AIRail.IsRailTile(AIMap.GetTileIndex(jg[0], jg[1] + 1)) && (AIRail.GetRailTracks(AIMap.GetTileIndex(jg[0], jg[1] + 1)) & AIRail.RAILTRACK_NW_SE) == AIRail.RAILTRACK_NW_SE) {
        e1 = true;
    }
    if (AIRail.IsRailTile(AIMap.GetTileIndex(jg[0] - 1, jg[1])) && (AIRail.GetRailTracks(AIMap.GetTileIndex(jg[0] - 1, jg[1])) & AIRail.RAILTRACK_NE_SW) == AIRail.RAILTRACK_NE_SW) {
        e2 = true;
    }
    if (AIRail.IsRailTile(AIMap.GetTileIndex(jg[0] + 1, jg[1])) && (AIRail.GetRailTracks(AIMap.GetTileIndex(jg[0] + 1, jg[1])) & AIRail.RAILTRACK_NE_SW) == AIRail.RAILTRACK_NE_SW) {
        e3 = true;
    }

    //AISign.BuildSign(j, " " + e0 + " " + e1 + " " + e2 + " " + e3);


    if (AITile.GetOwner(i) != Me) AITile.DemolishTile(i); // just in case the town put a house here or something while we were building the line
    if (yof != 0) { // coming in on the y axis
        if (!PBuild(i, AIRail.RAILTRACK_NW_SE)) {
            return false
        }
        if (yof < 0) {
            e1 = true;
        } else {
            e0 = true;
        }
    } else {
        if (!PBuild(i, AIRail.RAILTRACK_NE_SW)) {
            return false
        }
        if (xof < 0) {
            e3 = true;
        } else {
            e2 = true;
        }
    }


    if (e2 && e3) {
        PBuild(j, AIRail.RAILTRACK_NE_SW);
    }
    if (e0 && e1) {
        PBuild(j, AIRail.RAILTRACK_NW_SE);
    }
    if (e0 && e2) {
        PBuild(j, AIRail.RAILTRACK_NW_NE);
    }
    if (e3 && e1) {
        PBuild(j, AIRail.RAILTRACK_SW_SE);
    }
    if (e0 && e3) {
        PBuild(j, AIRail.RAILTRACK_NW_SW);
    }
    if (e2 && e1) {
        PBuild(j, AIRail.RAILTRACK_NE_SE);
    }

    return true;
}