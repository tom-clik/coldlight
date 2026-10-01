<!---

# Solr search component

Use the solr engine to provide text search. The idea was to provide a common interface for different search engines, e.g. Elastic Search. 

## Synposis

A wrapper for the various cfcollection and cfindex calls.

## Usage


1. Create index

```
solrObj.create(name="testing",path={folder for index});
```

2. Add to index
	-Create a query with columns for key,title,body and optionally two custom fields
	-Use update or refresh supplying column names

3. Search

solrObj.create(name="testing",path=ExpandPath("output"), surl="");

## Notes

It attempts to keep track of all collection info in a struct variables.collections. Actions on collections via other mechanisms will break this. Use updatelist() to update the var


## History

|------------|------|----------------------------------
| 2024-10-11 | THP  | Version 1


--->


component solr output=false {
	
	public solr function init() {

		updatelist();

		return this;

	}

	/**
	 * create a collection (if it doesn't already exist)
	 */
	public boolean function create(
		required string name, 
		required string path,
		         string lang = 'English') {

		var notexists = !structKeyExists(variables.collections, arguments.name);
		
		if ( notexists ) {
			cfcollection( action="create", 
						  engine="solr", 
						  collection=arguments.name, 
						  path=arguments.path,
						  language=arguments.lang
						 );
			variables.collections[arguments.name] = {doccount=0, lastmodified=now(), name=arguments.name,	path=arguments.path, size=0};
		}
		
		return notexists;
	}

	/**
	 * Update list of collections on server
	 */
	public void function updatelist() {

		cfcollection(action="list",name="local.qCollections");

		variables.collections = {};
		
		for (local.row in local.qCollections) {
			variables.collections[local.row.NAME] = {doccount=local.row.DOCCOUNT,	lastmodified=local.row.LASTMODIFIED,	name=local.row.NAME,	path=local.row.PATH,	size=local.row.SIZE};
		}

	}

	/**
	 * List of collections on server
	 */
	function list() {
		return variables.collections;
	}



	/**
	 * delete a collection (if it exists)
	 */
	public boolean function deleteCollection(required string name) {
		var exists = structKeyExists(variables.collections, arguments.name);
		if ( exists ) {

			cfcollection(action="delete",collection=arguments.name);

			updatelist();
		}

		return exists;
	}


	/**
	 * purge a collection
	 */
	public void function purge(required string name) {
		
		cfindex(action="purge",collection=arguments.name);

	}

	/**
	 * @hint Update a collection from a query. 
	 * 
	 * This won't remove any missing items. For small data sets, use refresh. For large ones, you have to manage the deletion process.
	 */
	public struct function update(
		required string name,
		required query qData,
		string title="title",
		string key="key",
		string body="body",
		string custom1="custom1",
		string custom2="custom2"
		) {

		return _update(argumentCollection = arguments, action="update");

	}

	/**
	 * @hint Refresh a collection from a query - will remove any missing keys
	 */
	public struct function refresh(
		required string name,
		required query qData,
		string title="title",
		string key="key",
		string body="body",
		string custom1="custom1",
		string custom2="custom2"
		) {

		return _update(argumentCollection = arguments, action="refresh");

	}

	/**
	 * See update() and refresh()
	 */
	private struct function _update(
		required string name,
		required query  qData,
		         string action="refresh",
		         string title="title",
		         string key="key",
		         string body="body",
		         string custom1="custom1",
		         string custom2="custom2"
		) {

		cfindex(
			collection="#arguments.name#",
			action=arguments.action,
			type="custom" ,
			query="arguments.qData",
			status="local.info",
			title=arguments.title,
			key=arguments.key,
			body=arguments.body,
			custom1=arguments.custom1,
			custom2=arguments.custom2
		);

		return local.info;

	}

	/**
	 * Delete items from a collection
	 */
	public struct function delete(
		required string name,
		required query qData,
		string key="key"
		) {

		cfindex(
			collection="#arguments.collection.name#",
			action="delete",
			query=arguments.qData,
			status="local.info",
			key=arguments.key
		);

		return local.info;

	}

	/**
	 * Search a collection
	 */
	public struct function search(required string name, required string qu, numeric startrow=1, numeric maxrows) {
		var search = {};

		if ( arguments.keyExists("maxrows") AND ! isValid("integer", arguments.maxrows, 1, 10000) ) {
			throw(message="Invalid value for max rows",detail="Maxrows must be 'all' or a positive integer less than 10,000");
		}

		// needs a nuemric value
		mh = arguments.maxrows ? : 1000000; 

		cfsearch(	
				collection=arguments.name,
				name="local.results",
				status="search",
				criteria=arguments.qu,
				suggestions="always",
				startrow=arguments.startrow,
				maxrows=mh
			);

		search.results = local.results;

		return search;
	}

}