/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 No Face Press, LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
require([
    'dojo/ready','dijit/registry', 'dojo/dom', 'dojo/on', 'dojo/parser',
    'dojo/dom-style', "dojo/request/xhr", "dojo/_base/lang",
    'dijit/layout/ContentPane', 'dojox/form/Uploader', 'dojo/domReady!'
], function(ready,registry, dojoDom, on, parser,
    domStyle, xhr, lang, ContentPane, Uploader) {


    var wjt = {
        init: function() {
        	this.usergroup = registry.byId("usergroup");
        	this.uploader = registry.byId("uploader");
        	this.submit = registry.byId("submit");
	}
    };

    var dom = {
        divForm: dojoDom.byId("divForm"),
        myForm: dojoDom.byId("myForm")
    };

    var getData = function() {

        return xhr("cgi/whoami.pl", {
            handleAs: "json"
        });
    };

    var accessRestriction = function(data) {
        divForm.innerHTML = "";
	var panel = new ContentPane({
        	title: "Access Restricted",
		content: '<div class="errmsg">You are not authorized to view this content.</div>'
   	 }, divForm);
    };

    var checksubmit = function() {
        var l = wjt.uploader.getFileList();
        if (l.length == 0) {
		alert("Select a file first");
		return;
        }
	dom.myForm.submit();
    };

    ready(function() {
   	 parser.parse().then(function() {
	wjt.init();
        getData().then(function (agent) {
		if (!agent || !agent.usergroups || agent.usergroups.length == 0) {
			accessRestriction();
			return;
		}
        var i;
        var options = [];
        for (i=0;i < agent.usergroups.length;i++) {
		options.push({
			value: agent.usergroups[i].name,
			label: agent.usergroups[i].label
                });
        }
	wjt.usergroup.set("options",options);
	wjt.usergroup.set("value",options[0].value);
	});
	wjt.submit.on("click", checksubmit);
	});
    });
});
