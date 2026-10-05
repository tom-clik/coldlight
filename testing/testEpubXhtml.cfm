<cfscript>
publisher = new coldlight.coldlight(
    jarpath=server.system.environment.javalib & "/flexmark-all-0.64.0-lib.jar",
    jsoupjar=server.system.environment.javalib & "/jsoup-1.22.1.jar");
soup = new coldsoup.coldsoup(server.system.environment.javalib & "/jsoup-1.22.1.jar");
fixture = getTempDirectory() & "coldlight-xhtml-" & createUUID() & "/";
directoryCreate(fixture);
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
function readEntry(required any archive, required string name) {
    var stream = arguments.archive.getInputStream(arguments.archive.getEntry(arguments.name));
    try { return charsetEncode(stream.readAllBytes(), "utf-8"); }
    finally { stream.close(); }
}
function isPublicationXml(required string text) {
    // Lucee rejects all DOCTYPEs by default, including this harmless HTML5 form.
    // Remove only that exact declaration; all document markup must still parse.
    return isXML(replaceNoCase(arguments.text, "<!DOCTYPE html>", ""));
}
try {
    fileWrite(fixture & "index.md", "---" & chr(10) & "title: XHTML test" & chr(10) & "---" & chr(10) & chr(10) & "Body text.", "utf-8");
    fileWrite(fixture & "absolute.css", "p { color:black; }", "utf-8");
    fileWrite(fixture & "relative.css", "p { margin:0; }", "utf-8");
    fileWrite(fixture & "template.html", '<!doctype html><html><head><title>{{title}}</title>'
        & '{{##author}}<meta name="author" content="{{author}}">{{/author}}'
        & '<link rel="stylesheet" href="{{cssdir}}/absolute.css"><link rel="stylesheet" href="relative.css">'
        & '</head><body><div id="front">{{{publisher_info}}}</div>{{{body}}}</body></html>', "utf-8");
    document = publisher.load(fixture & "index.md");
    document.meta.title = "A & B < C";
    document.meta.author = "Hugh Kelsey & Michael Glauert";
    document.meta["pub-id"] = 'book&"identifier';
    document.meta.cssdir = replace(fixture, chr(92), "/", "all");
    document.meta.publisher_info = '<p>Copyright &copy;<br>Publisher&nbsp;&amp; Co.</p><hr><input disabled>';
    for (id in document.sections) document.data[id].meta.title = "A & B < C";
    publisher.epub(document=document, filepath=fixture, template=fixture & "template.html", filename=fixture & "test.epub");
    archive = createObject("java", "java.util.zip.ZipFile").init(fixture & "test.epub");
    try {
        content = readEntry(archive, "OPS/content.xhtml");
        opf = readEntry(archive, "OPS/package.opf");
        toc = readEntry(archive, "OPS/toc.xhtml");
        check(isPublicationXml(content), "Final content is well-formed XML including raw metadata HTML");
        check(isXML(opf), "OPF metadata is XML escaped");
        check(isXML(toc), "Navigation titles are XML escaped");
        dom = soup.parse(content);
        check(dom.select("head link[rel=stylesheet]").size() == 2, "Both stylesheets stay in the head after Mustache rendering");
        check(dom.select("head meta[name=author]").size() == 1, "Conditional metadata stays in the head");
        check(dom.select("body link").isEmpty(), "No stylesheet links moved to the body");
        check(dom.select("html").attr("xmlns") == "http://www.w3.org/1999/xhtml", "XHTML namespace retained");
        check(find("<br />", content) > 0 && find("<hr />", content) > 0, "Void elements from metadata use XML syntax");
        check(!find("&nbsp;", content) && !find("&copy;", content), "HTML-only entities do not leak into XHTML");
        check(dom.select("title").text() == "A & B < C", "Title text survives rendering and escaping");
        if (isXML(opf)) {
            check(xmlSearch(xmlParse(opf), "//*[local-name()='creator']")[1].xmlText == document.meta.author, "Author is escaped exactly once");
        }
        check(readEntry(archive, "OPS/css/absolute.css") == fileRead(fixture & "absolute.css"), "Rendered absolute stylesheet paths resolve correctly");
        check(readEntry(archive, "OPS/css/relative.css") == fileRead(fixture & "relative.css"), "Relative stylesheet paths still resolve correctly");
    } finally { archive.close(); }
    publisher.epub(document=document, filepath=fixture, template=fixture & "template.html", filename=fixture & "debug.epub", debug=true);
    check(isPublicationXml(fileRead(fixture & "debug/OPS/content.xhtml")), "Debug EPUB output is also XHTML");
    check(fileRead(fixture & "debug.html") == fileRead(fixture & "debug/OPS/content.xhtml"), "Debug preview and EPUB content match");
} finally { directoryDelete(fixture, true); }
cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({"passed":failures.isEmpty(), "checks":checks, "failures":failures}));
</cfscript>
