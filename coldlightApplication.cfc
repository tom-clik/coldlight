/*

# Coldlight Base Application



## Usage

Extend this in your own app and redefine detaultContent()


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
	this.testMode = true;

	// Java Integration
	// this.javaSettings = { 
	// 	loadPaths = [ ".\lib" ], 
	// 	loadColdFusionClassPath = true, 
	// 	reloadOnChange= false 
	// };
	
	// adjust default content for your site.
	// Redifine this in your own application.cfc
	public void function defaultContent(required clikpage.page pageObj) {
		StructAppend(arguments.pageObj.content.static_css,
			{
				"content" = 1,
				"styles"= 1
			});

		// TODO: resolve fontawesome use. Have js version here?? use css only
		StructAppend(arguments.pageObj.content.static_js,
			{
				"jquery" = 1,
			 	"fuzzy"=1
			});
		
		ArrayAppend(arguments.pageObj.content.css_files,"/_assets/css/schemes/menus-schemes.css");
		ArrayAppend(arguments.pageObj.content.css_files,"/_assets/css/schemes/columns_schemes.css");
		

		arguments.pageObj.site.title = "<span class=""text-highlight"">Cold</span><span>Light</span>";			
		arguments.pageObj.site.copyright = "&copy; Tom Peer 1999-2021";

		arguments.pageObj.content.title = "Coldlight Demo";
		arguments.pageObj.content["bodyClass"] = "col-SMX mob-MSX";


	}

	public struct function defineApp() localmode="true" {
		
		version = "jsoup-1.22.1.jar";
		jsoupJarPath = server.system.environment.javalib & "\" & version
		if (! FileExists( jsoupJarPath ) ) { throw("JSOUP jar file (#jsoupJarPath#) not found");}

		version = "flexmark-all-0.64.0-lib.jar";
		flexmarkPath = server.system.environment.javalib & "\" & version
		if (! FileExists( flexmarkPath ) ) { throw("Flexmark jar file (#flexmarkPath#) not found");}

		args = {jarpath=flexmarkPath,jsoupJar=jsoupJarPath};

		// Usee prince to convert to PDF
		princeExecutable = server.system.environment.princeExecutable ? :  "C:/Program Files/Prince/engine/bin/prince.exe";
		if (fileExists( princeExecutable ) ) {
			args.pdfconverter = new coldlight.converters.princeXML(princeExecutable);
		}

		application.defaultTemplate = "";
		application.rootFolder = Replace(getDirectoryFromPath(getCurrentTemplatePath()),"sample\","sourcedocs");
		application.defaultTemplate = "/template.cfm";


		return args;

	}
	

	public boolean function onApplicationStart(){
		
		application.pageObj =  new clikpage.page();
		
		defaultContent(application.pageObj);		

		application.coldLight =  new coldlight.coldLight(argumentCollection=defineApp());		

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
		request.template = application.defaultTemplate;
		
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
				include request.template;
			}
		}


	}

	public void function onRequestEnd(){

		if (request.buildPage) {
			WriteOutput(application.pageObj.buildPage(content=request.content,debug=1));
		}
	}


	
}
