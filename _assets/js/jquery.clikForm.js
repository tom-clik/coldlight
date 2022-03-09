
/**
 * @fileOverview Essentially marries jQuery Form and jQuery Validate to provide validation and AJAX submission in the Clik system, with some default error message positioning
 * @author Gethin
 *
 * @module  clikForm
   @version 0.2
 */

/**
* Return true if the field value matches the given format RegExp
*
* @memberOf module:clikForm
*
* @example $.validator.methods.pattern("AR1004",element,/^AR\d{4}$/)
* @result true
*
* @example $.validator.methods.pattern("BR1004",element,/^AR\d{4}$/)
* @result false
*
* @name $.validator.methods.pattern
* @type Boolean
* @cat Plugins/Validate/Methods
*/
$.validator.addMethod( "pattern", function( value, element, param ) {
	if ( this.optional( element ) && value == '') {
		return true;
	}
	if ( typeof param === "string" ) {
		param = new RegExp( param );
	}
	return param.test( value );
}, "Invalid format." );

/**
* Shorthand for pattern validation of [A-Za-z0-9_]
*
* @example $.validator.methods.pattern("AR1004",element)
* @result true
*
* @example $.validator.methods.pattern("BR1004",element)
* @result false
*
* @name $.validator.methods.code
* @type Boolean
* @cat Plugins/Validate/Methods
*/
$.validator.addMethod("code",function(value,element){
	var re = new RegExp("^[A-Za-z0-9_]*$");
    return (this.optional(element) && value == '') || re.test(value);
});

(function($){

	/**
	 * Validates a form and submits it through AJAX.
	 *
	 * If the AJAX response is `true` the submission is deemed to have been successfull, and a success message is displayed. 
	 * Else, the AJAX response is deemed to be an object where the keys are the `name`s of the failed form fields, and the values are error messages.
	 *
	 * @memberOf module:clikForm
	 * 
	 * @param  {object} ops Options
	 * @param {string} [ops.finish_copy] Success message to show on successfull submission
	 * @param {string} [ops.error_message] Error message to show if submission wasn't successful
	 * @return {jQuery}     Returns `this` for easy chaining
	 */
	$.fn.clikForm = function(ops){
		var defaults = {
				mobileWidth : 0,
				debug: false
			},
			options = $.extend({},defaults,ops);

		return this.each(function(){
			var $cs = $(this), $form = $cs.find('form'), $originalForm = $form.clone(), imageID, validator;

			validator = $form.validate({
				debug: options.debug,
				errorPlacement: function(error, element) {
					$errorContainer = $form.find('.validateError[data-field='+element.attr('name')+']');
					if( $errorContainer.length ) {
						error.appendTo( $errorContainer );						
					} else {
						error.insertAfter(element)
					}
					$form.find('#question'+element.attr('name')).first().addClass("error");
				},				
		        unhighlight: function (element,sClass) {
		            $(element)
		            .addClass("valid")
		            .removeClass(sClass);
		            $form.find('#question'+$(element).attr('name')).first().removeClass("error");
		        },
				ignore: ':hidden:not(.ratingList input)', // don't validate hidden inputs, except for rating lists
				submitHandler: function() {
					$form.ajaxSubmit({
							dataType: 'json',
							beforeSubmit: function(){
								console.log("Clicked");
								$cs.find(':input').attr('disabled', 'true').css('opacity', 0.3);
							},
							success: function(data, statusText, xhr, $form){
								var qData = {}, msg;
								$cs.find(':input').attr('disabled', '').css('opacity', '');
								// console.log(data);
								if (data === true || ('OK' in data && data.OK)) {
									var $panel = $cs.find('div.contentInner');
									if ($panel.length == 0) {
										$panel = $cs;
									}
									
									if (data !== true && 'NEXTPAGE' in data) {
										$panel.html("<div class='loading></div>");
										window.location.href = data.NEXTPAGE;
									}
									else {
										var msg = data.MESSAGE || options.finish_copy;	
										$panel.html(msg);
									}
								
									
								}
								else {
									// Show error messages:
									// if we fail, we get back an object where the keys are the question names (sans the `Q` prefix) and the values are the error messages.
									$form.find('>.error').remove();
									msg = 'MESSAGE' in data ? data.MESSAGE : options.error_message;
									// recaptcha response is sent separately, so we need to write it out manually
									if( ('g-recaptcha-response' in data) && data['g-recaptcha-response'] !== '' ) {
										$form.find('#recaptcha_widget_'+data['g-recaptcha-response'])
										.find('>.validateError').remove().end()
										.append('<div class="validateError"><p> '+data[data['g-recaptcha-response']]+'</p></div>');
									}
									$form.prepend('<div class="error">' + msg + '</div>');
									// we can only display an error message if we have a field with that name (particularly relevant if you have a captcha) ...
									$.each(data, function(key, val){
										if( $form.find('[name=Q'+key+']').length ) {
											qData['Q' + key] = val;
										}
									});
									validator.showErrors(qData);
									//captcha must be reloaded each time, as only valid once
									grecaptcha.reset();
									$cs.find(':input:disabled').attr('disabled', false).css('opacity', 1);
								}
								$(window).trigger("throttledresize.doColumnResize");
							},
							error : function (jqXHR){
								var errorID, msg = options.error_message;
								if( typeof jqXHR.getResponseHeader === 'function') {
									msg += '<div class="validateError">Error ID: '+jqXHR.getResponseHeader('errorID')+'</div>';
								}
								$cs.find('div.contentInner').html(msg);
								$(window).trigger("throttledresize.doColumnResize");
							}
						});
				}
			});
			
			
			if ((imageID = ((document.location.hash || document.location.href).match('.*(?:photos_id=|photo_)(.+)(?:.html)?$') || ['', ''])[1])
					&& imageID in thumbnails) {
				$form.find('[name=photos_id]').val(imageID);
			}
			$('body').one('pageContentChange',function(e,data){
				if ((imageID = ((document.location.hash || document.location.href).match('.*(?:photos_id=|photo_)(.+)(?:.html)?$') || ['', ''])[1])
						&& imageID in thumbnails && imageID != $form.find('[name=photos_id]').val()) {
					$cs.find('.contentInner').empty().append($originalForm).end().clikForm(options);
				}
			});
		});
	};
}(jQuery));
