# Using the sample app

To see ColdLight in action ensure you can browse to the sample app in a web context. By default the sample app will show only this guide. It can easily be amended to show other "publications" by amending the `application.cfc`.

Three parts are required for an app: the index file, `index.md`, the contents file, `toc.md`, and source files.

## Creating a toc file

The table of contents file (`toc.md`) contains Markdown syntax to define the structure of a publication. If not used, the order of the content will be alphabetical file names.

The titles can be omitted. The link must the file name (the extension can be omitted if it is `.md`).

    [](section1.md)
    [](section2.md)
    [Short name](section3.md)

### Alternative titles

The page headings will be picked up to use for the menu, but explicit title can be supplied int he TOC to shorten or otherwise customise the menu entries.

(Functionality still in beta).

## The index file

An "home" page that is excluded from the table of contents can be used. Create an index.md file to do this.

Without this, the first page in the menu will be used.