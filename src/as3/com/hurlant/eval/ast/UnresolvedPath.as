package com.hurlant.eval.ast
{
    public class UnresolvedPath implements IAstIdentExpr {
        public var path /*: [String] */;
        public var ident : IAstIdentExpr;
        function UnresolvedPath (path,ident) {
            this.path=path;
            this.ident=ident;
        }
    }
}