/*

# ColdLight

Utility function for collating markdown files into a single "publication"

For usage and background, see the [user guide](https://www.coldlight.net)

## Synopsis

### 1. Read index file
	
An index file is read and converted to HTML.

JSOUP is used to read any div nodes and see if they have an href attribute. 

The included files are parsed into a sorted struct of objects. The default key for the struct is the filename stem. Any meta data (see YAML format) is extracted into a `meta` field, the markdown is converted into HTML in `html`, and an array of heading objects for the individual file is generated in `headings`.

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
	public coldlight function init(required string jarpath, required string jsoupjar) {
		
		variables.coldsoup = new coldsoup.coldsoup(arguments.jsoupjar);
		variables.markdown = new markdown.flexmark(attributes="true",typographic=true,jarpath=arguments.jarpath,coldsoupObj=variables.coldsoup);
		variables.mustache = new mustache.Mustache();
		variables.patternObj = CreateObject( "java", "java.util.regex.Pattern" );
		variables.var_pattern = variables.patternObj.compile("(?m)\{\$\w*\_\w*\}",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);
		variables.plugins = [=];
		
		return this;
	}

	// Add a plugin that implements pluginInterface
	public void function addPlugin(required pluginName) {
		
		variables.plugins[arguments.pluginName] = CreateObject("component", arguments.pluginName).init(markdownObj=variables.markdown, coldsoupObj=variables.coldsoup);
		if (StructKeyExists(this,"loggerObj")) {
			variables.plugins[arguments.pluginName].loggerObj = this.loggerObj;
		}
	}

	/**
	 * @hint Read an index file and return doc struct
	 * 
	 */
	public struct function load (required string filename) localmode=true {
		
		filepath = GetDirectoryFromPath(arguments.filename);
		text = FileRead(arguments.filename);
		data = {};
		contents = {};

		temp = parseText(text=text, filepath=filepath, data=data, contents=contents);

		setHierarchy(data=data,sections=temp.sections);

		returnVal["basepath"] = filepath;
		returnVal["sections"] = temp.sections;
		returnVal["meta"] = temp.meta;
		returnVal["data"] = data;
		returnVal["contents"] = contents;

		/* Index page has own text */
		if ( Trim( temp.node.body().html() ) neq "" ) {
			id = ListFirst( ListLast(arguments.filename,"\/"), "." );
			returnVal["meta"]["home"] = id;// weird naming. TODO: check see if this shouldn't be "id"
			returnVal["data"]["#id#"] = {
				"id" = id,
				"meta" = {"title": temp.meta.title },
				"node" = temp.node
			}
			// if there is only one page, we use that
			if ( !returnVal["sections"].len() ) {
				returnVal["sections"].append(id);
			}
		}
		else {
			returnVal["navigation_list"] = getNavigationList(data=returnVal.data, sections=returnVal.sections);
			returnVal["meta"]["home"] = returnVal["navigation_list"][1];
		}
		
		for (plugin_code in variables.plugins) {
			plugin = variables.plugins[plugin_code];
			for (section in returnVal.data) {
				sectionObj = returnVal.data[section];
				try {
					plugin.process(node=sectionObj.node, jsoupObj=variables.coldsoup, markDownObj=variables.markdown, document=returnVal);
				}
				catch (any e) {
					local.extendedinfo = {"error"=e};
					throw(
						extendedinfo = SerializeJSON(local.extendedinfo),
						message      = "Error in plug in:" & e.message, 
						detail       = e.detail
					);
					
					logger("Plugin #plugin_code# failed. Note the plug in should catch its own errors to give detail on the failure. Please update the plugin to do this.");
				}

				
			}
		}

		return returnVal;

	}

	/**
	 * @hint Recursive helper function for load()
	 *
	 * Calls markdown() on text. Needs to be recursive as it parses text for div elements
	 *  with href attribute and then parses those
	 * 
	 * @text     Markdown text to parse
	 */
	private struct function parseText(required string text, required string filepath, required struct data, required struct contents)  localmode=true {

		// run plugin preprocessor
		loop key="plugin_code" value="plugin" collection=variables.plugins {
			try {
				arguments.text = plugin.preProcess( arguments.text );
			}
			catch (any e) {
				logger(text="Plugin #plugin_code# preProcess failed. Note the plug in should catch its own errors to give detail on the failure. Please update the plugin to do this.",type="E");
			}
		}

		temp = variables.markdown.markdown(text=arguments.text,options={"meta"=false});

		// to avoid confusion later, ignore the single page toc
		structDelete(temp.data.meta, "toc");

		temp.node.outputSettings().charset("UTF-8");
		
		// Check title exists and remove first h1 if its the title
		titles = temp.node.select("h1");
		
		if ( IsDefined("titles") and titles.len() ) {
			title = titles.first();
			
			if (! temp.data.meta.keyExists("title") ) {
				temp.data.meta["title"] = title.text();
			}
			
			if ( title.text() eq temp.data.meta["title"] ) {
				title.remove();
			}
		}

		if (! temp.data.meta.keyExists("title") ) {
			extendedinfo = {"text"=arguments.text};
			throw(
				extendedinfo = SerializeJSON(local.extendedinfo),
				message      = "No title defined for document and no h1 set"
			);
		}

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
			div.remove();
 
			try {

				if (! StructKeyExists(info.attributes,"id")) {
					info.attributes["id"] = ListFirst(ListLast(info.attributes.href,"\/"),".");
					if (info.attributes.id eq "index") {
						info.attributes["id"] = ListFirst(info.attributes.href,"\/")
					}
					// removed sort-orders from filename for e.g. 50-sectioname
					numcheck = ListFirst(info.attributes["id"],"-");
					if ( isValid("integer", numcheck ) ) {
						info.attributes["id"] = Replace(info.attributes["id"],numcheck & "-","");
					}
				}

				// add default values
				StructAppend(info.attributes,{"meta"=false},false);
				
				filename = arguments.filepath & "/" & info.attributes.href;

				try{
					section_text = FileRead(filename);
				} 
				catch (any e) {
					throw(
						message      = "Unable to read input file #filename#:" & e.message, 
						detail       = e.detail
					);
				}

				// parse text as a variable -- not part of the main flow
				if (info.attributes.meta) {
					// not even markdown, maybe css or something
					if ( ListLast(filename,".") != "md" ) {
						retVal.meta["#info.attributes.id#"] = section_text;
					}
					else {
						temp = variables.markdown.markdown(text=section_text,options={"meta"=false});
						temp.node.outputSettings().charset("UTF-8");
						retVal.meta["#info.attributes.id#"] = temp.node.body().html();
					}
					continue;
				}
				else {
					subsection = parseText(text= section_text, filepath=getDirectoryFromPath(filename),data=arguments.data, contents=arguments.contents);
				}

				subsection["id"] = info.attributes.id;

				if ( Trim(subsection.node.body().html() neq "" ) ) {
					subsection["hasContent"] = 1;
					tmp = duplicate(subsection.contents);

					// add section name to content items before appending to complete record
					for (headingid in subsection.contents) {
						StructAppend(tmp[headingid], {"section" = info.attributes.id}, false);
					}

					StructAppend(arguments.contents, tmp, false);

				}
				else {
					subsection["hasContent"] = 0;
				}

				retVal.sections.append(info.attributes.id);
				arguments.data["#info.attributes.id#"] = subsection;

			}

			catch (any e) {
				local.extendedinfo = {"error"=e, "node"=div.html(),"text"=arguments.text};
				throw(
					extendedinfo = SerializeJSON(local.extendedinfo),
					message      = "invalid node:#e.message#"
				);
			}
			
		}

		return retVal;

	}

	/** Recursive function to set "parent" for any sub sections */
	private void function setHierarchy(required struct data, required array sections, string parent="") localmode=true {

		for (code in arguments.sections) {
			if (arguments.parent neq "") {
				arguments.data[code]["parent"] = arguments.parent;
			}
			if (arguments.data[code].keyExists("sections") AND ArrayLen(arguments.data[code].sections) ) {
				setHierarchy(data=arguments.data, sections=arguments.data[code].sections, parent=code);
			}
			
		}

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
	

	/**
	 * Not working yet. Needs to call princeXML. Currently just returns HTML
	 * 
	 */
	public string function pdf(
		required struct document,
		required string template,
		required string filename) localmode=true {

		templateHtml = FileRead(arguments.template,"utf-8");

		context = duplicate(arguments.document.meta);
		context.body = html(document=arguments.document);

		toclevel = arguments.document.meta.toclevel ? : 1;

		context.toc = TOC(arguments.document,toclevel)

		html = variables.mustache.render(template=templateHtml, context=context);
		

		return html;

	}

	/**
	 * Generate single page of html from sections (ignores "home" page)
	 *
	 * @footnotes  manually process footnotes and place end notes into meta var "footnotes" (requires context argument)
	 * @XML        sets output settings to XML - only needed for ebook generation
	 * @context    page rendering content to be updated with footnotes
	 *
	 */
	public string function html( required struct document, boolean footnotes=false, boolean XML=false, struct context={} ) {
		
		local.html = "";
		
		// track footnotes through recursion
		footnotes = {
			on = arguments.footnotes,
			html = [],
			count = 0,
		}

		local.html &= sectionsHTML(sections=arguments.document.sections,document=arguments.document, footnotes=footnotes, XML=arguments.XML);

		if (footnotes.count) {
			arguments.context["footnotes"] = footnotes.html.toList( newLine() );
		}


		if (StructKeyExists(arguments.document,"meta")) {
			local.html = variables.markdown.replaceVars(local.html, arguments.document.meta);
		}

		return local.html;

	}

	/**
	 * Recursive helper function for html()
	 * 
	 */
	private string function sectionsHTML(required array sections, required struct document, required struct footnotes, boolean XML=false, numeric depth=0 ) {

		local.html = "";

		for (local.id in arguments.sections) {

			local.sectionObj = arguments.document.data[local.id];
			node = duplicate(local.sectionObj.node);
			updateXrefs(node=node,contents=arguments.document.contents,preview=false,usePage=1);

			if (arguments.XML) {
				node.outputSettings(variables.coldsoup.XML); 
			}

			if (arguments.footnotes.on) {
				local.notes = node.select( "span.footnote" );

				for (local.note in local.notes) {
					arguments.footnotes.count++;
					arguments.footnotes.html.append( "<p><a id=""footnote-#arguments.footnotes.count#"" href=""##footnote-#arguments.footnotes.count#-ref""><strong>#arguments.footnotes.count#</strong></a> #local.note.html()#</p>");
					local.note.html( "<a id=""footnote-#arguments.footnotes.count#-ref"" href=""##footnote-#arguments.footnotes.count#""><sup>#arguments.footnotes.count#</sup></a>" );
				}
			}

			if ( arguments.depth ) {
				demoteHeadings(node=node,depth=arguments.depth);
			}

			local.headerLevel = arguments.depth + 1;
			
			if (arguments.sections.len() gt 1) {
				try{
					local.html &= "<section id='section_#local.id#' class='level-#local.headerLevel#'>";
					local.html &= "<h#local.headerLevel# id='#local.id#'>#local.sectionObj.meta.title#</h#local.headerLevel#>";
				} 
				catch (any e) {
					local.extendedinfo = {"error"=e, "sectionObj"=local.sectionObj};
					throw(
						extendedinfo = SerializeJSON(local.extendedinfo),
						message      = "Error creating toc:" & e.message, 
						detail       = e.detail
					);
				}
				
			}
			local.html &= node.body().html();

			if (StructKeyExists(local.sectionObj,"sections") && ArrayLen(local.sectionObj.sections) ) {
				local.html &= sectionsHTML(sections=local.sectionObj.sections,document=arguments.document, footnotes=arguments.footnotes, XML=arguments.XML, depth=local.headerLevel);
			}

			if (StructKeyExists(local.sectionObj,"meta")) {
				local.html = variables.markdown.replaceVars(local.html, local.sectionObj.meta);
			}
			if (arguments.sections.len() gt 1) {
				local.html &= "</section>";
			}

		}

		return local.html

	}

	private void function demoteHeadings(required node, required numeric depth) localmode=true {

		for (heading = 5; heading >= arguments.depth;  heading-- ) {
			headings = arguments.node.select( "h" & heading );
			headings.tagName("h" & heading + 1);
		}

	}


	/**
	 * @hint Update automatic cross references with text of target
	 *
	 * Auto links are any links with blank text or class of "auto" 
	 * 
	 */
	private void function updateXrefs(required node, required struct contents, boolean preview=false, boolean usePage=true) localmode=true {

		links = arguments.node.select("a[href]");

		for (link in links) {
			
			href =link.attr("href");
			
			if ( ! find("##", href ) ) {
				href = sectionLink(section=href, anchor="", preview=arguments.preview);
				link.attr("href", href);
			}
			else {
				
				linkid = ListLast(href,"##");

				if (StructKeyExists(arguments.contents,linkid)) {
					
					text = link.text();
					linkData = arguments.contents[linkid];
					if (trim(text) eq "" OR link.hasClass("auto")) {
						
						link.html(linkData.text);
					}
					if (arguments.usePage) {
						href = sectionLink(section=linkData.section, anchor=linkid, preview=arguments.preview);
					}
					else {
						href = "##" & linkid;
					}
					link.attr("href", href);
				}
				else {
					// manual link to e.g. table or something in form section#id
					if (ListLen( href ,"##") gt 1) {
						link_section = ListFirst(href,"##");
						href = sectionLink(section=link_section, anchor=linkid, preview=arguments.preview);
						link.attr("href", href);
					}
					
				}
			}
			
		}
				
	}

	/**
	 * Get list of images from all files
	 */
	private array function getImages(required struct document) localmode=true {

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

	/**
	 * replace all stylesheet urls with /styles/filename and return struct of original file names
	 * 
	 * @html        html text with relative paths to stylesheets
	 * @stylesheets Pass in struct by reference to return "set" of original names
	 */
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
	private string function OpfTOC(required struct document) {
		local.html = [];
		local.html.append("<?xml version=""1.0"" encoding=""UTF-8""?>");
		local.html.append("<html xmlns=""http://www.w3.org/1999/xhtml"" xmlns:epub=""http://www.idpf.org/2007/ops"">");
		local.html.append("<head>");
		local.html.append("	<meta charset=""utf-8"" />");
		local.html.append("	<title>Contents</title>");
		local.html.append("</head>");
		local.html.append("<body>");
		local.html.append("  <nav xmlns:epub=""http://www.idpf.org/2007/ops"" epub:type=""toc"" id=""toc"">");
		local.html.append("    <ol>" & epubTOC(document=arguments.document,filename="content.xhtml") & "</ol>");
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
	private string function epubTOC(required struct document, required string filename) localmode=true {
		
		html = "";

		for (id in arguments.document.sections) {
			
			sectionObj =  arguments.document.data[id];
			
			html &= "    <li><a href=""#arguments.filename####id#"">#sectionObj.meta.title#</a></li>" & newLine();

		}
		
		return html;

	}

	/**
	 * @hint HTML toc constructed from hierarchy
	 *
	 * TODO: [ISSUE-7] this needs to be more generic and usable for section TOCs
	 *
	 * @document      Complete document
	 * @toclevel      Headng level to include
	 * @linktype      page|live|preview - page = anchors on same page (epub, pdf), live = section.html, preview= index.cfm?section=section
	 */
	public string function TOC(required struct document, numeric toclevel=2, linktype="page") localmode=true {
		
		html = "";

		for (id in arguments.document.sections) {
			
			level = 1;	
			sectionObj =  arguments.document.data[id];
			
			html &= "    <p class='toc#level#'><a href=""###formatLink(section=id,type=arguments.linktype)#"">#sectionObj.meta.title#</a></p>" & newLine();

			if (arguments.toclevel gt 1) {
				level = 2;	
				if (sectionObj.keyExists("sections") ) {
					for (sub_id in sectionObj.sections) {
						subSectionObj =  arguments.document.data[sub_id];
						html &= "    <p class='toc#level#'><a href=""###formatLink(section=sub_id,type=arguments.linktype)#"">#subSectionObj.meta.title#</a></p>" & newLine();
						if (arguments.toclevel gt 2) {
							for (heading_id in subSectionObj.contents) {
								heading = subSectionObj.contents[heading_id];
								level = heading.level + 1;
								if (level gt 2 && level lte ( arguments.toclevel ) ) {
									html &= "    <p class='toc#level#'><a href=""###formatLink(section=sub_id,type=arguments.linktype,anchor=heading_id)#"">#heading.text#</a></p>" & newLine();
								}
							}
						}
						
					}
				}
			}

		}
		
		return html;

	}

	private string function OPFPackage(required struct context, struct manifest={}) {
		
		StructAppend(arguments.context,{"author"="","pub-id"="", "language"="EN-US"},false);
		StructAppend(arguments.manifest,{"styles" = [], "images"=[] }, false);

		local.html = [];
		local.html.append("<?xml version=""1.0"" encoding=""UTF-8""?>");
		local.html.append( "<package xmlns=""http://www.idpf.org/2007/opf"" version=""3.0"" xml:lang=""en"" unique-identifier=""pub-id"" prefix=""cc: http://creativecommons.org/ns##"">");
		local.html.append( "  <metadata xmlns:dc=""http://purl.org/dc/elements/1.1/"">");
		local.html.append( "    <dc:title id=""title"">#arguments.context.title#</dc:title>");
		local.html.append( "    <meta refines=""##title"" property=""title-type"">main</meta>");
		local.html.append( "    <dc:creator id=""creator"">#arguments.context.author#</dc:creator>");
		local.html.append( "    <!--meta refines=""##creator"" property=""file-as"">{$author_fileas}</meta-->");
		local.html.append( "    <meta refines=""##creator"" property=""role"" scheme=""marc:relators"">aut</meta>");
		local.html.append( "    <dc:identifier id=""pub-id"">#arguments.context["pub-id"]#</dc:identifier>");
		local.html.append( "    <meta property=""dcterms:modified"">#dateTimeFormat(now(), "iso", "UTC")#</meta>");
		local.html.append( "    <dc:language>#arguments.context.language#</dc:language>");
		local.html.append( "  </metadata>");
		local.html.append( "  <manifest>");

		for (local.image in arguments.manifest.images) {
			local.filename = ListLast(local.image,"\/");
			local.id = ListFirst( local.filename , ".");
			local.mime = mimeType( ListLast( local.filename , ".") );
			local.props = local.id eq "cover_image" OR local.id eq "cover_image" ? " properties=""cover-image""" : "";
			local.html.append( "    <item id=""img_#local.id#""#local.props# href=""#local.image#""  media-type=""#local.mime#""/>");
		}

		for (local.stylesheet in arguments.manifest.styles) {
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
				ArrayAppend(local.retVal,{"level"=local.heading.level,"id"=local.heading.id,"section"=local.heading.section,"title"=local.heading.text});
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
		
		context = duplicate(arguments.document.meta);
		
		templateHTML = FileRead(arguments.template,"utf-8");

		doc = {};
		
		manifest = {"styles"={},"images"= getImages(arguments.document) };
		
		templateHTML = processStylesheets(templateHTML,manifest.styles);

		context.body = html(document=arguments.document,XML=true,footnotes=true, context=context);

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
		html = OpfTOC(document=arguments.document);
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
		html = OPFPackage(context=context,manifest=manifest);
		zipFile(arguments.filename, outputFile, html);

		// Save images to zip. Requires images to be in sub folder. Could possibly improve to 
		// allow any path and update href in doc as we do with processStylesheets
		for (item in manifest["images"]) {
			source = getCanonicalPath( arguments.filePath & item );
			data = fileReadBinary(source);
			zipFile(arguments.filename,"OPS/" & item, data);
		}

		for (item in manifest.styles) {
			source = getCanonicalPath( arguments.filePath & manifest.styles[item] );
			data = fileRead(source);
			zipFile(arguments.filename,"OPS/css/" & item, data);
		}

		// output html
		html = variables.mustache.render(template=templateHTML, context=context);

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

	public struct function getSiteContext(required struct document, struct site={}, boolean preview=false ) localmode=true {

		context = duplicate(arguments.document.meta);
		
		context["site"] = duplicate(arguments.site);

		context["site"]["preview"] = arguments.preview ? 'true' : 'false';

		context["site"]["menu"] = sectionMenu(data=arguments.document.data, sections=arguments.document.sections, preview=arguments.preview);
		context["site"]["home_link"] = sectionLink(section=arguments.document.meta.home, preview=arguments.preview);

		linktype = arguments.preview ? "preview" : "live";
		context["toc"] = TOC(document=arguments.document, toclevel=arguments.document.meta.toclevel ? : 1, linktype=linktype);

		context.debug = arguments.preview;

		return context;

	}

	/**
	 * Generate HTML for a given page
	 * 
	 * @section       page code
	 * @document        
	 * @context       Struct to pass to mustache render. "page" is added to it
	 * @template      Mustache template for export
	 * @preview       Generate dynamic links for live preview
	 */
	public string function pageHTML( required string section, required struct document, required struct context, required string template, boolean preview=false ) localmode=true {
		
		// default page is index - use first section if not present
		if ( arguments.section eq "index" && ! arguments.document.data.keyExists("index") ) {
			arguments.section = arguments.document.sections[1];
		}

		sectionObj = arguments.document.data[arguments.section];

		if (! ( sectionObj.hasContent ? : true ) ) {
			return "";
		}

		// TODO: parent section values
		context["page"] = getPage(document=arguments.document,section=arguments.section,preview=arguments.preview);
		
		// replace {{ in text temporarily		
		context["page"].body = Replace(context["page"].html,"{{","X&X^AA%A%","all");

		context["page"]["section"] = {
			"id" = arguments.section,
			"parent" = sectionObj.parent ? : "",
		};

		// TODO: formalise all this stuff
		// section menu
		if ( sectionObj.keyExists("sections") ) {
			context["page"]["section"]["menu"] = sectionMenu(data=arguments.document.data, sections=sectionObj.sections,preview=arguments.preview);
		}

		html = variables.mustache.render(template=arguments.template, context=context);
		html = Replace(html,"X&X^AA%A%","{{","all");

		return html;

	}

	/**
	 * Save static html website 
	 */
	public struct function staticSite(required struct document, required string template, required string outputDir, struct site={} ) localmode=true {

		returnVal = {};
		templateHTML = FileRead(arguments.template);

		context = getSiteContext(document=arguments.document, site=arguments.site, preview=false );

		sectionList = structKeyArray(arguments.document.data);

		// Home page might have text in its own right, save it as a file
		if (! arguments.document.data.keyExists(arguments.document.meta.home) ) {
			// TODO: don't save if it doesn't have any actual content...
			// The "home" thing isn't the best mechanism for testing this.
			sectionList.append(arguments.document.meta.home);
		}

		arguments.document.meta["toc"] = TOC(document=arguments.document,toclevel=1,linktype="live");

		for (code in sectionList) {

			section = arguments.document.data[code];
			
			section.meta["toc"] = sectionTOC(document=arguments.document,toclevel=1,linktype="live");

			htmlx = pageHTML(document= arguments.document, section=code,context=context,template=templateHTML);

			if (htmlx eq "") continue;

			fileName = getCanonicalPath(arguments.outputDir & "/" & code & ".html");
			
			try{
				fileWrite(fileName, htmlx);
			} 
			catch (any e) {
				local.extendedinfo = {"error"=e,"filename": fileName};
				throw(
					extendedinfo = SerializeJSON(local.extendedinfo),
					message      = "Error writing file #fileName#:" & e.message, 
					detail       = e.detail
				);
			}
			
			
			returnVal["#code#"] = 1;
		
		}

		searchSymbolsJS = searchSymbols(document=arguments.document);
		fileName = getCanonicalPath(arguments.outputDir & "/searchSymbols.js");
		fileWrite(fileName, searchSymbolsJS);

		files = directoryList(arguments.outputDir,false,"name","*.html");
		for (fileName in files) {
			code = ListFirst(filename,".");
			if (! returnVal.keyExists(code)) {
				fileDelete(arguments.outputDir & "/" & fileName);
			}
		}

		return returnVal;

	}

	public string function searchSymbols() localmode=true {
		searchSymbols = getHeadingData(arguments.document);
		return "symbols = " & serializeJSON(searchSymbols) & ";" & newLine();
	}

	/**
	 *	 Replace {$ with a place holder if they're in a code block 
	 */	 
	private void function replaceCodeVars(required any node) localmode=true {

		code = node.select("code");
		for (text in code) {
			tmp = text.html();
			if (find("{$", tmp )) {
				text.html(Replace(tmp,"{$", "{dollarplaceholder","all"));
			}
		}

	}

	public struct function getPage(required struct document, required string section, boolean preview = false ) localmode=true {

		sectionData = arguments.document.data[arguments.section];
		node = duplicate(sectionData.node);
		updateXrefs(node=node,contents=arguments.document.contents,preview=arguments.preview,usePage=1);

		replaceCodeVars(node);
		page = {
			"title" = sectionData.meta.title,
			"page_title" = sectionData.meta.page_title ? : sectionData.meta.title,
			"html" = node.body().html(),
			"parent" = {}
		};

		if ( sectionData.keyExists("parent") ) {
			parentObj =  arguments.document.data[sectionData.parent];
			hasContent = parentObj.hasContent ? : true;
			page["parent"] = {
				"title" = parentObj.meta.title,
				"link" = hasContent ? getLink(dataSection=parentObj,preview=arguments.preview) : parentObj.meta.title
			};
		}

		page.html = variables.markdown.replaceVars(page.html, sectionData.meta);
		page.html = variables.markdown.replaceVars(page.html, arguments.document.meta);
		page.html = replace(page.html, "dollarplaceholder","$","all");


		pageNavigation(page=page, section=arguments.section, document=arguments.document, preview=arguments.preview);
		
		return page;

	}

	/**
	 * @hint populate fields for next and previous navigation
	 *
	 * | Field                 | Description
	 * |-----------------------|----------------------
	 * | next                  | Id of next section
	 * | next_link             | HTML element for link button
	 * | previous              | Id of previous section
	 * | previous_link         | HTML element for link button
	 * | next_section          | Id of next  top level section
	 * | next_section_link     | HTML element for link button
	 * | previous_section      | Id of previous top level section section
	 * | previous_section_link | HTML element for link button
	 *
	 * ## Logic
	 *
	 * next is either the first child if present or the next sibling
	 * previous is either the previous sibling or the
	 * 
	 */
	private void function pageNavigation( required struct page, required string section, required struct document, boolean preview=false) localmode=true {

		if (! arguments.document.keyExists("navigation_list") ) {
			arguments.document.navigation_list = getNavigationList(data=arguments.document.data, sections=arguments.document.sections);
		}
		sectionData = arguments.document.data[arguments.section];
		pos = ArrayFind(arguments.document.navigation_list, arguments.section);

		if ( pos ) {
			if (pos != ArrayLen(arguments.document.navigation_list)) {
				arguments.page["next"] = arguments.document.navigation_list[pos + 1];
				arguments.page["next_link"] = getLink(arguments.document.data[arguments.page["next"]],"next",arguments.preview);
			} else {
				arguments.page["next"] = "";
			}

			if (pos != 1) {
				arguments.page["previous"] = arguments.document.navigation_list[pos - 1];
				arguments.page["previous_link"] = getLink(arguments.document.data[arguments.page["previous"]],"previous",arguments.preview);
			} else {
				arguments.page["previous"] = "";
			}
		}
		else {
			arguments.page["next"] = "";
			arguments.page["previous"] = "";
		}

		if ( sectionData.keyExists("parent") ) {
			arguments.page["top"] = sectionData.parent;
			arguments.page["top_link"] = getLink(arguments.document.data[ sectionData.parent ],"top",arguments.preview);
		}
		else {
			arguments.page["top"] = "";
		}

	}

	/**
	 * @hint Return list of all sections in depth first order
	 *
	 * Note the function calls itself recursively, hence need for separate arguments
	 */
	private array function getNavigationList(required struct data, required array sections)  localmode=true {
		
		navList = [];
		
		for (code in arguments.sections ) {
			section = arguments.data[code];
			if ( section.hasContent ? : 1 ) {
				navList.append(code);
			}
			if ( section.keyExists("sections") ) {
				navList.append(getNavigationList(data = arguments.data, sections=section.sections ), true);
			}
		}

		return navList;

	}

	private array function getSiblings(required string section, required struct document) localmode=true {
		
		sectionObj = arguments.document.data[arguments.section];
		if (sectionObj.keyExists("parent") ) {
			sections = arguments.document.data[sectionObj.parent].sections;
		}
		else {
			sections = arguments.document.sections;
		}
		return sections;

	}

	private string function getLink(required struct dataSection, string icon, boolean preview=false) {
		local.icon_str = structKeyExists(arguments,"icon") ? "<i class='icon-#arguments.icon#'></i>": "";
		local.href = sectionLink(section=arguments.dataSection.id,preview=arguments.preview);
		return "<a href='#local.href#'>#local.icon_str##arguments.dataSection.meta.title#</a>";
	}

	private string function sectionMenu(required struct data, required array sections, boolean preview=false, string class="") localmode=true {
		className = arguments.class eq "" ? "" : " class='#arguments.class#'";
		menu = "<ul#className#>";

		for (code in arguments.sections) {
			section = arguments.data[code];
			title = section.meta.title ? : code;
			submenu = "";
			if (section.keyExists("sections") AND ArrayLen(section.sections)) {
				submenu = sectionMenu(data=arguments.data, sections=section.sections, preview=arguments.preview, class="submenu");
			}
			link = sectionLink(section=code,preview=arguments.preview);
			hasContent = section.hasContent ? : true;
			href = hasContent ? " href='#link#'" : "";
			class = hasContent ? "" : " class='menu_section'";
			menu &= "<li><a id='menu_#code#'#href##class#>#title#</a>#submenu#</li>";
		}

		menu &= "</ul>";

		return menu;
	}

	// Format page link
	public string function formatLink(required string section, string anchor, string type="preview") {

		if (arguments.type eq "page") {
			if (arguments.anchor neq "") {
				return "##" & arguments.anchor;
			}
			else {
				return "##" & arguments.section;
			}
		}

		preview = arguments.type eq "preview";

		return sectionLink(argumentCollection = arguments, preview = preview);

	}

	// Get link for a page 
	public string function sectionLink(required string section, string anchor, boolean preview=false) {
		link =  arguments.preview ? "?section=#arguments.section#" : "#arguments.section#.html";
		if (arguments.keyExists("anchor") ) {
			link &= "##" & arguments.anchor;
		}
		return link;
	}

	/**
	 * @hint Return a query to update a lucene search index
	 */
	public query function searchQuery(required struct document) localmode=true {

		data = queryNew("key,title,body,page,id");

		for (code in arguments.document.data) {
			section = arguments.document.data[code];
			pageSections = [=];
			node = Duplicate(section.node);
			
			tags = node.select("h2,h3,h4,h5,h6,p,ul,ol");
			id = section.id;
			title = section.meta.title;
			for (tag in tags) {
				tagName = tag.tagName(); 
				if (tagName eq "H2" OR tagName eq "H3") {
					id = tag.attr("id");
					title = tag.text();

					continue;
				}
				if (! pageSections.keyExists(id) ) {
					pageSections["#id#"] = {"text"="","title"=title};
				}
				pageSections[id]["text"] &= tag.text();
			}
			
			try{
				for (id in pageSections ) {
					queryAddRow(data, {
						"key" = code,
						"title" = pageSections[id].title,
						"body" = pageSections[id].text,
						"page" =  pageSections[id].title eq section.meta.title ? "" : section.meta.title,
						"id" = id
					});
				}
			} 
			catch (any e) {
				local.extendedinfo = {"tagcontext"=e.tagcontext,"section"=section};
				throw(
					extendedinfo = SerializeJSON(local.extendedinfo),
					message      = "Unable to add section to query:" & e.message, 
					detail       = e.detail
				);
			}
		}

		return data;

	}

	/**
	 * @hint A utility function to generate index files from a directory structure
	 */
	public struct function generateIndex(required string filepath) localmode=true {
		path = getCanonicalPath(arguments.filepath);
		if (right(path,1) eq "\") path = Left(path, len(path) - 1);

		filelist = directoryList(path, true, "query", "*.md");

		data = [ "index" = []];
		for (row in filelist ) {
			dir = Replace( Replace(row.directory,path,""), "\", "");
			if (row.name eq "index.md") {
				if (dir != "") {

					data["index"].append( dir & "\index.md" );
				}
			}
			else {
				if (! data.keyExists(dir) ) {
					data[dir] = [];
				}
				data[dir].append(row.name);
			}
			
		}
		
		for (code in data) {
			dirList = newLine();
			for (filename in data[code]) {
				dirList &= "<div href='#filename#' />" & newLine();
			}
			if (code eq "index") {
				filePath = path & "\index.md";
			}
			else {
				filePath = path & "\" & code & "\index.md";
			}

			fileAppend(filePath, dirList);

		}

		return data;

	}

	public void function logger(required text, type="I", category="") output=false {
 		if (StructKeyExists(this,"loggerObj")) {
 			this.loggerObj.log(argumentCollection = arguments);
 		}
 	}

}
