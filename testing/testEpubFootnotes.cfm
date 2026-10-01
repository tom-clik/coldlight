<cfscript>
publisher = new coldlight.coldlight(
    jarpath=server.system.environment.javalib & "/flexmark-all-0.64.0-lib.jar",
    jsoupjar=server.system.environment.javalib & "/jsoup-1.22.1.jar");
soup = new coldsoup.coldsoup(server.system.environment.javalib & "/jsoup-1.22.1.jar");
fixture = getTempDirectory() & "coldlight-footnotes-" & createUUID() & "/";
directoryCreate(fixture);
template = fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "../sample/templates/epub.html");
// Test the real publication template without its publication-specific stylesheets.
template = reReplaceNoCase(template, "<link\b[^>]*>", "", "all");
fileWrite(fixture & "template.html", template, "utf-8");
source = "---" & chr(10) & "title: Footnotes test" & chr(10) & "---" & chr(10) & chr(10)
    & "First call[^first] and second call[^second]." & chr(10) & chr(10)
    & "Last body paragraph." & chr(10) & chr(10)
    & "[^first]: First note with *emphasis*." & chr(10) & chr(10)
    & "[^second]: Second note." & chr(10);
fileWrite(fixture & "index.md", source, "utf-8");
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
function readContent(required string filename) {
    var archive = createObject("java", "java.util.zip.ZipFile").init(arguments.filename);
    try {
        var stream = archive.getInputStream(archive.getEntry("OPS/content.xhtml"));
        try { return charsetEncode(stream.readAllBytes(), "utf-8"); }
        finally { stream.close(); }
    } finally { archive.close(); }
}
document = publisher.load(fixture & "index.md");
publisher.epub(document=document, filepath=fixture, template=fixture & "template.html", filename=fixture & "notes.epub");
content = readContent(fixture & "notes.epub");
dom = soup.parse(content);
check(dom.select("div.footnotes").size() == 1, "Notes section included");
check(dom.select("div.footnotes p").size() == 2, "Both footnotes included");
check(dom.select("div.footnotes em").text() == "emphasis", "Footnote markup preserved");
check(!find("First note with", dom.select("div[id=content]").text()), "Note text removed from body");
check(find("First note with", content) > find("Last body paragraph.", content), "Notes follow the body");
for (i = 1; i <= 2; i++) {
    note = dom.getElementById("footnote-" & i);
    ref = dom.getElementById("footnote-" & i & "-ref");
    check(!isNull(note), "Note target exists: " & i);
    check(!isNull(ref), "Reference exists: " & i);
    if (!isNull(note) && !isNull(ref)) {
        check(ref.attr("href") == "##footnote-" & i, "Reference links to note: " & i);
        check(note.attr("href") == "##footnote-" & i & "-ref", "Note links back: " & i);
    }
}
fileWrite(fixture & "plain.md", "---" & chr(10) & "title: No notes" & chr(10) & "---" & chr(10) & chr(10) & "Plain text.");
document = publisher.load(fixture & "plain.md");
publisher.epub(document=document, filepath=fixture, template=fixture & "template.html", filename=fixture & "plain.epub");
check(soup.parse(readContent(fixture & "plain.epub")).select("div.footnotes").isEmpty(), "No empty Notes section without footnotes");
cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>