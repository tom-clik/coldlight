# Installing ColdLight

You will need to first install the [Flexmark java parser](https://github.com/vsch/flexmark-java) and [Jsoup](https://jsoup.org/) into your Java path.

Whether you decide to use ColdLight or not, these Java libraries are two of the best for CFML developers and time spent installing them won't be wasted.

To test your installation, try instantiating the object in a CFM page

    variables.markdown = createObject( "java", "Flexmark" ).init();

JSoup should be installed in the same way.

    variables.soup = createObject( "java", "org.jsoup.Jsoup" );

## Installing the helper components

ColdLight uses a number of CF components to run. These are wrappers for JSoup and Flexmark, and the Mustache library for templates

Install these into either your standard component location or a folder you intend adding to the component path for an application (or server).

### ColdSoup

A simple wrapper for JSoup, provides convenient methods for parsing and also caching of whitelists etc.

**File**: `coldsoup.coldSoup.cfc`<br>
**Repo**: [ColdSoup](https://github.com/tom-clik/coldsoup)

### Flexmark

Markdown parsing component with a few additional methods for handling "meta" data (details of headings etc).

**File**: `markdown.Flexmark.cfc`<br>
**Repo**: [Markdown](https://github.com/tom-clik/markdown)

### Mustache

A CFML Mustache library. Note the original author has archived the repository and I maintain a forked version.

**File**: `mustache.mustache.cfc`<br>
**Repo**: [Markdown](https://github.com/tom-clik/mustache)







