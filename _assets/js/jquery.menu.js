$.fn.menu = function() {
 
    return this.each(function() {
    	var self = this;
		
		console.log("Running menu");
		
		var arrow = "<svg version=\"1.1\" id=\"Capa_1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" viewBox=\"0 0 284.929 284.929\" style=\"enable-background:new 0 0 284.929 284.929;\"								 xml:space=\"preserve\"><g><path d=\"M282.082,76.511l-14.274-14.273c-1.902-1.906-4.093-2.856-6.57-2.856c-2.471,0-4.661,0.95-6.563,2.856L142.466,174.441 L30.262,62.241c-1.903-1.906-4.093-2.856-6.567-2.856c-2.475,0-4.665,0.95-6.567,2.856L2.856,76.51 C0.95,78.417,0,80.607,0,83.082 c0,2.473,0.953,4.663,2.856,6.565l133.043,133.046c1.902,1.903,4.093,2.854,6.567,2.854s4.661-0.951,6.562-2.854L282.082,89.647 								c1.902-1.903,2.847-4.093,2.847-6.565C284.929,80.607,283.984,78.417,282.082,76.511z\"/></g></svg>";

		$(self).find(".submenu").each(function() {
			$temp = $(this).prev("a");
			console.log($temp);
			$(this).prev("a").append(arrow).addClass("hasmenu");
		});

		$(self).on("click",".hasmenu",function(e) {
			e.preventDefault();
			e.stopPropagation(); 
			var $li = $(this).closest("li");
			var open = $li.hasClass("open");
			
			$(this).closest("ul").find("li").removeClass("open");
			if (!open) {
				$li.addClass("open");
			}

		});
	});
}