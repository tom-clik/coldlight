component {

	this.name = "coldlightPreview";
	
	// just for usage in this example.
	// better to put all your library components in a single location.
	this.componentpaths["libraries"]=ExpandPath("../../../.");

	function onApplicationStart() {
		application.rootDir = getDirectoryFromPath( getCurrentTemplatePath() );

		application.coldLightObj = new coldlight.coldlight();
		application.coldLightSampleObj = new coldlight.sample.preview.coldlightSample();

		application.code = "";
	
	}

	function loadDoc() localmode="true" {

		application.filename = getCanonicalPath(application.rootDir & "../../sample/" & application.code & ".json");

		site = {};
		config = application.coldLightSampleObj.getConfig(filename=application.filename, site=site);
		
		application.document  = application.coldlightObj.load( config.index );
		application.directory = getDirectoryFromPath(config.index);
		application.template  = FileRead( config.site_template );
		application.context   = application.coldLightObj.getSiteContext(document=application.document, site=site, preview=true );
		
		searchSymbolsJS = application.coldLightObj.searchSymbols(document=application.document);
		fileName = application.rootDir & "searchSymbols.js";
		fileWrite(fileName, searchSymbolsJS);
		

	}

	function onRequestStart(string targetPage) {
		

		request.rc = duplicate(url);
		structAppend(request.rc, form);


		param name="request.rc.code" type="string" default="";
		param name="request.rc.reset" type="boolean" default="false";
		param name="request.rc.reload" type="boolean" default="false";

		if (request.rc.reset) {
			onApplicationStart();
		}
		
		// Mechanism for loading different pubs. See /coldlight/sample
		if (request.rc.code == "" && application.code eq "") {
			request.rc.reload = true;
			application.code = "guide";

		}
		else if (request.rc.code != "" && request.rc.code != application.code) {
			request.rc.reload = true;
			application.code = request.rc.code;
		}

		if ( request.rc.reload OR checkCache() ) {
			loadDoc();
		}


	}

	boolean function checkCache() localmode="true" {

		if (! application.keyExists("LastModified") ) {
			application.LastModified = now();
			return true;
		}
		
		cacheUpdate = false;

		test = directoryList(application.directory,true,"query","*.md");
		
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