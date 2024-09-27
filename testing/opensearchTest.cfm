<cfscript>

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
		"id":row.key,
		"title" :row.title,
		"body": row.body,
		"parent": row.parent
	};

	data = awsopensearchObj.put(document=myTest);

}

// data = awsopensearchObj.delete(id=myTest.id);
data = awsopensearchObj.search(qu="glycemic index");
writeDump( deserializeJSON( data.filecontent ) );

</cfscript>