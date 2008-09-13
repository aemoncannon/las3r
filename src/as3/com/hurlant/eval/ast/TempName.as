package com.hurlant.eval.ast
{
	public class TempName implements IAstFixtureName {

        public var index : int;
		public function TempName(index) {
            this.index = index;
		}

	}
}