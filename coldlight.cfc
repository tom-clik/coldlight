/*

# ColdLight

Utility function for collating markdown files into a single "publication"

For usage and background, see the [user guide](https://www.coldlight.net)

## Synopsis

### 1. Read index file
	
An index file is read and converted to HTML.

JSOUP is used to read any div nodes and see if they have an href attribute.

A collection of files is created by using a index file to determine the order of their inclusion.

These are parsed into a sorted struct of objects. The default key for the struct is the filename stem. Any meta data (see YAML format) is extracted into a `meta` key, the markdown is converted into HTML in `html`, and an array of heading objects for the individual file is generated in `headings`.

## Document Struct

A document struct contains the following keys

data     | Struct         | Complete struct of sections and sub sections keyed by ID. 
sections | Array          | Array of top level sections.
contents | Struct         | Struct of heading information. Each value is a struct contain keys TBC
meta     | Struct         | Struct of variables set via YAML

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
		variables.var_pattern = variables.patternObj.compile("(?m)\{\$\w*\_\w*\}",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);
		
		return this;
	}

	/**
	 * @hint Read an index file and return doc struct
	 *
	 * 
	 *
	 * 
	 */
	public struct function load (required string filename) localmode=true {
		
		filepath = GetDirectoryFromPath(arguments.filename);
		text = FileRead(arguments.filename);
		data = {};
		contents = {};
		returnVal = parseText(text=text, filepath=filepath, data=data, contents=contents);
		returnVal["data"] = data;
		returnVal["contents"] = contents;

		return returnVal;

	}

	/**
	 * @hint Recursive helper function for load()
	 *
	 * Parses text for div elements with href attribute.
	 *
	 * Reads file and parse that (possibly recursively)
	 * 
	 * 
	 * @text     Markdown text to parse
	 */
	private struct function parseText(required string text, required string filepath, required struct data, required struct contents)  localmode=true {

		temp = variables.markdown.markdown(arguments.text);
		
		retVal = { 
			"sections" = [],
			"contents" = temp.data.content, 
			"meta" = temp.data.meta, 
			"text" = arguments.text,
			"node" = temp.node
		};
		
		// convert attributes for each "div" into a struct
		for (div in retVal.node.select("div[href]")) {
			
			info = variables.coldsoup.nodeInfo(div);

			try {

				if (! StructKeyExists(info.attributes,"id")) {
					info.attributes["id"] = ListFirst(ListLast(info.attributes.href,"\/"),".");
				}

				// add default values
				StructAppend(info.attributes,{"meta"=false},false);
				
				filename = filepath & "/" & info.attributes.href;

				try{
					section_text = FileRead(filename);
				} 
				catch (any e) {
					throw(
						message      = "Unable to read input file #filename#:" & e.message, 
						detail       = e.detail
					);
				}

				subsection = parseText(text=section_text, filepath=arguments.filepath,data=arguments.data, contents=arguments.contents);

				// parse text is a variable -- not part of the main flow
				if (info.attributes.meta) {
					retVal.meta["#info.attributes.id#"] = subsection.html;
					continue;
				}

				subsection["id"] = info.attributes.id;

				tmp = duplicate(subsection.contents);
				// add section name to content items before appending to complete record
				for (headingid in subsection.contents) {
					StructAppend(tmp[headingid], {"section" = info.attributes.id}, false);
				}

				StructAppend(arguments.contents, tmp, false);

				arguments.data["#info.attributes.id#"] = subsection;
				retVal.sections.append(info.attributes.id);

				div.remove();

			}

			catch (any e) {
				throw(e);
				local.extendedinfo = {"tagcontext"=e.tagcontext, "node"=div.html(),"text"=arguments.text};
				throw(
					extendedinfo = SerializeJSON(local.extendedinfo),
					message      = "invalid node:#e.message#"
				);
			}
			
		}

		retVal["html"] = retVal.node.body().html();

		return retVal;

	}

	/**
	 * Replace {$varname} format variables
	 *
	 * 
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
	 * @hint Generate full html for epub
	 *
	 * NB this previously tried to do all the manifest etc. Will use different
	 * functions for that.
	 *
	 * All this really does is combine the html and process the footnotes
	 * 
	 * @doc  The document Objects
	 * @stylesheets   List of stylesheets to add
	 */
	private string function epub_html(required struct document) {
		
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
	 * Not working yet. Needs to call princeXML. Currently just returns HTML
	 * 
	 */
	public string function pdf(
		required struct document,
		required string template,
		required string filename) localmode=true {

		doc = duplicate(arguments.document);

		doc["template"] = FileRead(arguments.template,"utf-8");

		doc.meta.body = pdf_html(doc);
		toclevel = doc.meta.toclevel ? : 1;

		doc.meta.toc = TOC(doc.contents,toclevel)

		html = variables.mustache.render(template=doc.template, context=doc.meta);
		
		// FileWrite(arguments.filename, html);

		return html;

	}

	private string function pdf_html(required struct document) {
		
		local.html = "";
		local.meta = arguments.document.meta ? : {};
		

		for (local.id in arguments.document.sections) {

			local.doc = arguments.document.data[local.id];

			StructAppend(local.meta, local.doc.meta, false);

			local.doc.node.outputSettings().charset("UTF-8");

			// TODO: common function for xrefs
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

		local.html = replaceVars(local.html, local.meta);

		return local.html;

	}

	/**
	 * Get list of images from all files
	 */
	private array function getImages(required any document format="") localmode=true {

		// (returned in manifest argument).
		returnVal = [];
		
		if ( arguments.document.meta.keyExists("cover") ) {
			returnVal.append( arguments.document.meta.cover );
		}
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
	private string function processStylesheets(
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
	private string function OpfTOC(required struct contents) {
		local.html = [];
		local.html.append("<?xml version=""1.0"" encoding=""UTF-8""?>");
		local.html.append("<html xmlns=""http://www.w3.org/1999/xhtml"" xmlns:epub=""http://www.idpf.org/2007/ops"">");
		local.html.append("<head>");
		local.html.append("	<meta charset=""utf-8"" />");
		local.html.append("	<title>Contents</title>");
		local.html.append("</head>");
		local.html.append("<body>");
		local.html.append("  <nav xmlns:epub=""http://www.idpf.org/2007/ops"" epub:type=""toc"" id=""toc"">");
		local.html.append("    <ol>" & epubTOC(contents=arguments.contents,filename="content.xhtml") & "</ol>");
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
	 * HTML for a epub table of contents.
	 *
	 * @contents      Struct of headings
	 * @filename      Name of file containing headings. Note this is geared to our system of only having one combined HTML file.
	 */
	private string function epubTOC(required struct contents, required string filename) localmode=true {
		
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

	/**
	 * HTML for a normal table of contents.
	 *
	 * @contents      Struct of headings
	 */
	private string function TOC(required struct contents, numeric toclevel=3) localmode=true {
		
		html = "";

		for (id in arguments.contents) {
			heading = arguments.contents[id];
			toc = heading.toc ? : true; // toc can be set to false via notoc mechanism
			if (toc && ( heading.level <= arguments.toclevel ) ) {
				
				html &= "    <p class='toc toc#heading.level#'><a href=""###heading.id#"">#heading.text#</a></p>" & newLine();
			}
			
		}
		
		return html;

	}

	private string function OPFPackage(required struct doc, struct manifest={}) {
		
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
	private string function OPFContainer() {
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
	public array function getHeadingData(required struct document) {

		local.retVal = [];

		for (local.code in StructSort(arguments.document.contents, "textnocase", "asc", "text") ) {
			local.heading = arguments.document.contents[local.code];
			if (local.heading.toc) {
				ArrayAppend(local.retVal,{"level"=local.heading.level,"code"=local.heading.id,"section"=local.heading.section,"anchor"=local.code,"title"=local.heading.text});
			}

		}

		return local.retVal;
		
	}

	public struct function epub(
		required struct document,
		required string filepath,
		required string template,
		required string filename

		) localmode=true {
		
		doc = duplicate(arguments.document);
		
		doc["template"] = FileRead(arguments.template,"utf-8");

		doc["manifest"] = {"styles"={}};
		doc["template"] = processStylesheets(doc["template"],doc.manifest.styles);

		doc.meta.body = epub_html(doc);

		if (fileExists(arguments.filename)) {
			try{
				fileDelete(arguments.filename);
			} 
			catch (any e) {
				local.extendedinfo = {"tagcontext"=e.tagcontext,"filename":arguments.filename};
				throw(
					extendedinfo = SerializeJSON(local.extendedinfo),
					message      = "Unable to delete exising file:" & e.message, 
					detail       = e.detail
				);
			}
			
		}

		// Epub toc file
		outputFile = "OPS/toc.xhtml";
		html = OpfTOC(contents=doc.contents);
		zipFile(arguments.filename, outputFile, html);

		// mime type file
		outputFile = "mimetype";
		html = OPFMimeType();
		zipFile(arguments.filename, outputFile, html);
		
		// container file
		outputFile = "META-INF/container.xml";
		html = OPFContainer();
		zipFile(arguments.filename, outputFile, html);
		
		// manifest file
		outputFile = "OPS/package.opf";
		html = OPFPackage(doc=doc);
		zipFile(arguments.filename, outputFile, html);

		// this isn't great. IMages assumed to be in /images but see below, stylesheets have paths
		// TODO: standardise, use one methodology
		for (item in doc.manifest["images"]) {
			source = getCanonicalPath( arguments.filePath & item );
			data = fileReadBinary(source);
			zipFile(arguments.filename,"OPS/" & item, data);
		}

		for (item in doc.manifest.styles) {
			source = getCanonicalPath( arguments.filePath & doc.manifest.styles[item] );
			data = fileRead(source);
			zipFile(arguments.filename,"OPS/css/" & item, data);
		}

		// output html
		html = variables.mustache.render(template=doc.template, context=doc.meta);
		outputFile = "OPS/content.xhtml";

		zipFile(arguments.filename, outputFile, html);

		return doc;

	}

	/**
	 * Add to zip file
	 * 
	 * @zipfile   full path of zip file to add to
	 * @entrypath  entry path of file
	 * @content    content to save (binary or string)
	 * 
	 */
	public void function zipFile(zipfile, entrypath, content) {
		try{
			cfzip(action="zip",file=arguments.zipfile) {
				cfzipparam( entrypath = arguments.entrypath, content=arguments.content );
			};
		} 
		catch (any e) {
			local.extendedinfo = {
				"tagcontext" = e.tagcontext,
				"entrypath"  = arguments.entrypath, 
				"content"    = arguments.content
			};
			throw(
				extendedinfo = SerializeJSON(local.extendedinfo),
				message      = "Unable to add to zip file:" & e.message, 
				detail       = e.detail
			);
		}
		
	}

	public struct function saveSite(required struct document, required string template, required string outputDir, struct site={} ) localmode=true {

		returnVal = {};
		template = FileRead(arguments.template);
		context["site"] = duplicate(arguments.site);
		context["site"]["menu"] = sectionMenu(data=arguments.document.data, sections=arguments.document.sections);

		for (code in arguments.document.data) {
			sectionObj = arguments.document.data[code];
			// TODO: parent section values
			//context["section"] = sectionObj; 
			context["page"] = getPage(document=arguments.document,section=code);
			context["page"].body = Replace(context["page"].body,"{{","X&X^AA%A%","all");
			html = variables.mustache.render(template=template, context=context);
			html = Replace(html,"X&X^AA%A%","{{","all");

			fileName = getCanonicalPath(arguments.outputDir & "/" & sectionObj.id & ".html");
			fileWrite(fileName, html);

			returnVal["#fileName#"] = 1;
		}

		searchSymbols = getHeadingData(arguments.document);
		searchSymbolsJS = "symbols = " & serializeJSON(searchSymbols) & ";" & newLine();
		fileName = getCanonicalPath(arguments.outputDir & "/searchSymbols.js");
			fileWrite(fileName, searchSymbolsJS);

		return returnVal;

	}

	private struct function getPage(required struct document, required string section ) localmode=true {

		sectionData = arguments.document.data[arguments.section];

		// TODO: formalise removal of h1 tag to become title
		temp = sectionData.node.clone();
		temp.select("h1").first().remove();

		returnVal = {
			"title" = sectionData.meta.title,
			"page_title" = sectionData.meta.title,
			"html" = sectionData.html,
			"body" = temp.body().html()
		};

		// TODO: previous next for sub sections
		// requires:
		// TODO: parent sections for pages
		pos  = arrayFind(arguments.document.sections, arguments.section);

		if (pos > 1) {
			previous = arguments.document.data[arguments.document.sections[pos-1]];
			returnVal["previous"] = getLink(previous,"previous");
		}
		
		if (pos < arguments.document.sections.len()) {
			next = arguments.document.data[arguments.document.sections[pos+1]];
			returnVal["next"] = getLink(next,"next");
		}



		return returnVal;

	}

	private string function getLink(required struct dataSection, string icon) {
		local.icon_str = structKeyExists(arguments,"icon") ? "<i class='icon-#arguments.icon#'></i>": "";
		return "<a href='#arguments.dataSection.id#.html'>#local.icon_str##arguments.dataSection.meta.title#</a>";
	}

	private string function sectionMenu(required struct data, required array sections, boolean preview=false, string class="") localmode=true {
		className = arguments.class eq "" ? "" : " class='#arguments.class#'";
		menu = "<ul#className#>";

		for (code in arguments.sections) {
			section = arguments.data[code];
			title = section.meta.title ? : code;
			submenu = "";
			if (section.keyExists("sections")) {
				submenu = sectionMenu(data=arguments.data, sections=section.sections, preview=arguments.preview, class="submenu");
			}
			link = sectionLink(section=code,preview=arguments.preview);
			menu &= "<li><a id='menu_#code#' href='#link#'>#title#</a>#submenu#</li>";
		}

		menu &= "</ul>";

		return menu;
	}

	// Get link for a page 
	private string function sectionLink(required string section, string anchor, boolean preview=false) {
		link =  arguments.preview ? "?section=#arguments.section#" : "#arguments.section#.html";
		if (arguments.keyExists("anchor") ) {
			link &= "##" & arguments.anchor;
		}
		return link;
	}

}
