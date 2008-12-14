/**
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/

package com.las3r.test.demos{
	import flash.display.Sprite;
	import flash.utils.Dictionary;

	public class DictAccess extends Sprite{

		public function DictAccess():void{
			var d:Dictionary = new Dictionary();
			d[20] = 1;
			d[60] = 2;
			var test:int = d[60];
		}
	}

}