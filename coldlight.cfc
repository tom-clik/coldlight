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
		temp = parseText(text=text, filepath=filepath, data=data, contents=contents);
		setHierarchy(data=data,sections=temp.sections);

		returnVal["sections"] = temp.sections;
		returnVal["meta"] = temp.meta;
		returnVal["data"] = data;
		returnVal["contents"] = contents;

		if ( Trim( temp.node.body().html() ) neq "" ) {
			id = ListFirst( ListLast(arguments.filename,"\/"), "." );
			returnVal["meta"]["home"] = id;
			returnVal["data"]["#id#"] = {
				"id" = id,
				"meta" = {"title": temp.meta.title },
				"node" = temp.node
			}
		}
		else {
			returnVal["meta"]["home"] = returnVal["sections"][1];
		}

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

		temp = variables.markdown.markdown(text=arguments.text,options={"meta"=false});
		temp.node.outputSettings().charset("UTF-8");
		
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

				subsection = parseText(text= section_text, filepath=arguments.filepath,data=arguments.data, contents=arguments.contents);

				// parse text is a variable -- not part of the main flow
				if (info.attributes.meta) {
					retVal.meta["#info.attributes.id#"] = subsection.node.body().html();
					continue;
				}

				subsection["id"] = info.attributes.id;

				tmp = duplicate(subsection.contents);

				// add section name to content items before appending to complete record
				for (headingid in subsection.contents) {
					StructAppend(tmp[headingid], {"section" = info.attributes.id}, false);
				}

				StructAppend(arguments.contents, tmp, false);

				// Remove first h1 if it was the title
				title = subsection.node.select("h1");
				if ( ArrayLen(title) && title.text() eq subsection.meta.title) {
					title.remove();
				}
				
				arguments.data["#info.attributes.id#"] = subsection;
				retVal.sections.append(info.attributes.id);

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

		return retVal;

	}

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
	 * @footnotes  manually process footnotes and place end notes into meta var "footnotes"
	 *
	 */
	public string function html(required struct document, boolean footnotes=false, boolean XML=false, struct context={}) {
		
		local.html = "";
		
		if (arguments.footnotes) {
			// track footnotes
			local.noteshtml = [];
			local.notecount = 0;
		}

		for (local.id in arguments.document.sections) {

			local.doc = arguments.document.data[local.id];
			node = duplicate(local.doc.node);
			updateXrefs(node=node,contents=arguments.document.contents,preview=false,usePage=0);

			if (arguments.XML) {
				node.outputSettings(variables.coldsoup.XML); 
			}

			if (arguments.footnotes) {
				local.notes = node.select( "span.footnote" );

				for (local.note in local.notes) {
					local.notecount++;
					local.noteshtml.append( "<p><a id=""footnote-#local.notecount#"" href=""##footnote-#local.notecount#-ref""><strong>#local.notecount#</strong></a> #local.note.html()#</p>");
					local.note.html( "<a id=""footnote-#local.notecount#-ref"" href=""##footnote-#local.notecount#""><sup>#local.notecount#</sup></a>" );
				}
			}

			local.section_html = node.body().html();

			if (StructKeyExists(local.doc,"meta")) {
				local.section_html = replaceVars(local.section_html, local.doc.meta);
			}

			local.html &= "<section id='section_#local.id#'>";
			local.html &= "<h1 id='#local.id#'>#local.doc.meta.title#</h1>";
			local.html &= local.section_html;
			local.html &= "</section>";
			
		}

		if (arguments.footnotes && local.notecount) {
			arguments.context["footnotes"] = local.noteshtml.toList( newLine() );
		}


		if (StructKeyExists(arguments.document,"meta")) {

			local.html = replaceVars(local.html, arguments.document.meta);
		}

		return local.html;

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
			
			linkid = ListLast(link.attr("href"),"##");
			
			if (StructKeyExists(arguments.contents,linkid)) {
				text = link.text();
				if (trim(text) eq "" OR link.hasClass("auto")) {
					linkData = arguments.contents[linkid];
					href = sectionLink(section=linkData.section, anchor=linkid, preview=arguments.preview);
					link.attr("href", href);
					link.html(linkData.text);
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
	 * @contents      Struct of headings
	 */
	public string function TOC(required struct document, numeric toclevel=2) localmode=true {
		
		html = "";

		for (id in arguments.document.sections) {
			
			level = 1;	
			sectionObj =  arguments.document.data[id];
			
			html &= "    <p class='toc#level#'><a href=""###id#"">#sectionObj.meta.title#</a></p>" & newLine();

			if (arguments.toclevel gt 1) {
				level = 2;	
				if (sectionObj.keyExists("sections") ) {
					for (sub_id in sectionObj.sections) {
						subSectionObj =  arguments.document.data[sub_id];
						html &= "    <p class='toc#level#'><a href=""###sub_id#"">#subSectionObj.meta.title#</a></p>" & newLine();
						if (arguments.toclevel gt 2) {
							for (heading_id in subSectionObj.contents) {
								heading = subSectionObj.contents[heading_id];
								level = heading.level + 1;
								if (level gt 2 && level lte ( arguments.toclevel ) ) {
									html &= "    <p class='toc#level#'><a href=""###heading_id#"">#heading.text#</a></p>" & newLine();
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

		// this isn't great. IMages assumed to be in /images but see below, stylesheets have paths
		// TODO: standardise, use one methodology
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

	public struct function saveSite(required struct document, required string template, required string outputDir, struct site={} ) localmode=true {

		returnVal = {};

		// TODO: this will all be common to the preview stuff
		context = duplicate(arguments.document.meta);
		template = FileRead(arguments.template);
		context["site"] = duplicate(arguments.site);

		context["site"]["menu"] = sectionMenu(data=arguments.document.data, sections=arguments.document.sections);
		context["site"]["home_link"] = sectionLink(section=arguments.document.meta.home, preview=false);

		sectionList = structKeyArray(arguments.document.data);

		// Home page might have text in its own right, save it as a file
		if (! arguments.document.data.keyExists(arguments.document.meta.home) ) {
			sectionList.append(arguments.document.meta.home);
		}

		for (code in sectionList) {
		
			sectionObj = arguments.document.data[code];

			
			// TODO: parent section values
			context["page"] = getPage(document=arguments.document,section=code);
			context["page"].body = Replace(context["page"].html,"{{","X&X^AA%A%","all");
			context["page"]["section"] = {
				"id" = code,
				"parent" = sectionObj.parent ? : "",
			};

			// TODO: formalise all this stuff
			// section menu
			if ( sectionObj.keyExists("sections") ) {
				context["page"]["section"]["menu"] = sectionMenu(data=arguments.document.data, sections=sectionObj.sections);
			}

			html = variables.mustache.render(template=template, context=context);
			html = Replace(html,"X&X^AA%A%","{{","all");

			fileName = getCanonicalPath(arguments.outputDir & "/" & sectionObj.id & ".html");
			fileWrite(fileName, html);
			
			returnVal["#sectionObj.id#"] = 1;
		
		}

		searchSymbols = getHeadingData(arguments.document);
		searchSymbolsJS = "symbols = " & serializeJSON(searchSymbols) & ";" & newLine();
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

	private struct function getPage(required struct document, required string section, boolean preview = false ) localmode=true {

		sectionData = arguments.document.data[arguments.section];
		node = duplicate(sectionData.node);
		updateXrefs(node=node,contents=arguments.document.contents,preview=arguments.preview,usePage=1);

		page = {
			"title" = sectionData.meta.title,
			"page_title" = sectionData.meta.page_title ? : sectionData.meta.title,
			"html" = node.body().html(),
		};

		page.html = replaceVars(page.html, sectionData.meta);
		page.html = replaceVars(page.html, arguments.document.meta);
		
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
			navList.append(code);
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
			menu &= "<li><a id='menu_#code#' href='#link#'>#title#</a>#submenu#</li>";
		}

		menu &= "</ul>";

		return menu;
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

		data = queryNew("key,title,body,parent,custom2");
		for (code in arguments.document.data) {
			section = arguments.document.data[code];
			try{
				
				
				queryAddRow(data, {
					"key" = code,
					"title" = section.meta.title,
					"body" = section.html,
					"parent" = section.parent ? : "",
					"custom2" = ""
				});
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

}
