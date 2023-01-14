
//>
// ====================================================== 
//                       SAVE/LOAD
// ====================================================== 

function CivilAI::Save() {
local Save = {
s0 = [],
s1 = [],
s2 = [],
s3 = [],
s4 = 0,
s5 = [],
s6 = [],
s7 = [],
s8 = [],
s9 = [],
s10 = [],
s11 = [],
s12 = [],
slname = null,
sfname = null,
sBiasCheap = null,
sBiasFast = null,
sBiasBig = null,
sRoadType = null
};

Save.s0 = CivilAI.ListToArray(Dudtowns);
Save.s1 = CivilAI.ListToArray(DudTerminus);
Save.s2 = CivilAI.ListToArray(DudIndustries);
Save.s3 = CivilAI.ListToArray(IndTownList);
Save.s4 = DudCounter;
Save.s5 = CivilAI.ListToArray(DudBusNetwork);
Save.s6 = CivilAI.ListToArray(Exclaves);
Save.s7 = CivilAI.ListToArray(DudRailCon);
Save.s8 = CivilAI.ListToArray(DudPTerminus);
Save.s9 = CivilAI.ListToArray(ConnectedPInds);
Save.s10 = CivilAI.ListToArray(DontGoodsTruck);
Save.s11 = CivilAI.ListToArray(DudEngines);
Save.s11 = CivilAI.ListToArray(BannedRoadTypes);
Save.slname = lname;
Save.sfname = fname;
Save.sBiasCheap = BiasCheap;
Save.sBiasFast = BiasFast;
Save.sBiasBig = BiasBig;
Save.sRoadType = AIRoad.GetCurrentRoadType();

AILog.Info("I've made a few notes...");

return Save;
}  
function CivilAI::Load(version, data) {

if ("s0" in data) Dudtowns = ArrayToList(data.s0);
if ("s1" in data) DudTerminus = ArrayToList(data.s1);
if ("s2" in data) DudIndustries = ArrayToList(data.s2);
if ("s3" in data) IndTownList = ArrayToList(data.s3);
if ("s4" in data) DudCounter = data.s4;
if ("s5" in data) DudBusNetwork = ArrayToList(data.s5);
if ("s6" in data) Exclaves = ArrayToList(data.s6);
if ("s7" in data) DudRailCon = ArrayToList(data.s7);
if ("s8" in data) DudPTerminus = ArrayToList(data.s8);
if ("s9" in data) ConnectedPInds = ArrayToList(data.s9);
if ("s10" in data) DontGoodsTruck = ArrayToList(data.s10);
if ("s11" in data) DudEngines = ArrayToList(data.s11);
if ("s12" in data) BannedRoadTypes = ArrayToList(data.s12);

if ("slname" in data) {lname = data.slname;} else {lname = "Tycoon";}
if ("sfname" in data) {fname = data.sfname;} else {fname = "Transport";}
if ("sBiasCheap" in data) {BiasCheap = data.sBiasCheap;} else {BiasCheap = 10;}
if ("sBiasFast" in data) {BiasFast = data.sBiasFast;} else {BiasFast = 10;}
if ("sBiasBig" in data) {BiasBig = data.sBiasBig;} else {BiasBig = 10;}
if ("sRoadType" in data) {AIRoad.SetCurrentRoadType(data.sRoadType);} else {SelectRoadType(true);}

AILog.Info(fname + " " + lname + " here - I've found my notes.");

IsLoaded = true;
}  

/**
 * Converts an AIList to an array.
 * @param list The AIList to be converted.
 * @return The converted array.
 * Thanks to Brumi/SimpleAI for this code.
 */
function CivilAI::ListToArray(list)
{
	local array = [];
	local templist = AIList();
	templist.AddList(list);
	while (templist.Count() > 0) {
		local arrayitem = [templist.Begin(), templist.GetValue(templist.Begin())];
		array.append(arrayitem);
		templist.RemoveTop(1);
	}
	return array;
}

/**
 * Converts an array to an AIList.
 * @param The array to be converted.
 * @return The converted AIList.
  * Thanks to Brumi/SimpleAI for this code.
 */
function CivilAI::ArrayToList(array)
{
	local list = AIList();
	local temparray = [];
	temparray.extend(array);
	while (temparray.len() > 0) {
		local arrayitem = temparray.pop();
		list.AddItem(arrayitem[0], arrayitem[1]);
	}
	return list;
}

// ====================================================== 
//                     LOAD PARAMETERS
// ====================================================== 

function CivilAI::LoadParas() {
NetworkRadius = AIController.GetSetting("NetworkRadius");
BrakeYear = 	AIController.GetSetting("BrakeYear");

// the following were formerly parameters, but are now set values. Modify if you want to!

MinPop =		1000 
MaxBus = 		500  
MaxCar = 		500  
BuyCar = 	 	10 
MinAirRange =	80 
BuyPlane = 		1  
TrainRange = 	NetworkRadius / 2
ShipRange = 	NetworkRadius 	
}
  