
// ====================================================== 
//                   HOME TOWN SET UP
// ====================================================== 

function CivilAI::LocateHomeTown()
{
AILog.Info("Oh, hello...");

// find a town
local bigtown = null;
local townlist = AITownList();
townlist.Valuate(AITown.GetPopulation);
townlist.RemoveBelowValue(MinPop);

// remove unreachables
foreach (town,z in townlist) {
local towntile = AITown.GetLocation(town);
if (!AITile.HasTransportType(towntile,AITile.TRANSPORT_ROAD)) {
AILog.Info(AITown.GetName(town) + " has no central road tile.");
townlist.RemoveItem(town);
} else{
}
}

for(local c = 0; c < 15; c++) {
if ((AICompany.ResolveCompanyID(c) != AICompany.COMPANY_INVALID) && 
    (AICompany.GetCompanyHQ(c) != AIMap.TILE_INVALID)) {
AILog.Info("Hello to " + AICompany.GetPresidentName(c) + " in " + AITown.GetName(AITile.GetClosestTown(AICompany.GetCompanyHQ(c))) + "!");	
townlist.RemoveItem(AITile.GetClosestTown(AICompany.GetCompanyHQ(c))); // don't set up in the same town as other companies
}
}

townlist.Valuate(AIBase.RandItem); // shuffle the list

foreach (town,z in townlist) {
if (!((AITown.GetLastMonthSupplied(town, 0) * 15) > AITown.GetPopulation(town))) {
bigtown = town;
break;
}
}
	
if (bigtown == null) {	
// we'll do our best...
local townlist = AITownList();

for(local c = 0; c < 15; c++) {
if ((AICompany.ResolveCompanyID(c) != AICompany.COMPANY_INVALID) && 
    (AICompany.GetCompanyHQ(c) != AIMap.TILE_INVALID) &&
	townlist.Count() > 1) {
AILog.Info("Hello to " + AICompany.GetPresidentName(c) + " in " + AITown.GetName(AITile.GetClosestTown(AICompany.GetCompanyHQ(c))) + "!");	
townlist.RemoveItem(AITile.GetClosestTown(AICompany.GetCompanyHQ(c))); // don't set up in the same town as other companies
}
}

townlist.Valuate(AITown.GetPopulation);
bigtown = townlist.Begin();
}	

//AILog.Info("First, I should probably name the company, and myself...");	
SetName(AITown.GetName(bigtown));
AILog.Info("I'll set up my headquarters in " + (AITown.GetName(bigtown)) + ".");	

HaveRoadType = SelectRoadType(true);

BuildHQ(bigtown);
return
}

function CivilAI::SetName(HomeTownName)
{
local firstnamem = [0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7]
local firstnamef = [0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7]
local lastname = [0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7]

firstnamem[0] = ("Kenneth");
firstnamem[1] = ("Gordon");
firstnamem[2] = ("Jim");
firstnamem[3] = ("Ronald");
firstnamem[4] = ("Hubert");
firstnamem[5] = ("Alan");
firstnamem[6] = ("Edgar");
firstnamem[7] = ("Tony");
firstnamem[8] = ("Bertie");
firstnamem[9] = ("Rupert");
firstnamem[10] = ("Clive");
firstnamem[11] = ("Chris");
firstnamem[12] = ("Roger");
firstnamem[13] = ("George");
firstnamem[14] = ("Henry");
firstnamem[15] = ("Thomas");

firstnamef[0] = ("Florence");
firstnamef[1] = ("Alice");
firstnamef[2] = ("Sally");
firstnamef[3] = ("Gertrude");
firstnamef[4] = ("Victoria");
firstnamef[5] = ("Madge");
firstnamef[6] = ("Liz");
firstnamef[7] = ("Ronnie");
firstnamef[8] = ("Sharon");
firstnamef[9] = ("Delia");
firstnamef[10] = ("Mavis");
firstnamef[11] = ("Gladys");
firstnamef[12] = ("Sarah");
firstnamef[13] = ("Betty");
firstnamef[14] = ("Anne");
firstnamef[15] = ("Janet");

lastname[0] = ("Wideload");
lastname[1] = ("McBus");
lastname[2] = ("Honker");
lastname[3] = ("Smythe");
lastname[4] = ("Vickers");
lastname[5] = ("Speedy");
lastname[6] = ("Diesel");
lastname[7] = ("Mangosteen");

lastname[8] = ("Murphy");
lastname[9] = ("Argyle");
lastname[10] = ("Wheeler");
lastname[11] = ("Fox");
lastname[12] = ("Chutney");
lastname[13] = ("Onslow");
lastname[14] = ("Nock");
lastname[15] = ("Spriggs");

lastname[16] = ("Jinty");
lastname[17] = ("Pepper");
lastname[18] = ("Stevenson");
lastname[19] = ("Copperbottom");
lastname[20] = ("Smellie");
lastname[21] = ("Johnson");
lastname[22] = ("King");
lastname[23] = ("Boggs");

local setn = false;
while (setn == false) {
if (AICompany.GetPresidentGender(Me) == 0) {
fname = firstnamem[AIBase.RandRange(16)];
} else {
fname = firstnamef[AIBase.RandRange(16)];
}
lname = lastname[AIBase.RandRange(24)];

if (AICompany.SetPresidentName(fname + " " + lname)) {
setn = true;
}
}
// set company colour (1.9!) =================================================================
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
local ccs = [0, 1, 2, 3, 4, 5, 6, 7]

local dull = grey;
local blank = white;
local pop = orange;
local contrast = red;

// the default company colours are biased, we're going to select one truly randomly (and if it fails, stick with the default selected)
AICompany.SetPrimaryLiveryColour(0, AIBase.RandRange(16))
local cc = AICompany.GetPrimaryLiveryColour(0)

// DARK BLUE
if (cc == darkblue) {
blank = white; dull = grey; pop = orange; contrast = red;

} else if (cc == palegreen) {
blank = white; dull = yellow; pop = red; contrast = blue;

} else if (cc == pink) {
blank = pink; dull = grey; pop = purple; contrast = darkblue;

} else if (cc == yellow) {
blank = white; dull = grey; pop = yellow; contrast = blue;

} else if (cc == red) {
blank = white; dull = grey; pop = orange; contrast = darkblue;

} else if (cc == lightblue) {
blank = white; dull = mauve; pop = brown; contrast = orange;

} else if (cc == green) {
blank = white; dull = lightblue; pop = red; contrast = yellow;

} else if (cc == darkgreen) {
blank = white; dull = lightblue; pop = red; contrast = yellow;

} else if (cc == blue) {
blank = white; dull = cream; pop = yellow; contrast = red;

} else if (cc == cream) {
blank = white; dull = palegreen; pop = orange; contrast = darkblue;

} else if (cc == mauve) {
blank = pink; dull = grey; pop = red; contrast = blue;

} else if (cc == purple) {
blank = white; dull = grey; pop = orange; contrast = darkblue;

} else if (cc == orange) {
blank = white; dull = brown; pop = red; contrast = darkblue;

} else if (cc == brown) {
blank = yellow; dull = brown; pop = yellow; contrast = red;

} else if (cc == grey) {
blank = yellow; dull = green; pop = blue; contrast = red;

} else if (cc == white) {
blank = orange; dull = green; pop = blue; contrast = red;

}

// 2cc
ccs[0] = blank;
ccs[1] = dull;
ccs[2] = pop;
AICompany.SetSecondaryLiveryColour(0, ccs[AIBase.RandRange(3)]);

// locos
ccs[0] = blank;
ccs[1] = dull;
ccs[2] = pop;
ccs[3] = contrast;
ccs[4] = cc;
AICompany.SetSecondaryLiveryColour(1, ccs[AIBase.RandRange(5)]);
AICompany.SetSecondaryLiveryColour(2, ccs[AIBase.RandRange(5)]);
AICompany.SetSecondaryLiveryColour(3, ccs[AIBase.RandRange(5)]);

// freight wagons
ccs[0] = dull;
ccs[1] = cc;
ccs[2] = brown;
ccs[3] = pop;
AICompany.SetPrimaryLiveryColour(13, ccs[AIBase.RandRange(4)]);
AICompany.SetSecondaryLiveryColour(13, ccs[AIBase.RandRange(4)]);

// bus
ccs[0] = blank;
ccs[1] = pop;
ccs[2] = contrast;
ccs[4] = dull;
AICompany.SetSecondaryLiveryColour(14, ccs[AIBase.RandRange(4)]);
AICompany.SetSecondaryLiveryColour(21, ccs[AIBase.RandRange(4)]); // tram

// truck
ccs[0] = brown;
ccs[1] = pop;
ccs[2] = cream;
ccs[4] = dull;
AICompany.SetSecondaryLiveryColour(15, ccs[AIBase.RandRange(4)]);

// ships
AICompany.SetSecondaryLiveryColour(16, contrast);
AICompany.SetSecondaryLiveryColour(17, contrast);

// planes
ccs[0] = dull;
ccs[1] = pop;
ccs[2] = contrast;
ccs[4] = blank;
AICompany.SetSecondaryLiveryColour(18, ccs[AIBase.RandRange(4)]);
AICompany.SetSecondaryLiveryColour(19, ccs[AIBase.RandRange(4)]);
AICompany.SetSecondaryLiveryColour(20, ccs[AIBase.RandRange(4)]);

// coaches and MUs - 1/4 reversed
if (AIBase.RandRange(4) == 1) {
AICompany.SetSecondaryLiveryColour(6, AICompany.GetPrimaryLiveryColour(0));
AICompany.SetSecondaryLiveryColour(7, AICompany.GetPrimaryLiveryColour(0));
AICompany.SetSecondaryLiveryColour(8, AICompany.GetPrimaryLiveryColour(0));
AICompany.SetSecondaryLiveryColour(9, AICompany.GetPrimaryLiveryColour(0));
AICompany.SetSecondaryLiveryColour(10, AICompany.GetPrimaryLiveryColour(0));
AICompany.SetPrimaryLiveryColour(6, AICompany.GetSecondaryLiveryColour(0));
AICompany.SetPrimaryLiveryColour(7, AICompany.GetSecondaryLiveryColour(0));
AICompany.SetPrimaryLiveryColour(8, AICompany.GetSecondaryLiveryColour(0));
AICompany.SetPrimaryLiveryColour(9, AICompany.GetSecondaryLiveryColour(0));
AICompany.SetPrimaryLiveryColour(10, AICompany.GetSecondaryLiveryColour(0));
}

//buses - 1/4 reversed
if (AIBase.RandRange(4) == 1) {
AICompany.SetPrimaryLiveryColour(14, AICompany.GetSecondaryLiveryColour(14));
AICompany.SetSecondaryLiveryColour(14, AICompany.GetPrimaryLiveryColour(0));
}

//planes - 1/2 reversed
if (AIBase.RandRange(2) == 1) {
AICompany.SetPrimaryLiveryColour(19, AICompany.GetSecondaryLiveryColour(19));
AICompany.SetSecondaryLiveryColour(19, AICompany.GetPrimaryLiveryColour(0));
}

// set company name

local companynames = [0,1,2,3,4,5,6,7,8,9,10,11]

companynames[0] = (HomeTownName + " Garages");
companynames[1] = ("Transport for " + HomeTownName);
companynames[2] = (HomeTownName + " Engineering");
companynames[3] = (HomeTownName + " Transport");
companynames[4] = ("Buses by " + fname);
companynames[5] = (fname + "'s Charabanc");
companynames[6] = (HomeTownName + " Express");
companynames[7] = (lname + " & Co.");
companynames[8] = (lname + " Coaches");
companynames[9] = (lname + " Haulage");
companynames[10] = (HomeTownName + " Corporation");
companynames[11] = (lname + "'s");

local set = false;
while (set == false) {
if (AICompany.SetName(companynames[AIBase.RandRange(12)]))
{
set = true;
}
}

// Set biases (one big one small as of v20)

  BiasCheap = 5;
  BiasFast =  5;
  BiasBig =   5;
  
  local d = AIBase.RandRange(6);
		if (d == 0) {BiasCheap = 25; BiasFast = 15; BiasBig = 05;}
		if (d == 1) {BiasCheap = 25; BiasFast = 05; BiasBig = 15;}
		if (d == 2) {BiasCheap = 15; BiasFast = 25; BiasBig = 05;}
		if (d == 3) {BiasCheap = 15; BiasFast = 05; BiasBig = 25;}
		if (d == 4) {BiasCheap = 05; BiasFast = 25; BiasBig = 15;}
		if (d == 5) {BiasCheap = 05; BiasFast = 15; BiasBig = 25;}
  

  
AILog.Info ("My vehicle preferences are: Cheap " + BiasCheap + "; Fast " + BiasFast + "; Big " + BiasBig + ".");

return
}

// ====================================================== 
//                     BUILD HQ
// ====================================================== 

function CivilAI::BuildHQ(hometown)
{

  local HomeTownGrid = [0,0];
  local HQ = 0;

local towntile = AITown.GetLocation(hometown);
HomeTownGrid[0] = AIMap.GetTileX(towntile);
HomeTownGrid[1] = AIMap.GetTileY(towntile);

local trytilegrid = [0,0]
local trytile = AIMap.GetTileIndex(trytilegrid[0],trytilegrid[1]);

// this is a cross search!

local i = 0; // iteration
local s = 3; // initial cross length
local j = AIBase.RandRange(2); // toggle x/y
local k = AIBase.RandRange(4); // toggle +/-

while (!AICompany.BuildCompanyHQ(trytile)) {

if (j == 0) {
	trytilegrid[1] = HomeTownGrid[1] + 2;
	if (k < 2) {
	trytilegrid[0] = (HomeTownGrid[0] + s);	
	} else {
    trytilegrid[0] = (HomeTownGrid[0] - s);
	}
} else {
	trytilegrid[0] = HomeTownGrid[0] + 2;
	if (k < 2) {
	trytilegrid[1] = (HomeTownGrid[1] + s);	
	} else {
    trytilegrid[1] = (HomeTownGrid[1] - s);	
	}
}

trytile = AIMap.GetTileIndex(trytilegrid[0],trytilegrid[1]);
// AISign.BuildSign(trytile, "I tried to build an HQ here");

if (j < 1) {
		j = j + 1;
		} else {
		j = 0;
		}
if (k < 3) {
		k = k + 1;
		} else {
		k = 0;
		}
if (i < 3) {
		i = i + 1;
		} else {
		i = 0;
		s = s + 5;
		}		

}
HQ = trytile;
//AILog.Info("I've built an HQ at " + trytilegrid[0] + " ," + trytilegrid[1] + ". We're off to a good start!");	

HomeDepot = NewDepot(hometown, true, 0, 0);

return;
}

// ====================================================== 
//            		 Group Management
// ====================================================== 

function CivilAI::MakeGroups() {

Groups[0] = AIGroup.CreateGroup(AIVehicle.VT_ROAD, AIGroup.GROUP_INVALID);
Groups[1] = AIGroup.CreateGroup(AIVehicle.VT_ROAD, AIGroup.GROUP_INVALID);
Groups[2] = AIGroup.CreateGroup(AIVehicle.VT_ROAD, AIGroup.GROUP_INVALID);
Groups[3] = AIGroup.CreateGroup(AIVehicle.VT_ROAD, AIGroup.GROUP_INVALID);

Groups[4] = AIGroup.CreateGroup(AIVehicle.VT_AIR, AIGroup.GROUP_INVALID);
Groups[5] = AIGroup.CreateGroup(AIVehicle.VT_AIR, AIGroup.GROUP_INVALID);

Groups[6] = AIGroup.CreateGroup(AIVehicle.VT_RAIL, AIGroup.GROUP_INVALID);
Groups[7] = AIGroup.CreateGroup(AIVehicle.VT_RAIL, AIGroup.GROUP_INVALID);

if (AIGroup.SetName(Groups[0], "Buses")) {} else { AIGroup.SetName(Groups[0], "Buses " + Me ) }
if (AIGroup.SetName(Groups[1], "Cars")) {} else { AIGroup.SetName(Groups[1], "Cars " + Me ) }
if (AIGroup.SetName(Groups[2], "Mail")) {} else { AIGroup.SetName(Groups[2], "Mail " + Me ) }
if (AIGroup.SetName(Groups[3], "Goods")) {} else { AIGroup.SetName(Groups[3], "Goods " + Me ) }

if (AIGroup.SetName(Groups[4], "Passenger")) {} else { AIGroup.SetName(Groups[4], "Passenger " + Me ) }
if (AIGroup.SetName(Groups[5], "Freighter")) {} else { AIGroup.SetName(Groups[5], "Freighter " + Me ) }

if (AIGroup.SetName(Groups[6], "Commuter")) {} else { AIGroup.SetName(Groups[6], "Commuter " + Me ) }
if (AIGroup.SetName(Groups[7], "Freight")) {} else { AIGroup.SetName(Groups[7], "Freight " + Me ) }
}

function CivilAI::LoadGroups() {

local glist = AIGroupList();
foreach (group,z in glist) {

	 if (AIGroup.GetName(group) == "Buses" || AIGroup.GetName(group) == "Buses " + Me) { Groups[0] = group; } 
else if (AIGroup.GetName(group) == "Cars" || AIGroup.GetName(group) == "Cars " + Me) { Groups[1] = group; } 
else if (AIGroup.GetName(group) == "Mail" || AIGroup.GetName(group) == "Mail " + Me) { Groups[2] = group; } 
else if (AIGroup.GetName(group) == "Goods" || AIGroup.GetName(group) == "Goods " + Me) { Groups[3] = group; } 
else if (AIGroup.GetName(group) == "Passenger" || AIGroup.GetName(group) == "Passenger " + Me) { Groups[4] = group; } 
else if (AIGroup.GetName(group) == "Freighter" || AIGroup.GetName(group) == "Freighter " + Me) { Groups[5] = group; } 
else if (AIGroup.GetName(group) == "Commuter" || AIGroup.GetName(group) == "Commuter " + Me) { Groups[6] = group; } 
else if (AIGroup.GetName(group) == "Freight" || AIGroup.GetName(group) == "Freight " + Me) { Groups[7] = group; } 
}

// create post-rv groups if they don't exist (primarily for backwards compatibility)

if (Groups[4] == null) {
Groups[4] = AIGroup.CreateGroup(AIVehicle.VT_AIR, AIGroup.GROUP_INVALID);
if (AIGroup.SetName(Groups[4], "Passenger")) {} else { AIGroup.SetName(Groups[4], "Passenger " + Me ) }
}
if (Groups[5] == null) {
Groups[5] = AIGroup.CreateGroup(AIVehicle.VT_AIR, AIGroup.GROUP_INVALID);
if (AIGroup.SetName(Groups[5], "Freighter")) {} else { AIGroup.SetName(Groups[5], "Freighter " + Me ) }
}
if (Groups[6] == null) {
Groups[6] = AIGroup.CreateGroup(AIVehicle.VT_RAIL, AIGroup.GROUP_INVALID);
if (AIGroup.SetName(Groups[6], "Commuter")) {} else { AIGroup.SetName(Groups[6], "Commuter " + Me ) }
}
if (Groups[7] == null) {
Groups[7] = AIGroup.CreateGroup(AIVehicle.VT_RAIL, AIGroup.GROUP_INVALID);
if (AIGroup.SetName(Groups[7], "Freight")) {} else { AIGroup.SetName(Groups[7], "Freight " + Me ) }
}






}