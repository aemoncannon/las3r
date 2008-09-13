package com.hurlant.eval.ast
{
	public class Block
	{
        public var head: Head;
        public var stmts : Array; //STMTS;
		public function Block(head,stmts) {
            this.head = head;
            this.stmts = stmts;
    	}
	}
}