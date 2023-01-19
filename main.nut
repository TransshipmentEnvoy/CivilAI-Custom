//
//CIVIL AI v36
//
//
//AI for OpenTTD
//2014-2022 David Dallaston (PikkaBird)
//
//Turn back, before it's too late.
//


import("Pathfinder.CRoad", "RoadPF", 4);
import("Pathfinder.Rail", "RailPF", 1);

class CivilAI extends AIController {
    // vv!

    // === global vars
    Groups = [null, null, null, null, null, null, null, null];
    LCounter = 0;
    HomeDepot = null;
    IsLoaded = false;
    Dudtowns = AIList();
    NetworkRadius = null;
    MinPop = null;
    MaxBus = null;
    MaxCar = null;
    BuyCar = null;
    MinAirRange = null;
    BuyPlane = null;
    TrainRange = null;
    BrakeYear = null;
    ShipRange = null;
    LeftHand = true;
    HaveRoadType = false;
    BannedRoadTypes = AIList();

    Exclaves = AIList();
    MaxExclaves = 5;

    Cachedtowns = AIList();
    Recache = true;

    BackTrackCounter = 0;
    PassingPlace = null;
    HillClimb = 0;
    CycleCount = 0;

    fname = null;
    lname = null;

    AltMethod = false;

    // === cargo plan elements

    PlanDestination = null;
    PlanSource = null;

    DudIndustries = AIList();
    DudTerminus = AIList();
    DudPTerminus = AIList();
    IndTownList = AIList();
    DudBusNetwork = AIList();
    DudRailCon = AIList();
    DudEngines = AIList();
    DudCounter = 0;
    ConnectedPInds = AIList();
    DontGoodsTruck = AIList();


    // === Character Biases

    BiasCheap = 10;
    BiasFast = 10;
    BiasBig = 10;

    Me = (AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
}


require("setup.nut");
require("saveload.nut");
require("bits.nut");
require("buyvehicle.nut")

require("road.nut");
require("bus.nut");
require("bus2.nut");
require("rv.nut");
require("towncars.nut");

require("train.nut");
require("train2.nut");
require("rail.nut");
require("rail2.nut");
require("railreview.nut");
require("twintrack.nut");

require("air.nut");
require("ship.nut");





// ====================================================== 
//                         START
// ====================================================== 

function CivilAI::Start() {

    // Startup parameters:
    AICompany.SetAutoRenewStatus(false); // we don't do autorenew
    AIRail.SetCurrentRailType(0); // let's assume this is standard rail

    if (AIGameSettings.GetValue("vehicle.road_side") == 1) {
        LeftHand = false;
    }


    LoadParas();
    CashUp();

    if (!IsLoaded) {
        MakeGroups();
        LocateHomeTown();
    } else {
        LoadGroups();
    }

    MainLoop();

}

// ====================================================== 
//                      MAIN LOOP
// ====================================================== 

function CivilAI::MainLoop() {

    if (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_ROAD)) { // use alt mode if no road vehicle construction allowed
        AILog.Info("Road vehicle construction is not allowed - using alternative network method.");
        AltMethod = true;
    }

    if (IsLoaded) {
        AILog.Info("Welcome back!");
    } else {
        AILog.Info("Now that I have introduced myself, I should like to have some idea of what is going on...");
    }

    local dosh;
    LCounter = AIDate.GetCurrentDate();

    while (true) {

        LoadParas();

        dosh = AICompany.GetBankBalance(Me);
        if (dosh > (AICompany.GetMaxLoanAmount() * 2)) {
            CashDown(); // pay off our loan when we're rich, just for the points.
        } else {
            CashUp(); // Retake loan, just in case inflation is on
        }
        CacheTownList(); // Recache town list
        DepotClean(); // Clear Depots
        RailReview(); // Clear old tracks, build new trains

        HaveRoadType = SelectRoadType(false);

        if (!AltMethod && HaveRoadType) {
            TruckOps(); // Add some trucks
            BusReview(); // Bus Review
            BigCityDepots(); // build extra depots in large towns
            InterCity(); // Intercity
            CargoPlan(); // Find a goods/food source
            NewNetwork(); // New Bus Network
            Vroom(); // Town Cars
            XingReplace(); // Check for crashes	
        }
        ChooChoo2(); // Build passenger trains
        ChooChoo(); // Build freight trains	
        Shipping(); // Build ships
        AirReview(); // Review Aircraft
        Airportz(); // Build Airports
        ManualService(); // Send low-reliability vehicles for servicing
        Statues(); // Build statues in towns
        TreeTime(); // Plant trees around towns which don't like us
        MappaMundi(); // Roads - this is also when we tend to build up cash, so put the most important things at the top

        CashDown(); // remain little cash

        LoopCounter();
    }
}