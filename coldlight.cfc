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
		variables.mustache = new mustache.Mustache();
		variables.patternObj = CreateObject( "java", "java.util.regex.Pattern" );
		variables.include_pattern = variables.patternObj.compile("\[include\s+file\s*\=\s*[\""\']?(\S+?)[\""\']\s*\]",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);
		variables.var_pattern = variables.patternObj.compile("(?m)\{\$\w*\_\w*\}",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);
		
		return this;
	}

	/**
	 * @hint Read an index file 
	 *
	 * An index file can include other markdown files. Include them
	 * using <div href='filename.md' />
	 *
	 * Use meta=true and an id to read the files into a meta var rather than the content, e.g.
	 *
	 * <div href='Publisher_Info.md' id='publisher_info' meta='true' />
	 * 
	 * Note that the syntax is quite fussy.
	 * 
	 */
	public struct function load (required string filename) localmode=true {
		
		returnVal = ["contents"=[=],"data"=[=],"meta"={}];

		filepath = GetDirectoryFromPath(arguments.filename);
		text = FileRead(arguments.filename);
		
		html = variables.markdown.toHtml(text, returnVal.meta);
		
		doc = variables.coldsoup.parse(html);
		
		for (div in doc.select("div")) {
			info = variables.coldsoup.nodeInfo(div);

			try {
				if (! StructKeyExists(info.attributes,"id")) {
					info.attributes["id"] = ListFirst(info.attributes.href,".");
				}
				StructAppend(info.attributes,{"meta"=false},false);
				returnVal.data["#info.attributes.id#"] = info.attributes;
				
			}
			catch (any e) {
				local.extendedinfo = {"tagcontext"=e.tagcontext, "node"=info.html(),"filename"=arguments.filename};
				throw(
					extendedinfo = SerializeJSON(local.extendedinfo),
					message      = "invalid node:#e.message#"
				);
			}
			
		}
		
		for (id in returnVal.data) {
			info = returnVal.data[id];
			filename = filepath & "/" & info.href;
			try{
				info["text"] = FileRead(filepath & "/" & info.href);
			} 
			catch (any e) {
				throw(
					message      = "Unable to read input file #filename#:" & e.message, 
					detail       = e.detail
				);
			}
			
			temp = variables.markdown.markdown(info["text"],returnVal.meta);

			if (info.meta) {
				returnVal.meta["#id#"] = temp.html;
				structDelete(returnVal.data, id);
				continue;
			}

			info["meta"] = temp.data.meta;
			info["content"] = Duplicate(temp.data.content);
			info["node"] = temp.node;
			info["html"] = temp.html;

			// add file name to contents before appending to complete record
			for (headingid in temp.data.content) {
				temp.data.content[headingid]["file"] = id;
				StructAppend(returnVal["contents"], temp.data.content);
			}

		}

		return returnVal;

	}

	/**
	 * Replace {$varname} format variables
	 *
	 * This is now deprecated. See mechanisms using mustache
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

	
	
	private array function getHeadings(required any document) {
		local.headings = [];
		local.nodes = arguments.document.select("h1,h2,h3,h4,h5,h6");
		for (local.node in local.nodes) {
			local.headings.append( variables.coldsoup.nodeInfo(local.node) );
		}
		return local.headings;
	}

	/**
	 * @hint Generate full html for kindle (Still very prototype)
	 *
	 * NB this previously tried to do all the manifest etc. Will use different
	 * functions for that.
	 *
	 * All this really does is combine the html and process the footnotes
	 * 
	 * @doc  The document Objects
	 * @stylesheets   List of stylesheets to add
	 */
	public string function html(required struct document) {
		
		local.html = "";
		local.meta = arguments.document.meta ? : {};
		// track footnotes
		local.noteshtml = [];
		local.notecount = 0;

		for (local.id in arguments.document.data) {
			local.doc = arguments.document.data[local.id];

			StructAppend(local.meta, local.doc.meta, false);

			local.doc.node.outputSettings(variables.coldsoup.XML); 
			local.doc.node.outputSettings().charset("UTF-8");

			local.notes = local.doc.node.select( "span.footnote" );
		
			for (local.note in local.notes) {
				local.notecount++;
				local.noteshtml.append( "<p><a id=""footnote-#local.notecount#"" href=""##footnote-#local.notecount#-ref""><strong>#local.notecount#</strong></a> #local.note.html()#</p>");
				local.note.html( "<a id=""footnote-#local.notecount#-ref"" href=""##footnote-#local.notecount#""><sup>#local.notecount#</sup></a>" );
			}

			local.links = local.doc.node.select("a[href]");

			for (local.link in local.links) {
			
				local.linkid = ListLast(local.link.attr("href"),"##");
				
				if (StructKeyExists(arguments.document.contents,local.linkid)) {
					local.text = local.link.text();
					if (trim(local.text) eq "") {
						local.link.html(arguments.document.contents[local.linkid].text);
					}
				}
				
			}

			local.html &= "<section id='#local.id#'>" & local.doc.node.body().html() & "</section>";
			
		}

		if (local.notecount) {
			local.html &= "<section id=""footnotes""><h1>Footnotes</h1>#local.noteshtml.toList("")#</section>";
		}

		local.html = replaceVars(local.html, local.meta);

		return local.html;

	}

	/**
	 * Get list of images from all files
	 */
	private array function getImages(required any document format="") localmode=true {

		// (returned in manifest argument).
		returnVal = [];
		
		for (id in arguments.document.data) {

			images = arguments.document.data[id].node.select( "img" );
			for (image in images) {
				returnVal.append( local.image.attr("src") );
			}

		}

		return returnVal;

	}

	// replace all stylesheet urls with /styles/filename
	// Return struct of original file names
	public string function processStylesheets(
		required string html, 
		required struct stylesheets) localmode=true {

		doc = variables.coldsoup.parse(arguments.html);
		addNameSpace(doc);
		doc.outputSettings(variables.coldsoup.XML); 
		doc.outputSettings().charset("UTF-8");

		returnValue = {};
		links = doc.select("link[rel=stylesheet]");
		for (link in links) {
			filename = ListLast(link.attr("href"),"\/");
			stylesheets["#filename#"] = link.attr("href");
			link.attr("href","css/#filename#");
		}

		return doc.html();

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
	public string function OpfTOC(required struct contents) {
		local.html = [];
		local.html.append("<?xml version=""1.0"" encoding=""UTF-8""?>");
		local.html.append("<html xmlns=""http://www.w3.org/1999/xhtml"" xmlns:epub=""http://www.idpf.org/2007/ops"">");
		local.html.append("<head>");
		local.html.append("	<meta charset=""utf-8"" />");
		local.html.append("	<title>Contents</title>");
		local.html.append("</head>");
		local.html.append("<body>");
		local.html.append("  <nav xmlns:epub=""http://www.idpf.org/2007/ops"" epub:type=""toc"" id=""toc"">");
		local.html.append("    <ol>" & TOChtml(contents=arguments.contents,filename="content.xhtml") & "</ol>");
		local.html.append("  </nav>");
		local.html.append("  <nav xmlns:epub=""http://www.idpf.org/2007/ops"" epub:type=""landmarks"" id=""guide"">");
		local.html.append("    <ol>");
		local.html.append("      <li>");
		local.html.append("         <a epub:type=""bodymatter""  href=""content.xhtml##start"">Begin Reading</a>");
		local.html.append("       </li>");
		local.html.append("     </ol>");
		local.html.append("   </nav>");
		local.html.append("</body>");
		local.html.append("</html>");

		return local.html.toList( newLine() );
	}

	/**
	 * Simple HTML for a epub table of contents.
	 *
	 * @contents      Struct of headings
	 */
	private string function TOChtml(required struct contents, required string filename) localmode=true {
		
		html = "";

		for (id in arguments.contents) {
			heading = arguments.contents[id];
			toc = heading.toc ? : true; // toc can be set to false via notoc mechanism
			if (toc && heading.level eq 1) {
				
				html &= "    <li><a href=""#arguments.filename####heading.id#"">#heading.text#</a></li>" & newLine();
			}
			
		}
		
		return html;

	}

	public string function OPFPackage(required struct doc, struct manifest={}) {
		
		StructAppend(arguments.doc.meta,{"author"="","pub-id"=createUUID(), "language"="EN-US"},false);
		
		StructAppend(arguments.doc,{"manifest"={}},false);
		arguments.doc.manifest["images"] = getImages(arguments.doc);
		
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

		for (local.image in arguments.doc.manifest.images) {
			local.filename = ListLast(local.image,"\/");
			local.id = ListFirst( local.filename , ".");
			local.mime = mimeType( ListLast( local.filename , ".") );
			local.props = local.id eq "cover_image" OR local.id eq "cover_image" ? " properties=""cover-image""" : "";
			local.html.append( "    <item id=""img_#local.id#""#local.props# href=""#local.image#""  media-type=""#local.mime#""/>");
		}

		for (local.stylesheet in arguments.doc.manifest.styles) {
			local.id = ListFirst(local.stylesheet,".");
			local.html.append( "    <item id=""#local.id#"" href=""css/#local.stylesheet#""  media-type=""text/css""/>");
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

		// TODO: redo this
		throw("needs redoing");

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

		// TODO: this function no longer required, just use contents
		throw("needs redoing");

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


}
