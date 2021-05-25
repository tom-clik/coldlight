<cfscript>

local.pubs = application.coldLight.getPubs(true);

local.temp = "";

for (request.pub in local.pubs) {
	local.pagelist = ['index'];
	ArrayAppend(local.pagelist ,application.coldLight.getPages(request.pub),true);
	
	local.outfolder = ExpandPath("_build/#request.pub#/");

	if (! DirectoryExists(local.outfolder)) {
		DirectoryCreate(local.outfolder);
	}

	request.cache = 1;
	for (request.code in local.pagelist ) {

		request.content = application.pageObj.getContent();

		request.page = application.coldLight.getPage(pub=request.pub,code=request.code,cache=true);
			request.content.title = request.page.title;

		savecontent variable="request.content.body" {
			cfinclude(template="template.cfm");
		}


		FileWrite(local.outfolder & request.code & ".html",application.pageObj.buildPage(request.content));
		local.temp  &= "<p>Written #request.code#.html</p>";
		
	}


}

local.outfolder = ExpandPath("_build/_scripts");

if (! DirectoryExists(local.outfolder)) {
	DirectoryCreate(local.outfolder);
}

FileWrite(local.outfolder & "/searchSymbols.js","symbols = " & serializeJSON(application.coldLight.getHeadingData()) & ";");

request.content = application.pageObj.getContent();
request.content.title = "Page made live";
request.content.body = local.temp;
request.buildPage = false;
writeOutput(application.pageObj.buildPage(content=request.content,debug=1));

</cfscript>
