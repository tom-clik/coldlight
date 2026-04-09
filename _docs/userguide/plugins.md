---
title:	Plug ins
author: Tom Peer
toc_level: 1
---

Plug-ins can be used to adjust content after conversion to HTML. Typically they use Jsoup syntax to select nodes and update them.

## Plug-in Interface

There is an interface available to use/copy, see `pluginInterface.cfc`. Plug-ins should implement the `process` and `preProcess` function. 

### Pre-processing

The `preProcess` function operates on the whole markdown source before it is parsed. You can copy the blank function from the interface if you don't need it.

### Process

The more important function is `process`, which operates on the JSOUP node passed-in by reference. This is the whole document body for each individual document.

## Loading plug-ins

Plug-ins are loaded by supplying the component path to the `addPlugin` method. E.g.

```
coldLightObj.addPlugin('coldlight.testing.plugin_listings');
```

The `process` and `preProcess` methods will then be called on each document in the publication.


## Document struct

The document struct passed to the `process` function is the complete loaded publication. See the sample dump available in `testing/testLoad.cfm` if you need to reference other parts of the document.

## Sample

The `listings` sample selects all nodes with a class of `listing` and looks for an attribute `data-href`. If that is there, it loads and processes a markdown file and then replaces the body of the tag.

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
