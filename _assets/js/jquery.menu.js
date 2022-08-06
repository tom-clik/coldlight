/**
 * Menu function
 *
 * Add arrow icon to any items with a sub menu
 *
 * Ad onclick to those items that adds an open class to the sub menu.
 *
 * TODO:
 *
 * 1. Auto animate height of sub menus
 * 2. Position sub menus for any that aren't inline
 * 
 */

$.fn.menu = function(ops) {
 	
	var defaults = {
			debug: false,
			arrow: "<i class='icon icon-next openicon'></i>",
			menuAnimationTime: "0.3s"
		},
		options = $.extend({},defaults,ops);

	$(".submenu").on("open",function() {
		console.log("opening " + $(this).attr("id"));
		$(this).animateAuto("height", options.menuAnimationTime, function() {
			console.log("Animation complete");	
			$(this).css({"height":""}).addClass("open");
		});

	}).on("close",function() {
		console.log("closing " + $(this).attr("id"));
		$(this).animate({"height":0}, options.menuAnimationTime, function() {
			console.log("Animation complete");	
			$(this).removeClass("open").css({"height":""});
		});
	});
	

	return this.each(function() {
    	var self = this;
			
		$(self).find(".submenu").each(function() {
			$(this).prev("a").append(options.arrow).addClass("hasmenu");
		});

		$(self).on("click",".hasmenu",function(e) {
			e.preventDefault();
			e.stopPropagation(); 
			var $li = $(this).closest("li");
			var open = $li.hasClass("open");
			
			$(this).closest("ul").find("li").removeClass("open");
			if (!open) {
				$li.addClass("open");
				$li.find("> ul").first().trigger("open");
			}
			else {
				$li.find("> ul").first().trigger("close");	
			}
			

		});

		
		
	});
}
