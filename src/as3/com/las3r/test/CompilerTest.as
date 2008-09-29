/**
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.las3r.test{
	import flexunit.framework.TestCase;
 	import flexunit.framework.TestSuite;
	import flash.utils.*;
	import flash.events.*;
	import com.las3r.runtime.*;
	import com.las3r.util.*;

	public class CompilerTest extends LAS3RTest {

		// For testing...
		public static var name:String;
		public static function getName():String {return name;}
		public static function echo(str:String):String {return str;}
		
		override public function setUp():void {
			CompilerTest.name = "joe";
		}
		
		override public function tearDown():void {
		}


		public function testBindBirdToTrue():void{
			readAndLoad("(def *bird* true)",
				function(rt:RT, val:*):void{
					assertTrue("Should be one static constant (the var *bird*).", rt.constants.length == 1);
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be true.", v.get() == true);
				});
		}

		public function testBindBirdToFalse():void{
			readAndLoad("(def *bird* false)",
				function(rt:RT, val:*):void{
					assertTrue("Should be one static constant (the var *bird*).", rt.constants.length == 1);
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be true.", v.get() == false);
				});
		}

		public function testBindBirdToNil():void{
			readAndLoad("(def *bird* nil)",
				function(rt:RT, val:*):void{
					assertTrue("Should be one static constant (the var *bird*).", rt.constants.length == 1);
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be true.", v.get() == null);
				});
		}

		public function testBindBirdToNumber():void{
			readAndLoad("(def *bird* 1)",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be 1.", v.get() == 1);
				});
		}

		public function testBindBirdToString():void{
			readAndLoad("(def *bird* \"dudes\")",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be \"dudes\".", v.get() == "dudes");
				});
		}

		public function testBindBirdToKeyword():void{
			readAndLoad("(def *bird* :dude)",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be :dude.", v.get() == key1(rt, "dude"));
				});
		}

		public function testDefWithNoInit():void{
			readAndLoad("(def *bird*)",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be unbound.", v.hasRoot() == false);
				});
		}

		public function testBindBirdToAS3Class():void{
			readAndLoad("(def *bird* com.las3r.runtime.Vector)",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to the class Vector.", v.get() == Vector);
				});
		}

		public function testBindBirdToVectorLiteral():void{
			readAndLoad("(def *bird* [1 2 3])",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be a vector.", v.get() is IVector);
					assertTrue("Value of *bird* should have 2 as second value.", (v.get()).nth(1) == 2);
					assertTrue("Length of *bird* should be 3.", (v.get()).count() == 3);
				});
		}


		public function testBindBirdToEmptyVectorLiteral():void{
			readAndLoad("(def *bird* [])",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be a vector.", v.get() is IVector);
					assertTrue("Length of *bird* should be 0.", (v.get()).count() == 0);
				});
		}

		public function testBindBirdToMapLiteral():void{
			readAndLoad("(def *bird* { :horse 4, :dino 2})",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be a map.", v.get() is IMap);
					assertTrue("Value of *bird* at :horse should be 4.", (v.get()).valAt(key1(rt, "horse")) == 4);
					assertTrue("Value of *bird* at :dino should be 2.", (v.get()).valAt(key1(rt, "dino")) == 2);
					assertTrue("Length of *bird* should be 3.", (v.get()).count() == 2);
				});
		}

		public function testBindBirdToEmptyMapLiteral():void{
			readAndLoad("(def *bird* {})",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("Value of *bird* should be a map.", v.get() is IMap);
					assertTrue("Length of *bird* should be 0.", (v.get()).count() == 0);
				});
		}

		public function testDefingAVarThenReadingTheValue():void{
			readAndLoad("(def *word* :bird)", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* *word*)", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to :bird.", v.get() == key1(rt, "bird"));
						}, rt);
				});
		}


		public function testEmptyDoExpressionReturnsNil():void{
			readAndLoad("(def *bird* (do))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to null.", v.get() == null);
				});
		}

		public function testDoExpressionHasValueOfOnlyExpr():void{
			readAndLoad("(def *bird* (do :d))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to :d.", v.get() == key1(rt, "d"));
				});
		}

		public function testDoExpressionHasValueOfLastExpr():void{
			readAndLoad("(def *bird* (do :a :b :c :d))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to :d.", v.get() == key1(rt, "d"));
				});
		}

		public function testBindingBirdToIfExpression():void{
			readAndLoad("(def *bird* (if true 1))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 1.", v.get() == 1);
				});
		}

		public function testBindingBirdToIfExpressionElse():void{
			readAndLoad("(def *bird* (if false 1 5))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 5.", v.get() == 5);
				});
		}

		public function testBindingBirdToComplexExpression1():void{
			readAndLoad("(def *bird* (if false 1 (if (do 1 2 true) \"horse\" :fly)))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to \"horse\".", v.get() == "horse");
				});
		}


		public function testBindingBirdToSimpleFn():void{
			readAndLoad("(def *bird* (fn* [a b c] 1))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to a Function.", v.get() is Function);
				});
		}

		public function testBindingBirdToNoOpFn():void{
			readAndLoad("(def *bird* (fn* [] ))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to a Functoin.", v.get() is Function);
				});
		}

		public function testDefingAVarThenInvokingItsValue():void{
			readAndLoad("(def *fun* (fn* [] :hello))", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (*fun*))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to :hello.", v.get() == key1(rt, "hello"));
						}, rt);
				});
		}

		public function testDefingAVarThenInvokingItsValueWithParameter():void{
			readAndLoad("(def *fun* (fn* [a] a))", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (*fun* 1))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to 1.", v.get() == 1);
						}, rt);
				});
		}

		public function testFnWithAnOptionalArgument():void{
			readAndLoad("(def *bird* ((fn* [a b (c nil)] c) 1 2))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be nil", v.get() == null);
				});
		}

		public function testPassingValueToOptionalArg():void{
			readAndLoad("(def *bird* ((fn* [a b (c nil)] c) 1 2 3))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be nil", v.get() == 3);
				});
		}

		public function testPassingValueToFirstOfTwoOptionalArgs():void{
			readAndLoad("(def *bird* ((fn* [a b (c nil) (d nil)] c) 1 2 3))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be nil", v.get() == 3);

				});
		}

		public function testOnlyArgIsOptional():void{
			readAndLoad("(def *bird* ((fn* [(c nil)] c)))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be nil", v.get() == null);

				});
		}

		public function testFnWithOnlyRestParam():void{
			readAndLoad("(def *fun* (fn* [& dudes] dudes))", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (*fun* 1 2))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should match....", Util.equal(v.get(), RT.list(1, 2)));
						}, rt);
				});
		}

		public function testFnWithOnlyRestParamEmpty():void{
			readAndLoad("(def *fun* (fn* [& dudes] dudes))", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (*fun*))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should match....", Util.equal(v.get(), null));
						}, rt);
				});
		}

		public function testFnWithEmptyRestParam():void{
			readAndLoad("(def *fun* (fn* [a & dudes] dudes))", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (*fun* 1))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to a List.", v.get() is List);
							assertTrue("*bird* should be empty.", v.get().count() == 0);
						}, rt);
				});
		}

		public function testFnWithRestParam():void{
			readAndLoad("(def *fun* (fn* [a & dudes] dudes))", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (*fun* 1 2 3 4))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to a List.", v.get() is List);
							assertTrue("*bird* should be empty.", v.get().count() == 3);
							assertTrue("*bird* should match....", Util.equal(v.get(), RT.list(2, 3, 4)));
						}, rt);
				});
		}

		public function testOptionalsWithEmptyRestArg():void{
			readAndLoad("(def *bird* ((fn* [a (b nil) & rest] rest) 1 2))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should match....", Util.equal(v.get(), RT.list()));

				});
		}


		public function testOptionalsWithRestArg():void{
			readAndLoad("(def *bird* ((fn* [a (b nil) & rest] rest) 1 2 3 4))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should match....", Util.equal(v.get(), RT.list(3, 4)));
				});
		}

		public function testFunctionWithSelfName():void{
			readAndLoad("(def *bird* ((fn* me [] me)))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be a function", v.get() is Function);
				});
		}

		public function testVariadicFunctionWithTwoMethods():void{
			readAndLoad("((fn* ([a] a) ([a b] (list a b))) 1)", function(rt:RT, val:*):void{
					assertTrue("return value should be 1", val == 1);
				});
		}

		public function testVariadicFunctionWithTwoMethodsCallingSecond():void{
			readAndLoad("((fn* ([a] a) ([a b] (list a b))) 1 2)", function(rt:RT, val:*):void{
					assertTrue("return value should be (1 2)", Util.equal(val, RT.list(1, 2)));
				});
		}

		public function testVariadicFunctionWithRestParam():void{
			readAndLoad("((fn* ([a] a) ([a b & c] c)) 1 2 3 4)", function(rt:RT, val:*):void{
					assertTrue("return value should be (1 2)", Util.equal(val, RT.list(3, 4)));
				});
		}

		public function testVariadicFunctionStartingWithArityGreaterThanOnex():void{
			readAndLoad("((fn* ([a b] (list a b)) ([a b c] (list a b c))) 1 2)", function(rt:RT, val:*):void{
					assertTrue("return value should be (1 2)", Util.equal(val, RT.list(1, 2)));
				});
		}

		public function testSimpleClosure():void{
			readAndLoad("(def *funA* (fn* [a] (fn* [] a)))", function(rt:RT, val:*):void{
					readAndLoad("(def *funB* (*funA* :bird))", function(rt:RT, val:*):void{
							readAndLoad("(def *result* (*funB*))", function(rt:RT, val:*):void{
									var v:Var = rt.getVar("las3r", "*result*");
									assertTrue("*result* should be bound to :bird.", v.get() == key1(rt, "bird"));
								}, rt);
						}, rt);
				});
		}


		public function testSimpleLet():void{
			readAndLoad("(def *bird* (let* [a 1] a))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 1.", v.get() == 1);
				});
		}

		public function testSimpleLetInFunction():void{
			readAndLoad("(def *bird* ((fn* [] (let* [a 1] a))))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 1.", v.get() == 1);
				});
		}

		public function testLetShadowingFunctionArg():void{
			readAndLoad("(def *bird* ((fn* [a] (let* [a 1] a)) 10))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 1.", v.get() == 1);
				});
		}

		public function testLetSameNamedBindingShadows():void{
			readAndLoad("(let* [a 1 a 2] a)",
				function(rt:RT, val:*):void{
					assertTrue("val is 2", val == 2);
				});
		}

		public function testLetSameNameReferencingPrevious():void{
			readAndLoad("(let* [a (fn* [] :dog) a (a)] a)",
				function(rt:RT, val:*):void{
					assertTrue("val is :dog", val == key1(rt, "dog"));
				});
		}


		public function testLetReferingToSurroundingFunctionArg():void{
			readAndLoad("(def *bird* ((fn* [a] (let* [b 1] a)) 10))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 10.", v.get() == 10);
				});
		}

		public function testFunctionClosingOverLetBindings():void{
			readAndLoad("(def *func* (let* [a :a b :b c :c] (fn* [] :c)))", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (*func*))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to :c.", v.get() == key1(rt, "c"));
						}, rt);
				});
		}


		public function testQuotedList():void{
			readAndLoad("(def *bird* '(hello everyone))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be equal to '(hello everyone).", Util.equal(v.get(), RT.list(sym1(rt, "hello"), sym1(rt, "everyone"))));
				});
		}


		public function testRecurCallToTopOfSimpleFunction():void{
			readAndLoad("(def *fun* (fn* [a] (if a (recur false) :hello)))", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (*fun* true))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to :hello.", v.get() == key1(rt, "hello"));
						}, rt);
				});
		}


		public function testRecurCallToTopOfLoop():void{
			readAndLoad("(def *bird* (loop* [a true] (if a (recur false) :hello)))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to :hello.", v.get() == key1(rt, "hello"));
				});
		}


		public function testGetStaticField():void{
			readAndLoad("(def *bird* (. com.las3r.test.CompilerTest name))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 'joe'", v.get() == "joe");
				});
		}


		public function testAssignToStaticFieldThenGet():void{
			readAndLoad("(set! (. com.las3r.test.CompilerTest name) \"jack\")", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (. com.las3r.test.CompilerTest name))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to 'jack'", v.get() == "jack");
						}, rt);
				});
		}


		/* Note 'instance' in this case is a class instance */
		public function testGetInstanceField():void{
			readAndLoad("(def *bird* (. (if true com.las3r.test.CompilerTest) name))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 'joe'", v.get() == "joe");
				});
		}


		/* Note 'instance' in this case is a class instance */
		public function testAssignToInstanceFieldThenGet():void{
			readAndLoad("(set! (. (if true com.las3r.test.CompilerTest) name) \"jack\")", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (. (if true com.las3r.test.CompilerTest) name))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to 'jack'", v.get() == "jack");
						}, rt);
				});
		}


		/* Note 'instance' in this case is a class instance */
		public function testCallInstanceMethodWithNoArgs():void{
			readAndLoad("(def *bird* (. (if true com.las3r.test.CompilerTest) (getName)))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 'joe'", v.get() == "joe");
				});
		}

		/* Note 'instance' in this case is a class instance */
		public function testCallInstanceMethod():void{
			readAndLoad("(def *bird* (. (if true com.las3r.test.CompilerTest) (echo \"jack\")))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 'jack'", v.get() == "jack");
				});
		}


		public function testConstructNewObject():void{
			readAndLoad("(def *bird* (new Object))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to an Object", v.get() is Object);
				});
		}

		public function testConstructNewObjectAndSetProperty():void{
			readAndLoad("(def *bird* (let* [o (new Object)] (set! (. o legs) 4) (. o legs)))", function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 4", v.get() == 4);
				});
		}


		public function testVarLiteralExpression():void{
			readAndLoad("(def *dude* 1)", function(rt:RT, val:*):void{
					readAndLoad("(def *bird* (var *dude*))", function(rt:RT, val:*):void{
							var v:Var = rt.getVar("las3r", "*bird*");
							assertTrue("*bird* should be bound to *dude*", v.get() == rt.getVar("las3r", "*dude*"));
						}, rt);
				});
		}


		public function testFnThrowingException():void{
			readAndLoad("(def *bird* (fn* [] (throw \"Caw!\")))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertThrows("calling *bird* should throw \"Caw!\".", 
						function():void{ (v.fn())(); }, 
						function(e:*):Boolean{ return e == "Caw!"; }
					);
				});
		}

		public function testTryCatchNoException():void{
			readAndLoad("(def *bird* (try 1 (catch Error e 2)))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 1", v.get() == 1);
				});
		}

		public function testCatchWithException():void{
			readAndLoad("(def *bird* (try (throw \"Caw!\") (catch String e 2)))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 2", v.get() == 2);
				});
		}

		public function testCatchWithExceptionReferencingCatchVar():void{
			readAndLoad("(def *bird* (try (throw \"Caw!\") (catch String e e)))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to \"Caw!\"", v.get() == "Caw!");
				});
		}

		public function testTryWithFinallyClause():void{
			readAndLoad("(def *bird* (try 1 (catch String e e) (finally 2)))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 2", v.get() == 2);
				});
		}

		public function testTryCatchThenFinallyClause():void{
			readAndLoad("(def *bird* (try (throw 5) (catch Number e e) (finally 10)))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 10", v.get() == 10);
				});
		}

		public function testTwoCatchClauses():void{
			readAndLoad("(def *bird* (try (throw \"Caw!\") (catch Number e 2) (catch String e 5)))",
				function(rt:RT, val:*):void{
					var v:Var = rt.getVar("las3r", "*bird*");
					assertTrue("*bird* should be bound to 5", v.get() == 5);
				});
		}

		public function testThreeCatchClauses():void{
			readAndLoad("(try (throw \"Caw!\") (catch Number e 2) (catch Error e 1) (catch String e 5))",
				function(rt:RT, val:*):void{
					assertTrue("val should be 5", val == 5);
				});
		}

		public function testThreeCatchClausesMiddle():void{
			readAndLoad("(try (throw \"Caw!\") (catch Number e 2) (catch String e 1) (catch Error e 5))",
				function(rt:RT, val:*):void{
					assertTrue("val should be 1", val == 1);
				});
		}

		public function testThreeCatchClausesFirst():void{
			readAndLoad("(try (throw \"Caw!\") (catch String e 10) (catch String e 1) (catch Error e 5))",
				function(rt:RT, val:*):void{
					assertTrue("val should be 10", val == 10);
				});
		}


		public function testBasicSyntaxQuotedList():void{
			readAndLoad("`(a b c)",
				function(rt:RT, val:*):void{
					var ns:String = LispNamespace.LAS3R_NAMESPACE_NAME;
					assertTrue("val should be equivalent to quoted..", Util.equal(val, RT.list(sym2(rt,ns,"a"), sym2(rt,ns,"b"), sym2(rt,ns,"c"))));
				});
		}


		public function testSyntaxQuotedListWithSimpleUnquote():void{
			readAndLoad("(let* [a 1] `(~a b c))",
				function(rt:RT, val:*):void{
					var ns:String = LispNamespace.LAS3R_NAMESPACE_NAME;
					assertTrue("val should be equivalent to quoted..", Util.equal(val, RT.list(1, sym2(rt,ns,"b"), sym2(rt,ns,"c"))));
				});
		}

		public function testSyntaxQuotedListWithSimpleUnquoteSplicing():void{
			readAndLoad("(let* [a '(a)] `(~@a b c))",
				function(rt:RT, val:*):void{
					var ns:String = LispNamespace.LAS3R_NAMESPACE_NAME;
					assertTrue("val should be equivalent to quoted..", Util.equal(val, RT.list(sym1(rt,"a"), sym2(rt,ns,"b"), sym2(rt,ns,"c"))));
				});
		}


		public function testSyntaxQuotedListWithFunCallUnquote():void{
			readAndLoad("`(~(list 1 2 3) b c)",
				function(rt:RT, val:*):void{
					var ns:String = LispNamespace.LAS3R_NAMESPACE_NAME;
					assertTrue("val should be equivalent to quoted..", Util.equal(val, RT.list(RT.list(1, 2, 3), sym2(rt,ns,"b"), sym2(rt,ns,"c"))));
				});
		}




	}

}

