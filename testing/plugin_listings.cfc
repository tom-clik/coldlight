component implements="coldlight.pluginInterface" {

	
	public function init() {
		variables.coldSoup = new coldsoup.coldsoup();
		return this;
	}

	public void function process(required node, required jsoupObj, required markDownObj, struct document) localmode=true {

		listings = arguments.node.select(".listing");

		for ( listing in listings ) {
			attr = variables.coldSoup.getAttributes(listing);
			if ( attr.keyExists("data") and attr.data.keyExists("href") ) {
				code = FileRead( getCanonicalPath( document.basepath & "/" & attr.data.href ) );
				
				data = {};
				htmlBody = arguments.markDownObj.toHtml(code, data);
				html = data.keyExists("title") ? "<p class='listingName'>#data.title#</p>" : "";
				html &= data.keyExists("file") ? "<p class='listingFile'>#data.file#</p>" : "";
				html &= htmlBody;

				listing.html(html).removeAttr("data-href");
			}
			
		}
		
	}

}