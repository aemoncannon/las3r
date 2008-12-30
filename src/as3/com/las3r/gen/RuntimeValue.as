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

	public class RuntimeValue {

		private var tmpIndex:int = -1;

		private var slotIndex:int = -1;
		private var slotName:String = null;

		private var _gen:CodeGen;

		private function get inTmp():Boolean { return tmpIndex > -1; }
		private function get inActivationSlot():Boolean { return slotIndex > -1 && slotName != null; }
		
		public function RuntimeValue(gen:CodeGen){
			_gen = gen;
		}

		public static function fromTmp(gen:CodeGen, i:int, name:String):RuntimeValue{
			var l:RuntimeValue = new RuntimeValue(gen);
			l.tmpIndex = i;
			if(gen.currentActivation){
				l.slotName = name;
				l.slotIndex = gen.nextActivationSlot(l.slotName);
				gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
				gen.asm.I_getlocal(l.tmpIndex);
				gen.asm.I_coerce_a();
				gen.asm.I_setslot(l.slotIndex);
			}
			return l;
		}

		public static function fromTOS(gen:CodeGen, name:String):RuntimeValue{
			var l:RuntimeValue = new RuntimeValue(gen);
			l.tmpIndex = gen.asm.getTemp();
			if(gen.currentActivation) gen.asm.I_dup();
			gen.asm.I_coerce_a();
			gen.asm.I_setlocal(l.tmpIndex);
			if(gen.currentActivation){
				l.slotName = name;
				l.slotIndex = gen.nextActivationSlot(l.slotName);
				gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
				gen.asm.I_swap();
				gen.asm.I_setslot(l.slotIndex);
			}
			return l;
		}

		public function get(gen:CodeGen):void{
			if(gen == _gen && inTmp){
				gen.asm.I_getlocal(tmpIndex);
				gen.asm.I_coerce_a();
			}
			else if(inActivationSlot){
				gen.asm.I_getlex(gen.emitter.qname({ns: "", id: slotName}, false));
			}
		}

		public function updateFromTOS(gen:CodeGen):void{
			if(gen != _gen) throw new Error("IllegalStateException: Can't update runtime value from outside originating function.");
			if(inTmp && inActivationSlot){
				gen.asm.I_coerce_a();
				gen.asm.I_dup();
				gen.asm.I_setlocal(tmpIndex);
				gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
				gen.asm.I_swap();
				gen.asm.I_setslot(slotIndex);
			}
			else if(inTmp && !inActivationSlot){
				gen.asm.I_coerce_a();
				gen.asm.I_setlocal(tmpIndex);
			}
			else if(inActivationSlot){
				gen.asm.I_coerce_a();
				gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
				gen.asm.I_swap();
				gen.asm.I_setslot(slotIndex);
			}
		}

		public function updateFromTmp(gen:CodeGen, i:int):void{
			if(gen != _gen) throw new Error("IllegalStateException: Can't update runtime value from outside originating function.");
			if(inTmp && tmpIndex != i && !inActivationSlot){
				gen.asm.I_getlocal(i);
				gen.asm.I_coerce_a();
				gen.asm.I_setlocal(tmpIndex);
			}
			else if(inTmp && tmpIndex != i && inActivationSlot){
				gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
				gen.asm.I_getlocal(i);
				gen.asm.I_coerce_a();
				gen.asm.I_dup();
				gen.asm.I_setlocal(tmpIndex);
				gen.asm.I_setslot(slotIndex);
			}
			else if(inActivationSlot){
				gen.asm.I_getscopeobject(gen.currentActivation.scopeIndex);
				gen.asm.I_getlocal(i);
				gen.asm.I_coerce_a();
				gen.asm.I_setslot(slotIndex);
			}
		}

	}

}
