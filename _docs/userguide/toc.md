# Table of contents

A table of contents can be generated from the headings. Three mechanisms exist for including/excluding items:

1. `toclevel`
	By default all headings of level 3 and above are included. Adjust this with the `toclevel` variable. It can be any number from 1-6
2. `notoc` variable
	Use YAML to define a list of CSS selectors to exclude from the toc, e.g. `#frontmatter h1, #frontmatter h2, #frontmatter h3`
3. `notoc` class
	Any heading can be simply excluded by adding a notoc class

## Using the toc

The toc is added to the document variables with key `toc` and can be output with the syntax `{$toc}`.

## Examples

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


