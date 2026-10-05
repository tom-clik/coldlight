/*

# Coldlight Sample  App


## Usage

Normally you would redefined the functions marked virtual in the coldlightApplication


## History

|-----------|------|---------------------
|2020-01-30 | THP  | Created

*/


component extends="coldlight.coldlightApplication" {

	this.testMode = false;

	public void function onError(e) {
		
		param request.prc = {};

		local.args = {
			e=e,
			debug=1,
			ajax=request.prc.isAjaxRequest ? : 0
		};

		new cferrorHandler.errorHandler(argumentCollection=local.args);
		
	}
	
}
