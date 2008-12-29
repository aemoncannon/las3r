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

	public class MiscChecks extends Sprite{

		public function MiscChecks():void{
			var val:* = null;
			trace("null == false is " + (val == false));
			trace("null == 0 is " + (val == 0));
			trace("null == '' is " + (val == ""));
			trace("null == undefined is " + (val == undefined));

			val = false;
			trace("false == null is " + (val == null));
			trace("false == 0 is " + (val == 0));
			trace("false == '' is " + (val == ""));
			trace("false == undefined is " + (val == undefined));
		}

	}

}