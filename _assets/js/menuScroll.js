/*
Scroll a menu to match a heading in the main content

## Details

Apply to a sub menu and supply the main content ID in options

As the page scrolls it will search for the first h2 or h3 tag in view. It expects these to have an 
anchor with an ID. This is the format that gets psat out of Flexmakr markdown converted

<h2><a id="heading1">Heading 1</a><h2>

In the menu it will apply a headingselected class to an item with a id
of #headingmenu_{id} where {id} is the id of heading in the main content.

It will also manually scroll the page to the heading when you click on the menu if the
link is to the anchor. This a) allows for a slower scroll to get around the last anchor usability issue[^last]
and b) allows us to supply a header height to cope with fixed headers.

[^last]: When you click to an anchor that is near the bottom of the page, often it seems like nothing has
happened. The anchor will not be at the top of the page and often it moves too fast, if at all. By slowing the 
anim, we can provide visual feedback for most scroll ranges.

## Usage

$("#mymeny").menuScroll({"maincontent":"#maincol", $("#header").height()});

*/

$.fn.menuScroll = function(options) {
	
	console.log("working");

	var $menu = this;

	var settings = $.extend({
        maincontent:"body",
        headerheight:0
    }, options );

	var $maincontent = $(settings.maincontent);

	if (settings.headerheight == "auto") {
		settings.headerheight = $maincontent.offset().top;
	}
	console.log("headerheight:", settings.headerheight);

	// trigger immediate run
	scrollMenu($menu,$maincontent);

	// could do with throttling
	$(window).on('scroll', function() {
		scrollMenu($menu,$maincontent);
	});

	$menu.on("click","a", function(e) {
		e.preventDefault();
	   	var id = $(this).attr("href");
	   	scrollToAnchor(id)

	});

	function scrollToAnchor(aid){
	    var aTag = $(aid);
	    $('html,body').animate({scrollTop: aTag.offset().top - settings.headerheight},'slow',function() {
	    	scrollMenu($menu,$maincontent);	
	    });
	    
	}
	
	function scrollMenu($menu, $maincontent) {

		var first = true;
		var id;
		var selected = '';

		$maincontent.find("h2 a,h3 a").each(function() {

			var anchor_offset = $(this).offset().top;
			var top = $(window).scrollTop() + settings.headerheight;

			id = $(this).attr('id');
			
			console.log(id, "top=", top, "anchor_offset=", anchor_offset);

			if (first && (top <= anchor_offset ))  {
	    		selected = id;
	        	first = false;
	        	console.log("Setting selected to " + selected);

	        }
	        // #DEBUG
	        else if (first) {
	        	console.log("off screen");
	        }
	        // /#DEBUG
	    });

	    $menu.find('.headingselected').each(function() {
	    	$(this).removeClass('headingselected');
	    });
	    
	    if (selected != '') {
	    	$menu.find('#headingmenu_' + selected).addClass('headingselected');
	    }

	}
};

