<div id="ubercontainer">
	<div id="header" class="header spanning">
		<div class="inner">
			<div id="sitetitle" class="scheme-title">
				<a href="index.cfm">
					<cfoutput>#application.pageObj.site.title#</cfoutput>
				</a>
			</div>
			<div id="breadcrumb" class="cs-breadcrumb">
				<ol class="breadcrumb">
					<li class="breadcrumb-item"><cfoutput><a href="#application.coldlight.getLink(pub=request.pub,code='index',cache=request.cache)#">#request.page.publication#</a></cfoutput></li>
					<li class="breadcrumb-item active"><cfoutput>#request.page.title#</cfoutput></li>
				</ol>
			</div>
			<div id="search">
				<input type="text"autocomplete="off" id="fuzzySearch" placeholder="Search..." name="search" class="form-control search-input">
				<button type="submit" class="btn search-btn" value="Search"><i class="fa fa-search"></i></button>
			</div>
			<div id="searchResults" class="empty">
			</div>
			<div id="hamburger" class="icon icon-big">
				<a href="#mainmenu">a</a>
			</div>
		</div>

	</div>

	<div id="content" class="spanning">
		
		<div class="inner">
			<div id="columns">
				<div id="subcol" class="hasSticky">
						<div id="mainmenu" class="cs-menu menu-vertical">
							<div id="mobileclose" class="icon icon-big">
								<a href="#top">M</a>
							</div>
							<div class="cs-menu scheme-vertical scheme-main">
								<cfoutput>#application.coldLight.pubMenu(pub=request.pub,selected=request.code,cache=request.cache)#</cfoutput>
							</div>
						</div>
					
				</div>

				<div id="maincol">
						
					<div id="maincol_top">	
						<div id="pageContent">
							<div class="pageTitle">
								<h1><cfoutput>#request.page.title#</cfoutput></h1>
							</div>
							<div class="pageBody">
								<cfoutput>#request.page.content_html#</cfoutput>
							</div>
						</div>

					</div>
					<div id="maincol_bottom">		
						<div class="navButtons">
							<div id="previous" class="previousnext previous">
								<cfif request.page.previous neq "">
									<cfoutput><a href=#request.page.previous_link#>#request.page.previous#</a></cfoutput>
								</cfif>
							</div>
							<div id="next" class="previousnext next">
								<cfif request.page.next neq "">
									<cfoutput><a href=#request.page.next_link#>#request.page.next#</a></cfoutput>
								</cfif>
							</div>
						</div>
					</div>	
					
				</div>

				<div id="xcol" class="hasSticky">
					
					<div id="pagemenu" class="cs-menu menu-vertical">
						<cfoutput>#application.coldLight.getPageHeadings(page=request.page)#</cfoutput>
					</div>
						
					
				</div>
			</div>
			
		</div>	
	</div>         

	<div id="footer" class="spanning">
		<div class="inner">
			<small class="copyright"><cfoutput>#application.pageObj.site.copyright#</cfoutput></small>
		</div>
	</div>
		
</div>

<cfscript>
// fuzzy logic symbols
if (request.cache) {
	application.pageObj.addJs(request.content,"../_scripts/searchSymbols.js");
}
else {
	application.pageObj.addJs(request.content,"search.cfc?method=searchSymbols");
}

request.content.static_js["search"] = 1;
request.content.static_js["menuScroll"] = 1;

request.content.onready &= "

$(""##submenu"").menuScroll();

/* to do: move most of this to a plug in */
$(""##fuzzySearch"").on(""keydown"",
		function(e) {
			if (e.key === 'Enter') {
				e.preventDefault();
				e.stopPropagation();
			}
		})
	.on(""keyup"",function(e) {
		e.preventDefault();
		e.stopPropagation();
		var auto = false;
		console.log(e.key);
		if (e.key === 'Escape') {
			$(this).val("""");
		}
		else if (e.key === 'Enter') {
			auto = true;
		}

		search($(this).val(),$(""##searchResults""), #request.cache#, auto);
	});

";
</cfscript>
