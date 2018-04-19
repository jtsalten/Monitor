Class websys.MonitorLicenseUnits Extends %Persistent [ ClassType = persistent, CompileAfter = websys.MonitorLicense, Not ProcedureBlock ]
{

Relationship ParRef As websys.MonitorLicense [ Cardinality = parent, Inverse = Units ];

/// This Parameter should be updated when synced from Perforce
Parameter SrcVer = "$Id: $";

/// The UserId field contains the License Login UserId. 
Property UserId As %String(MAXLEN = 220, TRUNCATE = 1);

/// The Type field contains the login type and is one of the following:
/// 	User - Regular user login
/// 	CSP - Cache Server Page login
/// 	Mixed - Regular user plus Cache Server Page login
/// 	Grace - Logged out CSP session waiting for grace period to expire.
Property Type As %String(MAXLEN = 220, TRUNCATE = 1);

/// Connects is the number of connections to this Cache instance by the user represented by UserId.
Property Connects As %Integer;

/// MaxCon is the maximum number of concurrent connections to this Cache instance by the user represented by UserId.
Property MaxCon As %Integer;

/// CSPCon is the number of CSP sessions open to this Cache instance by the user represented by UserId.
Property CSPCon As %Integer;

/// LU is the number of License Units consumed on this Cache instance by the user represented by the UserId.
Property LU As %Integer;

/// Active is the time in seconds the UserId has been logged in to this Cache instance.
Property Active As %Integer;

/// Grace is the amount of time this license unit will remain in the grace period if all connections were closed immediately.
Property Grace As %Integer;

Property SimulatedData As %Boolean [ InitialExpression = 0 ];

Storage Default
{
<Data name="MonitorLicenseUnitsClassName">
<Attribute>%%CLASSNAME</Attribute>
<Structure>node</Structure>
<Subscript>0</Subscript>
</Data>
<Data name="MonitorLicenseUnitsDefaultData">
<Value name="1">
<Value>Active</Value>
</Value>
<Value name="2">
<Value>CSPCon</Value>
</Value>
<Value name="3">
<Value>Connects</Value>
</Value>
<Value name="4">
<Value>Grace</Value>
</Value>
<Value name="5">
<Value>LU</Value>
</Value>
<Value name="6">
<Value>MaxCon</Value>
</Value>
<Value name="7">
<Value>Type</Value>
</Value>
<Value name="8">
<Value>UserId</Value>
</Value>
<Value name="10">
<Value>InactivityTimeOut</Value>
</Value>
<Value name="11">
<Value>InactivityTimeout</Value>
</Value>
<Value name="12">
<Value>SimulationMode</Value>
</Value>
<Value name="13">
<Value>SimulatedData</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Units")</DataLocation>
<DefaultData>MonitorLicenseUnitsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>{%%PARENT}("Units")</IdLocation>
<IndexLocation>^websys.MonitorLicenseUnitsI</IndexLocation>
<StreamLocation>^websys.MonitorLicenseUnitsS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

