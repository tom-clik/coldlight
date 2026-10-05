/** Batch element screenshots using the adjacent Node/Playwright helper. */
component {
    public function init(required string nodePath) {
        variables.nodePath = arguments.nodePath;
        variables.renderer = getDirectoryFromPath(getCurrentTemplatePath()) & "html-to-png/renderer.mjs";
        return this;
    }

    /** HTML must include a base URL when it has relative resource references. */
    public array function convert(required string html, required array images,
        required string outputFolder, struct options={}) localmode=true {
        if (!arrayLen(arguments.images)) return [];
        if (!directoryExists(arguments.outputFolder))
            throw(type="coldlight.htmlToPng", message="Output folder does not exist: " & arguments.outputFolder);
        timeout = structKeyExists(arguments.options, "timeout") ? arguments.options.timeout : 60;
        if (!isNumeric(timeout) || timeout <= 0)
            throw(type="coldlight.htmlToPng", message="Timeout must be positive");
        tempFolder = getTempDirectory() & "coldlight-html-png-" & createUUID() & "/";
        directoryCreate(tempFolder);
        try {
            htmlFile = tempFolder & "document.html";
            jobFile = tempFolder & "job.json";
            fileWrite(htmlFile, arguments.html, "utf-8");
            normalizedOptions = {};
            optionNames = {"width":"width", "height":"height", "scale":"scale", "media":"media",
                "transparent":"transparent", "timeout":"timeout", "executablePath":"executablePath"};
            for (key in arguments.options) {
                if (!structKeyExists(optionNames, key))
                    throw(type="coldlight.htmlToPng", message="Unknown renderer option: " & key);
                normalizedOptions[optionNames[key]] = arguments.options[key];
            }
            job = {"htmlFile":htmlFile, "images":[],
                "outputFolder":getCanonicalPath(arguments.outputFolder), "options":normalizedOptions};
            // Explicit keys keep Lucee's struct casing out of the JSON protocol.
            for (item in arguments.images) {
                if (!isStruct(item) || !structKeyExists(item, "id") || !structKeyExists(item, "filename"))
                    throw(type="coldlight.htmlToPng", message="Each batch item needs id and filename");
                job.images.append({"id":item.id, "filename":item.filename});
            }
            fileWrite(jobFile, serializeJSON(job), "utf-8");
            stdout = "";
            stderr = "";
            cfexecute(name=variables.nodePath, arguments=[variables.renderer, jobFile],
                timeout=timeout + 15, terminateOnTimeout=true, variable="stdout", errorVariable="stderr");
            if (!isJSON(stdout))
                throw(type="coldlight.htmlToPng", message="HTML renderer did not return JSON", detail=left(stderr & stdout, 4000));
            result = deserializeJSON(stdout);
            if (!result.ok)
                throw(type="coldlight.htmlToPng", message=result.error);
            return result.images;
        } finally {
            directoryDelete(tempFolder, true);
        }
    }
}
