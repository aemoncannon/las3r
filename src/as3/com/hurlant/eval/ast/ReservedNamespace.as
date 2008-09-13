package com.hurlant.eval.ast
{
    public class ReservedNamespace implements IAstIdentExpr {
        public var ns: IAstNamespace;
        function ReservedNamespace (ns) {
            this.ns=ns;
        }
    }
}