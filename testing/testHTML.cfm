<cfscript>
coldLightObj = new coldlight.coldlight();

// filePath = ExpandPath("../_docs/userguide/index.md");
filePath = ExpandPath("source/index.md");

doc = coldLightObj.load( filePath );
html = coldLightObj.html(document=doc,footnotes=1);

writeOutput(htmlCodeFormat(html));

</cfscript>