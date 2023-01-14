
//<
// ====================================================== 
// ====================================================== 
//      		   BBBB     U    U    SSSS
//     			   B   BB   U    U   SS   S
//      		   BBBBB    U    U     SS
//       		   B   BB   U    U   S   SS
//       		   BBBB      UUUU     SSSS
// ==========================================New bits!== 
// ====================================================== 
//>

// v20 - give buses transfer orders at train stations and airports ---------------------
function CivilAI::BusTransfers() {

local pax = FindCargo("PASS");

local bslist = AIStationList(AIStation.STATION_BUS_STOP); 
local tslist = AIStationList(AIStation.STATION_TRAIN); 
bslist.KeepList(tslist);
tslist = AIStationList(AIStation.STATION_AIRPORT);  
bslist.AddList(tslist);

	foreach (bs, z in bslist) {
//	AILog.Info ("Assessing " + AIStation.GetName(bs));	
	
	local blist = AIVehicleList_Station(bs);
	
	local xlist = AIVehicleList_Group(Groups[4]);
	xlist.AddList(AIVehicleList_Group(Groups[6]));
	xlist.KeepList(blist);
	
			if (xlist.Count() > 0) { // this stop is actually served by a passenger plane or train
	
				blist.KeepList(AIVehicleList_Group(Groups[0])); // busses only fool
				foreach (b, z in blist) {
					
				local o = 0;	
					
					while(AIOrder.IsValidVehicleOrder(b, o)) {
					
						if (AIStation.GetStationID(AIOrder.GetOrderDestination(b, o)) == bs) {
							if (AIStation.GetCargoWaiting(bs, pax) < 50) { AIOrder.SetOrderFlags(b, o, AIOrder.OF_TRANSFER + AIOrder.OF_NO_LOAD + AIOrder.OF_NON_STOP_INTERMEDIATE); }
					   else if( AIStation.GetCargoWaiting(bs, pax) > 500) { AIOrder.SetOrderFlags(b, o, AIOrder.OF_NON_STOP_INTERMEDIATE); }	
							//AILog.Info("Set " + AIVehicle.GetName(b) + " to transfer at " + AIStation.GetName(bs) + ".")
							break;
						}
					o++;
					}
				}
			}
	}
}

// v20 - remove transfer orders at a stop (if a train or air service has been discontinued) ---------------------
function CivilAI::BusDetransfer(bs) {

local blist = AIVehicleList_Station(bs);
blist.KeepList(AIVehicleList_Group(Groups[0])); // busses only fool
				foreach (b, z in blist) {
				local o = 0;	
					
					while(AIOrder.IsValidVehicleOrder(b, o)) {
					
						if (AIStation.GetStationID(AIOrder.GetOrderDestination(b, o)) == bs) {
							AIOrder.SetOrderFlags(b, o, AIOrder.OF_NON_STOP_INTERMEDIATE); 	
							break;
						}
					o++;
					}
				}
}				