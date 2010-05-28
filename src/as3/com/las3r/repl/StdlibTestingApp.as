/*   
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	the terms of this license.
*   You must not remove this notice, or any other, from this software.
*/

package com.las3r.repl{
	import flash.display.*;
	import flash.events.*;

	/**
    * This is an interim measure to facilitate testing of changes to las3r stdlib files.
	* It starts a repl which uses the stdlib lsr files (instead of the precompiled swfs).
    *
    * TODO: Write a cli lsr->swf compiler, fix Rakefile and get rid of this?
	*/

	public class StdlibTestingApp extends Sprite{
		protected var _repl:Repl;

		public function StdlibTestingApp(){
			stage.scaleMode = StageScaleMode.NO_SCALE;
			_repl = new Repl(stage.stageWidth - 50, stage.stageHeight - 50, stage, true);
			_repl.x = stage.stageWidth/2 - _repl.width/2;
			_repl.y = stage.stageHeight/2 - _repl.height/2;
			addChild(_repl);
		}
	}
}