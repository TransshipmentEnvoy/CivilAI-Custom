// ====================================================== 
// ====================================================== 
// 			   RRRR     A    I  L		 2222
// 			   R   R   A A   I  L		2	 2
// 			   R  R   A   A  I  L		   2
//  		   RRRR   AAAAA  I  L	     2
//  		   R   R  A   A  I  LLLLL   222222 (for passengers!)
// ===========================================ChooChoo!== 
// ====================================================== 

// as time has passed since the old industrial rail system was coded, and documentation has been lost
// it's important to note that the side/face numbering may have changed. 0/1 = -/+y, 2/3 = -/+ x.

function CivilAI::PaxLine(town1, town2, existingstation1, existingstation2) {

    // first, check we can afford to build

    local dosh = AICompany.GetBankBalance(Me);
    local cost;
    local pax = FindCargo("PASS");

    cost = (
        (AIRail.GetBuildCost(AIRail.GetCurrentRailType(), AIRail.BT_TRACK) * AIMap.DistanceManhattan(AITown.GetLocation(town1), AITown.GetLocation(town1)) * 2) +
        (AITile.GetBuildCost(AITile.BT_CLEAR_FIELDS) * AIMap.DistanceManhattan(AITown.GetLocation(town1), AITown.GetLocation(town1))) +
        (AIRail.GetBuildCost(AIRail.GetCurrentRailType(), AIRail.BT_STATION) * 12) +
        (AIRail.GetBuildCost(AIRail.GetCurrentRailType(), AIRail.BT_DEPOT * 4)) +
        BuyATrain(0, 0, pax, 0, 3, true, 0)
    )

    //AILog.Info(cost); 

    if (dosh < cost) {
        AILog.Info("I can't afford to build a railway right now. Perhaps later.");
        return;
    }

    local connect1;
    local connect2;
    local ok = false;


    // determine side and face for first station

    local t1x = AIMap.GetTileX(AITown.GetLocation(town1));
    local t1y = AIMap.GetTileY(AITown.GetLocation(town1));
    local t2x = AIMap.GetTileX(AITown.GetLocation(town2));
    local t2y = AIMap.GetTileY(AITown.GetLocation(town2));
    local side;
    local face;

    local rx = t2x - t1x;
    local ry = t2y - t1y;

    if (ry > 0) {
        if (rx > 0) {
            // south
            if (rx > ry) {
                side = 1
                face = 3
            } else {
                side = 3
                face = 1
            }
        } else {
            // east
            if (-rx > ry) {
                side = 1
                face = 2
            } else {
                side = 2
                face = 1
            }
        }

    } else {

        if (rx > 0) {
            // west
            if (rx > -ry) {
                side = 0
                face = 3
            } else {
                side = 3
                face = 0
            }
        } else {
            // north
            if (-rx > -ry) {
                side = 0
                face = 2
            } else {
                side = 2
                face = 0
            }
        }
    }


    if (existingstation1 == null) {
        connect1 = PaxStation(town1, side, face);
    } else {
        connect1 = existingstation1;
    }
    if (connect1 != null) {
        if (existingstation2 == null) {
            // flip face for second station
            if (face % 2 == 0) {
                face++;
            } else {
                face--;
            }
            connect2 = PaxStation(town2, side, face);
        } else {
            connect2 = existingstation2;
        }
    }

    if (connect1 != null && connect2 != null &&
        AIStation.IsValidStation(connect1) && AIStation.IsValidStation(connect2)) {

        if (BuildPaxLine(connect1, connect2)) {
            local pax = FindCargo("PASS");
            local depot = FindTrainDepot(connect1);
            if (depot != null) {
                BuyATrain(connect1, connect2, pax, depot, 3, false, 0);
            }
        }
    }
    return;
}

//=================
//Build a passenger station

function CivilAI::PaxStation(town, side, face) {

    local NewStat = null;
    local xof = 0;
    local yof = 0;


    if (side == 1) {
        yof = 10
    } else if (side == 3) {
        xof = 10
    } else if (side == 0) {
        yof = -10
    } else {
        xof = -10
    }

    if (face == 1) {
        yof = yof + 5
    } else if (face == 3) {
        xof = xof + 5
    } else if (face == 0) {
        yof = yof - 5
    } else {
        xof = xof - 5
    }

    // clockwise spiral out, with longitudinal side bias
    local trytilegrid = [AIMap.GetTileX(AITown.GetLocation(town)) + xof, AIMap.GetTileY(AITown.GetLocation(town)) + yof]
    local trytile = AIMap.GetTileIndex(trytilegrid[0], trytilegrid[1]);
    local x = 0
    local y = 0
    local xbias = 1;
    local ybias = 1;
    local i = 0
    local s = 8
    local NewStat = null;

    if (side < 2) {
        ybias = 2;
    } else {
        xbias = 2;
    }

    while ((i < s) && NewStat == null) {
        if ((AITown.GetRating(town, Me) < 4) && (AITown.GetRating(town, Me) != -1)) {
            AILog.Info("My local authority rating isn't high enough.")
            return;
        }

        //y--
        for (; y >= 0 - i; y--) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + (x * xbias), trytilegrid[1] + (y * ybias));
            //AISign.BuildSign(trytile, side + "," + face);
            NewStat = BuildPaxStation(town, trytile, side, face);
            if (NewStat != null) {
                return NewStat;
            }
        }
        //x--;
        for (; x >= 0 - i; x--) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + (x * xbias), trytilegrid[1] + (y * ybias));
            //AISign.BuildSign(trytile, side + "," + face);
            NewStat = BuildPaxStation(town, trytile, side, face);
            if (NewStat != null) {
                return NewStat;
            }
        }
        //y++;
        for (; y <= i; y++) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + (x * xbias), trytilegrid[1] + (y * ybias));
            //AISign.BuildSign(trytile, side + "," + face);
            NewStat = BuildPaxStation(town, trytile, side, face);
            if (NewStat != null) {
                return NewStat;
            }
        }
        //x++;
        for (; x <= i; x++) {
            trytile = AIMap.GetTileIndex(trytilegrid[0] + (x * xbias), trytilegrid[1] + (y * ybias));
            //AISign.BuildSign(trytile, side + "," + face);
            NewStat = BuildPaxStation(town, trytile, side, face);
            if (NewStat != null) {
                return NewStat;
            }
        }
        i = i + 1
    }

    if (NewStat == null && (side != face)) {
        side = face;
        PaxStation(town, side, face); // try again but put the station on the nearside, facing away from the town
    } else if (NewStat == null) {

    }
    return NewStat;
}


//======
function CivilAI::BuildPaxStation(town, tile, side, face) {
    //=====

    local go = false;
    local tg = [AIMap.GetTileX(tile), AIMap.GetTileY(tile)]
    local tt = null;
    local pax = FindCargo("PASS");


    local bslist = AIStationList(AIStation.STATION_BUS_STOP);
    bslist.Valuate(AIStation.GetNearestTown);
    bslist.KeepValue(town);
    bslist.Valuate(AIStation.GetDistanceManhattanToTile, tile);
    bslist.Sort(AIList.SORT_BY_VALUE, true); // nearest first

    foreach(bs, b in bslist) {
        if (AIStation.HasStationType(bs, AIStation.STATION_TRAIN)) {
            //AILog.Info("Whoops! I already have a station in this town.")
            return bs;
        }
    }

    local bs = bslist.Begin();
    local s = AIGameSettings.GetValue("station.station_spread")
    if (AIStation.GetDistanceManhattanToTile(bs, tile) > s - 3) {
        return;
    }

    if (face < 2) { // station oriented on y axis
        if (!(AITile.IsBuildableRectangle(AIMap.GetTileIndex(tg[0] - 1, tg[1] - 3), 3, 7))) {
            return null;
        }
        if (!NoWater(AIMap.GetTileIndex(tg[0] - 1, tg[1] - 3), 3, 7)) {
            return null;
        }

        AITile.LevelTiles(tile, AIMap.GetTileIndex(tg[0] + 2, tg[1] + 3));
        AITile.LevelTiles(tile, AIMap.GetTileIndex(tg[0] - 1, tg[1] + 3));
        AITile.LevelTiles(tile, AIMap.GetTileIndex(tg[0] + 2, tg[1] - 2));
        AITile.LevelTiles(tile, AIMap.GetTileIndex(tg[0] - 1, tg[1] - 2));
        //AITile.LevelTiles(AIMap.GetTileIndex(tg[0]+2,tg[1]-3),AIMap.GetTileIndex(tg[0]-1,tg[1]+4));
        //AITile.LevelTiles(AIMap.GetTileIndex(tg[0]-1,tg[1]+4),AIMap.GetTileIndex(tg[0]+2,tg[1]-3));

        // check it's flattish
        if (!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] + 2, tg[1] + 3))) ||
            !(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] - 1, tg[1] + 2))) ||
            !(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] + 2, tg[1] - 2))) ||
            !(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] - 1, tg[1] - 1)))) {
            return null;
        }

        //AISign.BuildSign(AIMap.GetTileIndex(tg[0]+1,tg[1]+3), "+");
        //AISign.BuildSign(AIMap.GetTileIndex(tg[0]-1,tg[1]-3), "-");
        //AISign.BuildSign(tile, "C");

        if (face == 0) {
            tt = AIMap.GetTileIndex(tg[0], tg[1]);


            if (AltMethod) {
                if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NW_SE, 2, 3, AIStation.STATION_NEW, pax, AIIndustryType.INDUSTRYTYPE_TOWN, AIIndustryType.INDUSTRYTYPE_TOWN, 64, true)) {
                    go = true;
                }

            } else {

                foreach(bs, b in bslist) {
                    AILog.Info("Attempting to build a railway station at " + AIStation.GetName(bs) + ".");
                    if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NW_SE, 2, 3, bs, pax, AIIndustryType.INDUSTRYTYPE_TOWN, AIIndustryType.INDUSTRYTYPE_TOWN, 64, true)) {
                        go = true;
                        break;
                    }
                }
            }

        } else {

            tt = AIMap.GetTileIndex(tg[0], tg[1] - 2);
            if (AltMethod) {
                if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NW_SE, 2, 3, AIStation.STATION_NEW, pax, AIIndustryType.INDUSTRYTYPE_TOWN, AIIndustryType.INDUSTRYTYPE_TOWN, 64, true)) {
                    go = true;
                }

            } else {
                foreach(bs, b in bslist) {
                    AILog.Info("Attempting to build a railway station at " + AIStation.GetName(bs) + ".");
                    if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NW_SE, 2, 3, bs, pax, AIIndustryType.INDUSTRYTYPE_TOWN, AIIndustryType.INDUSTRYTYPE_TOWN, 64, true)) {
                        go = true;

                        break;
                    }
                }
            }

        }

    } else {
        if (!(AITile.IsBuildableRectangle(AIMap.GetTileIndex(tg[0] - 3, tg[1] - 1), 7, 3))) {
            return null;
        }
        if (!NoWater(AIMap.GetTileIndex(tg[0] - 3, tg[1] - 1), 7, 3)) {
            return null;
        }
        AITile.LevelTiles(tile, AIMap.GetTileIndex(tg[0] + 3, tg[1] + 2));
        AITile.LevelTiles(tile, AIMap.GetTileIndex(tg[0] + 3, tg[1] - 1));
        AITile.LevelTiles(tile, AIMap.GetTileIndex(tg[0] - 2, tg[1] + 2));
        AITile.LevelTiles(tile, AIMap.GetTileIndex(tg[0] - 2, tg[1] - 1));
        //AITile.LevelTiles(AIMap.GetTileIndex(tg[0]-3,tg[1]+2),AIMap.GetTileIndex(tg[0]+4,tg[1]-1));
        //AITile.LevelTiles(AIMap.GetTileIndex(tg[0]+4,tg[1]-1),AIMap.GetTileIndex(tg[0]-3,tg[1]+2));

        // check it's flattish
        if (!(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] + 3, tg[1] + 2))) ||
            !(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] + 2, tg[1] - 1))) ||
            !(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] - 2, tg[1] + 2))) ||
            !(AITile.GetMaxHeight(tile) == AITile.GetMaxHeight(AIMap.GetTileIndex(tg[0] - 1, tg[1] - 1)))) {
            return null;
        }

        //AISign.BuildSign(AIMap.GetTileIndex(tg[0]+3,tg[1]+1), "+");
        //AISign.BuildSign(AIMap.GetTileIndex(tg[0]-3,tg[1]-1), "-");
        //AISign.BuildSign(tile, "C");

        if (face == 2) {

            tt = AIMap.GetTileIndex(tg[0], tg[1]);
            if (AltMethod) {
                if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NE_SW, 2, 3, AIStation.STATION_NEW, pax, AIIndustryType.INDUSTRYTYPE_TOWN, AIIndustryType.INDUSTRYTYPE_TOWN, 64, true)) {
                    go = true;

                } else {
                    foreach(bs, b in bslist) {
                        AILog.Info("Attempting to build a railway station at " + AIStation.GetName(bs) + ".");
                        if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NE_SW, 2, 3, bs, pax, AIIndustryType.INDUSTRYTYPE_TOWN, AIIndustryType.INDUSTRYTYPE_TOWN, 64, true)) {
                            go = true;
                        }

                        break;
                    }
                }
            }

        } else {

            tt = AIMap.GetTileIndex(tg[0] - 2, tg[1]);
            if (AltMethod) {
                if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NE_SW, 2, 3, AIStation.STATION_NEW, pax, AIIndustryType.INDUSTRYTYPE_TOWN, AIIndustryType.INDUSTRYTYPE_TOWN, 64, true)) {
                    go = true;
                }

            } else {
                foreach(bs, b in bslist) {
                    AILog.Info("Attempting to build a railway station at " + AIStation.GetName(bs) + ".");
                    if (AIRail.BuildNewGRFRailStation(tt, AIRail.RAILTRACK_NE_SW, 2, 3, bs, pax, AIIndustryType.INDUSTRYTYPE_TOWN, AIIndustryType.INDUSTRYTYPE_TOWN, 64, true)) {
                        go = true;

                        break;
                    }
                }
            }
        }
    }

    if (go) {
        if (face == 0) {

            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 0, tg[1] - 1), AIRail.RAILTRACK_NW_SE)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 0, tg[1] - 2), AIRail.RAILTRACK_NE_SE)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 0, tg[1] - 2), AIRail.RAILTRACK_NE_SW)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 0, tg[1] - 2), AIRail.RAILTRACK_SW_SE)

            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 1, tg[1] - 1), AIRail.RAILTRACK_NW_SE)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 1, tg[1] - 2), AIRail.RAILTRACK_NE_SE)

            AIRail.BuildRailDepot(AIMap.GetTileIndex(tg[0] - 1, tg[1] - 2), AIMap.GetTileIndex(tg[0] + 0, tg[1] - 2))

            AIRail.BuildSignal(AIMap.GetTileIndex(tg[0] + 0, tg[1] - 1), AIMap.GetTileIndex(tg[0] + 0, tg[1]), AIRail.SIGNALTYPE_PBS);
            AIRail.BuildSignal(AIMap.GetTileIndex(tg[0] + 1, tg[1] - 1), AIMap.GetTileIndex(tg[0] + 1, tg[1]), AIRail.SIGNALTYPE_PBS);
        } else if (face == 1) {
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 0, tg[1] + 1), AIRail.RAILTRACK_NW_SE)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 0, tg[1] + 2), AIRail.RAILTRACK_NW_NE)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 0, tg[1] + 2), AIRail.RAILTRACK_NE_SW)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 0, tg[1] + 2), AIRail.RAILTRACK_NW_SW)

            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 1, tg[1] + 1), AIRail.RAILTRACK_NW_SE)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 1, tg[1] + 2), AIRail.RAILTRACK_NW_NE)

            AIRail.BuildRailDepot(AIMap.GetTileIndex(tg[0] - 1, tg[1] + 2), AIMap.GetTileIndex(tg[0] + 0, tg[1] + 2))

            AIRail.BuildSignal(AIMap.GetTileIndex(tg[0] + 0, tg[1] + 1), AIMap.GetTileIndex(tg[0] + 0, tg[1]), AIRail.SIGNALTYPE_PBS);
            AIRail.BuildSignal(AIMap.GetTileIndex(tg[0] + 1, tg[1] + 1), AIMap.GetTileIndex(tg[0] + 1, tg[1]), AIRail.SIGNALTYPE_PBS);
        } else if (face == 2) {
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] - 1, tg[1] + 0), AIRail.RAILTRACK_NE_SW)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] - 2, tg[1] + 0), AIRail.RAILTRACK_NW_SW)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] - 2, tg[1] + 0), AIRail.RAILTRACK_NW_SE)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] - 2, tg[1] + 0), AIRail.RAILTRACK_SW_SE)

            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] - 1, tg[1] + 1), AIRail.RAILTRACK_NE_SW)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] - 2, tg[1] + 1), AIRail.RAILTRACK_NW_SW)

            AIRail.BuildRailDepot(AIMap.GetTileIndex(tg[0] - 2, tg[1] - 1), AIMap.GetTileIndex(tg[0] - 2, tg[1] + 0))

            AIRail.BuildSignal(AIMap.GetTileIndex(tg[0] - 1, tg[1] + 0), AIMap.GetTileIndex(tg[0], tg[1] + 0), AIRail.SIGNALTYPE_PBS);
            AIRail.BuildSignal(AIMap.GetTileIndex(tg[0] - 1, tg[1] + 1), AIMap.GetTileIndex(tg[0], tg[1] + 1), AIRail.SIGNALTYPE_PBS);
        } else {
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 1, tg[1] + 0), AIRail.RAILTRACK_NE_SW)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 2, tg[1] + 0), AIRail.RAILTRACK_NW_NE)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 2, tg[1] + 0), AIRail.RAILTRACK_NW_SE)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 2, tg[1] + 0), AIRail.RAILTRACK_NE_SE)

            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 1, tg[1] + 1), AIRail.RAILTRACK_NE_SW)
            AIRail.BuildRailTrack(AIMap.GetTileIndex(tg[0] + 2, tg[1] + 1), AIRail.RAILTRACK_NW_NE)

            AIRail.BuildRailDepot(AIMap.GetTileIndex(tg[0] + 2, tg[1] - 1), AIMap.GetTileIndex(tg[0] + 2, tg[1] + 0))

            AIRail.BuildSignal(AIMap.GetTileIndex(tg[0] + 1, tg[1] + 0), AIMap.GetTileIndex(tg[0], tg[1] + 0), AIRail.SIGNALTYPE_PBS);
            AIRail.BuildSignal(AIMap.GetTileIndex(tg[0] + 1, tg[1] + 1), AIMap.GetTileIndex(tg[0], tg[1] + 1), AIRail.SIGNALTYPE_PBS);
        }

        return AIStation.GetStationID(tt)
    } else {
        return null;
    }
}


// =============
// build a line between the stations
// =============

function CivilAI::BuildPaxLine(stat1, stat2) {
    HillClimb = 0; // reset global vars
    BackTrackCounter = 0;

    local ok = false;

    // identify connecting tiles
    local goa = gotile(stat1);
    local gob = gotile(stat2);

    if (goa != null && gob != null) {
        if (BuildALine([goa], [gob])) {

            TwinTrack(goa, gob, GetStatLength(stat2));
            if (AttachLine(goa) && AttachLine(gob)) {
                ok = true;
            } else {
                DemoWalk(goa[0], 0, false);
                DemoWalk(gob[0], 0, false);
            }
        }


    }

    return ok;

}