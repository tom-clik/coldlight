component extends="baseapi" {

	request.isAjaxRequest = 1;

	remote void function index() {
		content type="text/html; charset=utf-8";
		writeOutput( "<h2>ColdLight Test API</h2>" );
		writeOutput( "<p>This is a demonstration API</p>" );
		writeOutput( "<p>There is one method, search, which takes a parameter qu and does a query of queries text match. This is a demonstration only and isn't recommended for production.</p>" );
		abort;

	}

	remote struct function search(required string qu) returnformat="json" {
		local.returnData = response();
		if ( ! IsValid( "regex", arguments.qu, "([A-Za-z].*){2,}" ) ) {
			addError(local.returnData, "Invalid data");
			local.returnData["fields"] = {"qu": "Must be at least 2 letters"};
			rep(local.returnData);
		}
		
		local.returnData["results"] = application.coldLightObj.search(qu=arguments.qu, data=application.dataQ);

		return setStatus(local.returnData);
		
	}

	

}