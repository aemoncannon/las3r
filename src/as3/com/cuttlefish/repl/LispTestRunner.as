/*   
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	the terms of this license.
*   You must not remove this notice, or any other, from this software.
*/

package com.cuttlefish.repl{


	import flash.display.*;

	public class LispTestRunner extends Sprite{

		public function LispTestRunner(){
			stage.scaleMode = StageScaleMode.NO_SCALE;
			var r:Repl = new Repl(stage.stageWidth - 50, stage.stageHeight - 50, stage);
			r.x = r.y = 25;
			addChild(r);
		}

	}
}