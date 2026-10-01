<cfscript>
try {  
	throw("Test message");
}
catch (any e) {
	local.extendedinfo = {"tagcontext"=e.tagcontext,info="Your info"};
	throw(
		extendedinfo = SerializeJSON(local.extendedinfo),
		message      = "Test error:" & e.message, 
		detail       = e.detail,
		errorcode    = "test.1"		
	);
}


</cfscript>
