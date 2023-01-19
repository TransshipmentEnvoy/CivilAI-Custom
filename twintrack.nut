// ====================================================== 
// ====================================================== 
// 			  RRRR     A    I  L
// 			  R   R   A A   I  L
// 			  R  R   A   A  I  L
//  		  RRRR   AAAAA  I  L
//  		  R   R  A   A  I  LLLLL
// ========================= Twin Track Passing Places!== 
// ====================================================== 

function CivilAI::TwinTrack(a, b, tlen) {

    local tlist = AIList();
    tlist.AddItem(a[0], 0);
    tlist.AddItem(a[1], 0);
    tlist.AddItem(b[0], 0);

    tlist = TwinWalk(a[0], 0, tlist, b[0]);

    tlist.RemoveItem(a[0]);
    tlist.RemoveItem(a[1]);
    tlist.RemoveItem(b[0]);
    AILog.Info("Finding passing places (" + tlist.Count() + " tiles).");

    BuildPassingPlaces(tlist, tlen);
}

function CivilAI::TwinWalk(t, o, tlist, range) {

    local a = (AIMap.GetTileIndex(AIMap.GetTileX(t) + 0, AIMap.GetTileY(t) - 1));
    local b = (AIMap.GetTileIndex(AIMap.GetTileX(t) + 0, AIMap.GetTileY(t) + 1));
    local c = (AIMap.GetTileIndex(AIMap.GetTileX(t) - 1, AIMap.GetTileY(t) + 0));
    local d = (AIMap.GetTileIndex(AIMap.GetTileX(t) + 1, AIMap.GetTileY(t) + 0));

    if (!tlist.HasItem(a) && (
            (AITunnel.IsTunnelTile(a) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(a)) == AIMap.GetTileX(a)) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(a)) < AIMap.GetTileY(a))) ||
            (AIBridge.IsBridgeTile(a) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(a)) == AIMap.GetTileX(a)) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(a)) < AIMap.GetTileY(a))) ||
            (AIRail.IsRailTile(a) && !AIRail.IsRailDepotTile(a) && !AIRail.IsRailStationTile(a) && ((AIRail.GetRailTracks(a) & (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_SW_SE + AIRail.RAILTRACK_NE_SE)) != 0)))) {

        if (AITunnel.IsTunnelTile(a)) {
            a = AITunnel.GetOtherTunnelEnd(a);
        }
        if (AIBridge.IsBridgeTile(a)) {
            a = AIBridge.GetOtherBridgeEnd(a);
        }

        tlist.AddItem(a, o);
        o++;
        //AISign.BuildSign(a, o + " ")
        TwinWalk(a, o, tlist, range);
    }
    if (!tlist.HasItem(b) && (
            (AITunnel.IsTunnelTile(b) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(b)) == AIMap.GetTileX(b)) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(b)) > AIMap.GetTileY(b))) ||
            (AIBridge.IsBridgeTile(b) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(b)) == AIMap.GetTileX(b)) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(b)) > AIMap.GetTileY(b))) ||
            (AIRail.IsRailTile(b) && !AIRail.IsRailDepotTile(b) && !AIRail.IsRailStationTile(b) && ((AIRail.GetRailTracks(b) & (AIRail.RAILTRACK_NW_SE + AIRail.RAILTRACK_NW_NE + AIRail.RAILTRACK_NW_SW)) != 0)))) {

        if (AITunnel.IsTunnelTile(b)) {
            b = AITunnel.GetOtherTunnelEnd(b);
        }
        if (AIBridge.IsBridgeTile(b)) {
            b = AIBridge.GetOtherBridgeEnd(b);
        }

        tlist.AddItem(b, o);
        o++;
        //AISign.BuildSign(b, o + " ")
        TwinWalk(b, o, tlist, range);
    }
    if (!tlist.HasItem(c) && (
            (AITunnel.IsTunnelTile(c) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(c)) == AIMap.GetTileY(c)) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(c)) < AIMap.GetTileX(c))) ||
            (AIBridge.IsBridgeTile(c) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(c)) == AIMap.GetTileY(c)) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(c)) < AIMap.GetTileX(c))) ||
            (AIRail.IsRailTile(c) && !AIRail.IsRailDepotTile(c) && !AIRail.IsRailStationTile(c) && ((AIRail.GetRailTracks(c) & (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_SW_SE + AIRail.RAILTRACK_NW_SW)) != 0)))) {

        if (AITunnel.IsTunnelTile(c)) {
            c = AITunnel.GetOtherTunnelEnd(c);
        }
        if (AIBridge.IsBridgeTile(c)) {
            c = AIBridge.GetOtherBridgeEnd(c);
        }


        tlist.AddItem(c, o);
        o++;
        //AISign.BuildSign(c, o + " ")
        TwinWalk(c, o, tlist, range);
    }
    if (!tlist.HasItem(d) && (
            (AITunnel.IsTunnelTile(d) && (AIMap.GetTileY(AITunnel.GetOtherTunnelEnd(d)) == AIMap.GetTileY(d)) && (AIMap.GetTileX(AITunnel.GetOtherTunnelEnd(d)) > AIMap.GetTileX(d))) ||
            (AIBridge.IsBridgeTile(d) && (AIMap.GetTileY(AIBridge.GetOtherBridgeEnd(d)) == AIMap.GetTileY(d)) && (AIMap.GetTileX(AIBridge.GetOtherBridgeEnd(d)) > AIMap.GetTileX(d))) ||
            (AIRail.IsRailTile(d) && !AIRail.IsRailDepotTile(d) && !AIRail.IsRailStationTile(d) && ((AIRail.GetRailTracks(d) & (AIRail.RAILTRACK_NE_SW + AIRail.RAILTRACK_NE_SE + AIRail.RAILTRACK_NW_NE)) != 0)))) {

        if (AITunnel.IsTunnelTile(d)) {
            d = AITunnel.GetOtherTunnelEnd(d);
        }
        if (AIBridge.IsBridgeTile(d)) {
            d = AIBridge.GetOtherBridgeEnd(d);
        }


        tlist.AddItem(d, o);
        o++;
        //AISign.BuildSign(d, o + " ")
        TwinWalk(d, o, tlist, range);
    }

    return tlist;

}

//===================================
// Use our list to build some passing places!
//===================================
function CivilAI::BuildPassingPlaces(tlist, tlen) {

    local pp = [];
    local pin = null;
    local pot = null;
    local pc = 0;
    local po = -10;
    local st = true;
    local prevt = null;
    local prevprevt = null;
    local pl = 0;

    tlist.Sort(AIList.SORT_BY_VALUE, true);

    foreach(t, c in tlist) {
        pc++;
        if (pc == 2 && st == true && pin == null) {
            st = false
        } // force a first pin on straight track


        if ((AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NE_SW || AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NW_SE) &&
            st == false) {
            st = true;
            if ((pc - po) > 3) { // don't put two passing places too close together - it may result in an unremovable junction
                pin = t;
            } else {
                pin = null;
            }
        } else if (!(AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NE_SW || AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NW_SE) &&
            st == true &&
            pin != null
        ) {
            st = false;
            pot = prevt;
            pl = AIMap.DistanceManhattan(pin, pot);
            if (pl > tlen + 1) {
                po = pc;
                pp.append([pin, pot])
            } else {
                pin = null;
            }
        } else if (!(AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NE_SW || AIRail.GetRailTracks(t) == AIRail.RAILTRACK_NW_SE)) {
            st = false;
        }

        //AISign.BuildSign (t, (tlist.Count() - pc) + " ");

        if (((tlist.Count() - pc) == 2) && st == true && pin != null) { // force a last pot on straight track

            pl = AIMap.DistanceManhattan(pin, t);
            if (pl > tlen + 1) {

                st = false;
                pot = prevprevt;
                po = pc;
                pp.append([pin, pot])

            }
        }
        prevprevt = prevt;
        prevt = t;
    }

    AILog.Info(pp.len() + " potential passing places found.");

    for (local o = 0; o < pp.len(); o++) {
        BuildPassingPlace(pp[o], tlen);
    }

}

function CivilAI::BuildPassingPlace(p, tlen) {
    local pin = p[0];
    local pot = p[1];
    local pl = AIMap.DistanceManhattan(pin, pot);
    local phi = false;
    local dir = 0;
    local pswap;
    local tt;
    local t2;
    local t3;
    local kink;
    local p1;
    local p1t;
    local p2;
    local p2t;


    // passing places are symmetrical so we can make the low (+) end always pin and only have 2 orientations to worry about.
    if (AIMap.GetTileX(pin) < AIMap.GetTileX(pot) || AIMap.GetTileY(pin) < AIMap.GetTileY(pot)) {
        pswap = pot;
        pot = pin;
        pin = pswap;
    }

    local ping = [AIMap.GetTileX(pin), AIMap.GetTileY(pin)]
    local potg = [AIMap.GetTileX(pot), AIMap.GetTileY(pot)]
    local pint;
    local pott;


    if (AIRail.GetRailTracks(pin) == AIRail.RAILTRACK_NE_SW) {
        dir = 2;
    } else {
        dir = 0;
    }

    // test pin for which side we want to build the passing place
    if (dir == 2) {
        pint = AIMap.GetTileIndex(ping[0] + 1, ping[1] + 0)
    } else {
        pint = AIMap.GetTileIndex(ping[0] + 0, ping[1] + 1);
    }
    if (dir == 2) {
        pott = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 0)
    } else {
        pott = AIMap.GetTileIndex(potg[0] + 0, potg[1] - 1);
    }

    if (AIRail.GetRailTracks(pint) == AIRail.RAILTRACK_NW_NE) {
        phi = true;
    } else if (AIRail.GetRailTracks(pint) == AIRail.RAILTRACK_NW_SW ||
        AIRail.GetRailTracks(pint) == AIRail.RAILTRACK_NE_SE) {
        phi = false;
    } else { // pin is forced, check pot		 
        if (AIRail.GetRailTracks(pott) == AIRail.RAILTRACK_SW_SE) {
            phi = false;
        } else {
            phi = true;
        }
    }

    if (dir == 0) {
        if (phi == false) {
            p1 = AIMap.GetTileIndex(ping[0] + 1, ping[1] - 1)
            p1t = AIMap.GetTileIndex(ping[0] + 1, ping[1] - 0)
            p2 = AIMap.GetTileIndex(potg[0] + 1, potg[1] + 1)
            p2t = AIMap.GetTileIndex(potg[0] + 1, potg[1] - 0)
        } else {
            p1 = AIMap.GetTileIndex(ping[0] - 1, ping[1] - 1)
            p1t = AIMap.GetTileIndex(ping[0] - 1, ping[1] - 0)
            p2 = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 1)
            p2t = AIMap.GetTileIndex(potg[0] - 1, potg[1] - 0)
        }
    } else {
        if (phi == false) {
            p1 = AIMap.GetTileIndex(ping[0] - 1, ping[1] + 1)
            p1t = AIMap.GetTileIndex(ping[0] - 0, ping[1] + 1)
            p2 = AIMap.GetTileIndex(potg[0] + 1, potg[1] + 1)
            p2t = AIMap.GetTileIndex(potg[0] - 0, potg[1] + 1)
        } else {
            p1 = AIMap.GetTileIndex(ping[0] - 1, ping[1] - 1)
            p1t = AIMap.GetTileIndex(ping[0] - 0, ping[1] - 1)
            p2 = AIMap.GetTileIndex(potg[0] + 1, potg[1] - 1)
            p2t = AIMap.GetTileIndex(potg[0] - 0, potg[1] - 1)
        }

    }

    if (!AITile.IsBuildable(p1) || !AITile.IsBuildable(p2) || !AITile.IsBuildable(p1t) || !AITile.IsBuildable(p2t)) { // try the other side if construction tiles are blocked

        phi = !phi;
    }

    // clear and flatten
    for (local o = 0; o < pl; o++) {
        if (dir == 0) {
            if (phi == false) {
                tt = AIMap.GetTileIndex(ping[0] + 1, ping[1] - o)
                t2 = AIMap.GetTileIndex(ping[0] + 0, ping[1] - o)
                t3 = AIMap.GetTileIndex(ping[0] + 2, ping[1] - o)
                if (AITile.GetMaxHeight(tt) > AITile.GetMaxHeight(t2)) {
                    AITile.LevelTiles(t2, t3)
                } else {
                    AITile.LevelTiles(t2, tt)
                }
            } else {
                tt = AIMap.GetTileIndex(ping[0] - 1, ping[1] - o)
                t2 = AIMap.GetTileIndex(ping[0] + 0, ping[1] - o)
                t3 = AIMap.GetTileIndex(ping[0] + 1, ping[1] - o)
                if (AITile.GetMaxHeight(tt) > AITile.GetMaxHeight(t2)) {
                    AITile.LevelTiles(t3, tt)
                } else {
                    AITile.LevelTiles(t3, t2)
                }
            }
        } else {
            if (phi == false) {
                tt = AIMap.GetTileIndex(ping[0] - o, ping[1] + 1)
                t2 = AIMap.GetTileIndex(ping[0] - o, ping[1] + 0)
                t3 = AIMap.GetTileIndex(ping[0] - o, ping[1] + 2)
                if (AITile.GetMaxHeight(tt) > AITile.GetMaxHeight(t2)) {
                    AITile.LevelTiles(t2, t3)
                } else {
                    AITile.LevelTiles(t2, tt)
                }
            } else {
                tt = AIMap.GetTileIndex(ping[0] - o, ping[1] - 1)
                t2 = AIMap.GetTileIndex(ping[0] - o, ping[1] + 0)
                t3 = AIMap.GetTileIndex(ping[0] - o, ping[1] + 1)
                if (AITile.GetMaxHeight(tt) > AITile.GetMaxHeight(t2)) {
                    AITile.LevelTiles(t3, tt)
                } else {
                    AITile.LevelTiles(t3, t2)
                }
            }
        }
        if (!AITile.IsBuildable(tt)) {

            if (AITile.GetOwner(tt) == Me || !AITile.DemolishTile(tt)) {

                if (o > tlen + 3) { // bring pot back if the passing place is already long enough and an obstacle is in the way

                    if (dir == 2) {
                        pot = AIMap.GetTileIndex(ping[0] - (o - 2), ping[1] + 0)
                    } else {
                        pot = AIMap.GetTileIndex(ping[0] + 0, ping[1] - (o - 2))
                    }
                    potg = [AIMap.GetTileX(pot), AIMap.GetTileY(pot)]
                    if (dir == 2) {
                        pott = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 0)
                    } else {
                        pott = AIMap.GetTileIndex(potg[0] + 0, potg[1] - 1);
                    }

                    pl = (o - 2);

                    break;
                } else if (pl - o > tlen + 3) { // push pin forward if the passing place will still be long enough and an obstacle is in the way

                    if (dir == 2) {
                        pin = AIMap.GetTileIndex(ping[0] - (o + 2), ping[1] + 0)
                    } else {
                        pin = AIMap.GetTileIndex(ping[0] + 0, ping[1] - (o + 2))
                    }
                    ping = [AIMap.GetTileX(pin), AIMap.GetTileY(pin)]
                    if (dir == 2) {
                        pint = AIMap.GetTileIndex(ping[0] + 1, ping[1] + 0)
                    } else {
                        pint = AIMap.GetTileIndex(ping[0] + 0, ping[1] + 1);
                    }

                    pl = (pl - (o + 2));
                }
            }
        }

        // AISign.BuildSign(tt, "_");
    }

    if (dir == 0) {
        if (phi == false) {
            p1 = AIMap.GetTileIndex(ping[0] + 1, ping[1] - 1)
            p1t = AIMap.GetTileIndex(ping[0] + 1, ping[1] - 0)
            p2 = AIMap.GetTileIndex(potg[0] + 1, potg[1] + 1)
            p2t = AIMap.GetTileIndex(potg[0] + 1, potg[1] - 0)
        } else {
            p1 = AIMap.GetTileIndex(ping[0] - 1, ping[1] - 1)
            p1t = AIMap.GetTileIndex(ping[0] - 1, ping[1] - 0)
            p2 = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 1)
            p2t = AIMap.GetTileIndex(potg[0] - 1, potg[1] - 0)
        }
    } else {
        if (phi == false) {
            p1 = AIMap.GetTileIndex(ping[0] - 1, ping[1] + 1)
            p1t = AIMap.GetTileIndex(ping[0] - 0, ping[1] + 1)
            p2 = AIMap.GetTileIndex(potg[0] + 1, potg[1] + 1)
            p2t = AIMap.GetTileIndex(potg[0] - 0, potg[1] + 1)
        } else {
            p1 = AIMap.GetTileIndex(ping[0] - 1, ping[1] - 1)
            p1t = AIMap.GetTileIndex(ping[0] - 0, ping[1] - 1)
            p2 = AIMap.GetTileIndex(potg[0] + 1, potg[1] - 1)
            p2t = AIMap.GetTileIndex(potg[0] - 0, potg[1] - 1)
        }

    }

    // build track (pathfinder)
    if (BuildALine([
            [p1, p1t]
        ], [
            [p2, p2t]
        ])) { // build the passing track

        local ok = true; // turn this flag off if we fail to build a piece

        // analyse pin -------------------------------------

        if (dir == 0) {
            tt = AIMap.GetTileIndex(ping[0] + 0, ping[1] + 1) // tile behind pin


            if ((AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_SW) && phi == false) { // regular bend plo
                t2 = AIMap.GetTileIndex(ping[0] + 1, ping[1] + 1) // connect tile
                t3 = AIMap.GetTileIndex(ping[0] + 2, ping[1] + 2) // levelling tile (target below)
                AITile.LevelTiles(pin, p1t) // level the connect tile	
                AITile.LevelTiles(tt, t3) // level the connect tile	
                if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NW_SE);
                //AISign.BuildSign(tt, "tt " + dir + " " + phi); AISign.BuildSign(t2, "t2"); AISign.BuildSign(t3, "t3"); AISign.BuildSign(p1t, "p1t"); AISign.BuildSign(pin, "pin"); 	 	

                t3 = AIMap.GetTileIndex(ping[0] + 1, ping[1] + 2) // kink track
                if (AIRail.GetRailTracks(t2) != AIRail.RAILTRACK_NE_SW) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_SE)
                } else if (AIRail.GetRailTracks(t3) != AIRail.RAILTRACK_NW_NE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_SW)
                } else {
                    ok = false;
                }

            } else if (phi == false) { // reverse bend plo 
                t2 = AIMap.GetTileIndex(ping[0] + 1, ping[1] + 1) // hook tile
                t3 = AIMap.GetTileIndex(ping[0] + 2, ping[1] + 2) // level tile
                AITile.LevelTiles(pin, p1t) // level
                //AISign.BuildSign(tt, "tt " + dir + " " + phi); AISign.BuildSign(t2, "t2"); AISign.BuildSign(t3, "t3"); AISign.BuildSign(p1t, "p1t"); AISign.BuildSign(pin, "pin"); 	 	

                if (FlatRail(pin, 0) && FlatRail(p1t, 0)) {
                    if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NW_NE);
                    if (ok) ok = PBuild(pin, AIRail.RAILTRACK_SW_SE);
                } else if (FlatRail(tt, 0)) {
                    AITile.LevelTiles(tt, t2) // level
                    AITile.LevelTiles(t2, t3) // level
                    if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NW_SE);
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_NE);
                    if (AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_SE) {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_SW_SE)
                    } else {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NE_SW)
                    }

                } else {
                    DemoWalk(p1t, 0, false); // pin is on a slope, abandon the passing place
                    return;
                }


            } else if ((AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_NE) && phi == true) { // regular bend phi
                t2 = AIMap.GetTileIndex(ping[0] - 1, ping[1] + 1) // connect tile
                t3 = AIMap.GetTileIndex(ping[0] + 0, ping[1] + 2) // levelling tile (start below)
                AITile.LevelTiles(t3, t2) // level the connect tile				
                if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NW_SE);
                //AISign.BuildSign(tt, "tt " + dir + " " + phi); AISign.BuildSign(t2, "t2"); AISign.BuildSign(t3, "t3"); AISign.BuildSign(p1t, "p1t"); AISign.BuildSign(pin, "pin"); 	 	

                t3 = AIMap.GetTileIndex(ping[0] - 2, ping[1] + 1) // kink track				
                if (AIRail.GetRailTracks(t2) != AIRail.RAILTRACK_NE_SW) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_SE)
                } else if (AIRail.GetRailTracks(t3) != AIRail.RAILTRACK_NW_SW) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_NE)
                } else {
                    ok = false;
                }

            } else if (phi == true) { // reverse bend phi
                t2 = AIMap.GetTileIndex(ping[0] - 1, ping[1] + 1) // hook tile
                t3 = AIMap.GetTileIndex(ping[0] + 1, ping[1] + 0) // level tile
                AITile.LevelTiles(t3, p1t) // level
                //AISign.BuildSign(tt, "tt " + dir + " " + phi); AISign.BuildSign(t2, "t2"); AISign.BuildSign(t3, "t3"); AISign.BuildSign(p1t, "p1t"); AISign.BuildSign(pin, "pin"); 	 	

                if (FlatRail(pin, 0) && FlatRail(p1t, 0)) {
                    if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NW_SW);
                    if (ok) ok = PBuild(pin, AIRail.RAILTRACK_NE_SE);
                } else if (FlatRail(tt, 0)) {
                    AITile.LevelTiles(tt, t2) // level
                    if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NW_SE);
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_SW);

                    if (AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_SE) {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NE_SE)
                    } else {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NE_SW)
                    }

                } else {
                    DemoWalk(p1t, 0, false); // pin is on a slope, abandon the passing place
                    return;
                }

            }

        } else {
            tt = AIMap.GetTileIndex(ping[0] + 1, ping[1] + 0) // tile behind pin


            if ((AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NE_SE) && phi == false) { // regular bend plo
                t2 = AIMap.GetTileIndex(ping[0] + 1, ping[1] + 1) // connect tile
                t3 = AIMap.GetTileIndex(ping[0] + 2, ping[1] + 2) // levelling tile (target below)
                AITile.LevelTiles(pin, p1t) // level the connect tile	
                AITile.LevelTiles(tt, t3) // level the connect tile				
                //AISign.BuildSign(tt, "tt " + dir + " " + phi); AISign.BuildSign(t2, "t2"); AISign.BuildSign(t3, "t3"); AISign.BuildSign(p1t, "p1t"); AISign.BuildSign(pin, "pin"); 	 	

                if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NE_SW);
                t3 = AIMap.GetTileIndex(ping[0] + 2, ping[1] + 1) // kink track				
                if (AIRail.GetRailTracks(t2) != AIRail.RAILTRACK_NW_SE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NE_SW)
                } else if (AIRail.GetRailTracks(t3) != AIRail.RAILTRACK_NW_NE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NE_SE)
                } else {
                    ok = false;
                }

            } else if (phi == false) { // reverse bend plo 
                t2 = AIMap.GetTileIndex(ping[0] + 1, ping[1] + 1) // hook tile
                t3 = AIMap.GetTileIndex(ping[0] + 2, ping[1] + 2) // level tile
                AITile.LevelTiles(pin, p1t) // level	
                //AISign.BuildSign(tt, "tt " + dir + " " + phi); AISign.BuildSign(t2, "t2"); AISign.BuildSign(t3, "t3"); AISign.BuildSign(p1t, "p1t"); AISign.BuildSign(pin, "pin"); 	 	

                if (FlatRail(pin, 2) && FlatRail(p1t, 2)) {
                    if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NW_NE);
                    if (ok) ok = PBuild(pin, AIRail.RAILTRACK_SW_SE);
                } else if (FlatRail(tt, 2)) {
                    AITile.LevelTiles(tt, t2) // level
                    AITile.LevelTiles(t2, t3) // level
                    if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NE_SW);
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_NE);
                    if (AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NE_SW) {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_SW_SE)
                    } else {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NW_SE)
                    }

                } else {
                    ok = false;
                }


            } else if ((AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_NE) && phi == true) { // regular bend phi
                t2 = AIMap.GetTileIndex(ping[0] + 1, ping[1] - 1) // connect tile
                t3 = AIMap.GetTileIndex(ping[0] + 2, ping[1] + 0) // levelling tile (start below)
                AITile.LevelTiles(t3, t2) // level the connect tile				
                if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NE_SW);

                //AISign.BuildSign(tt, "tt " + dir + " " + phi); AISign.BuildSign(t2, "t2"); AISign.BuildSign(t3, "t3"); AISign.BuildSign(p1t, "p1t"); AISign.BuildSign(pin, "pin"); 	 	

                t3 = AIMap.GetTileIndex(ping[0] + 1, ping[1] - 2) // kink track					
                if (AIRail.GetRailTracks(t2) != AIRail.RAILTRACK_NW_SE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NE_SW)
                } else if (AIRail.GetRailTracks(t3) != AIRail.RAILTRACK_NE_SE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_NE)
                } else {
                    ok = false;
                }

            } else if (phi == true) { // reverse bend phi
                t2 = AIMap.GetTileIndex(ping[0] + 1, ping[1] - 1) // hook tile
                t3 = AIMap.GetTileIndex(ping[0] + 0, ping[1] + 1) // level tile
                AITile.LevelTiles(t3, p1t) // level
                //AISign.BuildSign(tt, "tt " + dir + " " + phi); AISign.BuildSign(t2, "t2"); AISign.BuildSign(t3, "t3"); AISign.BuildSign(p1t, "p1t"); AISign.BuildSign(pin, "pin"); 	 	

                if (FlatRail(pin, 2) && FlatRail(p1t, 2)) {
                    if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NE_SE);
                    if (ok) ok = PBuild(pin, AIRail.RAILTRACK_NW_SW);
                } else if (FlatRail(tt, 2)) {
                    AITile.LevelTiles(tt, t2) // level
                    if (ok) ok = PBuild(p1t, AIRail.RAILTRACK_NE_SW);
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NE_SE);
                    if (AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NE_SW) {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NW_SW)
                    } else {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NW_SE)
                    }

                } else {
                    ok = false;
                }

            }

        }

        // analyse pot -------------------------------------

        if (dir == 0) {
            tt = AIMap.GetTileIndex(potg[0] + 0, potg[1] - 1) // tile behind pot


            if ((AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_SW_SE) && phi == false) { // regular bend plo
                t2 = AIMap.GetTileIndex(potg[0] + 1, potg[1] - 1) // connect tile
                t3 = AIMap.GetTileIndex(potg[0] + 2, potg[1] - 1) // levelling tile (target below)
                AITile.LevelTiles(p2t, pot) // level the connect tile	
                AITile.LevelTiles(pot, t3) // level the connect tile				
                if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NW_SE);

                t3 = AIMap.GetTileIndex(potg[0] + 2, potg[1] - 1) // kink track	
                if (AIRail.GetRailTracks(t2) != AIRail.RAILTRACK_NE_SW) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_SE)
                } else if (AIRail.GetRailTracks(t3) != AIRail.RAILTRACK_NE_SE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_SW_SE)
                } else {
                    ok = false;
                }

            } else if (phi == false) { // reverse bend plo
                t2 = AIMap.GetTileIndex(potg[0] + 1, potg[1] - 1) // hook tile
                t3 = AIMap.GetTileIndex(potg[0] + 2, potg[1] - 0) // level tile
                AITile.LevelTiles(pot, p2t) // level
                AITile.LevelTiles(pot, t3) // level				
                if (FlatRail(pot, 0) && FlatRail(p2t, 0)) {
                    if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NE_SE);
                    if (ok) ok = PBuild(pot, AIRail.RAILTRACK_NW_SW);
                } else if (FlatRail(tt, 0)) {
                    AITile.LevelTiles(p2t, pot) // level
                    AITile.LevelTiles(pot, t2) // level
                    if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NW_SE);
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NE_SE);
                    if (AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_SE) {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NW_SW)
                        // todo check kink				
                    } else {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NE_SW)
                    }

                } else {
                    ok = false;
                }


            } else if ((AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NE_SE) && phi == true) { // regular bend phi
                t2 = AIMap.GetTileIndex(potg[0] - 1, potg[1] - 1) // connect tile
                t3 = AIMap.GetTileIndex(potg[0] + 1, potg[1] - 0) // levelling tile (start below)
                AITile.LevelTiles(t3, pot) // level the connect tile		
                AITile.LevelTiles(pot, t2) // level the connect tile					 
                if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NW_SE);

                t3 = AIMap.GetTileIndex(potg[0] - 2, potg[1] - 1) // kink track	
                if (AIRail.GetRailTracks(t2) != AIRail.RAILTRACK_NE_SW) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_SE)
                } else if (AIRail.GetRailTracks(t3) != AIRail.RAILTRACK_SW_SE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NE_SE)
                } else {
                    ok = false;
                }

            } else if (phi == true) { // reverse bend phi
                t2 = AIMap.GetTileIndex(potg[0] - 1, potg[1] - 1) // hook tile
                t3 = AIMap.GetTileIndex(potg[0] + 1, potg[1] - 0) // level tile
                AITile.LevelTiles(t3, p2t) // level
                if (FlatRail(pot, 0) && FlatRail(p2t, 0)) {
                    if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_SW_SE);
                    if (ok) ok = PBuild(pot, AIRail.RAILTRACK_NW_NE);
                } else if (FlatRail(tt, 0)) {
                    AITile.LevelTiles(tt, p2t) // level
                    if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NW_SE);
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_SW_SE);
                    if (AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_SE) {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NW_NE)
                        // todo check kink				
                    } else {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NE_SW)
                    }

                } else {
                    ok = false;
                }





            }



        } else {
            tt = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 0) // tile behind pot


            if ((AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_SW_SE) && phi == false) { // regular bend plo
                t2 = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 1) // connect tile
                t3 = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 2) // levelling tile (target below)
                AITile.LevelTiles(p2t, pot) // level the connect tile	
                AITile.LevelTiles(pot, t3) // level the connect tile				
                if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NE_SW);

                t3 = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 2) // kink track	
                if (AIRail.GetRailTracks(t2) != AIRail.RAILTRACK_NW_SE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NE_SW)
                } else if (AIRail.GetRailTracks(t3) != AIRail.RAILTRACK_NW_SW) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_SW_SE)
                } else {
                    ok = false;
                }




            } else if (phi == false) { // reverse bend plo
                t2 = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 1) // hook tile
                t3 = AIMap.GetTileIndex(potg[0] - 0, potg[1] + 2) // level tile
                AITile.LevelTiles(pot, p2t) // level
                AITile.LevelTiles(pot, t3) // level				
                if (FlatRail(pot, 2) && FlatRail(p2t, 2)) {
                    if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NW_SW);
                    if (ok) ok = PBuild(pot, AIRail.RAILTRACK_NE_SE);
                } else if (FlatRail(tt, 2)) {
                    AITile.LevelTiles(p2t, pot) // level
                    AITile.LevelTiles(pot, t2) // level
                    if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NE_SW);
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_SW);
                    if (AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NE_SW) {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NE_SE)
                        // todo check kink				
                    } else {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NW_SE)
                    }

                } else {
                    ok = false;
                }


            } else if ((AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NW_SW) && phi == true) { // regular bend phi
                t2 = AIMap.GetTileIndex(potg[0] - 1, potg[1] - 1) // connect tile
                t3 = AIMap.GetTileIndex(potg[0] - 0, potg[1] + 1) // levelling tile (start below)
                AITile.LevelTiles(t3, pot) // level the connect tile		
                AITile.LevelTiles(pot, t2) // level the connect tile					 
                if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NE_SW);

                t3 = AIMap.GetTileIndex(potg[0] - 1, potg[1] + 2) // kink track	
                if (AIRail.GetRailTracks(t2) != AIRail.RAILTRACK_NW_SE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NE_SW)
                } else if (AIRail.GetRailTracks(t3) != AIRail.RAILTRACK_SW_SE) {
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_NW_SW)
                } else {
                    ok = false;
                }

            } else if (phi == true) { // reverse bend phi
                t2 = AIMap.GetTileIndex(potg[0] - 1, potg[1] - 1) // hook tile
                t3 = AIMap.GetTileIndex(potg[0] - 0, potg[1] + 1) // level tile
                AITile.LevelTiles(t3, p2t) // level				
                if (FlatRail(pot, 2) && FlatRail(p2t, 2)) {
                    if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_SW_SE);
                    if (ok) ok = PBuild(pot, AIRail.RAILTRACK_NW_NE);
                } else if (FlatRail(tt, 2)) {
                    AITile.LevelTiles(tt, p2t) // level
                    if (ok) ok = PBuild(p2t, AIRail.RAILTRACK_NE_SW);
                    if (ok) ok = PBuild(t2, AIRail.RAILTRACK_SW_SE);
                    if (AIRail.GetRailTracks(tt) == AIRail.RAILTRACK_NE_SW) {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NW_NE)
                        // todo check kink				
                    } else {
                        if (ok) ok = PBuild(tt, AIRail.RAILTRACK_NW_SE)
                    }

                } else {
                    ok = false;
                }





            }



        }



        //AISign.BuildSign(p1, "p1");
        //AISign.BuildSign(p2, "p2");
        //AISign.BuildSign(p1t, "p1t");
        //AISign.BuildSign(p2t, "p2t");
        //AISign.BuildSign(pin, "pin");
        //AISign.BuildSign(pot, "pot"); 
        //AISign.BuildSign(tt, "tt");				
        //AISign.BuildSign(t2, "t2");
        //AISign.BuildSign(t3, "t3");


        // -------------------------------------------------

        if (!ok) {
            AILog.Info("I failed to build the passing place track.")
            DemoWalk(p1t, 0, false); // something went wrong, abandon the passing place
            DemoWalk(p2t, 0, false); // something went wrong, abandon the passing place

            return;
        } else {

            // place signals

            local siga = 10; // how long since we placed a signal
            local sigup; // signal tile up (heading north)
            local sigdn; // signal tile dn (heading south)
            local sigt; // signal target tile

            //AILog.Info ("signal " + pl)

            if (dir == 0) {

                if (LeftHand) {
                    if (!phi) {
                        sigup = p2t;
                        sigdn = pin;
                    } else {
                        sigup = pot;
                        sigdn = p1t;
                    }
                } else {
                    if (phi) {
                        sigup = p2t;
                        sigdn = pin;
                    } else {
                        sigup = pot;
                        sigdn = p1t;
                    }
                }

                for (local o = 0; o <= (pl - tlen); o++) {
                    sigt = AIMap.GetTileIndex(AIMap.GetTileX(sigup), AIMap.GetTileY(sigup) + 1)
                    if (siga > tlen - 1 &&
                        AIRail.BuildSignal(sigup, sigt, AIRail.SIGNALTYPE_PBS_ONEWAY)) {
                        //			AISign.BuildSign(sigup, "up");
                        siga = 0;
                    } else {
                        siga++;
                    }
                    sigup = AIMap.GetTileIndex(AIMap.GetTileX(sigup), AIMap.GetTileY(sigup) + 1)

                }

                siga = 10;

                for (local o = 0; o <= (pl - tlen); o++) {
                    sigt = AIMap.GetTileIndex(AIMap.GetTileX(sigdn), AIMap.GetTileY(sigdn) - 1)
                    if (siga > tlen - 1 &&
                        AIRail.BuildSignal(sigdn, sigt, AIRail.SIGNALTYPE_PBS_ONEWAY)) {
                        //			AISign.BuildSign(sigdn, "dn");
                        siga = 0;
                    } else {
                        siga++;
                    }
                    sigdn = AIMap.GetTileIndex(AIMap.GetTileX(sigdn), AIMap.GetTileY(sigdn) - 1)
                }

            } else {

                if (LeftHand) {
                    if (phi) {
                        sigup = p2t;
                        sigdn = pin;
                    } else {
                        sigup = pot;
                        sigdn = p1t;
                    }
                } else {
                    if (!phi) {
                        sigup = p2t;
                        sigdn = pin;
                    } else {
                        sigup = pot;
                        sigdn = p1t;
                    }
                }


                for (local o = 0; o <= (pl - tlen); o++) {
                    sigt = AIMap.GetTileIndex(AIMap.GetTileX(sigup) + 1, AIMap.GetTileY(sigup))
                    if (siga > tlen - 1 &&
                        AIRail.BuildSignal(sigup, sigt, AIRail.SIGNALTYPE_PBS_ONEWAY)) {
                        //			AISign.BuildSign(sigup, "up");
                        siga = 0;
                    } else {
                        siga++;
                    }
                    sigup = AIMap.GetTileIndex(AIMap.GetTileX(sigup) + 1, AIMap.GetTileY(sigup))
                }

                siga = 10;

                for (local o = 0; o <= (pl - tlen); o++) {
                    sigt = AIMap.GetTileIndex(AIMap.GetTileX(sigdn) - 1, AIMap.GetTileY(sigdn))
                    if (siga > tlen - 1 &&
                        AIRail.BuildSignal(sigdn, sigt, AIRail.SIGNALTYPE_PBS_ONEWAY)) {
                        //			AISign.BuildSign(sigdn, "dn");
                        siga = 0;
                    } else {
                        siga++;
                    }
                    sigdn = AIMap.GetTileIndex(AIMap.GetTileX(sigdn) - 1, AIMap.GetTileY(sigdn))
                }








            }

        }


    } else {
        AILog.Info("I failed to build the passing place track.")
        return;
    }
}