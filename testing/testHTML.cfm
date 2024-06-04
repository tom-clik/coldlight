<cfscript>
coldLightObj = new coldlight.coldlight();

// filePath = ExpandPath("../_docs/userguide/index.md");
filePath = ExpandPath("source/index.md");

doc = coldLightObj.load( filePath );



html = coldLightObj.html(doc);
writeOutput(htmlCodeFormat(html));



</cfscript>