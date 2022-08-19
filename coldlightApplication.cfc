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
	public void function defaultContent(required clikpage.pageObj pageObj) {
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

	public array function defineApp() {
		
		application.rootFolder = Replace(getDirectoryFromPath(getCurrentTemplatePath()),"sample\","sourcedocs");
		application.defaultTemplate = "/template.cfm";
		local.appDef = [];
		ArrayAppend(local.appDef,{"code"="coldlight","title"="Coldlight Demo",path=application.rootFolder});

		return local.appDef;

	}
	

	public boolean function onApplicationStart(){
		
		application.pageObj =  new clikpage.pageObj();
		
		defaultContent(application.pageObj);		

		application.coldLight =  new coldlight.coldLight(defineApp());		

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


	public void function onError(e) {
		
		var niceError = ["message"=e.message,"detail"=e.detail,"code"=e.errorcode,"ExtendedInfo"=deserializeJSON(e.ExtendedInfo)];
		
		// supply original tag context in extended info
		if (IsDefined("niceError.ExtendedInfo.tagcontext")) {
			niceError["tagcontext"] =  niceError.ExtendedInfo.tagcontext;
			StructDelete(niceError.ExtendedInfo,"tagcontext");
		}
		else {
			niceError["tagcontext"] =  e.TagContext;
		}
		
	

		// set to true in any API to always get JSON errors even when testing
		param name="request.prc.isAjaxRequest" default="false" type="boolean";

		if (e.type == "ajaxError" OR request.prc.isAjaxRequest) {
			
			local.errorCode = createUUID();
			local.filename = this.errorFolder & "/" & local.errorCode & ".html";
			
			FileWrite(local.filename,local.errorDump,"utf-8");
			
			local.error = {
				"status": 500,
				"filename": local.filename,
				"message" : e.message,
				"code": local.errorCode
			}
			
			WriteOutput(serializeJSON(local.error));
		}
		else {
			if (this.testMode) {
				writeDump(niceError);
			}
			else {
				handleError(niceError);
				
				local.pageWritten = false;
				if (IsDefined("application.pageObj")) {

					request.content.body = "<h1>Error</h1>";
					request.content.body &= arguments.e.message;
					try {
						writeOutput(application.pageObj.buildPage(request.content));
						local.pageWritten = true;
					}
					catch (any e) {

					}
				}
				if (NOT local.pageWritten) {
					writeOutput("Sorry, an error has occurred");
				}

			}
			
		}
		
	}

	// VIRTUAL
	public void function handleError(struct error) {
		// DO SOMETHING WITH THE ERROR
	}

}
