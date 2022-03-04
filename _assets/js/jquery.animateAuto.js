jQuery.fn.animateAuto = function(prop, speed, callback){
    var elem, height, width;
    return this.each(function(i, el){
        el = jQuery(el); /*, elem = el.clone().css({"height":"auto","width":"auto","visibility":"visible"}).appendTo("body");*/

        el.css({"height":"auto","width":"auto"});
        height = el.css("height");
        width = el.css("width");

        // elem.remove();
        
        if(prop === "height") {
            el.css({"height":0});   
            el.animate({"height":height}, speed, callback);
        }
        else if(prop === "width") {
             el.css({"width":0}); 
            el.animate({"width":width}, speed, callback);  
        }
        else if(prop === "both") {
             el.css({"height":0,"width":0});   
            el.animate({"width":width,"height":height}, speed, callback);
        }
    });  
}
