package com.hurlant.eval.gen
{
	import com.hurlant.eval.Util;
	import com.hurlant.eval.abc.*;
	import com.hurlant.eval.ast.*;
	
	public class CodeGeneration
	{

	    /* Returns an ABCFile structure */
	    public static function cg(tree: Program) {
	    /// function cg(tree: PROGRAM) {
	        var e = new ABCEmitter;
	        var s = e.newScript();
	        // CTX.prototype = { "emitter": e, "script": s, "cp": e.constants };  // tamarin doesn't like initing prototype here
	        CTX_shared = { "emitter": e, "script": s, "cp": e.constants };
	        cgProgram(new CTX(s.init.asm, null, s), tree);
	        return e.finalize();
	    }
	
	    /* A context is a structure with the fields
	     *
	     *    emitter  -- the unique emitter
	     *    script   -- the only script we care about in that emitter
	     *    cp       -- the emitter's constant pool
	     *    asm      -- the current function's assembler
	     *    stk      -- the current function's binding stack (labels, ribs)
	     *    target   -- the current trait target
	     *
	     * All of these are invariant and kept in the prototype except for
	     * 'asm', 'stk', and some fields to come.
	     *
	     * FIXME, there are probably at least two targets: one for LET, another
	     * for VAR/CONST/FUNCTION.
	     */
	
	
	    static function push(ctx, node) {
	        node.link = ctx.stk;
	        return new CTX(ctx.asm, node, ctx.target);
	    }
	
	    static function cgProgram(ctx, prog) {
	        if (prog.head.fixtures != null)
	            cgFixtures(ctx, prog.head.fixtures);
	        cgBlock(ctx, prog.block);
	    }
	
	    static function hasTrait(traits, name, kind) {
	        for(var i = 0, l =traits.length; i < l; i++) {
	            var t = traits[i];
	            if(t.name==name && ((t.kind&15)==kind))
	                return true;
	        }
	        return false;
	    }
	    
	    static function cgFixtures(ctx, fixtures) {
	        //var { target:target, asm:asm, emitter:emitter } = ctx;
	        var target=ctx.target, asm=ctx.asm, emitter=ctx.emitter;
	        var methidx, trait_kind, clsidx;
	        for ( var i=0 ; i < fixtures.length ; i++ ) {
	            var tmp = fixtures[i];
	            var fxname=tmp[0], fx=tmp[1];
	            var name = emitter.fixtureNameToName(fxname);
	
	            /// switch type (fx) {
	            /// case (fx:ValFixture) {
	            if (fx is ValFixture) {
	                if( !hasTrait(target.traits, name, AVM2Assembler.TRAIT_Slot) )
	                    target.addTrait(new ABCSlotTrait(name, 0, false, 0, emitter.typeFromTypeExpr(fx.type), 0, 0)); 
						// FIXME when we have more general support for type annos
	            }
	            /// case (fx:MethodFixture) {
	            else if (fx is MethodFixture) {
	                var initScopeDepth = (ctx.stk!=null && ctx.stk.tag=="instance")?2:0;
	                methidx = cgFunc(ctx, fx.func, initScopeDepth);
	                /// switch type (target) {
	                /// case (m:Method) {
	                if (target is Method) {
	                    target.addTrait(new ABCSlotTrait(name, 0, false, 0, 0, 0, 0)); 
	                    asm.I_findpropstrict(name);
	                    asm.I_newfunction(methidx);
	                    asm.I_setproperty(name);
	                }
	                /// case (x:*) {
	                else {
	                    // target.addTrait(new ABCOtherTrait(name, 0, TRAIT_Method, 0, methidx));
	                    trait_kind = AVM2Assembler.TRAIT_Method;
	                    /// switch type(fx.func.name.kind) {
	                    /// case (g:Get) {
	                    if (fx.func.name.kind is Get) {
	                        //print("Getter, target: " + target);
	                        trait_kind = AVM2Assembler.TRAIT_Getter;
	                    }
	                    /// case (s:Set) {
	                    else if (fx.func.name.kind is Set) {
	                        //print("Setter, target: " +target);
	                        trait_kind = AVM2Assembler.TRAIT_Setter;
	                    }
	                    /// }
	                    target.addTrait(new ABCOtherTrait(name, 0, trait_kind, 0, methidx));
	                }
	                /// }
	            }
	            /// case (fx:ClassFixture) {
	            else if (fx is ClassFixture) {
	                clsidx = cgClass(ctx, fx.cls);
	                target.addTrait(new ABCOtherTrait(name, 0, AVM2Assembler.TRAIT_Class, 0, clsidx));
	            }
	            /// case (fx:NamespaceFixture) {
	            else if (fx is NamespaceFixture) {
	                target.addTrait(new ABCSlotTrait(name, 0, true, 0, emitter.qname({ns:new PublicNamespace(""), id:"Namespace"},false), emitter.namespace(fx.ns), AVM2Assembler.CONSTANT_Namespace));
	            }
	            /// case (fx:TypeFixture) {
	            else if (fx is TypeFixture) {
	                //print ("warning: ignoring type fixture");
	            }
	            /// case (fx:*) { 
	            else {
	                throw "Internal error: unhandled fixture type" 
	            }
	            /// }
	        }
	    }
	
	    static function cgBlock(ctx, b) {
	        // FIXME -- more here
	        cgHead(ctx, b.head);
	        var stmts = b.stmts;
	        for ( var i=0 ; i < stmts.length ; i++ )
	            cgStmt(ctx, stmts[i]);
	    }
	
	/*
	    static function cgDefn(ctx, d) {
	        var { asm:asm, emitter:emitter } = ctx;
	        switch type (d) {
	        case (fd:FunctionDefn) {
	            assert( fd.func.name.kind is Ordinary );
	            var name = emitter.nameFromIdent(fd.func.name.ident);
	            //asm.I_findpropstrict(name); // name is fixture, thus always defined
	            //asm.I_newfunction(cgFunc(ctx, fd.func));
	            //asm.I_initproperty(name);
	        }
	        case (vd: VariableDefn) {
	            // nothing to do, right?
	        }
	        case (x:*) { throw "Internal error: unimplemented defn" }
	        }
	    }
	*/
	
	    static function extractNamedFixtures(fixtures)
	    {
	        var named = [];
	        var fix_length = fixtures ? fixtures.length : 0;
	        for(var i = 0; i < fix_length; ++i)
	        {
	            var tmp = fixtures[i];
	            var name=tmp[0], fixture=tmp[1];
	            if (name is PropName) {
                    named.push([name,fixture]);
                } else if (name is TempName) {
                    // do nothing
	            }
	        }
	        return named;
	    }
	    
	    static function extractUnNamedFixtures(fixtures)
	    {
	        var named = [];
	        var fix_length = fixtures ? fixtures.length : 0;
	        for(var i = 0; i < fix_length; ++i)
	        {
	            var tmp = fixtures[i];
	            var name=tmp[0], fixture=tmp[1];
	            if (name is PropName) {
                    // do nothing
                } else if (name is TempName) {
                    named.push([name,fixture]);
	            }
	       }
	       return named;
	   }
	
		static function getObject(emitter:ABCEmitter):int {
			return emitter.qname({ns:new PublicNamespace(""), id:"Object"},false);
		}
	
	    static function cgClass(ctx, c) {
	        
	        //var {asm:asm, emitter:emitter, script:script} = ctx;
	        var asm:AVM2Assembler=ctx.asm, emitter:ABCEmitter=ctx.emitter, script=ctx.script;
	        
	        var classname = emitter.qname(c.name,false);
	        var basename = c.baseName != null ? emitter.qname(c.baseName,false) : getObject(emitter);
	        
	        var cls = script.newClass(classname, basename);
	        
	        
	        var c_ctx = new CTX(asm, {tag:"class"}, cls);
	
	        // static fixtures
	        cgFixtures(c_ctx, c.classHead.fixtures);
	
	        // cinit - init static fixtures
	        var cinit = cls.getCInit();
	        var cinit_ctx = new CTX(cinit.asm, {tag:"cinit"}, cinit);
	        cgHead(cinit_ctx, {fixtures:[], exprs:c.classHead.exprs});
	        
			
	        var inst = cls.getInstance();
	        
	        // Context for the instance
	        var i_ctx = new CTX(asm, {tag:"instance"}, inst);
	        
	        // do instance slots
	        cgFixtures(i_ctx, c.instanceHead.fixtures);  // FIXME instanceHead and instanceInits should be unified
	        
	        inst.setIInit(cgCtor(i_ctx, c.constructor, {fixtures:[],exprs:c.instanceHead.exprs}));
	        
	        var clsidx = cls.finalize();
	        var Object_name = getObject(emitter);
	
			// original code
//	        asm.I_findpropstrict(Object_name);
//	        asm.I_getproperty(Object_name);
//	        asm.I_dup();
//	        asm.I_pushscope();
//	        asm.I_newclass(clsidx);
//	        asm.I_popscope();
//	        asm.I_getglobalscope();
//	        asm.I_swap();
//	        asm.I_initproperty(classname);

			// my code, trying to mimic ASC better
			asm.I_getscopeobject(0);
			// push Object
			asm.I_findpropstrict(Object_name);
			asm.I_getproperty(Object_name);
			asm.I_pushscope();
			// push full parent class name. flash.display.Sprite;
			if (Object_name!=basename) {
				asm.I_findpropstrict(basename);
				asm.I_getproperty(basename);
				asm.I_pushscope();
			}
			// class test extends Sprite
			asm.I_findpropstrict(basename);
			asm.I_getproperty(basename);
			asm.I_newclass(clsidx);
			// pop parent
			if (Object_name!=basename) {
				asm.I_popscope();
			}
			// pop Object
			asm.I_popscope();
			// init test
			asm.I_initproperty(classname);
	
	        return clsidx;
	    }
	    
	    /*  
	     *  Generate code for a ctor.
	     */
	    static function cgCtor(ctx, c, instanceInits) {
	        var formals_type = extractFormalTypes(ctx, c.func);
	        var method = new Method(ctx.script.e, formals_type, 2, "$construct", false);
	        var asm = method.asm;
	
	        var defaults = extractDefaultValues(ctx, c.func);
	        if( defaults.length > 0 )
	        {
	            method.setDefaults(defaults);
	        }
	        
	        // var t = asm.getTemp(); // XXX
	        var ctor_ctx = new CTX(asm, {tag:"function" /*, scope_reg:t*/}, method);
	       
	        asm.I_getlocal(0);
	        if (instanceInits.length>0) { // avoid unnecessary bytes for simple classes
		        asm.I_dup();
		        // Should this be instanceInits.inits only?
		        asm.I_pushscope();  // This isn't quite right...
		        for( var i = 0; i < instanceInits.length; i++ ) {
		            cgExpr(ctor_ctx, instanceInits[i]);
		            asm.I_pop();
		        }
		        cgHead(ctor_ctx, instanceInits);
		        asm.I_popscope();
		    }
	        //cgHead(ctor_ctx, instanceInits.inits, true);
	
	        // Push 'this' onto scope stack
	        //asm.I_getlocal(0);
	        //asm.I_pushscope();
	        // Create the activation object, and initialize params
	        //asm.I_newactivation(); // XXX
	        //asm.I_dup(); // XXX
	        //asm.I_setlocal(t); // XXX
	        //asm.I_dup(); // XXX
	        //asm.I_pushwith(); // XXX
	        // XXX less crude. hope I'm not missing something.
	        asm.I_pushscope();
	        
	        cgHead(ctor_ctx, c.func.params);
	
	        for ( var i=0 ; i < c.settings.length ; i++ ) {
	            cgExpr(ctor_ctx, c.settings[i]);
	            asm.I_pop();
	        }
	
	        // Eval super args, and call super ctor
	        asm.I_getlocal(0);
	        var nargs = c.superArgs.length;
	        for ( var i=0 ; i < nargs ; i++ )
	            cgExpr(ctx, c.superArgs[i]);
	        asm.I_constructsuper(nargs);
	        
	        //asm.I_popscope(); // XXX
	        //asm.I_getlocal(0); // XXX
	        //asm.I_pushscope();  //'this' // XXX
	        // asm.I_pushscope();  //'activation' // XXX
	        
	        cgHead(ctor_ctx, c.func.vars);
	
	        cgBlock(ctor_ctx, c.func.block);
	        
	        //asm.I_kill(t); // XXX
	        return method.finalize();
	    }
	
	    static function extractFormalTypes(ctx, f:Func) {
	        //var {emitter:emitter, script:script} = ctx;
	        var emitter=ctx.emitter, script=ctx.script;
	        function extractType(tmp) {
	        	var name=tmp[0], fixture=tmp[1];
	            return emitter.fixtureTypeToType(fixture);
	        }
	        
	        var named_fixtures = extractUnNamedFixtures(f.params.fixtures);
	        
	        return Util.map(extractType, named_fixtures);
	    }
	        
	    static function extractDefaultValues(ctx, f:Func) {
	        //var {emitter:emitter, script:script} = ctx;
	        var emitter=ctx.emitter, script=ctx.script;
	        function extractDefaults(expr) {
	            return emitter.defaultExpr(expr);
	        }
	
	        return Util.map(extractDefaults, f.defaults);
	    }
	    
	    /* Create a method trait in the ABCFile
	     * Generate code for the function
	     * Return the function index
	     */
	    static function cgFunc(ctx, f:Func, initScopeDepth) {
	        //var {emitter:emitter,script:script} = ctx0;
	        var emitter=ctx.emitter, script=ctx.script;
	        var formals_type = extractFormalTypes({emitter:emitter, script:script}, f);
	        var method = script.newFunction(formals_type,initScopeDepth);
	        var asm = method.asm;
	
	        var defaults = extractDefaultValues({emitter:emitter, script:script}, f);
	        if( defaults.length > 0 )
	        {
	            method.setDefaults(defaults);
	        }
	        
	        /* Create a new rib and populate it with the values of all the
	         * formals.  Add slot traits for all the formals so that the
	         * rib have all the necessary names.  Later code generation
	         * will add properties for all local (hoisted) VAR, CONST, and
	         * FUNCTION bindings, and they will be added to the rib too,
	         * but not initialized here.  (That may have to change, for
	         * FUNCTION bindings at least.)
	         *
	         * FIXME: if a local VAR shadows a formal, there's more
	         * elaborate behavior here, and the compiler must perform some
	         * analysis and avoid the shadowed formal here.
	         *
	         * God only knows about the arguments object...
	         */
	        var t = asm.getTemp();
	        asm.I_newactivation();
	        asm.I_dup();
	        asm.I_setlocal(t);
	        asm.I_pushscope();
	        
	        var ctx = new CTX(asm, {tag: "function", scope_reg:t, has_scope:true}, method);
	
	        cgHead(ctx, f.params);
	
	        cgHead(ctx, f.vars);
	        
	        /* Generate code for the body.  If there is no return statement in the
	         * code then the default behavior of the emitter is to add a returnvoid
	         * at the end, so there's nothing to worry about here.
	         */
	        cgBlock(ctx, f.block);
	        asm.I_kill(t);
	        return method.finalize();
	    }
	    
	    static function cgHead(ctx, head) {
	        //var {asm:asm, emitter:emitter, target:target} = ctx;
	        var asm=ctx.asm, emitter=ctx.emitter, target=ctx.target;
	        
	        function extractName(tmp) {
	        	var name=tmp[0], fixture=tmp[1];
	            return emitter.fixtureNameToName(name); //FIXME: shouldn't need ctx.
	        }
	        
	        function extractType(tmp) {
	        	var name=tmp[0], fixture=tmp[1];
	            return emitter.fixtureTypeToType(fixture); //FIXME: shouldn't need ctx.
	        }
	        
	        var named_fixtures = extractNamedFixtures(head.fixtures);
	/*
	        var formals = map(extractName, named_fixtures);
	        var formals_type = map(extractType, named_fixtures);
	        for ( var i=0 ; i < formals.length ; i++ ) {
	            if(!hasTrait(target.traits, formals[i], TRAIT_Slot) )
	                target.addTrait(new ABCSlotTrait(formals[i], 0, false, 0, formals_type[i]));
	        }
	*/
	        cgFixtures(ctx, named_fixtures);
	        for ( var i=0 ; i < head.exprs.length ; i++ ) {
	            cgExpr(ctx, head.exprs[i]);
	            asm.I_pop();
	        }
	    }
	
	    static function cgInits(ctx, inits, baseOnStk){
	        //var {asm:asm, emitter:emitter} = ctx;
	        var asm=ctx.asm, emitter=ctx.emitter;
	
	        var t = -1;
	        var inits_length = inits?inits.length:0;
	        for( var i=0; i < inits_length; ++i ) {
	            var tmp = inits[i];
	            var name=tmp[0], init=tmp[1];
	
	            var name_index = emitter.fixtureNameToName(name);
	
	            if( baseOnStk ) {
	                if(i < inits_length-1)
	                    asm.I_dup();
	            }
	            else
	                asm.I_findproperty(name_index);
	            
	            cgExpr(ctx, init);
	            asm.I_setproperty(name_index);
	        }
	        if( inits_length == 0 && baseOnStk )
	        {
	            asm.I_pop();
	        }
	  }
	    
	
	    // Handles scopes and finally handlers and returns a label, if appropriate, to
	    // branch to.  "tag" is one of "function", "break", "continue"
	
	    static function unstructuredControlFlow(ctx, hit, jump, msg) {
	        //var {stk:stk, asm:asm} = ctx;
	        var stk=ctx.stk, asm=ctx.asm;
	        while (stk != null) {
	            if (hit(stk)) {
	                if (jump)
	                    asm.I_jump(stk.target);
	                return;
	            }
	            else {
	                if(stk.has_scope) {
	                    asm.I_popscope();
	                }
	                // FIXME
	                // if there's a FINALLY, visit it here
	            }
	            stk = stk.link;
	        }
	        throw msg;
	    }
	
	    static function restoreScopes(ctx) {
	        //var {stk:stk, asm:asm} = ctx;
	        var stk=ctx.stk, asm=ctx.asm;
	        var regs = [];
	        while (stk != null) {
	            if(stk.has_scope) {
	                regs.push(stk.scope_reg);
	            }
	            if( stk.tag != "function" ) {
	                stk = stk.link;
	            }
	            else {
	                stk = null;
	            }
	        }
	        for( var i = regs.length-1; i >= 0; i-- )
	        {
	            asm.I_getlocal(regs[i]);
	            asm.I_pushscope();
	        }
	    }
	
	    // The following return extended contexts
	    static function pushBreak(ctx, labels, target) {
	        return push(ctx, { tag:"break", labels:labels, target:target, has_scope:false });
	    }
	
	    static function pushContinue(ctx, labels, target) {
	        return push(ctx, { tag:"continue", labels:labels, target:target, has_scope:false });
	    }
	
	    static function pushFunction(ctx /*more*/) {
	        // FIXME
	    }
	
	    static function pushWith(ctx /*more*/) {
	        // FIXME
	    }
	
	    static function pushLet(ctx /*more*/) {
	    }
	
	    static function pushCatch(ctx, scope_reg ) {
	        return push(ctx, {tag:"catch", has_scope:true, scope_reg:scope_reg});
	        // FIXME anything else?
	    }
	
	    static function pushFinally(ctx /*more*/) {
	        // FIXME
	    }

		// cogen-expr

	    static function cgExpr(ctx, e) {
	    	if (e is TernaryExpr) {
	    		cgTernaryExpr(ctx, e);
	    	} else if (e is BinaryExpr) {
	        	cgBinaryExpr(ctx, e);
	    	} else if (e is BinaryTypeExpr) {
	        	cgBinaryTypeExpr(ctx, e);
	     	} else if (e is UnaryExpr) {
	        	cgUnaryExpr(ctx, e);
	      	} else if (e is TypeExpr) { 
	      		cgTypeExpr(ctx, e);
	      	} else if (e is ThisExpr) {
	      		cgThisExpr(ctx, e);
	      	} else if (e is YieldExpr) {
	      		cgYieldExpr(ctx, e);
	      	} else if (e is SuperExpr) {
	      		throw "Internal error: SuperExpr can't appear here";
	      	} else if (e is LiteralExpr) {
	      		cgLiteralExpr(ctx, e);
	      	} else if (e is CallExpr) {
	      		cgCallExpr(ctx, e);
	      	} else if (e is ApplyTypeExpr) {
	      		cgApplyTypeExpr(ctx, e);
	      	} else if (e is LetExpr) {
	      		cgLetExpr(ctx, e);
	      	} else if (e is NewExpr) {
	      		cgNewExpr(ctx, e);
	      	} else if (e is ObjectRef) {
	      		cgObjectRef(ctx, e);
	      	} else if (e is LexicalRef) {
	      		cgLexicalRef(ctx, e);
	      	} else if (e is SetExpr) {
	      		cgSetExpr(ctx, e);
	      	} else if (e is ListExpr) {
	      		cgListExpr(ctx, e);
	      	} else if (e is InitExpr) {
	      		cgInitExpr(ctx, e);
	      	} else if (e is SliceExpr) {
	      		cgSliceExpr(ctx, e);
	      	} else if (e is GetTemp) {
	      		cgGetTempExpr(ctx, e);
	      	} else if (e is GetParam) {
	      		cgGetParamExpr(ctx, e);
	      	} else {
	        	throw ("Internal error: Unimplemented expression type " + e);
	        }
	    }
	
	    static function cgTernaryExpr(ctx, tmp) {
	    	var test=tmp.e1, consequent=tmp.e2, alternate=tmp.e3;
	        var asm = ctx.asm;
	        cgExpr(ctx, test);
	        var L0 = asm.I_iffalse(undefined);
	        cgExpr(ctx, consequent);
	        asm.I_coerce_a();
	        var L1 = asm.I_jump(undefined);
	        asm.I_label(L0);
	        cgExpr(ctx, alternate);
	        asm.I_coerce_a();
	        asm.I_label(L1);
	    }
	
	    static function cgBinaryExpr(ctx, e) {
	        var asm:AVM2Assembler = ctx.asm;
	        if (e.op is LogicalAnd) {
	            cgExpr(ctx, e.e1);
	            asm.I_convert_b();
	            asm.I_dup();
	            var L0 = asm.I_iffalse(undefined);
	            asm.I_pop();
	            cgExpr(ctx, e.e2);
	            asm.I_convert_b();
	            asm.I_label(L0);
	        }
	        else if (e.op is LogicalOr) {
	            cgExpr(ctx, e.e1);
	            asm.I_convert_b();
	            asm.I_dup();
	            var L0 = asm.I_iftrue(undefined);
	            asm.I_pop();
	            cgExpr(ctx, e.e2);
	            asm.I_convert_b();
	            asm.I_label(L0);
	        }
	        else {
	            cgExpr(ctx, e.e1);
	            cgExpr(ctx, e.e2);
	            var op = e.op;
	            if (op is Plus) {
	            	asm.I_add();
	            } else if (op is Minus) {
	            	asm.I_subtract();
	            } else if (op is Times) {
	            	asm.I_multiply();
	            } else if (op is Divide) {
	            	asm.I_divide();
	            } else if (op is Remainder) {
	            	asm.I_modulo();
	            } else if (op is LeftShift) {
	            	asm.I_lshift();
	            } else if (op is RightShift) {
	            	asm.I_rshift();
	            } else if (op is RightShiftUnsigned) {
	            	asm.I_urshift();
	            } else if (op is BitwiseAnd) {
	            	asm.I_bitand();
	            } else if (op is BitwiseOr) { 
	            	asm.I_bitor();
	            } else if (op is BitwiseXor) {
	            	asm.I_bitxor();
	            } else if (op is InstanceOf) {
	            	asm.I_instanceof();
	            } else if (op is In) {
	            	asm.I_in();
	            } else if (op is Equal) {
	            	asm.I_equals();
	            } else if (op is NotEqual) {
	            	asm.I_equals(); 
	            	asm.I_not();
	            } else if (op is StrictEqual) {
	            	asm.I_strictequals();
	            } else if (op is StrictNotEqual) {
	            	asm.I_strictequals(); 
	            	asm.I_not();
	            } else if (op is Less) { 
	            	asm.I_lessthan();
	            } else if (op is LessOrEqual) {
	            	asm.I_lessequals();
	            } else if (op is Greater) {
	            	asm.I_greaterthan();
	            } else if (op is GreaterOrEqual) {
	            	asm.I_greaterequals();
	            } else {
	            	throw "Internal error: Unimplemented binary operator";
	            }
	        }
	    }
	
	    static function cgBinaryTypeExpr(ctx, e) {
	        var asm = ctx.asm;
	        cgExpr(ctx, e.e1);
	        cgTypeExprHelper(ctx, e.e2);
	        var op = e.op;
	        if (op is CastOp) { asm.I_coerce() }
	        else if (op is IsOp) { asm.I_istypelate() }
	        else if (op is ToOp) {
	            // If the type expression object has a property meta::convert then invoke that
	            // method and return its result.  Otherwise, behave as cast.
	            asm.I_dup();
	            asm.I_getproperty(ctx.emitter.meta_convert_name);
	            asm.I_pushundefined();
	            asm.I_strictequals();
	            var L1 = asm.I_iftrue(undefined);
	            // not undefined
	            asm.I_swap();
	            asm.I_callproperty(ctx.emitter.meta_convert_name, 1);
	            var L2 = asm.I_jump(undefined);
	            asm.I_label(L1);
	            // undefined
	            asm.I_coerce();
	            asm.I_label(L2);
	        }
	        else { throw "Internal error: Unimplemented binary type operator" }
	    }
	
	    static function cgTypeExpr(ctx, e) {
	        cgTypeExprHelper(ctx, e.ex);
	    }
	
	    static function cgTypeExprHelper(ctx, ty) {
	        //var {asm:asm, emitter:emitter} = ctx;
	        var asm=ctx.asm, emitter=ctx.emitter;
	        if (ty is TypeName) {
	            //var name = cgIdentExpr(ctx, ty.ident);
	            asm.I_findpropstrict(cgIdentExpr(ctx, ty.ident));
	            asm.I_getproperty(cgIdentExpr(ctx, ty.ident));
	        } else {
	            /* FIXME */
	            throw ("Unimplemented: type expression type " + ty);
	        }
	    }
	
	    static function cgUnaryExpr(ctx, e) {
	        //var {asm:asm, emitter:emitter} = ctx;
	        var asm=ctx.asm, emitter=ctx.emitter;
	
	        function incdec(pre, inc) {
	        	var x = e.e1;
	        	if (x is LexicalRef) {
	            	var lr:LexicalRef = x as LexicalRef;
	                //name = cgIdentExpr(ctx, lr.ident);
	                asm.I_findpropstrict(cgIdentExpr(ctx, lr.ident));
	            } else if (x is ObjectRef) {
	            	var or:ObjectRef = x as ObjectRef;
	                //name = cgIdentExpr(ctx, or.ident);
	                cgExpr(ctx, or.base);
	            } else {
	            	throw "Internal error: invalid lvalue";
	            }
	            asm.I_dup();
	            asm.I_getproperty(cgIdentExpr(ctx, e.e1.ident));
	            var t = asm.getTemp();
	            if (!pre) {
	                asm.I_dup();
	                asm.I_setlocal(t);
	            }
	            if (inc)
	                asm.I_increment();
	            else
	                asm.I_decrement();
	            if (pre) {
	                asm.I_dup();
	                asm.I_setlocal(t);
	            }
	            asm.I_setproperty(cgIdentExpr(ctx, e.e1.ident));
	            asm.I_getlocal(t);
	            asm.killTemp(t);
	        }

			var op = e.op;	
	        if (op is Delete) {
	        	var e1 = e.e1;
	        	if (e1 is LexicalRef) {
	            	var lr:LexicalRef = e1 as LexicalRef;
	                //var name = cgIdentExpr(ctx, lr.ident);
	                asm.I_findproperty(cgIdentExpr(ctx, lr.ident));
	                asm.I_deleteproperty(cgIdentExpr(ctx, lr.ident));
	            } else if (e1 is ObjectRef) {
	            	var or:ObjectRef = e1 as ObjectRef;
	                //var name = cgIdentExpr(ctx, or.ident);
	                cgExpr(ctx, or.base);
	                asm.I_deleteproperty(cgIdentExpr(ctx, or.ident));
	            } else {
	                cgExpr(ctx, e1);
	                asm.I_pop();
	                asm.I_pushtrue();
	            }
	        } else if (op is Void) {
	            cgExpr(ctx, e.e1);
	            asm.I_pop();
	            asm.I_pushundefined();
	        } else if (op is Typeof) {
	            if (e.e1 is LexicalRef) {
	                //var name = cgIdentExpr(ctx, e.e1.ident);
	                ctx.asm.I_findproperty(cgIdentExpr(ctx, e.e1.ident));
	                ctx.asm.I_getproperty(cgIdentExpr(ctx, e.e1.ident));
	            }
	            else {
	                cgExpr(ctx, e.e1);
	                // I_typeof is not compatible with ES4, so do something elaborate to work around that.
	                asm.I_dup();
	                asm.I_pushnull();
	                asm.I_strictequals();
	                var L0 = asm.I_iffalse(undefined);
	                asm.I_pushstring(ctx.cp.stringUtf8("null"));
	                var L1 = asm.I_jump(undefined);
	                asm.I_label(L0);
	                asm.I_typeof();
	                asm.I_label(L1);
	            }
	        } 
	        else if (op is PreIncr) { incdec(true, true) }
	        else if (op is PreDecr) { incdec(true, false) }
	        else if (op is PostIncr) { incdec(false, true) }
	        else if (op is PostDecr) { incdec(false, false) }
	        else if (op is UnaryPlus) {
	            cgExpr(ctx, e.e1);
	            asm.I_convert_d();
	        }
	        else if (op is UnaryMinus) {
	            cgExpr(ctx, e.e1);
	            asm.I_negate();
	        }
	        else if (op is BitwiseNot) {
	            cgExpr(ctx, e.e1);
	            asm.I_bitnot();
	        }
	        else if (op is LogicalNot) {
	            cgExpr(ctx, e.e1);
	            asm.I_not();
	        } else {
	        	throw "Internal error: Unimplemented unary operation";
	        }
	    }
	
	    static function cgThisExpr(ctx, e) {
	        ctx.asm.I_getlocal(0);
	    }
	
	    static function cgYieldExpr(ctx, e) {
	        // FIXME
	        throw "Unimplemented 'yield' expression";
	    }
	
	    static function cgCallExpr(ctx, e) {
	        //var {asm:asm, emitter:emitter} = ctx;
	        var asm=ctx.asm, emitter=ctx.emitter;
	        
	        var name = null;
	        var x = e.expr;
	        if (x is ObjectRef) {
	        	var or:ObjectRef = x as ObjectRef;
	            name = or.ident; // = cgIdentExpr(ctx, or.ident);
	            cgExpr(ctx, or.base);
	        } else if (x is LexicalRef) {
	        	var lr:LexicalRef = x as LexicalRef;
	            asm.I_findpropstrict(cgIdentExpr(ctx, lr.ident));
	            name = lr.ident;
	        } else {
	            cgExpr(ctx, e.expr);
	            asm.I_pushnull();
	        }
	        var nargs = e.args.length;
	        for ( var i=0 ; i < nargs ; i++ )
	            cgExpr(ctx, e.args[i]);
	        if (name != null)
	            asm.I_callproperty(cgIdentExpr(ctx, name),nargs);
	        else
	            asm.I_call(nargs);
	    }
	
	    static function cgApplyTypeExpr(ctx, e) {
	        // FIXME
	        throw "Unimplemented type application expression";
	    }
	
	    static function cgLetExpr(ctx, e) {
	        cgHead(ctx, e.head);
	        cgExpr(ctx, e.expr);
	    }
	
	    static function cgNewExpr(ctx, e) {
	        cgExpr(ctx, e.expr);
	        for ( var i=0 ; i < e.args.length ; i++ )
	            cgExpr(ctx, e.args[i]);
	        ctx.asm.I_construct(e.args.length);
	    }
	
	    static function cgObjectRef(ctx, e) {
	        cgExpr(ctx, e.base);
	        ctx.asm.I_getproperty(cgIdentExpr(ctx, e.ident));
	    }
	
	    static function cgLexicalRef(ctx, e) {
	        var asm = ctx.asm;
	        //var name = cgIdentExpr(ctx, e.ident);
	        asm.I_findpropstrict(cgIdentExpr(ctx, e.ident));
	        asm.I_getproperty(cgIdentExpr(ctx, e.ident));
	    }
	
	    static function cgSetExpr(ctx, e) {
	        //var {asm:asm, emitter:emitter} = ctx;
	        var asm=ctx.asm, emitter=ctx.emitter;

	        var name = null;
	
	        // The switch leaves an object on the stack and sets "name"
	        var lhs = e.le;
	        if (lhs is ObjectRef) {
	            cgExpr(ctx, lhs.base);
	            name = lhs.ident;
	        }
	        else if (lhs is LexicalRef) {
	            //name = cgIdentExpr(ctx, lhs.ident);
	            name = lhs.ident;
	            if (e.op is Assign)
	                asm.I_findproperty(cgIdentExpr(ctx, lhs.ident));
	            else
	                asm.I_findpropstrict(cgIdentExpr(ctx, lhs.ident));
	        } else {
	        	throw "Internal error: illegal ref type";
	        }
	
	        if (e.op is AssignLogicalAnd) {
	            asm.I_dup();
	            asm.I_getproperty(cgIdentExpr(ctx, name));
	            var L0 = asm.I_iffalse(undefined);
	            asm.I_pop();
	            cgExpr(ctx, e.re);
	            asm.I_label(L0);
	            asm.I_setproperty(cgIdentExpr(ctx, name));  // Always store it; the effect is observable
	        }
	        else if (e.op is AssignLogicalOr) {
	            asm.I_dup();
	            asm.I_getproperty(cgIdentExpr(ctx, name));
	            var L0 = asm.I_iftrue(undefined);
	            asm.I_pop();
	            cgExpr(ctx, e.re);
	            asm.I_label(L0);
	            asm.I_setproperty(cgIdentExpr(ctx, name));  // Always store it; the effect is observable
	        }
	        else {
	            var use_once_name = cgIdentExpr(ctx, name);
	            cgExpr(ctx, e.re);
	            var t = asm.getTemp();
	            if (e.op is Assign) {
	                asm.I_dup();
	                asm.I_setlocal(t);
	                asm.I_setproperty(use_once_name);
	            }
	            else {
	                asm.I_dup();
	                asm.I_getproperty(cgIdentExpr(ctx, name));
	                var op = e.op;
	                if (op is AssignPlus) { asm.I_add() }
	                else if (op is AssignMinus) { asm.I_subtract() }
	                else if (op is AssignTimes) { asm.I_multiply() }
	                else if (op is AssignDivide) { asm.I_divide() }
	                else if (op is AssignRemainder) { asm.I_modulo() }
	                else if (op is AssignLeftShift) { asm.I_lshift() }
	                else if (op is AssignRightShift) { asm.I_rshift() }
	                else if (op is AssignRightShiftUnsigned) { asm.I_urshift() }
	                else if (op is AssignBitwiseAnd) { asm.I_bitand() }
	                else if (op is AssignBitwiseOr) { asm.I_bitor() }
	                else if (op is AssignBitwiseXor) { asm.I_bitxor() }
	                else { throw "Internal error: ASSIGNOP not supported" }
	                asm.I_dup();
	                asm.I_setlocal(t);
	                asm.I_setproperty(use_once_name);
	            }
	            asm.I_getlocal(t);
	            asm.killTemp(t);
	        }
	    }
	
	    static function cgListExpr(ctx, e) {
	        var asm = ctx.asm;
	        for ( var i=0, limit=e.exprs.length ; i < limit ; i++ ) {
	            cgExpr(ctx, e.exprs[i]);
	            if (i < limit-1)
	                asm.I_pop();
	        }
	    }
	
	    static function cgInitExpr(ctx, e) {
	        var asm = ctx.asm;
	        var baseOnStk = false;
	//        cgHead(ctx, e.head);
			if (e.target is InstanceInit) {
	            // Load this on the stack
	            asm.I_getlocal(0);
	            baseOnStk = true;
	        }
	        cgInits(ctx, e.inits, baseOnStk);
	    	asm.I_pushundefined(); // exprs need to leave something on the stack
	        // FIXME: should this be the value of the last init?
	    }
	
	    static function cgLiteralExpr(ctx, e) {
	
	        function cgArrayInitializer(ctx, tmp) {
	        	var exprs=tmp.exprs;
	            var asm = ctx.asm;
	            for ( var i=0 ; i < exprs.length ; i++ ) {
	                cgExpr(ctx, exprs[i]);
	            }
	            asm.I_newarray(exprs.length);
	/*            asm.I_getglobalscope();
	            asm.I_getproperty(ctx.emitter.Array_name);
	            asm.I_construct(0);
	            asm.I_dup();
	            var t = asm.getTemp();
	            asm.I_setlocal(t);
	            for ( var i=0 ; i < exprs.length ; i++ ) {
	                if (exprs[i] !== undefined) {
	                    asm.I_getlocal(t);
	                    asm.I_pushuint(cg.uint32(i));
	                    cgExpr(ctx, exprs[i]);
	                    asm.I_setproperty(genMultinameL());
	                }
	            }
	            asm.I_getlocal(t);
	            asm.killTemp(t);
	*/        }
	
	        function cgObjectInitializer(ctx, tmp) {
	        	var fields = tmp.fields;
	            //var {asm:asm, emitter:emitter} = ctx;
		        var asm=ctx.asm, emitter=ctx.emitter;
	            asm.I_findpropstrict(ctx.emitter.Object_name);
	            asm.I_constructprop(ctx.emitter.Object_name, 0);
	            var t = asm.getTemp();
	            asm.I_setlocal(t);
	            for ( var i=0 ; i < fields.length ; i++ ) {
	                //cgLiteralField(fields[i]);
	                var f = fields[i];
	                asm.I_getlocal(t);
	                cgExpr(ctx, f.expr);
	                asm.I_setproperty(cgIdentExpr(ctx, f.ident));
	            }
	            //asm.I_newobject(fields.length);
	            asm.I_getlocal(t);
	            asm.killTemp(t);
	        }
	
	        function cgRegExpLiteral(tmp1, tmp2) {
	        	var asm=tmp1.asm, cp=tmp1.cp, src=tmp2.src;
	            // src is "/.../flags"
	            // Slow...
	            var p = src.lastIndexOf('/');
	            asm.I_getglobalscope();
	            asm.I_getproperty(ctx.emitter.RegExp_name);
	            asm.I_pushstring(cp.stringUtf8(src.substring(1,p)));
	            asm.I_pushstring(cp.stringUtf8(src.substring(p+1)));
	            asm.I_construct(2);
	        }
	
	        var asm = ctx.asm;
	        var e = e.literal; // XXX risky, but looks okay here.
	        if (e is LiteralNull) { asm.I_pushnull() }
	        else if (e is LiteralUndefined) { asm.I_pushundefined() }
	        else if (e is LiteralInt) { asm.I_pushint(ctx.cp.int32(e.intValue)) }
	        else if (e is LiteralUInt) { asm.I_pushuint(ctx.cp.uint32(e.uintValue)) }
	        else if (e is LiteralDouble) { asm.I_pushdouble(ctx.cp.float64(e.doubleValue)) }
	        else if (e is LiteralDecimal) { 
	            var i : int = int(e.decimalValue);
	            var n : Number = Number(e.decimalValue);
	            if( e.decimalValue == String(i) ) {
	                asm.I_pushint(ctx.cp.int32(i));
	            }
	            else if( e.decimalValue == String(n) ) {
	                asm.I_pushdouble(ctx.cp.float64(Number(n))) 
	            }
	            else {
	                // Work around RI bug - converts all hex strings to 0
	                asm.I_pushstring(ctx.cp.stringUtf8(e.decimalValue));
	                asm.I_convert_d();
	            }
	        } // FIXME - the AVM2 can't handle decimal yet
	        else if (e is LiteralString) { asm.I_pushstring(ctx.cp.stringUtf8(e.strValue)) }
	        else if (e is LiteralBoolean) {
	            if (e.booleanValue)
	                asm.I_pushtrue();
	            else
	                asm.I_pushfalse();
	        }
	        else if (e is LiteralFunction) { asm.I_newfunction(cgFunc(ctx, e.func, 0)) } // XXX setting an explicit depth of 0
	        else if (e is LiteralArray) { cgArrayInitializer(ctx, e) }
	        else if (e is LiteralObject) { cgObjectInitializer(ctx, e) }
	        else if (e is LiteralRegExp) { cgRegExpLiteral(ctx, e) }
	            // case (e:LiteralNamesace) { cgNamespaceLiteral(ctx, e) }
	        else { throw "Unimplemented LiteralExpr " + e }
	    }
	
	    static function cgSliceExpr(ctx, e) {
	        // FIXME
	        throw "Unimplemented slice expression";
	    }
	
	    static function cgGetTempExpr(ctx, e) {
	        // FIXME
	        //let{asm:asm, emitter:emitter} = ctx;
	        var asm=ctx.asm, emitter=ctx.emitter;
	        var qn = emitter.qname ({ns: Ast.noNS,id:"$t"+e.n},false);
	        asm.I_findpropstrict(qn);
	        asm.I_getproperty(qn);
	    }
	
	    static function cgGetParamExpr(ctx, e) {
	        var asm = ctx.asm;
	        asm.I_getlocal(e.n + 1);  //account for 'this'
	    }
	    
	    static function cgIdentExpr(ctx, e) {
	        //var {asm:asm, emitter:emitter} = ctx;
	        var asm=ctx.asm, emitter=ctx.emitter;
	        if (e is Identifier) {
	            var id:Identifier = e as Identifier;
	            return emitter.multiname(id,false);
	        } else if (e is ExpressionIdentifier) {
	            var ei:ExpressionIdentifier = e as ExpressionIdentifier;
				cgExpr(ctx, ei.expr);
				return emitter.multinameL(ei,false);
	        } else if (e is QualifiedIdentifier) {
	            var qi:QualifiedIdentifier = e as QualifiedIdentifier;
				var e = qi.qual;
				if (e is LexicalRef) {	            
                	var lr:LexicalRef = e as LexicalRef;
                    // Hack to deal with namespaces for now...
                    // later we will have to implement a namespace lookup to resolve qualified typenames
                    return emitter.qname({ns:new PublicNamespace((lr.ident as Object).ident), id:qi.ident},false)
                } else {
                    /// cgExpr(ctx, qi.qual);
                    /// return emitter.rtqname(qi);
                    throw "unsupported form of qualified identifier " + qi.ident;
                }
			} else {
	            throw ("Unimplemented cgIdentExpr " + e);
	        }
	    }
			
		// cogen-stmt

	    static function cgStmt(ctx, s) {
	        if (s is EmptyStmt) { }
	        else if (s is ExprStmt) { cgExprStmt(ctx, s) }
	        else if (s is ClassBlock) { cgClassBlock(ctx, s) }
	        else if (s is ForInStmt) { cgForInStmt(ctx, s) }
	        else if (s is ThrowStmt) { cgThrowStmt(ctx, s) }
	        else if (s is ReturnStmt) { cgReturnStmt(ctx, s) }
	        else if (s is BreakStmt) { cgBreakStmt(ctx,s) }
	        else if (s is ContinueStmt) { cgContinueStmt(ctx,s) }
	        else if (s is BlockStmt) { cgBlockStmt(ctx,s) }
	        else if (s is LabeledStmt) { cgLabeledStmt(ctx,s) }
	        else if (s is LetStmt) { cgLetStmt(ctx,s) }
	        else if (s is WhileStmt) { cgWhileStmt(ctx, s) }
	        else if (s is DoWhileStmt) { cgDoWhileStmt(ctx, s) }
	        else if (s is ForStmt) { cgForStmt(ctx, s) }
	        else if (s is IfStmt) { cgIfStmt(ctx, s) }
	        else if (s is WithStmt) { cgWithStmt(ctx, s) }
	        else if (s is TryStmt) { cgTryStmt(ctx, s) }
	        else if (s is SwitchStmt) { cgSwitchStmt(ctx, s) }
	        else if (s is SwitchTypeStmt) { cgSwitchTypeStmt(ctx, s) }
	        else if (s is DXNStmt) { cgDxnStmt(ctx, s) }
	    }
	
	    static function cgExprStmt(ctx, s) {
	        cgExpr(ctx, s.expr);
	        ctx.asm.I_pop();  // FIXME the last expr stmt of the program must save its value
	    }
	
	    static function cgClassBlock(ctx, s) {
	        cgBlock(ctx, s.block);
	    }
	    
	    static function cgLetStmt(ctx, s) {
	    	// XXX FIXME
	    	throw "Not implemented";
	    }
	    static function cgDxnStmt(ctx, s) {
	    	// XXX FIXME
	    	throw "Not implemented.";
	    }
	
	    static function cgBlockStmt(ctx, s) {
	        cgBlock(ctx, s.block);
	    }
	
	    static function cgLabeledStmt(ctx, tmp) {
	    	var label=tmp.label, stmt=tmp.stmt;
	        var L0 = ctx.asm.newLabel();
	        cgStmt(pushBreak(ctx, [label], L0), stmt);
	        ctx.asm.I_label(L0);
	    }
	
	    static function cgIfStmt(ctx, s) {
	        //var {expr:test, then:consequent, elseOpt:alternate} = s;
	        var test=s.expr, consequent=s.then, alternate=s.elseOpt;
	        var asm = ctx.asm;
	        cgExpr(ctx, test);
	        var L0 = asm.I_iffalse(undefined);
	        cgStmt(ctx, consequent);
	        if (alternate != null) {
	            var L1 = asm.I_jump(undefined);
	            asm.I_label(L0);
	            cgStmt(ctx, alternate);
	            asm.I_label(L1);
	        }
	        else
	            asm.I_label(L0);
	    }
	
	    // Probable AST bug: should be no fixtures here, you can't define
	    // vars in the WHILE head.
	    static function cgWhileStmt(ctx, s) {
	        //var {stmt: stmt, labels: labels, expr: expr} = s;
	        var stmt=s.stmt, labels=s.labels, expr=s.expr;
	        var asm    = ctx.asm;
	        var Lbreak = asm.newLabel();
	        var Lcont  = asm.I_jump(undefined);
	        var Ltop   = asm.I_label(undefined);
	        cgStmt(pushBreak(pushContinue(ctx, labels, Lcont), labels, Lbreak), stmt);
	        asm.I_label(Lcont);
	        cgExpr(ctx, expr);
	        asm.I_iftrue(Ltop);
	        asm.I_label(Lbreak);
	    }
	
	    // Probable AST bug: should be no fixtures here, you can't define
	    // vars in the DO-WHILE head.
	    static function cgDoWhileStmt(ctx, s) {
	        //var {stmt: stmt, labels: labels, expr: expr} = s;
	        var stmt=s.stmt, labels=s.labels, expr=s.expr;
	        var asm    = ctx.asm;
	        var Lbreak = asm.newLabel();
	        var Lcont  = asm.newLabel();
	        var Ltop   = asm.I_label(undefined);
	        cgStmt(pushBreak(pushContinue(ctx, labels, Lcont), labels, Lbreak), stmt);
	        asm.I_label(Lcont);
	        cgExpr(ctx, expr);
	        asm.I_iftrue(Ltop);
	        asm.I_label(Lbreak);
	    }
	
	    static function cgForStmt(ctx, s) {
	        //var {vars:vars,init:init,cond:cond,incr:incr,stmt:stmt,labels:labels} = s;
	        var vars=s.vars, init=s.init, cond=s.cond, incr=s.incr, stmt=s.stmt, labels=s.labels;
	        // FIXME: fixtures
	        // FIXME: code shape?
	        var asm:AVM2Assembler = ctx.asm;
	        cgHead(ctx, vars);
	        var Lbreak = asm.newLabel();
	        var Lcont = asm.newLabel();
	        if (init != null) {
	            cgExpr(ctx, init);
	            asm.I_pop();
	        }
	        var Ltop = asm.I_label(undefined);
	        if (cond != null) {
	            cgExpr(ctx, cond);
	            asm.I_iffalse(Lbreak);
	        }
	        cgStmt(pushBreak(pushContinue(ctx, labels, Lcont), labels, Lbreak), stmt);
	        asm.I_label(Lcont);
	        if (incr != null)
	        {
	            cgExpr(ctx, incr);
	            asm.I_pop();
	        }
	        asm.I_jump(Ltop);
	        asm.I_label(Lbreak);
	    }
	
	    static function cgForInStmt(ctx, s:ForInStmt) {
	    	var vars=s.vars, init=s.init, expr=s.expr, stmt=s.stmt, labels=s.labels;
	    	var asm:AVM2Assembler = ctx.asm;
	    	cgHead(ctx, vars);
	        var Lbreak = asm.newLabel();
	        var Ltmp = asm.newLabel();
	        var tmp1 = asm.getTemp();
	        var tmp2 = asm.getTemp();
	        
	        asm.I_pushbyte(0);     // pushbyte 0
	        asm.I_setlocal(tmp1);	   // setlocal 2
	        cgExpr(ctx, expr);   // eval "expr"
	        asm.I_coerce_a();      // coerce_a
	        asm.I_setlocal(tmp2);    // setlocal 3
	        var Lcont = asm.I_jump(undefined); // jump L1
	        asm.I_label(Ltmp);    // L2: label
	    	asm.I_getlocal(tmp2);    // getlocal3
	    	asm.I_getlocal(tmp1);    // getlocal2
	    	asm.I_nextname();      // nextname (For each is similar, but with nextvalue here)
	    	
	    	var name = cgIdentExpr(ctx, init);
			asm.I_findproperty(name);
			asm.I_swap();
			asm.I_setproperty(name);
	    	
	        cgStmt(pushBreak(pushContinue(ctx, labels, Lcont), labels, Lbreak), stmt); // ...
	    	
	    	asm.I_label(Lcont);	   // L1:
	    	asm.I_hasnext2(tmp2, tmp1);  // hasnext2 3 2
	    	asm.I_iftrue(Lcont);   // if true L2
	    	asm.I_label(Lbreak);
	    	asm.I_kill(tmp2);         // kill 3
	    	asm.I_kill(tmp1);         // kill 2
	    }
	    static function cgBreakStmt(ctx, s) {
	        //var {ident: ident} = s;
	        var ident=s.ident;
	        var stk = ctx.stk;
	        function hit (node) {
	            return node.tag == "break" && (ident == null || Util.memberOf(ident, stk.labels))
	        }
	        unstructuredControlFlow(ctx,
	                                hit,
	                                true,
	                                "Internal error: definer should have checked that all referenced labels are defined");
	    }
	
	    static function cgContinueStmt(ctx, s) {
	        //var {ident: ident} = s;
	        var ident=s.ident;
	        var stk = ctx.stk;
	        function hit(node) {
	            return node.tag == "continue" && (ident == null || Util.memberOf(ident, stk.labels))
	        }
	        unstructuredControlFlow(ctx,
	                                hit,
	                                true,
	                                "Internal error: definer should have checked that all referenced labels are defined");
	    }
	
	    static function cgThrowStmt(ctx, s) {
	        cgExpr(ctx, s.expr);
	        ctx.asm.I_throw();
	    }
	
	    static function cgReturnStmt(ctx, s) {
	        var asm = ctx.asm;
	        var t = null;
	        if (s.expr != null) {
	            cgExpr(ctx, s.expr);
	            t = asm.getTemp();
	            asm.I_setlocal(t);
	        }
	        function hit(node){
	            return node.tag == "function" 
	        }
	        unstructuredControlFlow(ctx,
	                                hit,
	                                false,
	                                "Internal error: definer should have checked that top-level code does not return");
	        if (s.expr == null)
	            asm.I_returnvoid();
	        else {
	            asm.I_getlocal(t);
	            asm.I_returnvalue();
	            asm.killTemp(t);
	        }
	    }
	
	    static function cgSwitchStmt(ctx, s) {
	        //var {expr:expr, cases:cases, labels:labels} = s;
	        var expr=s.expr, cases=s.cases, labels=s.labels;
	        var asm = ctx.asm;
	        cgExpr(ctx, expr);
	        var t = asm.getTemp();
	        asm.I_setlocal(t);
	        var Ldefault = null;
	        var Lnext = null;
	        var Lfall = null;
	        var Lbreak = asm.newLabel();
	        var nctx = pushBreak(ctx, labels, Lbreak);
	        var hasBreak = false;
	        for ( var i=0 ; i < cases.length ; i++ ) {
	            var c = cases[i];
	
	            if (c.expr == null) {
	                Util.assert (Ldefault==null);
	                Ldefault = asm.I_label(undefined);    // label default pos
	            }
	
	            if (Lnext !== null) {
	                asm.I_label(Lnext);          // label next pos
	                Lnext = null;
	            }
	
	            if (c.expr != null) {
	                cgExpr(nctx, c.expr);        // check for match
	                asm.I_getlocal(t);
	                asm.I_strictequals();
	                Lnext = asm.I_iffalse(undefined);  // if no match jump to next label
	            }
	
	            if (Lfall !== null) {         // label fall through pos
	                asm.I_label(Lfall);
	                Lfall = null;
	            }
	
	            var stmts = c.stmts;
	            for ( var j=0 ; j < stmts.length ; j++ ) {
	                cgStmt(nctx, stmts[j] );
	            }
	
	            Lfall = asm.I_jump (undefined);         // fall through
	        }
	        if (Lnext !== null)
	            asm.I_label(Lnext);
	        if (Ldefault !== null)
	            asm.I_jump(Ldefault);
	        if (Lfall !== null)
	            asm.I_label(Lfall);
	        asm.I_label(Lbreak);
	        asm.killTemp(t);
	    }
	
	    static function cgSwitchTypeStmt(ctx, s) {
	        //var {expr:expr, type:type, cases:cases} = s;
	        var expr=s.expr, type=s.type, cases=s.cases;
	        var b = new Block(new Ast::Head([],[]), [new ThrowStmt(expr)]);
	
	        var newcases = [];
	        var hasDefault = false;
	        for( var i = 0; i < cases.length; i++ ) {
	            newcases.push(cases[i]);
	            var tmp = cases[i].param.fixtures[0];
	            var f=tmp[1];
	            if (f.type === Ast::anyType)
	                hasDefault = true;
	        }
	
	        // Add a catch all case so we don't end up throwing whatever the switch type expr was
	        if (!hasDefault) {
	            newcases.push(new Catch(new Head([ [new PropName({ns:new PublicNamespace(""), id:"x"})
	                                               ,new ValFixture(Ast::anyType, false) ] ], [])
	                                   ,new Block(new Head([],[]), [])));
	        }
	        cgTryStmt(ctx, {block:b, catches:newcases, finallyBlock:null} );        
	    }
	    
	    static function cgWithStmt(ctx, s) {
	        //var {expr:expr} = s;
	        var expr=s.expr, body=s.body; // XXX complete guess for "body" existing on s.
	        var asm = ctx.asm;
	        // FIXME: save the scope object in a register and record this fact in the ctx inside
	        // the body, so that catch/finally handlers inside the body can restore the scope
	        // stack properly.
	        //
	        // FIXME: record the fact that "with" is in effect so that unstructured control flow can
	        // pop the scope stack.
	        cgExpr(ctx, expr);
	        asm.I_pushwith();
	        cgStmt(ctx, body);
	        asm.I_popscope();
	    }
	    
	    static function cgTryStmt(ctx, s) {
	        //var {block:block, catches:catches, finallyBlock:finallyBlock} = s;
	        var block=s.block, catches=s.catches, finallyBlock=s.finallyBlock;
	        var asm = ctx.asm;
	        var code_start = asm.length;
	        cgBlock(ctx, block);
	        var code_end = asm.length;
	        
	        var Lend = asm.newLabel();
	        asm.I_jump(Lend);
	
	        for( var i = 0; i < catches.length; ++i ) {
	            cgCatch(ctx, [code_start, code_end, Lend], catches[i]);
	        }
	        
	        asm.I_label(Lend);
	        
	        
	        //FIXME need to do finally
	    }
	    
	    static function cgCatch(ctx, tmp, s ) {
	    	var code_start=tmp[0], code_end=tmp[1], Lend=tmp[2];
	        //var {param:param, block:block} = s;
	        var param=s.param, block=s.block;
	        //var {asm:asm, emitter:emitter, target:target} = ctx;
	        var asm=ctx.asm, emitter=ctx.emitter, target=ctx.target;
	        
	        if( param.fixtures.length != 1 )
	            throw "Internal Error: catch should have 1 fixture";
	        
	        var tmp = param.fixtures[0];
	        var propname=tmp[0], fix=tmp[1];
	        
	        var param_name = emitter.fixtureNameToName(propname);
	        var param_type = emitter.realTypeName(fix.type);
	        
	        var catch_idx = target.addException(new ABCException(code_start, code_end, asm.length, param_type, param_name));
	
	        asm.startCatch();
	
	        var t = asm.getTemp();
	        asm.I_getlocal(0);
	        asm.I_pushscope();
	        restoreScopes(ctx);
	        var catch_ctx = pushCatch(ctx,t);
	
	        asm.I_newcatch(catch_idx);
	        asm.I_dup();
	        asm.I_setlocal(t);  // Store catch scope in register so it can be restored later
	        asm.I_dup();
	        asm.I_pushscope();
	        
	        // Store the exception object in the catch scope.
	        asm.I_swap();
	        asm.I_setproperty(param_name);
	
	        // catch block body
	        cgBlock(catch_ctx, block);
	        
	        asm.I_kill(t);
	        
	        asm.I_popscope();
	        asm.I_jump(Lend);
	    }


	}
}

var CTX_shared;
class CTX {
    var asm, stk, target;
    var emitter, script, cp;

    function CTX (asm, stk, target) {
        this.asm = asm;
        this.stk = stk;
        this.target = target;

        // tamarin hack
        this.emitter = CTX_shared.emitter;
        this.script = CTX_shared.script;
        this.cp = CTX_shared.cp;
    }
}
