<cfscript>
/*
Save kindle epub (all files added to zip), PDF, and static site for a publication

## Description

Use a json configuration to set source file and output(s) for conversion.  

## Usage

1. See the sample_source.json and create a copy for your publication (see notes below).
2. Set the path to the Prince executable in environment.princeExecutable (or use default below) for PDFs
3. Run script NB it's configured to read all .json files in folder and display a list. If you use this, you may want to add a title to the json to appear in the list. Otherwise just call with url.code={stem of your json file}

### Config file fields

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
| assets_url    | This or any other field can be added here and will be added to site data for use in the Mustache templates, e.g. {{{site.assets_url}}}. Typically you would use technical variables here and the markdown for editorial variables. 

* Any of these can be omitted. The corresponding template file is then not needed. 

## Notes

The html for PDF version ends up in the root for the relative file paths. This could be better, we could adjust the paths as per the epub version.

*/

coldLightObj = new coldlight.coldlight(server.system.environment.javalib & "\jsoup-1.20.1.jar");
coldLightSampleObj = new coldlight.sample.preview.coldlightSample();

// List settings files in the folder if code not defined
if (! IsDefined("url.code") ) {
	coldLightSampleObj.listPubs(getDirectoryFromPath(getCurrentTemplatePath()));
	abort;
}

// Uses prince to convert to PDF. Omit pdf from config file if not using 
princeExecutable = server.system.environment.princeExecutable ? :  "C:/Program Files (x86)/Prince/engine/bin/prince.exe";

fileName = ExpandPath("./" & url.code & ".json");

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

for (type in ['pdf','epub']) { 
	if (config.keyExists(type)) {
		writeOutput("<p>Generating #type#</p>");
		// see note above
		args.document = coldlightObj.load(config.index);
		
		StructAppend(args.document.meta, site, false);
		
		args.filename = config[type];
		coldLightSampleObj.checkDirectory(args.filename);
		
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
	coldLightSampleObj.checkDirectory(args.outputDir);
	args.template = config["site_template"];
	args.site = site;

	site = coldLightObj.staticSite(argumentCollection = args);

}

WriteOutput("<p>Done</p>");

if (config.keyExists("preview_url")) {
	writeOutput("<p><a href='#config.preview_url#'>#config.preview_url#</a></p>");
}

</cfscript>