package com.hurlant.eval.ast
{
    public class AppType implements IAstTypeExpr {
        public var base : IAstTypeExpr;
        public var args : Array; //[IAstTypeExpr];
        function AppType (base,args) {
            this.base = base;
            this.args = args;
        }
    }
}