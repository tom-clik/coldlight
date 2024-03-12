<cfscript>
coldLightObj = new coldlight.coldlight();

filePath = ExpandPath("../../../dm/thedigitalmethod");
index = filePath & "/index_test.md";

outputFolder = filePath & "/_generated";
checkDirectory(outputFolder);
for (dir in ["/epub","/epub/META-INF","/epub/OPS","/epub/OPS/css","/epub/OPS/images"]) {
	checkDirectory(outputFolder & dir);
}
manifest = {};

// output html
outputFile = outputFolder & "/epub/OPS/content.xhtml";
data = coldLightObj.load( index );
html = coldLightObj.html_full(doc=data, stylesheets="css/stylesheet.css", manifest=manifest );

FileWrite( outputFile, html);

// Epub toc file
outputFile = outputFolder & "/epub/OPS/toc.xhtml";
html = coldLightObj.OpfTOC(doc=data);
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
html = coldLightObj.OPFPackage(doc=data, manifest=manifest );
FileWrite( outputFile, html);

// copy media
// MUSTDO: css file rationalisation
fileCopy(filePath & "/_styles/kindle.css", outputFolder & "/epub/OPS/css/stylesheet.css");

for (image in manifest.images) {
	filename = outputFolder & "/epub/OPS/" & image;
	if (! fileExists(filename) ) {
		fileCopy(filePath & "/" & image, outputFolder & "/epub/OPS/" & image);
	}

}

WriteOutput("Done");

function checkDirectory(dir) {
	if (! DirectoryExists(arguments.dir)) {
		DirectoryCreate(arguments.dir);
	}
}

</cfscript>