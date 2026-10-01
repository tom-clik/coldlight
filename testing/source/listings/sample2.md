---
title: Another code listing
file: sample2.cfc
---

```cfc
if ( sectionData.keyExists("parent") ) {
	parentObj =  arguments.document.data[sectionData.parent];
	hasContent = parentObj.hasContent ? : true;
	page["parent"] = {
		"title" = parentObj.meta.title,
		"link" = hasContent ? getLink(dataSection=parentObj,preview=arguments.preview) : parentObj.meta.title
	};
}
```