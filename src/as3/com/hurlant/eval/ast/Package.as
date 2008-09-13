package com.hurlant.eval.ast
{
    public class Package {
        public var name: Array; //[String];
        public var block: Block;
        function Package (name, block) {
            this.name = name;
            this.block = block;
        }
    }
}