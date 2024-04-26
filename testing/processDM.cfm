<cfscript>
/**
 * Create epub from Markdown "index"
 *
 * Status:
 *
 * Working but needs to be formalised. Parameterise inputs and put the body into
 * ColdLight as methods.
 *
 * TODO: cover images. Do these with a meta tag (yaml). 
 */

filePath = ExpandPath("../../../dm/thedigitalmethod/");

indexFile = filePath & "index.md";
mytemplate = filePath & "_template/thedm_kindle.html";
outputFolder = filePath & "_generated";

mustache = new mustache.Mustache();
coldLightObj = new coldlight.coldlight();

doc = coldLightObj.load( indexFile );

doc["template"] = FileRead(mytemplate,"utf-8");

doc["manifest"] = {"styles"={}};
doc["template"] = coldLightObj.processStylesheets(doc["template"],doc.manifest.styles);

doc.meta.body = coldLightObj.html(doc);


checkDirectory(outputFolder);
for (dir in ["/epub","/epub/META-INF","/epub/OPS","/epub/OPS/css","/epub/OPS/images"]) {
	checkDirectory(outputFolder & dir);
}

// Epub toc file
outputFile = outputFolder & "/epub/OPS/toc.xhtml";
html = coldLightObj.OpfTOC(contents=doc.contents);
FileWrite( outputFile, html);

// container file
outputFile = outputFolder & "/epub/mimetype";
	if (! fileExists( outputFile ) ) {
	html = coldLightObj.OPFMimeType();
	FileWrite( outputFile, html);
}

// container file
outputFile = outputFolder & "/epub/META-INF/container.xml";
	if (! fileExists( outputFile ) ) {
	html = coldLightObj.OPFContainer();
	FileWrite( outputFile, html);
}

// manifest file
outputFile = outputFolder & "/epub/OPS/package.opf";
html = coldLightObj.OPFPackage(doc=doc);
FileWrite( outputFile, html);

for (item in doc.manifest["images"]) {
	filename = outputFolder & "/epub/OPS/" & item;
	if (! fileExists(filename) ) {
		source = getCanonicalPath( filePath & item );
		fileCopy(source, filename);
	}
	else {
		writeOutput("File #filename# already exists<br>");
	}
}

for (item in doc.manifest.styles) {
	filename = getCanonicalPath(outputFolder & "/epub/OPS/css/" & item);
	if (! fileExists(filename) ) {
		source = getCanonicalPath( filePath & doc.manifest.styles[item] );
		fileCopy(source, filename);
	}
	else {
		writeOutput("File #filename# already exists<br>");
	}
}


// output html
html = mustache.render(template=doc.template, context=doc.meta);
outputFile = outputFolder & "/epub/OPS/content.xhtml";

FileWrite( outputFile, html);


WriteOutput("Done");

function checkDirectory(dir) {
	if (! DirectoryExists(arguments.dir)) {
		DirectoryCreate(arguments.dir);
	}
}

</cfscript>