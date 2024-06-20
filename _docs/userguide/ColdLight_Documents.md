# ColdLight Publications

A ColdLight "publication" consists of multiple markdown files that are combined using a single "index" file.

This uses a proprietary mechanism for defining the included files: `<div href="testing.md" id="testing"  />`. 

Note that the file names are not used to determine the order of the publication, you must create an index file.

The index file can contain markdown text, but usually just has YAML data and includes. e.g.

```
---
author: Tom Peer
title: Test app
description: Testing application
toclevel: 2
---

<div href="testing.md" id="testing" meta="true" />
<div href="test4.md" />
<div href="test2.md" />
<div href="test3.md" />
```

## Body text

All files (except see following) included this way are combined into a single document. YAML data can be defined in any of the files and will OVERWITE the existing value.

Note that the div tags are removed. You would need to wrap the includes if you wanted to divide the document into sections or something similar.

## Meta includes

An attribute `meta` can be added to the included files to exlcude them from the main body text and place their content into a variable. The id attribute is required in this case.

```
<div href="testing.md" id="testing" meta="true" />
```

## Cross references

Cross references require only the unique id of the target, irresepctive of file source.

In addition, it will automatically update cross references with the text of the reference (if left blank).

## Variables subsitutions

Variable subsitutions can be made using `{$fieldname}` syntax. Any YAML data or heading with an ID can be used.

## Table of contents

A table of contents can be generated from the headings. Three mechanisms exist for including/excluding items:

1. toclevel
	By default all headings of level 3 and above are included. Adjust this with the `toclevel` variables. If can be any number from 1-6
2. notoc variable
	A list of CSS selectors to exclude from the toc, e.g. `#frontmatter h1, #frontmatter h2, #frontmatter h3`
3. notoc class
	Any heading can be simply excluded by adding a notoc class



