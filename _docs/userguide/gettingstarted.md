# Installing ColdLight

You will need to first install the [Flexmark java parser](https://github.com/vsch/flexmark-java) and [Jsoup](https://jsoup.org/) into your Java class path.

Whether you decide to use ColdLight or not, these Java libraries are two of the best for CFML developers and time spent installing them won't be wasted.

## Installing Flexmark

Flexmark can be downloaded from [Maven](https://mvnrepository.com/artifact/com.vladsch.flexmark/flexmark-all). Select version 0.64.0 (important - later versions may not work) and then on the details page ensure you select "View all" in the `Files` section. Download the main jar AND the `-lib.jar` file.

Place the files into your Java class path and restart the CFML server (you may wish to install JSOUP as well before restarting, see section following). If you want to keep these components in a separate folder (good practice), you can add to your server class path in `application.cfc`.

```cfc
this.javaSettings = {LoadPaths = ["fullpath_to_folder"]};
```

To test your installation, try instantiating the object in a CF page

```cfc
markdown = createObject( "java", "Flexmark" ).init();
```

## Installing JSOUP

JSOUP is also on [Maven](https://mvnrepository.com/artifact/org.jsoup/jsoup), or the jar can be downloaded from the [Jsoup website](https://jsoup.org/) website. From Maven, only the main JAR file is needed.

Once installed, it should be tested in the same way.

```
Jsoup = createObject( "java", "org.jsoup.Jsoup" );
```

## Installing the helper components

ColdLight uses a number of CF components to run. These are wrappers for JSoup and Flexmark, and the Mustache library for templates.

Install these into either into your webroot, or a folder you have added to the component path. If you don't want them in the webroot, the next easiest way is to create a common folder, e.g. "shared", and add the path to the `componentpaths` in your `application.cfc` :    

```cfc
this.componentpaths["shared"]="fullpath_to_folder";
```

You can also configure these in the administrator.

Once installed, you can test them by creating a new object, e.g.

```
coldsoup = new coldsoup.coldSoup();
```

### ColdSoup

A simple wrapper for JSoup, provides convenient methods for parsing and also caching of whitelists etc.

**File**: `coldsoup/coldSoup.cfc`<br>
**Repo**: [ColdSoup](https://github.com/tom-clik/coldsoup)

### Markdown

Markdown parsing component with a few additional methods for handling "meta" data (details of headings etc).

**File**: `markdown/Flexmark.cfc`<br>
**Repo**: [Markdown](https://github.com/tom-clik/markdown)

### Mustache

A CFML Mustache library. Note the original author has archived the repository and I maintain a forked version.

**File**: `mustache/mustache.cfc`<br>
**Repo**: [Mustache](https://github.com/tom-clik/mustache)

## Testing and Exploring the Helper Components

The components have test and sample folders that can be run in a web context. If you put your shared component folder outside the webroot, you can set up a mapping and a virtual directory to preview them.

For ColdSoup, see the examples at:

```
/coldsoup/samples/index.cfm
```

For markdown, there is a `/markdown/testing/flexmark_test.cfm` page that can demonstrates simple usage of the tag.

For Mustache, see `/tests/tests_simple.cfm`.

