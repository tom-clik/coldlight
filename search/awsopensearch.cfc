<!---

# Open Search search component

## History

|------------|------|----------------------------------
| 2024-10-11 | THP  | Proof of concept

--->

component awsopensearch output=false {
	
	public awsopensearch function init(required string endpoint, required string index, required string username, required string password) {

		variables.endpoint = arguments.endpoint;          
		variables.index    = arguments.index;        
		variables.username = arguments.username;          
		variables.password = arguments.password;          

		return this;

	}
	
	/**
	 * @hint Update a document 
	 * 
	 */
	public struct function put(
		required struct document
		) {

		return apiAction(action="put", id=arguments.document.id, data=arguments.document);

	}

	/**
	 * Delete items from a collection
	 */
	public struct function delete(
		required string id
		) {

		
		return apiAction(action="delete", id=arguments.id);

	}

	/**
	 * Search a collection
	 */
	public struct function search(required string qu, numeric startrow=1, numeric maxrows)  localmode=true{

		data = {"query":"
			  {
			  ""query"": {
			    ""query_string"": {
			      ""query"": ""#arguments.qu#"",
			      ""fields"": [ ""body"", ""title ^ 3"" ]
			    }
			  }
			}"
		};

		return apiAction(action="search", data=data);
	
	}

	// TODO: finish this and then work out the commonality, only have 1 http call
	// Also check return values for success etc
	private struct function apiAction(required string action, string id, struct data) localmode=true {

		switch (arguments.action) {
			case "PUT":
				cfhttp( method="PUT", url=variables.endpoint & "/" & variables.index & "/_doc/" & arguments.id, username=variables.username, password=variables.password, result="res") {
					cfhttpparam( type="header", name="Content-type", value="application/json" );
					cfhttpparam( type="body", value=serializeJSON(arguments.data) );
				}
				break;
			case "DELETE":
				cfhttp( method="DELETE", url=variables.endpoint & "/" & variables.index & "/_doc/" & arguments.id, username=variables.username, password=variables.password, result="res") {
					
				}
				break;
			case "SEARCH":
				cfhttp( method="GET", url=variables.endpoint & "/" & variables.index & "/_search/?filter_path=took,hits.hits._id,hits.hits._score,hits.total", username=variables.username, password=variables.password, result="res") {
					cfhttpparam( type="header", name="Content-type", value="application/json" );
					cfhttpparam( type="body", value=arguments.data.query );
				}
				break;	

			default:
				res = {"notimplemented":1};
		}
		

		return res;

	}

}