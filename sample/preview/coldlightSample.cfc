/**
 * Utility functions for the sample/preview app
 */
component {

	/* Load and process configuration file */
	struct function getConfig(required string fileName, struct site={}) localmode=true {

		config = {};
		
		
		if (! fileExists(fileName)) {
			throw("Config file #fileName# not found");
		}

		data = deserializeJSON(fileRead(fileName));

		dir = getDirectoryFromPath(arguments.filename);

		// check index file defined
		if ( ! data.keyExists( "index" ) ) {
			throw("No index field defined");
		}
		// check templates defined for all outputs
		for (field in ['pdf','epub','site'] ) {
			if ( data.keyExists( field ) && ! data.keyExists( field & "_template" ) ) {
				throw("No template defined for #field#");
			}
		}

		// Expand file paths and add to config
		for (field in ['index','pdf','epub','site','pdf_template','epub_template','site_template','plugins','preview_url']) {
			
			if ( data.keyExists( field ) ) {
				if ( ( ! ListFind( "plugins,preview_url", field ) ) && Left(data[field],1) == "." ) {
					config[field] = getCanonicalPath(dir & data[field]);
				}
				else {
					config[field] = data[field];
				}
				StructDelete(data,field);
				
			   
			}
			
		}
		// Append any remaining data fields to site
		StructAppend(arguments.site, data);

		return config;

	}


	public void function checkDirectory(filepath) {
		local.dir = getDirectoryFromPath(arguments.filepath);
		
		if (! DirectoryExists(local.dir)) {
			try{
				DirectoryCreate(local.dir);
			} 
			catch (any e) {
				local.extendedinfo = {"error"=e,"dir"=local.dir};
				throw(
					extendedinfo = SerializeJSON(local.extendedinfo),
					message      = "Unable to create directory:" & e.message, 
					detail       = e.detail  
				);
			}
			
		}
	}


	// List JSON files in folder
	// getDirectoryFromPath(getCurrentTemplatePath())
	public void function listPubs(required string directory) {
		
		local.fileList = directoryList(arguments.directory ,false, "name", "*.json");
		local.html = "";
		
		if (arrayLen(local.fileList) ) {
			for (local.name in local.fileList) {
				local.code = listFirst(local.name,".");
				local.html &= "<p><a href='process.cfm?code=#local.code#'>#local.code#</a></p>";
			}
			writeOutput("<h1>Select Publication</h1>");
			writeOutput(local.html);
		}
		else {
			 writeOutput("<h1>No Publications Defined</h1>");
		}

	}
}