component extends="coldlight.coldlight" {
	public function getLink() {
		return super.getLink(argumentCollection = arguments);
	}
	public function sectionMenu() {
		return super.sectionMenu(argumentCollection = arguments);
	}
	public function sectionLink() {
		return super.sectionLink(argumentCollection = arguments);
	}
	public function getPage() {
		return super.sectionLink(argumentCollection = arguments);
	}

	public array function search(required string qu, required query data) {
		
		local.sql = "SELECT *, 100 as score FROM arguments.data
					 WHERE  body LIKE :qu ";

		local.params = {
			"qu":{value="%" & arguments.qu & "%"}
		};
		
		return  queryExecute( local.sql, local.params, {dbtype="query", returntype="array" } );

	}

}