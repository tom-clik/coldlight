/*
Scroll a menu to match a heading in the main content

## Usage

Apply to a sub menu and supply the main content ID in options

As the page scrolls it will search for the first h2 or h3 tag in view.

In the menu it will apply a headingselected class to an item with a id
of #headingmenu_{id} where {id} is the id of heading in the main content.


*/

$.fn.menuScroll = function(options) {

	var $menu = this;

	var settings = $.extend({
        maincontent:"#maincol .inner",
        headerheight:0
    }, options );

	// trigger immediate run
	scrollMenu($menu,$(settings.maincontent));

	// could do with throttling
	$(window).on('scroll', function() {
		scrollMenu($menu,$(settings.maincontent));
	});

	
	function scrollMenu($menu, $maincontent) {

		var first = true;
		var id;
		var selected = '';

		$maincontent.find("h2 a,h3 a").each(function() {

			var anchor_offset = $(this).offset().top;
			var top = $(window).scrollTop() + settings.headerheight;

			id = $(this).attr('id');
			
			if (first && (top < anchor_offset ))  {
	    		selected = id;
	        	first = false;
	        }
	    });

	    $menu.find('.headingselected').each(function() {
	    	$(this).removeClass('headingselected');
	    });
	    
	    if (selected != '') {
	    	$menu.find('#headingmenu_' + selected).addClass('headingselected');
	    }

	}
};

