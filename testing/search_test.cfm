<!---

# search_test.cfm

Test the search component

## Synopsis

Gets data from test site and tests search component with it

## Usage


## Status

Ad hoc test script. Runs as far as it goes

## History

|------------|------|----------------------------------
| 2024-09-25 | THP  | Version 1

--->

<cfscript>

param name="url.action" default="index";
solrObj = new coldlight.search.solr()

solrObj.create(name="testing",path=ExpandPath("output"));

// Use ColdLight to load a test site
coldLightObj = new coldlight.testing.coldLightTestingObj();
filePath = ExpandPath("source/index.md");
docObj = coldLightObj.load( filePath );

// Get query for search
dataQ = coldLightObj.searchQuery(docObj);

ret = coldLightObj.search(qu="glycemic", data=dataQ);
writeDump(ret);
abort;

ret = solrObj.update(name="testing", qdata=dataQ, custom1="page", custom2="id");
writeDump(ret);
writeDump(solrObj.list());

writeDump(solrObj.search("testing", "Bananas"));

StructDelete(docObj.data,"bananas");
dataQ = coldLightObj.searchQuery(docObj);

ret = solrObj.refresh(name="testing", qdata=dataQ, custom1="page", custom2="id");
// writeDump(ret);
// writeDump(solrObj.list());
writeDump(solrObj.search("testing", "Bananas"));

writeDump(solrObj.search("testing", "diat"));

writeDump(solrObj.search("testing", "diet"));

writeDump(solrObj.search(name="testing", qu="diet", startrow=4, maxrows=3));

solrObj.deleteCollection(name="testing");

</cfscript>

