/**
 * API component for ColdLight
 *
 * @author     Tom Peer
 * @date       2020
 */
component {

	request.api = true;

	/**
	 * @hint     Return the array of search symbols for fuzzy search
	 *
	 */
	remote string function searchSymbols() returnformat="plain"  {

		cfheader(name="Content-Type",value="application/javascript");
		
		return "symbols = " & serializeJSON(application.coldLight.getHeadingData()) & ";";

	}

}