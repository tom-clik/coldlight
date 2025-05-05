<cfscript>

param name="request.rc.section" default="index";

if (! application.cache.keyExists( request.rc.section ) ) {
	// reload page
	html = application.coldlightObj.getPage();
	
	application.cache[request.rc.section] = {
		"html" = html,
		"lastmodified" = now()
	}
}




</cfscript>