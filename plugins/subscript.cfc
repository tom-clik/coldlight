/*

Implement subscript H~2~O => H<sub>2</sub>~O

*/
component implements="coldlight.plugins.pluginInterface" {

	public function init(markdown.flexmark markdownObj, coldsoup.coldsoup coldsoupObj) {
		
		// Use Java regex objects for performance and control.
	    // Pattern explanation:
	    //   (?<!\\)    - negative lookbehind: ensure the tilde is NOT escaped (so "\~x\~" won't be replaced)
	    //   ~([^~]+)~  - capture anything between tildes (one or more chars, non-greedy against other tildes)
	    variables.pattern = createObject("java", "java.util.regex.Pattern").compile("(?<!\\\\)~([^~]+)~");
	    return this;

	}

	public string function preProcess(required string text) localmode=true {

		// Create matcher for the input string
	    matcher = variables.pattern.matcher(arguments.text);

	    // StringBuffer will be used with appendReplacement/appendTail (Java API)
	    sb = createObject("java", "java.lang.StringBuffer").init();

	    // Replace each match with <sub>captured</sub>
	    while ( matcher.find() ) {
	        // Use $1 to reference first capture group in Java replacement
	        matcher.appendReplacement(sb, "<sub>$1</sub>");
	    }

	    // Append remainder of the input
	    matcher.appendTail(sb);

	    // Return resulting string
	    return sb.toString();
		
	}
	
	public void function process(required section, required struct document) localmode=true {
		
	}

}