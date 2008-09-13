package com.hurlant.eval.ast
{
    public class Catch {
        public var param: Head;
        public var block: Block;
        function Catch (param,block) {
            this.param = param;
            this.block = block;
        }
    }
}