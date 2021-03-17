component name="coldlight" extends="utils.utils" {
	
	/**
	 * @hint      Pseudo constructor
	 *
	 * @filepath  File path of app definition. 
	 *
	 */
	public coldlight function init(required array appDef) {

		variables.markdown = CreateObject("component", "markdown.flexmark").init();
		
		this.menuClasses = "nav doc-menu";
		this.metaVars = {};
		
		variables.patternObj = CreateObject( "java", "java.util.regex.Pattern" );
		variables.pattern = variables.patternObj.compile("(?m)^@[\w\[\]]+\.?\w*\s+.+?\s*$",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);
		variables.varpattern = variables.patternObj.compile("(?m)\{\$\w*\_\w*\}",variables.patternObj.MULTILINE + variables.patternObj.UNIX_LINES);

		parseAppDef(arguments.appDef);
		
		return this;
	}

	private void function parseAppDef(required array appDef) {

		variables.pubs = {};
		variables.publist = [];
		this.data = {};

		for (local.pub in arguments.appDef) {
			checkPub(local.pub);
			ArrayAppend(variables.publist,local.pub.code);
			variables.pubs[local.pub.code] = local.pub;
		}
	}

	/** Check validity for publication definition
	*/
	private void function checkPub(required struct pubDef) {
		local.err = "";
		if (! StructKeyExists(arguments.pubDef, "code")) {
			local.err &= "<p>No code defined</p>";
		}
		if (! StructKeyExists(arguments.pubDef, "title")) {
			local.err &= "<p>No title defined</p>";

		}
		if (! StructKeyExists(arguments.pubDef, "path")) {
			local.err &= "<p>No path defined</p>";
		}

		if (! DirectoryExists(arguments.pubDef["path"])) {
			local.err &= "<p>Path not found</p>";
		}

		if (local.err != "") {
			local.err = local.err & serializeJSON(arguments.pubDef);
			throw(message="Error parsing pubDef",detail=local.err);
		}
	}
	/**
	 * @hint      Check any @meta vars and add to meta struct
	 * 
	 * Variables can be added to the documentscope with the syntax @varname  Value
	 * 
	 * 
	 * @text  The text
	 * @meta  Meta struct to update
	 *
	 * @return     text with vars removed
	 */
	private string function checkAlphaMeta(required string text, required struct meta) {
		
		local.sectionsObj = variables.pattern.matcher(text); 
		
		local.tags = [];
		local.str = false;

		// get all alphmeta definiions
		while (local.sectionsObj.find()){
		    ArrayAppend(local.tags, local.sectionsObj.group());
		}

		// VARS shouldn't have underscores in them. In case they do we have to do this
		local.dodgyVarsToReplace = {}; 
		local.dodgyVars = variables.varpattern.matcher(text); 
		while (local.dodgyVars.find()){
			local.dodgyVarsToReplace[local.dodgyVars.group()] =1;
		}

		for (local.str in local.dodgyVarsToReplace) {
			local.replaceStr = Replace(local.str,"_","%%varUndrscReplace%%","all");
			arguments.text = Replace(arguments.text,local.str,local.replaceStr,"all");	
		}

		for (local.str in local.tags) {
			//split on first whitespace
			local.trimStr = Trim(local.str);
			local.tag = ListFirst(local.trimStr," 	");
			local.data = ListRest(local.trimStr," 	");
			local.tagRoot = ListFirst(local.tag,"@.[]");
			if (ListLen(local.tag,"@.") gt 1) {
				// Struct property assignement
				local.tagProperty = ListRest(local.tag,"@.");
				if (NOT StructKeyExists(arguments.meta,local.tagRoot)) {
					arguments.meta[local.tagRoot] = {};
				}
				if (NOT IsStruct(arguments.meta[local.tagRoot])) {
					throw('You have tried to assign a property a value that is not in an struct [#local.tag#]')
				}
				arguments.meta[local.tagRoot][local.tagProperty] = local.data;
			}
			else {
				// array append value
				if (right(local.tag,2) eq "[]") {
					if (NOT structKeyExists(arguments.meta,local.tagRoot)) {
						arguments.meta[local.tagRoot] = [];
					}
					if (NOT isArray(arguments.meta[local.tagRoot])) {
						throw('You have tried to append array data to a value that is not an array [#local.tag#]')
					}
					ArrayAppend(arguments.meta[local.tagRoot],local.data);
				}
				else {
					// simple value
					arguments.meta[local.tagRoot] = local.data;
				}
			}

			arguments.text = Replace(arguments.text,local.str,"",1);
		}

		return arguments.text;

	}

	public string function replaceAlphaMeta(required string text, required struct meta) {
		
		arguments.text = REReplace(arguments.text,"%%varUndrscReplace%%","_","all");

		local.arrVarNames = REMatch("\{\$[^}]+\}",arguments.text);
		
		local.sVarNames = {};

		
		// create lookup struct of all vars present in text. Only defined ones are replaced.
		for (local.i in local.arrVarNames) {
			local.varName = ListFirst(local.i,"{}$");			
			
			if (ListLen(local.varName,".") gt 1) {
				// syntax with e.g. meta.title not brilliant to work with
				local.parentName = ListFirst(local.varName,".");
				local.keyName = ListLast(local.varName,".");
				if (StructKeyExists(arguments.meta, local.parentName)) {
					if (StructKeyExists(arguments.meta[local.parentName],local.keyName)) {
						local.sVarNames[local.varName] = arguments.meta[local.parentName][local.keyName];
					}
				}
			}
			else {
				if (StructKeyExists(arguments.meta, local.varName)) {
					local.sVarNames[local.varName] = arguments.meta[local.varName];
				}
			}
		
		}
		
		for (local.varName in local.sVarNames) {
			// possible problem with referencing complex values.
			if (IsSimpleValue(local.sVarNames[local.varName])) {
				arguments.text = ReplaceNoCase(arguments.text,"{$#local.varName#}", local.sVarNames[local.varName],"all");
			}
		}
		
		return arguments.text;

	}

	/**
	 * @hint      Parse a folder of docs
	 *
	 * Requires toc.md and index.md
	 * 
	 * @path  The path
	 *
	 */
	private void function parseFolder(required string path, required string pub) {

		this.data[arguments.pub] = {"pages"={},"orderedIndex"=[],"metaVars"={}};

		if (NOT DirectoryExists(arguments.path)) {
			throw("Path #arguments.path# not found");
		}

		local.autotoc = NOT FileExists(arguments.path & "\toc.md");
		local.hasIndex = FileExists(arguments.path & "\index.md");

		local.meta = {};

		if (local.hasIndex) {
			local.mdtext =  FileRead(arguments.path & "\index.md","utf-8");
			local.mdtext = checkAlphaMeta(text=local.mdtext,meta=this.data[arguments.pub].metaVars);
			this.data[arguments.pub]["pages"]["index"] = markdownToHTML(local.mdtext);
		}

		if (!local.autotoc) {
			local.doc = parse(arguments.path & "\toc.md");
			local.tocDom = variables.markdown.coldsoup.parse(local.doc.html);
		}
		else {
			throw("Auto toc func not complete");
		}

		var nodes = local.tocDom.getElementsByTag("a");
		
		var currentLevel = 1;
		var parent = "";
		var row = false;

		// loop over each entry in the toc and parse
		for (var node in nodes) {
			row = variables.markdown.coldsoup.getAttributes(node);
			local.entry = Duplicate(row);

			// extension optional
			if (ListLen(local.entry.href,".") < 2 ) {
				local.filename = local.entry.href &  ".md";
				local.id = local.entry.href;
			} else {
				local.id = ListFirst(local.entry.href,".");
				local.filename = local.entry.href;
			}
			if (! StructKeyExists(local.entry,"id")) {
				local.entry.id = local.id;
			}

			local.doc =  parse(arguments.path & "\" & local.filename);

			// meta data comes from here
			// e.g. meta.title
			StructAppend(local.entry,local.doc);
			
			this.data[arguments.pub]["pages"][local.entry.id] = local.entry;

			ArrayAppend(this.data[arguments.pub].orderedIndex,local.entry.id);
		}

		this.data[arguments.pub].metaVars["toc"] = getTOChtml(pub=arguments.pub, id="toc");
	
	}

	/**
	 * @hint Create markdown doc struct
	 * 
	 * Also apply any coldlight specific formatting
	 *
	 */
	public struct function markdownToHTML(string text) {
		local.retVal = variables.markdown.markdown(arguments.text);
		local.retVal.html = Replace(local.retVal.html," -- ", " &ndash; ","all");
		return local.retVal;
	}

	/**
	 * @hint      Parse an indivdual file
	 *
	 */
	public struct function parse(required string path) {
		if (NOT FileExists(arguments.path)) {
			throw("File #arguments.path# not found");
		}
		local.data = FileRead(arguments.path,"utf-8");
		return markdownToHTML(local.data);
	}

	/** get an HTML list representation of the TOC
	*/
	public string function getTOChtml(required string pub, string selected="", string id="main_menu",boolean cache=false) {

		local.menu = "<nav id='#arguments.id#' class='#this.menuClasses#'>";
		local.pubdata = this.data[arguments.pub];

		for (local.id in local.pubdata.orderedIndex) {

			local.isSelected = arguments.selected == local.id;
			// do submenu first as selected may be a sub item (functionality not complete)
			local.submenu = "";
			local.page = getPageData(arguments.pub, local.id);

			for (local.row in local.page.meta.toclist) {
				local.rowdata = local.page.meta[local.row];
				if (local.rowdata.level == 2) {
					local.submenu &= "<a class='nav-link scrollto toc2' href='" & getLink(pub=arguments.pub,code=local.id,anchor=local.row,cache=arguments.cache) &"'>#local.rowdata.text#</a>";
				}
			}

			local.selectedClass = local.isSelected ? " selected" : " notselected";
			local.menu &= "<div class='menuItem #local.selectedClass#'>";

			try {
			local.menu &= "<a class='nav-link scrollto toc1' href='" & getLink(pub=arguments.pub,code=local.id,cache=arguments.cache) & "'>#local.page.meta.meta.title#</a>";
			}
			catch (Any e) {
				writeOutput("Unable to generate toc entry for this file");
				writeDump(local.page);
				abort;
			}
			
			if (local.submenu != "") {
				local.menu &= "<nav class='doc-sub-menu nav flex-column'>" & local.submenu & "</nav>";
			}
			local.menu &= "</div>";

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

	/** @hint get an HTML for publication menu
	 * 
	 * If there is only one publication the CSS needs to take care of this. Func TBC
	 * 
	 */
	public string function pubMenu(string pub="", string selected="", string id="main_menu",boolean cache=false) {

		local.menu = "<nav id='#arguments.id#' class='#this.menuClasses#'>";
		
		local.multiMode = (ArrayLen(variables.publist) > 1);

		for (local.pub in variables.publist) {

			local.isSelected = arguments.pub == local.pub;
			local.class = local.isSelected ? " selected" : " notselected";
			if (! local.multiMode) {
				local.class  = listAppend(local.class, "single", " ");
			}
			local.menu &= "<div class='menuItem #local.class#'>";

			

			if (local.multiMode) {

				try {
					local.menu &= "<a class='nav-link scrollto' href='" & getLink(pub=local.pub,code="index",cache=arguments.cache) & "'>#variables.pubs[local.pub].title#</a>";
				}

				catch (Any e) {
					throw("Unable to generate toc entry for this file");
				}
			
			}

			
			
			
			if (StructKeyExists(this.data,local.pub)) {

				local.pubdata = this.data[local.pub];
				local.pages = local.pubdata.orderedIndex;
				
				if (!local.multiMode) {
					ArrayPrepend(local.pages,"index");
				}
				
				local.submenu = "";

				for (local.id in local.pages) {

					local.page = getPageData(local.pub, local.id);
					local.submenu &= "<a class='nav-link scrollto' href='" & getLink(pub=local.pub,code=local.id,cache=arguments.cache) & "'>#local.page.meta.meta.title#</a>";
					
				}

				if (local.submenu != "") {
					if (local.multiMode) {
						local.menu &= "<nav class='doc-sub-menu nav flex-column'>" & local.submenu & "</nav>";
					}
					else {
						local.menu &= 	local.submenu;
					}
				}
			}

			local.menu &= "</div>";


		}

		local.menu &= "</nav>";
		
			
		return local.menu;
	}

	/**
	 * @hint   Get array of publication codes
	 *
	 * @reset  Reload the docs
	 *
	 * @return  Arry of codes
	 */
	public array function getPubs(boolean reset=false) {
		if (arguments.reset) {
			for (local.code in variables.publist) {
				local.pubDef = variables.pubs[local.code];
				parseFolder(local.pubDef.path, local.pubDef.code);
			}
		}
		return variables.publist;
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
	 * @brief      Gets the page.
	 *
	 * @pub        The publication code
	 * @code       The page code
	 * @cache      Cache result (not implemented)
	 * @footnotes  Use HTML footnotes (false will inline footnotes for PDF)
	 *
	 * @return     The page.
	 */
	public struct function getPage(required string pub, required string code, boolean cache=0, boolean footnotes=1) {

		local.page = getPageData(pub=arguments.pub,code=arguments.code);
		
		var retVal = {
			"meta" = local.page.meta,
			"publication" = variables.pubs[arguments.pub].title,
			"code" = arguments.code,
			"title" = local.page.meta.meta.title,
			"content" = "",
			"content_html" = local.page.html,
			"chapter_link" = "",
			"level" = 1,
			"next" = "",
			"next_link" = "",
			"chapter_link" = "",
			"previous" = "",
			"previous_link" = "",
			"next_chapter" = "",
			"nextchapterlink" = "",
			"previous_chapter" = "",
			"previouschapterlink" = ""
		};

		retVal.linksDebug = "";
		
		local.node = variables.markdown.coldsoup.parse(retVal.content_html);

		// remove heading
		local.node.select("h1").first().remove();
		
		// get automatic cross references
		local.links = local.node.select("a");
		
		for (local.link in local.links) {
			
			retVal.linksDebug &= "<p>Link found #local.link.attr("href")#: #local.link.text()#</p>";
			local.href = local.link.attr("href");


			
			if (Left(local.href,1) == "##") {
				// flexmark does a weird thing where it adds an href to all anchors 
				// that link to themselves
				local.id = local.link.attr("id");
				if (IsDefined("local.id")) {
					if (local.id == ListFirst(local.href,"##")) {
						local.link.removeAttr("href");
						continue;
					}
				}
				// if it's an anchor, make it a consistent format
				// with the page code before the anchor
				local.href = arguments.code & local.href;
			}

			if (! Left(local.href,4) == "http" ) {
				
				local.code = ListFirst(local.href,"##");
				
				local.link_text = Trim(local.link.text());


				// get cross refs if poss
				local.autotext = (local.link_text == "");
				
				retVal.linksDebug &= "<p>autotext: " & local.autotext  & "</p>";
				
				if (local.autotext) {
					
					try {
						local.linkpage = getPageData(pub=arguments.pub,code=local.code);
					}
					catch (any e) {
						throw(message="Unable to get auto text for link #local.href#",detail="If this format is correct the publication may not be loaded. Either supply the text explicitly or preload the publication");
					}

					local.link_text = local.linkpage.meta.meta.title;
					retVal.linksDebug &= "<p>page text is: " & local.link_text  & "</p>";

				}

				if (ListLen(local.href,"##") > 1) {
					local.anchor = ListLast(local.href,"##");
					// update autotext with correct text for anchor heading
					if (local.autotext) {
						if (StructKeyExists(local.linkpage.meta, local.anchor)) {
							local.link_text = local.linkpage.meta[local.anchor].text;
							retVal.linksDebug &= "<p>anchor text is: " & local.link_text  & "</p>";
						}
						else {

							retVal.linksDebug &= "<p>no anchor text found for #local.anchor# in page #local.code#</p>";
							retVal.linksDebug &= serializeJSON(local.linkpage.meta);
						}
					}
				}
				else {
					local.anchor = "";
				}

				local.link.html(local.link_text);
				
				local.link.attr("href",getLink(pub=arguments.pub,code=local.code,anchor=local.anchor,cache=arguments.cache));
				
				if (local.autotext) {
					retVal.linksDebug &= local.link.outerHtml();
				}

			}

		}

		/**
		 *
		 * Footnotes look like this. 
		 * 
		 * Loop over each one, find the "call" (sup id="fnref-1") and replace tje whole node
		 * 
		 * <div class="footnotes"> 
			 <hr> 
			 <ol> variables.markdown.coldsoup.
			  <li id="fn-1"> <p>You may want to investigate something like a CSS <em>pre-processor</em> to solve this problem or just write your own code in PhP or similar to reduce the amount of duplication</p> <a href="../princeguide/headers_footers.html#fnref-1" class="footnote-backref">↩</a> </li> 
			 </ol> 
			</div>

		 */
		if (! arguments.footnotes) {
			local.footnotesDiv = local.node.select(".footnotes");
			if (ArrayLen(local.footnotesDiv)) {
				local.footnotes = local.footnotesDiv.first().select("li");
				if (ArrayLen(local.footnotes)) {
					for (local.footnote in local.footnotes) {
						// fn-1
						local.num = ListLast(local.footnote.attr("id"),"-");
						// remove backlink
						local.backref =  local.footnote.select(".footnote-backref");  
						for (local.link in local.backref) {
							local.link.remove();
						}
						local.paras =  local.footnote.select("p");  
						for (local.para in local.paras) {
							local.para.unwrap();
						}

						local.marker = local.node.select("##fnref-#local.num#").first();
						if (IsDefined("local.marker")) {
							local.fnNode = variables.markdown.coldsoup.createNode("a",local.footnote.html());
							local.fnNode.addClass("footnote");
							// writeDump(local.fnNode);
							// writeDump(local.marker);
							// abort;
							local.marker.replaceWith(local.fnNode);

						}
					}
				}
				local.footnotesDiv.remove();
			}





		}


		// get fixed html back from jsoup
		retVal.content_html = local.node.body().html();

		// replace meta vars
		retVal.content_html = replaceAlphaMeta(retVal.content_html,this.data[arguments.pub].metaVars);

		local.orderedIndex = this.data[arguments.pub].orderedIndex;

		// previous and next links
		local.index = ArrayFind(local.orderedIndex,arguments.code);

		if (local.index == -1) {
			throw("#arguments.code# not found in #ArrayToList(local.orderedIndex)#");
		}
		
		if (local.index < ArrayLen(local.orderedIndex)) {
			local.nextCode = local.orderedIndex[local.index + 1];
			retVal.next_link = getLink(pub=arguments.pub,code=local.nextCode,cache=arguments.cache);
			retVal.next = getPageData(pub=arguments.pub,code=local.nextCode).meta.meta.title;
		}

		if (local.index > 1) {
			local.previousCode = local.orderedIndex[local.index - 1];
			retVal.previous_link = getLink(pub=arguments.pub,code=local.previousCode,cache=arguments.cache);
			retVal.previous = getPageData(pub=arguments.pub,code=local.previousCode).meta.meta.title;
		}

		return retVal;
	
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
		
		local.multiMode = (ArrayLen(variables.publist) > 1);

		if (arguments.cache) {
			local.link = (local.multiMode ? "../#arguments.pub#/" : "" ) & "#arguments.code#.html";
		}
		else {
			local.link = "?pub=#arguments.pub#&code=#arguments.code#";
		}

		local.link &= (arguments.anchor == "" ? "" : "##" & arguments.anchor );
		
		return local.link;

	}


}
