/*
Copyright (c) 2009, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.net/yui/license.txt
version: 2.7.0
*/
YAHOO.util.Attribute=function(B,A){if(A){this.owner=A;this.configure(B,true);}};YAHOO.util.Attribute.prototype={name:undefined,value:null,owner:null,readOnly:false,writeOnce:false,_initialConfig:null,_written:false,method:null,setter:null,getter:null,validator:null,getValue:function(){var A=this.value;if(this.getter){A=this.getter.call(this.owner,this.name);}return A;},setValue:function(F,B){var E,A=this.owner,C=this.name;var D={type:C,prevValue:this.getValue(),newValue:F};if(this.readOnly||(this.writeOnce&&this._written)){return false;}if(this.validator&&!this.validator.call(A,F)){return false;}if(!B){E=A.fireBeforeChangeEvent(D);if(E===false){return false;}}if(this.setter){F=this.setter.call(A,F,this.name);if(F===undefined){}}if(this.method){this.method.call(A,F,this.name);}this.value=F;this._written=true;D.type=C;if(!B){this.owner.fireChangeEvent(D);}return true;},configure:function(B,C){B=B||{};if(C){this._written=false;}this._initialConfig=this._initialConfig||{};for(var A in B){if(B.hasOwnProperty(A)){this[A]=B[A];if(C){this._initialConfig[A]=B[A];}}}},resetValue:function(){return this.setValue(this._initialConfig.value);},resetConfig:function(){this.configure(this._initialConfig,true);},refresh:function(A){this.setValue(this.value,A);}};(function(){var A=YAHOO.util.Lang;YAHOO.util.AttributeProvider=function(){};YAHOO.util.AttributeProvider.prototype={_configs:null,get:function(C){this._configs=this._configs||{};var B=this._configs[C];if(!B||!this._configs.hasOwnProperty(C)){return null;}return B.getValue();},set:function(D,E,B){this._configs=this._configs||{};var C=this._configs[D];if(!C){return false;}return C.setValue(E,B);},getAttributeKeys:function(){this._configs=this._configs;var C=[],B;for(B in this._configs){if(A.hasOwnProperty(this._configs,B)&&!A.isUndefined(this._configs[B])){C[C.length]=B;}}return C;},setAttributes:function(D,B){for(var C in D){if(A.hasOwnProperty(D,C)){this.set(C,D[C],B);}}},resetValue:function(C,B){this._configs=this._configs||{};if(this._configs[C]){this.set(C,this._configs[C]._initialConfig.value,B);return true;}return false;},refresh:function(E,C){this._configs=this._configs||{};var F=this._configs;E=((A.isString(E))?[E]:E)||this.getAttributeKeys();for(var D=0,B=E.length;D<B;++D){if(F.hasOwnProperty(E[D])){this._configs[E[D]].refresh(C);}}},register:function(B,C){this.setAttributeConfig(B,C);},getAttributeConfig:function(C){this._configs=this._configs||{};var B=this._configs[C]||{};var D={};for(C in B){if(A.hasOwnProperty(B,C)){D[C]=B[C];}}return D;},setAttributeConfig:function(B,C,D){this._configs=this._configs||{};C=C||{};if(!this._configs[B]){C.name=B;this._configs[B]=this.createAttribute(C);}else{this._configs[B].configure(C,D);}},configureAttribute:function(B,C,D){this.setAttributeConfig(B,C,D);},resetAttributeConfig:function(B){this._configs=this._configs||{};this._configs[B].resetConfig();},subscribe:function(B,C){this._events=this._events||{};if(!(B in this._events)){this._events[B]=this.createEvent(B);}YAHOO.util.EventProvider.prototype.subscribe.apply(this,arguments);},on:function(){this.subscribe.apply(this,arguments);},addListener:function(){this.subscribe.apply(this,arguments);},fireBeforeChangeEvent:function(C){var B="before";B+=C.type.charAt(0).toUpperCase()+C.type.substr(1)+"Change";C.type=B;return this.fireEvent(C.type,C);},fireChangeEvent:function(B){B.type+="Change";return this.fireEvent(B.type,B);},createAttribute:function(B){return new YAHOO.util.Attribute(B,this);}};YAHOO.augment(YAHOO.util.AttributeProvider,YAHOO.util.EventProvider);})();(function(){var B=YAHOO.util.Dom,C=YAHOO.util.AttributeProvider;var A=function(D,E){this.init.apply(this,arguments);};A.DOM_EVENTS={"click":true,"dblclick":true,"keydown":true,"keypress":true,"keyup":true,"mousedown":true,"mousemove":true,"mouseout":true,"mouseover":true,"mouseup":true,"focus":true,"blur":true,"submit":true,"change":true};A.prototype={DOM_EVENTS:null,DEFAULT_HTML_SETTER:function(F,D){var E=this.get("element");if(E){E[D]=F;}},DEFAULT_HTML_GETTER:function(D){var E=this.get("element"),F;if(E){F=E[D];}return F;},appendChild:function(D){D=D.get?D.get("element"):D;return this.get("element").appendChild(D);},getElementsByTagName:function(D){return this.get("element").getElementsByTagName(D);},hasChildNodes:function(){return this.get("element").hasChildNodes();},insertBefore:function(D,E){D=D.get?D.get("element"):D;E=(E&&E.get)?E.get("element"):E;return this.get("element").insertBefore(D,E);},removeChild:function(D){D=D.get?D.get("element"):D;return this.get("element").removeChild(D);},replaceChild:function(D,E){D=D.get?D.get("element"):D;E=E.get?E.get("element"):E;return this.get("element").replaceChild(D,E);},initAttributes:function(D){},addListener:function(H,G,I,F){var E=this.get("element")||this.get("id");F=F||this;var D=this;if(!this._events[H]){if(E&&this.DOM_EVENTS[H]){YAHOO.util.Event.addListener(E,H,function(J){if(J.srcElement&&!J.target){J.target=J.srcElement;}D.fireEvent(H,J);},I,F);}this.createEvent(H,this);}return YAHOO.util.EventProvider.prototype.subscribe.apply(this,arguments);},on:function(){return this.addListener.apply(this,arguments);},subscribe:function(){return this.addListener.apply(this,arguments);},removeListener:function(E,D){return this.unsubscribe.apply(this,arguments);},addClass:function(D){B.addClass(this.get("element"),D);},getElementsByClassName:function(E,D){return B.getElementsByClassName(E,D,this.get("element"));},hasClass:function(D){return B.hasClass(this.get("element"),D);},removeClass:function(D){return B.removeClass(this.get("element"),D);},replaceClass:function(E,D){return B.replaceClass(this.get("element"),E,D);},setStyle:function(E,D){return B.setStyle(this.get("element"),E,D);},getStyle:function(D){return B.getStyle(this.get("element"),D);},fireQueue:function(){var E=this._queue;for(var F=0,D=E.length;F<D;++F){this[E[F][0]].apply(this,E[F][1]);}},appendTo:function(E,F){E=(E.get)?E.get("element"):B.get(E);this.fireEvent("beforeAppendTo",{type:"beforeAppendTo",target:E});
F=(F&&F.get)?F.get("element"):B.get(F);var D=this.get("element");if(!D){return false;}if(!E){return false;}if(D.parent!=E){if(F){E.insertBefore(D,F);}else{E.appendChild(D);}}this.fireEvent("appendTo",{type:"appendTo",target:E});return D;},get:function(D){var F=this._configs||{},E=F.element;if(E&&!F[D]&&!YAHOO.lang.isUndefined(E.value[D])){this._setHTMLAttrConfig(D);}return C.prototype.get.call(this,D);},setAttributes:function(J,G){var E={},H=this._configOrder;for(var I=0,D=H.length;I<D;++I){if(J[H[I]]!==undefined){E[H[I]]=true;this.set(H[I],J[H[I]],G);}}for(var F in J){if(J.hasOwnProperty(F)&&!E[F]){this.set(F,J[F],G);}}},set:function(E,G,D){var F=this.get("element");if(!F){this._queue[this._queue.length]=["set",arguments];if(this._configs[E]){this._configs[E].value=G;}return;}if(!this._configs[E]&&!YAHOO.lang.isUndefined(F[E])){this._setHTMLAttrConfig(E);}return C.prototype.set.apply(this,arguments);},setAttributeConfig:function(D,E,F){this._configOrder.push(D);C.prototype.setAttributeConfig.apply(this,arguments);},createEvent:function(E,D){this._events[E]=true;return C.prototype.createEvent.apply(this,arguments);},init:function(E,D){this._initElement(E,D);},destroy:function(){var D=this.get("element");YAHOO.util.Event.purgeElement(D,true);this.unsubscribeAll();if(D&&D.parentNode){D.parentNode.removeChild(D);}this._queue=[];this._events={};this._configs={};this._configOrder=[];},_initElement:function(F,E){this._queue=this._queue||[];this._events=this._events||{};this._configs=this._configs||{};this._configOrder=[];E=E||{};E.element=E.element||F||null;var H=false;var D=A.DOM_EVENTS;this.DOM_EVENTS=this.DOM_EVENTS||{};for(var G in D){if(D.hasOwnProperty(G)){this.DOM_EVENTS[G]=D[G];}}if(typeof E.element==="string"){this._setHTMLAttrConfig("id",{value:E.element});}if(B.get(E.element)){H=true;this._initHTMLElement(E);this._initContent(E);}YAHOO.util.Event.onAvailable(E.element,function(){if(!H){this._initHTMLElement(E);}this.fireEvent("available",{type:"available",target:B.get(E.element)});},this,true);YAHOO.util.Event.onContentReady(E.element,function(){if(!H){this._initContent(E);}this.fireEvent("contentReady",{type:"contentReady",target:B.get(E.element)});},this,true);},_initHTMLElement:function(D){this.setAttributeConfig("element",{value:B.get(D.element),readOnly:true});},_initContent:function(D){this.initAttributes(D);this.setAttributes(D,true);this.fireQueue();},_setHTMLAttrConfig:function(D,F){var E=this.get("element");F=F||{};F.name=D;F.setter=F.setter||this.DEFAULT_HTML_SETTER;F.getter=F.getter||this.DEFAULT_HTML_GETTER;F.value=F.value||E[D];this._configs[D]=new YAHOO.util.Attribute(F,this);}};YAHOO.augment(A,C);YAHOO.util.Element=A;})();YAHOO.register("element",YAHOO.util.Element,{version:"2.7.0",build:"1796"});