/*

# ColdLight plug in interface

Copy/implement this in your own plugins. See for example

testing\plugin_listings.cfc

*/
interface {

	public function init() {

	}
	
	public void function process(required node, required struct document) localmode=true {

		/**
		 * Do something to the node
		 *
		 * 
		 * node.html("<h1>Hello world</h1>");
		 */
		
	}

}