#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma moduleName=Roborig
static strconstant module=Roborig
static constant main_panel_xstart = 3
static constant main_panel_ystart = 2
static strconstant electrode_locations="Midline;Penetrate;Record"
static strconstant sutter_loc="root:Packages:Sutter:"

Menu "Roborig"
	"Initialize", Roborig#init()
	
End

function init()
	Core#LoadModuleManifest(module)
	Core#LoadPackage(module, "Coordinates")
	main_panel(rebuild=1)
end

// Generate an alert dialog
function alert(msg, actions)
	string msg // Display this message
	string actions // Semicolon-separated list of actions (Igor commands)
						// to execute for each possible button press
	// If there is one action, the button title will be "OK"
	// If there are two actions, the button titles will be "Yes" and "No"
	// If there are three actions, the button titles will be "Yes", "No", and "Cancel"
	
	variable i
	string buttons
	for(i=0;i<itemsinlist(actions);i+=1)
		
	endfor
	DoAlert itemsinlist(actions)-1, msg
	string action = stringfromlist(v_flag-1,actions)
	Execute /Q/P action
end

// Launch the main panel
Function main_panel([rebuild])
	variable rebuild
	if(rebuild)
		DoWindow /K MainPanel
	else
		if(WinType("MainPanel"))
			DoWindow /F MainPanel
			return 0
		endif
	endif
	NewPanel /K=1 /W=(0,0,745,500) /N=MainPanel as module
	main_panel_controls()
End	

// Create the main panel controls
function main_panel_controls()	
	variable xx = main_panel_xstart
	variable yy = main_panel_ystart
	
	// Animal specs
	main_panel_animal_specs(xx,yy)
	
	// Drugs present
	main_panel_drugs(xx,yy)
	
	// Cell coordinates
	main_panel_coords(xx,yy)
	
	// Actions
	main_panel_actions(xx,yy)
	
	// Status
	main_panel_status(xx,yy)
	
	// Notebook and Timed Entry
	main_panel_notebook(xx,yy)
End

// Render the main panel notebook
Function main_panel_notebook(xx, yy)
	variable &xx, &yy	
	
	yy = main_panel_ystart
	xx += 358
	GroupBox Logg frame=1, pos={xx,yy}, size={378,400}, title="Log", fstyle=1
	main_panel_timed_entry(xx, yy)
	NewNotebook /f=1 /K=2 /n=ExperimentLog /HOST=MainPanel /W=(xx+10,yy+25,xx+360,yy+375)
	Notebook MainPanel#ExperimentLog text = "", margins={0,0,300}
	string log_default=Core#StrPackageSetting(module,"logging","","log_default")
	Notebook MainPanel#ExperimentLog text = log_default
	SetActiveSubwindow MainPanel#ExperimentLog
	Notebook MainPanel#ExperimentLog selection={endOfFile,endOfFile}
End

// Create a widget for timestamped log entries
function main_panel_timed_entry(xx,yy)
	variable &xx,&yy
	
	xx += 5
	yy += 16
	SetVariable Log_Entry,pos={xx,yy},size={275,16},title="Entry:",value= _STR:"",proc=main_panel_setvariables
	Button Log_Submit,pos={xx+278,yy-2},size={45,20},proc=main_panel_buttons,title="Submit"
	Checkbox Log_Timestamp,value=1,pos={xx+327,yy+3}, title="T-stamp"
end

// Create a widget for animal specifications (DOB, weight, etc.)
function main_panel_animal_specs(xx,yy)
	variable &xx,&yy
	
	xx = main_panel_xstart
	yy+=0
	
	// Animal DOB
	GroupBox Specs frame=1, pos={xx,yy}, size={350,35}, title="Specs", fstyle=1
	xx+=5; yy+=14
	String dait=ReplaceString("/",Secs2Date(DateTime,0),";")	
	SetVariable Specs_DOB_Month,pos={xx,yy},size={65,16},proc=main_panel_setvariables, title="DOB:"
	SetVariable Specs_DOB_Month,limits={1,12,1},value=_NUM:str2num(StringFromList(0,dait))
	SetVariable Specs_DOB_Day,pos={xx+72,yy},size={40,16},proc=main_panel_setvariables
	SetVariable Specs_DOB_Day,limits={1,31,1},value=_NUM:str2num(StringFromList(1,dait))
	SetVariable Specs_DOB_Year,pos={xx+120,yy},size={50,16},proc=main_panel_setvariables
	SetVariable Specs_DOB_Year,value=_NUM:str2num(StringFromList(2,dait))
	
	// Animal Weight
	xx+=185
	SetVariable Specs_Weight,pos={xx,yy},size={103,16},bodyWidth=50,proc=main_panel_setvariables,title="Weight (g)"
	SetVariable Specs_Weight,value= _NUM:0
	
	// Cohort
	xx+=120
	PopupMenu Cohort, pos={xx,yy}, value="A;B;C"
end

// Create a widget for drug specifications
function main_panel_drugs(xx,yy)
	variable &xx, &yy
	
	xx=main_panel_xstart
	yy+=28
	variable max_drugs=3
	GroupBox Drugs frame=1, pos={xx,yy}, size={274,12+max_drugs*25}, title="Drugs", fstyle=1
	yy+=17
	variable yy0 = yy
	variable i,j
	
	for(i=1;i<=max_drugs;i+=1)
		string name="drug"+num2str(i)
		Core#CopyDefaultInstance("Acq","drugs",name)
		dfref df=Core#InstanceHome("Acq","drugs",name)
		nvar /z/sdfr=df active,conc
		svar /z/sdfr=df units
		xx=main_panel_xstart+5
		Checkbox $("Drug_"+num2str(i)), pos={xx,yy+1}, variable=active, title=" "
		xx+=17
		SetVariable $("DrugConc_"+num2str(i)),pos={xx,yy-2},size={30,18},limits={0,1000,1}, variable=conc, title=" "
		xx+=50
		PopupMenu $("DrugUnits_"+num2str(i)),pos={xx,yy-2},size={21,18},mode=1,value=#"Core#PopupMenuOptions(\"Roborig\",\"drugs\",\"\",\"units\",brackets=0)"
		xx+=40
		PopupMenu $("DrugName_"+num2str(i)),pos={xx,yy-2},size={21,18},mode=1,value=#"Core#PopupMenuOptions(\"Roborig\",\"drugs\",\"\",\"names\",brackets=0)"
		yy+=25
	endfor
	
	Button UpdateDrugs,pos={xx+50,yy0},size={100,20},title="Update",proc=main_panel_buttons
	PopupMenu DrugPresets,pos={xx+80,yy0+35},size={328,30},mode=0,value=#"Core#PopupMenuOptions(\"Roborig\",\"drugs\",\"\",\"presets\",brackets=0)",proc=main_panel_popupmenus,title="Presets"
end

// Create a widget for cell/electrode coordinate logging
function main_panel_coords(xx, yy)
	variable &xx, &yy
	
	xx = main_panel_xstart
	yy = 138
	
	wave /t names = Core#WavTPackageSetting(module, "coordinates", "", "names")
	wave coords = Core#WavTPackageSetting(module, "coordinates", "", "values")
	
	//redimension /n=2 names
	//redimension /n=(2,3) coords
	//names = {"Here","There"}
	//coords = {{1,2,3},{4,5,6}}
	
	GroupBox Coordinates frame=1, pos={xx,yy}, size={323,95+28*numpnts(names)}, title="Coordinates", fstyle=1
	variable i,j
	
	string axes = "X;Y;Z"
	xx = 10
	yy += 22
	GroupBox CurrCoordinates frame=1, pos={xx-2,yy+20}, size={230,28}
	for(j=0;j<ItemsInList(axes);j+=1)
		string axis=StringFromList(j,axes)
		TitleBox $("Coords_Title_"+axis),title=axis,pos={xx+12,yy}
		ValDisplay $("Coords_NowRel_"+axis),pos={xx,yy+25}, size={40,15},value= _NUM:12500
		SetVariable $("Coords_Now_"+axis),pos={xx,yy+50}, size={40,15},value= _NUM:12500, proc=main_panel_setvariables
		xx += 60
	endfor
	Titlebox Coords_NowRel_Title, pos={xx,yy+25}, size={100,15}, title="Relative"
	SetVariable $("Coords_Now_Name"), pos={xx-7,yy+51}, size={95,15}, value= _STR:""
	Button Coords_Now_Save, proc=main_panel_buttons, title="Save"
	
	xx = main_panel_xstart
	yy += 75
	
	variable max_names = 5
	for(i=0;i<max_names;i+=1)
		if(i<numpnts(names)) // Create controls for any saved coordinate sets
			string name = names[i]
			variable disable=0
		else // Hide controls for any saved coordinate sets that do not currently exist
			name = ""
			disable=1
		endif
		xx = 10
		for(j=0;j<ItemsInList(axes);j+=1)
			axis=StringFromList(j,axes)
			string ctrl_name = "Coords_"+num2str(i)+"_"+axis
			SetVariable $ctrl_name, pos={xx,yy}, size={40,15}, limits={0,25000,500}, title=" "
			SetVariable $ctrl_name, value=coords[i][j], disable=disable, proc=main_panel_setvariables
			xx+=60
		endfor
		Checkbox $("Coords_"+num2str(i)+"_relative"), pos={xx-15,yy+3}, proc=main_panel_checkboxes,value=0, title=" ",pos={xx-15,yy+2}, disable=disable, proc=main_panel_checkboxes
		Titlebox $("Coords_"+num2str(i)+"_name"), pos={xx,yy}, bodywidth=50, title=name, disable=disable
		ControlInfo Coords_Now_Save
		Button $("Coords_"+num2str(i)+"_delete"), pos={v_left,yy}, proc=main_panel_buttons, title="Delete", disable=disable
		yy += 25*(!disable)
	endfor
	
//	xx=main_panel_xstart-3
//	if(exists("Sutter#Init"))	
//		Checkbox Diag, pos={xx+8,yy+1}, proc=main_panel_Checkboxes, title="Diag",value=1
//		for(j=0;j<ItemsInList(electrode_axes);j+=1)
//			axis=StringFromList(j,electrode_axes)
//			xx+=75
//			SetVariable $("d"+axis),pos={xx,yy},bodywidth=50,title="d"+axis,disable=1
//			SetVariable $("d"+axis),limits={0,25000,10},value= _NUM:0,disable=1
//		endfor
//		xx=main_panel_xstart+95
//		SetVariable Angle,pos={xx,yy},bodywidth=50,title="Angle"
//		SetVariable Angle,limits={0,90,1},value= _NUM:26.565,disable=0,proc=main_panel_SetVariables
//		xx+=100
//		SetVariable dDiag,pos={xx,yy},bodywidth=50,title="dDiag"
//		SetVariable dDiag,limits={0,25000,10},value= _NUM:0,disable=0,proc=main_panel_SetVariables
//		xx+=112
//		SetVariable Sutter_Speed,value=_NUM:1,limits={0,25,0.5}, title="Speed",pos={xx,yy}, bodywidth=50
//		xx+=60
//		Button Sutter_Move proc=main_panel_Buttons,title="Go",pos={xx,yy-2},userData="Go"
//	endif
end

function main_panel_actions(xx, yy)
	variable &xx, &yy
	
	xx = main_panel_xstart
	yy += 15
	Button Action_Seal, fsize=24, pos={xx,yy}, size={75,40}, disable=0, proc=main_panel_buttons, title="Seal"
	Button Action_Run, fsize=24,  pos={xx+80,yy}, size={75,40}, disable=2, proc=main_panel_buttons, title="Run"
end

function main_panel_status(xx, yy)
	variable &xx, &yy
	
	//wave seal_status = Core#WavTPackageSetting(module, "status", "", "seal")
	xx = main_panel_xstart 
	yy += 50
	variable i
	for(i=0;i<3;i+=1)
		string str = stringfromlist(i,"Input;Access;Rest")
		string name = "Status_SealQuality_"+str
		ValDisplay $name mode=1,limits={0,1,0.5},highColor=(2,39321,1),lowColor=(65535,0,0),zeroColor=(65535,65532,16385)
		ValDisplay $name pos={xx,yy+40*i}, size={50,25}, bodywidth=25, barmisc={0,0}, value=_NUM:0.3+0.3*i
		ValDisplay $name title=str
	endfor
	Button Run, disable=1
end

// Handle all button presses
Function main_panel_buttons(ctrlName) : ButtonControl
	String ctrlName
	
	String action=StringFromList(0,ctrlName,"_") // First part of ctrlName
	String detail=ctrlName[strlen(action)+1,strlen(ctrlName)] // Remainder of ctrlName
	strswitch(action)
		case "Log":
			// Only one detail: "Submit"
			main_panel_set_log_entry()
			break
		case "Drug":
			// Only one detail: "Update"
			main_panel_set_drug()
			break
		case "Coords":
			main_panel_set_coords(detail)
			break
		case "Manipulator":
			main_panel_set_manipulator(detail)
			break
	endswitch
	FirstBlankLine("MainPanel#ExperimentLog")
End

// Handle timed log entries
function main_panel_set_log_entry()
	ControlInfo /W=MainPanel Log_Entry
	String text=S_Value
	ControlInfo /W=MainPanel Log_Timestamp
	if(V_Value)
		text+=" @ "+Secs2Time(DateTime,3)
	endif
	FirstBlankLine("MainPanel#ExperimentLog")
	Notebook MainPanel#ExperimentLog text=text+"\r"
end

// Handle changes to drugs
function main_panel_set_drug()
//	ControlInfo /W=MainPanel Drug; string drug=S_Value; string units=StringFromList(V_Value-1,conc_units)
//	ControlInfo /W=MainPanel Concentration; Variable concentration=V_Value
//	ControlInfo /W=MainPanel Dose; Variable dose=V_Value
//	FirstBlankLine("MainPanel#ExperimentLog")
//	Notebook MainPanel#ExperimentLog text="Drug: "+anaesthetic+" ("+num2str(concentration)+" "+units+") "
//	if(!StringMatch(anaesthetic,"Sevoflurane"))
//		Notebook MainPanel#ExperimentLog text=num2str(dose)+" "
//		Notebook MainPanel#ExperimentLog font="Symbol", text="m"
//		Notebook MainPanel#ExperimentLog font="default", text="L "
//	endif
//	Notebook MainPanel#ExperimentLog font="default", text="@ "+Secs2Time(DateTime,3)+"\r"
end

// Handle changes to cell/electrode coordinates
function main_panel_set_coords(detail)
	string detail
	
	string coord_set = stringfromlist(0, detail, "_")
	string action = stringfromlist(1, detail, "_")
	variable xx, yy
	wave /t names = Core#WavTPackageSetting(module, "coordinates", "", "names")
	wave coords = Core#WavTPackageSetting(module, "coordinates", "", "values")
	variable num_saved = numpnts(names)
	strswitch(coord_set)
		case "Now":
			strswitch(action)
				case "Save": // Save coordinate set
					redimension /n=(num_saved+1) names
					controlinfo Coords_Now_Name
					names[num_saved] = S_value
					redimension /n=(num_saved+1,3) coords
					controlinfo Coords_Now_Name
					variable i
					for(i=0;i<3;i+=1)
						string letter = stringfromlist(i,"X;Y;Z")
						controlinfo $("Coords_Now_"+letter)
						coords[num_saved][i] = v_value
					endfor
					main_panel_coords(xx, yy)
					break
			endswitch
			break
		default:
			variable coord_set_num = str2num(coord_set)
			strswitch(action)
				case "Delete":
					deletepoints coord_set_num, 1, names
					deletepoints /m=0 coord_set_num, 1, coords 
					main_panel_coords(xx, yy)
					break
			endswitch
	endswitch	

	//ControlInfo /W=MainPanel $(detail+"_X"); Variable mx=V_Value
	//ControlInfo /W=MainPanel $(detail+"_Y"); Variable my=V_Value
	//ControlInfo /W=MainPanel $(detail+"_Z"); Variable mz=V_Value
	//string text
	//sprintf text,detail+": (%d,%d,%d) @ %s",mx,my,mz,Secs2Time(DateTime,3)
	//FirstBlankLine("MainPanel#ExperimentLog")
	//Notebook MainPanel#ExperimentLog text=text+"\r"
end

// Move the micromanipulator
function main_panel_set_manipulator(detail)
	string detail
	
	if(StringMatch(detail,"move"))
#if exists("Sutter#SlowMove")==6
		ControlInfo /W=MainPanel Sutter_Move
		if(StringMatch(S_userData,"Go"))
			ControlInfo /W=MainPanel dX; Variable dx=V_Value
			ControlInfo /W=MainPanel dY; Variable dy=V_Value
			ControlInfo /W=MainPanel dZ; Variable dz=V_Value
			ControlInfo /W=MainPanel Sutter_Speed; Variable speed=V_Value
			Button Sutter_Move,title="Stop",userData="Stop"
			Sutter#SlowMove(dx,dy,dz,speed)
		else
			Sutter#Stop()
		endif
#endif
	else
#if exists("Sutter#Update")==6
		Sutter#Update()
#endif
		update_main_panel_coords(detail)
	endif
end

// Handle setvariable changes
Function main_panel_setvariables(info) : SetVariableControl
	STRUCT WMSetVariableAction &info
	if(info.eventCode<0)
		return 0
	endif
	string section = stringfromlist(0, info.ctrlName, "_")
	string detail = stringfromlist(1, info.ctrlName, "_")
	strswitch(section)
		case "Log":
			if(info.eventCode==2)
				//main_panel_set_log_entry()
			endif
			break
		case "Specs":
			strswitch(detail)
				case "Weight":
					main_panel_set_weight()
					break
				case "DOB":
					main_panel_set_dob()
					break
			endswitch
			break
		case "Drugs":
			break
		case "Coords":
			// All set variables are coordinates, so recompute relative coordinates.  
			main_panel_update_coords()
			break
	endswitch
	FirstBlankLine("MainPanel#ExperimentLog")
End

function main_panel_update_coords()
	variable i, max_names=5
	make /free/n=3 subtract = {0,0,0}
	wave coords = Core#WavTPackageSetting(module, "coordinates", "", "values")
	for(i=0; i<max_names; i+=1)
		ControlInfo $("Coords_"+num2str(i)+"_relative")
		if(v_value)
			duplicate /free/r=[i,i][0,2] coords subtract
			redimension /n=3 subtract
		endif
	endfor
	variable xx=v_left
	variable yy=v_top
	for(i=0; i<3; i+=1)
		string axis = stringfromlist(i,"X;Y;Z")
		ControlInfo $("Coords_Now_"+axis)
		ValDisplay $("Coords_NowRel_"+axis),value= _NUM:(v_value - subtract[i])
	endfor
	main_panel_actions(xx, yy)
	main_panel_status(xx, yy)
end

// Handle DOB changes
function main_panel_set_dob()
	ControlInfo /W=MainPanel Specs_DOB_Month
	Variable month=V_Value
	ControlInfo /W=MainPanel Specs_DOB_Day
	Variable day=V_Value
	ControlInfo /W=MainPanel Specs_DOB_Year
	Variable year=V_Value
	Notebook MainPanel#ExperimentLog findText={"DOB: ",9}
	if(V_flag)
		GetSelection notebook, MainPanel#ExperimentLog, 1
		Notebook MainPanel#ExperimentLog selection={(V_startparagraph,0),(V_startparagraph+2,0)}
	else
		FirstBlankLine("MainPanel#ExperimentLog")
	endif
	Notebook MainPanel#ExperimentLog text="DOB: "+num2str(month)+"/"+num2str(day)+"/"+num2str(year)+"\r"
	Notebook MainPanel#ExperimentLog text="Age: P"+num2str(round((datetime-date2secs(year,month,day))/(60*60*24)))+"\r"
end

// Handle weight changes
function main_panel_set_weight()
	ControlInfo /W=MainPanel Specs_Weight
	Variable weight=V_Value
	Notebook MainPanel#ExperimentLog findText={"Weight: ",9}
	if(V_flag)
		GetSelection notebook, MainPanel#ExperimentLog, 1
		Notebook MainPanel#ExperimentLog selection={(V_startparagraph,0),(V_startparagraph+1,0)}
	else
		FirstBlankLine("MainPanel#ExperimentLog")
	endif
	Notebook MainPanel#ExperimentLog text="Weight: "+num2str(weight)+" g\r"
end

// Handle popup menu selections
Function main_panel_popup_menus(info) : PopupMenuControl
	STRUCT WMPopupAction &info
	if(!SVInput(info.eventCode))
		return 0
	endif
	strswitch(info.ctrlName)
		case "Drug":
			ControlInfo Drug
			//SetVariable Concentration,value=_NUM:str2num(StringFromList(V_Value-1,conc_units)), title=StringFromList(V_Value-1,conc_units)
			//Titlebox Anaesthetic_Units, title=StringFromList(V_Value-1,anaesthetic_units)
			break
	endswitch
	FirstBlankLine("MainPanel#ExperimentLog")
End

// Handle checkbox interactions
// XXXX: Need to handle setting saved coordinates to be used for computing relative current coordinates.  
Function main_panel_checkboxes(info) : CheckboxControl
	STRUCT WMCheckboxAction &info
	if(info.eventCode<0)
		return -1
	endif
	String action=StringFromList(0,info.ctrlName,"_")
	strswitch(action)
		case "Coords":
			main_panel_update_coords()
			break
//#if exists("Sutter#Init")
//		case "Live":
//			Sutter#ToggleLive()
//			break
//		case "Diag":
//				ModifyControlList "dX;dY;dZ" disable=info.checked
//				ModifyControlList "Angle;dDiag" disable=!info.checked
//				break
//		case "Relative":
//			break
//#endif
	endswitch
End

//// Update cell/electrode coordinates from the micromanipulator
Function update_main_panel_coords(location)
	String location
//	Variable i
//	String sutter_loc="root:Packages:Sutter:"
//	ControlInfo /W=MainPanel $("Relative_"+location)
//	if(V_Value)
//		Variable relative=1
//	endif
//	for(i=0;i<ItemsInList(electrode_axes);i+=1)
//		String axis=StringFromList(i,electrode_axes)
//		NVar axis_coord=$(sutter_loc+axis+"1")
//		if(relative==1)
//			Variable j=WhichListItem(location,electrode_locations)
//			ControlInfo /W=MainPanel $(StringFromList(j-1,electrode_locations)+"_"+axis)
//			SetVariable $(location+"_"+axis) value=_NUM:(axis_coord-relative*V_Value), win=MainPanel
//		else
//			SetVariable $(location+"_"+axis) value=_NUM:axis_coord, win=MainPanel
//		endif
//	endfor
End