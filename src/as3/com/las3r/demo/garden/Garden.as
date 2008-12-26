/*   
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	the terms of this license.
*   You must not remove this notice, or any other, from this software.
*/

package com.las3r.demo.garden{

	import flash.display.*;
	import flash.events.*;
	import flash.utils.ByteArray;
	import com.las3r.runtime.RT;
	import com.las3r.io.*;
	import com.las3r.errors.LispError;
	import com.las3r.repl.Repl;

	public class Garden extends Sprite{

		[Embed(source="garden.lsr", mimeType="application/octet-stream")]
		protected const GardenLsr:Class;

		protected var _rt:RT;

		public function Garden(){
			stage.scaleMode = StageScaleMode.NO_SCALE;
			var repl:Repl = new Repl(350, 200, stage);
			repl.x = stage.stageWidth - repl.width;
			repl.y = stage.stageHeight - repl.height;
			addChild(repl);
			_rt = repl.rt;
			repl.evalLibrary(ByteArray(new GardenLsr).toString());
		}


	}
}