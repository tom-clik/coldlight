<cfscript>
coldLightObj = new coldlight.testing.coldLightTestingObj();
filePath = ExpandPath("source/index.md");
docObj = coldLightObj.load( filePath );
menu = coldLightObj.sectionMenu(data=docObj.data,sections=docObj.sections,preview=0);
// writeOutput(menu);
// writeDump(docObj);

TOC = coldLightObj.TOC(document=docObj,toclevel=2);

writeOutput(TOC);

</cfscript>