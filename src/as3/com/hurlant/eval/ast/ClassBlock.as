package com.hurlant.eval.ast
{
    public class ClassBlock implements IAstStmt {
        public var name //: NAME;
        public var block : Block;
        function ClassBlock (name,block) {
            this.name = name;
            this.block = block;
        }
    }
}