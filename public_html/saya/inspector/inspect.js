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
'dijit/registry', 'dojo/dom', 'dojo/on', 'dojo/dom-construct', 'dojo/parser', 'dijit/form/TextBox', 
'dijit/layout/ContentPane', 'dijit/layout/BorderContainer',
"dojo/request/xhr", 'saya/3p/handlebars', 'dojo/domReady!'
], function (registry, dojoDom, on, domConstruct, parser, TextBox, ContentPane, BorderContainer, xhr, HandleBars) {


  parser.parse();

  var wjt = {
      content: registry.byId("content"),
  };

  var dom = {
	usrRow: dojoDom.byId("usr-template"),
	hitRow: dojoDom.byId("hit-template")
  };

  var hitTemplate   = HandleBars.compile(dom.hitRow.innerHTML);
  var usrTemplate   = HandleBars.compile(dom.usrRow.innerHTML);

 var getData = function() {

   return xhr("inspect.pl", {
     handleAs: "json"
     });
 };

 var updatePage = function(data) {

    data.suspects.sort(function(a,b){
	 if(a.user < b.user) return -1;
    if(a.user > b.user) return 1;
    return 0;
	});

   var tbl = domConstruct.create("table", {className: "suspects"});
    for (var i=0;i<data.suspects.length;i++) {
  		 	domConstruct.place(usrTemplate(data.suspects[i]),tbl,"last");
    		for (var j=0;j<data.suspects[i].log.length;j++) {
  		 	domConstruct.place(hitTemplate(data.suspects[i].log[j]),tbl,"last");
		}
	}
  // var th = domConstruct.create("th", null, tr);
 //  th.innerHTML = "Hello";

   wjt.content.set("content", tbl);
 };

  getData().then(updatePage);

});
require([
    'dijit/registry', 'dojo/dom', 'dojo/on', 'dojo/dom-construct', 'dojo/parser', 'dijit/form/TextBox',
    'dijit/layout/ContentPane', 'dijit/layout/BorderContainer',
    "dojo/request/xhr", 'saya/3p/handlebars',
    'dojo/domReady!'
], function(registry, dojoDom, on, domConstruct, parser, TextBox, ContentPane, BorderContainer, xhr, HandleBars) {


    parser.parse();

    var wjt = {
        content: registry.byId("content"),
    };

    var dom = {
        usrRow: dojoDom.byId("usr-template"),
        hitRow: dojoDom.byId("hit-template")
    };

    var hitTemplate = HandleBars.compile(dom.hitRow.innerHTML);
    var usrTemplate = HandleBars.compile(dom.usrRow.innerHTML);

    var getData = function() {

        return xhr("inspect.pl", {
            handleAs: "json"
        });
    };

    var updatePage = function(data) {

        data.suspects.sort(function(a, b) {
            if (a.user < b.user) return -1;
            if (a.user > b.user) return 1;
            return 0;
        });

        var tbl = domConstruct.create("table", {
            className: "suspects"
        });
        for (var i = 0; i < data.suspects.length; i++) {
            domConstruct.place(usrTemplate(data.suspects[i]), tbl, "last");
            for (var j = 0; j < data.suspects[i].log.length; j++) {
                domConstruct.place(hitTemplate(data.suspects[i].log[j]), tbl, "last");
            }
        }
        // var th = domConstruct.create("th", null, tr);
        //  th.innerHTML = "Hello";

        wjt.content.set("content", tbl);
    };

    getData().then(updatePage);

});
