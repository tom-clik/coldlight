# Footnotes

Footnotes can be added using the following syntax:

```
Some text[^fn1]

[^fn1]: Footnote text
```

The footnotes themselves can appear anywhere in the text but it's best to put them on the paragraph following the marker.

They are added to the html just as `<span class='footnote'>Footnote text</span>`. For EPUB publications, ColdLight will manually process them and produce HTML in a variable `$footnotes`. Other formats should use JavaScript or exotic CSS (see e.g. PrinceXML footnotes for PDFs).



