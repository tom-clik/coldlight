<cfscript>
coldLightObj = new coldlight.coldlight();
filePath = ExpandPath("../_docs/userguide/index.md");
data = coldLightObj.load( filePath );
writeDump(data);

site = {
	"title" = "ColdLight",
	"copyright" = "&copy; Tom Peer 2008-2024",
	"assets_url" = "/clikpage/_assets"
}

template = ExpandPath("../sample/site/template.html");
outputDir = ExpandPath("../guide");

site = coldLightObj.saveSite(document=data,template=template,outputDir=outputDir,site=site);
writeDump(site);

</cfscript>