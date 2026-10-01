/**
 * PDF converter interface
 */
interface name="iconverter" {

	public void function convert(required string fileIn) {

		var fileOut = replace(arguments.filename,".html", ".pdf");

	}

}