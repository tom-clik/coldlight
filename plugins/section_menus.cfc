/**
 * # Section Menus plug in
 *
 * Generate link and description for all child sections where a div with class 'section-menu' is found
 *
 * ```
 * <div class="section-menu"></div>
 * ```
 *  
 */

component implements="coldlight.plugins.pluginInterface" {
	
	public function init(markdown.flexmark markdownObj, coldsoup.coldsoup coldsoupObj) {
		
		variables.markdown = arguments.markdownObj;
		variables.coldsoup = arguments.coldsoupObj;
		
		return this;
	}

		
	public string function preProcess(required string text) localmode=true {

		return arguments.text;
		
	}

	public void function process(required struct section, required struct document) localmode=true {

		// writeDump(arguments.section);

		listings = arguments.section.node.select(".section-menu");

		if (listings.len() ) {
			if ( arguments.section.keyExists("sections") ) {
				sectionsList = arguments.section.sections;
			}
			else {
				sectionsList = arguments.document.sections;
			}

			if ( sectionsList.len() ) {
				html = "";
				for ( listing in listings ) {
					for (section_code in sectionsList) {
						sectionObj = arguments.document.data[section_code];
						// html &= "<p><strong><a href='#section_code#'>#sectionObj.meta.title#</a></strong></p>";
						html &= "<h4><a href='#section_code#'>#sectionObj.meta.title#</a></h4>";
						if ( sectionObj.meta.keyExists("description")) {
							html &= "<p>#sectionObj.meta.description#</p>";
						}
					}
				}
				listing.html(html);
			}
			else {

			}
		}
		
	}

}