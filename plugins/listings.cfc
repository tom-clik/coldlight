/**
 * # Code Listings plug in
 *
 * Use external files for code listings and include with attribute `data-href`:
 *
 * ```
 * <div class="listing" data-href="listings/sample2.md">
 * ```
 * 
 * Any divs with class `listing` are processed.
 * 
 * ---
 * title: Sample code listing
 * file: sample1.cfc
 * ---
 * 
 * ```cfc
 * if ( sectionData.keyExists("parent") ) {
	 * parentObj =  arguments.document.data[sectionData.parent];
	 * hasContent = parentObj.hasContent ? : true;
	 * page["parent"] = {
		 * "title" = parentObj.meta.title,
		 * "link" = hasContent ? getLink(dataSection=parentObj,preview=arguments.preview) : parentObj.meta.title
	 * };
 * }
 * ```
 * 
 * And display as HTML. 
 * 
 */

component implements="coldlight.plugins.pluginInterface" {
	
	public function init(markdown.flexmark markdownObj, coldsoup.coldsoup coldsoupObj) {
		
		variables.markdown = arguments.markdownObj;
		variables.coldsoup = arguments.coldsoupObj;
		
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

	public void function process(required node, required struct document) localmode=true {

		listings = arguments.node.select(".listing");

		for ( listing in listings ) {
			attr = variables.coldsoup.getAttributes(listing);
			if ( attr.keyExists("data") and attr.data.keyExists("href") ) {
				code = FileRead( getCanonicalPath( document.basepath & "/" & attr.data.href ) );
				
				data = {};
				htmlBody = variables.markdown.toHtml(code, data);
				html = data.keyExists("title") ? "<p class='listingName'>#data.title#</p>" : "";
				html &= data.keyExists("file") ? "<p class='listingFile'>#data.file#</p>" : "";
				html &= htmlBody;
				
				listing.html(html).removeAttr("data-href");
			}
			
		}
		
	}

}