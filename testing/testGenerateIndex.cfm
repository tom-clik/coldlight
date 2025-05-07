<cfscript>
/**
 * Demonstrate use of the generateIndex method on a typical directory based structure.
 *
 * Creates an index in each of the sub folders and then a main index pointing to the sub indexes.
 *
 * The svelte documentation is a good one to try this on.
 */

coldLightObj = new coldlight.coldlight();

data = coldLightObj.generateIndex( "C:\git\svelte\kit\documentation\docs" );

if ( data.count() ) {
	writeDump(data);
}

writeOutput("Finished");

</cfscript>