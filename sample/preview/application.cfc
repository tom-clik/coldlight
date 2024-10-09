component {

	this.name = "coldlightPreview";
	
	// just for usage in this example.
	// better to put all your library components in a single location.
	// And use dot paths for intialisation e.g. new cferrorHandler.errorHandler
	this.componentpaths["libraries"]=ExpandPath("../../../.");

	function onApplicationStart() {
		rootDir = getDirectoryFromPath( getCurrentTemplatePath() );

		application.folder = getCanonicalPath(rootDir & "../../_docs/userguide");
		application.coldLightObj = new coldlight.coldlight();
		application.document = application.coldlightObj.load( application.folder & "/index.md" );
		loadDoc();
	}

	function loadDoc() {
		application.document = application.coldlightObj.load( application.folder & "/index.md" );
	}

	

	function onRequestStart(string targetPage) {
		
		request.rc = duplicate(url);
		structAppend(request.rc, form);

		param name="request.rc.reset" type="boolean" default="false";
		param name="request.rc.reload" type="boolean" default="false";
		if (request.rc.reset) {
			onApplicationStart();
		}
		else if (request.rc.reload) {
			loadDoc();
		}


	}


}