
//<
// ====================================================== 
// ====================================================== 
//         CCCC     AAAA    RRRRR     SSSS
//        C    C   A    A   R   RR   SS   S
//       CC        AAAAAA   RRRRR      SS
//        C    C   A    A   R   R    S   SS
//         CCCC    A    A   R    R    SSSS
// ====================================================== 
// ====================================================== 
//>
// ====================================================== 
//                 MANAGE TOWN CARS
// ====================================================== 

function CivilAI::Vroom() {



local rvlist = AIVehicleList_Group(Groups[1]);
local carcount = GroupCount(1)
if (carcount < MaxCar) { // do we have the maximum cars?


local vlist = AIEngineList(AIVehicle.VT_ROAD); 	// list of all road vehicles

// valid town cars have no running cost and < 10 capacity.

vlist.Valuate(AIEngine.IsValidEngine);
vlist.KeepValue(1);
vlist.Valuate(AIEngine.GetRunningCost);
vlist.KeepValue(0);
vlist.Valuate(AIEngine.GetCapacity);
vlist.KeepBelowValue(10);

if (vlist.Count() == 0) {
AILog.Info("I can't find any town cars available to buy.")

return
} else {

local townlist = AIList();
townlist.AddList(Cachedtowns);
// ====================================================== 
//      calculate the maximum number of cars to buy
// ====================================================== 

// the maximum number of towncars is governed by 3 factors;
// the config setting.
// the ratio of unserved passengers.
// the total population of the network.

// get total population
local population = 0.0
foreach (town,z in townlist) {
population = (population + AITown.GetPopulation(town))
}
// get passengers produced
local totpax = 1 // add 1, just in case something goes wrong and we end up dividing by 0.
foreach (town,z in townlist) {
totpax = (totpax + AITown.GetLastMonthProduction(town, 0))  // again assuming pax = cargo 0
}
// get passengers carried
local transpax = 0
foreach (town,z in townlist) {
transpax = (transpax + (AITown.GetLastMonthProduction(town, 0) * AITown.GetLastMonthTransportedPercentage(town, 0)))
}

local unservedperc = (100 - (transpax / totpax))

local mapsize = ((AIMap.GetMapSizeX() + AIMap.GetMapSizeY() ) / 2)
if (mapsize > NetworkRadius) { mapsize = NetworkRadius }
local worldsize = ((mapsize / 64) * (mapsize / 64))


local MaxToBuild = ((MaxCar * unservedperc / 100) * (population / worldsize / 16000) * 2).tointeger();
if (MaxToBuild > MaxCar) { MaxToBuild = MaxCar }

local CarsToBuild = (MaxToBuild - carcount)

if (CarsToBuild < 1) {
AILog.Info("No drivers want new cars (" + carcount + " town cars active).")
} else if (CarsToBuild == 1) {
AILog.Info(CarsToBuild + " driver wants a new car (" + carcount + " town cars active).")
} else {
AILog.Info(CarsToBuild + " drivers want new cars (" + carcount + " town cars active).")
//AILog.Info(CarsToBuild + " drivers want new cars (" + (((population / worldsize / 160).tointeger()) + 1) +  "% population density, " + (100 - unservedperc) + "% of passengers transported, " + carcount + " town cars active).")
}
// ====================================================== 
//             purchase and name town cars
// ====================================================== 

if (CarsToBuild > BuyCar) { CarsToBuild = BuyCar }
local c = 0
local newcar


local dlist = AIDepotList(AITile.TRANSPORT_ROAD); 	

local namefirst = ["Jim", "Bob", "Harry", "Charlie", "Eric", "Owen", "Hans", "Keith",
				   "Mike", "Albert", "Gordon", "Dave", "Clive", "Olaf", "Anthony", "Bruce",
 				   "Kelly", "Susan", "Jessie", "Jane", "Sally", "Jean", "Ruth", "Elizabeth",
				   "Mary", "Anne", "Casey", "Kate", "Ingrid", "Lucy", "Colleen", "Julia",
				   "Gwyneth", "Sam", "Margaret", "Antonia", "Gerald", "Donald", "Colin", "Dennis",
				   "Basil", "Norma", "Jeremy", "Virginia", "Emma", "Stanley", "Gladys", "Tim"]

local namelast = ["Spriggs", "Hudson", "Simpson", "McDonald", "Clarkson", "Robertson", "Jones", "Griffith",
				  "Mills", "Palmer", "Morecambe", "Rudge", "Wells", "Evans", "Dixon", "Williams",
				  "Wood", "Foster", "Jackson", "O'Malley", "Lewis", "Deakin", "Mackintosh", "Talbot",
				  "Petersen", "Churchill", "Worthington", "Steel", "Boyd", "McGrath", "Hilton", "Smith",
				  "Hughes", "Horner", "Jones", "Brown", "Dalziel", "Menzies", "Baxter", "Bond",
				  "MacArthur", "Mayne", "Armstrong", "Waterman", "Freud", "Abbott", "Cooper", "James"]
				  

while (c < CarsToBuild) {
dlist.Valuate(AIBase.RandItem); // shuffle the list
vlist.Valuate(AIBase.RandItem); // shuffle the list
newcar = (AIVehicle.BuildVehicle(dlist.Begin(),vlist.Begin())); 
if (AIVehicle.IsValidVehicle(newcar)) {
local nx = 0
local name = null
local changename = false
while (!changename && (nx < 1000)) {
nx++ 
name = (namefirst[AIBase.RandRange(48)] + " " + namelast[AIBase.RandRange(48)])
changename = AIVehicle.SetName(newcar,name)
}
AILog.Info("I've bought a car for " + AIVehicle.GetName(newcar) + ".")
AIGroup.MoveVehicle(Groups[1], newcar); // add to appropriate group
AIVehicle.StartStopVehicle(newcar);
} else {
AILog.Info("For some reason (probably not enough money), I couldn't buy a new car.")
}
c++
}
}

} else {
AILog.Info("I've already got my maximum number of town cars, so I won't build more.")
}

// ====================================================== 
//             send old cars to the depot
// ====================================================== 

for (local v = rvlist.Begin(); !(rvlist.IsEnd()); v = rvlist.Next()) {
if  ((AIVehicle.GetAgeLeft(v) < (365 * 1)) && !(AIVehicle.IsStoppedInDepot(v)) && AIVehicle.IsValidVehicle(v)) {
AIVehicle.SendVehicleToDepot(v);
//AILog.Info(AIVehicle.GetName(v) + "'s car is getting old, so I'm sending it to the depot.")
}
}

return
}
