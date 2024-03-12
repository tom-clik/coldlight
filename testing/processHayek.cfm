<cfscript>
coldLightObj = new coldlight.coldlight();

filePath = ExpandPath("../../../dm/ClikWriter/hayekfa/fatalconceipt/index.md");
outputFile = ExpandPath("../../../dm/ClikWriter/hayekfa/fatalconceipt/_generated/fatalconceipt.html");
// templateFile = ExpandPath("../../../dm/ClikWriter/hayekfa/fatalconceipt/_template/fatalconceipt_print.tmpl");

data = coldLightObj.load( filePath );
// html = coldLightObj.html(doc=data, template=fileRead( templateFile ) );
html = coldLightObj.html_full(doc=data);

writeDump(data);

FileWrite( outputFile, html);

WriteOutput("Done");

</cfscript>