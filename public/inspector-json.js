/* Inspector JSON v0.1.0
   Generated on 2014-07-08 at 10:10:12 */
! function(a) {
    if ("object" == typeof exports) module.exports = a();
    else if ("function" == typeof define && define.amd) define(a);
    else {
        var b;
        "undefined" != typeof window ? b = window : "undefined" != typeof global ? b = global : "undefined" != typeof self && (b = self), b.InspectorJSON = a()
    }
}(function() {
    var a;
    return function b(a, c, d) {
        function e(g, h) {
            if (!c[g]) {
                if (!a[g]) {
                    var i = "function" == typeof require && require;
                    if (!h && i) return i(g, !0);
                    if (f) return f(g, !0);
                    throw new Error("Cannot find module '" + g + "'")
                }
                var j = c[g] = {
                    exports: {}
                };
                a[g][0].call(j.exports, function(b) {
                    var c = a[g][1][b];
                    return e(c ? c : b)
                }, j, j.exports, b, a, c, d)
            }
            return c[g].exports
        }
        for (var f = "function" == typeof require && require, g = 0; g < d.length; g++) e(d[g]);
        return e
    }({
        1: [
            function(a, b) {
                var c = a("type-of"),
                    d = a("extend"),
                    e = a("dom-delegate"),
                    f = a("store"),
                    g = a("./utils/toggle_class.js"),
                    h = a("./utils/html_escape.js"),
                    i = function(a) {
                        a = a || {};
                        var b = {
                            element: "body",
                            debug: !1,
                            collapsed: !0,
                            url: location.pathname
                        };
                        a = d(b, a), "element" !== c(a.element) && (a.element = document.getElementById(a.element));
                        var i = f.get(a.url + ":inspectorJSON/collapse_states") || {};
                        if (this.el = a.element, this.el.className += " inspector-json viewer", this.event_delegator = new e(this.el), this.event_delegator.on("click", "li.object > a, li.array > a", function(b) {
                            b.preventDefault();
                            var c = this.parentNode,
                                d = c.getAttribute("data-path");
                            g(c, "collapsed"), /\bcollapsed\b/gi.exec(c.className) ? delete i[d] : i[d] = !0, f.set(a.url + ":inspectorJSON/collapse_states", i)
                        }), this.view = function(b) {
                            var d, e;
                            a.debug && (d = (new Date).getTime());
                            var f = function(b, d, e, g) {
                                var j = c(b),
                                    k = c(d),
                                    l = "";
                                if ("array" === k ? g += "[" + e + "]" : "object" === k ? g += "." + e : g = e || "this", d && (l += i[g] || !a.collapsed || "object" !== j && "array" !== j ? '<li class="' + j + '" data-path="' + g + '">' : '<li class="' + j + ' collapsed" data-path="' + g + '">'), "object" === j) {
                                    e && (l += '<a href="#toggle"><strong>' + e + "</strong></a>"), l += "<ul>";
                                    for (e in b) l += f(b[e], b, e, g);
                                    l += "</ul>"
                                } else if ("array" === j) {
                                    e && (l += '<a href="#toggle"><strong>' + e + "</strong></a>Array(" + b.length + ")"), l += "<ol>";
                                    for (var m in b) l += f(b[m], b, m, g);
                                    l += "</ol>"
                                } else "string" === j ? l += "<strong>" + e + '</strong><span>"' + h(b) + '"</span>' : "number" === j ? l += "<strong>" + e + "</strong><var>" + b.toString() + "</var>" : "boolean" === j ? l += "<strong>" + e + "</strong><em>" + b.toString() + "</em>" : "null" === j && (l += "<strong>" + e + "</strong><i>null</i>");
                                return d && (l += "</li>"), l
                            };
                            "string" === c(b) && (b = JSON.parse(b));
                            var g = f(b);
                            this.el.innerHTML = g, a.debug && (e = (new Date).getTime(), console.log("Inspector JSON: Rendered in " + (e - d) + "ms"))
                        }, this.destroy = function() {
                            this.event_delegator.off(), this.el.innerHTML = ""
                        }, !a.json) try {
                            a.json = JSON.parse(this.el.textContent || this.el.innerText)
                        } catch (j) {
                            a.debug && console.log("Inspector JSON: Element contents are not valid JSON")
                        }
                        a.json && this.view(a.json)
                    };
                b.exports = i
            }, {
                "./utils/html_escape.js": 2,
                "./utils/toggle_class.js": 3,
                "dom-delegate": 5,
                extend: 6,
                store: 7,
                "type-of": 8
            }
        ],
        2: [
            function(a, b) {
                b.exports = function(a) {
                    var b = document.createElement("div");
                    return b.appendChild(document.createTextNode(a)), b.innerHTML
                }
            }, {}
        ],
        3: [
            function(a, b) {
                b.exports = function(a, b) {
                    var c = a.className,
                        d = new RegExp("\\b" + b + "\\b", "ig"),
                        e = !!d.exec(c);
                    return a.className = e ? c.replace(d, "") : c + " " + b, a
                }
            }, {}
        ],
        4: [
            function(a, b) {
                "use strict";

                function c(a) {
                    a && this.root(a), this.listenerMap = {}, this.handle = c.prototype.handle.bind(this)
                }
                b.exports = c, c.tagsCaseSensitive = null, c.prototype.root = function(a) {
                    var b, c = this.listenerMap;
                    if ("string" == typeof a && (a = document.querySelector(a)), this.rootElement)
                        for (b in c) c.hasOwnProperty(b) && this.rootElement.removeEventListener(b, this.handle, this.captureForType(b));
                    if (!a || !a.addEventListener) return this.rootElement && delete this.rootElement, this;
                    this.rootElement = a;
                    for (b in c) c.hasOwnProperty(b) && this.rootElement.addEventListener(b, this.handle, this.captureForType(b));
                    return this
                }, c.prototype.captureForType = function(a) {
                    return "error" === a
                }, c.prototype.on = function(a, b, d, e) {
                    var f, g, h, i;
                    if (!a) throw new TypeError("Invalid event type: " + a);
                    if ("function" == typeof b && (d = b, b = null, e = d), void 0 === e && (e = null), "function" != typeof d) throw new TypeError("Handler must be a type of Function");
                    return f = this.rootElement, g = this.listenerMap, g[a] || (f && f.addEventListener(a, this.handle, this.captureForType(a)), g[a] = []), b ? /^[a-z]+$/i.test(b) ? (null === c.tagsCaseSensitive && (c.tagsCaseSensitive = "i" === document.createElement("i").tagName), i = c.tagsCaseSensitive ? b : b.toUpperCase(), h = this.matchesTag) : /^#[a-z0-9\-_]+$/i.test(b) ? (i = b.slice(1), h = this.matchesId) : (i = b, h = this.matches) : (i = null, h = this.matchesRoot.bind(this)), g[a].push({
                        selector: b,
                        eventData: e,
                        handler: d,
                        matcher: h,
                        matcherParam: i
                    }), this
                }, c.prototype.off = function(a, b, c) {
                    var d, e, f, g, h;
                    if ("function" == typeof b && (c = b, b = null), f = this.listenerMap, !a) {
                        for (h in f) f.hasOwnProperty(h) && this.off(h, b, c);
                        return this
                    }
                    if (g = f[a], !g || !g.length) return this;
                    for (d = g.length - 1; d >= 0; d--) e = g[d], b && b !== e.selector || c && c !== e.handler || g.splice(d, 1);
                    return g.length || (delete f[a], this.rootElement && this.rootElement.removeEventListener(a, this.handle, this.captureForType(a))), this
                }, c.prototype.handle = function(a) {
                    var b, c, d, e, f, g, h, i = "ftLabsDelegateIgnore";
                    if (a[i] !== !0)
                        for (h = a.target, h.nodeType === Node.TEXT_NODE && (h = h.parentNode), d = this.rootElement, g = this.listenerMap[a.type], c = g.length; h && c;) {
                            for (b = 0; c > b && (e = g[b], e); b++)
                                if (e.matcher.call(h, e.matcherParam, h) && (f = this.fire(a, h, e)), f === !1) return void(a[i] = !0);
                            if (h === d) break;
                            c = g.length, h = h.parentElement
                        }
                }, c.prototype.fire = function(a, b, c) {
                    var d, e;
                    return null !== c.eventData ? (e = a.data, a.data = c.eventData, d = c.handler.call(b, a, b), a.data = e) : d = c.handler.call(b, a, b), d
                }, c.prototype.matches = function(a) {
                    if (a) {
                        var b = a.prototype;
                        return b.matchesSelector || b.webkitMatchesSelector || b.mozMatchesSelector || b.msMatchesSelector || b.oMatchesSelector
                    }
                }(HTMLElement), c.prototype.matchesTag = function(a, b) {
                    return a === b.tagName
                }, c.prototype.matchesRoot = function(a, b) {
                    return this.rootElement === b
                }, c.prototype.matchesId = function(a, b) {
                    return a === b.id
                }, c.prototype.destroy = function() {
                    this.off(), this.root()
                }
            }, {}
        ],
        5: [
            function(a, b) {
                "use strict";
                var c = a("./delegate");
                b.exports = function(a) {
                    return new c(a)
                }, b.exports.Delegate = c
            }, {
                "./delegate": 4
            }
        ],
        6: [
            function(a, b) {
                function c(a) {
                    if (!a || "[object Object]" !== e.call(a) || a.nodeType || a.setInterval) return !1;
                    var b = d.call(a, "constructor"),
                        c = d.call(a.constructor.prototype, "isPrototypeOf");
                    if (a.constructor && !b && !c) return !1;
                    var f;
                    for (f in a);
                    return void 0 === f || d.call(a, f)
                }
                var d = Object.prototype.hasOwnProperty,
                    e = Object.prototype.toString;
                b.exports = function f() {
                    var a, b, d, e, g, h, i = arguments[0] || {},
                        j = 1,
                        k = arguments.length,
                        l = !1;
                    for ("boolean" == typeof i && (l = i, i = arguments[1] || {}, j = 2), "object" != typeof i && "function" != typeof i && (i = {}); k > j; j++)
                        if (null != (a = arguments[j]))
                            for (b in a) d = i[b], e = a[b], i !== e && (l && e && (c(e) || (g = Array.isArray(e))) ? (g ? (g = !1, h = d && Array.isArray(d) ? d : []) : h = d && c(d) ? d : {}, i[b] = f(l, h, e)) : void 0 !== e && (i[b] = e));
                    return i
                }
            }, {}
        ],
        7: [
            function(b, c) {
                ! function(b) {
                    function d() {
                        try {
                            return j in b && b[j]
                        } catch (a) {
                            return !1
                        }
                    }

                    function e(a) {
                        return function() {
                            var b = Array.prototype.slice.call(arguments, 0);
                            b.unshift(g), l.appendChild(g), g.addBehavior("#default#userData"), g.load(j);
                            var c = a.apply(h, b);
                            return l.removeChild(g), c
                        }
                    }

                    function f(a) {
                        return a.replace(/^d/, "___$&").replace(o, "___")
                    }
                    var g, h = {},
                        i = b.document,
                        j = "localStorage",
                        k = "script";
                    if (h.disabled = !1, h.set = function() {}, h.get = function() {}, h.remove = function() {}, h.clear = function() {}, h.transact = function(a, b, c) {
                        var d = h.get(a);
                        null == c && (c = b, b = null), "undefined" == typeof d && (d = b || {}), c(d), h.set(a, d)
                    }, h.getAll = function() {}, h.forEach = function() {}, h.serialize = function(a) {
                        return JSON.stringify(a)
                    }, h.deserialize = function(a) {
                        if ("string" != typeof a) return void 0;
                        try {
                            return JSON.parse(a)
                        } catch (b) {
                            return a || void 0
                        }
                    }, d()) g = b[j], h.set = function(a, b) {
                        return void 0 === b ? h.remove(a) : (g.setItem(a, h.serialize(b)), b)
                    }, h.get = function(a) {
                        return h.deserialize(g.getItem(a))
                    }, h.remove = function(a) {
                        g.removeItem(a)
                    }, h.clear = function() {
                        g.clear()
                    }, h.getAll = function() {
                        var a = {};
                        return h.forEach(function(b, c) {
                            a[b] = c
                        }), a
                    }, h.forEach = function(a) {
                        for (var b = 0; b < g.length; b++) {
                            var c = g.key(b);
                            a(c, h.get(c))
                        }
                    };
                    else if (i.documentElement.addBehavior) {
                        var l, m;
                        try {
                            m = new ActiveXObject("htmlfile"), m.open(), m.write("<" + k + ">document.w=window</" + k + '><iframe src="/favicon.ico"></iframe>'), m.close(), l = m.w.frames[0].document, g = l.createElement("div")
                        } catch (n) {
                            g = i.createElement("div"), l = i.body
                        }
                        var o = new RegExp("[!\"#$%&'()*+,/\\\\:;<=>?@[\\]^`{|}~]", "g");
                        h.set = e(function(a, b, c) {
                            return b = f(b), void 0 === c ? h.remove(b) : (a.setAttribute(b, h.serialize(c)), a.save(j), c)
                        }), h.get = e(function(a, b) {
                            return b = f(b), h.deserialize(a.getAttribute(b))
                        }), h.remove = e(function(a, b) {
                            b = f(b), a.removeAttribute(b), a.save(j)
                        }), h.clear = e(function(a) {
                            var b = a.XMLDocument.documentElement.attributes;
                            a.load(j);
                            for (var c, d = 0; c = b[d]; d++) a.removeAttribute(c.name);
                            a.save(j)
                        }), h.getAll = function() {
                            var a = {};
                            return h.forEach(function(b, c) {
                                a[b] = c
                            }), a
                        }, h.forEach = e(function(a, b) {
                            for (var c, d = a.XMLDocument.documentElement.attributes, e = 0; c = d[e]; ++e) b(c.name, h.deserialize(a.getAttribute(c.name)))
                        })
                    }
                    try {
                        var p = "__storejs__";
                        h.set(p, p), h.get(p) != p && (h.disabled = !0), h.remove(p)
                    } catch (n) {
                        h.disabled = !0
                    }
                    h.enabled = !h.disabled, "undefined" != typeof c && c.exports && this.module !== c ? c.exports = h : "function" == typeof a && a.amd ? a(h) : b.store = h
                }(Function("return this")())
            }, {}
        ],
        8: [
            function(a, b) {
                var c = Object.prototype.toString;
                b.exports = function(a) {
                    switch (c.call(a)) {
                        case "[object Function]":
                            return "function";
                        case "[object Date]":
                            return "date";
                        case "[object RegExp]":
                            return "regexp";
                        case "[object Arguments]":
                            return "arguments";
                        case "[object Array]":
                            return "array";
                        case "[object String]":
                            return "string"
                    }
                    if ("object" == typeof a && a && "number" == typeof a.length) try {
                        if ("function" == typeof a.callee) return "arguments"
                    } catch (b) {
                        if (b instanceof TypeError) return "arguments"
                    }
                    return null === a ? "null" : void 0 === a ? "undefined" : a && 1 === a.nodeType ? "element" : a === Object(a) ? "object" : typeof a
                }
            }, {}
        ]
    }, {}, [1])(1)
});