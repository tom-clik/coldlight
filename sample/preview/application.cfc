component {

	this.name = "coldlightPreview";
	
	// just for usage in this example.
	// better to put all your library components in a single location.
	this.componentpaths["libraries"]=ExpandPath("../../../.");

	function onApplicationStart() {
		application.rootDir = getDirectoryFromPath( getCurrentTemplatePath() );

		application.filename = getCanonicalPath(application.rootDir & "../../sample/guide.json");
		application.coldLightObj = new coldlight.coldlight();
		application.coldLightSampleObj = new coldlight.sample.coldlightSample();

		loadDoc();

	}

	function loadDoc() localmode="true" {

		site = {};
		config = application.coldLightSampleObj.getConfig(filename=application.filename, site=site);

		application.document = application.coldlightObj.load( config.index );
		application.template = config.site_template;
	}

	

	function onRequestStart(string targetPage) {
		
		request.rc = duplicate(url);
		structAppend(request.rc, form);

		param name="request.rc.reset" type="boolean" default="false";
		param name="request.rc.reload" type="boolean" default="false";

		if (request.rc.reset) {
			onApplicationStart();
		}
		else if ( request.rc.reload OR checkCache() ) {
			loadDoc();
		}

	}

	boolean function checkCache() localmode="true" {

		if (! application.keyExists("LastModified") ) {
			application.LastModified = now();
			return true;
		}
		
		cacheUpdate = false;

		test = directoryList(application.folder,true,"query","*.md");
		
		for (row in test) {
			if ( row.dateLastModified gt application.LastModified ) {
				application.LastModified = now();
				cacheUpdate = true;
				break;
			}
		
		}
		return cacheUpdate;

	}

	function onError(error,method) {
		
		try {
			new cferrorHandler.ErrorHandler(e=error, debug=1);
		}
		catch (any n) {
			throw(object=e);
		}
	}


}