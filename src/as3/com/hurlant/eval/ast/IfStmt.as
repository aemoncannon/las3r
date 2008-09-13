package com.hurlant.eval.ast
{
    public class IfStmt implements IAstStmt {
        public var expr : IAstExpr;
        public var then : IAstStmt;
        public var elseOpt : IAstStmt?;
        function IfStmt (expr,then,elseOpt) {
            this.expr = expr;
            this.then = then;
            this.elseOpt = elseOpt;
        }
    }
}