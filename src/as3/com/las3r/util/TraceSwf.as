/**
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/


package com.las3r.util{
	import flash.display.*;
	import com.hurlant.eval.ByteLoader;
	import com.hurlant.eval.dump.ABCDump;
	import flash.utils.ByteArray;
	import com.las3r.test.demos.StaticVarAccess;


	public class TraceSwf extends Sprite{


		[Embed(source="../../../../../bin/StaticVarAccess.swf", mimeType="application/octet-stream")]
		private const SWF:Class;

		public function TraceSwf() {
			var forceImport:Array = [];
			var swf:ByteArray = new SWF() as ByteArray;
			throw ABCDump.dump(swf);
		}

	}
}