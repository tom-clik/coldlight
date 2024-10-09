<!---

# test_staticFiles

Get static files required for coldLight

--->

<cfscript>
for (opts in [{type:"CSS",package:{"content":true}},{type:"JS",package:{"coldlight":true}}]) {
	defFile = ExpandPath("/clikpage/staticFiles/static#opts.type#.json");
	// defFile = ExpandPath("../../staticFiles/staticJS.json");
	local.tempData = FileRead(defFile);
	
	try {
		local.jsonData = deserializeJSON(local.tempData);
	}
	catch (Any e) {
		throw("Unable to parse static files definition file #arguments.defFile#");	
	}

	staticFilesObj = new clikpage.staticFiles.staticFiles(staticDef=local.jsonData);
	if (opts.type eq "CSS") {
		staticFilesObj.setCss();
	}

	writeOutput("<h2>#opts.type#</h2>");
	writeOutput("<h3>Debug</h3>");
	writeOutput("<pre>");
	writeOutput(htmlEditFormat(staticFilesObj.getLinks(opts.package,true)));
	writeOutput("</pre>");
	writeOutput("<h3>Live</h3>");
	writeOutput("<pre>");
	writeOutput(htmlEditFormat(staticFilesObj.getLinks(opts.package,false)));
	writeOutput("</pre>");
	
}


</cfscript>
