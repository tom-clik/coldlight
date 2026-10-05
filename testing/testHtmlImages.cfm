<cfscript>
// Run on the local CFML server after installing the converter's dependencies.
setting requesttimeout=180;
markdown = new markdown.testing.flexmarkTestObj();
publisher = new coldlight.coldlight(
    jarpath=server.system.environment.javalib & "/flexmark-all-0.64.0-lib.jar",
    jsoupjar=server.system.environment.javalib & "/jsoup-1.22.1.jar");
failures = [];
checks = 0;
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
folder = getTempDirectory() & "coldlight-image-test-" & createUUID() & "/";
directoryCreate(folder);
try {
    fileWrite(folder & "layout.css", 'table {border-collapse:collapse;width:120px;height:40px} td {padding:0} body {margin:0}', "utf-8");
    html = '<!doctype html><html><head><title>Batch test</title><link rel="stylesheet" href="layout.css"></head><body>'
        & '<table id="first" data-image="old.png"><tr><td>First table</td></tr></table>'
        & '<table id="second" data-image><tr><td>Second table</td></tr></table>'
        & '<figure id="chart" data-image style="width:60px;height:30px;background:blue"></figure>'
        & '<table id="large" class="large" style="width:200px;height:1200px"><tr><td>Large table</td></tr></table>'
        & '<table id="ignored"><tr><td>Not marked</td></tr></table></body></html>';
    node = markdown.coldsoupObj.Jsoup.parse(html);
    before = node.outerHtml();
    batch = publisher.tableImageBatch(node);
    check(batch.len() == 2, "Only marked tables are collected");
    check(batch[1].filename == "images/table-first.png", "Filename derives from the ID, not the old data-image value");
    generic = publisher.imageBatch(node);
    check(generic.len() == 3 && generic[3].filename == "images/image-chart.png", "Generic helper includes non-table elements");
    selected = publisher.imageBatch(node, "table.large, figure", "exports", "capture");
    check(selected.len() == 2 && selected[2].filename == "exports/capture-large.png", "Custom selector, folder and prefix work");
    baseUrl = createObject("java", "java.io.File").init(folder).toURI().toString();
    nodePath = server.os.name contains "Windows" ? "C:/Program Files/nodejs/node.exe" : "/usr/bin/node";
    options = {scale:2, width:600, height:400};
    if (fileExists("C:/Program Files/Google/Chrome/Application/chrome.exe"))
        options.executablePath = "C:/Program Files/Google/Chrome/Application/chrome.exe";
    result = publisher.saveImages(node, batch, folder, baseUrl, nodePath, options);
    check(result.len() == 2, "Both images are returned");
    for (item in result) {
        check(fileExists(item.path), "PNG exists: " & item.id);
        check(item.width == 240 && item.height == 80, "CSS resource and scale apply to " & item.id);
        image = createObject("java", "javax.imageio.ImageIO").read(createObject("java", "java.io.File").init(item.path));
        check(image.getWidth() == 240 && image.getHeight() == 80, "Valid PNG dimensions for " & item.id);
    }
    check(node.outerHtml() == before, "Original Jsoup document is unchanged");
    check(publisher.saveImages(node, [], folder, baseUrl, "not-installed").isEmpty(), "Empty batch starts no process");
    options.scale = 1;
    result = publisher.saveImages(html, [batch[1]], folder, baseUrl, nodePath, options);
    check(result[1].width == 120, "HTML strings are accepted and existing PNGs can be regenerated");
    result = publisher.saveImages(node, selected, folder, baseUrl, nodePath, options);
    check(result[1].width == 60 && result[1].height == 30, "Generic element capture works without a Bridge plugin");
    check(result[2].width == 200 && result[2].height == 1200, "Large tables are captured beyond the viewport height");
    check(node.outerHtml() == before, "Generic capture also preserves the document");
    try {
        publisher.saveImages(node, [{id:"missing",filename:"images/missing.png"}], folder, baseUrl, nodePath, options);
        check(false, "Missing ID must throw");
    } catch (coldlight.htmlToPng e) {
        check(find("exactly one", e.message) > 0, "Renderer errors reach Lucee");
    }
} finally {
    directoryDelete(folder, true);
}
cfcontent(type="application/json; charset=utf-8", reset=true);
writeOutput(serializeJSON({"passed":failures.isEmpty(), "checks":checks, "failures":failures}));
</cfscript>
