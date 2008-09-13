package com.las3r.runtime{
	class Frame{
		//Var->Box
		var bindings:IMap;

		var prev:Frame;

		public function Frame(bindings:IMap = null, prev:Frame = null){
			this.bindings = bindings || new Map();
			this.prev = prev || null;
		}
	}

}