# ColdLight Publications

A ColdLight publication consists of multiple markdown files that are combined using a single index file.

This uses a proprietary mechanism for defining the included files: `<div href="testing.md" />`. This is done to ensure file names are unique, permanent references without the numeric sort orders that similar systems use. There are also advantages when it comes to generation PDF and EPUB versions of the publication.

The index file can contain markdown text, but usually just has YAML data and includes. e.g.

```
---
author: Tom Peer
title: Test app
description: Testing application
toclevel: 2
---

<div href="gettingstarted.md" />
<div href="nextdoc.md" />
<div href="doc3.md" />
<div href="doc4.md" />
```

Any content added to the index page will be shown on the home page of the web site but not in the PDF or EPUB versions. If there is no content in the page, the first page of the web version will be the first section.

## Sub sections

A publication can be divided into subsections with sub-indices. These function like the main index -- if there is content, a page will be created for the section, otherwise the first page will be the first sub section. 

Typically the sections are divided into separate folders, but remember, these don't affect the document structure.

```
index.md
  |---intro/index.md
        |---installing.md
        |---configuring.md
  |---basics/index.md
```

Note that in the web site, all files are saved to the root and the "id" of the sub indices in the publication above paths would be `intro` and `basics`.

### Conversion from directory based systems

You can convert directory structure based systems to ColdLight using the `generateIndex` method of the component. This expects a file index.md to be present in every folder and will update it with a list of the files. A sample script is available in `/testing/testGenerateIndex.cfm`.

## Body text

The files (except see [](#metainc) following) included this way are combined into a single publication. 

Note that the div tags are removed in the final HTML. You would need to wrap the includes if you wanted to divide the document into sections or something similar.

## YAML Data

YAML data can be defined in the main index for global values or in the files to rapply to that section only. The defined variables can be used in the final document generation -- see [](#variables) and [](#templates)

## Meta includes { #metainc}

An attribute `meta` can be added to the included files to exclude them from the main body text and place their content into a variable. The id attribute is required in this case. The content is converted to HTML, and so different from YAML defined variables.

```html
<div href="print_intro.md" id="print_intro" meta="true" />
```

## Cross references

Cross references require only the unique id of the target, irrespective of file source. For sections, use the filename excluding any legacy sort orders at the front (e.g. for a file `40-getting-started.md` just use (`#getting-started`). For headings, you need to apply an ID -- see [](#additional_attrs) -- and then use this as the link.

In addition, ColdLight will automatically update cross references with the text of the reference (if left blank).

## Variables subsitutions { #variables}

Variable subsitutions can be made using `{$fieldname}` syntax. Any YAML data, meta includes, or heading with an ID can be used.

In addition, all the YAML or meta includes can be used with the template system when the final version is generated.