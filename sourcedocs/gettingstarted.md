# Getting started

You will need to first install the [Flexmark java parser](#flexmark) and [Jsoup](jsoup) into your Java path.

Whether you decide to use ColdLight or not, these Java libraries are two of the best for CFML developers and time spent installing them won't be wasted.

## Installing Flexmark

We have made a simple Flexmark class that takes a list of plugins to use. The default is to use all. See the [flex mark repository](https://www.coldlight.net/flexmark) to download it.

The available plug ins are tables, abbreviation, admonition, anchorlink, attributes, autolink, definition, emoji, escapedcharacter, footnote, strikethrough, softbreaks.

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

**File**: `coldsoup.coldSoup.cfc`<br>
**Repo**: [ColdSoup](https://github.com/tom-clik/coldsoup)

### Flexmark

Markdown parsing component with a few additional methods for handling "meta" data (details of headings etc).

**File**: `markdown.Flexmark.cfc`<br>
**Repo**: [Markdown](https://github.com/tom-clik/markdown)

### Page Builder

The page rendering in the sample ColdLight app uses the [Clik](https://www.clik.com) publishing components. 

**File**: `clikpage.pageObj.cfc`<br>
**Repo**: [Clikpage](https://github.com/tom-clik/clikpage)

### Static files

Allows for easy inclusion of static files (js,css) in a web page. Used by pageObj.

**File**: `clikpage.staticfiles.cfc`<br>
**Repo**: Same as page builder

Some static file definitions are also required. The ones in the folder will be used by default.

## Running the sample app

With all the help apps installed, you can preview the ColdLight sample app.

See `coldlight/sample`.

Ensure the app is in a webfolder and browse to it.





















