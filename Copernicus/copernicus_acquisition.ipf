#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma moduleName = copernicus
static strconstant module=copernicus


function start_acquisition()
	string daq = MasterDAQ()
	StartAcquisition()
	set_state("Acquisition:Start")
	
	SetAcquisitionMonitor(1)
	Button StartStop, title="Stop", win=DataWin
End

function stop_acquisition()
	string daq = MasterDAQ()
	StopAcquisition()
	set_state("Acquisition:Stop")
	SetAcquisitionMonitor(0)
	Button StartStop, title="Start", win=DataWin
End

function SetAcquisitionMonitor(on)
	variable on // 1 to turn on; 0 to turn off
	
	if(on)
		CtrlNamedBackground acquisition_monitor, start, period=30, proc=AcquisitionMonitor
	else
		CtrlNamedBackground acquisition_monitor, stop
	endif
end

function AcquisitionMonitor(info)
	struct WMBackgroundStruct &info
	
	string quality = check_acquisition_quality()
	string stage = check_acquisition_stage()
	strswitch(stage)
		case "finished":
			StopAcquisition()
			DoAlert 0, "Experiment is finished"
			return 1
			break
		default:
			break
	endswitch
	return 0
end

function /s check_acquisition_quality()
	compute_input_resistance()
	//check_access_resistance()
	//print("Acqusition quality is good")
	return "good"
end

function /s check_acquisition_stage()
	//wave /t sequence = get_protocol_sequence()
	string stage = ""
	variable result = auto_configure_stimulus()
	switch(result)
		case 0:
			break
		case 1:
			// Out of protocols. Experiment is finshed.
			stage = "finished"
			break
	endswitch
	return stage
end


