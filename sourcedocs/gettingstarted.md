# Getting started

You will need to first install the [Flexmark java parser](#flexmark) and [Jsoup](jsoup) into your Java path.

Whether you decide to use ColdLight or not, these Java libraries are two of the best for CFML developers and time spent installing them won't be wasted.

## Installing Flexmark

<<<<<<< HEAD
We have made a simple Flexmark class that takes a list of plugins to use. The default is to use all. See the [markdown repository](https://github.com/tom-clik/markdown) to download it (the source and class file are in the java sub folder).

The available plug-ins are tables, abbreviation, admonition, anchorlink, attributes, autolink, definition, emoji, escapedcharacter, footnote, strikethrough, softbreaks.
=======
We have made a simple Flexmark class that takes a list of plugins to use. The default is to use all. See the [flex mark repository](https://www.coldlight.net/flexmark) to download it.

The available plug ins are tables, abbreviation, admonition, anchorlink, attributes, autolink, definition, emoji, escapedcharacter, footnote, strikethrough, softbreaks.
>>>>>>> e0aac16 (Moved docs and published new html)

Installation of a Java class depends on whether your are using ACF or Lucee. 

Please refer to the documentation for your server set up. For ACF, the easiest is just to drop the class into your lib folder and restart.

To test your installation, try instantiating the object in a CFM page

    variables.markdown = createObject( "java", "Flexmark" ).init();

## Installing JSoup

[JSoup](https://www.jsoup.org) should be installed in the same way.

    variables.soup = createObject( "java", "org.jsoup.Jsoup" );

## Installing the helper components

ColdLight uses a number of CF components to run. This includes wrappers for JSoup and Flexmark.

Install these into either your standard component location or a folder you intend adding to the component path for an application (or server).

### ColdSoup

A simple wrapper for JSoup, provides convenient methods for parsing and also caching of whitelists etc.

<<<<<<< HEAD
**File**: `coldsoup.coldSoup.cfc`<br>
**Repo**: [ColdSoup](https://github.com/tom-clik/coldsoup)
=======
File: `coldsoup.coldSoup.cfc`
>>>>>>> e0aac16 (Moved docs and published new html)

### Flexmark

Markdown parsing component with a few additional methods for handling "meta" data (details of headings etc).

<<<<<<< HEAD
**File**: `markdown.Flexmark.cfc`<br>
**Repo**: [Markdown](https://github.com/tom-clik/markdown)

### Page Builder

The page rendering in the sample ColdLight app uses the [Clik](https://www.clik.com) publishing components. 

**File**: `publishing.pageObj.cfc`<br>
**Repo**: [Clikpage](https://github.com/tom-clik/clikpage)
=======
File: `markdown.Flexmark.cfc`

### Page Builder

The page rendering in the sample ColdLight app uses the [Clik](https://www.clik.com) publishing components. They are all in the publishing folder. 

File: `publishing.pageObj.cfc`
>>>>>>> e0aac16 (Moved docs and published new html)

### Static files

Allows for easy inclusion of static files (js,css) in a web page. Used by pageObj.

<<<<<<< HEAD
**File**: `publishing.staticfiles.cfc`<br>
**Repo**: Same as page builder
=======
File: `publishing.staticfiles.cfc`

Some static file definitions are also required. The ones in the folder will be used by default.
>>>>>>> e0aac16 (Moved docs and published new html)

## Running the sample app

With all the help apps installed, you can preview the ColdLight sample app.

See `coldlight/testing`.

Ensure the app is in a webfolder and browse to it.





















