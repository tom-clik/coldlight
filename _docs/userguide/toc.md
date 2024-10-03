# Table of contents

## Web version

Each section and the site has a toc variables which is the top level headings in that section.

## Print Version

For print publications, a table of contents is generated from all the headings. Three mechanisms exist for including/excluding items:

1. `toclevel`
	By default all headings of level 3 and above are included. Adjust this with the `toclevel` variable. It can be any number from 1-6
2. `notoc` variable
	Use YAML to define a list of CSS selectors to exclude from the toc, e.g. `#frontmatter h1, #frontmatter h2, #frontmatter h3`
3. `notoc` class
	Any heading can be simply excluded by adding a notoc class


### Examples

Setting the toc level variable in YAML.

```
---
toclevel: 1
---
```

Setting a no toc rule to exclud headings in the front matter.

```
---
notoc: #frontmatter h1, #frontmatter h2, #frontmatter h3
---
```

Using a class to exclude a header

```
### Header text {.notoc} 
```

## Using the toc

The toc is added to the document variables with key `toc` and can be output with the syntax `{$toc}` or with a mustache variable in the template.

E.g. for a section you can add a table of contents so:

```
<h2>Section contents</h2>

{$toc}
```