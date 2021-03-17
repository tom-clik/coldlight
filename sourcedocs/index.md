# Introduction to ColdLight

ColdLight is a Markdown based CFML documentation application. It was designed to allow instant preview of edited pages in large document sets without rebuilding.

It uses a simple format for describing the contents of a document and can be used either as a CFML app in "live" preview or to generate static HTML.

In "live" mode, it offers advantages over other static file generators in that it will reload the menu and cross-references instantly without the need to rebuild the whole app.

It uses Flexmark as its markdown parser, but this could easily be swapped out.

It allows for different pages of a document to be stored in varying locations, ideal for documenting component libraries.

As well as Flexmark, it consists of a few CFML components and a sample app that can be easily customised or even replaced.


