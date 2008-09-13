package com.hurlant.eval.ast
{
    public class TryStmt implements IAstStmt {
        public var block : Block;
        public var catches: Array; //CATCHES;
        public var finallyBlock: Block;
        function TryStmt (block,catches,finallyBlock) {
            this.block = block;
            this.catches = catches;
            this.finallyBlock = finallyBlock;
        }
    }
}