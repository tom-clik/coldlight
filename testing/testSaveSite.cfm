<cfscript>
/**
 * Save the sample site to static HTML
 *
 * Meant primarily as a testing scratchpad but you can use this in preference to the sample code
 * 
 */


param name="url.site" default="sample";

coldLightObj = new coldlight.testing.coldLighttestingObj();

for ( plugin in ['coldlight.testing.plugin_listings'] ) {
	coldLightObj.addPlugin(plugin);
}

filePath = ExpandPath("source/index.md");

site_data = {
	"title" = "ColdLight Sample Site",
	"copyright" = "&copy; Tom Peer 2008-2024",
	"assets_url" = "/clikpage/_assets",
}

template = ExpandPath("../sample/templates/site.html");
outputDir = ExpandPath("output/site");

data = coldLightObj.load( filePath );

// create a dummy page that isn't in the site. It should be removed
dummyFile = outputDir & "/dummy_file.html";
fileWrite(dummyFile, "Dummy file");

site = coldLightObj.staticSite(document=data,template=template,outputDir=outputDir,site=site_data);
writeDump(site);

if (fileExists(dummyFile)) {
	writeOutput("Remove old file failed");
}


</cfscript>