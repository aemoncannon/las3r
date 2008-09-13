package com.hurlant.eval.ast
{
    public class ParamIdent implements IAstBindingIdent {
        public var index : int;
        function ParamIdent (index) {
            this.index = index;
        }
    }
}