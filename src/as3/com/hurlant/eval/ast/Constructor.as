package com.hurlant.eval.ast
{
	public class Constructor
	{
        public var settings : Array; //[IAstExpr];
        public var superArgs : Array; //[IAstExpr];
        public var func : Func;
		public function Constructor(settings,superArgs,func) {
            this.settings = settings;
            this.superArgs = superArgs;
            this.func = func;
		}
	}
}