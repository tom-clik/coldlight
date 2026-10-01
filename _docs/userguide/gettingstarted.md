# Installing ColdLight

To run ColdLight, you will need the Java libraries and some CFML helper components to run.

## Java Libraries

You will need to first install the [Flexmark java parser](https://github.com/vsch/flexmark-java) and [Jsoup](https://jsoup.org/) where your app can access them. Recommended versions are `jsoup-1.22.1.jar` and `flexmark-all-0.64.0-lib.jar`.

A sample installation is shown in the repo in the object `testing/coldLightTestingObj.init()`. This relies on an environment variable called `server.system.environment.javalib` which is the location of these files. The full path is required as a parameter when loading the libraries.

At this time we're not using the new Maven dependecies in Lucee, we've experienced issues on start up when using this. Nor can we rely on using the Java class path. Flexmark and many other Java libraries embed Jsoup and it's often an incompatible version.

Whether you decide to use ColdLight or not, these Java libraries are two of the best for CFML developers and time spent installing them won't be wasted.

### Installing Flexmark

Flexmark can be downloaded from [Maven](https://mvnrepository.com/artifact/com.vladsch.flexmark/flexmark-all). Select version 0.64.0 (important - later versions may not work) and then on the details page ensure you select "View all" in the `Files` section. Download the `-lib.jar` file.

You can then test it loads:

```cfc
markdownParser = createObject("java", "com.vladsch.flexmark.parser.Parser",pathtojar);
```

### Installing JSOUP

JSOUP is also on [Maven](https://mvnrepository.com/artifact/org.jsoup/jsoup), or the jar can be downloaded from the [Jsoup website](https://jsoup.org/) website. From Maven, only the main JAR file is needed.

Once downloaded, it can be tested:

```
jSoupClass = createObject( "java", "org.jsoup.Jsoup", pathtojar );
```

## CFML components

ColdLight uses the following helper components to run. These are wrappers for JSoup and Flexmark, and the Mustache library for templates.

Install these into either into your webroot (avoid doing this in production), or a folder you have added to the component path. If you don't want them in the webroot, the next easiest (and best) way is to create a common folder, e.g. "shared", and add the path to the `componentpaths` in your `application.cfc` :    

```cfc
this.componentpaths["shared"]="fullpath_to_folder";
```

You can also configure the component path in the administrator.

The components must be within the folder path as per the layout below. Note the folder name "markdown" for Flexmark which is a legacy from a previous parser.

Once installed, you can test them by creating a new object, e.g.

```
coldsoup = new coldsoup.coldSoup(jarpath);
```

where `coldSoup.cfc` is in a directory `coldsoup` in your libraries folder. A typical set up for a project might look like this:

```
|
|--javalibs
|     |---jsoup-1.22.1.jar
|     |---flexmark-all-0.64.0-lib.jar
|--libraries
|     |---coldsoup
|     |      |--- coldsoup.cfc
|     |---markdown
|     |      |--- Flexmark.cfc
|     |---mustache
|     |      |--- mustache.cfc
|--www
    |---application.cfc
```

### ColdSoup

A simple wrapper for JSoup, provides convenient methods for parsing and also caching of whitelists etc.

**File**
: `coldsoup/coldSoup.cfc`

**Repo**
: [ColdSoup](https://github.com/tom-clik/coldsoup)

### Markdown

Markdown parsing component with a few additional methods for handling "meta" data (details of headings etc).

**File**
: `markdown/Flexmark.cfc`

**Repo**
: [Markdown](https://github.com/tom-clik/markdown)

### Mustache

A CFML Mustache library. Note the original author has archived the repository and I maintain a forked version.

**File**
: `mustache/mustache.cfc`

**Repo**
: [Mustache](https://github.com/tom-clik/mustache)

## Testing and Exploring the Helper Components

The components have test and sample folders that can be run in a web context. If you put your shared component folder outside the webroot, you can set up a mapping and a virtual directory to preview them.

For ColdSoup, see the examples at:

```
/coldsoup/samples/index.cfm
```

For markdown, there is a `/markdown/testing/flexmark_test.cfm` page that can demonstrates simple usage of the tag.

For Mustache, see `/tests/tests_simple.cfm`.

