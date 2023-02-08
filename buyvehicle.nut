// ====================================================== 
//                    FIND RVs TO BUY
// ======================================================  

// Buses, Coaches, Mail and Goods trucks are now unified in this single function (1.9)
function CivilAI::IdentifyBus(silent, intercity, cargo) {

    local busid = null;
    local vlist = 0;
    local blist = 0;
    local bcap = 0;
    local bdate = 0;
    local z = 0;

    local fast = BiasFast;
    local big = BiasBig;
    local cheap = BiasCheap;
    local fscore = 0;
    local bscore = 0;
    local cscore = 0;
    local tscore = 0;
    local hitea = null;

    if (intercity) {
        fast = BiasFast + 5; // prefer faster vehicles for intercity
    } else {
        big = BiasBig + 5; // prefer higher capacity for city
    }


    // check native vehicles first
    vlist = AIEngineList(AIVehicle.VT_ROAD); // list of all road vehicles
    foreach(rv, z in vlist) { // remove everything that can't carry the cargo
        if ((AIEngine.IsBuildable(rv)) &&
            (AIEngine.GetCargoType(rv) == cargo) &&
            (AIEngine.GetCapacity(rv) > 0) &&
            (AIEngine.GetRoadType(rv) == AIRoad.ROADTYPE_ROAD || (AIRoadTypeList(AIRoad.ROADTRAMTYPES_ROAD).HasItem(AIEngine.GetRoadType(rv)) && !BannedRoadTypes.HasItem(AIEngine.GetRoadType(rv))))) {

            //AILog.Info (AIEngine.GetName(rv) + " is a suitable vehicle.")
        } else {
            vlist.RemoveItem(rv);
        }
    }

    if (vlist.Count() == 0) { // no native vehicles found - check refittable vehicles
        vlist = AIEngineList(AIVehicle.VT_ROAD); // list of all road vehicles
        foreach(rv, z in vlist) { // remove everything that can't carry the cargo
            if ((AIEngine.IsBuildable(rv)) &&
                (AIEngine.CanRefitCargo(rv, cargo)) &&
                (AIEngine.GetCapacity(rv) > 0) &&
                (AIEngine.GetRoadType(rv) == AIRoad.ROADTYPE_ROAD || AIRoadTypeList(AIRoad.ROADTRAMTYPES_ROAD).HasItem(AIEngine.GetRoadType(rv)))) {

                //AILog.Info (AIEngine.GetName(rv) + " is a suitable vehicle.")
            } else {
                vlist.RemoveItem(rv);
            }
        }
    }

    if (vlist.Count() == 0) {
        return null;
    } else {

        // remove too-slow vehicles

        vlist.Valuate(AIEngine.GetMaxSpeed);
        vlist.Sort(AIList.SORT_BY_VALUE, true);

        foreach(rv, z in vlist) {
            if (
                (vlist.Count() > 1) &&
                (AIEngine.GetMaxSpeed(rv) < 20)
            ) {
                vlist.RemoveItem(rv);
            }
        }

        vlist.Valuate(AIBase.RandItem); // shuffle the list so if we have vehicles with the same values (eg different truck graphics) we'll get a random selection

        foreach(rv, z in vlist) { // score the vehicles
            fscore = AIEngine.GetMaxSpeed(rv) * fast / 4;
            bscore = AIEngine.GetCapacity(rv) * big / 2;
            cscore = (AIEngine.GetPrice(rv) + AIEngine.GetRunningCost(rv)) * cheap / 800;
            tscore = (fscore) + (bscore) - (cscore);

            //AILog.Info ("Scored " + AIEngine.GetName(rv) + " at " + tscore + " (" + fscore + "," + bscore + "," + cscore + ").");

            if (hitea == null || tscore > hitea) {
                busid = rv;
                hitea = tscore;
            }

        }
    }
    if (!silent) {
        AILog.Info("I've selected " + AIEngine.GetName(busid) + " to buy.")
    }
    return (busid);
}

// ====================================================== 
//                    FIND PASSENGER LOCO TO BUY
// ======================================================  

function CivilAI::PickPaxLoco(routelength, climb, railbase, oldHP, cargo, tlen) {

    local pax = FindCargo("PASS");
    local mail = FindCargo("MAIL");

    local rtypes = AIRailTypeList();
    local wrtypes = AIRailTypeList();

    if (railbase != null) {
        foreach(r, z in rtypes) {
            if (!(AIRail.TrainCanRunOnRail(railbase, r) && AIRail.TrainHasPowerOnRail(railbase, r))) {
                rtypes.RemoveItem(r);
            }
        }
        foreach(r, z in wrtypes) {
            if (!(AIRail.TrainCanRunOnRail(railbase, r))) {
                wrtypes.RemoveItem(r);
            }
        }
    }


    local loco = null;

    local fast = BiasFast;
    local big = BiasBig;
    local cheap = BiasCheap;
    local fscore = 0;
    local wscore = 0;
    local bscore = 0;
    local cscore = 0;
    local tscore = 0;
    local tbonus = 0;
    local hitea = null;

    local locolist = AIEngineList(AIVehicle.VT_RAIL);
    locolist.RemoveList(DudEngines);

    local ft;
    if (AIGameSettings.IsValid("vehicle.freight_trains")) {
        ft = AIGameSettings.GetValue("vehicle.freight_trains");
    } else {
        ft = 1;
    }

    local minpow = 400; // ignoring freight_trains multiplier for pax
    local tarpow = ((250 * tlen) + (climb * 20)); // ignoring freight_trains multiplier for pax, but wanting more hill-climbing power
    if (oldHP > tarpow) tarpow = oldHP; // bias towards building an equally powerful locomotive than the one we're replacing, since replacements don't know about hillclimbing

    foreach(l, z in locolist) { // remove vehicles which don't meet basic standards
        if (
            (AIEngine.GetCapacity(l) > 0 && AIEngine.GetCargoType(l) != pax && AIEngine.GetCargoType(l) != mail) ||
            AIEngine.GetPower(l) < minpow ||
            AIEngine.GetMaxSpeed(l) < 64 ||
            !rtypes.HasItem(AIEngine.GetRailType(l)) // these are our minimum standards 
        ) {
            locolist.RemoveItem(l)
        }
    }

    locolist.Valuate(AIEngine.GetPower);
    locolist.Sort(AIList.SORT_BY_VALUE, true);


    foreach(l, z in locolist) { // remove vehicles which don't meet hillclimbing requirement (as long as we keep 1)
        if (
            (locolist.Count() > 1) &&
            ((AIEngine.GetPower(l) + AIEngine.GetMaxTractiveEffort(l)) < tarpow)
        ) {
            locolist.RemoveItem(l)
        }
    }

    // v25 - find the speed limit of an exemplar wagon --------------
    local woganlist = AIEngineList(AIVehicle.VT_RAIL);
    foreach(w, z in woganlist) {
        //AILog.Info("Assessing " + AIEngine.GetName(w));

        if (
            AIEngine.GetCapacity(w) == 0 ||
            AIEngine.GetPower(w) > 0 ||
            ((AIEngine.GetMaxSpeed(w) < 64) && (AIEngine.GetMaxSpeed(w) != 0)) // these are our minimum standards  
            ||
            !wrtypes.HasItem(AIEngine.GetRailType(w)) ||
            !AIEngine.CanRefitCargo(w, cargo)
        ) {
            woganlist.RemoveItem(w)
        } // no locos, unrefits or non-rail vehicles
    }
    if (woganlist.Count() == 0) {
        AILog.Info("I couldn't find any suitable wagons.");
        return (null);
    }

    local unit;
    local exemplar;
    local newwogan;
    local exlist = AIList();
    exlist.AddList(woganlist);

    // find the exemplar --------------------------------------------
    // prefer native vehicles
    foreach(w, z in exlist) {
        if (AIEngine.GetCargoType(w) != cargo) {
            exlist.RemoveItem(w);
        }
    }
    if (exlist.Count() == 0) {
        exlist.AddList(woganlist);
    } // no native wagons found, restore the list of refittables.

    // pick an exemplar: by capacity or speed, then by intro date

    if (BiasBig > BiasFast) {
        exlist.Valuate(AIEngine.GetCapacity);
        exlist.Sort(AIList.SORT_BY_VALUE, false);
        exemplar = exlist.Begin();
        exlist.KeepValue(exlist.GetValue(exemplar));
    } else {
        exlist.Valuate(AIEngine.GetMaxSpeed);
        exlist.Sort(AIList.SORT_BY_VALUE, false);
        exemplar = exlist.Begin();
        exlist.KeepValue(exlist.GetValue(exemplar));
    }
    exlist.Valuate(AIEngine.GetDesignDate);
    exlist.Sort(AIList.SORT_BY_VALUE, false);
    exemplar = exlist.Begin();

    //AILog.Info ("My biases are F:" + fast + " B:" + big + " C:" + cheap + ".") 

    foreach(l, z in locolist) {

        local wagonspeed = AIEngine.GetMaxSpeed(exemplar);
        if (wagonspeed > AIEngine.GetMaxSpeed(l) || wagonspeed == 0) {
            wagonspeed = AIEngine.GetMaxSpeed(l);
        }


        // new in 1.9 - we use a scoring method based on our biasing 
        fscore = AIEngine.GetMaxSpeed(l) * fast / 2;
        wscore = (wagonspeed - AIEngine.GetMaxSpeed(l)) * 20;
        bscore = AIEngine.GetCapacity(l) * big / 4; // 'big' for pax trains = DMU capacity, rather than tractive effort
        cscore = (AIEngine.GetPrice(l) + AIEngine.GetRunningCost(l)) * cheap / 1000;
        tbonus = (tarpow - AIEngine.GetPower(l)) / 6; // bonus for being close to tarpow
        tscore = 500 + (fscore) + wscore + (bscore) - (cscore) + tbonus;

        //AILog.Info ("Scored " + AIEngine.GetName(l) + " at " + tscore + " (f " + fscore + ", w " + wscore + ", b " + bscore + ", op " + tbonus + ", c " + -cscore + ").");

        if (hitea == null || tscore > hitea) {
            loco = l;
            hitea = tscore;
        }
    }
    if (loco != null) {
        AIRail.SetCurrentRailType(AIEngine.GetRailType(loco));
    }
    return (loco);

}

// ====================================================== 
//                    FIND FREIGHT LOCO TO BUY
// ======================================================  

function CivilAI::PickFreightLoco(routelength, climb, railbase, oldHP, cargo, tlen) {

    local rtypes = AIRailTypeList();
    local wrtypes = AIRailTypeList();

    if (railbase != null) {
        foreach(r, z in rtypes) {
            if (!(AIRail.TrainCanRunOnRail(railbase, r) && AIRail.TrainHasPowerOnRail(railbase, r))) {
                rtypes.RemoveItem(r);
            }
        }
        foreach(r, z in wrtypes) {
            if (!(AIRail.TrainCanRunOnRail(railbase, r))) {
                wrtypes.RemoveItem(r);
            }
        }
    }


    local loco = null;

    local fast = BiasFast;
    local big = BiasBig;
    local cheap = BiasCheap;
    local fscore = 0;
    local wscore = 0;
    local bscore = 0;
    local cscore = 0;
    local tscore = 0;
    local tbonus = 0;
    local hitea = null;

    local locolist = AIEngineList(AIVehicle.VT_RAIL);
    locolist.RemoveList(DudEngines);

    local ft;
    if (AIGameSettings.IsValid("vehicle.freight_trains")) {
        ft = AIGameSettings.GetValue("vehicle.freight_trains");
    } else {
        ft = 1;
    }

    local minpow = (
        350 +
        (ft * 50)); // taking freight_trains multiplier into account
    local tarpow = (
        (250 * tlen) +
        (climb * 10 * ft) +
        (ft * 20 * tlen)); // taking freight_trains multiplier into account
    if ((oldHP + 100) > tarpow) tarpow = (oldHP + 100); // bias towards building a more powerful locomotive than the one we're replacing, since replacements don't know about hillclimbing

    //AILog.Info("Freight multiplier is " + ft + ", hilliness of route is " + climb + ", target locomotive power is " + tarpow + "hp.")

    foreach(l, z in locolist) { // remove vehicles which don't meet basic standards
        if (
            AIEngine.GetCapacity(l) > 0 ||
            AIEngine.GetPower(l) < minpow ||
            AIEngine.GetMaxSpeed(l) < 64 ||
            !rtypes.HasItem(AIEngine.GetRailType(l)) // these are our minimum standards 
        ) {
            locolist.RemoveItem(l)
        }
    }

    locolist.Valuate(AIEngine.GetMaxTractiveEffort); // prefer high TE for freight
    locolist.Sort(AIList.SORT_BY_VALUE, true);


    foreach(l, z in locolist) { // remove vehicles which don't meet hillclimbing requirement (as long as we keep 1)
        if (
            (locolist.Count() > 1) &&
            (((AIEngine.GetPower(l)) + (AIEngine.GetMaxTractiveEffort(l))) < tarpow)
        ) {
            locolist.RemoveItem(l)
        }
    }

    // v25 - find the speed limit of an exemplar wagon --------------
    local woganlist = AIEngineList(AIVehicle.VT_RAIL);
    foreach(w, z in woganlist) {
        //AILog.Info("Assessing " + AIEngine.GetName(w));

        if (
            AIEngine.GetCapacity(w) == 0 ||
            AIEngine.GetPower(w) > 0 ||
            ((AIEngine.GetMaxSpeed(w) < 64) && (AIEngine.GetMaxSpeed(w) != 0)) // these are our minimum standards  
            ||
            !wrtypes.HasItem(AIEngine.GetRailType(w)) ||
            !AIEngine.CanRefitCargo(w, cargo)
        ) {
            woganlist.RemoveItem(w)
        } // no locos, unrefits or non-rail vehicles
    }
    if (woganlist.Count() == 0) {
        AILog.Info("I couldn't find any suitable wagons.");
        return (null);
    }

    local unit;
    local exemplar;
    local newwogan;
    local exlist = AIList();
    exlist.AddList(woganlist);

    // find the exemplar --------------------------------------------
    // prefer native vehicles
    foreach(w, z in exlist) {
        if (AIEngine.GetCargoType(w) != cargo) {
            exlist.RemoveItem(w);
        }
    }
    if (exlist.Count() == 0) {
        exlist.AddList(woganlist);
    } // no native wagons found, restore the list of refittables.

    // pick an exemplar: by capacity or speed, then by intro date

    if (BiasBig > BiasFast) {
        exlist.Valuate(AIEngine.GetCapacity);
        exlist.Sort(AIList.SORT_BY_VALUE, false);
        exemplar = exlist.Begin();
        exlist.KeepValue(exlist.GetValue(exemplar));
    } else {
        exlist.Valuate(AIEngine.GetMaxSpeed);
        exlist.Sort(AIList.SORT_BY_VALUE, false);
        exemplar = exlist.Begin();
        exlist.KeepValue(exlist.GetValue(exemplar));
    }
    exlist.Valuate(AIEngine.GetDesignDate);
    exlist.Sort(AIList.SORT_BY_VALUE, false);
    exemplar = exlist.Begin();

    //AILog.Info ("My biases are F:" + fast + " B:" + big + " C:" + cheap + ".") 

    foreach(l, z in locolist) {

        local wagonspeed = AIEngine.GetMaxSpeed(exemplar);
        if (wagonspeed > AIEngine.GetMaxSpeed(l) || wagonspeed == 0) {
            wagonspeed = AIEngine.GetMaxSpeed(l);
        }

        // new in 1.9 - we use a scoring method based on our biasing 
        fscore = AIEngine.GetMaxSpeed(l) * fast / 4;
        wscore = (wagonspeed - AIEngine.GetMaxSpeed(l)) * 20;
        bscore = AIEngine.GetMaxTractiveEffort(l) * big / 4;
        cscore = (AIEngine.GetPrice(l) + AIEngine.GetRunningCost(l)) * cheap / 1000;
        tbonus = (tarpow - AIEngine.GetPower(l)) / 4; // bonus for being close to tarpow
        tscore = 500 + (fscore) + (wscore) + (bscore) - (cscore) + tbonus;

        //AILog.Info ("Scored " + AIEngine.GetName(l) + " at " + tscore + " (f " + fscore + ", w " + wscore + ", b " + bscore + ", op " + tbonus + ", c " + -cscore + ").");

        if (hitea == null || tscore > hitea) {
            loco = l;
            hitea = tscore;
        }
    }
    if (loco != null) {
        AIRail.SetCurrentRailType(AIEngine.GetRailType(loco));
    }
    return (loco);

}


// ==========================================
// Buy a Train! Choo Choo!
// ==========================================
// this function returns the cost of a new train, or the train itself
// ------------------------------------------
function CivilAI::BuyATrain(a, b, cargo, depot, tlen, costing, oldHP) {

    if (!AIRail.IsRailDepotTile(depot) && !costing) {
        if (AIRail.IsRailDepotTile(FindTrainDepot(a))) {
            depot = FindTrainDepot(a);
        } else if (AIRail.IsRailDepotTile(FindTrainDepot(b))) {
            depot = FindTrainDepot(b);
        } else {
            return null;
        } // no depot, oops
    }
    // first, pick a loco

    local routelength;
    local climb;
    local loco;
    local train = null;
    local dosh;
    local railbase;
    local cdepot;
    local stlist = AIList();
    local pax = FindCargo("PASS");
    local mail = FindCargo("MAIL");
    if (!AIRail.IsRailDepotTile(depot)) {
        railbase = null
    } else {
        railbase = AIRail.GetRailType(depot);
    }

    local ft;
    if (AIGameSettings.IsValid("vehicle.freight_trains")) {
        ft = AIGameSettings.GetValue("vehicle.freight_trains");
    } else {
        ft = 1;
    }

    if (a == 0) { // no route, we're just costing an approximate vehicle
        routelength = TrainRange;
        climb = 20;
    } else {
        routelength = AIMap.DistanceManhattan(AIBaseStation.GetLocation(a), AIBaseStation.GetLocation(b));
        climb = HillClimb;
    }

    if (cargo == pax || cargo == mail) {
        loco = PickPaxLoco(routelength, climb, railbase, oldHP, cargo, tlen);
    } else {
        loco = PickFreightLoco(routelength, climb, railbase, oldHP, cargo, tlen);
    }

    if (loco == null) {
        return 1000000000;
    } // couldn't find a loco so return a huge value
    else {
        dosh = AIEngine.GetPrice(loco);
        railbase = AIEngine.GetRailType(loco);
    }

    if (!costing) {

        // electrify
        cdepot = FindTrainDepot(a)
        if (
            cdepot != null &&
            (AIEngine.GetRailType(loco) != AIRail.GetRailType(cdepot)) &&
            (AIRail.TrainCanRunOnRail(AIRail.GetRailType(cdepot), AIEngine.GetRailType(loco))) &&
            (AIRail.TrainHasPowerOnRail(AIRail.GetRailType(cdepot), AIEngine.GetRailType(loco)))) {
            Electrify(cdepot, AIEngine.GetRailType(loco));
        }
        stlist = AITileList_StationType(a, AIStation.STATION_TRAIN)
        cdepot = stlist.Begin();
        if (
            cdepot != null &&
            (AIEngine.GetRailType(loco) != AIRail.GetRailType(cdepot)) &&
            (AIRail.TrainCanRunOnRail(AIRail.GetRailType(cdepot), AIEngine.GetRailType(loco))) &&
            (AIRail.TrainHasPowerOnRail(AIRail.GetRailType(cdepot), AIEngine.GetRailType(loco)))) {
            Electrify(cdepot, AIEngine.GetRailType(loco));
        }
        cdepot = FindTrainDepot(b)
        if (
            cdepot != null &&
            (AIEngine.GetRailType(loco) != AIRail.GetRailType(cdepot)) &&
            (AIRail.TrainCanRunOnRail(AIRail.GetRailType(cdepot), AIEngine.GetRailType(loco))) &&
            (AIRail.TrainHasPowerOnRail(AIRail.GetRailType(cdepot), AIEngine.GetRailType(loco)))) {
            Electrify(cdepot, AIEngine.GetRailType(loco));
        }
        stlist = AITileList_StationType(b, AIStation.STATION_TRAIN)
        cdepot = stlist.Begin();
        if (
            cdepot != null &&
            (AIEngine.GetRailType(loco) != AIRail.GetRailType(cdepot)) &&
            (AIRail.TrainCanRunOnRail(AIRail.GetRailType(cdepot), AIEngine.GetRailType(loco))) &&
            (AIRail.TrainHasPowerOnRail(AIRail.GetRailType(cdepot), AIEngine.GetRailType(loco)))) {
            Electrify(cdepot, AIEngine.GetRailType(loco));
        }

        //AILog.Info("I picked " + AIEngine.GetName(loco) + " as my locomotive.");
        while (train == null || !AIVehicle.IsValidVehicle(train)) {
            train = AIVehicle.BuildVehicle(depot, loco);
            AIController.Sleep(1);
        }
        AIVehicle.RefitVehicle(train, cargo); // refit (perhaps for mail)
    }

    // pick wogans

    local woganlist = AIEngineList(AIVehicle.VT_RAIL);
    foreach(w, z in woganlist) {
        //AILog.Info("Assessing " + AIEngine.GetName(w));

        if (
            AIEngine.GetCapacity(w) == 0 ||
            AIEngine.GetPower(w) > 0 ||
            ((AIEngine.GetMaxSpeed(w) < 64) && (AIEngine.GetMaxSpeed(w) != 0)) // these are our minimum standards  
            ||
            !AIEngine.CanRunOnRail(w, railbase) ||
            !AIEngine.CanRefitCargo(w, cargo)
        ) {
            woganlist.RemoveItem(w)
        } // no locos, unrefits or non-rail vehicles
    }
    if (woganlist.Count() == 0) {
        AILog.Info("I couldn't find any suitable wagons.");
        dosh = 1000000000;
        return (dosh);
    } else {

        local unit;
        local exemplar;
        local newwogan;
        local exlist = AIList();
        exlist.AddList(woganlist);

        // find the exemplar --------------------------------------------
        // prefer native vehicles
        foreach(w, z in exlist) {
            if (AIEngine.GetCargoType(w) != cargo) {
                exlist.RemoveItem(w);
            }
        }
        if (exlist.Count() == 0) {
            exlist.AddList(woganlist);
        } // no native wagons found, restore the list of refittables.

        // pick an exemplar: by capacity or speed, then by intro date

        if (BiasBig > BiasFast) {
            exlist.Valuate(AIEngine.GetCapacity);
            exlist.Sort(AIList.SORT_BY_VALUE, false);
            exemplar = exlist.Begin();
            exlist.KeepValue(exlist.GetValue(exemplar));
        } else {
            exlist.Valuate(AIEngine.GetMaxSpeed);
            exlist.Sort(AIList.SORT_BY_VALUE, false);
            exemplar = exlist.Begin();
            exlist.KeepValue(exlist.GetValue(exemplar));
        }
        exlist.Valuate(AIEngine.GetDesignDate);
        exlist.Sort(AIList.SORT_BY_VALUE, false);
        exemplar = exlist.Begin();


        // now remove vehicles which aren't up to spec (no slower than the exemplar or the loco) -------------
        //AILog.Info("I picked " + AIEngine.GetName(exemplar) + " as my ideal wagon.");

        local newwoganlist = AIList();
        newwoganlist.AddList(woganlist); // make a duplicate woganlist for unattaching.

        foreach(w, z in woganlist) {
            if ((AIEngine.GetMaxSpeed(w) < (AIEngine.GetMaxSpeed(exemplar))) && (AIEngine.GetMaxSpeed(w) < AIEngine.GetMaxSpeed(loco))) {
                woganlist.RemoveItem(w);
                //AILog.Info("I discarded " + AIEngine.GetName(w) + " as too slow.");
            }
        }

        if (costing) {
            dosh = dosh + (AIEngine.GetPrice(exemplar) * 8);
            return (dosh);
        }

        // buy a brakevan or mailvan? =========================

        local vanid = null;

        if ((AIDate.GetYear(AIDate.GetCurrentDate()) < BrakeYear) && !costing && cargo != pax && cargo != mail) {
            //AILog.Info("It's the year of the Brakevan!");

            local bvlist = AIEngineList(AIVehicle.VT_RAIL);
            foreach(w, z in bvlist) {
                //AILog.Info("Assessing " + AIEngine.GetName(w));

                if (
                    AIEngine.GetCapacity(w) > 0 ||
                    AIEngine.GetPower(w) > 0 ||
                    ((AIEngine.GetMaxSpeed(w) < AIEngine.GetMaxSpeed(loco)) && (AIEngine.GetMaxSpeed(w) < AIEngine.GetMaxSpeed(exemplar)) && (AIEngine.GetMaxSpeed(w) != 0)) // brakevan must be at least as fast as the exemplar or the loco
                    ||
                    !AIEngine.CanRunOnRail(w, railbase)
                ) {
                    bvlist.RemoveItem(w)
                } // no locos, unrefits or non-rail vehicles
            }
            if (bvlist.Count() > 0) {

                bvlist.Valuate(AIEngine.GetWeight); // choose the lightest, on the grounds that it's probably also the shortest.
                bvlist.Sort(AIList.SORT_BY_VALUE, true);
                vanid = bvlist.Begin();

                //AILog.Info("Brake Van " + AIEngine.GetName(vanid));
                newwogan = AIVehicle.BuildVehicle(depot, vanid);
                if (AIVehicle.IsValidVehicle(newwogan)) {
                    AIVehicle.MoveWagon(newwogan, 0, train, AIVehicle.GetNumWagons(train) - 1);
                }
                if (AIVehicle.IsValidVehicle(newwogan)) { // failed to attach the brakevan, so sell it
                    AIVehicle.SellVehicle(newwogan);
                }
            }
        } else if (cargo == pax) {
            // add a mailvan - largest, then latest =====================
            // pick wogans

            local mwlist = AIEngineList(AIVehicle.VT_RAIL);
            foreach(w, z in mwlist) {
                //AILog.Info("Assessing " + AIEngine.GetName(w));

                if (
                    AIEngine.GetCapacity(w) == 0 ||
                    AIEngine.GetPower(w) > 0 ||
                    ((AIEngine.GetMaxSpeed(w) < AIEngine.GetMaxSpeed(loco)) && (AIEngine.GetMaxSpeed(w) < AIEngine.GetMaxSpeed(exemplar)) && (AIEngine.GetMaxSpeed(w) != 0)) // brakevan must be at least as fast as the exemplar or the loco
                    ||
                    !AIEngine.CanRunOnRail(w, railbase) ||
                    !AIEngine.CanRefitCargo(w, mail)
                ) {
                    mwlist.RemoveItem(w)
                } // no locos, unrefits or non-rail vehicles
            }
            if (mwlist.Count() > 0) {

                local munitlist = AIList();
                munitlist.AddList(mwlist);

                // prefer native vehicles
                foreach(w, z in munitlist) {
                    if (AIEngine.GetCargoType(w) != mail) {
                        munitlist.RemoveItem(w);
                    }
                }
                if (munitlist.Count() > 0) {
                    munitlist.Valuate(AIEngine.GetCapacity);
                    munitlist.Sort(AIList.SORT_BY_VALUE, false);
                    vanid = munitlist.Begin();
                    munitlist.KeepValue(AIEngine.GetCapacity(vanid));
                    munitlist.Valuate(AIEngine.GetDesignDate);
                    munitlist.Sort(AIList.SORT_BY_VALUE, false);
                    vanid = munitlist.Begin();
                } else {
                    mwlist.Valuate(AIEngine.GetCapacity);
                    mwlist.Sort(AIList.SORT_BY_VALUE, false);
                    vanid = mwlist.Begin();
                    mwlist.KeepValue(AIEngine.GetCapacity(vanid));
                    mwlist.Valuate(AIEngine.GetDesignDate);
                    mwlist.Sort(AIList.SORT_BY_VALUE, false);
                    vanid = mwlist.Begin();
                }

                // AILog.Info("Mail Van " + AIEngine.GetName(vanid));
                newwogan = AIVehicle.BuildVehicle(depot, vanid);
                if (AIVehicle.IsValidVehicle(newwogan)) {
                    AIVehicle.RefitVehicle(newwogan, mail);
                    AIVehicle.MoveWagon(newwogan, 0, train, AIVehicle.GetNumWagons(train) - 1);
                }
                if (AIVehicle.IsValidVehicle(newwogan)) { // failed to attach the mailvan, so sell it
                    AIVehicle.SellVehicle(newwogan);
                }
            }
        }

        local maxcargo;
        if (cargo == pax || cargo == mail) {
            maxcargo = (AIEngine.GetPower(loco) / 6);
        } else {
            maxcargo = (AIEngine.GetPower(loco) / (ft * 2));
        }

        //AILog.Info("Maximum cargo is " + (maxcargo + 30) + ".")  

        // --------------------------------------------
        // build wagons

        local wogan;
        local newwoganlisted = false;
        while (
            (AIVehicle.GetLength(train) < (16 * tlen) + 1) &&
            (AIVehicle.GetCapacity(train, cargo) < maxcargo + 30)
        ) {
            wogan = exemplar;

            if (AICargo.HasCargoClass(cargo, AICargo.CC_PIECE_GOODS) // add random wagons for piece goods
                &&
                AIBase.RandRange(4) == 0 &&
                !newwoganlisted) {
                woganlist.Valuate(AIBase.RandItem);
                wogan = woganlist.Begin();
            }

            if (AIEngine.GetPrice(wogan) > AICompany.GetBankBalance(Me)) {
                AIController.Sleep(30);
            }

            newwogan = AIVehicle.BuildVehicle(depot, wogan);
            if (AIVehicle.IsValidVehicle(newwogan)) {
                AIVehicle.RefitVehicle(newwogan, cargo);
                AIVehicle.MoveWagon(newwogan, 0, train, AIVehicle.GetNumWagons(train) - 1);

                //v31 - handle unattachable wagons
                if (AIVehicle.IsValidVehicle(newwogan)) { // newwogan still exists, it didn't get moved
                    //AILog.Info("I couldn't attach " + AIEngine.GetName(wogan) + " to " + AIEngine.GetName(loco) + ".")
                    // our exemplar is shot so we need a new wagonlist
                    if (!newwoganlisted) {
                        woganlist.AddList(newwoganlist);
                        if (BiasBig > BiasFast) {
                            woganlist.Valuate(AIEngine.GetCapacity);
                            woganlist.Sort(AIList.SORT_BY_VALUE, false);
                        } else {
                            woganlist.Valuate(AIEngine.GetMaxSpeed);
                            woganlist.Sort(AIList.SORT_BY_VALUE, false);
                        }
                        newwoganlisted = true;
                    }

                    if (woganlist.Count() > 1) {
                        woganlist.RemoveItem(wogan);
                        exemplar = woganlist.Begin();
                        AIVehicle.SellVehicle(newwogan);
                    } else {
                        //AILog.Info("No more wagons found! I'll try a different locomotive.");	
                        DudEngines.AddItem(loco, 0);
                        AIVehicle.SellVehicle(newwogan);
                        AIVehicle.SellVehicle(train);
                        return BuyATrain(a, b, cargo, depot, tlen, costing, oldHP); // try again with a different loco
                    }
                }
            }
        }
        AIVehicle.SellWagon(train, AIVehicle.GetNumWagons(train) - 1) // build overlength and sell the last wagon

        // ----------------------------------------------

        if (vanid != null) {
            local bvmove = false;
            local bvc = 1;
            while (!bvmove && (bvc < 5)) {
                bvmove = AIVehicle.MoveWagon(train, bvc, train, AIVehicle.GetNumWagons(train) - 1); // move the brakevan to the back
                bvc++;
            }
        }

        if (!AIVehicle.IsValidVehicle(train)) {
            return null;
        } // oops, we sold the loco

        // give the orders and start the train!

        if (cargo == pax || cargo == mail) {
            AIOrder.AppendOrder(train, AIBaseStation.GetLocation(b), (AIOrder.OF_NON_STOP_INTERMEDIATE));
            AIOrder.AppendOrder(train, AIBaseStation.GetLocation(a), (AIOrder.OF_NON_STOP_INTERMEDIATE));

            local trainnames = [
                "Rover", "Flyer", "Bullet", "Voyager", "Rocket", "Comet",
                "Spirit", "Dasher", "Tripper", "Strider", "Express", "Hopper"
            ]

            local nx = 0
            local name = null
            local changename = false
            local stats = [a, b];
            local trainname = (AITown.GetName(AIStation.GetNearestTown(stats[AIBase.RandRange(2)])) + " " + trainnames[AIBase.RandRange(12)]);


            while (!changename && AIVehicle.IsValidVehicle(train)) {
                nx++
                if (nx < 2) {
                    name = (trainname)
                } else {
                    name = (trainname + " " + nx)
                }
                changename = AIVehicle.SetName(train, name)
            }

            AIGroup.MoveVehicle(Groups[6], train);

        } else {

            AIOrder.AppendOrder(train, AIBaseStation.GetLocation(b), (AIOrder.OF_NON_STOP_INTERMEDIATE + AIOrder.OF_FULL_LOAD_ANY));
            AIOrder.AppendOrder(train, AIBaseStation.GetLocation(a), (AIOrder.OF_NON_STOP_INTERMEDIATE + AIOrder.OF_NO_LOAD));

            local darkblue = 0;
            local palegreen = 1;
            local pink = 2;
            local yellow = 3;
            local red = 4;
            local lightblue = 5;
            local green = 6;
            local darkgreen = 7;
            local blue = 8;
            local cream = 9;
            local mauve = 10;
            local purple = 11;
            local orange = 12;
            local brown = 13;
            local grey = 14;
            local white = 15;

            local cc = AICompany.GetPrimaryLiveryColour(0);

            local cname = ["Bluebell", "Lightning", "Thomas", "Midnight"]
            if (cc == pink || cc == cream) {
                cname = ["Pinky", "Perky", "Salmon", "Eagle"]
            }
            if (cc == yellow) {
                cname = ["Banana", "Mellow Yellow", "Flying Banana", "Custard"]
            }
            if (cc == red) {
                cname = ["Scarlet", "Little Red", "Crimson Lake", "Viking"]
            }
            if (cc == green || cc == darkgreen || cc == palegreen) {
                cname = ["Minty", "Percy", "Apple", "Flying Cucumber"]
            }
            if (cc == purple || cc == mauve) {
                cname = ["Pinky", "Pruplethingz", "Cyclops", "Royal Purple"]
            }
            if (cc == orange) {
                cname = ["Juicy", "Wildcard", "Naranja", "Big O"]
            }
            if (cc == brown) {
                cname = ["Scuddles", "Bomber", "Richard", "Bull"]
            }
            if (cc == grey || cc == white) {
                cname = ["Ghost", "Spectre", "Ghost", "Knight"]
            }

            local trainnames = [
                "Monty", "Horace", "Apollo", "Mercury", "Vulcan",
                "Cupid", "Sooty", "George", "Comet", "Ajax",
                "Samson", "Giant", "Felix", "Puffer", "Romeo",
                AICompany.GetPresidentName(Me), "Hercules", "Amazon", "Atlas", "Rocket",
                cname[0], cname[1], cname[2], cname[3]
            ]

            local nx = 0
            local name = null
            local changename = false
            local trainname = trainnames[AIBase.RandRange(24)]

            while (!changename && AIVehicle.IsValidVehicle(train)) {
                nx++
                if (nx < 2) {
                    name = (trainname)
                } else {
                    name = (trainname + " " + nx)
                }
                changename = AIVehicle.SetName(train, name)
            }
            AIGroup.MoveVehicle(Groups[7], train);
        }


        AILog.Info("I bought a " + AIEngine.GetName(loco) + " named " + AIVehicle.GetName(train) + ".");

        AIVehicle.StartStopVehicle(train); // choo choo!
        return train;
    }
}


// ====================================================== 
//                    FIND HAIRYPLANE TO BUY
// ======================================================  


function CivilAI::PickAircraft(range, cargo) {

    local acid = null;

    local fast = BiasFast;
    local big = BiasBig;
    local cheap = BiasCheap;
    local fscore = 0;
    local bscore = 0;
    local cscore = 0;
    local tscore = 0;

    local aclist = AIEngineList(AIVehicle.VT_AIR);

    foreach(ac, z in aclist) {

        //AILog.Info(AIEngine.GetName(ac) + " " + AIEngine.GetCapacity(ac));

        if ((AIEngine.GetPlaneType(ac) != AIAirport.PT_SMALL_PLANE) && (AIEngine.GetPlaneType(ac) != AIAirport.PT_HELICOPTER)) {
            // AILog.Info("Discarding " + AIEngine.GetName(ac) + " because it is not a small aircraft."); 
            aclist.RemoveItem(ac)
        }

        if ((AIEngine.GetMaximumOrderDistance(ac) != 0) && (AIEngine.GetMaximumOrderDistance(ac) < range)) {
            // AILog.Info("Discarding " + AIEngine.GetName(ac) + " because it has insufficient range."); 
            aclist.RemoveItem(ac)
        }
    }

    local rclist = AIList();
    rclist.AddList(aclist); // dupe the list

    // check natives
    foreach(ac, z in aclist) {
        if (AIEngine.GetCargoType(ac) != cargo || AIEngine.GetCapacity(ac) < 10) {
            aclist.RemoveItem(ac)
        }
    }

    // check refits
    if (aclist.Count() == 0) {
        aclist.AddList(rclist);

        foreach(ac, z in aclist) {
            if (!AIEngine.CanRefitCargo(ac, cargo) || AIEngine.GetCapacity(ac) < 10) {
                aclist.RemoveItem(ac)
            }
        }
    }

    local aslist = AIList();

    foreach(ac, z in aclist) {
        // new in 1.9 - we use a scoring method based on our biasing 
        fscore = AIEngine.GetMaxSpeed(ac) * fast / 10;
        bscore = AIEngine.GetCapacity(ac) * big / 5;
        cscore = (AIEngine.GetPrice(ac) + AIEngine.GetRunningCost(ac)) * cheap / 20000;
        tscore = 500 + (fscore) + (bscore) - (cscore);

        //	AILog.Info ("Scored " + AIEngine.GetName(ac) + " at " + tscore + " (f " + fscore + ", b " + bscore + ", c " + cscore + ").");
        aslist.AddItem(ac, tscore);
    }

    aslist.Sort(AIList.SORT_BY_VALUE, false);

    acid = aslist.Begin();
    local hitea = aslist.GetValue(acid);
    local dosh = AICompany.GetBankBalance(Me);

    aslist.KeepAboveValue(hitea * 2 / 3);

    while (aslist.Count() > 0 && AIEngine.GetPrice(acid) > dosh) {
        //	AILog.Info (AIEngine.GetName(acid) + " is too expensive...")
        aslist.RemoveItem(acid);
        acid = aslist.Begin();
    }

    if (aslist.Count() == 0) {
        acid = null;
    }
    return (acid);

}

// ====================================================== 
//                    FIND SHIP TO BUY
// ======================================================  


function CivilAI::PickShip(dist) {

    local boatid = null;

    local fast = BiasFast;
    local big = BiasBig;
    local cheap = BiasCheap;
    local fscore = 0;
    local bscore = 0;
    local cscore = 0;
    local tscore = 0;
    local hitea = null;
    local pax = FindCargo("PASS");

    local shiplist = AIEngineList(AIVehicle.VT_WATER);

    shiplist.Valuate(AIEngine.GetCapacity);
    shiplist.Sort(AIList.SORT_BY_VALUE, true);

    foreach(boat, z in shiplist) {
        if (AIEngine.GetCargoType(boat) != pax) {
            // AILog.Info("Discarding " + AIEngine.GetName(boat) + " because it doesn't carry Passengers."); 
            shiplist.RemoveItem(boat)
        }

        if (
            (shiplist.Count() > 1) &&
            (AIEngine.GetCapacity(boat) < 50)) {
            //AILog.Info("Discarding " + AIEngine.GetName(boat) + " because it is too small."); 
            shiplist.RemoveItem(boat)
        }
    }

    foreach(boat, z in shiplist) {
        // new in 1.9 - we use a scoring method based on our biasing 
        fscore = AIEngine.GetMaxSpeed(boat) * fast / 5;
        bscore = AIEngine.GetCapacity(boat) * big / 5;
        cscore = (AIEngine.GetPrice(boat) + AIEngine.GetRunningCost(boat)) * cheap / 5000;
        tscore = 500 + (fscore) + (bscore) - (cscore);

        //AILog.Info ("Scored " + AIEngine.GetName(boat) + " at " + tscore + " (f " + fscore + ", b " + bscore + ", c " + cscore + ").");

        if ((boatid != null) && ((fscore + bscore) > (dist * 10))) {
            //AILog.Info (AIEngine.GetName(boat) + "is too big for the route length (" + dist + ").")
        } else {
            if (hitea == null || tscore > hitea) {
                boatid = boat;
                hitea = tscore;
            }
        }
    }
    //if (boatid != null) { AILog.Info ("Selected " + AIEngine.GetName(boatid) + ".")}
    return (boatid);

}