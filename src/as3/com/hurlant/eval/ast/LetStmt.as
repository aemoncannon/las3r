package com.hurlant.eval.ast
{
    public class LetStmt implements IAstStmt {
        public var block : Block;
        function LetStmt (block) {
            this.block = block;
        }
    }
}