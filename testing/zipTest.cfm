<cfscript>
/**
 * Testing adding files to Zip archive
 *
 * Working just using the date fof the whole archive. A little dangerous...but as best as we could do.
 * 
 * The individual dates are all a bit of a mystery. Windows picks up a "date taken" attribute for a photo and uses that as the modified date.
 *
 * The dates in the zip file are all a bit crazy.
 *
 * This works albeit with the obvious potential for not updating a file.
 * 
 */
filePath = ExpandPath("../../../dm/thedigitalmethod/");
epub = "_generated/The Digital Method.zip";
zipfile = filePath & epub;

lastUpdated = getFileInfo(zipfile).lastmodified;

cfzip(action="list",file=zipfile,name="res");

// writeDump(res);
contents = {};

for (row in res) {
	if ( Left(row.name,11) eq "OPS/images/") {
		contents[ListLast(row.name,"\/")] = 1 ;
	}
}

// writeDump(contents);

dir = directoryList(filePath & "images",true,"query");

filesToAdd = {};

for (fileinfo in dir) {
	if ( (! contents.keyExists(fileinfo.name)) || dateCompare( fileinfo.dateLastModified, lastUpdated ) > 0) {
		writeOutput("Adding file #fileinfo.name#<br>");
		filesToAdd["OPS/images/" & fileinfo.name] = filePath & "images/" & fileinfo.name;
	}
	structDelete(contents, fileinfo.name);
}


if (filesToAdd.count()) {
	cfzip( file = zipfile ) {
	  filesToAdd.each((zipFile)=>{
	    cfzipparam( source = filesToAdd[zipFile], entrypath= zipFile );
	  })
	}
}
else {
	writeOutput("No files to add<br>");
}


if (contents.count()) {
	filesToDelete = [];

	for (file in contents) {
		writeOutput("Removing file #file#<br>");
		filesToDelete.append("OPS/images/#file#");
	}

	cfzip(action="delete",file=zipfile) {
		filesToDelete.each((zipFile)=>{
			cfzipparam( entrypath = zipFile );
		});
	};
}
else {
	writeOutput("No files to remove<br>");
}

writeOutput("Done<br>");


</cfscript>