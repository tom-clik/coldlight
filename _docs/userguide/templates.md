# Templates

To output a publication, a template is required. These use the [Mustache](https://mustache.github.io/) syntax.

Variable names are enclosed in curly braces, e.g. `{{title}}`. Note any variables containing HTML need triple braces, e.g. `{{{intro}}}`.

For PDF or EPUB versions, one template is used to generate the whole document.

## Basic fields

Any fields defined using YAML or meta includes can be output using just their variable names, e.g. `{{title}}`.

The other fields depend on the output target.

## Single page publications

For a single page (PDF, EPUB), the main body text is combined into a variable called `body`. 

Each separate file is added in order. If a "section" has sub sections, the title of the is "demoted" to `<h2>`. The easiest way to change this behaviour is to create a separate index for the print/ebook versions. This is the primary reason for using the `<div href=''>` mechanism as opposed to the directory structure.

### The TOC variable

An HTML table of contents can be output with the `toc` variable.

Note this is only for PDF documents. The EPUB toc is generated automatically in code.

## Website publications

Multiple page publications have a "page" variable with multiple fields for navigation.

| Field      | Description
|------------|------------------------------
| `title`    | The page title
| `body `    | Body without the first h1 tag
| `next `    | 
| `previous` | Previous page or section code
| `previous_link` | Full HTML link to previous page
| `next` | Next page or section code
| `next_link` | Full HTML link to next page
| `parent.link` | Full HTML link to parent section
| `parent.title` | Name of parent section
| `parent.id` | ID of parent section
| `section.id` | ID of current page

### Site Variables

When saving a static website, variables can be defined in the site object and output with the `site` prefix, e.g. `{{site.title}}`. These are in addition to the basic variables defined in YAML.

### Menu

The main menu for a multiple page document is saved to a variable `site.menu`. It's the same on all pages 

