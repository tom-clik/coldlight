<cfscript>
publisher = new coldlight.coldlight(
    jarpath=server.system.environment.javalib & "/flexmark-all-0.64.0-lib.jar",
    jsoupjar=server.system.environment.javalib & "/jsoup-1.22.1.jar");
fixture = getDirectoryFromPath(getCurrentTemplatePath()) & "output/epub-batch/";
if (!directoryExists(fixture & "images")) directoryCreate(fixture & "images",true);
pixel = binaryDecode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=","base64");
fileWrite(fixture & "images/pixel.png",pixel);
fileWrite(fixture & "style.css","/* café */ p { color: black; }","utf-8");
fileWrite(fixture & "template.html",'<html><head><link rel="stylesheet" href="style.css"></head><body>{{{body}}}</body></html>',"utf-8");
fileWrite(fixture & "index.md",'---' & chr(10) & 'title: EPUB batching test' & chr(10) & 'cover: images/pixel.png' & chr(10) & '---' & chr(10) & chr(10) & '![First](images/pixel.png)' & chr(10) & chr(10) & '![Repeated](images/pixel.png)',"utf-8");
failures = [];
checks = 0;
function check(required boolean condition,required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
document = publisher.load(fixture & "index.md");
publisher.epub(document=document,filepath=fixture,template=fixture & "template.html",filename=fixture & "images.epub");
archive = createObject("java","java.util.zip.ZipFile").init(fixture & "images.epub");
try {
    check(archive.size()==7,"Expected five publication entries, one CSS and one unique image");
    stream = archive.getInputStream(archive.getEntry("OPS/images/pixel.png"));
    try { check(binaryEncode(stream.readAllBytes(),"base64")==binaryEncode(pixel,"base64"),"Image bytes preserved"); }
    finally { stream.close(); }
    stream = archive.getInputStream(archive.getEntry("OPS/package.opf"));
    try { opf = charsetEncode(stream.readAllBytes(),"utf-8"); } finally { stream.close(); }
    check(arrayLen(reMatch('href="images/pixel.png"',opf))==1,"Repeated and cover images deduplicated in manifest");
    stream = archive.getInputStream(archive.getEntry("OPS/content.xhtml"));
    try { content = charsetEncode(stream.readAllBytes(),"utf-8"); } finally { stream.close(); }
    check(arrayLen(reMatch('src="images/pixel.png"',content))==2,"Both image uses remain in the document");
    check(find('href="css/style.css"',content)>0,"Stylesheet path preserved");
    stream = archive.getInputStream(archive.getEntry("OPS/css/style.css"));
    try { check(charsetEncode(stream.readAllBytes(),"utf-8")==fileRead(fixture & "style.css","utf-8"),"CSS text preserved"); }
    finally { stream.close(); }
} finally { archive.close(); }
fileWrite(fixture & "text.md","---" & chr(10) & "title: Text only" & chr(10) & "---" & chr(10) & chr(10) & "A paragraph.","utf-8");
document = publisher.load(fixture & "text.md");
publisher.epub(document=document,filepath=fixture,template=fixture & "template.html",filename=fixture & "text.epub");
archive = createObject("java","java.util.zip.ZipFile").init(fixture & "text.epub");
try { check(archive.size()==6,"EPUB without images still builds"); } finally { archive.close(); }
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>
