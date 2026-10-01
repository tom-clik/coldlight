# Macros

Macros allow for reuse of content or for easier formatting of tables. Note that they are handled by the markdown parser and will only work for the page in which they are defined. There is another mechanism for variable substitution and meta data that can be used for publication-wide variables.

They are defined using `>>>name ... <<<` and inserted with `<<<name>>>`.

```
|   Complex   |     Data     |
|-------------|--------------|
| <<<macro>>> | <<<macro2>>> |

>>>macro
1. Item 1
2. Item 2
3. Item 3

| Column 1 | Column 2 |
|----------|----------|
| a        | b        |
| c        | d        |

> Block Quote and more

<<<

>>>macro2
- Item 1
- Item 2
- Item 3
<<<
```


|  Complex    |     Data     |
|-------------|--------------|
| <<<macro>>> | <<<macro2>>> |

>>>macro
1. Item 1
2. Item 2
3. Item 3

| Column 1 | Column 2 |
|----------|----------|
| a        | b        |
| c        | d        |

> Block Quote and more

<<<

>>>macro2
- Item 1
- Item 2
- Item 3
<<<