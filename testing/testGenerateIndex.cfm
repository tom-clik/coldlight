<cfscript>


coldLightObj = new coldlight.coldlight();


data = coldLightObj.generateIndex( "C:\git\svelte\kit\documentation\docs" );

writeDump(data);



</cfscript>