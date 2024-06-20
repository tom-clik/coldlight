# ColdLight Markdown

ColdLight uses extended Markdown with the additional attributes syntax for adding classes and ids.

## YAML data

Meta data can be added to the documents using the YAML format:

```
---
author: Tom Peer
title: Test app
description: Testing application
toclevel: 2
---
```

This information should be placed at the top of the markdown files. Any variable defined here will be available as for substitution using `{$varname}` syntax.

## Additional anchors { #additional_anchors}

Anchors can be added to any markdown tag using the attribute syntax:

```
### heading 3 { #tag}

Classes and other attributes can be added to this:

### heading 3 { #tag .warning data-subtitle='Other attribs added as key pairs'}
```

## Cross reference

When linking to a cross reference in any part of the document, use only the unique anchor. If omitted, the link text will be the heading title, e.g.

```markdown
[](#chapter4)
```

Sample cross-ref to `#additional_anchors`: [](#additional_anchors)

## Definition lists

Definition lists can be defined as so:

```markdown
term:
    Defintiion
term2:
    Defintiion
```

## HTML

HTML is supported and is recommended for creating `<div></div>` sections.

E.g. 

```markdown
<div class='classname'>

## heading

section text

</div>
```
