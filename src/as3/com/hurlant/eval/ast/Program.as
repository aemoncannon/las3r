package com.hurlant.eval.ast
{
    public class Program {
        public var packages: Array; //PACKAGES;
        public var block: Block;
        public var head: Head;
        function Program (packages, block, head) {
            this.packages = packages;
            this.block = block;
            this.head = head;
        }
    }
}