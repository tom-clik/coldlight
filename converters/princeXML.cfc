/**
 * Convert HTML to PDF using PrinceXML
 * 
 */
component implements="coldlight.converters.iconverter" {

	/**
	 * Pseudo constructor
	 * @pathToExe    Path to your princeXML executable
	 */
	public function init(required string pathToExe) {
		variables.pathToExe = arguments.pathToExe;
		if (! fileExists(variables.pathToExe) ) {
			throw("Prince executable #variables.pathToExe# not found");
		}
	}

	public void function convert(required string fileIn) {

		try{
			cfexecute(name=variables.pathToExe,arguments=arguments.fileIn,variable="res");
		} 
		catch (any e) {
			local.extendedinfo = {"error"=e,"pathToExe"=variables.pathToExe,fileIn=arguments.fileIn};
			throw(
				extendedinfo = SerializeJSON(local.extendedinfo),
				message      = "Error converting pdf:" & e.message
			);
		}
		

		if (IsDefined("res") && res != "") {
			
			local.extendedinfo = {"res"=res};
			
			throw(
				extendedinfo = SerializeJSON(local.extendedinfo),
				message      = "Error Generating pdf"
			);
			
		}

	}

}