/*

# ColdLight plug in interface

Copy/implement this in your own plugins. See for example

testing\plugin_listings.cfc

*/
interface {

	public function init(markdown.flexmark markdownObj, coldsoup.coldsoup coldsoupObj) {
		
		 return this;
		 
	}
	
	public string function preProcess(required string text) localmode=true {

		/**
		 * Process the whole text string before processings
		 *
		 * arguments.text = Replace(arguments.text,"♠","&spade;","all");
		 * 
		 */
		return arguments.text;
		
	}
	
	public void function process(required struct section, required struct document) localmode=true {

		/**
		 * Do something to the node
		 *
		 * 
		 * arguments.node.html("<h1>Hello world</h1>");
		 */
		
	}

}