/**
 * Convert HTML to PDF using cfdocument
 * 
 */
component implements="coldlight.converters.iconverter" {

	/**
	 * Pseudo constructor
	 */
	public function init() {
		return this;
	}

	public void function convert(required string fileIn) localmode=true {

		html = FileRead(arguments.fileIn);

		cfdocument(
		    format = "PDF",
		    filename = Replace(arguments.fileIn, ".html",".pdf"),
		    overwrite = true
		) {
		    writeOutput(html);
		}

	}

}