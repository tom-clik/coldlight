<cfscript>
coldLightObj = new coldlight.coldlight();
// filePath = ExpandPath("../_docs/userguide/_userguide.md");
filePath = ExpandPath("source/index.md");
data = coldLightObj.load( filePath );

site = {
	"title" = "ColdLight",
	"copyright" = "&copy; Tom Peer 2008-2024",
	"assets_url" = "/clikpage/_assets",
	"home" = "index.html"
}

template = ExpandPath("../sample/site/template.html");
// outputDir = ExpandPath("../guide");
outputDir = ExpandPath("output");

fileCopy(ExpandPath("../sample/site/styles.css"), outputDir);

site = coldLightObj.saveSite(document=data,template=template,outputDir=outputDir,site=site);
writeDump(site);

</cfscript>