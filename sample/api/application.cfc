component {
	
	this.componentpaths["libraries"] = getCanonicalPath(getDirectoryFromPath(getCurrentTemplatePath()) & "../../..");
	
	public void function  onApplicationStart(){
		application.debug = server.system.environment.debug ? : false;
		application.errorsFolder = expandPath("../_logs");
		
		application.coldLightObj = new coldlight.testing.coldLightTestingObj();
		local.filePath = ExpandPath("../../testing/source/index.md");
		local.pub = application.coldLightObj.load( local.filePath );

		// Get query for search
		application.dataQ = application.coldLightObj.searchQuery(local.pub);

	}

	public void function onRequestStart() {
		
		param name="url.method" type="string" default="index";

		if ( application.debug ) {
			param name="url.reset" type="boolean" default=false;
			if ( url.reset ) {
				onApplicationStart();
			}
		}

	}
	
	function onError(e,method) {
		param name="request.isAjaxRequest" type="boolean" default="0";
		
		// errorhandler available at https://github.com/tom-clik/cferrorHandler
		try {
			new cferrorHandler.ErrorHandler(e=arguments.e, ajax=request.isAjaxRequest ,debug=application.debug ? : false, logger= new cferrorHandler.textLogger( application.errorsFolder ));

		}
		catch (any local.n) {
			arguments.e.extendedInfo = "Warning: error handler failed: #n.message#";
			throw(object=arguments.e);
		}
	}
}