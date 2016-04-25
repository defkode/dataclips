/*! modernizr 3.3.1 (Custom Build) | MIT *
 * http://modernizr.com/download/?-adownload-datalistelem-setclasses !*/
!function(e,n,t){function a(e,n){return typeof e===n}function s(){var e,n,t,s,o,i,f;for(var u in r)if(r.hasOwnProperty(u)){if(e=[],n=r[u],n.name&&(e.push(n.name.toLowerCase()),n.options&&n.options.aliases&&n.options.aliases.length))for(t=0;t<n.options.aliases.length;t++)e.push(n.options.aliases[t].toLowerCase());for(s=a(n.fn,"function")?n.fn():n.fn,o=0;o<e.length;o++)i=e[o],f=i.split("."),1===f.length?Modernizr[f[0]]=s:(!Modernizr[f[0]]||Modernizr[f[0]]instanceof Boolean||(Modernizr[f[0]]=new Boolean(Modernizr[f[0]])),Modernizr[f[0]][f[1]]=s),l.push((s?"":"no-")+f.join("-"))}}function o(e){var n=u.className,t=Modernizr._config.classPrefix||"";if(c&&(n=n.baseVal),Modernizr._config.enableJSClass){var a=new RegExp("(^|\\s)"+t+"no-js(\\s|$)");n=n.replace(a,"$1"+t+"js$2")}Modernizr._config.enableClasses&&(n+=" "+t+e.join(" "+t),c?u.className.baseVal=n:u.className=n)}function i(){return"function"!=typeof n.createElement?n.createElement(arguments[0]):c?n.createElementNS.call(n,"http://www.w3.org/2000/svg",arguments[0]):n.createElement.apply(n,arguments)}var l=[],r=[],f={_version:"3.3.1",_config:{classPrefix:"",enableClasses:!0,enableJSClass:!0,usePrefixes:!0},_q:[],on:function(e,n){var t=this;setTimeout(function(){n(t[e])},0)},addTest:function(e,n,t){r.push({name:e,fn:n,options:t})},addAsyncTest:function(e){r.push({name:null,fn:e})}},Modernizr=function(){};Modernizr.prototype=f,Modernizr=new Modernizr;var u=n.documentElement,c="svg"===u.nodeName.toLowerCase(),p=i("input"),d="autocomplete autofocus list placeholder max min multiple pattern required step".split(" "),m={};Modernizr.input=function(n){for(var t=0,a=n.length;a>t;t++)m[n[t]]=!!(n[t]in p);return m.list&&(m.list=!(!i("datalist")||!e.HTMLDataListElement)),m}(d),Modernizr.addTest("datalistelem",Modernizr.input.list),Modernizr.addTest("adownload",!e.externalHost&&"download"in i("a")),s(),o(l),delete f.addTest,delete f.addAsyncTest;for(var g=0;g<Modernizr._q.length;g++)Modernizr._q[g]();e.Modernizr=Modernizr}(window,document);