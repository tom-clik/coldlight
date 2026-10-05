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
function classes(required any doc, required string id, required boolean first, required boolean last) {
    var cell = arguments.doc.getElementById(arguments.id);
    check(cell.hasClass("first-column") == arguments.first, arguments.id & ": first column");
    check(cell.hasClass("last-column") == arguments.last, arguments.id & ": last column");
}
doc = convert('<table class="large"><thead><tr id="head" class="existing"><th id="h1">A</th><th>B</th><th id="h3">C</th></tr></thead><tbody><tr id="body"><td id="left" rowspan="2">Left</td><td id="middle">Middle</td><td id="right" rowspan="2">Right</td></tr><tr id="continued"><td id="only">Middle only</td></tr></tbody><tfoot><tr id="foot"><td id="all" colspan="3">Footer</td></tr></tfoot></table>');
check(doc.getElementById("head").hasClass("first-row") && doc.getElementById("head").hasClass("existing"), "First row marked and existing class preserved");
check(doc.getElementById("foot").hasClass("last-row"), "Last row marked across row groups");
check(!doc.getElementById("body").hasClass("first-row") && !doc.getElementById("continued").hasClass("last-row"), "Body boundaries not mistaken for table boundaries");
classes(doc,"h1",true,false);
classes(doc,"h3",false,true);
classes(doc,"left",true,false);
classes(doc,"middle",false,false);
classes(doc,"right",false,true);
classes(doc,"only",false,false);
classes(doc,"all",true,true);
check(doc.select("div.nobreak").isEmpty(), "Large tables marked without being wrapped");
before = doc.body().html();
plugin.process(section={node:doc},document={});
check(doc.body().html() == before, "Repeated processing is stable");
doc = convert('<table><tr id="single"><td id="one"><span class="cards">A K</span></td></tr></table>');
check(doc.getElementById("single").hasClass("first-row") && doc.getElementById("single").hasClass("last-row"), "Single row has both classes");
classes(doc,"one",true,true);
check(doc.select(".cards").text() == "A K", "Cell markup retained");
doc = convert('<dl><dt id="term">Term</dt><dd id="first">One</dd><dd id="second">Two</dd></dl>');
classes(doc,"term",true,false);
classes(doc,"first",false,true);
classes(doc,"second",false,true);
check(doc.select("tr.first-row").size() == 1 && doc.select("tr.last-row").size() == 1, "Generated tables processed");
doc = convert('<table><tbody><tr><td id="zero" rowspan="0">A</td><td>B</td></tr><tr><td id="under-zero">C</td></tr></tbody><tbody><tr><td id="new-group">D</td><td>E</td></tr></tbody></table>');
classes(doc,"zero",true,false);
classes(doc,"under-zero",false,true);
classes(doc,"new-group",true,false);
doc = convert('<table><tr id="outer-first"><td id="outer-left">A<table><tr id="inner-row"><td id="inner-cell">Nested</td></tr></table></td><td id="outer-right">B</td></tr><tr id="outer-last"><td>C</td><td>D</td></tr></table>');
check(doc.getElementById("inner-row").hasClass("first-row") && doc.getElementById("inner-row").hasClass("last-row"), "Nested table has independent row boundaries");
check(!doc.getElementById("outer-first").hasClass("last-row") && doc.getElementById("outer-last").hasClass("last-row"), "Nested rows excluded from outer boundaries");
classes(doc,"inner-cell",true,true);
classes(doc,"outer-left",true,false);
classes(doc,"outer-right",false,true);
doc = convert('<table></table><table><tr><td id="invalid" colspan="bogus" rowspan="-1">A</td><td id="valid">B</td></tr></table>');
classes(doc,"invalid",true,false);
classes(doc,"valid",false,true);
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({passed:failures.isEmpty(),checks:checks,failures:failures}));
</cfscript>