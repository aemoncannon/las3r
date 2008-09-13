package com.hurlant.eval.ast
{
    public class TempIdent implements IAstBindingIdent {
        public var index : int;
        function TempIdent (index) {
            this.index = index;
        }
    }
}