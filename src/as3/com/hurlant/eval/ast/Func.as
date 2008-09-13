package com.hurlant.eval.ast
{
	public class Func
	{
        public var name //: FUNC_NAME;
        public var isNative: Boolean;
        public var block: Block;
        public var params: Head;
        public var vars: Head;
        public var defaults: Array; //[IAstExpr];
        public var type /*: FUNC_TYPE*/;    // FIXME: should be able to use 'type' here
		public function Func(name,isNative,block,
                       params,vars,defaults,ty) {
            this.name = name;
            this.isNative = isNative;
            this.block = block;
            this.params = params;
            this.vars = vars;
            this.defaults = defaults;
            this.type = ty;
		}

	}
}