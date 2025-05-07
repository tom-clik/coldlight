<cfscript>
// Just generate HTML for the complete doc

coldLightObj = new coldlight.coldlight();

filePath = ExpandPath("../sample/source/cv/resume.md");

doc = coldLightObj.load( filePath );

html = coldLightObj.html(document=doc,footnotes=1);

writeOutput(htmlCodeFormat(html));

</cfscript>