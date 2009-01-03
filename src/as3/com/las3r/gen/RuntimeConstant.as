/**
*   Copyright (c) Rich Hickey. All rights reserved.
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	 the terms of this license.
*   You must not remove this notice, or any other, from this software.
**/


package com.las3r.gen{

	import com.las3r.util.Util;

	public class RuntimeConstant {

		public var tmpIndex:int = -1;
		public var fieldName:String;

		private function get inTmp():Boolean { return tmpIndex > -1; }
		private function get inField():Boolean { return fieldName != null; }
		
		public function RuntimeConstant(val:Object, id:int){
			this.fieldName = CodeGen.constantName(id);
		}

		public function cacheInTmp(gen:CodeGen, tmpIndex:int):void{
			get(gen);
			gen.asm.I_setlocal(tmpIndex);
			this.tmpIndex = tmpIndex;
		}

		public function get(gen:CodeGen):void{
			if(inTmp){
				gen.asm.I_getlocal(tmpIndex);
			}
			else if(inField){
				gen.emitConstantByName(fieldName);
			}
		}


	}

}

