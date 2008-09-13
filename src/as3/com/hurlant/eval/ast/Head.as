package com.hurlant.eval.ast
{
	public class Head
	{
        public var fixtures: Array; //FIXTURES;  
        public var exprs // : Array;
		public function Head(fixtures,exprs) {
            this.fixtures = fixtures;
            this.exprs = exprs;
		}
	}
}