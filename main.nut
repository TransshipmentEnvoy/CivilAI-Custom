//
//CIVIL AI v36
//
//
//AI for OpenTTD
//2014-2022 David Dallaston (PikkaBird)
//
//Turn back, before it's too late.
//


require("pathfinder/road.nut");
require("pathfinder/rail.nut");
require("dep/AIToyLib/main.nut");
import("Library.SCPLib", "SCPLib", 45);

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
    MinPopHome = null;
    MinPopStatue = null;

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
    IgnoredRoadTable = {};
    IgnoredRailKeywordTable = [];

    MaxLoanKeep = null;
    MaxLoss = null;

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

    // comm
    toy_lib = null;
    TownSubsidery = null;
    received_exemption = false;
    // date schedule
    current_date = 0;
    current_month = 0;
    current_year = 0;
    current_decade_year = 0;
}

require("support.nut"); // library functions

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
    this.IgnoredRoadTable["ISR Style paved driveway"] <- 0;
    this.IgnoredRoadTable["CHIPS Style asphalt driveway"] <- 0;
    this.IgnoredRoadTable["CHIPS Style cobble driveway"] <- 0;
    this.IgnoredRoadTable["CHIPS Style mud driveway"] <- 0;
    this.IgnoredRoadTable["Paving slabs"] <- 0;
    this.IgnoredRoadTable["Urban asphalt road"] <- 0;
    this.IgnoredRoadTable["Urban asphalt road w/ stripes"] <- 0;
    this.IgnoredRoadTable["Road Verge"] <- 0;
    this.IgnoredRoadTable["Cobble stones road"] <- 0;
    this.IgnoredRoadTable["ISR road"] <- 0;
    this.IgnoredRoadTable["Cement slab of road"] <- 0;
    this.IgnoredRoadTable["Asphalt concrete road"] <- 0;
    this.IgnoredRoadTable["Concrete road"] <- 0;

    this.IgnoredRailKeywordTable = [
        "Metro",
        "metro",
        "narrow-gauge",
        "Wagonway",
        "Light Rail",
        "Pipeline",
        "Telecommunication",
        "Monorail",
        "Maglev",
    ]

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

    // Init ToyLib
    this.toy_lib = AIToyLib(null, this);
    this.toy_lib.SCPConfigChange(false, false, true);

    // loop
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

    local max_loan = AICompany.GetMaxLoanAmount();
    max_loan = max_loan < this.MaxLoanKeep ? max_loan : this.MaxLoanKeep;

    local dosh;
    LCounter = AIDate.GetCurrentDate();

    while (true) {

        LoadParas();

        dosh = AICompany.GetBankBalance(Me);
        if (dosh > (max_loan * 2)) {
            CashDown(); // pay off our loan when we're rich, just for the points.
        } else {
            CashUp(); // Retake loan, just in case inflation is on
        }

        // populate dud engine
        PopulateDudEngine();

        // Run the daily functions
        local date = AIDate.GetCurrentDate();
        if (date - this.current_date != 0)
        {
            this.current_date = date;

            // comm
            AIToyLib.Check();
        }

        // Run the monthly functions
        local month = AIDate.GetMonth(date);
        if (month - this.current_month != 0)
        {
            AILog.Info("Monthly update");

            CacheTownList(); // Recache town list

            this.AskForMoney();
            this.AskForExemption();

            this.current_month = month;
        }

        // Run the yearly functions
        local year = AIDate.GetYear(date);
        if (year - this.current_year != 0)
        {
            AILog.Info("Yearly Update");

            this.current_year = year
        }

        // Run the per-decade functions
        if (year - this.current_decade_year >= 10)
        {
            AILog.Info("Decade Update");

            this.current_decade_year = year;
        }

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

function CivilAI::AskForMoney()
{
    local balance = AICompany.GetBankBalance(Me);
    local loan = AICompany.GetLoanAmount();
    if (balance - loan > 1000000)
        return;
    local money = Cachedtowns.Count() * this.TownSubsidery * 10;
    AIToyLib.ToyAskMoney(money);
    AILog.Info("I am once again asking for town subsidery of " + money);
}

function CivilAI::AskForExemption()
{
    if (this.received_exemption)
        return;
    // Ask Exemption
    AIToyLib.AskExemption(1);
    AILog.Info("I am once again asking for your exemption as an AI");
    AIToyLib.Check();
}

function CivilAI::ConfirmExemption(message, self)
{
    AILog.Info("I have received my exemption as an AI");
    self.received_exemption = true;
}