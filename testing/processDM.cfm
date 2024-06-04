<cfscript>
/**
 * Save kindle epup (all files added to zip) and html for PDF
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
 * 
 * 
 */

filePath = ExpandPath("../../../dm/");



args.indexFile = filePath & "thedigitalmethod/index.md";
args.template = filePath & "thedigitalmethod/_template/thedm_print.html";
args.etemplate = filePath & "thedigitalmethod/_template/thedm_kindle.html";
args.epub = filePath & "thedigitalmethod/_generated/thedigitalmethod.epub";
args.filename = filePath & "thedigitalmethod/thedigitalmethod.pdf";

// args.indexFile = filePath & "clikwriter/hayekfa/fatalconceipt/index.md";
// args.template = filePath & "clikwriter/hayekfa/fatalconceipt/_template/fatalconceipt_print.tmpl";
// args.pdf = filePath & "clikwriter/hayekfa/fatalconceipt/fatalconceipt_print.html";
// args.etemplate = filePath & "clikwriter/hayekfa/fatalconceipt/_template/kindle.tmpl";
// args.epub = filePath & "clikwriter/hayekfa/fatalconceipt/_generated/thefatalconceipt.epub";

checkDirectory(filePath);
checkDirectory(filePath & "_generated");



coldLightObj = new coldlight.coldlight();
html = coldLightObj.pdf(argumentCollection = args);
fileWrite(Replace(args.filename ,".pdf",".html"), html);


// args.template = args.etemplate;
// doc = coldLightObj.epub(argumentCollection = args);

WriteOutput("Done");

public void function checkDirectory(dir) {
	if (! DirectoryExists(arguments.dir)) {
		DirectoryCreate(arguments.dir);
	}
}



</cfscript>