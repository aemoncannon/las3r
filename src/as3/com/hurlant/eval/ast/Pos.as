package com.hurlant.eval.ast
{
	public class Pos
	{
       public var file: String;
       public var span: int; //StreamPos.span
       public var sm: int; // StreamPos.sourcemap
       public var post_newline: Boolean;
	}
}