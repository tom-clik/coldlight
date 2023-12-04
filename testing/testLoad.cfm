<cfscript>
coldLightObj = new coldlight.coldlight();
data = coldLightObj.load( ExpandPath("../_docs/userguide/toc.md"));
writeDump(data);
FileWrite(ExpandPath("output/test.html"),data.text);
writeDump(coldLightObj.TOChtml(data));

</cfscript>