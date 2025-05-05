---
title:	Plug ins
author: Tom Peer
toc_level: 1
---

Plug-ins can be used to adjust content after conversion to HTML. Typically they use Jsoup syntax to select nodes and update them.

## Plug in Interface

Plug ins should implement the `process` function:

```cfml
public void function process(required node, struct document) {
```

There is an interface available to use/copy, see `pluginInterface.cfc`

## Document struct

The document struct is the complete loaded publication. See the sample dump available in `testing/testLoad.cfm` if you need to reference other parts of the document.

## Sample

The listings sample selects all nodes with a class of `listing` and looks for an attribute `data-href`. If that is there, it loads and processes a markdown file and then replaces the body of the tag.

```cfml

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
```
