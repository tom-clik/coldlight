<cfscript>
coldLightObj = new coldlight.coldlight();
filePath = ExpandPath("source/index.md");
data = coldLightObj.load( filePath );
writeDump(data);

</cfscript>