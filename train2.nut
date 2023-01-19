// ====================================================== 
// ====================================================== 
// 			  TTTTT RRRR     A    I  N   N  ZZZZZ
// 			    T   R   R   A A   I  NN  N	   Z
// 			    T   R  R   A   A  I  N N N    Z
//  		    T   RRRR   AAAAA  I  N  NN   Z
//  		    T   R   R  A   A  I  N   N  ZZZZZ (for passengers!)
// ===========================================ChooChoo!== 
// ====================================================== 


function CivilAI::ChooChoo2() {

    if (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_RAIL)) {
        AILog.Info("I'm not allowed to build trains, boo.");
        return; // no trains for us
    }

    AILog.Info("I'm thinking about passenger trains...");

    //find a desirable link

    local townlist = AIList();
    local bslist = AIList();
    local stlist = AIList();
    local town1 = null;
    local town2 = null;
    local existingstation1 = null;
    local existingstation2 = null;

    if (AltMethod) {
        townlist.AddList(Cachedtowns);
        townlist.AddList(Exclaves);

    } else {

        // standard method: make a list of serviced towns (ie with bus stops)
        bslist = AIStationList(AIStation.STATION_BUS_STOP);
        foreach(stat, z in bslist) {
            townlist.AddItem(AIStation.GetNearestTown(stat), 0);
        }
    }

    townlist.RemoveList(DudRailCon);

    // --- remove towns with a fully connected/unconnectable station
    foreach(town, z in townlist) {

        bslist = AIStationList(AIStation.STATION_TRAIN);
        bslist.Valuate(AIStation.GetNearestTown);
        bslist.KeepValue(town);

        foreach(stat, z in bslist) {
            if (DudPTerminus.HasItem(stat)) {

                AILog.Info(AITown.GetName(town) + " has an unconnectable station.")
                townlist.RemoveItem(town);
            }
        }
    }

    // find first town ---------------

    if (townlist.Count() > 1) {
        townlist.Valuate(AIBase.RandItem); // shuffle the list
        town1 = townlist.Begin();

        AILog.Info("Considering " + AITown.GetName(town1) + "...")

        if (town1 != null) {
            bslist = AIStationList(AIStation.STATION_TRAIN);
            bslist.Valuate(AIStation.GetNearestTown);
            bslist.KeepValue(town1);

            foreach(stat, z in bslist) {
                if (AIStation.HasStationType(stat, AIStation.STATION_BUS_STOP)) {
                    existingstation1 = stat;

                    AILog.Info("Existing station found at " + AITown.GetName(town1) + ", " + AIStation.GetName(stat));

                    local pax = FindCargo("PASS");
                    local mail = FindCargo("MAIL");

                    local tlist = AIVehicleList_Station(stat);
                    tlist.Valuate(AIVehicle.GetVehicleType);
                    tlist.KeepValue(AIVehicle.VT_RAIL);
                    tlist.Valuate(AIVehicle.GetGroupID);
                    tlist.KeepValue(Groups[6]); // passenger trains

                    foreach(t, z in tlist) {
                        //AILog.Info ("Assessing stations for " + AIVehicle.GetName(t) + ".")
                        local olist = AIStationList_Vehicle(t)
                        foreach(o, z in olist) {
                            townlist.RemoveItem(AIStation.GetNearestTown(o))
                        }
                    }


                    break;
                }
            }
        }

        // find second town ---------------

        townlist.Valuate(AITown.GetDistanceManhattanToTile, AITown.GetLocation(town1));
        townlist.KeepAboveValue(48);
        townlist.KeepBelowValue(TrainRange);

        if (townlist.Count() > 0) {
            townlist.Valuate(AIBase.RandItem); // shuffle the list
            town2 = townlist.Begin();
        }


        if (town2 != null) {
            bslist = AIStationList(AIStation.STATION_TRAIN);
            bslist.Valuate(AIStation.GetNearestTown);
            bslist.KeepValue(town2);

            foreach(stat, z in bslist) {
                if (AIStation.HasStationType(stat, AIStation.STATION_BUS_STOP)) {
                    existingstation2 = stat;

                    AILog.Info("Existing station found at " + AITown.GetName(town2) + ", " + AIStation.GetName(stat));

                    break;
                }
            }
        }
    }


    if (town1 != null && town2 != null &&
        ScoreRoute(AITown.GetLocation(town1), AITown.GetLocation(town2)) < TrainRange * 2) {
        AILog.Info("I'm considering a line from " + AITown.GetName(town1) + " to " + AITown.GetName(town2) + ".");
        PaxLine(town1, town2, existingstation1, existingstation2);
    }

}