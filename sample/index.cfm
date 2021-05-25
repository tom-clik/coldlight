<cfscript>
// pages in this model don't output anything. You can include instructions for your general framework.

request.page = application.coldLight.getPage(pub=request.pub,code=request.code);

request.content.title = request.page.title;

request.buildPage = 1;

</cfscript>
