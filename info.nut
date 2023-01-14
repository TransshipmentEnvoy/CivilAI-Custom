class CivilAI extends AIInfo {
  function GetAuthor()      { return "Forked by TransshipmentEnvoy"; }
  function GetName()        { return "CivilAI(Custom)"; }
  function GetDescription() { return "A general-purpose AI which builds out from a starting location. Uses buses, trucks, trains and aircraft and is friendly to children and small animals."; }
  function GetVersion()     { return 37; }
  function MinVersionToLoad () { return 1; }
  function GetDate()        { return "2023-01-01"; }
  function CreateInstance() { return "CivilAI"; }
  function GetShortName()   { return "CVLC"; }
  function GetAPIVersion()  { return "12"; }
  function UseAsRandomAI()  { return true }
  function GetSettings() {
 	AddSetting({name = "NetworkRadius", description = "The maximum radius of the road network this AI will build", easy_value = 960, medium_value = 960, hard_value = 960, custom_value = 960, flags = CONFIG_INGAME, step_size = 64, min_value = 64, max_value = 4096});
	AddSetting({name = "BrakeYear", description = "Build train brake vans, if available, until this year", easy_value = 1975, medium_value = 1975, hard_value = 1975, custom_value = 1975, flags = CONFIG_INGAME, step_size = 10, min_value = 0, max_value = 10000}); 
}  

  
  
}


/* Tell the core we are an AI */


RegisterAI(CivilAI());
