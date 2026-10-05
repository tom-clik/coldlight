<cfscript>
/*
Generate missing PNGs referenced by data-image attributes in a finished HTML file.

Usage: generate_images.cfm?file=relative/path/to/book.html
The HTML filename is relative to this script. Each data-image filename is
relative to the HTML file, e.g. data-image="images/table-division.png".
Existing images are skipped. The source HTML is never changed; elements without
IDs receive temporary IDs in the rendering snapshot only.

Requires the HTML-to-PNG converter's npm dependencies. Set nodeExecutable and,
optionally, chromiumExecutable in the environment, or edit the defaults below.
Only run this local publishing sample against trusted HTML.
*/
setting requesttimeout=300;
// TODO: fix all this once we have mappings in the project like the markdown.preview
// In the meantine just update and run
// param name="url.file" default="";
// if (!len(trim(url.file))) {
//     writeOutput('<p>Supply an HTML filename relative to this script: '
//         & '<code>generate_images.cfm?file=relative/path/to/book.html</code>.</p>');
//     abort;
// }

// sourceName = replace(trim(url.file), chr(92), "/", "all");
// if (left(sourceName, 1) == "/" || find(":", sourceName))
//     throw(type="coldlight.images", message="The HTML filename must be relative to this script");

// sourceFile = getCanonicalPath(getDirectoryFromPath(getCurrentTemplatePath()) & sourceName);

sourceFile = "C:\git\dm\ClikWriter\Bridge\Bridge Odds FPP\bofpp.html";

if (!fileExists(sourceFile))
    throw(type="coldlight.images", message="HTML file not found", detail=sourceFile);
outputFolder = getDirectoryFromPath(sourceFile);
javaFile = createObject("java", "java.io.File");
outputRoot = javaFile.init(outputFolder).getCanonicalFile().toPath();
baseUrl = javaFile.init(sourceFile).toURI().toString();

jsoupJar = server.system.environment.javalib & "/jsoup-1.22.1.jar";
soup = new coldsoup.coldsoup(jsoupJar);
document = soup.Jsoup.parse(fileRead(sourceFile, "utf-8"));
batch = [];
skipped = [];
seen = {};
for (element in document.select("[data-image]")) {
    filename = replace(trim(element.attr("data-image")), chr(92), "/", "all");
    if (!len(filename) || left(filename, 1) == "/" || find(":", filename)
        || reFind("[?##]", filename) || !reFind("\.png$", filename))
        throw(type="coldlight.images", message="data-image must be a relative PNG filename", detail=filename);
    target = javaFile.init(outputFolder & filename).getCanonicalFile().toPath();
    if (!target.startsWith(outputRoot))
        throw(type="coldlight.images", message="data-image must stay within the HTML document's folder", detail=filename);
    // Normalize ./ and nested ../ before passing filenames to the converter.
    filename = replace(outputRoot.relativize(target).toString(), chr(92), "/", "all");
    if (fileExists(target.toString())) {
        skipped.append(filename);
        continue;
    }
    if (directoryExists(target.toString()))
        throw(type="coldlight.images", message="Image filename points to a directory", detail=filename);
    if (structKeyExists(seen, filename))
        throw(type="coldlight.images", message="More than one element targets the same missing image", detail=filename);
    seen[filename] = true;
    id = element.id();
    if (!len(id)) {
        id = "coldlight-image-" & createUUID();
        element.attr("id", id);
    }
    batch.append({"id":id, "filename":filename});
}

generated = [];
if (batch.len()) {
    nodePath = server.system.environment.nodeExecutable ?:
        (server.os.name contains "Windows" ? "C:/Program Files/nodejs/node.exe" : "/usr/bin/node");
    options = {scale:2, width:1200, timeout:240};
    browserPath = server.system.environment.chromiumExecutable ?: "";
    if (!len(browserPath) && fileExists("C:/Program Files/Google/Chrome/Application/chrome.exe"))
        browserPath = "C:/Program Files/Google/Chrome/Application/chrome.exe";
    if (len(browserPath)) options.executablePath = browserPath;

    publisher = new coldlight.coldlight(
        jarpath=server.system.environment.javalib & "/flexmark-all-0.64.0-lib.jar", jsoupjar=jsoupJar);
    generated = publisher.saveImages(document=document, images=batch,
        outputFolder=outputFolder, baseUrl=baseUrl, nodePath=nodePath, options=options);
}
cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({"source":sourceFile, "generated":generated, "skipped":skipped}));
</cfscript>
