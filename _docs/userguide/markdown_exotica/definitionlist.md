# Definition lists

The simplest way to create a two column list is with a definition list.

These can be defined in markdown with the following syntax:

```markdown
First Term
: This is the definition of the first term.

Second Term
: This is one definition of the second term.
: This is another definition of the second term.
```

In HTML, these used to be of limited use as there was no "wrapping" tag around the rows. With CSS grids, they're more useful, and are better than tables for this sort of structure.

```html
<dl>
<dt>Term</dt>
<dd>Definition 1</dd>
<dd>Definition 2</dd>
</dl>
```

These can be styled with grid column specifications.

```css
dl {
  display: grid;
  grid-template-columns: max-content 1fr; /* Two columns: one for terms and one for definitions */
  gap: 10px 20px; /* Gap between rows and columns */
}

dl dt {
  font-weight: bold;
  grid-column: 1 / 2; /* Term always occupies the first column */
}

dl dd {
  margin: 0;
  grid-column: 2 / 3; /* Definitions always occupy the second column */
}
```

Note that for long terms with multiple definitions, sometimes you still have to convert to a table to get the styling right.

## Sample list

First Term
: This is the definition of the first term.

Second Term
: This is one definition of the second term.
: This is another definition of the second term.