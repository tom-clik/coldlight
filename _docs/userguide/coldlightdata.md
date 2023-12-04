# Using a Coldlight Data set

Once parsed, a Coldlight data set is accessed by publication and page code. 

To ensure any code you write can be used in live or cached mode, always used the `getLink()` method will return the correct link for any level of anchor.

## A page struct

The `getPage` struct contains the following keys which can be used to render a page.

| FIELD                  | Description
|------------------------|--------------------------------------------
| CODE                   | Unique code for containing page.           
| TITLE                  | Title of page           
| CONTENT                | Content as JSOUP node. 
| CONTENT_HTML           | Content html for people that can't type .html()
| PUBLICATION            | Title of publication               
| NEXT                   | Title of next page (blank if last)     
| NEXT_LINK              | HTML link to next page                
| PREVIOUS               | Title of previous page (blank if first)          
| PREVIOUS_LINK          | HTML link to previous page 
                  





