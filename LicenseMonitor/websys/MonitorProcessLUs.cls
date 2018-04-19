Class websys.MonitorProcessLUs Extends %Persistent [ ClassType = persistent, CompileAfter = websys.MonitorLicense ]
{

/// This Parameter should be updated when synced from Perforce
Parameter SrcVer = "$Id: $";

Relationship ParRef As websys.MonitorLicense [ Cardinality = parent, Inverse = Processes ];

// PID:DisplayPID:Process:UserId:Type:Con:MaxCon:CSPCon:LU:Active:Grace
/// OS PID identifier
Property PID As %Integer;

/// Display form for PID
Property DisplayPID As %String;

/// Process login type:
/// System - system processes that do not consume a license unit.
/// User - Regular user (terminal, ODBC, Cache Direct) login. 
/// CSP - Cache Server Pages server process. A CSP server process does not maintain an association with an internal license table entry. 
/// 			The association is rather with the session. For this reason, information regarding number of connections, 
/// 			and license units is not available for CSP processes. Use the UserList query to obtain this information for CSP sessions.
/// Diagnostic - Process is logged in to Cache with the "-B" command line argument and is using the diagnostic license unit.
/// Server - A server process (eg the COMMCTRL process) which does not consume a license unit, but which creates jobs which do consume license units.
/// Pending - A process for which license acquisition is pending. Can occur when deferred license acquisition is in effect.
Property Process As %String;

/// License login UserId for this process
Property UserId As %String;

/// Type of login license type:
///    User - Regular user login
///    CSP - Cache Server Page login
///    Mixed - Regular user plus Cache Server Page login
///    Grace - Logged out CSP session waiting for grace period to expire.
Property Type As %String;

/// Number of connections for the UserId
Property Con As %Integer;

/// Max number of connections for the UserId
Property MaxCon As %Integer;

/// Number of CSP sessions open for the UserId
Property CSPSessions As %Integer;

/// License Units consumed by this UserId
Property LU As %Integer;

/// Time in seconds the UserId has been logged
Property Active As %Integer;

/// Amount of time in seconds this license unit will remain in the grace period if all connections were closed immediately
Property Grace As %Integer;

Property SimulatedData As %Boolean [ InitialExpression = 0 ];

Index idxPID On (PID);

Index idxProcess On (Process);

Storage Default
{
<Data name="MonitorProcessLUsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PID</Value>
</Value>
<Value name="3">
<Value>DisplayPID</Value>
</Value>
<Value name="4">
<Value>Process</Value>
</Value>
<Value name="5">
<Value>UserId</Value>
</Value>
<Value name="6">
<Value>Type</Value>
</Value>
<Value name="7">
<Value>Con</Value>
</Value>
<Value name="8">
<Value>MaxCon</Value>
</Value>
<Value name="9">
<Value>CSPSessions</Value>
</Value>
<Value name="10">
<Value>LU</Value>
</Value>
<Value name="11">
<Value>Active</Value>
</Value>
<Value name="12">
<Value>Grace</Value>
</Value>
<Value name="13">
<Value>SimulationMode</Value>
</Value>
<Value name="14">
<Value>SimulatedData</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Processes")</DataLocation>
<DefaultData>MonitorProcessLUsDefaultData</DefaultData>
<IdLocation>^websys.MonitorLicenseC("Processes")</IdLocation>
<IndexLocation>^websys.MonitorProcessLUsI</IndexLocation>
<StreamLocation>^websys.MonitorProcessLUsS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

