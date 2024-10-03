<cfscript>

param name="url.site" default="sample";

coldLightObj = new coldlight.coldlight();

filePath = ExpandPath("source/index.md");
site = {
	"title" = "ColdLight Sample Site",
	"copyright" = "&copy; Tom Peer 2008-2024",
	"assets_url" = "/clikpage/_assets",
}

template = ExpandPath("../sample/site/template.html");
outputDir = ExpandPath("output/site");

data = coldLightObj.load( filePath );


dummyFile = outputDir & "/dummy_file.html";
fileWrite(dummyFile, "Dummy file");

fileCopy(ExpandPath("../sample/site/styles.css"), outputDir);

site = coldLightObj.staticSite(document=data,template=template,outputDir=outputDir,site=site);
writeDump(site);

if (fileExists(dummyFile)) {
	writeOutput("Remove old file failed");
}


</cfscript>