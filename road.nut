// ====================================================== 
//                    BUILD DEPOT
// ====================================================== 



function CivilAI::BuildDepot(roadtile, town) {
    // this is road, check it's joined to the centre of town
    local testroad = RoadPF();
    local towntile = AITown.GetLocation(town);
    local depot = null;

    testroad.cost.no_existing_road = testroad.cost.max_cost; // only check existing roads
    testroad.InitializePath([roadtile], [towntile]);

    local path = false;
    while (path == false) {
        path = testroad.FindPath(20);
        AIController.Sleep(1);
    }

    if ((path != null) && (AITile.GetSlope(roadtile) == 0)) {
        //AISign.BuildSign(roadtile, "?");

        local builtlink = false; // keep trying if a vehicle is preventing building the road connection
        local c = 0;
        local roadtilegrid = [AIMap.GetTileX(roadtile), AIMap.GetTileY(roadtile)]
        if (AIRoad.BuildRoadDepot(AIMap.GetTileIndex(roadtilegrid[0] + 1, roadtilegrid[1]), roadtile)) {
            depot = AIMap.GetTileIndex(roadtilegrid[0] + 1, roadtilegrid[1]);
            while (!builtlink && c < 100) {
                builtlink = AIRoad.BuildRoad(roadtile, depot);
                c++
                AIController.Sleep(5);
            }
        } else if (AIRoad.BuildRoadDepot(AIMap.GetTileIndex(roadtilegrid[0] - 1, roadtilegrid[1]), roadtile)) {
            depot = AIMap.GetTileIndex(roadtilegrid[0] - 1, roadtilegrid[1]);
            while (!builtlink && c < 100) {
                builtlink = AIRoad.BuildRoad(roadtile, depot);
                c++
                AIController.Sleep(5);
            }
        } else if (AIRoad.BuildRoadDepot(AIMap.GetTileIndex(roadtilegrid[0], roadtilegrid[1] + 1), roadtile)) {
            depot = AIMap.GetTileIndex(roadtilegrid[0], roadtilegrid[1] + 1);
            while (!builtlink && c < 100) {
                builtlink = AIRoad.BuildRoad(roadtile, depot);
                c++
                AIController.Sleep(5);
            }
        } else if (AIRoad.BuildRoadDepot(AIMap.GetTileIndex(roadtilegrid[0], roadtilegrid[1] - 1), roadtile)) {
            depot = AIMap.GetTileIndex(roadtilegrid[0], roadtilegrid[1] - 1);
            while (!builtlink && c < 100) {
                builtlink = AIRoad.BuildRoad(roadtile, depot);
                c++
                AIController.Sleep(5);
            }
        }
    }
    return depot;
}


//<
// ====================================================== 
// ====================================================== 
//         RRRRR     OOOO      AAAA     DDDD
//         R   RR   O    O    A    A    D  DD
//         RRRRR   OO    OO   AAAAAA    D   DD
//         R   R    O    O    A    A    D  DD
//         R    R    OOOO     A    A    DDDD
// ====================================================== 
// ====================================================== 
//>
// ====================================================== 
//                  CHOOSE ROAD CONNECTION
// ====================================================== 

function CivilAI::MappaMundi() {
    AILog.Info("Stand by for road construction...")
    AILog.Info("I'm connecting towns with road.");

    // new check: have we built in most of the towns already connected? If not, don't waste money expanding.

    local zoop = AIList();
    zoop.AddList(Cachedtowns);
    zoop.RemoveList(DudBusNetwork);

    zoop.Valuate(AITown.GetPopulation);
    zoop.RemoveBelowValue(MinPop); // only buildable towns considered


    local yoop = AIDepotList(AITile.TRANSPORT_ROAD);

    //AILog.Info("I currently have " + yoop.Count() + " depots in " + zoop.Count() + " towns.");

    if (zoop.Count() < yoop.Count() + 2) {

        local hq = AICompany.GetCompanyHQ(Me);
        local townlist = AITownList();

        townlist.Valuate(AITown.GetPopulation);
        //townlist.RemoveBelowValue(MinPop); // don't connect to towns we can't build in
        townlist.AddItem(AITile.GetClosestTown(hq), 0); // add back the home town, in case it's small
        townlist.AddList(IndTownList); // but add back any we want to connect for industrial reasons

        // sort by distance from the hq
        townlist.Valuate(AITown.GetDistanceManhattanToTile, hq);


        townlist.KeepBelowValue(NetworkRadius); // remove towns which are too far away
        townlist.RemoveList(Dudtowns); // remove known unconnectables

        townlist.Sort(AIList.SORT_BY_VALUE, true);

        // add the home town's home tile to the target list
        local hometown = townlist.Begin();
        local mapnodes = [];
        local nodecount = 1
        local target = -1

        zoop.AddList(Cachedtowns); //rezoop all-sized towns

        foreach(town, z in townlist) {
            local towntile = AITown.GetLocation(town);
            if (!AITile.HasTransportType(towntile, AITile.TRANSPORT_ROAD) && (AITown.GetRoadReworkDuration(town) == 0)) {
                Dudtowns.AddItem(town, 0) // add this town to a list of unreachables
                AILog.Info(AITown.GetName(town) + " has no central road tile.")
            } else {
                if (zoop.HasItem(town)) { // we are connected already
                    mapnodes.append(towntile); // add this town to the nodes we can connect to
                    nodecount++
                    //AILog.Info(AITown.GetName(town) + " added as connectable node.");
                } else if (Exclaves.HasItem(town)) {

                } else {
                    target = town;
                    //AILog.Info(AITown.GetName(town) + " targetted.");
                    break;
                }
            }
        }

        //AILog.Info(Exclaves.Count());

        local GoRoute = 1000000;
        local NodeRoute = 0;
        foreach(town, n in zoop) {
            NodeRoute = ScoreRoute(AITown.GetLocation(town), AITown.GetLocation(target));
            // AILog.Info(AITown.GetName(town) + " - " + AITown.GetName(target) + " score: " + NodeRoute);
            if (NodeRoute < GoRoute) GoRoute = NodeRoute;
        }

        if (target != -1 && AITown.IsValidTown(target)) {
            if (GoRoute < (NetworkRadius) &&
                BuildARoad(mapnodes, [AITown.GetLocation(target)], target, 200, false)) {

                // test town connects to target
                local testroad = RoadPF();
                local begin_towntile = AITown.GetLocation(hometown);
                local end_towntile = AITown.GetLocation(target);

                testroad.cost.no_existing_road = testroad.cost.max_cost;
                testroad.InitializePath([end_towntile], [begin_towntile]);

                local testpath = false;
                while (testpath == false) {
                    testpath = testroad.FindPath(50);
                    AIController.Sleep(1);
                }

                // judge on test results
                if (testpath != null) {
                    AILog.Info("I have connected " + AITown.GetName(target) + ".");
                } else {
                    AILog.Info("I somehow cannot connected " + AITown.GetName(target) + ". Add as exclave.");
                    Dudtowns.AddItem(target, 0);
                    Exclaves.AddItem(target, 0);
                }


            } else {
                Dudtowns.AddItem(target, 0) // add this town to a list of unreachables
                AILog.Info(AITown.GetName(target) + " seems to be unreachable.")
                // add exclave
                Exclaves.AddItem(target, 0);
                AILog.Info("I have added " + AITown.GetName(target) + " as an exclave.")
            }
        }
    }
}

// ====================================================== 
//                  BUILD ROAD CONNECTION
// ====================================================== 

function CivilAI::BuildARoad(a, b, target, bs, upgrade) {

    local buildroad = RoadPF();
    //                                    2147483647
    buildroad.cost.max_cost = 10000000; //10000000;
    buildroad.cost.tile = 100; // 100;
    buildroad.cost.no_existing_road = 400; //300 (1.9); //40;
    buildroad.cost.turn = 200; //100;
    buildroad.cost.slope = 800; //200;
    buildroad.cost.bridge_per_tile = 600; //150;
    buildroad.cost.tunnel_per_tile = 600; //120;
    buildroad.cost.coast = 500; //20;
    buildroad.cost.max_bridge_length = 12; //10; !!!!!
    buildroad.cost.max_tunnel_length = 10; //20;
    buildroad.cost.bus_stop = bs;

    if (upgrade) {
        buildroad.cost.no_existing_road = 40000;
    }

    if (target != -1) {
        // check funds allow for the connection, and a bit left over to maintain the network
        // as of 1.6 we only do this check for building new links, because we want to always check eg after building bridges
        // as of 20 we check for a huge amount of money to avoid spending all our early cash on roads
        local condist = NetworkRadius
        local nodedist
        foreach(node, loc in b) {
            nodedist = AITile.GetDistanceManhattanToTile(a[0], loc)
            if (nodedist < condist) {
                condist = nodedist;
            }
        }

        local dosh = AICompany.GetBankBalance(Me);
        local cost = AIRoad.GetBuildCost(AIRoad.GetCurrentRoadType(), AIRoad.BT_ROAD) * 30 * condist;

        //AILog.Info(cost);

        if (dosh < cost) {
            if (target != -1) {
                AILog.Info("I can't afford to build a road to " + AITown.GetName(target) + " right now. Perhaps later.")
            }

            return false;
        }
        AILog.Info("I'm connecting " + AITown.GetName(target) + " to the road network (" + condist + ").")
        Recache = true;



    } else {
        //AILog.Info("I'm reviewing the roads between " + AITown.GetName(AITile.GetClosestTown(a[0])) + " and " + AITown.GetName(AITile.GetClosestTown(b[0])) + ".")
    }

    buildroad.InitializePath(a, b);

    local i = 0;
    local maxtime = NetworkRadius * 20; // increase max time
    local percount = 0;
    local path = false;

    // cash down
    CashDown();

    while (path == false) {
        path = buildroad.FindPath(50);
        AIController.Sleep(1);

        i++
        if (((i * 10) / maxtime) > percount) {
            percount++;
            AILog.Info(percount * 10 + "%");
        }
        if (i > maxtime) {
            AILog.Info("I couldn't find a path.")
            break;
        }
    }

    // cash up
    CashUp();

    if (path == false) {
        return false;
    }

    local c = 0


    while (path != null) {
        local par = path.GetParent();
        if (par != null) {
            local t = par.GetTile();
            if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1) {

                // - 2022 - upgrade existing road
                if (AIRoad.IsRoadTile(t) &&
                    (AITile.GetOwner(t) == Me)) {
                    //AISign.BuildSign(t, "!");
                    AIRoad.ConvertRoadType(path.GetTile(), par.GetTile(), AIRoad.GetCurrentRoadType());
                }
                // - 

                if ((!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) && c < 10) {
                    /* An error occured while building a road. TODO: handle it. */
                    ;
                }
            } else {
                /* Build a bridge or tunnel. */
                if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
                    /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
                    if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
                    if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
                        if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
                            /* An error occured while building a tunnel. TODO: handle it. */
                        }
                    } else {
                        local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
                        bridge_list.Valuate(AIBridge.GetMaxSpeed);
                        bridge_list.Sort(AIList.SORT_BY_VALUE, false);
                        if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
                            /* An error occured while building a bridge. TODO: handle it. */
                        }
                    }
                }
            }
        }
        path = par;
    }
    //AILog.Info("I've finished road building for now.")

    return true;
}

// ====================================================== 
//    FIND LEVEL XINGS TO REPLACE
// ====================================================== 

function CivilAI::XingReplace() {

    while (AIEventController.IsEventWaiting()) {
        local event = AIEventController.GetNextEvent();

        if (event.GetEventType() == AIEvent.ET_VEHICLE_CRASHED) {
            local crash = AIEventVehicleCrashed.Convert(event);
            if (crash.GetCrashReason() == AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING) {
                local xing = crash.GetCrashSite();
                local xg = [AIMap.GetTileX(xing), AIMap.GetTileY(xing)]
                AILog.Info("One of our vehicles got squished at " + xg[0] + "," + xg[1] + ". I'll try and remove the crossing...");

                if (AIRail.GetRailTracks(xing) == AIRail.RAILTRACK_NE_SW) {
                    XRem(0, xing);
                } else {
                    XRem(1, xing);
                }
            }
        }
    }
    //AILog.Info("Finished crossing removal.")
}

function CivilAI::XRem(orientation, xing) {
    local xof = 0;
    local yof = 0;
    if (orientation == 0) {
        yof = 1;
    } else {
        xof = 1;
    }
    local xg = [AIMap.GetTileX(xing), AIMap.GetTileY(xing)]

    // find the road tiles either side of the crossing
    local tile1 = null;
    local tile2 = null;

    local c = 0;
    local testtile;
    while (tile1 == null) {
        c++;
        testtile = AIMap.GetTileIndex(xg[0] - (xof * c), xg[1] - (yof * c));
        //AISign.BuildSign(testtile, "1?");
        if (!AIRail.IsLevelCrossingTile(testtile)) {
            tile1 = testtile;
            xg = [AIMap.GetTileX(tile1), AIMap.GetTileY(tile1)];
        }
    }

    // check that the tile has road and belongs to us
    if (!AIRoad.IsRoadTile(tile1)) {
        AILog.Info("but it doesn't seem to be a connected level crossing.");
        return false;
    } else if ((AITile.GetOwner(tile1) != Me) && (AITile.GetOwner(tile1) != AICompany.COMPANY_INVALID)) {
        AILog.Info("but it's not my road.");
        return false;
    } else if (AIRoad.AreRoadTilesConnected(tile1,
            AIMap.GetTileIndex(xg[0] + yof, xg[1] + xof)) ||
        AIRoad.AreRoadTilesConnected(tile1,
            AIMap.GetTileIndex(xg[0] - yof, xg[1] - xof))
    ) {
        AILog.Info("but it's not a straight approach.");
        return false;
    }
    // we have our start tile

    //AISign.BuildSign(tile1, "1!");


    // now, find the tile across the crossing



    c = 0;
    while (tile2 == null) {
        c++;
        testtile = AIMap.GetTileIndex(xg[0] + (xof * c), xg[1] + (yof * c));
        //AISign.BuildSign(testtile, "2?");
        if (!AIRail.IsLevelCrossingTile(testtile)) {
            tile2 = testtile;
            xg = [AIMap.GetTileX(tile2), AIMap.GetTileY(tile2)];
        }
    }
    // check that the tile has road and belongs to us
    if (!AIRoad.IsRoadTile(tile2)) {
        AILog.Info("but it doesn't seem to be a connected level crossing - perhaps I already replaced it.");
        return false;
    } else if ((AITile.GetOwner(tile1) != Me) && (AITile.GetOwner(tile1) != AICompany.COMPANY_INVALID)) {
        AILog.Info("but it's not my road.");
        return false;
    } else if (AIRoad.AreRoadTilesConnected(tile2,
            AIMap.GetTileIndex(xg[0] + yof, xg[1] + xof)) ||
        AIRoad.AreRoadTilesConnected(tile2,
            AIMap.GetTileIndex(xg[0] - yof, xg[1] - xof))
    ) {
        AILog.Info("but it's not a straight approach.");
        return false;
    }
    // we have our end tile

    //AISign.BuildSign(tile2, "2!");
    xg = [AIMap.GetTileX(tile1), AIMap.GetTileY(tile1)];

    // check slopes
    local tunnel1 = false;
    local tunnel2 = false;

    if (xof == 1) {
        if (AITile.GetSlope(tile1) == AITile.SLOPE_SW) {
            tunnel1 = true
        };
        if (AITile.GetSlope(tile2) == AITile.SLOPE_NE) {
            tunnel2 = true
        };
    } else {
        if (AITile.GetSlope(tile1) == AITile.SLOPE_SE) {
            tunnel1 = true
        };
        if (AITile.GetSlope(tile2) == AITile.SLOPE_NW) {
            tunnel2 = true
        };
    }
    if (tunnel1 != tunnel2) {
        AILog.Info("but the slopes don't match.");
        return false;
    }

    // all is good - clear the roads.

    local d = 0;

    while (d < 100) {
        //AILog.Info("Clearing tile (" + d + "/100).")
        if (AITile.DemolishTile(tile1)) {
            break;
        }
        AIController.Sleep(3);
        d++
    }

    if (d == 100) {
        AILog.Info("Something went wrong - perhaps the traffic was too heavy to clear the road.");
        AIRoad.BuildRoadFull(tile1, tile2);
        AIRoad.BuildRoadFull(tile2, tile1);
        return;
    }

    xg = [AIMap.GetTileX(tile1), AIMap.GetTileY(tile1)]
    local e = 1;
    while (e < c + 1) { // c now = how many crossing tiles we have to remove (+1 for the other end). We remove one at a time to avoid stranding vehicles on the crossing.
        d = 0;
        while (d < 100) {
            //AILog.Info("Clearing tile (" + d + "/100).")
            //AISign.BuildSign(AIMap.GetTileIndex(xg[0] + (xof * e), xg[1] + (yof * e)), "v");
            AIRoad.RemoveRoadFull(tile1, AIMap.GetTileIndex(xg[0] + (xof * e), xg[1] + (yof * e)))
            if (!AIRoad.IsRoadTile(AIMap.GetTileIndex(xg[0] + (xof * e), xg[1] + (yof * e)))) {
                e++
                break;
            }
            AIController.Sleep(3);
            d++
        }
        if (d == 100) {
            AILog.Info("Something went wrong - perhaps the traffic was too heavy to clear the road.");
            AIRoad.BuildRoadFull(tile1, tile2);
            AIRoad.BuildRoadFull(tile2, tile1);
            return;
        }
    }

    // build a bridge (or tunnel)
    AITile.DemolishTile(tile1);
    AITile.DemolishTile(tile2);

    if (tunnel1) {
        if (AITunnel.BuildTunnel(AIVehicle.VT_ROAD, tile1)) {
            AILog.Info("I replaced it with a tunnel.")
        } else {
            AILog.Info("Something went wrong.");
            AIRoad.BuildRoadFull(tile1, tile2);
            AIRoad.BuildRoadFull(tile2, tile1);
            return;
        }
    } else {

        local bridgelist = AIBridgeList_Length((AIMap.GetTileX(tile2) - AIMap.GetTileX(tile1)) + (AIMap.GetTileY(tile2) - AIMap.GetTileY(tile1)))
        bridgelist.Valuate(AIBridge.GetMaxSpeed);
        bridgelist.Sort(AIList.SORT_BY_VALUE, false);
        local bridge = bridgelist.Begin();

        if (AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge, tile1, tile2)) {
            AILog.Info("I replaced it with a bridge.")
        } else {
            AILog.Info("Something went wrong.");
            AIRoad.BuildRoadFull(tile1, tile2);
            AIRoad.BuildRoadFull(tile2, tile1);
            return;
        }
    }
}


// ====================================================== 
//                    Select Road Type (2022!)
// ====================================================== 



function CivilAI::SelectRoadType(FirstTime) {

    local SelRoadType = null;
    local OldRoadType = AIRoad.GetCurrentRoadType();
    AILog.Info("Selecting Road Type..." + OldRoadType);

    local HasBus = IdentifyBus(false, false, FindCargo("PASS"));
    if (HasBus == null) {
        return false;
    }

    local RoadTypes = AIRoadTypeList(AIRoad.ROADTRAMTYPES_ROAD);
    local maxspeed = -2;

    foreach(RoadType, z in RoadTypes) {

        //AILog.Info ("Assessing Road Type " + RoadType);

        if (!BannedRoadTypes.HasItem(RoadType) &&
            AIEngine.CanRunOnRoad(HasBus, RoadType) &&
            (FirstTime || OldRoadType == AIRoad.ROADTYPE_ROAD || AIRoad.RoadVehCanRunOnRoad(RoadType, OldRoadType))
        ) {

            if (AIRoad.GetMaxSpeed(RoadType) > maxspeed) {
                SelRoadType = RoadType;
                maxspeed = AIRoad.GetMaxSpeed(RoadType);
            }
        }
    }

    if (SelRoadType != null) {

        AIRoad.SetCurrentRoadType(SelRoadType);
        AILog.Info("Selected " + AIRoad.GetName(SelRoadType) + " as my road type.");
        return true;
    } else {
        AILog.Info("I couldn't find a roadtype, oh no!")
        return false;
    }


}