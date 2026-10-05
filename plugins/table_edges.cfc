component implements="coldlight.plugins.pluginInterface" {

	public function init(markdown.flexmark markdownObj, coldsoup.coldsoup coldsoupObj) {
		
		variables.jsoupObj=arguments.coldsoupObj;
		
		return this;
	}

	public string function preProcess(required string text) localmode=true {

		/**
		 * Process the whole text string before processings
		 *
		 * arguments.text = Replace(arguments.text,"♠","&spade;","all");
		 * 
		 */
		return arguments.text;
		
	}

	public void function process(required struct section, required struct document) localmode=true {

		markTableEdges( section = arguments.section );
	
	}


	/** Mark table boundaries using logical columns, including merged cells. */
	public void function markTableEdges(required struct section) localmode=true {
		for (table in arguments.section.node.select("table")) {
			rows = [];
			// Descendant tables are processed separately.
			for (row in table.select("tr")) {
				if (row.closest("table").equals(table)) {
					row.removeClass("first-row").removeClass("last-row");
					rows.append(row);
				}
			}
			if (!rows.len()) continue;
			rows[1].addClass("first-row");
			rows[rows.len()].addClass("last-row");

			occupied = {};
			placements = [];
			width = 0;
			for (rowIndex = 1; rowIndex <= rows.len(); rowIndex++) {
				row = rows[rowIndex];
				// Row spans cannot cross a thead/tbody/tfoot boundary.
				if (rowIndex == 1 || !row.parent().equals(rows[rowIndex - 1].parent())) {
					occupied = {};
					groupEnd = rowIndex;
					while (groupEnd < rows.len() && rows[groupEnd + 1].parent().equals(row.parent()))
						groupEnd++;
				}
				column = 1;
				for (cell in row.children()) {
					if (!cell.is("td, th")) continue;
					cell.removeClass("first-column").removeClass("last-column");
					while (occupied.keyExists(column) && occupied[column] >= rowIndex) column++;

					colspan = tableSpan(cell.attr("colspan"), 1000);
					rowspan = cell.attr("rowspan") == "0"
						? groupEnd - rowIndex + 1
						: tableSpan(cell.attr("rowspan"), 65534);
					endColumn = column + colspan - 1;
					placements.append({node:cell, first:column, last:endColumn});
					width = max(width, endColumn);
					for (covered = column; covered <= endColumn; covered++)
						occupied[covered] = min(groupEnd, rowIndex + rowspan - 1);
					column = endColumn + 1;
				}
			}
			for (placement in placements) {
				if (placement.first == 1) placement.node.addClass("first-column");
				if (placement.last == width) placement.node.addClass("last-column");
			}
		}
	}

	private numeric function tableSpan(required string value, required numeric maximum) {
		if (!reFind("^[0-9]+$", trim(arguments.value))) return 1;
		return max(1, min(arguments.maximum, val(arguments.value)));
	}


}
