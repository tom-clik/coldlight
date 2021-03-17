# Fuzzy Search

`fts_fuzzy_match.js` is a JavaScript component that tries to emulate Sublime's fuzzy search.

It does a reasonable job considering it's JavaScript, and can return a score for a give search pattern. By looping over a set of "symbols" we can sort the results according to the best match.

It doesn't allow for emboldening of the matched letters, and there's no guarantee first occurence of a letter is the one that has triggered the score. E.g.

For the pattern  `GS`, `Goings South` would probably match the second S

## Integration

ColdLight generates symbols for all h1-h3 tags in the app.

## Link

[forrestthewoods/lib_fts](https://github.com/forrestthewoods/lib_fts/blob/master/code/fts_fuzzy_match.js)






