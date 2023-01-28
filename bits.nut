//<
// ====================================================== 
// ====================================================== 
//         TTTTTT    OOOO    W     W   N   N
//           TT     O    O   WW   WW   NN  N
//           TT    OO    OO   W W W    N N N
//           TT     O    O    WWWWW    N  NN
//           TT      OOOO      W W     N   N
// ====================================================== 
// ====================================================== 
//>

function CivilAI::CacheTownList() {

    if ((!Recache) && (CycleCount < 5)) {
        AILog.Info("I'm using my cached list of connected towns.");
        CycleCount++;
        return;
    }

    AILog.Info("Updating my list of connected towns, please wait...");
    local cache = MyTownList(); // update the townlist only as needed
    Recache = false;
    foreach(town, z in cache) {
        Cachedtowns.AddItem(town, 0);
    }

    foreach(town, z in Exclaves) {
        if (cache.HasItem(town)) {
            Exclaves.RemoveItem(town);
            AILog.Info(AITown.GetName(town) + " is no longer an Exclave.")
        } else {
            AILog.Info(AITown.GetName(town) + " is an Exclave.")
        }
    }

    CycleCount = 0;
    AILog.Info("Update complete!");
    return;
}




// ====================================================== 
//                  LIST CONNECTED TOWNS
// ====================================================== 

function CivilAI::MyTownList() {

    local hq = AICompany.GetCompanyHQ(Me);
    local townlist = AITownList();
    // sort by distance from the hq
    townlist.Valuate(AITown.GetDistanceManhattanToTile, hq);
    townlist.KeepBelowValue(NetworkRadius); // remove towns which are too far away
    //townlist.RemoveList(Dudtowns); // remove known unconnectables

    townlist.Sort(AIList.SORT_BY_VALUE, true);

    // add the home town's home tile to the target list
    local hometown = townlist.Begin();
    local mapnodes = [AITown.GetLocation(hometown)]
    local nodecount = 1
    local target = -1

    // cash down
    CashDown();

    foreach(town, z in townlist) {

        local testroad = RoadPF();
        local towntile = AITown.GetLocation(town);
        testroad.cost.no_existing_road = testroad.cost.max_cost; // only check existing roads
        testroad.InitializePath([towntile], mapnodes);

        local path = false;
        while (path == false) {
            path = testroad.FindPath(50);
            AIController.Sleep(1);
        }

        if (path != null) { // we are connected already
            mapnodes.append(towntile); // add this town to the nodes we can connect to
            nodecount++
            AILog.Info(AITown.GetName(town) + " is connected.")
            if (Dudtowns.HasItem(town)) {
                Dudtowns.RemoveItem(town);
            } // remove from dudlist, in case someone has connected it for us.
        } else {
            townlist.RemoveItem(town); // discard disconnected towns
        }
    }

    // cash up
    CashUp();

    // our townlist now contains only connected towns within the network radius.

    return townlist;
}




// ====================================================== 
//                     COMPANY FAIL
// ====================================================== 

function CivilAI::Failure() {
    AILog.Info("Woe is me!")
    AICompany.SetName("Failed CivilAI");
    CashDown();
    while (1) {
        AIController.Sleep(1000000);
    }
}

//=======================================================
// Cargo label identification
//=======================================================


function CivilAI::FindCargo(label) {

    local clist = AICargoList();

    foreach(cargo, z in clist) {
        if (AICargo.GetCargoLabel(cargo) == label) {
            return cargo;
        }
    }
    return null;
}

function CivilAI::LoopCounter() {

    AILog.Info("Looping " + AIDate.GetMonth(AIDate.GetCurrentDate()) + " / " + AIDate.GetYear(AIDate.GetCurrentDate()));
    AILog.Info("Last loop took " + (AIDate.GetCurrentDate() - LCounter) + " days.");

    while ((AIDate.GetCurrentDate() - LCounter) < 30) {
        AIController.Sleep(1);
    } // don't loop more than once a month

    LCounter = AIDate.GetCurrentDate();
    return;
}

//=======================================================
// Don't clear water or mountains
//=======================================================


function CivilAI::NoWater(t, xs, ys) {
    local tg = [AIMap.GetTileX(t), AIMap.GetTileY(t)]

    // test we're not trying to build on water

    for (local x = 0; x < xs; x++) {
        for (local y = 0; y < ys; y++) {

            local tt = AIMap.GetTileIndex(tg[0] + (x), tg[1] + (y));
            if (AITile.IsWaterTile(tt) || AITile.IsCoastTile(tt)) {
                return false;
            }
        }
    }

    // test we're not trying to flatten a heavy slope	

    local min = 15;
    local max = 0;

    for (local x = -1; x <= xs; x++) {
        for (local y = -1; y <= ys; y++) {

            local tt = AIMap.GetTileIndex(tg[0] + (x), tg[1] + (y));
            if (x == -1 || x == xs || y == -1 || y == ys) { // only interested in the edge tiles
                local tt = AIMap.GetTileIndex(tg[0] + (x), tg[1] + (y));
                if (AITile.GetMinHeight(tt) < min) {
                    min = AITile.GetMinHeight(tt);
                }
                if (AITile.GetMaxHeight(tt) > max) {
                    max = AITile.GetMaxHeight(tt);
                }

            }
        }
    }

    //AISign.BuildSign(t,"=" + (max - min) + "=")	

    if (max - min > 2) {
        return false
    } else {
        return true;
    }
}

// ====================================================== 
//                    LOAN MANAGEMENT
// ====================================================== 

function CivilAI::CashUp() {
    local dosh = AICompany.GetBankBalance(Me);
    if (dosh <= (AICompany.GetMaxLoanAmount() * 2)) {
        AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
        //AILog.Info("I've borrowed some money from the bank.")
    }
    return
}

function CivilAI::CashDown() {


    /* local b = 0; // just in case
    while ((AICompany.GetBankBalance(Me) > AICompany.GetLoanInterval()) && b < 100) {
    AICompany.SetLoanAmount(AICompany.GetLoanAmount()-AICompany.GetLoanInterval())
    b++
    } */

    local balance = AICompany.GetBankBalance(Me);
    local loan = AICompany.GetLoanAmount();
    local interval = AICompany.GetLoanInterval();
    if (balance >= loan) {
        AICompany.SetLoanAmount(0);
    } else {
        // clear balance
        local curr_credit = loan - balance;
        curr_credit = ((curr_credit - 1) / interval + 1) * interval;
        AICompany.SetLoanAmount(curr_credit);
    }

    //AILog.Info("I've paid off as much of my loan as I can.")
    return
}


function CivilAI::GroupCount(group) {
    local glist = AIVehicleList_Group(Groups[group]);
    local gcount = glist.Count();
    return (gcount);
}


// ====================================================== 
//               CLEAN VEHICLES FROM DEPOT
// ====================================================== 

function CivilAI::DepotClean() {

    AILog.Info("I'm clearing out old vehicles from my depots.");

    local rvlist = AIVehicleList();
    local c = 0;

    for (local v = rvlist.Begin(); !(rvlist.IsEnd()); v = rvlist.Next()) {
        if (AIVehicle.IsStoppedInDepot(v)) {
            AIVehicle.SellVehicle(v);
            c++
        }
    }
    if (c == 0) {
        AILog.Info("I found nothing to sell.")
    } else if (c == 1) {
        AILog.Info("I've disposed of " + c + " vehicle.")
    } else {
        AILog.Info("I've disposed of " + c + " vehicles.")
    }

    return
}


// treeeeeeeeeeees
function CivilAI::TreeTime() {
    local townlist = AIList();
    townlist.AddList(Cachedtowns);
    townlist.Valuate(AITown.GetRating, Me);
    townlist.Sort(AIList.SORT_BY_VALUE, true);
    local town = townlist.Begin();

    //AILog.Info("My poorest-rated town is " + AITown.GetName(town) +".")

    if (AITown.GetRating(town, Me) < 4) {
        TreePlant(town);
    }
}

function CivilAI::TreePlant(town) {

    AILog.Info("Planting trees around " + AITown.GetName(town) + ".")

    local treetile;
    local tg = [AIMap.GetTileX(AITown.GetLocation(town)), AIMap.GetTileY(AITown.GetLocation(town))]

    for (local c = 0; c < 200; c++) {
        treetile = AIMap.GetTileIndex(tg[0] - 10 + (AIBase.RandRange(20)), tg[1] - 10 + (AIBase.RandRange(20)));

        if (AITile.IsBuildable(treetile) && !AITile.IsFarmTile(treetile) && !AITile.HasTreeOnTile(treetile)) {
            AITile.PlantTree(treetile);
            //AISign.BuildSign(treetile, ".");
            c++;
        }
    }
}

function CivilAI::ManualService() {

    // sometimes vehicles can have trouble finding a depot to service. We find such vehicles and manually send them to the depot.

    local rvlist = AIVehicleList();
    foreach(veh, z in rvlist) {
        if (AIVehicle.GetVehicleType(veh) != AIVehicle.VT_ROAD) {
            rvlist.RemoveItem(veh);
        }
    }

    rvlist.Valuate(AIVehicle.GetReliability);
    rvlist.KeepBelowValue(25);

    foreach(rv, z in rvlist) {
        if (!AIOrder.IsGotoDepotOrder(rv, AIOrder.ORDER_CURRENT)) {
            AIVehicle.SendVehicleToDepotForServicing(rv);
            AILog.Info("Sending " + AIVehicle.GetName(rv) + " to the depot for servicing.");
        }
    }
    AILog.Info("Finished reliability checks.")
    return;
}


function CivilAI::Statues() {

    local dosh = AICompany.GetBankBalance(Me);

    if (dosh < 1000000) {
        AILog.Info("No money for statues right now.");
        return;
    }

    local townlist = AIList();
    townlist.AddList(Cachedtowns);

    foreach(town, z in townlist) {
        if (
            AITown.HasStatue(town) ||
            AITown.GetPopulation(town) < (MinPopStatue)
        ) {
            townlist.RemoveItem(town);
        }
    }

    if (townlist.Count() == 0) {
        AILog.Info("I've built enough statues to myself for now.");
        return;
    }

    townlist.Valuate(AIBase.RandItem); // shuffle the list
    local stattown = townlist.Begin();
    if (AITown.PerformTownAction(stattown, AITown.TOWN_ACTION_BUILD_STATUE)) {
        AILog.Info("Built a statue in " + AITown.GetName(stattown) + ".");
        return;
    } else {
        AILog.Info("Failed to build a statue in " + AITown.GetName(stattown) + ", for some reason.");
        return;
    }
}

// ====================================================== 
//               SCORE ROUTE
// ====================================================== 

function CivilAI::ScoreRoute(a, b) {

    //AISign.BuildSign(a, "a");
    //AISign.BuildSign(b, "b");

    local score = 0;
    local dist = 0;
    local elev = 0;
    local wet = 0;

    local ax = AIMap.GetTileX(a);
    local ay = AIMap.GetTileY(a);
    local bx = AIMap.GetTileX(b);
    local by = AIMap.GetTileY(b);

    local ix;
    local iy;
    local itile;

    dist = AITile.GetDistanceManhattanToTile(a, b);

    for (local i = 0; i < 25; i++) {
        ix = (bx - ax) / 6; // init measurement
        iy = (by - ay) / 6; // init measurement

        ix = (ax + (ix * ((i % 5) + 1)));
        iy = (ay + (iy * ((i / 5) + 1)));

        itile = AIMap.GetTileIndex(ix, iy);


        // elev score
        local lelev = 0;

        local hda = (AITile.GetMinHeight(itile) - AITile.GetMinHeight(a));
        if (hda < 0) hda = -hda;
        lelev = lelev + (hda);
        local hdb = (AITile.GetMinHeight(itile) - AITile.GetMinHeight(b));
        if (hdb < 0) hdb = -hdb;
        lelev = lelev + (hdb);
        if (AITile.GetSlope(itile) != AITile.SLOPE_FLAT) {
            lelev = lelev + 3;
        }

        // wet score
        //local lwet = 0;
        //if (AITile.IsWaterTile(itile)) lwet = 100;

        //AISign.BuildSign(itile, "e " + lelev + " w " + lwet);

        elev = elev + lelev;
        //wet = wet + lwet;
    }

    score = dist + elev + wet;

    // AILog.Info("Scored route " + score + " (distance " + dist + " elevation " + elev + " wet " + wet + ")"); 

    return (score);
}