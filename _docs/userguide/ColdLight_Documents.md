# ColdLight Publications

A markdown "publication" consists of multiple markdown files that are combined using a single "index" file.

This uses a proprietary extension `[include file='']`. The path is relative or defined via a [mapping]()

The following is generated for use in your own application or with Clikpage:

1. An ordered struct of [documents](#documents)
2. An array of [heading data]()
3. A struct of meta data
4. An HTML table of contents

In addition, it will automatically update cross references with the text of the reference (if left blank) and a file reference if it's in a different file.

Variable subsitutions can be made using `{$fieldname}` syntax. These can either be supplied as YAML or else it will use the text of a heading with the specified ID.

## Documents


## Headings


