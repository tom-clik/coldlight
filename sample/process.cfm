<cfscript>
/*
Save kindle epub (all files added to zip), PDF, and static site for a publication

## Description

Using a json configuration     

## Usage

1. See the sample_soure.json and create a copy for your publication (see notes below).
2. Set the path to the Prince executable in environment.princeExecutable (or use default below)
3. Run script

Omit either "epub" or "pdf" from the

### Config file params

## Notes

The html for PDF version ends up in the root for the relative file paths. This could be better, we could adjust the paths as per the epub version.

*/

// List settings files in the folder if code not defined
if (! IsDefined("url.code") ) {
	listPubs();
	abort;
}
princeExecutable = server.system.environment.princeExecutable ? :  "C:/Program Files (x86)/Prince/engine/bin/prince.exe";


site = {};
config = getConfig(code=url.code, site=site);

coldLightObj = new coldlight.coldlight();

if (config.keyExists( "plugins") ) {
	for ( plugin in listToArray(config.plugins ) ) {
		coldLightObj.addPlugin(plugin);
	}

}

// The idea was to only load this once. I have a bug whereby the epub process is affecting
// the pdf process that I can't track down. In the meantime, see the main loop where we load it 
// on each iteration.
// args.document = coldlightObj.load(config.index);

args.filepath = getDirectoryFromPath(config.index);

for (type in ['pdf','epub']) { // ,
	if (config.keyExists(type)) {
		writeOutput("<p>Generating #type#</p>");
		// see note above
		args.document = coldlightObj.load(config.index);
		args.filename = config[type];
		checkDirectory(args.filename);
		
		args.template = config[type & "_template"];
		doc = coldLightObj[type](argumentCollection = args);
		
		if (type eq "pdf") {
			html_file = Replace(args.filename,".pdf",".html");
			fileWrite(html_file, doc);

			cfexecute(name=princeExecutable,arguments=html_file,variable="res");

			if (IsDefined("res") && res != "") {
				writeOutput("<p>Error Generating #type#</p>");
				writeDump(res);    
			}
					
		}
	}
}

if (config.keyExists("site")) {
	writeOutput("<p>Generating site</p>");
	args = {};

	args.document = coldlightObj.load(config.index);
	args.outputDir = config["site"];
	checkDirectory(args.outputDir & "/index.html");
	args.template = config["site_template"];
	args.site = site;

	site = coldLightObj.staticSite(argumentCollection = args);

}

WriteOutput("<p>Done</p>");

public void function checkDirectory(filepath) {
	local.dir = getDirectoryFromPath(arguments.filepath);
	
	if (! DirectoryExists(local.dir)) {
		try{
			DirectoryCreate(local.dir);
		} 
		catch (any e) {
			local.extendedinfo = {"tagcontext"=e.tagcontext,"dir"=local.dir};
			throw(
				extendedinfo = SerializeJSON(local.extendedinfo),
				message      = "Unabel to create directory:" & e.message, 
				detail       = e.detail  
			);
		}
		
	}
}


// List JSON files in folder
public void function listPubs() {
	
	local.fileList = directoryList(getDirectoryFromPath(getCurrentTemplatePath()) ,false, "name", "*.json");
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

/* Load and process configuration file */
struct function getConfig(required string code, struct site={}) localmode=true {

	config = {};
	fileName = ExpandPath("./" & arguments.code & ".json");
	
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
	for (field in ['index','pdf','epub','site','pdf_template','epub_template','site_template','plugins']) {
		
		if ( data.keyExists( field ) ) {
			if (field != "plugins") {
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



</cfscript>