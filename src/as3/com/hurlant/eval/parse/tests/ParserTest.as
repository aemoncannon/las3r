package com.hurlant.eval.parse.tests
{
	import com.hurlant.eval.Evaluator;
	import com.hurlant.test.ITestHarness;
	import com.hurlant.test.TestCase;

	public class ParserTest extends TestCase
	{
		public function ParserTest(h:ITestHarness)
		{
			super(h, "Parser Test");
			runTest(testFailBoat, "Known OLD AS3 PORT parser problems");
			h.endTestCase();
		}
		
		public function testFailBoat():void {
			// this is a handy place to store things that don't work.
			var programs:Array =
			[
				// E4X: full of fail.
				"var fail=<Boat/>;",
				// For In loops
				"for (var a in b) {}",
				// packages
				"package stuff {}",
				// super()
				"class test { function test() { super(); } }",
			];
	    	var evaluator:Evaluator = new Evaluator
			
			for each (var p:String in programs) {
				try {
					evaluator.eval(p);
				} catch (e:*) {
					claim("Parsing "+p+" =>"+e, false);
				}
				
			}
		}
		
	}
}