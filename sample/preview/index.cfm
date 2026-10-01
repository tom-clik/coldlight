<cfscript>

param name="request.rc.section" default="index";

// allow for easy preview from e.g. Sublime Text
request.rc.section = ListFirst(request.rc.section,"/.");


html = application.coldlightObj.pageHTML(document= application.document, section=request.rc.section,context=application.context,template=application.template,preview=true);

writeOutput(html);

</cfscript>