# ColdLight Publications

A ColdLight app is one or more "publications". These appear in the left hand menu in the sample app. Only one publication will be expanded at any one time.

A ColdLight publication is specified via a "toc" file, which includes simple markdown, e.g.

```
[](gettingstarted)
[](coldLightmarkdown)
[](ColdLight_Documents)
[](coldlightdata)
[](pageObj)
[](fuzzy)
```

Each entry links to one markdown file with a single h1 tag. The order determines the order in which the entries appear in the menu.

You can also create an index file in the same folder name index.md. You don't have to do this and the first entry in the list will be used if not specified.

The toc links can be relative to the toc folder specified for the toc file.

## Loading ColdLight publications

For each pub, you need to specify a title, the code (used for navigation),and the path to the toc file. These are added to the array used to initalise ColdLight

A typical app might look like this:

```
local.appDef = [{"code"="coldlight","title"="Coldlight Demo",path=application.rootFolder}];

ArrayAppend(local.appDef,{"code"="princeguide","title"="PrinceXML","path"="D:\clik\dm\ClikWriter\PrinceXML"});

application.coldLight =  createObject("component", "coldlight.coldLight").init(local.appDef);
```

## Getting a ColdLight page

ColdLight only generates the "body" HTML and other elements to construct a page such as the title and links to the next pages. There are also methods to generate the menu HTML and link elements.

The sample app uses the Clik pagebuilder, and the two are designed to work together, but it's not a requirement.

A typical app might look like this.

```
request.prc.page = application.coldLight.getPage(pub=request.rc.pub,code=request.rc.code);
request.prc.content.title = request.prc.page.title;
```

For details of the page data returned by ColdLight, see the next section.
