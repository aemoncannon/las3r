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


package com.las3r.runtime{

	public class Numbers{

		static public function add(a:Number, b:Number):Number{ return a + b; }

		static public function multiply(a:Number, b:Number):Number{ return a * b; }

		static public function divide(a:Number, b:Number):Number{ return a / b; }

		static public function minus(a:Number, b:Number):Number{ return a - b; }

		static public function lt(a:Number, b:Number):Boolean{ return a < b; }

		static public function lte(a:Number, b:Number):Boolean{ return a <= b; }

		static public function gt(a:Number, b:Number):Boolean{ return a > b; }

		static public function gte(a:Number, b:Number):Boolean{ return a >= b; }

		static public function equiv(a:Number, b:Number):Boolean{ return a === b; }

		static public function inc(a:Number):Number{ return a + 1; }

		static public function dec(a:Number):Number{ return a - 1; }

		static public function bitAnd(a:Number, b:Number):Number{ return a & b; }

		static public function bitOr(a:Number, b:Number):Number{ return a | b; }

		static public function bitXor(a:Number, b:Number):Number{ return a ^ b; }

		static public function bitNot(a:Number):Number{ return ~ b; }

		static public function bitShl(a:Number, b:Number):Number{ return a << b; }

		static public function bitShr(a:Number, b:Number):Number{ return a >>> b; }

		static public function bitSar(a:Number, b:Number):Number{ return a >> b; }
	}
}