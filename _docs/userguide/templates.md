# Templates

To output a publication, a template is required. These use the [Mustache](https://mustache.github.io/) syntax.

Variable names are enclosed in curly braces, e.g. `{{title}}`. Note any variables containing HTML need triple braces, e.g. `{{{intro}}}`.

## Basic fields

Any fields defined using YAML or meta includes can be output using just their variable names, e.g. `{{title}}`

### Main text

The main body text is combined into a variable called `body`. 

### The TOC variable

An HTML table of contents can be output with the `toc` variable.

## Static Site templates

Templates for a static site need the "page" context for the data. The page variables:

| Field    | Description
|----------|------------------------------
| Title    | The page title
| Body     | Body without the first h1 tag
| Next     | 
| `previous` | Link to previous page or section

### Site Variables

When saving a static website, variables can be defined in the site object and output with the `site` prefix, e.g. `{{site.title}}`. These are in addition to the basic variables defined in YAML.



