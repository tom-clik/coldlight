# ColdLight Publications

A ColdLight publication consists of multiple markdown files that are combined using a single index file.

This uses a proprietary mechanism for defining the included files: `<div href="testing.md" />`. 

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

## Body text

The files (except see following) included this way are combined into a single document. 

Note that the div tags are removed in the final HTML. You would need to wrap the includes if you wanted to divide the document into sections or something similar.

## YAML Data

YAML data can be defined in any of the files and will OVERWITE the existing value. The defined variables can be used in the final document generation -- see [](#templates)

## Meta includes

An attribute `meta` can be added to the included files to exclude them from the main body text and place their content into a variable. The id attribute is required in this case.

```
<div href="print_intro.md" id="print_intro" meta="true" />
```

## Cross references

Cross references require only the unique id of the target, irresepctive of file source.

In addition, ColdLight will automatically update cross references with the text of the reference (if left blank).

## Variables subsitutions

Variable subsitutions can be made using `{$fieldname}` syntax. Any YAML data, meta includes, or heading with an ID can be used.


