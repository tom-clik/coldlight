<!---

# compress_styles

Compress standard styles ready for synching to coldlight public CDN

## Synposis

We loop over all the styles in staticCSS.json and create the minimised versions, e.g.

/styles/min/1.0/pdf/reset.css

The minimised files are ignored by git, so may not be present on your local version.

These files are then synch'd to the bucket where they can be served.

https://www.coldlight.net/_styles/min/1.0/pdf/reset.css

## Notes

1. The script won't overwrite an existing file. There maybe publications using that style.

--->

<cfscript>
defFile = ExpandPath("./staticCSS.json");
local.tempData = FileRead(defFile);

try {
	local.jsonData = deserializeJSON(local.tempData);
}
catch (Any e) {
	throw("Unable to parse static files definition file #arguments.defFile#");	
}

staticFilesObj = new clikpage.staticFiles.staticFiles(staticDef=local.jsonData);

mappings = [
	"/coldlight/_styles/" = ExpandPath("/coldlight/_styles/"),
	"//www.coldlight.net/_styles/" = ExpandPath("/coldlight/_styles/")
];

for (script in local.jsonData.scripts) {
	filename = staticFilesObj.filePath(script.debug, mappings);
	css =  staticFilesObj.minifiyCSS ( fileRead(filename) );
	outfilename = staticFilesObj.filePath(script.min, mappings);
	checkDirectory(outfilename);
	if (! fileExists(outfilename)) {
		FileWrite(filepath=outfilename,data=css)
	};
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

</cfscript>
