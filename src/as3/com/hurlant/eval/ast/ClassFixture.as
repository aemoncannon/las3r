package com.hurlant.eval.ast
{
    public class ClassFixture implements IAstFixture {
        public var cls : Cls;
        function ClassFixture (cls) {
            this.cls = cls;
        }
    }
}