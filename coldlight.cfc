component name="coldlight" {
	
	/**
	 * @hint      Pseudo constructor
	 *
	 * @filepath  File path of app definition. 
	 *
	 */
	public coldlight function init() {

		variables.markdown = new markdown.flexmark(attributes=true);
		variables.coldsoup = new coldsoup.coldsoup();
		variables.patternObj = CreateObject( "java", "java.util.regex.Pattern" );
		variables.include_pattern = variables.patternObj.compile("\[include\s+file\s*\=\s*[\""\']?(\S+?)[\""\']\s*\]",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);
		variables.var_pattern = variables.patternObj.compile("(?m)\{\$\w*\_\w*\}",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);
		
		return this;
	}

	public struct function load(required string filePath) {

		if (NOT FileExists(arguments.filePath)) {
			throw("File #arguments.filePath# not found");
		}
		
		local.doc = {"text"="","docs"=[=],"meta"={}, "headings"=[]};

		local.doc.text = FileRead(arguments.filePath,"utf-8");
		local.includes = getIncludes(local.doc.text);
		local.rootPath =  getDirectoryFromPath(arguments.filePath);

		for (local.file in local.includes) {
			
			local.filename = local.rootpath & local.includes[local.file];
			local.meta = {};
			if ( FileExists( local.filename ) ) {
				local.text = FileRead( local.filename,"utf-8" );
				local.html = variables.markdown.toHtml(local.text,local.meta);
			}
			else {
				local.html = "";
			}
			
			local.doc.text = Replace(local.doc.text,local.file,local.html);
			StructAppend(local.doc.meta,local.meta,true);
			
		}

		local.doc.text = variables.markdown.toHtml(local.doc.text,local.doc.meta);

		local.doc.headings = getHeadings( local.doc.text );

		for (local.heading in local.doc.headings) {
			local.doc.meta["#local.heading.attributes.id#"] = local.heading.html;
		}



		return local.doc;

	}

	
	private array function getHeadings(required string text) {
		local.headings = [];
		local.temp = variables.coldsoup.parse(arguments.text);
		variables.coldsoup.unwrapHeaders(local.temp);
		local.nodes = local.temp.select("h1,h2,h3,h4,h5,h6");
		for (local.node in local.nodes) {
			local.headings.append( variables.coldsoup.nodeInfo(local.node) );
		}
		return local.headings;
	} 
	private struct function getIncludes(required string text) {

		local.vals = variables.include_pattern.matcher(arguments.text);

		local.fileNames  = {};
		while (local.vals.find()){
		    local.fileNames[local.vals.group()] = local.vals.group(javacast("int",1));
		}
		
		return local.fileNames;

	}
	
	
	/**
	 * @hint Create markdown doc struct
	 * 
	 * Also apply any coldlight specific formatting
	 *
	 */
	public string function markdownToHTML(required string text, required struct data ) {
		local.html = variables.markdown.toHtml(arguments.text, arguments.data);
		local.html = Replace(local.html," -- ", " &ndash; ","all");
		return local.html;
	}

	/** get an HTML list representation of the TOC
	*/
	public string function TOChtml(required struct doc) {

		local.menu = "<nav id='toc'>";
		local.toc_level = arguments.doc.meta.toc_level ? : 3;

		for (local.heading in arguments.doc.headings) {
			
			local.level = Replace(local.heading.tagName,"h","");
			// TODO: needs wrapping
			if (local.level lte local.toc_level) {
				
				local.menu &= "<p class='toc#local.level#'>" & local.heading.html & "</p>";
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

		local.menu &= "</nav>";		
			
		return local.menu;

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

	/**
	 * @hint      Get publication details
	 *
	 * @pub   The publication code
	 *
	 */
	public struct function getPub(required string pub) {
		return variables.pubs[arguments.pub];
	}

	
	/**
	 * @hint Get HTML for internal link
	 *
	 * @code    The publication code
	 * @code    The document code
	 * @anchor  Anchor within page
	 * @cache   generate static html link
	 *
	 * @return     The link.
	 */
	public string function getLink(required string pub, required string code,string anchor="", boolean cache=0) {
		
		
		
		return local.link;

	}


}
