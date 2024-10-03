# Macros

Macros are good for inserting complex data into tables.

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