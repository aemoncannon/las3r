package com.hurlant.eval.ast
{
	public class InitExpr implements IAstExpr {
        public var target : IAstInitTarget ;
        public var head : Head;               // for desugaring temporaries
        public var inits  //: INITS;
        function InitExpr (target, head, inits) {
            this.target = target;
            this.head = head;
            this.inits = inits;
        }
    }
}