/*
Base API methods to include in API components
*/
component {
	/** Add an error to a return struct 

	@return the api return struct
	@error error to add
	*/
	private void function addError(required struct return, required string error) {
		
		if (! StructKeyExists(arguments.return, "errors")) {
			arguments.return["errors"] = [];
		}
		
		arguments.return.statuscode = 400;
		arguments.return.statustext = 'badrequest';

		ArrayAppend(arguments.return["errors"], arguments.error);

	}

	remote string function testError() {
		
		if ( application.debug ? : false) {
			throw(message="test error",type="custom");
		}
		else {
			throw(type="badrequest");
		}
	}

	private struct function response() {
		return  {
			'statuscode': 200,
			'statustext': 'ok'
		};
	}

	private struct function setStatus(required struct returnData) {
		
		StructAppend(arguments.returnData, {"statuscode":200},false);
		
		cfheader( statuscode=arguments.returnData.statuscode );
		
		if (structKeyExists(arguments.returnData, "statustext" )) {
			cfheader( statustext="#arguments.returnData.statustext#" );
		}

		return arguments.returnData;
	}
	/* Manually return JSON representation of return after setting response codes */
	private string function rep(required struct returnData) {
		setJSON();
		setStatus(arguments.returnData);
		writeOutput( serializeJSON( arguments.returnData ) );
		abort;
	}

	private void function setJSON() {
		content type="application/json; charset=utf-8";
	}

}