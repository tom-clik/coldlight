/*

# Coldlight Sample  App

App for creating documentation 

## Usage


## History

|-----------|------|---------------------
|2020-01-30 | THP  | Created

*/


component{
	
	// Application properties
	this.name = "coldlight";
	this.sessionManagement = true;
	this.sessionTimeout = createTimeSpan(0,0,30,0);
	this.setClientCookies = true;
	this.sessioncookie.secure = true;

	// Java Integration
	// this.javaSettings = { 
	// 	loadPaths = [ ".\lib" ], 
	// 	loadColdFusionClassPath = true, 
	// 	reloadOnChange= false 
	// };

	public boolean function onApplicationStart(){
		application.pageObj =  createObject("component", "clikpage.pageObj").init();
		StructAppend(application.pageObj.content.static_css,
			{
				"styles" = 1
			});

		// TODO: resolve fontawesome use. Have js version here?? use css only
		StructAppend(application.pageObj.content.static_js,
			{
				"jquery" = 1,
			 	"fuzzy"=1
			});
		

		application.pageObj.site.title = "<span class=""text-highlight"">Cold</span><span>Light</span>";			

		application.pageObj.content.title = "Coldlight Demo";
		application.pageObj.content.copyright = "&copy; Tom Peer 1999-2021";

		application.rootFolder = Replace(getDirectoryFromPath(getCurrentTemplatePath()),"sample\","sourcedocs");
		
		
		local.appDef = [];
		ArrayAppend(local.appDef,{"code"="coldlight","title"="Coldlight Demo",path=application.rootFolder});
		// ArrayAppend(local.appDef,{"code"="princeguide","title"="PrinceXML","path"="D:\git\dm\ClikWriter\PrinceXML"});
		
		application.coldLight =  createObject("component", "coldlight.coldLight").init(local.appDef);
		

		return true;
	}

	public void function onApplicationEnd( struct appScope ){
		
	}

	public boolean function onRequestStart( string targetPage ){

		StructAppend(request,url);
		StructAppend(request,form);

		param name="request.reload" default="0" type="boolean";
		param name="request.code" default="index";
		param name="request.pub" default="coldlight";

		// don't do this in production!
		if (request.reload) onApplicationStart();

		request.content = application.pageObj.getContent();
		
		// use pageBuilder in onRequestEnd
		request.buildPage = false;

		// dynamic or saved version
		request.cache = 0;


		return true;

	}

	public void function onRequest( string targetPage ) {
		
		include arguments.targetPage;
		
		// basic template system for html
		if (request.buildPage) {
			savecontent variable="request.content.body" {
				include "template.cfm";
			}
		}


	}

	public void function onRequestEnd(){

		if (request.buildPage) {
			WriteOutput(application.pageObj.buildPage(content=request.content,debug=1));
		}
	}

	public void function onSessionStart(){
		
	}

	public void function onSessionEnd( struct sessionScope, struct appScope ){
		
	}

	public void function onXXError(e){
		if (IsDefined("application.pageObj")) {

			request.content.body = "<h1>Error</h1>";
			request.content.body &= arguments.e.message;

			writeOutput(application.pageObj.buildPage(request.content));
		}
		else {
			writeDump(arguments.e);
		}
	}

}
