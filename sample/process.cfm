<cfscript>
/**
 * Save kindle epub (all files added to zip) and html for PDF (supposed to do converion but this isn't working).
 *
 * The PDF version ends up in the root for the relative file paths. This could be better, we could adjust the paths as per the epub version and still save to _generated, a bit neater.
 *
 * Status:
 *
 * Working as far as it goes.
 * 
 * We've lost the idea of parsing a document and then using the data object.
 *
 * These methods do the parsing twice. I think we need a single parse and the pass the document in as a reference.
 *
 * Also all the params could use some work. 
 * 
 */

url.code = "fatalconceipt";

param name="url.code" default="sample_source";

fileName = ExpandPath("./" & url.code & ".json");

if (! fileExists(fileName)) {
    throw("Config file #fileName# not found");
}

config = deserializeJSON(fileRead(fileName));

for (field in config) {
    config[field] = ExpandPath(config[field]);
}

args.indexFile = config.indexFile;
coldLightObj = new coldlight.coldlight();

for (type in ['epub','pdf']) {
    if (config.keyExists(type)) {
        args.filename = config[type];
        checkDirectory(args.filename);
        args.template = config[type & "_template"];
        doc = coldLightObj[type](argumentCollection = args);
        // NB pdf not working. Returns html for manual converion...
        if (type eq "pdf") {
            fileWrite(Replace(args.filename,".pdf",".html"), doc)
        }
    }

}

WriteOutput("Done");

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



</cfscript>