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
    "dojo/request/xhr",
    'dojo/domReady!'
], function(registry, dojoDom, on, domConstruct, parser, TextBox, ContentPane, BorderContainer, xhr) {

    parser.parse();

    var wjt = {
        image: registry.byId("image"),
        probe: registry.byId("probe")
    };

    var dom = {
        imageExample: dojoDom.byId("imageExample"),
        imageResult: dojoDom.byId("imageResult")
    };

    var getLocalURL = function(rmturl) {

        var file = "";
        var p = rmturl.lastIndexOf("/") + 1;
        if (p < rmturl.length) {
            var s = rmturl.substring(p, rmturl.length);
            if (s.indexOf(".") >= 0) {
                file = s;
            }
        }

        xhr("agent.pl", {
            handleAs: "json",
            query: {
                url: rmturl,
                file: file
            }
        }).then(function(data) {
            wjt.probe.set("value", data.url);
            var img = new Image();
            img.src = data.url;
            dom.imageResult.innerHTML = "";
            dom.imageResult.appendChild(img);
        });
    };

    var currentImage = "";
    on(wjt.image, "change", function() {
        if (currentImage == wjt.image.get("value")) return;
        currentImage = wjt.image.get("value");
        dom.imageExample.innerHTML = "Loading...";
        var img = new Image();
        img.onload = function() {
            dom.imageResult.innerHTML = "Getting Probe Url...";
            getLocalURL(this.src);
            dom.imageExample.innerHTML = "";
            dom.imageExample.appendChild(this);
        }
        img.src = currentImage;
    });

});
