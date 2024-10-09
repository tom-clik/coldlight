<cfscript>

checkCache();

param name="request.rc.section" default="index";

if (! application.cache.keyExists( request.rc.section ) ) {
	// reload page
	html = application.coldlight.getPage();
	
	application.cache[request.rc.section] = {
		"html" = html,
		"lastmodified" = now()
	}
}

function checkCache() localmode="true" {

	param name="application.cache" default={};
	
	test = directoryList(application.folder,true,"query","*.md");
	
	for (row in test) {
		code = ListFirst(ListLast(row.name, "\/"), ".");

		if ( application.cache.keyExists( code ) ) {

			if ( row.dateLastModified gt application.cache[code].LastModified ) {

				StructDelete(application.cache, code);

			}

		}
	
	}

}


</cfscript>