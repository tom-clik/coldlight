<cfscript>

param name="request.rc.section" default="index";

html = application.coldlightObj.pageHTML(document= application.document, section=request.rc.section,context=application.context,template=application.template,preview=true);

writeOutput(html);

</cfscript>