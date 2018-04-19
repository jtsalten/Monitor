/// Monitor Cache License  - JTS 1.3 - 2017-05-24
Class websys.MonitorLicense Extends %Persistent [ ClassType = persistent ]
{

/// This Parameter should be updated when synced from Perforce
Parameter SrcVer = "$Id: $";

/// DateTime stamp of recorded entry
Property DateTimeStamp As %TimeStamp;

/// Time of recorded entry
Property MonitorTime As %Time;

/// Date of recorded entry
Property MonitorDate As %Date;

/// License Concurrent Users - $system.License.KeyLicenseUnits()
Property CacheTotal As %Integer;

/// Licenses available - $system.License.LUAvailable()
Property CacheAvailable As %Integer;

/// Licenses consumed - $system.License.LUConsumed()
Property CacheConsumed As %Integer;

/// Max number of Licenses consumed since last system restart - $system.License.LUMaxConsumed()
Property CacheMaxNo As %Integer;

/// Min number of Licenses available since last system restart - $system.License.LUMinAvailable()
Property CacheMinNo As %Integer;

/// contains the name of your current system - $ZUTIL(110)
Property ServerName As %String(COLLATION = "ALPHAUP", MAXLEN = 220, TRUNCATE = 1);

/// Namespace where license monitor was run - $ZNSPACE
Property Namespace As %String(COLLATION = "ALPHAUP", MAXLEN = 220, TRUNCATE = 1);

/// Distributed Current License Units Used
Property DistributedCurrentUsed As %Integer;

/// Distributed Maximum License Units Used
Property DistributedMaxUsed As %Integer;

/// Distributed License Units Enforced
Property DistributedEnforced As %Integer;

/// Distributed License Units Authorized   
Property DistributedAuthorized As %Integer;

/// Maximum number of concurrent CSP users since the instance started or the CSPUsers maximum counter was reset - $system.License.MaxCSPUsers()
Property MaxCSPUsers As %Integer;

/// $system.License.MaxCSPGrace() - Maximum number of CSP sessions in the grace period at any time since the instance started or the CSPGrace maximum counter was reset
Property MaxCSPGrace As %Integer;

/// $system.License.PublicWebAppUserCount() - Current number of public web application connections active
Property PublicWebAppUsers As %Integer;

/// $system.License.PublicWebAppUsersMax() - Maximum number of public web application connections active at any one time
Property MaxPublicWebAppUsers As %Integer;

Property RowHash As %String(MAXLEN = "");

Property SimulationMode As %Boolean [ InitialExpression = 0 ];

Index DateTime On (MonitorDate, MonitorTime);

Index idxDateTimeStamp On (DateTimeStamp);

Relationship Units As websys.MonitorLicenseUnits [ Cardinality = children, Inverse = ParRef ];

Relationship Processes As websys.MonitorProcessLUs [ Cardinality = children, Inverse = ParRef ];

/// Display entry points
ClassMethod Help() As %Status
{
	
	write !,"License Monitor Help"
	write !,"-----------------------------"
	write !,""
	write !,"d ##class(websys.MonitorLicense).Clear()"
	write !,"- deletes all Monitor License data"
	write !,""
	write !,"d ##class(websys.MonitorLicense).DisplayLicenseKey()"
	write !,"- displays License keys"
	write !,""
	write !,"d ##class(websys.MonitorLicense).Export(DateFrom,DateTo,Directory)"
	write !,"- date parameters are optional. If no dates, prompts user for dates."
	write !,"- date format same as defined in TrakCare Configuration Manager"
	write !,"- exports license information to the following files"
	write !,"	YYYYMMDD_HHMM_MonitorLicenseKeys.lic - keys and inactivity timeouts"
	write !,"	YYYYMMDD_HHMM_MonitorLicenseData.csv - license count data"
	write !,"	YYYYMMDD_HHMM_MonitorLicenseUnits.csv - license units data"
	write !,"	YYYYMMDD_HHMM_MonitorLicenseUnitsByProcess.csv - license units data by process"
	write !,"	YYYYMMDD_HHMM_MonitorLicenseSummary.csv - license maximum values"
	write !,""
	write !,"d ##class(websys.MonitorLicense).Help()"
	write !,"- displays all the entry points"
	write !,""
	write !,"d ##class(websys.MonitorLicense).Save(DumpKeysPath,Debug)"
	write !,"- saves one instance of websys.MonitorLicense, websys.MonitorLicenseUnits, websys.MonitorProcessLUs"
	write !,"  and generates one dumpkeys.txt. DumpKeysPath is the destination directory"
	write !,"  path for the dumpkeys files. DumpKeysPath is optional, if no path then no "
	write !,"  dumpkeys files will be created. Debug is also optional and it's set to 'false' by default, "
	write !,"  it simulates some inserts per run in MonitorLicenseUnits and in MonitorProcessLUs"
	write !,""
	quit 1
}

/// Clear all License Monitor data
ClassMethod Clear() As %Status
{
	kill ^websys.MonitorLicenseD
	kill ^websys.MonitorLicenseI
	kill ^websys.MonitorLicenseC("Processes")
	kill ^websys.MonitorProcessLUsI
	kill ^websys.MonitorProcessLUsS
	quit 1
}

/// Display License Key information
ClassMethod DisplayLicenseKey() As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	
	try {
		//JTS+
		do ..GetLicenseKey(.tMaxUsers,.tSiteID,.tLicense,.tExpiryDate)
		write !,"Caché License Key"
		write !,"--------------------"
		write !,"Site ID: "_tSiteID
		write !,"Expiry Date: "_$zdate(tExpiryDate,4)
		write !,"Maximum Number of Users: "_tMaxUsers
		write !,"License Key: "_tLicense
		//-JTS	
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	
	quit tSC
}

// JTS+ - Generic method
/// Get general License Key Info
ClassMethod GetLicenseKey(Output MaxUsers As %String, Output SiteID As %String, Output License As %String, Output ExpiryDate As %String) As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	
	try {	
		set SiteID = $system.License.KeyCustomerName()
		set MaxUsers = $system.License.KeyLicenseUnits()
		set License=$system.License.KeyAuthorizationKey()
		set ExpiryDate=$system.License.KeyExpirationDate()
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	quit tSC
}

/// Save one instance of license monitoring statistics including license unit information
/// If pDebug = 1 it will simulate load storage as if there were more users and more processes [basically this parameter pretends to simulate data growth rate]
/// pThreshold (0.0 to 1.0) indicated the percentage of currently consumed licenses above which we'll record details (to know which users and processes are consuming those licenses)
ClassMethod Save(Path As %String = "", pDebug As %Boolean = 0, pThreshold As %Decimal = "0.5") As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	
	try {
		set obj=##class(websys.MonitorLicense).%New()
		set obj.SimulationMode = pDebug
		set obj.DateTimeStamp=$zdatetime($h,3)
		set obj.MonitorDate=+$h
		set obj.MonitorTime=$piece($h,",",2)
		set obj.CacheTotal=$system.License.KeyLicenseUnits()
		set obj.CacheAvailable=$system.License.LUAvailable()
		set obj.CacheConsumed=$system.License.LUConsumed()
		set obj.CacheMaxNo=$system.License.LUMaxConsumed()
		set obj.CacheMinNo=$system.License.LUMinAvailable()
		
		//JTS Additional metrics 
		//maximum number of concurrent CSP users since the instance started or the CSPUsers maximum counter was reset
		set obj.MaxCSPUsers = $system.License.MaxCSPUsers()
		//maximum number of CSP sessions in the grace period at any time since the instance started or the CSPGrace maximum counter was reset
		set obj.MaxCSPGrace = $system.License.MaxCSPGrace() 
		//current number of public web application connections active
		set obj.PublicWebAppUsers = $system.License.PublicWebAppUserCount()
		//maximum number of public web application connections active at any one time
		set obj.MaxPublicWebAppUsers = $system.License.PublicWebAppUsersMax()
		//-JTS
		
		set obj.ServerName=$zutil(110)
		set obj.Namespace=$znspace
		
		do ..GetDistributedLicenseValues(.DistCurrentUsed, .DistMaxUsed, .DistEnforced, .DistAuthorized)
		set obj.DistributedCurrentUsed=$get(DistCurrentUsed)
		set obj.DistributedMaxUsed=$get(DistMaxUsed)
		set obj.DistributedEnforced=$get(DistEnforced)
		set obj.DistributedAuthorized=$get(DistAuthorized)
		set save=obj.%Save(0)
		set id=obj.%Id()
		set obj.RowHash = $system.Encryption.MD5Hash(id_obj.CacheAvailable_$zd(obj.MonitorDate,3)_$ztime(obj.MonitorDate,1))
		set save=obj.%Save(0)
			
		//WARNING: Only for Cache 5.1+
		if (obj.CacheConsumed/obj.CacheTotal) > pThreshold {
			do ..SaveUserList(id,pDebug)
			do ..SaveProcessList(id,pDebug)
		}
		if $get(Path)'="" do ..DumpKeys(Path)
	}
	catch errObj {
		set tSC = errObj.AsStatus()	
	}
	quit tSC
}

/// Save license statistics from %SYSTEM.License:UserList - used for Cache 5.2 and higher
ClassMethod SaveUserList(parref As %Integer, pDebug As %Boolean = 0) As %Status
{
	#dim errObj as %Exception.AbstractException
	#dim rset as %ResultSet
	
	set tSC = $$$OK
	
	try {
		set (userid,type,connects,maxcon,cspcon,lu,active,grace)=""
		
		set rset = ##class(%ResultSet).%New("%SYSTEM.License:UserList")
		do rset.Execute()
		while (rset.Next()) {
			set userid=rset.Data("UserId")
			set type=rset.Data("Type")
			set connects=rset.Data("Connects")
			set maxcon=rset.Data("MaxCon")
			set cspcon=rset.Data("CSPCon")
			set lu=rset.Data("LU")
			set active=rset.Data("Active")
			set grace=rset.Data("Grace")
			
			&SQL(INSERT INTO websys.MonitorLicenseUnits
				(ParRef,UserId,Type,Connects,MaxCon,CSPCon,LU,Active,Grace,SimulatedData)
				VALUES (:parref,:userid,:type,:connects,:maxcon,:cspcon,:lu,:active,:grace,0))
			if pDebug {
				for i=1:1:300 {
					&SQL(INSERT INTO websys.MonitorLicenseUnits
					(ParRef,UserId,Type,Connects,MaxCon,CSPCon,LU,Active,Grace,SimulatedData)
					VALUES (:parref,:userid,:type,:connects,:maxcon,:cspcon,:lu,:active,:grace,:pDebug))
				}
			}
		}
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	quit tSC
}

ClassMethod SaveProcessList(parref As %Integer, pDebug As %Boolean = 0) As %Status
{
	#dim errObj as %Exception.AbstractException
	#dim rset as %Library.ResultSet
	
	set tSC=$$$OK
	
	try {
		
		set (tPID,tDisplayPID,tProcess,tUserId,tType,tCon,tMaxCon,tCSPSessions,tLU,tActive,tGrace)=""
		
		set rset = ##class(%ResultSet).%New("%SYSTEM.License:ProcessList")
		do rset.Execute()
		while (rset.Next()) {
			set tPID = rset.Data("PID")
			set tDisplayPID = rset.Data("DisplayPID")
			set tProcess = rset.Data("Process")
			set tUserId = rset.Data("LID")
			set tType = rset.Data("Type")
			set tCon = rset.Data("Con")
			set tMaxCon = rset.Data("MaxCon")
			set tCSPSessions = rset.Data("CSPCon")
			set tLU = rset.Data("LU")
			set tActive = rset.Data("Active")
			set tGrace = rset.Data("Grace")
		
			//Only store process that could consume licenses - Skip types: System | CSP | Diagnostic
			if (tType="User")||(tType="Server")||(tType="Pending") {
				&SQL(INSERT INTO websys.MonitorProcessLUs (parref,PID, DisplayPID, Process, UserId, Type, Con, MaxCon, CSPSessions, LU, Active, Grace, SimulatedData)
						VALUES (:parref,:tPID,:tDisplayPID,:tProcess,:tUserId,:tType,:tCon,:tMaxCon,:tCSPSessions,:tLU,:tActive,:tGrace,0))
				if pDebug {
					for i=1:1:4 {
						&SQL(INSERT INTO websys.MonitorProcessLUs (parref,PID, DisplayPID, Process, UserId, Type, Con, MaxCon, CSPSessions, LU, Active, Grace, SimulatedData)
								VALUES (:parref,:tPID,:tDisplayPID,:tProcess,:tUserId,:tType,:tCon,:tMaxCon,:tCSPSessions,:tLU,:tActive,:tGrace,:pDebug))
					}
				}
			}
		}

	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}	
	
	quit tSC
}

/// To be called from a Task to get information during shorter polling periods
/// Example: task that executes this method each minute from 09:00 am to 14:00 with 10 s polling period.
/// Polling will end automatically when execution goes beyond the beginning day
ClassMethod RunByMinute(pPoolingTime As %Integer = 10, pDebug As %Boolean = 0) As %Status
{
	if pPoolingTime'>0.5 set pPoolingTime = 0.5
	if pPoolingTime>59 set pPoolingTime = 59
	
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
		
	try {
		set tLoops = 59\pPoolingTime
		for tCnt=1:1:tLoops{
			do ..Save(,pDebug)
			h pPoolingTime
		}
	}
	catch errObj {
		set tSC	 = errObj.AsStatus()
	}
	
	quit tSC
}

/// Exports license key information to filename.lic and license count data to filename.csv.
/// Prompt the user for DateFrom, DateTo and destination File Path. By default it exports all the data since 15 days up
ClassMethod Export(DateFrom As %String = {$zd((+$h-15),3)}, DateTo As %String = {$zd(+$h,3)}, Path As %String = "", pDel As %String = ",", pWithSimulatedData As %Boolean = 0) As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	
	try {
		if ('$zdh(DateFrom,3,,,,,,,0)||('$zdh(DateTo,3,,,,,,,0))) $$$ThrowOnError($$$ERROR("LICMON1","ERROR: Invalid dates"))
		//quit:((Path="")||('##class(%Library.File).DirectoryExists(Path))) "ERROR: Invalid directory"	
		if ((Path="")||('##class(%Library.File).DirectoryExists(Path))) $$$ThrowOnError($$$ERROR("LICMON2","ERROR: Invalid Directory"))
		if $zdh(DateTo,3)<$zdh(DateFrom,3) $$$ThrowOnError($$$ERROR("LICMON3","ERROR: Date To must be after Date From"))

		w !,"Dateform: "_DateFrom_"   DateTo: "_DateTo,!
				
		// set trailing slash
		set filepath=..SetDirSlash(Path)
		
		write !,""
		write !,"Export data between "_DateFrom_" and "_DateTo
		write !,"to filepath: "_$get(filepath)
		
		write !,"Exporting... "
		//set filenames
		set hhmm=$translate($ztime($piece($h,",",2),2),":","")
		set filepath=filepath_$zdate(+$h,8)_"_"_hhmm_"_MonitorLicense"
		set csvfilename=filepath_"Data.csv"
		set licfilename=filepath_"Keys.lic"
		set unitsfilename=filepath_"Units.csv"
		set unitsbyprocfilename=filepath_"UnitsByProcess.csv"
		set maxdailyfilename=filepath_"DailySummary.csv"
		set maxtotalsfilename=filepath_"TotalsSummary.csv"
		//write license key file
		do ..WriteLicenseKeyFile(licfilename)
		//write license data file
		do ..WriteLicenseDataFile(csvfilename,unitsfilename,unitsbyprocfilename,$zdh(DateFrom,3),$zdh(DateTo,3),pDel,pWithSimulatedData)
		do ..WriteMaxDailyDataFile(maxdailyfilename,$zdh(DateFrom,3),$zdh(DateTo,3),pDel)
		do ..WriteMaxTotalsDataFile(maxtotalsfilename,$zdh(DateFrom,3),$zdh(DateTo,3),pDel)
		write !,"Done!"
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	
	quit tSC
}

/// Write license key information to file - called by Export()
ClassMethod WriteLicenseKeyFile(filename As %String) As %Status [ PlaceAfter = DisplayLicenseKey ]
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	
	try {
		set file=##class(%File).%New(filename)
		do file.Open("WSN")
		
		//write Cache License Key to file
		set stream=##class(%FileCharacterStream).%New()
		set stream.Filename=$system.Util.ManagerDirectory()_"cache.key"
		while 'stream.AtEnd {
			set line=stream.ReadLine()
			do file.WriteLine(line)
		}
		do file.WriteLine("")
		
		do file.Close()
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
		
	quit tSC
}

/// Write license statistics to file - called from Export()
ClassMethod WriteLicenseDataFile(filename As %String, ufilename As %String, pProcFileName As %String, DateFrom As %Date, DateTo As %Date, del As %String = ",", pWithSimulatedData As %Boolean = 0) As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	
	try {
		set (str,ustr,tProcHead)=""
			
		set file=##class(%File).%New(filename)
		do file.Open("WSN")
		set ufile=##class(%File).%New(ufilename)
		do ufile.Open("WSN")
		set tProcFile=##class(%File).%New(pProcFileName)
		do tProcFile.Open("WSN")

		&SQL(DECLARE LICENSE CURSOR FOR
			SELECT
			ID,DateTimeStamp,CAST(MonitorDate as CHAR(10)), CAST(MonitorTime as CHAR(8)),CacheConsumed,CacheTotal,CacheAvailable,CacheMaxNo,CacheMinNo,
			DistributedCurrentUsed, DistributedMaxUsed, DistributedEnforced, DistributedAuthorized,MaxCSPGrace, MaxCSPUsers, MaxPublicWebAppUsers,
			PublicWebAppUsers,ServerName,Namespace,SimulationMode
			FROM websys.MonitorLicense
			WHERE MonitorDate >=:DateFrom AND MonitorDate <=:DateTo)
		
		//Column Headings
		set str = "ID,DateTimeStamp,MonitorDate,MonitorTime,CacheConsumed,CacheTotal,CacheAvailable,CacheMaxNo,CacheMinNo,"
				_"DistributedCurrentUsed,DistributedMaxUsed,DistributedEnforced,DistributedAuthorized,"
				_"MaxCSPGrace,MaxCSPUsers,MaxPublicWebAppUsers,PublicWebAppUsers,ServerName,Namespace,SimulationMode"
		set:del'="," str=$replace(str,",",del)
		do file.WriteLine(str)
		
		//License Units by User - Column Headings
		set ustr="ParRef,DateTimeStamp,MonitorTime,UserId,Type,Active,Connects,LU,MaxCon,CSPCon,Grace,SimulatedData"
		set:del'="," ustr=$replace(ustr,",",del)
		do ufile.WriteLine(ustr)

		//License Units by Process - Column Headings
		set tProcHead="ParRef,DateTimeStamp,MonitorTime,PID,DisplayPID,Process,UserId,Type,Active,Con,LU,MaxCon,Grace,CSPSessions,SimulatedData"
		set:del'="," tProcHead=$replace(tProcHead,",",del)
		do tProcFile.WriteLine(tProcHead)

		&SQL(OPEN LICENSE)
		do {
			&SQL(FETCH LICENSE INTO
				:tData(1),:tData(2),:tData(3),:tData(4),:tData(5),:tData(6),:tData(7),
				:tData(8),:tData(9),:tData(10),:tData(11),
				:tData(12),:tData(13),:tData(14),:tData(15),:tData(16),:tData(17),:tData(18),:tData(19),:tData(20))
			if 'SQLCODE {
				//build row and write to file
				set str=""
				set tColStart=0  // 0 - we start from tData(1) inclusive, 1 - we discard tData(1), 2 -....
				set tSC = ..SerializeRow(.str,.tData,tColStart,del)
				$$$ThrowOnError(tSC)
				do file.WriteLine(str)
				set tID = tData(1)
				do ..WriteLicenseUnitsFile(ufile,tID,del,pWithSimulatedData)
				do ..WriteProcessLicenseUnitsFile(tProcFile,tID,del,pWithSimulatedData)
			}
			kill tData
		} while 'SQLCODE
		&SQL(CLOSE LICENSE)
		
		do file.Close()
		do ufile.Close()
	} 
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	
	quit tSC
}

/// Write a summary data file with maximum values within specified date range
ClassMethod WriteMaxTotalsDataFile(filename As %String, DateFrom As %Date, DateTo As %Date, del As %String = ",") As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	try {
		set (str,tCnt)=""
		
		set file=##class(%File).%New(filename)
		do file.Open("WSN")

		//write TOTAL title heading
		set str="Maximum Totals from "_$zdate(DateFrom,3)_" to "_$zdate(DateTo,3)
		do file.WriteLine(str)
		
		//Column Headings
		set str="CacheConsumed,ServerName,Namespace,DistributedCurrentUsed,DistributedMaxUsed,DistributedEnforced,DistributedAuthorized"
		set:del'="," str = $replace(str,",",del)
		do file.WriteLine(str)
		
		//write TOTAL summary line
		&SQL(SELECT DISTINCT MonitorDate, Max(CacheConsumed),
			Max(DistributedCurrentUsed), Max(DistributedMaxUsed), Max(DistributedEnforced), Max(DistributedAuthorized),ServerName,Namespace
			INTO :tData(1),:tData(2),:tData(3),:tData(4),:tData(5),:tData(6),:tData(7),:tData(8)
			FROM websys.MonitorLicense
			WHERE MonitorDate >=:DateFrom AND MonitorDate <=:DateTo)
		
		//Write Line of Data to File
		set str=""
		set tSC = ..SerializeRow(.str,.tData,0,del)
		$$$ThrowOnError(tSC)
		do file.WriteLine(str)
		do file.Close()
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	
	quit tSC
}

/// Write a summary data file with maximum DAILY values within specified date range
ClassMethod WriteMaxDailyDataFile(filename As %String, DateFrom As %Date, DateTo As %Date, del As %String = ",") As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	try {
		set str=""
		set MonDate=""

		//Create DAILY maximums
		set file=##class(%File).%New(filename)
		do file.Open("WSN")
		
		//Write DAILY maximum
		set str="Maximum Daily Totals from "_$zdate(DateFrom,3)_" to "_$zdate(DateTo,3)
		do file.WriteLine(str)

		//Column Headings
		set str="Date,CacheConsumed,DistributedCurrentUsed,DistributedMaxUsed,DistributedEnforced,DistributedAuthorized,ServerName,Namespace"
		set:del'="," str=$replace(str,",",del)
		
		do file.WriteLine(str)
		
		//find all recorded dates between specified date range
		&SQL(DECLARE LICENSEDATES CURSOR FOR
			SELECT DISTINCT MonitorDate
			FROM websys.MonitorLicense
			WHERE MonitorDate >=:DateFrom AND MonitorDate <=:DateTo)
		&SQL(OPEN LICENSEDATES)
		do {
			&SQL(FETCH LICENSEDATES INTO :MonDate)
			set Finished=SQLCODE
			if 'SQLCODE {
				&SQL(SELECT DISTINCT MonitorDate,Max(CacheConsumed),
						Max(DistributedCurrentUsed), Max(DistributedMaxUsed), Max(DistributedEnforced), Max(DistributedAuthorized),ServerName,Namespace
					INTO :tData(1),:tData(2),:tData(3),:tData(4),
						:tData(5),:tData(6),:tData(7),:tData(8)
					FROM websys.MonitorLicense
					WHERE MonitorDate = :MonDate)
				if 'SQLCODE {
					//build row and write to file
					set str=$zdate(MonDate,3)_del
					set tSC = ..SerializeRow(.str,.tData,1,del) // we start to serialize from second column on
					$$$ThrowOnError(tSC)
					do file.WriteLine(str)
				}
			}
		} while 'Finished
		&SQL(CLOSE LICENSEDATES)

		do file.Close()
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	
	quit tSC
}

/// write license monitor units to file
ClassMethod WriteLicenseUnitsFile(ByRef ufile As %File, id As %Integer, del As %String = ",", pWithSimulatedData As %Boolean = 0) As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	try {
		//Heading:"ParRef,DateTimeStamp,MonitorTime,UserId,Type,Active,Connects,LU,MaxCon,CSPCon,Grace,SimulatedData"
		&SQL(DECLARE UNITS CURSOR FOR
			SELECT ParRef,ParRef->DateTimeStamp,CAST (ParRef->MonitorTime as Char(8)),UserId,Type,Active,Connects,LU,MaxCon,CSPCon,Grace,SimulatedData
			FROM websys.MonitorLicenseUnits
			WHERE ParRef=:id and SimulatedData <= :pWithSimulatedData
			)
		&SQL(OPEN UNITS)
		do {
			&SQL(FETCH UNITS INTO
				:tData(1),:tData(2),:tData(3),:tData(4),:tData(5),:tData(6),:tData(7),:tData(8),:tData(9),:tData(10),:tData(11),:tData(12))
			if 'SQLCODE {
				set str=""
				set tSC = ..SerializeRow(.str,.tData,0,del)
				$$$ThrowOnError(tSC)
				do ufile.WriteLine(str)	
			}
		} while 'SQLCODE
		&SQL(CLOSE UNITS)
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
		
	quit tSC
}

/// write Process - license monitor units to file
ClassMethod WriteProcessLicenseUnitsFile(ByRef ufile As %File, id As %Integer, del As %String = ",", pWithSimulatedData As %Boolean = 0) As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	try {
		//Heading: "ParRef,DateTimeStamp,MonitorTime,PID, DisplayPID, Process, UserId, Type, Active, Con, LU, MaxCon, Grace, CSPSessions,SimulatedData"
		&SQL(DECLARE PROCUNITS CURSOR FOR
			SELECT ParRef,ParRef->DateTimeStamp,CAST (ParRef->MonitorTime as Char(8)),PID, DisplayPID, Process, UserId, Type, Active, Con, LU, MaxCon, Grace, CSPSessions, SimulatedData 
			FROM websys.MonitorProcessLUs
			WHERE ParRef=:id and SimulatedData <= :pWithSimulatedData
			)
		&SQL(OPEN PROCUNITS)
		do {
			&SQL(FETCH PROCUNITS INTO
				:tData(1),:tData(2),:tData(3),:tData(4),:tData(5),:tData(6),:tData(7),:tData(8),:tData(9),:tData(10),:tData(11),:tData(12),:tData(13),:tData(14),:tData(15))
			if 'SQLCODE {
				set str=""
				set tSC = ..SerializeRow(.str,.tData,0,del)
				$$$ThrowOnError(tSC)
				do ufile.WriteLine(str)	
			}
		} while 'SQLCODE
		&SQL(CLOSE PROCUNITS)
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
		
	quit tSC
}

ClassMethod SerializeRow(ByRef pStr As %String = "", ByRef pData, pIni As %String = "", pSep As %String = ",") As %String
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	try {	
		set tCnt=$order(pData(pIni))
		while tCnt'="" {
			set pStr=pStr_pData(tCnt)
			set tCnt=$order(pData(tCnt))
			set:tCnt'="" pStr=pStr_pSep	
		}
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	
	quit tSC
}

/// Prompt user for target directory
ClassMethod GetDirectory() As %String
{
	set dir=""
	
	//prompt user for target directory
	write !,"Enter directory, default is "_$zutil(168)
	read !,"Directory? Default => ",dir
	
	//if filepath is blank set default database path
	if $get(dir)="" set dir=$zutil(168)
	
	quit dir
}

/// Set trailing directory slash
ClassMethod SetDirSlash(dir As %String) As %String
{
	//determine slash based on operating system
	if $zversion(1)=2	{  //Windows
		set slash="\"
	}else{
		set slash="/"
	}
	//if not trailing slash then add one
	if $extract(dir,$length(dir))'=slash set dir=dir_slash
	
	quit dir
}

/// Return distributed license count
ClassMethod GetDistributedLicenseValues(ByRef DistCurrentUsed As %Integer, ByRef DistMaxUsed As %Integer, ByRef DistEnforced As %Integer, ByRef DistAuthorized As %Integer) As %Status [ ProcedureBlock = 1 ]
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	
	try {
		// the below code comes from %SYS.LICENSE
		set address=$zutil(201,4)
		if address'=$char(0,0,0,0,0,0) {
			set request=3
			set x=$zutil(112,16,3,address,request)
			set y=$piece(x,"|",2)
			set DistCurrentUsed=$piece(y,",",1)
			set DistMaxUsed=$piece(y,",",2)
			set DistEnforced=$piece(y,",",3)
			set DistAuthorized=$piece(y,",",4)
		}
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	
	quit tSC
}

/// Run dumpkeys
ClassMethod DumpKeys(Path As %String = "") As %Status
{
	#dim errObj as %Exception.AbstractException
	set tSC = $$$OK
	
	try {	
		if $get(Path)="" {
			set filepath=..GetDirectory()
		} else {
			set filepath=Path
		}

		//if directory does not exist quit
		if '##class(%Library.File).DirectoryExists(filepath) $$$ThrowOnError($$$ERROR("LICMON2","ERROR: Invalid directory")) 

		write !,"Dump Keys License Monitor"
		write !,"-------------------------"
		write !,""
		
		// set trailing slash
		set filepath=..SetDirSlash(filepath)
		
		set mgrdir=$zutil(12)
		set day=$zdate(+$h,8)
		set time=$ztime($piece($h,",",2),2)
		set time=$translate(time,":","")
		set prefix = day_"_"_time
		
		write !,""
		//create dumpkeys.txt in system mgr directory
		do $system.License.DumpKeys()
		
		//copy file to filepath
		if ##class(%File).Exists(mgrdir_"dumpkeys.txt") {
			set filename=filepath_prefix_"_dumpkeys.txt"
			do ##class(%File).CopyFile(mgrdir_"dumpkeys.txt",filename)
			write !,"Dumpkeys file copied to:  "_filename
			write !,""
		} else {
			write !,"Error - dumpkeys.txt file not found"
		}
	}
	catch errObj {
		set tSC = errObj.AsStatus()
	}
	
	quit tSC
}

/// JSON data
/// must be in date time order, get daily max
Query Summary(RunDateFromH As %Date = {+$H}, RunDateToH As %Date = {+$H}) As %SQLQuery
{
	SELECT MonitorDate AS RunDate,CAST('0' AS TIME) AS RunTime,MAX(CacheMaxNo) AS CacheMaxNo,MAX(CacheTotal) AS CacheTotal
	FROM websys.MonitorLicense
	WHERE MonitorDate>=:RunDateFromH
		AND MonitorDate<=:RunDateToH
	GROUP BY MonitorDate
	ORDER BY MonitorDate
}

Storage Default
{
<Data name="MonitorLicenseDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>CacheAvailable</Value>
</Value>
<Value name="3">
<Value>CacheConsumed</Value>
</Value>
<Value name="4">
<Value>CacheMaxNo</Value>
</Value>
<Value name="5">
<Value>CacheMinNo</Value>
</Value>
<Value name="6">
<Value>CacheTotal</Value>
</Value>
<Value name="7">
<Value>DateTimeStamp</Value>
</Value>
<Value name="8">
<Value>LabTrak</Value>
</Value>
<Value name="9">
<Value>MonitorDate</Value>
</Value>
<Value name="10">
<Value>ServerName</Value>
</Value>
<Value name="11">
<Value>TrakCare</Value>
</Value>
<Value name="12">
<Value>MedTrak</Value>
</Value>
<Value name="13">
<Value>MonitorTime</Value>
</Value>
<Value name="14">
<Value>LabInstruments</Value>
</Value>
<Value name="15">
<Value>Namespace</Value>
</Value>
<Value name="16">
<Value>DistributedCurrentUsed</Value>
</Value>
<Value name="17">
<Value>DistributedMaxUsed</Value>
</Value>
<Value name="18">
<Value>DistributedEnforced</Value>
</Value>
<Value name="19">
<Value>DistributedAuthorized</Value>
</Value>
<Value name="20">
<Value>MaxCSPUsers</Value>
</Value>
<Value name="21">
<Value>MaxCSPGrace</Value>
</Value>
<Value name="22">
<Value>PublicWebAppUsers</Value>
</Value>
<Value name="23">
<Value>MaxPublicWebAppUsers</Value>
</Value>
<Value name="24">
<Value>RowHash</Value>
</Value>
<Value name="25">
<Value>SimulationMode</Value>
</Value>
</Data>
<DataLocation>^websys.MonitorLicenseD</DataLocation>
<DefaultData>MonitorLicenseDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^websys.MonitorLicenseD</IdLocation>
<IndexLocation>^websys.MonitorLicenseI</IndexLocation>
<StreamLocation>^websys.MonitorLicenseS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

