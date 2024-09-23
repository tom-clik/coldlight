component extends="coldlight.coldlight" {
	public function getLink() {
		return super.getLink(argumentCollection = arguments);
	}
	public function sectionMenu() {
		return super.sectionMenu(argumentCollection = arguments);
	}
	public function sectionLink() {
		return super.sectionLink(argumentCollection = arguments);
	}
	public function getPage() {
		return super.sectionLink(argumentCollection = arguments);
	}
}