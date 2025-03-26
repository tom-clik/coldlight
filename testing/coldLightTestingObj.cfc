component extends="coldlight.coldlight" {

	public function init() {
		super.init();
		try {
			this.loggerObj = new logger.logger(debug=1);
		} 
		catch (e) {
			writeDump(e);
		}
	}
	

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

	public void function logger(required text, type="I", category="") output=false {
		if (StructKeyExists(this,"loggerObj")) {
			this.loggerObj.log(argumentCollection = arguments);
		}
	}

}