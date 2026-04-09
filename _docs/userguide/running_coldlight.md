---
title:	Running ColdLight
author: Tom Peer
toc_level: 1
---

How you run ColdLight depends on your workflow. Essentially all usage involves loading the "publication" and then chosing an export method.

## Instantiating the component

ColdLight is designed as a singleton component. It can be loaded into a shared scope, e.g. `application`. Essentially all methods are static, and require you to pass in the loaded "document", see following

Assuming you have successfully installed the JARs and the helper components, it can be instantiated thus:

```
coldLightObj = new coldlight.coldlight(jarpath=flexmarkPath,jsoupJar=jsoupJarPath);
```

## Loading

A ColdLight publication is a struct with parsed markdown and meta data. 

To load a publication, use the load method pointed at your [index](ColdLight_Documents) file.

```
docObj = coldLightObj.load( filePath );
```

See `testing\testLoad.cfm` for an example.

## Exporting a static site

The most common usage is to generate a static site, and this can be done simply with the `staticSite` method.

This takes a document, a [template]()

site = coldLightObj.staticSite(document=data,template=template,outputDir=outputDir,site=site_data);


## Generating an Ebook




## Code Examples

There are several exampe

### Process.cfm

In `/testing` there is a script `process.cfm`. This is the go to script if you are using multiple ColdLight publications. You can create config files in the folder with the details of the source, the templates, and the required outputs. These can then be referenced by the code.

There are samples for `resume.json` (a sample resume) , `guide.json` (the ColdLight guide), and `bok.json`

Previewing the script without `url.code` will list all the config files in the folder allowing for quick selection.

### Preview app

Also in `/testing/preview` is a sample application for live preview of a site. By default it shows the user guide but it's configure to accept `url.code` to use one of the config files as described in the previous section.

This will automatically reload the document when you make changes to the markdown source.


