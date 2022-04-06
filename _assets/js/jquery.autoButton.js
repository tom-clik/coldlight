/*

# Auto button function

Use data-target and data-action and to trigger actions on a target.

## Details

The method is applied to a button container. This typically will have two elements in it for e.g. 
open and close. A class `state_<state>` applied to the button container ensures only one of these is shown. 

In the actual buttons themselves there should be `<a>` tags with an action specified in the data, e.g. data-action="open".

This will be triggered on the target specified on the button with data-target.

The target elements should have methods for the actions specified, e.g. on("open",{}).on("close",{});

The special case openclose will "toggle" the open and close actions. By default the state is assumed 
to be "close" to start. Override this with data-open on the button.[todo: check]

### Styling

The plug in will apply a class of state_<action> to the link elements. The class can be added manually
to avoid potential FOUCs, e.g. <a class="state_close" data-action="close">.

A class of state_<state> will be added to the button element.  This is the state *of the target*. So e.g. if a menu 
is closed the button will have a class of `state_close`.

To start with a different state, use `class="state_open" data-state="open"` on the button.

Ensure your styling hides the buttons as required. E.g. 

```CSS
.cs_button.state_close a:not(.state_open), .cs_button.state_open a:not(.state_close)  {
	display:none;	
}
```

## Usage

Typically apply to all relevant elements by a standardised class, e.g.

$(".button").button();

Typical actions are open, close (or the special case openclose which can be applied to a single button).

```HTML
<div class="cs-button scheme-hamburger mobile scheme-headerbutton" id="mainmenu_button" data-state="close" data-target="#mainmenu">
	<a [class="state_open"] data-action="open">
		<div class="icon">
			<svg   viewBox="0 0 32 32"><use xlink:href="_common/images/menu.svg#menu"></svg>
		</div>
	</a>
	<a [class="state_close"] data-action="close">
		<div class="icon">
			<svg   viewBox="0 0 357 357"><use xlink:href="_common/images/close47.svg#close"></svg>
		</div>
	</a>
</div>
```

@author Tom Peer
@version 1.0

*/

$.fn.button = function() {
 
    return this.each(function() {

    	var $button = $(this);
    	var $target = $($button.data("target"));

    	let state = $button.data("state");
    	
    	// add default state class to button
    	if (state) {
    		$button.addClass("state_" + state);
    	}

    	// add default state class to links
    	$button.find("a").each(function() {
    		let $link  = $(this);
    		let action = $link.data("action");
    		$link.addClass("state_" + action);
    	});

    	$(this).on("click","a",function() {	
		
			var $self = $(this);
			let action = $self.data("action");
			
			if ($target && action) {
				
		    	let state = $button.data("state");

				if (action == "openclose") {
					if (!state) {
						state = "close";
					}
					action = state == "open" ? "close" : "open";
				}
				
				console.log("triggering " + action + " on " + $target.attr("id"));

				$target.trigger(action);
				
				// we use a data property to track the state and we add
				// add css class of state_<state>
				// currently only open and close are in any sort of use
				
				console.log("Updating state:", action);
				let currentstate = $button.data("state");
				if (currentstate) {
					$button.removeClass("state_" + currentstate);
				}
				$button.data("state",action);
				$button.addClass("state_" + action);
				
			}
			// debug
			else {
				console.log("No auto actions for button");
			}
			// /debug
			
		});
	})
}