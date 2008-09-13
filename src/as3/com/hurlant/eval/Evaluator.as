package com.hurlant.eval
{
	import com.hurlant.eval.parse.Parser;
	import com.hurlant.eval.dump.ABCDump;
	import com.hurlant.eval.gen.CodeGeneration;
	import com.hurlant.util.Hex;
	
	import flash.utils.ByteArray;
	
	public class Evaluator
	{
		public function Evaluator() {
			super();
		}
		
		public function eval(src:String):ByteArray {
			var top:Array = [];
			var parser:Parser = new Parser(src, top);
			var tmp:Array = parser.program();
			var ts=tmp[0], nd=tmp[1];
			var b:ByteArray = CodeGeneration.cg(nd).getBytes();
			b.position=0;
			return b;
		}

	}
}