/*

Auto button function

Use data-target and data-action and use them to trigger the action on the target.

## Details

The target elements should have methods for the actions specified, e.g. on("open",{}).on("close",{});

The special case openclose will "toggle" the open and close actions. By default the state is assumed 
to be "close" to start. Override this with data-open on the button.

### Button classes

A class of state_<state> will be added to the button element. To start with a default use 
`class="state_open" data="state_open"`

## Usage

Typically apply to all relevant elements by a standardised class, e.g.

$(".button").button();

Typical actions are open, close (or the special case openclose).

@author Tom Peer
@version 1.0

*/

$.fn.button = function() {
 
    return this.each(function() {

    	var $button = $(this);

    	$(this).on("click","a",function() {	
		
			var $self = $(this);
			
			let $id = $($self.data("target"));
			let action = $self.data("action");
			
			if ($id && action) {
				console.log("triggering " + action + " on " + $id.attr("id"));
				let state = $self.data("state"); 
				if (action == "openclose") {
					if (!state) {
						state = "close";
					}
					action = state == "open" ? "close" : "open";
				}
				
				$id.trigger(action);
				
				// state allows us to apply one single class to indicate the state.
				// we need a data property to track the state and we add
				// add css class of state_<state>
				// currently only open and close are in any sort of use
				
				if (state) {
					console.log("Updating state:", state);
					let currentstate = $button.data("state");
					if (currentstate) {
						$button.removeClass("state_" + currentstate);
					}
					$button.data("state",state);
					$button.addClass("state_" + state);
				}
			}
			// debug
			else {
				console.log("No auto actions for button");
			}
			// /debug
			
		});
	})
}