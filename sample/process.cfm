<cfscript>
/*
Save kindle epub (all files added to zip) and html for PDF (supposed to do converion but this isn't working).


## Usage

See the sample_soure.json and create a copy for your publication.

## Notes

The html for PDF version ends up in the root for the relative file paths. This could be better, we could adjust the paths as per the epub version.



*/

// param name="url.code" default="sample_source";
param name="url.code" default="thedigitalmethod";

princeExecutable = server.system.environment.princeExecutable ? :  "C:/Program Files (x86)/Prince/engine/bin/prince.exe";

fileName = ExpandPath("./" & url.code & ".json");

if (! fileExists(fileName)) {
    throw("Config file #fileName# not found");
}

config = deserializeJSON(fileRead(fileName));

for (field in config) {
    config[field] = ExpandPath(config[field]);
}

coldLightObj = new coldlight.coldlight();

// The idea was to only load this once. I have a bug whereby the epub process is affecting
// the pdf process that I can't track down. In the meantime, see the main loop where we load it 
// on each iteration.
// args.document = coldlightObj.load(config.indexFile);

args.filepath = getDirectoryFromPath(config.indexFile);

for (type in ['epub','pdf']) {
    if (config.keyExists(type)) {
        // see note above
        args.document = coldlightObj.load(config.indexFile);
        args.filename = config[type];
        checkDirectory(args.filename);
        args.template = config[type & "_template"];
        doc = coldLightObj[type](argumentCollection = args);
        
        
        if (type eq "pdf") {
            html_file = Replace(args.filename,".pdf",".html");
            fileWrite(html_file, doc);

            cfexecute(name=princeExecutable,arguments=html_file,variable="res");
            if (IsDefined("res")) {
                writeDump(res);    
            }
                    
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