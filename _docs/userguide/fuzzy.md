# Search

## Fuzzy Search

The sample template uses a Fuzzy Search library, [`fts_fuzzy_match.js`](https://github.com/forrestthewoods/lib_fts/blob/master/code/fts_fuzzy_match.js).

This matches letters against the letters of given headings and returns a score according to where they are placed.

For example, the pattern  `GS` would match `Going South` with a high score, `Giselle` with a lower one, and `Goings` lower.

Fuzzy search works well for publications where the sections have lots of headings.

## Integration

ColdLight generates symbols for all h1-h3 tags in the app. These are saved to file `searchSymbols.js` which creates a global variable `symbols`. 

The fuzzy search plug in can then be applied to a search box:

```
$("#searchControl").fuzzySearch({symbols:symbols, results: "#searchResults"});
```

## Other search

If you want to write your own API for search, you can adapt the fuzzySearch plugin to call it. Some sample search functionality is available in the testing folder.

### Solr search

A `testing/search_test.cfm` file uses the `search/solr.cfc` component to create a Solr search catalogue. This could be used to create an API search.

### Open search

A `search_test.cfm` file uses the `search/solr.cfc` component to create a Solr search catalogue. 

### Simple match

You could do a query of queries on all the data using a simple match. This is generally a very bad idea, however the data can be obtained using the `searchQuery()` method.





