<cfscript>
// Just generate HTML for the complete doc

coldLightObj = new coldlight.testing.coldLighttestingObj();

filePath = ExpandPath("../sample/source/research/index.md");

doc = coldLightObj.load( filePath );

html = coldLightObj.html(document=doc,footnotes=1);

writeOutput(htmlCodeFormat(html));

</cfscript>