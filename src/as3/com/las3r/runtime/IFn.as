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

	public interface IFn {

		function invoke0():Object;

		function invoke1(args1:Object):Object;

		function invoke2(args1:Object, args2:Object):Object;

		function invoke3(args1:Object, args2:Object, args3:Object):Object;

		function invoke4(args1:Object, args2:Object, args3:Object, args4:Object):Object;

		function invoke5(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object):Object;

		function invoke6(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object):Object;

		function invoke7(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object):Object;

		function invoke8(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object):Object;

		function invoke9(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object):Object;

		function invoke10(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object):Object;

		function invoke11(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object):Object;

		function invoke12(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object):Object;

		function invoke13(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object):Object;

		function invoke14(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object):Object;

		function invoke15(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object):Object;

		function invoke16(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object):Object;

		function invoke17(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object, args17:Object):Object;

		function invoke18(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object, args17:Object, args18:Object):Object;

		function invoke19(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object, args17:Object, args18:Object, args19:Object):Object;

		function invoke20(args1:Object, args2:Object, args3:Object, args4:Object, args5:Object, args6:Object, args7:Object,
            args8:Object, args9:Object, args10:Object, args11:Object, args12:Object, args13:Object, args14:Object,
            args15:Object, args16:Object, args17:Object, args18:Object, args19:Object, args20:Object):Object;

		function applyTo(arglist:ISeq):Object;
	}

}