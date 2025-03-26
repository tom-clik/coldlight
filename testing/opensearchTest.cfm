<cfscript>
/*
A sample page demonstarting use of AWS OpenSearch

# Synopsis

1. Read credentials file (see below) 
2. Add data from the test publication to the index
3. Do a test search

## Credentials file

Create a file credentials.json with initialisation data for awsopensearch.cfc

*/
try {
	data = deserializeJSON(FileRead(expandPath("credentials.json")));
}
catch (any e) {
	throw("Unable to read credentials file for open search test");
}

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

	cfstopwatch( variable="dur" ) {
		data = awsopensearchObj.put(document=myTest);
	}

	coldLightObj.logger("Added #row.id#  in #dur#ms");

}

// sample delete call
// data = awsopensearchObj.delete(id=myTest.id);

data = awsopensearchObj.search(qu="glycemic index");
writeDump( deserializeJSON( data.filecontent ) );

coldLightObj.loggerObj.viewLog();

</cfscript>