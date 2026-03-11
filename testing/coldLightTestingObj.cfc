component extends="coldlight.coldlight" {

	public function init() localmode=true {
		version = "jsoup-1.22.1.jar";
		jsoupJarPath = server.system.environment.javalib & "\" & version
		if (! FileExists( jsoupJarPath ) ) { throw("JSOUP jar file (#jsoupJarPath#) not found");}

		version = "flexmark-all-0.64.0-lib.jar";
		flexmarkPath = server.system.environment.javalib & "\" & version
		if (! FileExists( flexmarkPath ) ) { throw("Flexmark jar file (#flexmarkPath#) not found");}

		super.init(jarpath=flexmarkPath,jsoupJar=jsoupJarPath);
		
		try {
			this.loggerObj = new logger.logger(debug=1);
		} 
		catch (e) {
			// logger not in use - just ignore
		}

		return this;

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

	public void function updatePlugins(required struct config) {

		existingPlugins = Duplicate(variables.plugins);

		if (arguments.config.keyExists( "plugins") ) {
			if (! isArray(arguments.config.plugins)){ arguments.config.plugins = listToArray(arguments.config.plugins ) }
			for ( plugin in arguments.config.plugins ) {
				if (! existingPlugins.keyExists(plugin)) {
					addPlugin(plugin);
				}
				existingPlugins.delete(plugin);
			}
			// remove unused
			for (plugin in existingPlugins) {
				existingPlugins.delete(plugin);
			}
		}
		else {
			structClear(variables.plugins)
		}

	}

}