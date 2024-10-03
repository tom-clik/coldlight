<cfscript>
/*
A sample page demonstarting use of AWS OpenSearch

# Synopsis

1. Read credentials file (see below) 
2. Add data from the test ublication to the index
3. Do a test search

*/
data = deserializeJSON(FileRead(expandPath("credentials.json")));

awsopensearchObj = new coldlight.search.awsopensearch(argumentCollection = data);

// Use ColdLight to load a test site
coldLightObj = new coldlight.testing.coldLightTestingObj();
filePath = ExpandPath("source/index.md");
docObj = coldLightObj.load( filePath );

// Get query for search
dataQ = coldLightObj.searchQuery(docObj);

for (row in dataQ) {

	myTest = {
		"file":row.key,
		"title" :row.title,
		"body": row.body,
		"page": row.page,
		"id": row.id
	};

	data = awsopensearchObj.put(document=myTest);

}

// data = awsopensearchObj.delete(id=myTest.id);
data = awsopensearchObj.search(qu="glycemic index");
writeDump( deserializeJSON( data.filecontent ) );

</cfscript>