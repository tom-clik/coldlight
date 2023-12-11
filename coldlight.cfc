/*

# ColdLight

Utility function for collating markdown files into a single 
"publication"

## Synopsis

A collection of files is created either by using a index file

These are parsed into a sorted struct of objects. The default 
key for the struct is the filename stem. Any meta data (see YAML 
format) is extracted into a `meta` key, the markdown is 
converted into HTML in `html`, and an array of heading objects
for the individual file is generated in `headings`.

## Usage

### Index file

An index file is created using Markdown with HTML embedded. Each separate file
is included by using an href attribute attached to a div.

The index file can be reused to generate a complete HTML document -- see html_full()

A sample file is as follows

```markdown
---
title: The Digital Method
subtitle: Why software is so bad
author: Tom Peer
---

<div id="title" class="section">
	<p class="author">{$author}</p>
	<p class="title">{$title}</p>
	<p class="subtitle">{$subtitle}</p>
</div>

<div href='Intro.md' id='start' />
<div href='The_Digital_Method.md' />
```

### Meta Data

Meta data can be added using YAML format.

---
title:	Cold Light stuff
author: Tom Peer
toc_level: 2
---

This is returned in the meta data struct. The fields can also be used in the text `{$name}`.

### Heading Objects

Each `heading` object has three keys: the tagname, the html, and the meta information for the tag.

## Table of Contents

An HTML table of contents can be generated from the headings data. It is primarily intended for use in print versions.

### TOC Level

The toc level variable determines what level of headings are added to the TOC. By default this is 3. It can be varied by using the `toc_level` meta field in the index.

### Excluding headers

Headings with a class of `.notoc` will not be included in any TOCs.

*/

component name="coldlight" {
	
	/**
	 * @hint      Pseudo constructor
	 *
	 */
	public coldlight function init() {
		
		variables.markdown = new markdown.flexmark(attributes="true",typographic=true);
		variables.coldsoup = new coldsoup.coldsoup();
		variables.patternObj = CreateObject( "java", "java.util.regex.Pattern" );
		variables.include_pattern = variables.patternObj.compile("\[include\s+file\s*\=\s*[\""\']?(\S+?)[\""\']\s*\]",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);
		variables.var_pattern = variables.patternObj.compile("(?m)\{\$\w*\_\w*\}",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);
		
		return this;
	}

	// Load an index file
	public struct function load(required string filePath) {

		if (NOT FileExists(arguments.filePath)) {
			throw("File #arguments.filePath# not found");
		}
		
		local.doc = {"docs"=[=],"meta"={}};

		local.index = FileRead(arguments.filePath,"utf-8");

		local.temp = variables.markdown.toHtml(local.index,local.doc.meta);
		local.doc["node"] = variables.coldsoup.parse(local.temp);

		local.includes = getIncludes(local.doc.node);
		local.rootPath =  getDirectoryFromPath(arguments.filePath);

		for (local.file in local.includes) {
			local.id = ListFirst( ListLast( local.includes[local.file], "\/" ), ".");
			local.filename = local.rootpath & local.includes[local.file];
			local.meta = {};

			if ( FileExists( local.filename ) ) {
				local.text = FileRead( local.filename,"utf-8" );
				local.html = variables.markdown.toHtml(local.text,local.meta);
				if (local.meta.keyExists("id")) {
					local.id = local.meta.id;
				}
				local.temp = variables.coldsoup.parse( local.html );
				variables.coldsoup.unwrapHeaders(local.temp);
				parseFootnotes(local.temp);

				local.html = local.temp.body().html();
				local.doc.docs["#local.id#"] = {"html"=local.html,"meta"=local.meta, "headings" = getHeadings(local.temp), "jsoup"=local.temp};
				
			}
			else {
				local.doc.docs["#local.id#"] = {"html"="","meta"={}, "headings" = [] };
			}
			
			StructAppend(local.doc.meta,local.meta,true);
			
		}

		// parse but just for YAML
		
		
		// add toc to vars
		local.doc.meta["toc"] = TOChtml(local.doc);

		// add all heading text to meta data
		for (local.id in local.doc.docs) {
			
			for (local.heading in local.doc.docs[local.id].headings) {
				local.doc.meta["#local.heading.attributes.id#"] = local.heading.html;
			}
		}

		// Process html for vars, xrefs, and other fixes
		for (local.id in local.doc.docs) {

			local.docobj = local.doc.docs[local.id];
			
			if (local.docObj.html eq "") continue;

			// replace meta DATA
			local.docobj.html = replaceVars(text=local.docobj.html, data=local.doc.meta);

			// update cross references
			local.nodes = local.docobj.jsoup.select("a[href]");
			
			// look for link tags with blank text
			local.fixes = 0;
			for (local.node in local.nodes) {
				local.info = variables.coldsoup.nodeInfo(local.node) ;
				
				if ( Trim( local.info.html ) eq "") {
					local.id = ListLast(local.info.attributes.href , "##.");
					if ( local.doc.meta.KeyExists( local.id ) ) {
						local.node.html( local.doc.meta[local.id] );
						local.fixes = 1;
					}
				}
			}

			

			// unwrap images
			// All images go on their own block. If you really want wrapping use floats or somethign with a class
			local.nodes = local.docobj.jsoup.select("img");
			for (local.node in local.nodes) {
				local.node.parent().unwrap();
				local.fixes = 1;
			}

			if ( local.fixes ) {
				local.docobj.html = local.docobj.jsoup.body().html();
			}

			StructDelete(local.docobj, "jsoup");
		}

		return local.doc;

	}

	/**
	 * Replace {$varname} format variables
	 * 
	 */
	public string function replaceVars(required string text, required struct data) {

		local.matches = ReMatchNoCase("\{\$*.+?\}",arguments.text);
		
		// create unique list to only process each var once
		local.vars = {};

		if ( ArrayLen(local.matches) ) {
			for (local.match in local.matches) {
				local.vars[ ListFirst( match,"{$}" ) ] = 1;
			}

			for (local.match in local.vars) {
				if ( arguments.data.KeyExists( local.match ) ) {
					arguments.text = ReplaceNoCase( arguments.text, "{$#local.match#}", arguments.data[local.match], "all" );
				}
			}

		}

		return arguments.text;
	}

	// Flexmark will extract footnotes into the HTML
	// We want to use them in different ways according to how we are diplsaying
	// the content. Here we parse them out into a struct and put variables
	// in for place holders
	private void function parseFootnotes(required any document) {
		
		local.docs = arguments.document.select(".footnotes");
		if (! local.docs.len()) {
			return;
		}

		// get rid of the extraneous <sup> tags
		local.markers = arguments.document.select("sup[id]");
		for (local.marker in local.markers) {
			local.marker.unwrap();
		}

		// find all the footnote markers
		local.footnotes = arguments.document.select("a.footnote-ref");

		for (local.marker in local.footnotes) {
			/* find footnote with format 
			<li id="fn-2"> <p>Look it up if you don’t already know it. And then try not to do it.</p>
			*/
			local.href = local.marker.attr("href");
			local.num = ListLast(local.href,"-");
			local.note = arguments.document.select(local.href & " p").first().html();
			local.marker.html("<span class='footnote'>#local.note#</span>").unwrap();
		}

		// remove the footnotes section
		arguments.document.select(".footnotes").first().remove();
		

	}
	
	private array function getHeadings(required any document) {
		local.headings = [];
		local.nodes = arguments.document.select("h1,h2,h3,h4,h5,h6");
		for (local.node in local.nodes) {
			local.headings.append( variables.coldsoup.nodeInfo(local.node) );
		}
		return local.headings;
	}

	/**
	 * @hint Parse [include file=''] pattern from a string
	 *
	 * @return struct keyed by the tag matched with values=the file
	 */
	private struct function getIncludesOld(required string text) {

		local.vals = variables.include_pattern.matcher(arguments.text);

		local.fileNames  = [=];
		while (local.vals.find()){
		    local.fileNames[local.vals.group()] = local.vals.group(javacast("int",1));
		}
		
		return local.fileNames;

	}

	/**
	 * @hint Parse [include file=''] pattern from a string
	 *
	 * @return struct keyed by the tag matched with values=the file
	 */
	private struct function getIncludes(required node) {

		local.fileNames = [=];

		local.includes = arguments.node.select( "div[href]" );
		for (local.include in local.includes) {
			local.href = local.include.attr("href");
			local.id = ListFirst( ListLast( local.href, "\/" ), ".");
			local.fileNames[local.id] = local.href;
			local.include.attr("id",javacast("String", local.id));

		}
		
		return local.fileNames;

	}
	
	
	/**
	 * @hint Create markdown doc struct
	 * 
	 * Also apply any coldlight specific formatting
	 *
	 * TODO: actually use this...
	 */
	public string function markdownToHTML(required string text, required struct data ) {
		local.html = variables.markdown.toHtml(arguments.text, arguments.data);
		local.html = Replace(local.html," -- ", " &ndash; ","all");
		return local.html;
	}

	// get combined HTML for all docs
	public string function html(required struct doc, string template) {
		
		if ( arguments.keyExists("template") ) {
			local.html = replaceVars(text=arguments.template, data=arguments.doc.meta);
		}
		else {
			local.html = "";
		}

		for (local.id in arguments.doc.docs) {
			if ( arguments.keyExists("template") ) {
				local.html = replaceNocase(local.html, "{$#local.id#}", arguments.doc.docs[local.id].html);
			}
			else {
				local.html &= arguments.doc.docs[local.id].html;
			}
		}

		return local.html;
	}

	// WIP trying out using the index as a proper file
	/**
	 * Generate full XML using the index file as a template (Still very prototype)
	 * @doc  The document Objects
	 * @stylesheets   List of stylesheets to add
	 * @manifest   Struct to add details of images and stylesheets to
	 */
	public string function html_full(required struct doc, string stylesheets="", struct manifest={}) {
		
		if ( ! arguments.doc.keyExists("node") ) {
			throw("No node define in doc...");
		}
		local.node = arguments.doc.node.clone();

		local.includes = local.node.select( "div[href]" );
		for (local.include in local.includes) {
			local.id = local.include.attr("id");
			if (arguments.doc.docs.KeyExists(local.id)) {
				
				local.include.html( arguments.doc.docs[local.id].html );
				local.include.removeAttr("href");
				local.include.tagName("section");

			}
		}

		// remove unwanted IDs
		local.headers = local.node.select( "h3,h4,.dialog h2" );
		for (local.header in local.headers) {
			local.header.removeAttr("id");
		}

		// Convert caption attibutes to tags
		local.tables = local.node.select( "table[caption]" );
		for (local.table in local.tables) {
			local.table.prepend(variables.coldsoup.createNode(tagName="caption",text=local.table.attr("caption")));
			local.table.removeAttr("caption");
		}

		local.node.title(arguments.doc.meta.title);
		local.node.head().appendElement("meta").attr("name","author").attr("content",arguments.doc.meta.author);
		local.node.head().appendElement("meta").attr("charset","UTF-8");

		local.node.outputSettings(variables.coldsoup.XML); 
        local.node.outputSettings().charset("UTF-8");
		
		addNameSpace(local.node);

		// Get lists of images (returned in manifest argument).
		arguments.manifest["images"] = [];
		
		local.images = local.node.select( "img" );
		for (local.image in local.images) {
			arguments.manifest["images"].append( local.image.attr("src") );
		}

		local.notes = local.node.select( "span.footnote" );
		local.noteshtml = [];
		local.count = 0;
		for (local.note in local.notes) {
			local.count++;
			local.noteshtml.append( "<p><a id=""footnote-#local.count#"" href=""##footnote-#local.count#-ref""><strong>#local.count#</strong></a> #local.note.html()#</p>");
			local.note.html( "<a id=""footnote-#local.count#-ref"" href=""##footnote-#local.count#""><sup>#local.count#</sup></a>" );
		}

		if (local.count) {
			local.node.body().append("<section id=""footnotes""><h1>Footnotes</h1>#local.noteshtml.toList("")#</section>");
		}

		// add stylesheet
		arguments.manifest["stylesheets"] = [];
		for (local.style in ListToArray(arguments.stylesheets)) {
			arguments.manifest["stylesheets"].append(local.style);
			local.node.head().appendElement("link").attr("rel","stylesheet").attr("href",local.style);
		}

		local.html = local.node.html();
		local.html = "<?xml version=""1.0"" encoding=""UTF-8""?>" & newLine() & local.html ;
		local.html = replaceVars(text=local.html, data=arguments.doc.meta);

		

		return local.html;
	}

	// add required namespaces for epub
	private function addNameSpace(node) {
    	arguments.node.select("html").attr("xmlns", "http://www.w3.org/1999/xhtml").attr("xmlns:epub", "http://www.idpf.org/2007/ops");
    }

    /**
     * @hint WIP creating TOC file for OPF
     *
     * See the epub notes. We're creating a separate file that doesn't really get used.
      */
	public string function OpfTOC(required struct doc) {
		local.html = [];
		local.html.append("<?xml version=""1.0"" encoding=""UTF-8""?>");
		local.html.append("<html xmlns=""http://www.w3.org/1999/xhtml"" xmlns:epub=""http://www.idpf.org/2007/ops"">");
		local.html.append("<head>");
		local.html.append("	<meta charset=""utf-8"" />");
		local.html.append("	<title>Contents</title>");
		local.html.append("</head>");
		local.html.append("<body>");
		local.html.append("  <nav xmlns:epub=""http://www.idpf.org/2007/ops"" epub:type=""toc"" id=""toc"">");
		local.html.append("    <ol>" & TOChtml(doc=arguments.doc,tag="li",filename="content.xhtml") & "</ol>");
		local.html.append("  </nav>");
		local.html.append("  <nav xmlns:epub=""http://www.idpf.org/2007/ops"" epub:type=""landmarks"" id=""guide"">");
		local.html.append("    <ol>");
		local.html.append("      <li>");
		local.html.append("         <a epub:type=""bodymatter""  href=""content.xhtml##Intro"">Begin Reading</a>");
		local.html.append("       </li>");
		local.html.append("     </ol>");
		local.html.append("   </nav>");
		local.html.append("</body>");
		local.html.append("</html>");

		return local.html.toList( newLine() );
	}
	/** get an HTML list representation of the TOC
	*/
	public string function TOChtml(required struct doc, string tag="p", string filename="") {

		local.menu = "";
		local.toc_level = arguments.doc.meta.toc_level ? : 3;
		for (local.id in arguments.doc.docs) {
			local.doc = arguments.doc.docs[local.id];
			for (local.heading in local.doc.headings) {
				
				local.level = Replace(local.heading.tagName,"h","");
				// TODO: needs wrapping
				if (local.level lte local.toc_level) {
					// MUSTDO: mechanism for the filename
					local.menu &= "<#arguments.tag# class='toc#local.level#'><a href='#arguments.filename####local.heading.attributes.id#'>" & local.heading.html & "</a></#arguments.tag#>";
				}
				
				// TODO: resurrect what is needed here
				// local.selectedClass = local.isSelected ? " selected" : " notselected";
				// local.menu &= "<div class='menuItem #local.selectedClass#'>";

				// local.menu &= "<a class='nav-link scrollto toc1' href='" & getLink(pub=arguments.pub,code=local.id,cache=arguments.cache) & "'>#local.page.meta.meta.title#</a>";
				// }
				
				
				// if (local.submenu != "") {
				// 	local.menu &= "<nav class='doc-sub-menu nav flex-column'>" & local.submenu & "</nav>";
				// }
				

			}
		}

			
		return local.menu;

	}

	public string function OPFPackage(required struct doc, struct manifest={}) {
		
		StructAppend(arguments.doc.meta,{"author"="","pub-id"=createUUID(), "language"="EN-US"},false);
		StructAppend(arguments.manifest,{"stylesheets"=[],"images"=[]},false);
		
		local.html = [];
		local.html.append("<?xml version=""1.0"" encoding=""UTF-8""?>");
		local.html.append( "<package xmlns=""http://www.idpf.org/2007/opf"" version=""3.0"" xml:lang=""en"" unique-identifier=""pub-id"" prefix=""cc: http://creativecommons.org/ns##"">");
		local.html.append( "  <metadata xmlns:dc=""http://purl.org/dc/elements/1.1/"">");
		local.html.append( "    <dc:title id=""title"">#arguments.doc.meta.title#</dc:title>");
		local.html.append( "    <meta refines=""##title"" property=""title-type"">main</meta>");
		local.html.append( "    <dc:creator id=""creator"">#arguments.doc.meta.author#</dc:creator>");
		local.html.append( "    <!--meta refines=""##creator"" property=""file-as"">{$author_fileas}</meta-->");
		local.html.append( "    <meta refines=""##creator"" property=""role"" scheme=""marc:relators"">aut</meta>");
		local.html.append( "    <dc:identifier id=""pub-id"">#arguments.doc.meta["pub-id"]#</dc:identifier>");
		local.html.append( "    <meta property=""dcterms:modified"">#dateTimeFormat(now(), "iso", "UTC")#</meta>");
		local.html.append( "    <dc:language>#arguments.doc.meta["language"]#</dc:language>");
		local.html.append( "  </metadata>");
		local.html.append( "  <manifest>");

		for (local.image in arguments.manifest.images) {
			local.filename = ListLast(local.image,"\/");
			local.id = ListFirst( local.filename , ".");
			local.mime = mimeType( ListLast( local.filename , ".") );
			local.props = local.id eq "cover_image" OR local.id eq "cover_image" ? " properties=""cover-image""" : "";
			local.html.append( "    <item id=""img_#local.id#""#local.props# href=""#local.image#""  media-type=""#local.mime#""/>");
		}
		for (local.stylesheet in arguments.manifest.stylesheets) {
			local.id = ListFirst( ListLast(local.stylesheet,"\/") , ".");
			local.html.append( "    <item id=""#local.id#""#local.props# href=""#local.stylesheet#""  media-type=""text/css""/>");
		}
		local.html.append( "    <item id=""content"" href=""content.xhtml"" media-type=""application/xhtml+xml""/>");
		local.html.append( "    <item id=""toc"" properties=""nav"" href=""toc.xhtml"" media-type=""application/xhtml+xml""/>");
		local.html.append( "  </manifest>");
		local.html.append( "  <spine>");
		local.html.append( "    <itemref linear=""yes"" idref=""content""/>");
		local.html.append( "  </spine>");
		local.html.append( "</package>");
		return local.html.toList( newLine() );
	}

	public function mimeType(required string ext) {
		switch (arguments.ext ) {
			case "jpg":
				return "image/jpeg";
			case "png":
				return "image/png";

		}
		throw("Unknown image extension #arguments.ext#");
	}
	/** get an HTML list representation of the TOC
	*/
	public string function getPageHeadings(required struct page, string id="page_menu") {

		local.retVal = "<ul class='pageHeadings'>";
		
		for (local.heading in arguments.page.meta.tocList) {
			
			// for page headings we only want level 2 and below
			if (arguments.page.meta[local.heading].level > 1 && arguments.page.meta[local.heading].level <= 3) {

				local.retVal &= "<li id='headingmenu_#local.heading#' class='level#arguments.page.meta[local.heading].level#'><a href='###local.heading#'>#arguments.page.meta[local.heading].text#</a></li>";

			}
		}

		local.retVal &= "</ul>";

		return local.retVal;
		
	}

	// return a container definition for EPUB
	public string function OPFContainer() {
		local.html = [];
		local.html.append("<?xml version=""1.0"" encoding=""UTF-8""?><container xmlns=""urn:oasis:names:tc:opendocument:xmlns:container"" version=""1.0"">");
		local.html.append("<rootfiles>");
		local.html.append("<rootfile full-path=""OPS/package.opf"" media-type=""application/oebps-package+xml""/>");
		local.html.append("</rootfiles>");
		local.html.append("</container>");
		return local.html.toList( newLine() );
	}

	// return the required MIME type file for EPUB
	public string function OPFMimeType() {
		return "application/epub+zip";
	}
	/** 
	 * @hint get headings for a pub as an an array
	 * 
	 *  Used for inclusion in symbols (see fuzzy search functionality) and manual toc generation
	 *  
	 */
	public array function getHeadingData() {

		local.retVal = [];

		for (local.pub in variables.publist) {

			ArrayAppend(local.retVal,{"level"=1,"pub"=local.pub,"code"="index","title":variables.pubs[local.pub].title});

			if (StructKeyExists(this.data,local.pub)) {

				local.pubdata = this.data[local.pub];
				
				for (local.id in local.pubdata.orderedIndex) {

					local.page = getPageData(local.pub, local.id);

					for (local.code in local.page.meta.tocList) {
						local.heading = local.page.meta[local.code];
						// todo: actual level
						ArrayAppend(local.retVal,{"level"=local.heading.level ,"pub"=local.pub,"code"=local.id,"anchor"=local.code,"title":local.heading.text});
					}
					
				}

			}

		}


		return local.retVal;
		
	}

	/**
	 * @hint Gets the contents of a complete pub for PDF
	 *
	 
	 * @return     The contents.
	 */
	public string function getContents(string pub, level=3) {
		local.toc = "<div id='contents' class='toc'>";

		local.data = getHeadingData();
		
		for (local.heading in local.data) {
			if (local.heading.pub == arguments.pub && local.heading.level <= arguments.level) {
				if (StructKeyExists(local.heading,"anchor")) {
					local.toc &= "<p class='toc#local.heading.level#'><a href='###local.heading.anchor#'>#local.heading.title#</a></p>";
				}
			}
		}

		local.toc &= "</div>";

		return local.toc;
	}

	
	public array function getPages(required string pub) {

		if (! StructKeyExists(this.data, arguments.pub)) {
			local.pubDef = variables.pubs[arguments.pub];
			parseFolder(local.pubDef.path, local.pubDef.code);
		}


		return this.data[arguments.pub].orderedIndex;
	}

	private struct function getPageData(required string pub, required string code) {
		
		if (! StructKeyExists(this.data, arguments.pub)) {
			if (! StructKeyExists(variables.pubs,arguments.pub)) {
				throw("Publication not defined");
			}
			local.pubDef = variables.pubs[arguments.pub];
			parseFolder(local.pubDef.path, local.pubDef.code);
		}

		if (! StructKeyExists(this.data[arguments.pub]["pages"],arguments.code)) {
			throw("page not found #arguments.code#:#arguments.code#");
			
		}

		return this.data[arguments.pub]["pages"][arguments.code];


	}

	

}
