package com.hurlant.eval.gen
{
	import com.hurlant.eval.Util;
	import com.hurlant.eval.abc.ABCConstantPool;
	import com.hurlant.eval.abc.ABCFile;
	import com.hurlant.eval.ast.*;
	
	public class ABCEmitter
	{
        public var file:ABCFile, constants:ABCConstantPool;
        /*private*/ var scripts = [];

        function ABCEmitter() {
            file = new ABCFile;
            constants = new ABCConstantPool;
            file.addConstants(constants);
            // XXX why are we adding junk in the constant pool for no good reason?
            //Object_name = nameFromIdent("Object");
            //Array_name = nameFromIdent("Array");
            //RegExp_name = nameFromIdent("RegExp");
        }

        public function newScript(): Script {
            var s = new Script(this);
            scripts.push(s);
            return s;
        }

        public function finalize() {
            function f(s) { s.finalize() }
            Util.forEach(f, scripts);
            return file;
        }

        public var Object_name;
        public var Array_name;
        public var RegExp_name;
        public var meta_construct_name;

        public function namespace( ns:IAstNamespace ) {
        	if (ns is IntrinsicNamespace) {
                return constants.namespace(AVM2Assembler.CONSTANT_Namespace, constants.stringUtf8("intrinsic"));  // FIXME
			} else if (ns is OperatorNamespace) {
                throw ("Unimplemented namespace OperatorNamespace");
			} else if (ns is PrivateNamespace) {
				var pn:PrivateNamespace = ns as PrivateNamespace;
                return constants.namespace(AVM2Assembler.CONSTANT_PrivateNamespace, constants.stringUtf8(pn.name));
   			} else if (ns is ProtectedNamespace) {
   				var pn2:ProtectedNamespace = ns as ProtectedNamespace;
                return constants.namespace(AVM2Assembler.CONSTANT_ProtectedNamespace, constants.stringUtf8(pn2.name));
            } else if (ns is PublicNamespace) {
            	var pn3:PublicNamespace = ns as PublicNamespace;
                return constants.namespace(AVM2Assembler.CONSTANT_Namespace, constants.stringUtf8(pn3.name));
            } else if (ns is InternalNamespace) {
            	var pn4:InternalNamespace = ns as InternalNamespace;
                return constants.namespace(AVM2Assembler.CONSTANT_PackageInternalNS, constants.stringUtf8(pn4.name));
            } else if (ns is UserNamespace) {
            	var un:UserNamespace = ns as UserNamespace;
                /// return constants.namespace(CONSTANT_ExplicitNamespace, constants.stringUtf8(pn.name));
                return constants.namespace(AVM2Assembler.CONSTANT_Namespace, constants.stringUtf8(un.name));
            } else if (ns is AnonymousNamespace) {
            	var an:AnonymousNamespace = ns as AnonymousNamespace;
                /// return constants.namespace(CONSTANT_PackageInternalNS, constants.stringUtf8(an.name));
                return constants.namespace(AVM2Assembler.CONSTANT_Namespace, constants.stringUtf8(an.name));
            } else if (ns is ImportNamespace) {
                throw ("Unimplemented namespace ImportNamespace");
            } else {
                throw ("Unimplemented namespace " + ns);
            }
        }
        function flattenNamespaceSet(nss /*:[[NAMESPACE]]*/) {
            var new_nss = [];
            for( var i = 0; i <nss.length; i++ ) {
                var temp = nss[i];
                for( var q = 0; q < temp.length; q++) {
                    new_nss.push(namespace(temp[q]));
                } 
            } 
            return new_nss;
        }
        public function multiname(mname, is_attr) {
            //var {nss:nss, ident:ident} = mname;
            var nss=mname.nss, ident=mname.ident;
            return constants.Multiname(constants.namespaceset(flattenNamespaceSet(nss)), constants.stringUtf8(ident), is_attr);
        }
        public function qname(qn, is_attr ) {
            //var {ns:ns, id:id} = qn;
            var ns=qn.ns, id=qn.id;
            return constants.QName(namespace(ns), constants.stringUtf8(id), is_attr);
        }
        public function nameFromIdent(id) {
            return constants.QName(constants.namespace(AVM2Assembler.CONSTANT_PackageNamespace, constants.stringUtf8("")),
                                   constants.stringUtf8(id),false);
        }

        public function multinameL(tmp, is_attr) {
        	var nss=tmp.nss;
            return constants.MultinameL(constants.namespaceset(flattenNamespaceSet(nss)), is_attr);
        }

        public function nameFromIdentExpr(e) {
        	if (e is Identifier) {
        		var id:Identifier = e as Identifier;
				return multiname(id,false);
        	} else if (e is QualifiedIdentifier) {
        		var qi:QualifiedIdentifier = e as QualifiedIdentifier;
        		var x = qi.qual;
        		if (x is LexicalRef) {
        			var lr:LexicalRef = x as LexicalRef;
                    // Hack to deal with namespaces for now...
                    // later we will have to implement a namespace lookup to resolve qualified typenames
                    return qname({ns:new AnonymousNamespace((lr.ident as Object).ident), id:qi.ident}, false)
                } else {
                    throw ("Unimplemented: nameFromIdentExpr " + e);
                }
                return multiname(id,false) 
            } else {
            	throw ("Unimplemented: nameFromIdentExpr " + e);
            }
        }
        
        public function rtqname(tmp, is_attr) {
        	var ident=tmp.ident;
            return constants.RTQName(constants.stringUtf8(ident), is_attr);
        }

        public function typeFromTypeExpr(t) {
            // not dealing with types for now
            if (t is TypeName) {
            	var tn:TypeName = t as TypeName;
            	var x = tn.ident;
            	if (x is Identifier) {
            		var i:Identifier = x as Identifier;
                    var name = i.ident;
                    if( name=="String" || name=="Number" ||
                        name=="Boolean" || name=="int" ||
                        name=="uint" || name=="Object" ||
                        name=="Array" || name=="Class" ||
                        name=="Function") {
                        return nameFromIdent(name);
                    } else if( name=="string" ) {
                        return nameFromIdent("String");
                    } else if( name=="boolean" ) {
                        return nameFromIdent("Boolean");
                    } else {
                        //print ("warning: unknown type name " + t + ", using Object");
				        return nameFromIdent("Object");
			        }
                }
            } else {
                // print ("warning: Unimplemented: typeFromTypeExpr " + t + ", using *");
            }
            return 0;
        }

        // Use this only for places that need a QName, only works with basic class names
        // as Tamarin doesn't support 
        public function realTypeName(t) {
            // not dealing with types for now
            if (t is TypeName) {
            	var tn:TypeName = t as TypeName;
                return nameFromIdentExpr(tn.ident);
            } else if (t is SpecialType) {
                return 0;
            } else {
                throw ("Unimplemented: realTypeName " + t + ", using *")
            }
            return 0;
        }

        public function fixtureNameToName(fn) {
        	if (fn is PropName) {
        		var pn:PropName = fn as PropName;
                return qname(pn.name, false);
            } else if (fn is TempName) {
            	var tn:TempName = fn as TempName;
				return qname ({ns:Ast.noNS,id:"$t"+tn.index},false);  // FIXME allocate and access actual temps
            } else {
            	throw "Internal error: not a valid fixture name";
            }
        }
        
        public function fixtureTypeToType(fix) {
        	if (fix is ValFixture) {
                var vf:ValFixture = fix as ValFixture;
                return vf.type != null ? typeFromTypeExpr(vf.type) : 0 ;
         	} else if (fix is MethodFixture) { 
                return 0;
            } else {
                throw "Unimplemented: fixtureTypeToType " + fix;
            }
        }
        
        public function defaultLiteralExpr(lit) {
        	if (lit is LiteralNull) {
                return {val:AVM2Assembler.CONSTANT_Null, kind:AVM2Assembler.CONSTANT_Null}
            } else if (lit is LiteralUndefined) {
                return {val:0, kind:0}
            } else if (lit is LiteralDouble) {
                var ld:LiteralDouble = lit as LiteralDouble;
                var val = constants.float64(ld.doubleValue);
                return {val:val, kind:AVM2Assembler.CONSTANT_Double};
            } else if (lit is LiteralDecimal) {
                var ld2:LiteralDecimal = lit as LiteralDecimal;
                var val = constants.float64(parseFloat(ld2.decimalValue));
                return {val:val, kind:AVM2Assembler.CONSTANT_Double};
            } else if (lit is LiteralInt) {
                var li:LiteralInt = lit as LiteralInt;
                var val = constants.int32(li.intValue);
                return {val:val, kind:AVM2Assembler.CONSTANT_Integer};
            } else if (lit as LiteralUInt) {
                var lu:LiteralUInt = lit as LiteralUInt;
                var val = constants.uint32(lu.uintValue);
                return {val:val, kind:AVM2Assembler.CONSTANT_UInt};
            } else if (lit as LiteralBoolean) {
                var lb:LiteralBoolean = lit as LiteralBoolean;
                var val = (lb.booleanValue ? AVM2Assembler.CONSTANT_True : AVM2Assembler.CONSTANT_False);
                return {val:val, kind:val};
            } else if (lit as LiteralString) {
                var ls:LiteralString = lit as LiteralString;
				var val = constants.stringUtf8(ls.strValue);
                return {val:val, kind:AVM2Assembler.CONSTANT_Utf8};
            } else if (lit is LiteralNamespace) {
                var ln:LiteralNamespace = lit as LiteralNamespace;
                var val = namespace(ln.namespaceValue);
                return  {val:val, kind:AVM2Assembler.CONSTANT_Namespace};
            } else {
                throw ("le Default expression must be a constant value" + lit)
            }
        }
        public function defaultExpr(expr) {
        	if (expr is LiteralExpr) {
                var le:LiteralExpr = expr as LiteralExpr;
				return defaultLiteralExpr(le.literal);
            } else if (expr is LexicalRef) {
                var lr:LexicalRef = expr as LexicalRef;
                var x = lr.ident;
                if (x is Identifier) {
					var i:Identifier = x as Identifier;
					if( i.ident == "undefined" ) {
						// Handle defualt expr of (... arg = undefined ...)
						return defaultLiteralExpr(new LiteralUndefined());
                    } 
                }
            }
            throw ("Default expression must be a constant value" + expr);
        }
    }
}