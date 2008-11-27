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

		static public function remainder(a:Number, b:Number):Number{ return a % b; }

		static public function inc(a:Number):Number{ return a + 1; }

		static public function dec(a:Number):Number{ return a - 1; }

		static public function and(a:Number, b:Number):Number{ return a & b; }

		static public function or(a:Number, b:Number):Number{ return a | b; }

		static public function xor(a:Number, b:Number):Number{ return a ^ b; }

		static public function not(a:Number):Number{ return ~ a; }

		static public function shl(a:Number, b:Number):Number{ return a << b; }

		static public function shr(a:Number, b:Number):Number{ return a >>> b; }

		static public function sar(a:Number, b:Number):Number{ return a >> b; }
	}
}