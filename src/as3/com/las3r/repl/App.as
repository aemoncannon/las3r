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

	public class App extends Sprite{

		protected var _repl:Repl;
		

		public function App(){
			stage.scaleMode = StageScaleMode.NO_SCALE;
			_repl = new Repl(stage.stageWidth - 50, stage.stageHeight - 50, stage);
			addChild(_repl);
			_repl.init();
			stage.addEventListener(Event.RESIZE, onStageResize);
			onStageResize(null);
		}

		protected function onStageResize(e:Event):void{
			_repl.x = (stage.stageWidth / 2) - (_repl.width / 2);
			_repl.y = (stage.stageHeight / 2) - (_repl.height / 2);
		}

	}
}