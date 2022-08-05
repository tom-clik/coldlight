/*

Tabs function

Fancy new semantic markup based tabs system. Place as many items as you like next to each other
and call this on the container. No need for separate header div

<div class="cs-tabs">
	<div class="tab state_open" id="test1" title="Test 1">

		<h3 class="title"><a href="#test1">tab 1</a></h3>

		<div class="item>
			
				<p>Tab 1Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
				tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
				quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
				consequat. </p>
					
			
		</div>
	
	</div>
	...rinse and repeat
</div>

## Details

@author Tom Peer
@version 1.0

*/

$.fn.tabs = function(ops) {
 	
 	var defaults = {
			vertical: false,
			accordian: false,
			resize: "resize",
			menuAnimationTime: 600,
			allowClosed: true
		},
		options = $.extend({},defaults,ops);

	return this.each(function() {

    	var $tabs = $(this);
    	var vertical = options.vertical || $tabs.hasClass("vertical");
    	var accordian = options.accordian || $tabs.hasClass("accordian");

    	setHeight($tabs.find(".tab.state_open"));
    	
    	$tabs.on("resize",function() {
    		console.log("Resizing ", $tabs.attr("id"));
    		$tab = $tabs.find(".state_open").first();
    		setHeight($tab);
    	});

    	$(window).on(options.resize, function( event ) {
    		$tabs.trigger("resize");

		});

    	function setHeight($tab) {
    		if (accordian) return;
    		$tabs.css({"height":"auto"});
    		let t_height = vertical ? 0 : $tab.outerHeight();
    		let $item = $tab.find(".item").first();
    		t_height += $item.outerHeight();
    		if (vertical && t_height < $tabs.outerHeight()) { 
    			t_height = $tabs.outerHeight();
    		}
    		$tabs.outerHeight(t_height);
    	}

    	$tabs.on("click",".title",function() {	
			
			let $tab = $($(this).data("target"));

			if ($tab) {
				console.log("opening " + $tab.attr("id"));
				
				if (accordian){
					let open = $tab.hasClass("state_open");
					if (open && ! options.allowClosed) {
						console.log("Can't close: not allowed");	
						return;
					}
					let $closeElements = $tab;
					if (!open) {
						$closeElements = $tab.siblings(".state_open");
						$tab.addClass("state_open").animateAuto("height", options.menuAnimationTime, function() {
							console.log("Animation complete");	
							$tab.css({"height":""}).addClass("state_open");
						});
					}

					$closeElements.animate({"height":0}, options.menuAnimationTime, function() {
						console.log("Close Animation complete:", $(this).attr("id"));	
						$(this).removeClass("state_open").css({"height":""});
					});
	
				}
				else {
					if ($tab.hasClass("state_open")) {
						return;
					}
					$tab.addClass("state_open").siblings().removeClass("state_open");
					setHeight($tab);
				}
				setHeight($tab);
			}
			// debug
			else {
				console.log("No target found for tab link");
			}
			// /debug
			
		});
	})
}