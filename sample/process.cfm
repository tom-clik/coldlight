<cfscript>
/*
Save kindle epub (all files added to zip), PDF, and static site for a publication

## Description

Use a json configuration to set source file and output(s) for conversion.  

## Usage

1. See the sample_source.json and create a copy for your publication (see notes below).
2. Set the path to the Prince executable in environment.princeExecutable (or use default below) for PDFs
3. Run script NB it's configured to read all .json files in folder and display a list. If you use this, you may want to add a title to the json to appear in the list. Otherwise just call with url.code={stem of your json file}

### Config file params


| Param         | Description
|---------------|-----------------------------------------------------------
| index         | REQUIRED  Markdown index page
| epub*         | File name for Epub export
| epub_template | Template to use for epub conversion
| pdf*          | File name for PDF export 
| pdf_template  | Template to use for PDF conversion
| site*         | Folder for HTML site 
| site_template | Template for HTML conversion
| plugins       | List of ColdLight plug ins to load. Currently in alpha testing
| assets_url    | Other data can be added here and will be added to site data for use in conversion. Typically you would use technical variables here and the markdown for editorial. 

* Any of these can be omitted. The corresponding template file is then not needed. 

## Notes

The html for PDF version ends up in the root for the relative file paths. This could be better, we could adjust the paths as per the epub version.

*/

// List settings files in the folder if code not defined
if (! IsDefined("url.code") ) {
	listPubs();
	abort;
}

princeExecutable = server.system.environment.princeExecutable ? :  "C:/Program Files (x86)/Prince/engine/bin/prince.exe";

fileName = ExpandPath("./" & url.code & ".json");

coldLightObj = new coldlight.coldlight();
coldLightSampleObj = new coldlight.sample.coldlightSample();

site = {};
config = coldLightSampleObj.getConfig(fileName=fileName, site=site);

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

writeDump(config);

if (config.keyExists("preview_url")) {
	writeOutput("<p><a href='#config.preview_url#'>#config.preview_url#</a></p>");
}

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




</cfscript>