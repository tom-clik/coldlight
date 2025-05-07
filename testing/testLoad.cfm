<cfscript>
/**
 * Dump a document object to view structure
 */

coldLightObj = new coldlight.testing.coldLightTestingObj();
filePath = ExpandPath("source/index.md");
docObj = coldLightObj.load( filePath );

writeDump(docObj);


</cfscript>