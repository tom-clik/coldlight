<cfscript>
coldLightObj = new coldlight.coldlight();
// filePath = ExpandPath("../_docs/userguide/index.md");
filePath = ExpandPath("source/index.md");
data = coldLightObj.load( filePath );
writeDump(data);

FileWrite(ExpandPath("output/test.html"), coldLightObj.html(data) );

writeDump(coldLightObj.TOChtml(data));

</cfscript>