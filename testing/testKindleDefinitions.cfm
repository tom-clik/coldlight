<cfscript>
markdown = new markdown.testing.flexmarkTestObj();
soup = markdown.coldsoupObj;
plugin = new coldlight.plugins.kindle(markdownObj=markdown,coldsoupObj=soup);
checks = 0;
failures = [];
function check(required boolean condition, required string message) {
    variables.checks++;
    if (!arguments.condition) variables.failures.append(arguments.message);
}
function convert(required string html) {
    var section = {node:variables.soup.parse(arguments.html)};
    variables.plugin.process(section=section,document={});
    return section.node;
}
doc = convert('<dl id="bids" class="plain" data-test="keep"><dt id="term" class="bid"><span class="suit h">♥</span></dt><dd id="first"><p>First <em>meaning</em>.</p></dd><dd id="second"><a href="##term">Second</a><span class="cards">A K</span></dd><dd>Third</dd><dt>Pass</dt><dd>Nothing to add</dd></dl>');

table = doc.getElementById("bids");
check(table.tagName() == "table" && table.hasClass("plain") && table.hasClass("definition-list"), "Table preserves list ID and classes");
check(table.attr("data-test") == "keep", "Table preserves other attributes");
rows = table.select("tr");
check(rows.size() == 4, "Each definition gets its own row");
term = doc.getElementById("term");
check(term.tagName() == "td" && term.attr("rowspan") == "3", "Term spans its three definitions");
check(term.hasClass("bid") && term.hasClass("definition-term"), "Term classes retained");
check(term.attr("valign") == "top", "Spanning term aligns at top");
check(rows.get(0).children().size() == 2 && rows.get(1).children().size() == 1 && rows.get(2).children().size() == 1, "Spanned rows do not get extra term cells");
check(rows.get(3).children().size() == 2 && !rows.get(3).child(0).hasAttr("rowspan"), "Next group resets to two cells");
check(doc.getElementById("first").select("p > em").text() == "meaning", "Definition block and inline markup retained");
check(doc.getElementById("second").select("a").attr("href") == "##term", "Links and definition IDs retained");
check(doc.select(".suit.h").text() == "♥" && doc.select(".cards").text() == "A K", "Suit and cards spans retained");
before = doc.body().html();
plugin.process(section={node:doc},document={});
check(doc.body().html() == before, "Conversion is idempotent");
doc = convert('<dl><dt id="a">Alpha</dt><dt id="b">Beta</dt><dd>One</dd><dd>Two</dd></dl>');
check(doc.select("tr").size() == 2, "Multiple terms share definition rows");
check(doc.select("td.definition-term").first().attr("rowspan") == "2", "Shared term cell has rowspan");
check(doc.select("td.definition-term > div").size() == 2, "Both terms retained separately");
check(doc.getElementById("a").text() == "Alpha" && doc.getElementById("b").text() == "Beta", "Shared terms retain IDs");
doc = convert('<dl id="outer"><dt>Outer</dt><dd><dl id="inner"><dt>Inner</dt><dd>A</dd><dd>B</dd></dl></dd></dl>');
check(doc.select("dl").isEmpty() && doc.select("table.definition-list").size() == 2, "Nested lists converted");
check(doc.getElementById("inner").parent().is("div.nobreak") && doc.getElementById("inner").parent().parent().tagName() == "td", "Nested table stays inside definition");
check(doc.getElementById("inner").select(".definition-term").first().attr("rowspan") == "2", "Nested rowspan retained");
doc = convert('<dl><div id="group" class="group"><dt>A</dt><dd>One</dd><dd>Two</dd></div><div><dt>B</dt><dd>Three</dd></div></dl>');
check(doc.select("tbody").size() == 2 && doc.select("tr").size() == 3, "Div-wrapped groups converted");
check(doc.getElementById("group").tagName() == "tbody" && doc.getElementById("group").hasClass("group"), "Group attributes preserved");
doc = convert('<dl><dd>Orphan</dd><dt>Trailing term</dt></dl>');
check(doc.select("tr").size() == 2 && doc.select("td").size() == 4, "Incomplete groups retain two-column layout");
check(doc.select("tr").get(0).child(1).text() == "Orphan" && doc.select("tr").get(1).child(0).text() == "Trailing term", "Incomplete group contents preserved");
doc = convert('<dl><dt>A</dt><dd>One</dd></dl><dl><dt>B</dt><dd>Two</dd></dl>');
check(doc.select("table.definition-list").size() == 2, "Multiple lists converted");
doc = convert('<dl><dt>A</dt><dd>One</dd><section>Unexpected content</section></dl>');
check(doc.select("dl").size() == 1 && doc.select("section").text() == "Unexpected content", "Unexpected structures left intact");
doc = convert('<table id="small"><tr><td>Small</td></tr></table><table id="large" class="plain large"><tr><td>Large</td></tr></table><dl id="large-list" class="large"><dt>Term</dt><dd>Definition</dd></dl>');
check(doc.getElementById("small").parent().is("div.nobreak"), "Ordinary table receives no-break wrapper");
check(!doc.getElementById("large").parent().is("div.nobreak"), "Large table is exempt");
check(!doc.getElementById("large-list").parent().is("div.nobreak"), "Converted large definition list is exempt");
before = doc.body().html();
plugin.process(section={node:doc},document={});
check(doc.body().html() == before, "Wrapping does not duplicate wrappers on subsequent runs");
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>