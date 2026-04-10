# Templates

To output a publication, a template is required. These use the [Mustache](https://mustache.github.io/) syntax.

Variable names are enclosed in curly braces, e.g. `{{title}}`. Note any variables containing HTML need triple braces, e.g. `{{{intro}}}`.

Remember that to include variables in the text of a document, you use `${varname}` syntax. Any mustache code in the text will be preserved as is.

## Basic fields

Any fields defined using YAML or meta includes can be output using just their variable names, e.g. `{{title}}`.

The other fields depend on the output target.

## Single page publications

For a single page version (PDF, EPUB), the main body text is combined into a variable called `body`. 

Each separate file is added in order. If a section has sub sections, the title of each sub section is demoted to `<h2>`. The easiest way to change this behaviour is to create a separate index for the print/ebook versions.

### The TOC variable

An HTML table of contents can be output with the `toc` variable. It's primarily designed for PDF documents. The EPUB TOC is generated automatically in code, and listings of content for websites are usually best done with a plug-in, see e.g. the `section_menus` plug-in.

## Website publications

Multiple page publications have a "page" variable with multiple fields for navigation. These are included with dot notation, e.g. `{{page.title}}` or `{{{page.parent.link}}}`.

### Page Variables

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

When saving a static website, variables can be defined in the optional site struct and output with the `site` prefix, e.g. `{{site.title}}`. These are in addition to the basic variables defined in YAML.

These are generally used for "technical" variables such as `{{site.assets_url}}`. Editorial variables such as title are best defined in the text.

### Menu

The main menu for a multiple page document is saved to a variable `site.menu`. It's the same on all pages.

