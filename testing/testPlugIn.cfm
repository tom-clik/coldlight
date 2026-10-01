<cfscript>
/**
 * Demonstrate use of plug ins
 *
 * MUSTDO: resolve issue around relative paths for includes
 * 
 */

coldLightObj = new coldlight.testing.coldLighttestingObj();

for ( plugin in ['coldlight.plugins.listings'] ) {
	coldLightObj.addPlugin(plugin);
}

filePath = ExpandPath("source/fruit/index.md");

doc = coldLightObj.load( filePath );

html = coldLightObj.html(document=doc,footnotes=1);

writeOutput(htmlCodeFormat(html));

</cfscript>