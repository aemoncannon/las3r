package com.hurlant.eval.ast
{
    public class BlockStmt implements IAstStmt {
        public var block : Block;
        function BlockStmt (block) {
            this.block = block;
        }
    }
}