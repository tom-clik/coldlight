component {
	
	/* Load and process configuration file */
	struct function getConfig(required string fileName, struct site={}) localmode=true {

		config = {};
		
		
		if (! fileExists(fileName)) {
			throw("Config file #fileName# not found");
		}

		data = deserializeJSON(fileRead(fileName));

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
				if (! ListFind( "plugins,preview_url", field ) ) {
					config[field] = ExpandPath(data[field]);
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
}