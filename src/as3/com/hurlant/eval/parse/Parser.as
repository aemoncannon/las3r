/* -*- mode: java; mode: font-lock; tab-width: 4; insert-tabs-mode: nil; indent-tabs-mode: nil -*- */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is [Open Source Virtual Machine.].
 *
 * The Initial Developer of the Original Code is
 * Adobe System Incorporated.
 * Portions created by the Initial Developer are Copyright (C) 2004-2006
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Adobe AS3 Team
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package com.hurlant.eval.parse {
	import com.hurlant.eval.*;
	import com.hurlant.eval.ast.*;
	
	// PATTERNS == Array
    //type PATTERNS = [IParserPattern];
    
//    type IParserPattern =
//          ( ObjectPattern
//          , ArrayPattern
//          , SimplePattern
//          , IdentifierPattern );
//
//    type Array = [FieldPattern];
//    type FieldPattern = FieldPattern;


    //type ENV = [FIXTURES];

    //type PRAGMAS = Pragmas;
    //type PRAGMA_ENV = [PRAGMAS];

    public class Parser
    {
    //type IAlpha = (NoColon, AllowColon);
    const noColon = new NoColon;
    const allowColon = new AllowColon;

    //type IBeta = (NoIn, AllowIn);
    const noIn = new NoIn;
    const allowIn = new AllowIn;

    //type IGamma = (NoExpr, AllowExpr);
    const noExpr = new NoExpr;
    const allowExpr = new AllowExpr;

    //type ITau = (GlobalBlk, ClassBlk, InterfaceBlk, LocalBlk);
    const globalBlk = new GlobalBlk;
    const classBlk = new ClassBlk;
    const interfaceBlk = new InterfaceBlk;
    const localBlk = new LocalBlk;

    /*
    const AbbrevIfElse = 0;
    const AbbrevDoWhile = AbbrevIfElse + 1;
    const AbbrevFunction = AbbrevDoWhile + 1;
    const Abbrev = AbbrevFunction + 1;
    const Full = Abbrev + 1;
    */

    //type IOmega = (FullStmt, AbbrevStmt);
    const fullStmt = new FullStmt;
    const abbrevStmt = new AbbrevStmt;



        var scan : Scanner;
        var cx: Context;

        function Parser(src,topFixtures:Array = null)
        {
        	if (topFixtures==null) {
        		topFixtures = [];
        	}
            this.cx = new Context (topFixtures)
            this.scan = new Scanner (src,"")
        }

        var defaultNamespace: IAstNamespace;
        var currentPackageName: String;
        var currentClassName: String;

        var coordList;

        function hd (ts:TokenStream):int
        {
            //Debug.enter("hd ",ts.head());
            var tk:int = Token.tokenKind (ts.head());
            //print ("hd ",tk);
            return tk;
        }

        function hd2 (ts:TokenStream):int 
        {
            //Debug.enter("hd ",ts.head());
            var tk:int = Token.tokenKind (ts.head2());
            //print ("hd ",tk);
            return tk;
        }

        function eat (ts:TokenStream,tc:int) {
            //print("eating ",Token.tokenText(tc));
            var tk:int = hd (ts);
            if (tk == tc) {
                return tl (ts);
            }
            throw "expecting "+Token.tokenText(tc)+" found "+Token.tokenText(tk);
        }

        /*
          Replace the first token in the stream with another one. Raise an exception
          if the first token is not of a specified kind.
        */

        function swap (ts,t0,t1) {
            var tk = hd (ts);
            if (tk === t0) {
                ts.ts.position = ts.n-4;
                ts.ts.writeInt (t1);
                return t1;
            }
            throw "expecting "+Token.tokenText(t0)+" found "+Token.tokenText(tk);
        }

        function tl (ts:TokenStream) : TokenStream {
            ts.next ();
            return ts;
            //return new TokenStream (ts.ts,ts.n+1);
        }  //ts.slice (1,ts.length);


        /*

        Notation

        []             list
        (fl,el)        head
        fl             fixture list
        el             expr list
-        il             init list
        sl             stmt list
        it             init target = VAR, LET (default=LET)
        ie             init expr
        se             set expr

        initexpr       init it (fl,el) il
        letexpr        let (fl,el) el
        block          (fl,el) sl

      

        Bindings

        var x = y      [x], init VAR () [x=y]
        var [x] = y    [x], init VAR ([t0],[init t0=y]) [x=t0[0]]

        let (x=y) ...  let ([x], init x=y) ...
        let x=y             [x], init x=y]

        Assignments

        x = y          [],  set x=y
        [x] = y        [],  let ([t0],[init t0=y]) [set x=t0[0]]

        Blocks

        { }            () {}
        {stmt}         () {stmt}
        {let x}        ([x],[x=undef]) {}       is undef the right val?
        let (x) {}     ([x],[x=undef]) {}       what about reping uninit?

        Mixture

        { var x = y; let z = y }  =>
            ([x],[]) { blkstmt ([z],[]) { init VAR () x=y; init LET () z=y } }


        assignment, create a let for each aggregate, a temp for
        each level of nesting

        x = y              set x=y
        [x] = y            let (t0=y) set x=t0[0]
        [[x]] = y          let (t0=y) let (t1=t0[0]) set x=t1[0]
        [[x],[x]] = y      let (t0=y) let (t1=t0[0]) set x=t1[0]
                                    , let (t1=t0[1]) set x=t1[0]
        
        initialization, create an init rather than a set for the
        leaf nodes

        var x = v            let (t0=v) init () [x=t0]
        var [x] = v          let (t0=v) init () [x=t0[0]]
        var [x,[y,z]] = v    let (t0=v) init () [x=t0[0]]
                                      , let (t1=t0[1]) init () [y=t1[0], z=t1[1]]
        var [x,[y,[z]]] = v  let (t0=v) init () [x=t0[0]]
                                      , let (t1=t0[1]) init () [y=t1[0]
                                                     , let (t2=t1[0]) init () [z=t2[0]]

        for initialization, we need to know the namespace and the target 
        so we make INITS to go into the InitExpr inside the LetExpr

        let x = y          init x=y

        flattening.

        var [x,[y,z]] = v  let (t0=v) init () [x=t0[0]]
                                    , let (t1=t0[1]) init () [y=t1[0], z=t1[0]]

                           t0=v
                           x=t0[0]
                           t1=t0[1]
                           y=t1[0]
                           z=t1[1]
        head = {[t0,x,t1,y,z],

        flattening doesn't work because it mixes named and temporary
        fixtures

        lets and params have the same problem. both allow destructuring
        patterns that can expand into a nested expression.

        let ([x,[y,z]]=v) ...

        top heads only have named fixtures. sub heads only have temporaries.
        temporaries are always immediately initialized. a head is a list of
        fixtures and a list of expressions. the expressions get evaluated
        in the scope outside the head.

        settings is a sub head. it has temporary fixtures and init exprs that
        target instance variables

        */

        function desugarAssignmentPattern (p: IParserPattern, t: IAstTypeExpr, e: IAstExpr, op: IAstAssignOp)
            : Array //[FIXTURES, IAstExpr]
        {
            return desugarPattern (p,t,e,null,null,false,op);
        }

        function desugarBindingPattern (p: IParserPattern, t: IAstTypeExpr, e: IAstExpr,
                                        ns: IAstNamespace?, it: IAstInitTarget?, ro: Boolean?)
            : Array //[FIXTURES, IAstExpr]
        {
            return desugarPattern (p,t,e,ns,it,ro,null);
        }

        function desugarPattern (p: IParserPattern, t: IAstTypeExpr, e: IAstExpr,
                                 ns: IAstNamespace?, it: IAstInitTarget ?, ro: Boolean?, op: IAstAssignOp?)
            : Array //[FIXTURES, IAstExpr]
        {
            return desugarSubPattern (p,t,e,0);

            function identExprFromExpr (e: IAstExpr) 
                : IAstIdentExpr {
                Debug.enter("identExprFromExpr","");
                
                var x = e;
                if (x is LexicalRef) {
                    var ie = (e as LexicalRef).ident;
                } else {
                    throw "invalid init lhs " + e;
                }
                Debug.exit("identExprFromExpr","");
                return ie;
            }

            function desugarSubPattern (p: IParserPattern, t: IAstTypeExpr, e: IAstExpr, n: int) 
                : Array //[FIXTURES, IAstExpr]
            {
                Debug.enter("desugarSubPattern","");
                
                var x = p;
                if (x is IdentifierPattern) {
                    var nm = new PropName ({ns:ns,id:(p as IdentifierPattern).ident});
                    var fx = new ValFixture (t,ro);
                    var fxtrs = [[nm,fx]];
                    if (e !== null) {
                        var inits = [[nm,e]];
                    }
                    else {
                        var inits = [];
                    }
                    var expr = new InitExpr (it, new Head ([],[]), inits);
                } else if (x is SimplePattern) {
                    if (e === null) throw "simple pattern without initializer";
                    var fxtrs = [];
                    if (it != null) { // we have an init target so must be an init
                        var ie = identExprFromExpr ((p as SimplePattern).expr);
                        var nm = cx.resolveIdentExpr (ie,it);
                        var expr = new InitExpr (it, new Head ([],[]), [[nm,e]]);
                    }
                    else {
                        var expr = new SetExpr (op,(p as SimplePattern).expr,e);
                    }
                } else {
                    var tn = new TempName (n);
                    var fxtrs = [];
                    var exprs = [];
                    var ptrns = (p as Object).ptrns;
                    for (var i=0; i<ptrns.length; ++i) {
                        var sub = ptrns[i];
                        /// switch type (sub) {
                        /// case (sub: FieldPattern) {
                        if (sub is FieldPattern) {
                            var typ = new FieldTypeRef (t,sub.ident);
                            var exp = new ObjectRef (new GetTemp (n), sub.ident);
                            var ptn = sub.ptrn;
                        }
                        /// case (pat: *) {
                        else {
                            var typ = new ElementTypeRef (t,i);
                            var exp = new ObjectRef (new GetTemp (n), new Identifier (i,[[Ast.noNS]]));
                                      // FIXME what is the ns of a temp and how do we refer it
                            var ptn = sub;
                        }
                        /// }

                        //var [fx,ex] = desugarSubPattern (ptn,typ,exp,n+1);
                        var tmp:Array = desugarSubPattern (ptn,typ,exp,n+1);
                        var fx = tmp[0], ex = tmp[1];
                        for (var j=0; j<fx.length; ++j) fxtrs.push(fx[j]);
                        exprs.push(ex);
                    }
                    var head = new Head ([[tn,new ValFixture (Ast.anyType,false)]],[new InitExpr (Ast.letInit,new Head([],[]),[[tn,e]])]);
                    var expr = new LetExpr (head, new ListExpr (exprs));
                }
                Debug.exit("desugarSubPattern","");
                return [fxtrs,expr];
            }
        }

        // Parse rountines

        /*

        Identifier
            Identifier
            call
            debugger
            dynamic
            each
            final
            get
            goto
            include
            namespace
            native
            override
            prototype
            set
            static
            type
            xml

        */

        public function identifier (ts: TokenStream)
            : Array //[TokenStream, IDENT]
        {
            Debug.enter("Parser::identifier ", ts);

            var str = "";   // fixme: evaluator isn't happy if this is inside of the switch

            switch (hd (ts)) {
            case Token.Identifier:
            case Token.Call:
            case Token.Cast:
            case Token.Const:
            case Token.Decimal:
            case Token.Double:
            case Token.Dynamic:
            case Token.Each:
            case Token.Eval:
            case Token.Final:
            case Token.Get:
            case Token.Has:
            case Token.Implements:
            case Token.Import:
            case Token.Int:
            case Token.Interface:
            case Token.Internal:
            case Token.Intrinsic:
            case Token.Is:
            case Token.Let:
            case Token.Namespace:
            case Token.Native:
            case Token.Number:
            case Token.Override:
            case Token.Package:
            case Token.Precision:
            case Token.Private:
            case Token.Protected:
            case Token.Prototype:
            case Token.Public:
            case Token.Rounding:
            case Token.Standard:
            case Token.Strict:
            case Token.Set:
            case Token.Static:
            case Token.To:
            case Token.Type:
            case Token.UInt:
            case Token.Undefined:
            case Token.Use:
            case Token.Xml:
            case Token.Yield:
                var str = Token.tokenText (ts.head());
                break;
            default:
                throw "expecting identifier, found " + Token.tokenText (ts.head());
            }
            Debug.exit("Parser::identifier ", str);
            return [tl (ts), str];
        }

        function isReserved (tk: int) {
            switch (tk) {
            case Token.Break:
                break;
            // FIXME more of these
            default:
                return false;
                break;
            }
        }

        function reservedOrOrdinaryIdentifier (ts: TokenStream)
            : Array //[TokenStream, IDENT]
        {
            Debug.enter("Parser::reservedOrOrdinaryIdentifer");

            if (isReserved (hd (ts))) 
            {
                //var [ts1,nd1] = Token.tokenText (hd (ts));
                var tmp = Token.tokenText (hd (ts));
                var ts1 = tmp[0], nd1 = tmp[1];
            }
            else 
            {
                //var [ts1,nd1] = identifier (ts);
                var tmp = identifier (ts);
                var ts1 = tmp[0], nd1 = tmp[1];
            }

            Debug.exit("Parser::reservedOrOrdinaryIdentifier");
            return [ts1,nd1];
        }

        /*
            Qualifier
                *
                ReservedNamespace
                Identifier
        */

        function qualifier(ts)
            : Array //[TokenStream, (IDENT,IAstNamespace)]
        {
            Debug.enter("Parser::qualifier ",ts);

            switch (hd(ts)) {
            case Token.Internal:
            case Token.Intrinsic:
            case Token.Private:
            case Token.Protected:
            case Token.Public:
                //var [ts1,nd1] = reservedNamespace(ts);
                var tmp = reservedNamespace(ts);
                var ts1 = tmp[0], nd1 = tmp[1];
                break;
            case Token.Mult:
                var id = Token.tokenText (ts.head());
                //var [ts1,nd1] = [tl (ts), id];
                var tmp = [tl (ts), id];
                var ts1 = tmp[0], nd1 = tmp[1];
                break;
            default:
                //var [ts1,nd1] = identifier (ts);
                var tmp = identifier (ts);
                var ts1 = tmp[0], nd1 = tmp[1];
                break;
            }

            Debug.exit("Parser::qualifier ",nd1);
            return [ts1,nd1];
        }

        /*
            ReservedNamespace
                internal
                intrinsic
                private
                protected
                public
        */

        function reservedNamespace (ts: TokenStream)
			: Array //[TokenStream, IAstNamespace]
        {
            Debug.enter("Parser::reservedNamespace ", ts);

            switch (hd (ts)) {
            case Token.Internal:
                //var [ts1,nd1] = [tl (ts), new InternalNamespace (currentPackageName)];
                var ts1 = tl (ts);
                var nd1 = new InternalNamespace (currentPackageName);
                break;
            case Token.Public:
                //var [ts1,nd1] = [tl (ts), new PublicNamespace (currentPackageName)];
                var ts1 = tl (ts);
                var nd1 = new PublicNamespace (currentPackageName);
                break;
            case Token.Intrinsic:
                //var [ts1,nd1] = [tl (ts), new IntrinsicNamespace];
                var ts1 = tl (ts);
                var nd1 = new IntrinsicNamespace;
                break;
            case Token.Private:
                //var [ts1,nd1] = [tl (ts), new PrivateNamespace (currentClassName)];
                var ts1 = tl (ts);
                var nd1 = new PrivateNamespace (currentClassName);
                break;
            case Token.Protected:
                //var [ts1,nd1] = [tl (ts), new ProtectedNamespace (currentClassName)];
                var ts1 = tl (ts);
                var nd1 = new ProtectedNamespace (currentClassName);
                break;
            }

            Debug.exit("Parser::reservedNamespace ", ts1);
            return [ts1,nd1];
        }

        /*
          QualifiedNameIdentifier
              *
              Identifier
              ReservedIdentifier
              String
              Number
              Brackets
        */

        function qualifiedNameIdentifier (ts1: TokenStream, nd1: IAstExpr)
            : Array //[TokenStream, IAstIdentExpr]
        {
            Debug.enter("Parser::qualifiedNameIdentifier ", ts1);

            switch (hd(ts1)) {
                case Token.Mult:
                    //var [ts2,nd2] = [tl(ts1), "*"];
                    var ts2 = tl(ts1);
                    var nd2 = "*";
                    //var [ts3,nd3] = [ts1, new QualifiedIdentifier (nd1,nd2)];
                    var ts3 = ts1;
                    var nd3 = new QualifiedIdentifier (nd1,nd2);
                    break;
                case Token.StringLiteral:
                case Token.DecimalLiteral:
                    var str = Token.tokenText (ts1.head());
                    //var [ts2,nd2] = [tl(ts1), str];
                    var ts2 = tl(ts1);
                    var nd2 = str;
                    //var [ts3,nd3] = [ts1, new QualifiedIdentifier (nd1,nd2)];
                    var ts3 = ts1;
                    var nd3 = new QualifiedIdentifier (nd1,nd2);
                    break;
                case Token.LeftBracket:
                    //var [ts2,nd2] = brackets (ts1);
                    var tmp = brackets (ts1);
                    var ts2 = tmp[0], nd2 = tmp[1];
                    //var [ts3,nd3] = [ts1, new QualifiedExpression (nd1,nd2)];
                    var ts3 = ts1;
                    var nd3 = new QualifiedExpression (nd1,nd2);
                    break;
                default:
                    //var [ts2,nd2] = identifier (ts1);
                    var tmp = identifier (ts1);
                    var ts2 = tmp[0], nd2 = tmp[1];
                    //var [ts3,nd3] = [ts2, new QualifiedIdentifier (nd1,nd2)];
                    var ts3 = ts2;
                    var nd3 = new QualifiedIdentifier (nd1,nd2);
                    break;
            }

            Debug.exit("Parser::qualifiedNameIdentifier ", nd3);
            return [ts3,nd3];
        }

        /*
          SimpleQualifiedName
              Identifier
              Qualifier  ::  QualifiedNameIdentifier
        */

        function simpleQualifiedName (ts: TokenStream)
            : Array //[TokenStream, IAstIdentExpr]
        {
            Debug.enter("Parser::simpleQualifiedName ", ts);

            //var [ts1,nd1] = qualifier (ts);
            var tmp = qualifier (ts);
            var ts1 = tmp[0], nd1 = tmp[1];
            
            switch (hd (ts1)) {
            case Token.DoubleColon:
            
            	var x = nd1;
            	if (x is String) {
                    nd1 = new LexicalRef (new Identifier (nd1,cx.pragmas.openNamespaces))
                } else {
                    nd1 = new LiteralExpr (new LiteralNamespace (nd1));
                }
                //var [ts2,nd2] = qualifiedNameIdentifier (tl(ts1), nd1);
                var tmp = qualifiedNameIdentifier (tl(ts1), nd1);
                var ts2 = tmp[0], nd2 = tmp[1];
                break;
            default:
            
            	var x = nd1;
            	if (x is String) {
                    //var [ts2,nd2] = [ts1,new Identifier (nd1,cx.pragmas.openNamespaces)];
                    var ts2 = ts1, nd2 = new Identifier (nd1,cx.pragmas.openNamespaces);
                } else {
                    //var [ts2,nd2] = [ts1,new ReservedNamespace (nd1)];
                    var ts2 = ts1, nd2 = new ReservedNamespace (nd1);
                }
                break;
            }

            Debug.exit("Parser::simpleQualifiedName ", ts2);
            return [ts2,nd2];
        }

        /*
            ExpressionQualifiedName
                ParenListExpression :: QualifiedName
        */

        /*
            NonAttributeQualifiedIdentifier
                SimpleQualifiedName
                ExpressionQualifiedName
        */

        function nonAttributeQualifiedName (ts: TokenStream)
            : Array //[TokenStream, IAstIdentExpr]
        {
            Debug.enter("Parser::nonAttributeQualifiedName ", ts);

            switch (hd (ts)) {
            case Token.LeftParen:
                //var [ts1,nd1] = expressionQualifiedIdentifier (ts);
                var tmp = expressionQualifiedIdentifier (ts);
                var ts1 = tmp[0], nd1 = tmp[1];
                break;
            default:
                //var [ts1,nd1] = simpleQualifiedName (ts);
                var tmp = simpleQualifiedName (ts);
                var ts1 = tmp[0], nd1 = tmp[1];
            }

            Debug.exit("Parser::nonAttributeQualifiedName ", ts1);
            return [ts1,nd1];
        }

        /*
            AttributeQualifiedIdentifier
                @ Brackets
                @ NonAttributeQualifiedIdentifier
        */

        /*
            QualifiedName
                AttributeName
                NonAttributeQualifiedName
        */

        function qualifiedName (ts: TokenStream)
            : Array //[TokenStream, IAstIdentExpr]
        {
            Debug.enter("Parser::qualifiedName ", ts);

            switch (hd (ts)) {
            case Token.LeftParen:
                //var [ts1,nd1] = expressionQualifiedIdentifier (ts);
                var tmp = expressionQualifiedIdentifier (ts);
                var ts1 = tmp[0], nd1 = tmp[1];
                break;
            default:
                //var [ts1,nd1] = simpleQualifiedName (ts);
                var tmp = simpleQualifiedName (ts);
                var ts1 = tmp[0], nd1 = tmp[1];
            }

            Debug.exit("Parser::qualifiedName ", ts1);
            return [ts1,nd1];
        }

        /*
            PropertyName
                NonAttributeQualifiedName
                NonAttributeQualifiedName  .<  TypeExpressionList  >
                (  TypeExpression  )  .<  TypeExpressionList  >

            e.g.
                A.<B.<C.<t>,D.<u>>>
        */

        function propertyName (ts: TokenStream)
            : Array //[TokenStream, IAstIdentExpr]
        {
            Debug.enter("Parser::propertyName ", ts);

            switch (hd (ts)) {
/*  FIXME: this is a grammar bug
            case Token.LeftParen:
                var [ts1,nd1] = typeExpression (tl (ts));
                ts1 = eat (ts1,Token.RightParen);
                break;
*/
            default:
                //var [ts1,nd1] = nonAttributeQualifiedName (ts);
                var tmp = nonAttributeQualifiedName (ts);
                var ts1 = tmp[0], nd1 = tmp[1];
            }

            switch (hd (ts1)) {
            case Token.LeftDotAngle:
                //var [ts2,nd2] = typeExpressionList (tl (ts1));
                var tmp = typeExpressionList (tl (ts1));
                var ts2 = tmp[0], nd2 = tmp[1];
                switch (hd (ts2)) {
                case Token.UnsignedRightShift:
                    // downgrade >>> to >> to eat one >
                    ts2 = swap (ts2,Token.UnsignedRightShift,Token.RightShift);
                    break;
                case Token.RightShift:
                    // downgrade >> to > to eat one >
                    ts2 = swap (ts2,Token.RightShift,Token.GreaterThan);
                    break;
                default:
                    ts2 = eat (ts2,Token.GreaterThan);
                    break;
                }
                break;
            default:
                //var [ts2,nd2] = [ts1,nd1];
                var ts2 = ts1, nd2 = nd1;
                break;
            }

            Debug.exit("Parser::propertyName ", ts2);
            return [ts2,nd2];
        }

        /*
            PrimaryName
                Path  .  PropertyName
                PropertyName
        */

        function primaryName (ts: TokenStream)
            : Array //[TokenStream, IAstIdentExpr]
        {
            Debug.enter("Parser::primaryName ", ts);

            switch (hd (ts)) {
            case Token.Identifier:
                switch (hd2 (ts)) {
                case Token.Dot:
                    var tx = Token.tokenText(ts.head());
                    //var [ts1,nd1] = path (tl (tl (ts)), [tx]);
                    var tmp = path (tl (tl (ts)), [tx]);
                    var ts1=tmp[0], nd1=tmp[1];
                    //var [ts2,nd2] = propertyName (ts1);
                    var tmp  = propertyName (ts1);
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new UnresolvedPath (nd1,nd2);
                    break;
                default:
                    //var [ts2,nd2] = propertyName (ts);
                    var tmp = propertyName (ts);
                    var ts2=tmp[0], nd2=tmp[1];
                    break;
                }
                break;
            default:
                //var [ts2,nd2] = propertyName (ts);
                var tmp = propertyName (ts);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            }

            Debug.exit("Parser::primaryName ", ts2);
            return [ts2,nd2];
        }

        /*
            Path
                Identifier
                Path  .  Identifier
        */

        function path (ts: TokenStream, nd /*: [IDENT]*/ )  /* FIXME: verifier bug */
            : Array //[TokenStream, [IDENT]]
        {
            Debug.enter("Parser::path ", ts);

            switch (hd (ts)) {
            case Token.Identifier:
                switch (hd2 (ts)) {
                case Token.Dot:
                    nd.push(Token.tokenText(ts.head()));
                    //var [ts1,nd1] = path (tl (tl (ts)), nd);
                    var tmp = path (tl (tl (ts)), nd);
                    var ts1=tmp[0], nd1=tmp[1];
                    break;
                default:
                    //var [ts1,nd1] = [ts,nd];
                    var ts1=ts, nd1=nd;
                    break;
                }
                break;
            default:
                //var [ts1,nd1] = [ts,nd];
                var ts1=ts, nd1=nd;
                break;
            }

            Debug.exit("Parser::path ", ts1);
            return [ts1,nd1];
        }

        function parenExpression (ts: TokenStream)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::parenExpression ", ts);

            var ts1 = eat (ts,Token.LeftParen);
            //var [ts2,ndx] = assignmentExpression (ts1, allowIn);
            var tmp = assignmentExpression (ts1, allowIn);
            var ts2=tmp[0], ndx=tmp[1];
            var tsx = eat (ts2,Token.RightParen);

            Debug.exit("Parser::parenExpression ", tsx);
            return [tsx, ndx];
        }

        function parenListExpression (ts: TokenStream)
            : Array //[TokenStream, [IAstExpr]]
        {
            Debug.enter("Parser::parenListExpression ", ts);

            var ts1 = eat (ts,Token.LeftParen);
            //var [ts2,ndx] = listExpression (ts1, allowIn);
            var tmp = listExpression (ts1, allowIn);
            var ts2=tmp[0], ndx=tmp[1];
            var tsx = eat (ts2,Token.RightParen);

            Debug.exit("Parser::parenListExpression ", tsx);
            return [tsx, ndx];
        }

        /*

        ObjectLiteral(noColon)
            {  FieldList  }

        ObjectLiteral(allowColon)
            {  FieldList  }
            {  FieldList  }  :  TypeExpression

        */

        function objectLiteral (ts: TokenStream /*, alpha: IAlpha*/)
            : Array //[TokenStream, IAstTypeExpr]
        {
            Debug.enter("Parser::objectLiteral ", ts);

            var alpha: IAlpha = allowColon;    // FIXME need to get this from caller
            ts = eat (ts,Token.LeftBrace);
            //var [ts1,nd1] = fieldList (ts);
            var tmp = fieldList (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.RightBrace);
            switch (alpha) {
            case allowColon:
                switch (hd (ts1)) {
                case Token.Colon:
                    //var [ts2,nd2] = typeExpression (tl (ts1));
                    var tmp = typeExpression (tl (ts1));
                    var ts2=tmp[0], nd2=tmp[1];
                    break;
                default:
                    //var [ts2,nd2] = [ts1,new ObjectType ([])]; // FIXME I mean {*}
                    var tmp = [ts1,new ObjectType ([])]; // FIXME I mean {*}
                    var ts2=tmp[0], nd2=tmp[1];
                    break;
                }
                break;
            default:
                //var [ts2,nd2] = [ts1,new ObjectType ([])]; // FIXME I mean {*}
                var tmp = [ts1,new ObjectType ([])]; // FIXME I mean {*}
                var ts2=tmp[0], nd2=tmp[1];
                break;
            }

            Debug.exit("Parser::objectLiteral ", ts2);
            return [ts2,new LiteralExpr (new LiteralObject (nd1,nd2))];
        }

        /*

        FieldList
            empty
            LiteralField
            LiteralField  ,  LiteralFieldList

        */

        function fieldList (ts: TokenStream)
            //            : [TokenStream, [FIELD_TYPE]]
        {
            Debug.enter("Parser::fieldList ", ts);

            var nd1 = [];
            var ts1 = ts;

            if (hd (ts) !== Token.RightBrace) 
            {
                //var [ts1,ndx] = literalField (ts);
                var tmp = literalField (ts);
                var ts1=tmp[0], ndx=tmp[1];
                nd1.push (ndx);
                while (hd (ts1) === Token.Comma) {
                    //var [ts1,ndx] = literalField (tl (ts1));
                    var tmp = literalField (tl (ts1));
                    var ts1=tmp[0], ndx=tmp[1];
                    nd1.push (ndx);
                }
            }

            Debug.exit("Parser::fieldList ", ts1);
            return [ts1,nd1];
        }

        /*

          LiteralField
              FieldKind  FieldName  :  AssignmentExpressionallowColon, allowIn
              get  FieldName  FunctionSignature  FunctionExpressionBodyallowColon, allowIn
              set  FieldName  FunctionSignature  FunctionExpressionBodyallowColon, allowIn

        */

        function literalField (ts: TokenStream)
            : Array //[TokenStream, FIELD_TYPE]
        {
            Debug.enter("Parser::literalField",ts);

            switch (hd (ts)) {
            case Token.Const:
                //var [ts1,nd1] = [tl (ts), constTag];
                var ts1= tl (ts), nd1=Ast.constTag;
                break;
            default:
                //var [ts1,nd1] = [ts,varTag];
                var ts1=ts, nd1=Ast.varTag;
                break;
            }

            //var [ts2,nd2] = fieldName (ts);
            var tmp = fieldName (ts);
            var ts2=tmp[0], nd2=tmp[1];
            ts2 = eat (ts2,Token.Colon);

            switch (hd (ts2)) {
            case Token.LeftBrace:   // short cut to avoid recursion
                //var [ts3,nd3] = objectLiteral (ts2);
                var tmp = objectLiteral (ts2);
                var ts3=tmp[0], nd3=tmp[1];
                break;
            case Token.LeftBracket:
                //var [ts3,nd3] = arrayLiteral (ts2);
                var tmp = arrayLiteral (ts2);
                var ts3=tmp[0], nd3=tmp[1];
                break;
            default:
                //var [ts3,nd3] = assignmentExpression (ts2,allowIn);
                var tmp = assignmentExpression (ts2,allowIn);
                var ts3=tmp[0], nd3=tmp[1];
                break;
            }

            Debug.exit("Parser::literalField", ts3);
            return [ts3, new LiteralField (nd1,nd2,nd3)];
        }

        /*

        FieldName
            NonAttributeQualifiedName
            StringLiteral
            NumberLiteral
            ReservedIdentifier

        */

        function fieldName (ts: TokenStream)
            : Array //[TokenStream, IAstIdentExpr]
        {
            Debug.enter("Parser::fieldName",ts);

            switch (hd (ts)) {
            case Token.StringLiteral:
                var nd = new Identifier (Token.tokenText (ts.head()),cx.pragmas.openNamespaces);
                //var [ts1,nd1] = [tl (ts), nd];
                var ts1=tl (ts), nd1=nd;
                break;
            case Token.DecimalLiteral:
            case Token.DecimalIntegerLiteral:
            case Token.HexIntegerLiteral:
                throw "unsupported fieldName " + hd(ts);
                break;
            default:
                if (isReserved (hd (ts))) {
                    var nd = new Identifier (Token.tokenText (ts.head()),cx.pragmas.openNamespaces);
                    //var [ts1,nd1] = [tl (ts), nd];
                    var ts1=tl (ts), nd1=nd;
                                     // NOTE we use openNamespaces here to indicate that the name is 
                                     //      unqualified. the generator should use the expando namespace,
                                     //      which is probably Public "".
                }
                else {
                    //var [ts1,nd1] = nonAttributeQualifiedName (ts);
                    var tmp = nonAttributeQualifiedName (ts);
                    var ts1=tmp[0], nd1=tmp[1];
                }
                break;
            }

            Debug.exit("Parser::fieldName");
            return [ts1,nd1];
        }

        /*

        ArrayLiteral(noColon)
            [  Elements  ]
        
        ArrayLiteral(allowColon)
            [  Elements  ]
            [  Elements  ]  :  TypeExpression
        
        Elements
            ElementList
            ElementComprehension

        */

        function arrayLiteral (ts: TokenStream)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::arrayLiteral ", ts);

            ts = eat (ts,Token.LeftBracket);
            //var [ts1,nd1] = elementList (ts);
            var tmp = elementList (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.RightBracket);

            Debug.exit("Parser::arrayLiteral ", ts1);
            return [ts1, new LiteralExpr (new LiteralArray (nd1,new ArrayType ([])))];
        }

        /*

        ElementList
            empty
            LiteralElement
            ,  ElementList
             LiteralElement  ,  ElementList

        LiteralElement
            AssignmentExpression(allowColon,allowIn)

        */

        function elementList (ts: TokenStream)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::elementList ", ts);

            var nd1 = [];
            var ts1 = ts;

            if (hd (ts) !== Token.RightBracket) 
            {
                switch (hd (ts)) {
                case Token.Comma:
                    //var [ts1,ndx] = [tl (ts),new LiteralExpr (new LiteralUndefined)];
                    var ts1=tl (ts), ndx=new LiteralExpr (new LiteralUndefined);
                    break;
                default:
                    switch (hd (ts1)) {
                    case Token.LeftBrace:
                        //var [ts1,ndx] = objectLiteral (ts1);
                        var tmp = objectLiteral (ts1);
                        var ts1=tmp[0], ndx=tmp[1];
                        break;
                    case Token.LeftBracket:
                        //var [ts1,ndx] = arrayLiteral (ts1);
                        var tmp = arrayLiteral (ts1);
                        var ts1=tmp[0], ndx=tmp[1];
                        break;
                    default:
                        //var [ts1,ndx] = assignmentExpression (ts1,allowIn);
                        var tmp = assignmentExpression (ts1,allowIn);
                        var ts1=tmp[0], ndx=tmp[1];
                        break;
                    }
                    break;
                }
                nd1.push (ndx);
                while (hd (ts1) === Token.Comma) {
                    ts1 = eat (ts1,Token.Comma);
                    switch (hd (ts1)) {
                    case Token.Comma:
                        //var [ts1,ndx] = [ts1,new LiteralExpr (new LiteralUndefined)];
                        var ts1=ts1, ndx=new LiteralExpr (new LiteralUndefined);
                        break;
                    case Token.RightBracket:
                        continue;  // we're done
                    default:
                        switch (hd (ts1)) {
                        case Token.LeftBrace:
                            //var [ts1,ndx] = objectLiteral (ts1);
                            var tmp = objectLiteral (ts1);
                            var ts1=tmp[0], ndx=tmp[1];
                            break;
                        case Token.LeftBracket:
                            //var [ts1,ndx] = arrayLiteral (ts1);
                            var tmp = arrayLiteral (ts1);
                            var ts1=tmp[0], ndx=tmp[1];
                            break;
                        default:
                            //var [ts1,ndx] = assignmentExpression (ts1,allowIn);
                            var tmp = assignmentExpression (ts1,allowIn);
                            var ts1=tmp[0], ndx=tmp[1];
                            break;
                        }
                        break;
                    }
                    nd1.push (ndx);
                }
            }

            Debug.exit("Parser::elementList ", ts1);
            return [ts1, nd1];
        }

        /*

        PrimaryExpression
            null
            true
            false
            NumberLiteral
            StringLiteral
            this
            RegularExpression
            XMLInitialiser
            ParenListExpression
            ArrayLiteral
            ObjectLiteral
            FunctionExpressionb
            AttributeIdentifier
            PrimaryIdentifier
        */

        function primaryExpression(ts:TokenStream,beta:IBeta)
            : Array //[TokenStream,IAstExpr]
        {
            Debug.enter("Parser::primaryExpression ",ts);

            switch (hd (ts)) {
            case Token.Null:
                //var [ts1,nd1] = [tl (ts), new LiteralExpr (new LiteralNull ())];
                var ts1=tl (ts), nd1=new LiteralExpr (new LiteralNull ());
                break;
            case Token.True:
                //var [ts1,nd1] = [tl (ts), new LiteralExpr (new LiteralBoolean (true))];
                var ts1=tl (ts), nd1=new LiteralExpr (new LiteralBoolean (true));
                break;
            case Token.False:
                //var [ts1,nd1] = [tl (ts), new LiteralExpr (new LiteralBoolean (false))];
                var ts1=tl (ts), nd1=new LiteralExpr (new LiteralBoolean (false));
                break;
            case Token.DecimalLiteral:
                var tx = Token.tokenText (ts.head());
                //var [ts1,nd1] = [tl (ts), new LiteralExpr (new LiteralDecimal (tx))];
                var ts1=tl (ts), nd1=new LiteralExpr (new LiteralDecimal (tx));
                break;
            case Token.StringLiteral:
                var tx = Token.tokenText (ts.head());
                //var [ts1,nd1] = [tl (ts), new LiteralExpr (new LiteralString (tx))];
                var ts1=tl (ts), nd1=new LiteralExpr (new LiteralString (tx));
                break;
            case Token.This:
                //var [ts1,nd1] = [tl (ts), new ThisExpr ()];
                var ts1=tl (ts), nd1=new ThisExpr ();
                break;
//            else
//            if( lookahead(regexpliteral_token) )
//            {
//                var result = <LiteralRegExp value={scan.tokenText(match(regexpliteral_token))}/>
//            }
//            else
//            if( lookahead(function_token) )
//            {
//                match(function_token);
//                var first = null
//                if( lookahead(identifier_token) )
//                {
//                    first = parseIdentifier();
//                }
//                var result = parseFunctionCommon(first);
//            }
            case Token.LeftParen:
                //var [ts1,nd1] = parenListExpression(ts);
                var tmp = parenListExpression(ts);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.LeftBracket:
                //var [ts1,nd1] = arrayLiteral (ts);
                var tmp = arrayLiteral (ts);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.LeftBrace:
                //var [ts1,nd1] = objectLiteral (ts);
                var tmp = objectLiteral (ts);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            default:
                //var [ts1,nd1] = primaryName (ts);
                var tmp = primaryName (ts);
                var ts1=tmp[0], nd1=tmp[1];
                
                var x=nd1;
                if (x is UnresolvedPath) {
                	var nd = x as UnresolvedPath;
                    var base = resolvePath (nd.path,null);
                    nd1 = new ObjectRef (base,nd.ident);  // FIXME: not good for package qualified refs
                } else {
                    nd1 = new LexicalRef (nd1);
                }
                break;
            }

            Debug.exit("Parser::primaryExpression ",ts1);
            return [ts1,nd1];
        }

        function resolvePath (path/*: [IDENT]*/, expr: IAstExpr)
        {
            return resolveObjectPath (path,expr);
        }

        function resolveObjectPath (path /*: [IDENT]*/, expr: IAstExpr)
            : IAstExpr
        {
            if (path.length === 0) {
                return expr;
            }
            else
            if (expr === null) 
            {
                var base = new LexicalRef (new Identifier (path[0],cx.pragmas.openNamespaces));
                return resolveObjectPath (path.slice (1,path.length), base);
            }
            else 
            {
                var base = new ObjectRef (expr, new Identifier (path[0],cx.pragmas.openNamespaces));
                return resolveObjectPath (path.slice (1,path.length), base);
            }
        }

        /*

        SuperExpression
            super
            super  Arguments

        */


        /*

        PropertyOperator
            .  ReservedIdentifier
            .  PropertyName
            .  AttributeName
            ..  QualifiedName
            .  ParenListExpression
            .  ParenListExpression  ::  QualifiedNameIdentifier
            Brackets

        */

        function propertyOperator (ts: TokenStream, nd: IAstExpr)
            : Array //[TokenStream, [IAstExpr]]
        {
            Debug.enter("Parser::propertyOperator ", ts);

            switch (hd (ts)) {
            case Token.Dot:
                switch (hd2 (ts)) {
                case Token.LeftParen:
                    throw "filter operator not implemented";
                    break;
                default:
                    //                    if (isReservedIdentifier (hd (ts))) {
                    //                    }
                    //var [ts1,nd1] = propertyName (tl (ts));
                    var tmp = propertyName (tl (ts));
                    var ts1=tmp[0], nd1=tmp[1];
                    //var [tsx,ndx] = [ts1, new ObjectRef (nd,nd1)];
                    var tsx=ts1, ndx= new ObjectRef (nd,nd1);
                    break;
                }
                break;
            case Token.LeftBracket:
                //var [ts1,nd1] = listExpression (tl (ts), allowIn);
                var tmp = listExpression (tl (ts), allowIn);
                var ts1=tmp[0], nd1=tmp[1];
                ts1 = eat (ts1,Token.RightBracket);
                //var [tsx,ndx] = [ts1, new ObjectRef (nd,new ExpressionIdentifier (nd1,cx.pragmas.openNamespaces))];
                var tsx=ts1, ndx=new ObjectRef (nd,new ExpressionIdentifier (nd1,cx.pragmas.openNamespaces));
                break;
            case Token.DoubleDot:
                throw "descendents operator not implemented";
                break;
            default:
                throw "internal error: propertyOperator";
                break;
            }

            Debug.exit("Parser::propertyOperator ", tsx);
            return [tsx, ndx];
        }

        /*

        Arguments
            (  )
            (  ArgumentList  )

        ArgumentList
            AssignmentExpression(allowIn)
            ArgumentList  ,  AssignmentExpression(allowIn)

        */

        function arguments (ts: TokenStream)
            : Array //[TokenStream, * /*[IAstExpr]*/]
        {
            Debug.enter("Parser::arguments ", ts);

            var ts1 = eat (ts,Token.LeftParen);
            switch (hd (ts1)) {
            case Token.RightParen:
                var tsx = eat (ts1,Token.RightParen);
                var ndx = [];
                break;
            default:
                //var [ts2,nd2] = listExpression (ts1, allowIn);
                var tmp = listExpression (ts1, allowIn);
                var ts2=tmp[0], nd2=tmp[1];
                var tsx = eat (ts2,Token.RightParen);
                var ndx = nd2.exprs;
                break;
            }
            Debug.exit("Parser::arguments ", tsx);
            return [tsx, ndx];
        }

        /*

        MemberExpression(beta)
            PrimaryExpression(beta)
            new  MemberExpression(beta)  Arguments
            SuperExpression  PropertyOperator
            MemberExpression(beta)  PropertyOperator

        Refactored:

        MemberExpression(beta)
            PrimaryExpression(beta) MemberExpressionPrime(beta)
            new MemberExpression(beta) Arguments MemberExpressionPrime(beta)
            SuperExpression  PropertyOperator  MemberExpressionPrime(beta)

        MemberExpressionPrime(beta)
            PropertyOperator MemberExpressionPrime(beta)
            empty

        Note: member expressions always have balanced new and (). The LHS parser is
        responsible for dispatching extra 'new' or '()' to 

        */

        function memberExpression (ts: TokenStream, beta:IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::memberExpression ", ts);

            switch (hd (ts)) {
            case Token.New:
                //var [ts1,nd1] = memberExpression (tl (ts), beta);
                var tmp = memberExpression (tl (ts), beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [ts2,nd2] = this.arguments (ts1);
                var tmp = this.arguments (ts1);
                var ts2=tmp[0], nd2=tmp[1];
                //var [tsx,ndx] = memberExpressionPrime (ts2, beta, new NewExpr (nd1,nd2));
                var tmp = memberExpressionPrime (ts2, beta, new NewExpr (nd1,nd2));
                var tsx=tmp[0], ndx=tmp[1];
                break;
            case Token.Super:
                //var [ts1,nd1] = superExpression (ts);
                var tmp = superExpression (ts);
                var ts1=tmp[0],nd1=tmp[1];
                //var [ts2,nd2] = propertyOperator (ts1,nd1);
                var tmp = propertyOperator (ts1,nd1);
                var ts2=tmp[0], nd2=tmp[1];
                //var [tsx,ndx] = memberExpressionPrime (ts2, beta, nd2);
                var tmp = memberExpressionPrime (ts2, beta, nd2);
                var tsx=tmp[0], ndx=tmp[1];
            default:
                //var [ts1,nd1] = primaryExpression (ts,beta);
                var tmp = primaryExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = memberExpressionPrime (ts1, beta, nd1);
                var tmp = memberExpressionPrime (ts1, beta, nd1);
                var tsx=tmp[0], ndx=tmp[1];
                break;
            }

            Debug.exit("Parser::memberExpression ", tsx);
            return [tsx, ndx];
        }

        function memberExpressionPrime (ts: TokenStream, beta:IBeta, nd: IAstExpr)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::memberExpressionPrime ", ts);

            switch (hd (ts)) {
            case Token.LeftBracket:
            case Token.Dot:
            case Token.DoubleDot:
                //var [ts1,nd1] = propertyOperator (ts,nd);
                var tmp = propertyOperator (ts,nd);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = memberExpressionPrime (ts1, beta, nd1);
                var tmp = memberExpressionPrime (ts1, beta, nd1);
                var tsx=tmp[0], ndx=tmp[1];
                break;
            default:
                //var [tsx,ndx] = [ts,nd]
                var tsx=ts, ndx=nd;
                break;
            }

            Debug.exit("Parser::memberExpressionPrime ", tsx);
            return [tsx, ndx];
        }

        /*

        CallExpression(beta)
            MemberExpression(beta) Arguments CallExpressionPrime(beta) 

        CallExpressionPrime(beta)
            Arguments CallExpressionPrime(beta)
            [ Expression ] CallExpressionPrime(beta)
            . Identifier CallExpressionPrime(beta)
            empty

        */

        function callExpression (ts: TokenStream, beta:IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::callExpression ", ts);

            //var [ts1,nd1] = memberExpression (ts,beta);
            var tmp = memberExpression (ts,beta);
            var ts1=tmp[0], nd1=tmp[1];
            //var [ts2,nd2] = this.arguments (ts);
            var tmp = this.arguments (ts);
            var ts2=tmp[0], nd2=tmp[1];
            //var [tsx,ndx] = callExpressionPrime (ts2, beta, new CallExpr (nd1,nd2));
            var tmp = callExpressionPrime (ts2, beta, new CallExpr (nd1,nd2));
            var tsx=tmp[0], ndx=tmp[1];

            Debug.exit("Parser::callExpressionPrime ", ndx);
            return [tsx, ndx];
        }

        function callExpressionPrime (ts: TokenStream, beta:IBeta, nd: IAstExpr)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::callExpressionPrime ", ts);

            switch (hd (ts)) {
            case Token.LeftParen:
                //var [ts1,nd1] = this.arguments (ts);
                var tmp = this.arguments (ts);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = callExpressionPrime (ts1, beta, new CallExpr (nd,nd1));
                var tmp = callExpressionPrime (ts1, beta, new CallExpr (nd,nd1));
                var tsx=tmp[0], ndx=tmp[1];
                break;
            case Token.LeftBracket:
            case Token.Dot:
            case Token.DoubleDot:
                //var [ts1,nd1] = propertyOperator (ts,nd);
                var tmp = propertyOperator (ts,nd);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = callExpressionPrime (ts1, beta, nd1);
                var tmp = callExpressionPrime (ts1, beta, nd1);
                var tsx=tmp[0], ndx=tmp[1];
                break;
            default:
                //var [tsx,ndx] = [ts,nd]
                var tsx=ts, ndx=nd;
                break;
            }

            Debug.exit("Parser::callExpressionPrime ", ndx);
            return [tsx, ndx];
        }

        /*

        NewExpression
            MemberExpression
            new  NewExpression

        */

        function newExpression (ts: TokenStream, beta:IBeta, new_count=0)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::newExpression ", ts);

            switch (hd (ts)) {
            case Token.New:
                //var [ts1,nd1] = newExpression (tl (ts), beta, new_count+1);
                var tmp = newExpression (tl (ts), beta, new_count+1);
                var ts1=tmp[0], nd1=tmp[1]
                switch (hd (ts1)) {
                case Token.LeftParen:  // no more new exprs so this paren must start a call expr
                    //var [ts2,nd2] = this.arguments (ts1); // refer to parser method
                    var tmp = this.arguments (ts1); // refer to parser method
                    var ts2=tmp[0], nd2=tmp[1];
                    if (new_count == 0)
                    {
                        //var [tsx,ndx] = callExpressionPrime (ts2,beta,new CallExpr (nd1,nd2));
                        var tmp = callExpressionPrime (ts2,beta,new CallExpr (nd1,nd2));
                        var tsx=tmp[0], ndx=tmp[1];
                    }
                    else
                    {
                        //var [tsx,ndx] = [ts2,new NewExpr (nd1,nd2)];
                        var tsx=ts2, ndx=new NewExpr (nd1,nd2);
                    }
                    break;
                default:
                    if (new_count == 0)
                    {
                        //var [tsx,ndx] = memberExpressionPrime (ts1,beta,nd1);
                        var tmp = memberExpressionPrime (ts1,beta,nd1);
                        var tsx=tmp[0], ndx=tmp[1];
                    }
                    else
                    {
                        //var [tsx,ndx] = [ts1,new NewExpr (nd1,[])];
                        var tsx=ts1, ndx=new NewExpr (nd1,[]);
                    }
                    break;
                }
                break;
            default:
                //var [ts1,nd1] = memberExpression (ts,beta);
                var tmp = memberExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                switch (hd (ts1)) {
                case Token.LeftParen:
                    //var [ts2,nd2] = this.arguments (ts1); // refer to parser method
                    var tmp = this.arguments (ts1); // refer to parser method
                    var ts2=tmp[0], nd2=tmp[1];
                    if( new_count == 0 )
                    {
                       //var [tsx,ndx] = callExpressionPrime (ts2,beta,new CallExpr (nd1,nd2));
                       var tmp = callExpressionPrime (ts2,beta,new CallExpr (nd1,nd2));
                       var tsx=tmp[0], ndx=tmp[1];
                    }
                    else
                    {
                        //var [tsx,ndx] = [ts2,new NewExpr (nd1,nd2)];
                        var tsx=ts2, ndx=new NewExpr (nd1,nd2);
                    }
                    break;
                default:
                    if( new_count == 0 ) 
                    {
                        //var [tsx,ndx] = [ts1,nd1];
                        var tsx=ts1, ndx=nd1;
                    }
                    else 
                    {
                        //var [tsx,ndx] = [ts1,new NewExpr (nd1,[])];
                        var tsx=ts1, ndx=new NewExpr (nd1,[]);
                    }
                    break;
                }
                break;
            }

            Debug.exit("Parser::newExpression ", ndx);
            return [tsx, ndx];
        }

        /*

        LeftHandSideExpression
            NewExpression
            CallExpression

        Refactored:

        LeftHandSideExpression
            NewExpression
            MemberExpression Arguments CallExpressionPrime
            MemberExpression

        */

        function leftHandSideExpression (ts: TokenStream, beta:IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::leftHandSideExpression ", ts);

            switch (hd (ts)) {
            case Token.New:
                //var [ts1,nd1] = newExpression (ts,beta,0);
                var tmp = newExpression (ts,beta,0);
                var ts1=tmp[0], nd1=tmp[1];
                switch (hd (ts1)) {
                case Token.LeftParen:
                    //var [ts2,nd2] = this.arguments (ts1); // refer to parser method
                    var tmp = this.arguments (ts1); // refer to parser method
                    var ts2=tmp[0], nd2=tmp[1];
                    //var [tsx,ndx] = callExpressionPrime (ts2, beta, new CallExpr (nd1,nd2));
                    var tmp = callExpressionPrime (ts2, beta, new CallExpr (nd1,nd2));
                    var tsx=tmp[0], ndx=tmp[1];
                    break;
                default:
                    //var [tsx,ndx] = [ts1,nd1];
                    var tsx=ts1, ndx=nd1;
                    break;
                }
                break;
            default:
                //var [ts1,nd1] = memberExpression (ts,beta);
                var tmp = memberExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                switch (hd (ts1)) {
                case Token.LeftParen:
                    //var [ts2,nd2] = this.arguments (ts1); // refer to parser method
                    var tmp = this.arguments (ts1); // refer to parser method
                    var ts2=tmp[0], nd2=tmp[1];
                    //var [tsx,ndx] = callExpressionPrime (ts2, beta, new CallExpr (nd1,nd2));
                    var tmp = callExpressionPrime (ts2, beta, new CallExpr (nd1,nd2));
                    var tsx=tmp[0], ndx=tmp[1];
                    break;
                default:
                    //var [tsx,ndx] = [ts1,nd1];
                    var tsx=ts1, ndx=nd1;
                    break;
                }
                break;
            }

            Debug.exit("Parser::leftHandSideExpression ", ndx);
            return [tsx, ndx];
        }

        /*

        PostfixExpression(beta)
            LeftHandSideExpression(beta)
            LeftHandSideExpression(beta)  [no line break]  ++
            LeftHandSideExpression(beta)  [no line break]  --

        */

        function postfixExpression (ts: TokenStream, beta:IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::postfixExpression ", ts);

            //var [ts1, nd1] = leftHandSideExpression (ts, beta);
            var tmp = leftHandSideExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            switch (hd (ts1)) {
            case Token.PlusPlus:
                //var [tsx,ndx] = [tl (ts1), new UnaryExpr (postIncrOp,nd1)];
                var tsx=tl (ts1), ndx=new UnaryExpr (Ast.postIncrOp,nd1);
                break;
            case Token.MinusMinus:
                //var [tsx,ndx] = [tl (ts1), new UnaryExpr (postDecrOp,nd1)];
                var tsx=tl (ts1), ndx=new UnaryExpr (Ast.postDecrOp,nd1);
                break;
            default:
                //var [tsx,ndx] = [ts1,nd1];
                var tsx=ts1, ndx=nd1;
                break;
            }

            Debug.exit("Parser::postfixExpression ", tsx);
            return [tsx, ndx];
        }

        /*

        UnaryExpression(beta)
            PostfixExpression(beta)
            delete  PostfixExpression(beta)
            void  UnaryExpression(beta)
            typeof  UnaryExpression(beta)
            ++   PostfixExpression(beta)
            --  PostfixExpression(beta)
            +  UnaryExpression(beta)
            -  UnaryExpression(beta)
            ~  UnaryExpression(beta)
            !  UnaryExpression(beta)
            type  NullableTypeExpression

        */

        function unaryExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::unaryExpression ", ts);

            switch (hd (ts)) {
            case Token.Delete:
                //var [ts1,nd1] = postfixExpression (tl (ts),beta);
                var tmp = postfixExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new UnaryExpr (deleteOp,nd1)];
                var tsx=ts1, ndx=new UnaryExpr (Ast.deleteOp,nd1);
                break;
            case Token.Void:
                //var [ts1,nd1] = unaryExpression (tl (ts),beta);
                var tmp = unaryExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new UnaryExpr (voidOp,nd1)];
                var tsx=ts1, ndx=new UnaryExpr (Ast.voidOp,nd1);
                break;
            case Token.TypeOf:
                //var [ts1,nd1] = unaryExpression (tl (ts),beta);
                var tmp = unaryExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new UnaryExpr (typeOfOp,nd1)];
                var tsx=ts1, ndx=new UnaryExpr (Ast.typeOfOp,nd1);
                break;
            case Token.PlusPlus:
                //var [ts1,nd1] = postfixExpression (tl (ts),beta);
                var tmp = postfixExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new UnaryExpr (preIncrOp,nd1)];
                var tsx=ts1, ndx=new UnaryExpr (Ast.preIncrOp,nd1);
                break;
            case Token.MinusMinus:
                //var [ts1,nd1] = postfixExpression (tl (ts),beta);
                var tmp = postfixExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new UnaryExpr (preDecrOp,nd1)];
                var tsx=ts1, ndx=new UnaryExpr (Ast.preDecrOp,nd1);
                break;
            case Token.Plus:
                //var [ts1,nd1] = unaryExpression (tl (ts),beta);
                var tmp = unaryExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new UnaryExpr (unaryPlusOp,nd1)];
                var tsx=ts1, ndx=new UnaryExpr (Ast.unaryPlusOp,nd1);
                break;
            case Token.Minus:
                //var [ts1,nd1] = unaryExpression (tl (ts),beta);
                var tmp = unaryExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new UnaryExpr (unaryMinusOp,nd1)];
                var tsx=ts1, ndx=new UnaryExpr (Ast.unaryMinusOp,nd1);
                break;
            case Token.BitwiseNot:
                //var [ts1,nd1] = unaryExpression (tl (ts),beta);
                var tmp = unaryExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new UnaryExpr (bitwiseNotOp,nd1)];
                var tsx=ts1, ndx=new UnaryExpr (Ast.bitwiseNotOp,nd1);
                break;
            case Token.Not:
                //var [ts1,nd1] = unaryExpression (tl (ts),beta);
                var tmp = unaryExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new UnaryExpr (logicalNotOp,nd1)];
                var tsx=ts1, ndx=new UnaryExpr (Ast.logicalNotOp,nd1);
                break;
            case Token.Type:
                //var [ts1,nd1] = nullableTypeExpression (tl (ts),beta);
                var tmp = nullableTypeExpression (tl (ts),beta);
                var ts1=tmp[0], nd1=tmp[1];
                //var [tsx,ndx] = [ts1,new TypeExpr (nd1)];
                var tsx=ts1, ndx=new TypeExpr (nd1);
                break;
            default:
                //var [tsx,ndx] = postfixExpression (ts,beta);
                var tmp = postfixExpression (ts,beta);
                var tsx=tmp[0], ndx=tmp[1];
                break;
            }

            Debug.exit("Parser::unaryExpression ", tsx);
            return [tsx,ndx];
        }

        /*

        MultiplicativeExpression
            UnaryExpression
            MultiplicativeExpression  *  UnaryExpression
            MultiplicativeExpression  /  UnaryExpression
            MultiplicativeExpression  %  UnaryExpression

        */

        function multiplicativeExpression (ts: TokenStream, beta:IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::multiplicativeExpression ", ts);

            //var [ts1,nd1] = unaryExpression (ts, beta);
            var tmp = unaryExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];

            /// done:
            var done = false;
            while (true) {

                if (hd (ts1) === Token.BREAK) {
                    var tsx;
                    var csx;
                    //[tsx,csx] = scan.tokenList (scan.div);
                    tmp = scan.tokenList (scan.div);
                    tsx=tmp[0];
                    csx=tmp[1];
                    coordList = csx;
                    ts1 = new TokenStream (tsx);
                }

                switch (hd (ts1)) {
                case Token.Mult:
                    var op = Ast.timesOp;
                    break;
                case Token.Div:
                    var op = Ast.divideOp;
                    break;
                case Token.Remainder:
                    var op = Ast.remainderOp;
                    break;
                default:
                    done = true;
                    break /// done;
                }
                if (done) break;

                //var [ts2, nd2] = unaryExpression (tl (ts1), beta);
                var tmp = unaryExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1];
                ts1 = ts2;
                nd1 = new BinaryExpr (op, nd1, nd2);
            }

            Debug.exit("Parser::multiplicativeExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        AdditiveExpression
            MultiplicativeExpression
            AdditiveExpression + MultiplicativeExpression
            AdditiveExpression - MultiplicativeExpression

        */

        function additiveExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::additiveExpression ", ts);

            //var [ts1, nd1] = multiplicativeExpression (ts, beta);
            var tmp = multiplicativeExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];

            /// done:
            var done = false;
            while (true) {
                switch (hd (ts1)) {
                case Token.Plus:
                    var op = Ast.plusOp;
                    break;
                case Token.Minus:
                    var op = Ast.minusOp;
                    break;
                default:
                    done = true;
                    break /// done;
                }
                if (done) break;

                //var [ts2, nd2] = multiplicativeExpression (tl (ts1), beta);
                var tmp = multiplicativeExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1];
                //[ts1, nd1] = [ts2, new BinaryExpr (op, nd1, nd2)];
                ts1=ts2;
                nd1=new BinaryExpr (op, nd1, nd2);
            }

            Debug.exit("Parser::additiveExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        ShiftExpression
            AdditiveExpression
            ShiftExpression << AdditiveExpression
            ShiftExpression >> AdditiveExpression
            ShiftExpression >>> AdditiveExpression

        */

        function shiftExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::shiftExpression ", ts);

            //var [ts1, nd1] = additiveExpression (ts, beta);
            var tmp = additiveExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            
            var done = false;
            /// done:
            while (true) {
                switch (hd (ts1)) {
                case Token.LeftShift:
                    var op = Ast.leftShiftOp;
                    break;
                case Token.RightShift:
                    var op = Ast.rightShiftOp;
                    break;
                case Token.UnsignedRightShift:
                    var op = Ast.rightShiftUnsignedOp;
                    break;
                default:
                    done = true;
                    break /// done;
                }
                if (done) break;

                //var [ts2, nd2] = additiveExpression (tl (ts1), beta);
                var tmp = additiveExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1];
                //var [ts1, nd1] = [ts2, new BinaryExpr (op, nd1, nd2)];
                var ts1=ts2, nd1=new BinaryExpr (op, nd1, nd2);
            }

            Debug.exit("Parser::shiftExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        RelationalExpression(noIn)
            ShiftExpression(noIn)
            RelationalExpression(noIn) < ShiftExpression(noIn)
            RelationalExpression(noIn) > ShiftExpression(noIn)
            RelationalExpression(noIn) <= ShiftExpression(noIn)
            RelationalExpression(noIn) >= ShiftExpression(noIn)
            RelationalExpression(noIn) instanceof ShiftExpression(noIn)
            RelationalExpression(noIn) is TypeExpression
            RelationalExpression(noIn) to TypeExpression
            RelationalExpression(noIn) cast TypeExpression

        RelationalExpression(allowIn)
            ShiftExpression(allowIn)
            RelationalExpression(allowIn) < ShiftExpression(allowIn)
            RelationalExpression(allowIn) > ShiftExpression(allowIn)
            RelationalExpression(allowIn) <= ShiftExpression(allowIn)
            RelationalExpression(allowIn) >= ShiftExpression(allowIn)
            RelationalExpression(allowIn) in ShiftExpression(allowIn)
            RelationalExpression(allowIn) instanceof ShiftExpression(allowIn)
            RelationalExpression(allowIn) is TypeExpression
            RelationalExpression(allowIn) to TypeExpression
            RelationalExpression(allowIn) cast TypeExpression

        */

        function relationalExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::relationalExpression ", ts);

            //var [ts1, nd1] = shiftExpression (ts, beta);
            var tmp = shiftExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];

            /// done:
            var done = false;
            while (true) {
                switch (hd (ts1)) {
                case Token.LessThan:
                    //var [ts2, nd2] = shiftExpression (tl (ts1), beta);
                    var tmp = shiftExpression (tl (ts1), beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryExpr (Ast.lessOp,nd1,nd2);
                    break;
                case Token.GreaterThan:
                    //var [ts2, nd2] = shiftExpression (tl (ts1), beta);
                    var tmp = shiftExpression (tl (ts1), beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryExpr (Ast.greaterOp,nd1,nd2);
                    break;
                case Token.LessThanOrEqual:
                    //var [ts2, nd2] = shiftExpression (tl (ts1), beta);
                    var tmp = shiftExpression (tl (ts1), beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryExpr (Ast.lessOrEqualOp,nd1,nd2);
                    break;
                case Token.GreaterThanOrEqual:
                    //var [ts2, nd2] = shiftExpression (tl (ts1), beta);
                    var tmp = shiftExpression (tl (ts1), beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryExpr (Ast.greaterOrEqualOp,nd1,nd2);
                    break;
                case Token.In:
                    if (beta == noIn) {
                        done = true;
                        break /// done;
                    }
                    //var [ts2, nd2] = shiftExpression (tl (ts1), beta);
                    var tmp = shiftExpression (tl (ts1), beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryExpr (Ast.inOp,nd1,nd2);
                    break;
                case Token.InstanceOf:
                    //var [ts2, nd2] = shiftExpression (tl (ts1), beta);
                    var tmp = shiftExpression (tl (ts1), beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryExpr (Ast.instanceOfOp,nd1,nd2);
                    break;
                case Token.Is:
                    //var [ts2, nd2] = typeExpression (tl (ts1));
                    var tmp = typeExpression (tl (ts1));
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryTypeExpr (Ast.isOp,nd1,nd2);
                    break;
                case Token.To:
                    //var [ts2, nd2] = typeExpression (tl (ts1));
                    var tmp = typeExpression (tl (ts1));
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryTypeExpr (Ast.toOp,nd1,nd2);
                    break;
                case Token.Cast:
                    //var [ts2, nd2] = typeExpression (tl (ts1));
                    var tmp = typeExpression (tl (ts1));
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryTypeExpr (Ast.castOp,nd1,nd2);
                    break;
                default:
                    done = true;
                    break /// done;
                }
                if (done) break;
                //var [ts1, nd1] = [ts2,nd2];
                var ts1=ts2, nd1=nd2;
            }

            Debug.exit("Parser::equalityExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        EqualityExpression(beta)
            RelationalExpression(beta)
            EqualityExpression(beta) == RelationalExpression(beta)
            EqualityExpression(beta) != RelationalExpression(beta)
            EqualityExpression(beta) === RelationalExpression(beta)
            EqualityExpression(beta) !== RelationalExpression(beta)

        */

        function equalityExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::equalityExpression ", ts);

            //var [ts1, nd1] = relationalExpression (ts, beta);
            var tmp = relationalExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            /// done:
            var done = false;
            while (true) {
                switch (hd (ts1)) {
                case Token.Equal:
                    var op = Ast.equalOp;
                    break;
                case Token.NotEqual:
                    var op = Ast.notEqualOp;
                    break;
                case Token.StrictEqual:
                    var op = Ast.strictEqualOp;
                    break;
                case Token.StrictNotEqual:
                    var op = Ast.strictNotEqualOp;
                    break;
                default:
                    done = true;
                    break /// done;
                }
                if (done) break;

                //var [ts2, nd2] = relationalExpression (tl (ts1), beta);
                var tmp = relationalExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1];
                //var [ts1, nd1] = [ts2, new BinaryExpr (op, nd1, nd2)];
                var ts1=ts2, nd1=new BinaryExpr (op, nd1, nd2);
            }

            Debug.exit("Parser::equalityExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        BitwiseAndExpression(beta)
            EqualityExpression(beta)
            BitwiseAndExpressionr(beta) & EqualityExpression(beta)

        */

        function bitwiseAndExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::bitwiseAndExpression ", ts);

            //var [ts1, nd1] = equalityExpression (ts, beta);
            var tmp = equalityExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            while (hd (ts1) === Token.BitwiseAnd) {
                //var [ts2, nd2] = equalityExpression (tl (ts1), beta);
                var tmp = equalityExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1];
                //var [ts1, nd1] = [ts2, new BinaryExpr (bitwiseAndOp, nd1, nd2)];
                var ts1=ts2, nd1=new BinaryExpr (Ast.bitwiseAndOp, nd1, nd2);
            }

            Debug.exit("Parser::bitwiseAndExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        BitwiseXorExpressionb
            BitwiseAndExpressionb
            BitwiseXorExpressionb ^ BitwiseAndExpressionb

        */

        function bitwiseXorExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::bitwiseXorExpression ", ts);

            //var [ts1, nd1] = bitwiseAndExpression (ts, beta);
            var tmp = bitwiseAndExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            while (hd (ts1) === Token.BitwiseXor) {
                //var [ts2, nd2] = bitwiseAndExpression (tl (ts1), beta);
                var tmp = bitwiseAndExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1];
                //var [ts1, nd1] = [ts2, new BinaryExpr (bitwiseXorOp, nd1, nd2)];
                var ts1=ts2, nd1=new BinaryExpr (Ast.bitwiseXorOp, nd1, nd2);
            }

            Debug.exit("Parser::bitwiseXorExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        BitwiseOrExpression(beta)
            BitwiseXorExpression(beta)
            BitwiseOrExpression(beta) | BitwiseXorExpression(beta)

        */

        function bitwiseOrExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::bitwiseOrExpression ", ts);

            //var [ts1, nd1] = bitwiseXorExpression (ts, beta);
            var tmp = bitwiseXorExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            while (hd (ts1) === Token.BitwiseOr) {
                //var [ts2, nd2] = bitwiseXorExpression (tl (ts1), beta);
                var tmp = bitwiseXorExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1];
                //var [ts1, nd1] = [ts2, new BinaryExpr (bitwiseOrOp, nd1, nd2)];
                var ts1=ts2, nd1=new BinaryExpr (Ast.bitwiseOrOp, nd1, nd2);
            }

            Debug.exit("Parser::bitwiseOrExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        LogicalAndExpression(beta)
            BitwiseOrExpression(beta)
            LogicalAndExpression(beta) && BitwiseOrExpression(beta)

        */

        function logicalAndExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::logicalAndExpression ", ts);

            //var [ts1, nd1] = bitwiseOrExpression (ts, beta);
            var tmp = bitwiseOrExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            while (hd (ts1) === Token.LogicalAnd) {
                //var [ts2, nd2] = bitwiseOrExpression (tl (ts1), beta);
                var tmp = bitwiseOrExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1];
                //var [ts1, nd1] = [ts2, new BinaryExpr (logicalAndOp, nd1, nd2)];
                var ts1=ts2, nd1=new BinaryExpr (Ast.logicalAndOp, nd1, nd2);
            }

            Debug.exit("Parser::logicalAndExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        LogicalXorExpressionb
            LogicalAndExpressionb
            LogicalXorExpressionb ^^ LogicalAndExpressionb

        */

        function logicalXorExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::logicalXorExpression ", ts);

            //var [ts1, nd1] = logicalAndExpression (ts, beta);
            var tmp = logicalAndExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            while (hd (ts1) === Token.LogicalXor) {
                //var [ts2, nd2] = logicalAndExpression (tl (ts1), beta);
                var tmp = logicalAndExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1];
                //var [ts1, nd1] = [ts2, new BinaryExpr (logicalXor, nd1, nd2)];
                var ts1=ts2, nd1=new BinaryExpr (Ast.logicalXorOp, nd1, nd2);
            }

            Debug.exit("Parser::logicalXorExpression ", ts1);
            return [ts1, nd1];
        }

        /*

            LogicalOrExpression(beta)
                LogicalXorExpression(beta)
                LogicalOrExpression(AllowIn) || LogicalXorExpression(beta)

        */

        function logicalOrExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::logicalOrExpression ", ts);

            //var [ts1, nd1] = logicalXorExpression (ts, beta);
            var tmp = logicalXorExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            while (hd (ts1) === Token.LogicalOr) {
                //var [ts2, nd2] = logicalXorExpression (tl (ts1), beta);
                var tmp = logicalXorExpression (tl (ts1), beta);
                var ts2=tmp[0], nd2=tmp[1]
                //var [ts1, nd1] = [ts2, new BinaryExpr (logicalOrOp, nd1, nd2)];
                var ts1=ts2, nd1=new BinaryExpr (Ast.logicalOrOp, nd1, nd2);
            }

            Debug.exit("Parser::logicalOrExpression ", ts1);
            return [ts1, nd1];
        }

        /*

        YieldExpression
            UnaryExpression
            yield  UnaryExpression

        */


        /*

        NonAssignmentExpressiona, b
            LetExpressiona, b
            YieldExpressiona, b
            LogicalOrExpressiona, b
            LogicalOrExpressiona, b  ?  NonAssignmentExpressiona, b  
                                                    :  NonAssignmentExpressiona, b

        */

        function nonAssignmentExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::nonAssignmentExpression ", ts);

            switch (hd (ts)) {
            case Token.Let:
                //var [ts1,nd1] = letExpression (ts,beta);
                var tmp = letExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.Yield:
                //var [ts1,nd1] = yieldExpression (ts,beta);
                var tmp = yieldExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            default:
                //var [ts1,nd1] = logicalOrExpression (ts,beta);
                var tmp = logicalOrExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                switch (hd (ts1)) {
                case Token.QuestionMark:
                    //var [ts2,nd2] = nonAssignmentExpression (tl (ts1),beta);
                    var tmp = nonAssignmentExpression (tl (ts1),beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    ts2 = eat (ts2,Token.Colon);
                    //var [ts3,nd3] = nonAssignmentExpression (ts2,beta);
                    var tmp = nonAssignmentExpression (ts2,beta);
                    var ts3=tmp[0], nd3=tmp[1];
                    //var [ts1,nd1] = [ts3, new TernaryExpr (nd1,nd2,nd3)];
                    var ts1=ts3, nd1=new TernaryExpr (nd1,nd2,nd3)
                    break;
                default:
                    break;
                }
                break;
            }

            Debug.exit("Parser::nonAssignmentExpression ", ts1);
            return [ts1,nd1];
        }

        /*

        ConditionalExpression(beta)
            LetExpression(beta)
            YieldExpression(beta)
            LogicalOrExpression(beta)
            LogicalOrExpression(beta)  ?  AssignmentExpression(beta)
                                       :  AssignmentExpression(beta)

        */

        function conditionalExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::conditionalExpression ", ts);

            switch (hd (ts)) {
            case Token.Let:
                var tmp = letExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.Yield:
                var tmp = yieldExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            default:
                var tmp = logicalOrExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                switch (hd (ts1)) {
                case Token.QuestionMark:
                    var tmp = assignmentExpression (tl (ts1),beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    ts2 = eat (ts2,Token.Colon);
                    var tmp = assignmentExpression (ts2,beta);
                    var ts3=tmp[0], nd3=tmp[1];
                    //var [ts1,nd1] = [ts3, new TernaryExpr (nd1,nd2,nd3)];
                    var ts1=ts3, nd1=new TernaryExpr (nd1,nd2,nd3);
                    break;
                default:
                    break;
                }
            }

            Debug.exit("Parser::conditionalExpression ", ts1);
            return [ts1,nd1];
        }

        /*

        AssignmentExpression(beta)
            ConditionalExpression(beta)
            Pattern(beta, allowExpr)  =  AssignmentExpression(beta)
            SimplePattern(beta, allowExpr)  CompoundAssignmentOperator  AssignmentExpression(beta)

        */

        function assignmentExpression (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::assignmentExpression ", ts);

            var tmp = conditionalExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            switch (hd (ts1)) {
            case Token.Assign:
                //var [ts1,nd1] = [tl (ts1), patternFromExpr (nd1)];
                var ts1=tl (ts1), nd1=patternFromExpr (nd1);
                var tmp = assignmentExpression (ts1,beta);
                var ts2=tmp[0], nd2=tmp[1];
                var tmp = desugarAssignmentPattern (nd1,Ast.anyType,nd2,Ast.assignOp);
                var fxtrs=tmp[0],expr=tmp[1],head=tmp[2];
                break;
            default:
                var op = undefined;
                switch(hd (ts1)) {
                case Token.PlusAssign:
                    op = Ast.plusOp;
                    break;
                case Token.MinusAssign:
                    op = Ast.minusOp;
                    break;
                case Token.MultAssign:
                    op = Ast.timesOp;
                    break;
                case Token.DivAssign:
                    op = Ast.divideOp;
                    break;
                case Token.RemainderAssign:
                    op = Ast.remainderOp;
                    break;
                case Token.LogicalAndAssign:
                    op = Ast.logicalAndOp;
                    break;
                case Token.BitwiseAndAssign:
                    op = Ast.bitwiseAndOp;
                    break;
                case Token.LogicalOrAssign:
                    op = Ast.logicalOrOp;
                    break;
                case Token.BitwiseXorAssign:
                    op = Ast.bitwiseXorOp;
                    break;
                case Token.BitwiseOrAssign:
                    op = Ast.bitwiseOrOp;
                    break;
                case Token.LeftShiftAssign:
                    op = Ast.leftShiftOp;
                    break;
                case Token.RightShiftAssign:
                    op = Ast.rightShiftOp;
                    break;
                case Token.UnsignedRightShiftAssign:
                    op = Ast.rightShiftUnsignedOp;
                    break;
                }
                if( op != undefined )
                {
                    var nd_orig = nd1;
                    //var [ts1,nd1] = [tl (ts1), patternFromExpr(nd1)];
                    var ts1=tl (ts1), nd1=patternFromExpr(nd1);
                    var tmp = assignmentExpression(ts1, beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2 = new BinaryExpr(op, nd_orig, nd2);
                    var tmp = desugarAssignmentPattern (nd1,Ast.anyType,nd2,Ast.assignOp);
	                var fxtrs=tmp[0],expr=tmp[1],head=tmp[2];
                }
                else
                {
                    var ts2=ts1, expr=nd1;
                }
                break;
            }

            Debug.exit("Parser::assignmentExpression ", ts1);
            return [ts2,expr];

            // expression to pattern converters

            function patternFromExpr (e: IAstExpr) {
            	var x = e;
            	if (x is LiteralExpr) {
            		var y = (e as LiteralExpr).literal;
            		if (y is LiteralArray) {
                        var p = arrayPatternFromLiteral (y);
                    } else if (y is LiteralObject) {
                        var p = objectPatternFromLiteral (y);
                    } else {
                        throw "invalid lhs expr " + e;
                    }
                } else if (x is LexicalRef) {
                    var p = new SimplePattern (e);
                } else if (x is ObjectRef) {
                    var p = new SimplePattern (e);
                } else {
                    throw "error patternFromExpr, unhandled expression kind " + e;
                }
                return p;
            }

            function arrayPatternFromLiteral (nd: IAstLiteral)
                : IParserPattern
            {
                Debug.enter("Parser::arrayPatternFromLiteral ", ts);
                
                var nd1 = elementListPatternFromLiteral ((nd as LiteralArray).exprs);
                
                Debug.exit("Parser::arrayPatternFromLiteral ", ts1);
                return new ArrayPattern (nd1);
            }

            function elementListPatternFromLiteral (nd: Array)
                : Array
            {
                Debug.enter("Parser::elementListPatternFromLiteral ", nd);
                
                var nd1 = [];
                
                for (var i=0; i<nd.length; ++i) {
                    var ndx = patternFromExpr (nd[i]);
                    nd1.push (ndx);
                }
                
                Debug.exit("Parser::elementListPatternFromLiteral ", nd1);
                return nd1;
            }
                    
            function objectPatternFromLiteral (l: IAstLiteral)
                : IParserPattern
            {
                Debug.enter("Parser::objectPatternFromLiteral ", l);
                
                var x=l;
                if (x is LiteralObject) {
                	var nd = x as LiteralObject;
                    var p = fieldListPatternFromLiteral (nd.fields);
                } else {
                    throw "error objectPatternFromLiteral " + nd;
                }
                        
                Debug.exit("Parser::objectPatternFromLiteral ", p);
                return new ObjectPattern (p);
            }
                    
            function fieldListPatternFromLiteral (nd: Array)
                : Array
            {
                Debug.enter("Parser::fieldListPatternFromLiteral ", nd);
                
                var nd1 = [];
                
                for (var i=0; i<nd.length; ++i) {
                    var ndx = fieldPatternFromLiteral (nd[i]);
                    nd1.push (ndx);
                }
                
                Debug.exit("Parser::fieldListPatternFromLiteral ", nd1);
                return nd1;
            }
                    
            function fieldPatternFromLiteral (nd: LiteralField)
                : FieldPattern
            {
                Debug.enter("Parser::fieldPatternFromLiteral ", ts);
                
                var nd1 = nd.ident;
                var nd2 = patternFromExpr (nd.expr);
                
                Debug.exit("Parser::fieldPatternFromLiteral ", ts2);
                return new FieldPattern (nd1,nd2);
            }
        }

        /*

        ListExpression(b)
            AssignmentExpression(b)
            ListExpression(b)  ,  AssignmentExpression(b)

        right recursive:

        ListExpression(b)
            AssignmentExpression(b) ListExpressionPrime(b)

        ListExpressionPrime(b)
            empty
            , AssignmentExpression(b) ListExpressionPrime(b)

        */

        function listExpression (ts: TokenStream, beta: IBeta )
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::listExpression ", ts);

            function listExpressionPrime (ts: TokenStream )
                : Array //[TokenStream, IAstExpr]
            {
                Debug.enter("Parser::listExpressionPrime ", ts);
        
                switch (hd (ts)) {
                case Token.Comma:
                    var tmp = assignmentExpression (tl (ts), beta);
	                var ts1=tmp[0], nd1=tmp[1];
                    var tmp = listExpressionPrime (ts1);
                    var ts2=tmp[0], nd2=tmp[1];
                    nd2.unshift (nd1);
                    break;
                default:
                    var ts2=ts, nd2=[];
                    break;
                }

                Debug.exit("Parser::listExpressionPrime ", ts2);
                return [ts2,nd2];
            }

            var tmp = assignmentExpression (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = listExpressionPrime (ts1);
            var ts2=tmp[0], nd2=tmp[1];
            // print("nd2.length=",nd2.length);
            nd2.unshift (nd1);
            // print("nd2.length=",nd2.length);

            Debug.exit("Parser::listExpression ", ts2);
            return [ts2,new ListExpr (nd2)];
        }

//        /*
//
//        LetExpressionb
//            let  (  LetBindingList  )  AssignmentExpressionb
//
//        LetBindingList
//            empty
//            NonemptyLetBindingList
//
//        NonemptyLetBindingList
//            VariableBinding
//            VariableBinding , NonemptyLetBindingList
//
//        */
//
//        function parseLetExpression(mode)
//        {
//            Debug.enter("parseLetExpression")
//
//            var prologue = <Prologue/>
//            match(let_token)
//            match(leftparen_token)
//            if( lookahead(rightparen_token) )
//            {
//                var first = <></>
//            }
//            else
//            {
//                var first = <></>
//                first += parseVariableBinding(<Attributes><Let/></Attributes>,var_token,allowIn_mode,prologue)
//                while( lookahead(comma_token) )
//                {
//                    match(comma_token)
//                    first += parseVariableBinding(<Attributes><Let/></Attributes>,var_token,allowIn_mode,prologue)
//                }
//                prologue.* += first
//            }
//            match(rightparen_token)
//            var second = parseAssignmentExpression(mode)
//            var result = <LetExpression>{prologue}{second}</LetExpression>
//
//            Debug.exit("parseLetExpression",result)
//            return result
//        }
//
//        /*
//
//        YieldExpressionb
//            yield  AssignmentExpressionb
//
//        */
//
///*
//        function parseYieldExpression(mode)
//        {
//            Debug.enter("parseYieldExpression")
//
//            Debug.exit("parseYieldExpression",result)
//            return result
//        }
//*/

        // PATTERNS

        /*

          Pattern(beta,gamma)
              SimplePattern(beta,gamma)
              ObjectPattern(gamma)
              ArrayPattern(gamma)

        */

        function pattern (ts: TokenStream, beta: IBeta, gamma: IGamma)
            : Array //[TokenStream, IParserPattern]
        {
            Debug.enter("Parser::pattern", ts);

            switch (hd (ts)) {
            case Token.LeftBrace:
                var tmp = objectPattern (ts, gamma);
                var ts1=tmp[0], nd1=tmp[1];
               break;
            case Token.LeftBracket:
                var tmp = arrayPattern (ts, gamma);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            default:
                var tmp = simplePattern (ts, beta, gamma);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            }

            Debug.exit("Parser::pattern ", ts1);
            return [ts1,nd1];
        }

        /*

          SimplePattern(beta, noExpr)
              Identifier

          SimplePattern(beta, allowExpr)
              LeftHandSideExpression(beta)

          */

        function simplePattern (ts: TokenStream, beta: IBeta, gamma: IGamma)
            : Array //[TokenStream, IParserPattern]
        {
            Debug.enter("Parser::simplePattern", ts);

            switch (gamma) {
            case noExpr:
                var tmp = identifier (ts);
                var ts1=tmp[0], nd1=tmp[1];
                var tsx=ts1, ndx=new IdentifierPattern (nd1);
                break;
            case allowExpr:
                var tmp = leftHandSideExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                var tsx=ts1, ndx=new SimplePattern (nd1);
                break;
            }

            Debug.exit("Parser::simplePattern", tsx);
            return [tsx,ndx];
        }

        /*

        ArrayPattern(gamma)
            [  ElementListPattern(gamma)  ]
        
        */

        function arrayPattern (ts: TokenStream, gamma: IGamma)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::arrayPattern ", ts);

            ts = eat (ts,Token.LeftBracket);
            var tmp = elementListPattern (ts,gamma);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.RightBracket);

            Debug.exit("Parser::arrayPattern ", ts1);
            return [ts1, new ArrayPattern (nd1)];
        }

        /*

        ElementListPattern(gamma)
            empty
            LiteralElementPattern
            ,  ElementListPattern
             LiteralElementPattern  ,  ElementListPattern

        LiteralElementPattern
            Pattern(allowColon,allowIn,gamma)

        */

        function elementListPattern (ts: TokenStream, gamma:IGamma)
            : Array //[TokenStream, Array]
        {
            Debug.enter("Parser::elementListPattern ", ts);

            var nd1 = [];

            if (hd (ts) !== Token.RightBracket) 
            {
                switch (hd (ts)) {
                case Token.Comma:
                    //var [ts1,ndx] = [tl (ts),new LiteralExpr (new LiteralUndefined)];
                    var ts1=tl (ts), ndx=new LiteralExpr (new LiteralUndefined);
                    break;
                default:
                    var tmp = pattern (ts,allowIn,gamma);
                    var ts1=tmp[0], ndx=tmp[1];
                    break;
                }
                nd1.push (ndx);
                while (hd (ts1) === Token.Comma) {
                    ts1 = eat (ts1,Token.Comma);
                    switch (hd (ts1)) {
                    case Token.Comma:
                        var tmp = [ts1,new LiteralExpr (new LiteralUndefined)];
                        var ts1=tmp[0], ndx=tmp[1];
                        break;
                    default:
                        var tmp = pattern (ts1,allowIn,gamma);
                        var ts1=tmp[0], ndx=tmp[1];
                        break;
                    }
                    nd1.push (ndx);
                }
            }

            Debug.exit("Parser::elementListPattern ", ts1);
            return [ts1, nd1];
        }

        /*

        ObjectPattern(gamma)
            [  FieldListPattern(gamma)  ]
        
        */

        function objectPattern (ts: TokenStream, gamma: IGamma)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::objectPattern ", ts);

            ts = eat (ts,Token.LeftBrace);
            var tmp = fieldListPattern (ts,gamma);
             var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.RightBrace);

            Debug.exit("Parser::objectPattern ", ts1);
            return [ts1, new ObjectPattern (nd1)];
        }

        /*

        FieldListPattern(gamma)
            empty
            FieldPattern
            FieldPattern  ,  FieldListPattern

        FieldPattern
            FieldName
            FieldName  :  Pattern(allowColon,allowIn,gamma)

        */

        function fieldListPattern (ts: TokenStream, gamma:IGamma)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::fieldListPattern ", ts);

            var nd1 = [];

            if (hd (ts) !== Token.RightBrace) 
            {
                var tmp = fieldPattern (ts,gamma);
                var ts1=tmp[0], ndx=tmp[1];
                nd1.push (ndx);
                while (hd (ts1) === Token.Comma) {
                    ts1 = eat (ts1,Token.Comma);
                    var tmp = fieldPattern (ts1,gamma);
                    var ts1=tmp[0], ndx=tmp[1];
                    nd1.push (ndx);
                }
            }

            Debug.exit("Parser::fieldListPattern ", ts1);
            return [ts1, nd1];
        }

        function fieldPattern (ts: TokenStream, gamma:IGamma)
            : Array //[TokenStream, FieldPattern]
        {
            Debug.enter("Parser::fieldPattern ", ts);

            var tmp = fieldName (ts);
            var ts1=tmp[0], nd1=tmp[1];
            switch (hd (ts1)) {
            case Token.Colon:
                var tmp = pattern (tl (ts1),allowIn,gamma);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            default:
            	var x = nd1;
            	if (x is Identifier) {
                    //var [ts2,nd2] = [ts1, new IdentifierPattern (nd1.ident)];
                    var ts2=ts1, nd2=new IdentifierPattern (nd1.ident);
                } else {
                    throw "unsupported fieldPattern " + nd1;
                }
                break;
            }

            Debug.exit("Parser::fieldPattern ", ts2);
            return [ts2, new FieldPattern (nd1,nd2)];
        }

        /*

          TypedIdentifier(beta)
              SimplePattern(beta, noExpr)
              SimplePattern(beta, noExpr)  :  NullableTypeExpression

          TypedPattern(beta)
              Pattern(beta, noExpr)
              Pattern(beta, noExpr)  :  NullableTypeExpression

        */

        function typedPattern (ts: TokenStream, beta: IBeta)
            : Array //[TokenStream, [IParserPattern,IAstTypeExpr]]
        {
            Debug.enter("Parser::typedPattern ", ts);

            var tmp = pattern (ts,beta,noExpr);
            var ts1=tmp[0], nd1=tmp[1];
            switch (hd (ts1)) {
            case Token.Colon:
                var tmp = nullableTypeExpression (tl (ts1));
                var ts2=tmp[0], nd2=tmp[1];
                break;
            default:
                //var [ts2,nd2] = [ts1,Ast.anyType];
                var ts2=ts1, nd2=Ast.anyType;
                break;
            }

            Debug.exit("Parser::typedPattern ", ts2);
            return [ts2,[nd1,nd2]];
        }

        // TYPE EXPRESSIONS

        /*

        NullableTypeExpression
            TypeExpression
            TypeExpression  ?
            TypeExpression  !

        */

        function nullableTypeExpression (ts: TokenStream, junk:*=null)
            : Array //[TokenStream, IAstTypeExpr]
        {
            Debug.enter("Parser::nullableTypeExpression ", ts);

            var tmp = typeExpression (ts);
            var ts1=tmp[0], nd1=tmp[1];
            switch (hd (ts1)) {
            case Token.QuestionMark:
                //var [ts1,nd1] = [tl (ts1), new NullableType (nd1,true)];
                var ts1=tl (ts1), nd1=new NullableType (nd1,true);
                break;
            case Token.Not:
                //var [ts1,nd1] = [tl (ts1), new NullableType (nd1,false)];
                var ts1=tl (ts1), nd1=new NullableType (nd1,false);
                break;
            default:
                // do nothing
                break;
            }

            Debug.exit("Parser::nullableTypeExpression ", ts1);
            return [ts1,nd1];
        }

        /*

        TypeExpression
            null
            undefined
            FunctionType
            UnionType
            RecordType
            ArrayType
            PrimaryName

        */

        function typeExpression (ts: TokenStream)
            : Array //[TokenStream, IAstTypeExpr]
        {
            Debug.enter("Parser::typeExpression ", ts);

            switch (hd (ts)) {
            case Token.Mult:
                var ts1=tl (ts),nd1= Ast.anyType;
                break;
            case Token.Null:
                var ts1=tl (ts),nd1= Ast.nullType;
                break;
            case Token.Undefined:
                var ts1=tl (ts),nd1= Ast.undefinedType;
                break;
            case Token.Function:
                var tmp = functionType (ts);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.LeftParen:
                var tmp = unionType (ts);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.LeftBrace:
                var tmp = objectType (ts);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.LeftBracket:
                var tmp = arrayType (ts);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            default:
                var tmp = primaryName (ts);
                var ts1=tmp[0], nd1=tmp[1];
                nd1 = new TypeName (nd1);
                break;
            }

            Debug.exit("Parser::typeExpression ", ts1);
            return [ts1,nd1];
        }

        /*

        UnionType
            (  TypeExpressionList  )

        */

        function unionType (ts: TokenStream)
            : Array //[TokenStream, IAstTypeExpr]
        {
            Debug.enter("Parser::unionType ", ts);

            ts = eat (ts,Token.LeftParen);
            var tmp = typeExpressionList (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.RightParen);

            Debug.exit("Parser::unionType ", ts1);
            return [ts1,new UnionType (nd1)];
        }

        /*

        ObjectType
            {  FieldTypeTypeList  }

        */

        function objectType (ts: TokenStream)
            : Array //[TokenStream, IAstTypeExpr]
        {
            Debug.enter("Parser::objectType ", ts);

            ts = eat (ts,Token.LeftBrace);
            var tmp = fieldTypeList (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.RightBrace);

            Debug.exit("Parser::objectType ", ts1);
            return [ts1,new ObjectType (nd1)];
        }

        /*

        FieldTypeList
            empty
            NonemptyFieldTypeList

        NonemptyFieldTypeList
            FieldType
            FieldType  ,  NonemptyFieldTypeList

        */

        function fieldTypeList (ts: TokenStream)
            //            : [TokenStream, [FIELD_TYPE]]
        {
            Debug.enter("Parser::fieldTypeList ", ts);

            var nd1 = [];

            if (hd (ts) !== Token.RightBrace) 
            {
                var tmp = fieldType (ts);
                var ts1=tmp[0], ndx=tmp[1];
                nd1.push (ndx);
                while (hd (ts1) === Token.Comma) {
                    var tmp = fieldType (tl (ts1));
                    var ts1=tmp[0], ndx=tmp[1];
                    nd1.push (ndx);
                }
            }

            Debug.exit("Parser::fieldTypeList ", ts1);
            return [ts1,nd1];
        }

        function fieldType (ts: TokenStream)
            : Array //[TokenStream, FIELD_TYPE]
        {
            Debug.enter("Parser::fieldType");

            var tmp = fieldName (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.Colon);
            var tmp = nullableTypeExpression (ts1);
            var ts2=tmp[0], nd2=tmp[1];

            Debug.exit("Parser::fieldType");
            return [ts2, new FieldType (nd1,nd2)];
        }

        /*

        ArrayType
            [  ElementTypeList  ]

        ElementTypeList
            empty
            NullableTypeExpression
            ,  ElementTypeList
            NullableTypeExpression  ,  ElementTypeList

        */

        function arrayType (ts: TokenStream)
            : Array //[TokenStream, IAstTypeExpr]
        {
            Debug.enter("Parser::arrayType ", ts);

            ts = eat (ts,Token.LeftBracket);
            var tmp = elementTypeList (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.RightBracket);

            Debug.exit("Parser::arrayType ", ts1);
            return [ts1,new ArrayType (nd1)];
        }

        function elementTypeList (ts: TokenStream)
            //            : [TokenStream, [ELEMENT_TYPE]]
        {
            Debug.enter("Parser::elementTypeList ", ts);

            var nd1 = [];

            if (hd (ts) !== Token.RightBracket) 
            {
                switch (hd (ts)) {
                case Token.Comma:
                    var tmp = [tl (ts),new LiteralExpr (new LiteralUndefined)];
                    var ts1=tmp[0], ndx=tmp[1];
                    break;
                default:
                    var tmp = nullableTypeExpression (ts);
                    var ts1=tmp[0], ndx=tmp[1];
                    break;
                }
                nd1.push (ndx);
                while (hd (ts1) === Token.Comma) {
                    ts1 = eat (ts1,Token.Comma);
                    switch (hd (ts1)) {
                    case Token.Comma:
                        var tmp = [ts1,new LiteralExpr (new LiteralUndefined)];
                        var ts1=tmp[0], ndx=tmp[1];
                        break;
                    default:
                        var tmp = nullableTypeExpression (ts1);
                        var ts1=tmp[0], ndx=tmp[1];
                        break;
                    }
                    nd1.push (ndx);
                }
            }

            Debug.exit("Parser::elementTypeList ", ts1);
            return [ts1,nd1];
        }

        /*

        TypeExpressionList
            NullableTypeExpression
            TypeExpressionList  ,  NullableTypeExpression

        refactored

        TypeExpressionList
            NullableTypeExpression  TypeExpressionListPrime

        TypeExpressionListPrime
            empty
            ,  NullableTypeExpression  TypeExpressionListPrime

        */

        function typeExpressionList (ts: TokenStream)
            //            : [TokenStream, [IAstTypeExpr]]
        {
            Debug.enter("Parser::typeExpressionList ", ts);

            var nd1 = [];
            var tmp = nullableTypeExpression (ts);
            var ts1=tmp[0], ndx=tmp[1];
            nd1.push (ndx);
            while (hd (ts1) === Token.Comma) {
                var tmp = nullableTypeExpression (tl (ts1));
                var ts1=tmp[0], ndx=tmp[1];
                nd1.push (ndx);
            }

            Debug.exit("Parser::typeExpressionList ", ts1);
            return [ts1,nd1];
        }

        // STATEMENTS

        /*

        Statement(tau, omega)
            BlockStatement(tau)
            BreakStatement Semicolon(omega)
            ContinueStatement Semicolon(omega)
            DefaultXMLNamespaceStatement Semicolon(omega)
            DoStatement Semicolon(omega)
            ExpressionStatement Semicolon(omega)
            ForStatement(omega)
            IfStatement(omega)
            LabeledStatement(omega)
            LetStatement(omega)
            ReturnStatement Semicolon(omega)
            SwitchStatement
            ThrowStatement Semicolon(omega)
            TryStatement
            WhileStatement(omega)
            WithStatement(omega)

        */

        function statement (ts: TokenStream, tau: ITau, omega: IOmega)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::statement ", ts);

            switch (hd(ts)) {
            case Token.If:
                var tmp = ifStatement (ts,omega);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            case Token.While:
                var tmp = whileStatement (ts,omega);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            case Token.For:
                var tmp = forStatement (ts,omega);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            case Token.Return:
                var tmp = returnStatement (ts);
                var ts1=tmp[0], nd1=tmp[1];
                var ts2=semicolon (ts1,omega),nd2=nd1;
                break;
            case Token.Break:
                var tmp = breakStatement (ts);
                var ts1=tmp[0], nd1=tmp[1];
                var ts2=semicolon (ts1,omega),nd2=nd1;
                break;
            case Token.Continue:
                var tmp = continueStatement (ts);
                var ts1=tmp[0], nd1=tmp[1];
                var ts2=semicolon (ts1,omega),nd2=nd1;
                break;
            case Token.LeftBrace:
                var tmp = block (ts, tau);
                var ts1=tmp[0], nd1=tmp[1];
                var ts2=ts1,nd2=new BlockStmt (nd1);
                break;
            case Token.Switch:
                switch (hd2 (ts)) {
                case Token.Type:
                    var tmp = switchTypeStatement (ts);
                    var ts2=tmp[0], nd2=tmp[1];
                    break;
                default:
                    var tmp = switchStatement (ts);
                    var ts2=tmp[0], nd2=tmp[1];
                    break;
                }
                break;
            case Token.Throw:
                var tmp = throwStatement (ts);
                var ts1=tmp[0], nd1=tmp[1];
                var ts2=semicolon (ts1,omega),nd2=nd1;
                break;
            case Token.Try:
                var tmp = tryStatement (ts);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            default:
                var tmp = expressionStatement (ts);
                var ts1=tmp[0], nd1=tmp[1];
                var ts2=semicolon (ts1,omega),nd2=nd1;
                break;
            }

            Debug.exit("Parser::statement ", ts2);
            return [ts2,nd2];
        }

        function substatement (ts: TokenStream, omega: IOmega)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::substatement ", ts);

            switch (hd(ts)) {
            case Token.SemiColon:
                var ts1=tl (ts),nd1= new EmptyStmt;
                break;
            default:
                var tmp = statement (ts,localBlk,omega);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            }

            Debug.exit("Parser::substatement ", ts1);
            return [ts1,nd1];
        }

        var logicalLn = 0;
        function countLn () {
            ++logicalLn;
        }

        function printLn (ts:TokenStream) {
            Debug.enter("printLn ",ts.n/4);
            if (coordList.length <= ts.n/4) {
                //print("line eos");
            }
            else {
                var coord = coordList[ts.n/4];
                //print ("ln ",coord[0]+1," ",logicalLn);
                //print ("ln "+(coord[0]+1));
            }
            Debug.exit("printLn");
        }

        function newline (ts: TokenStream)
            : Boolean
        {
            var offset = ts.n/4;

            if (offset == 0)
                return true;  // first token, so follows newline, but whose asking?

            //print ("ts.ts.position",ts.ts.position);
            //print ("offset ",offset);
            //print ("coordList",coordList);
            //print ("coordList.length",coordList.length);
            var coord = coordList[offset];
            var prevCoord = coordList[offset-1];
            //print("coord=",coord);
            //print("prevCoord=",prevCoord);

            if(coord[0] != prevCoord[0]) // do line coords match?
                return true;
            else 
                return false;
        }

        function semicolon (ts: TokenStream, omega: IOmega)
            : TokenStream //[TokenStream]
        {
            Debug.enter("Parser::semicolon ", ts);

            switch (omega) {
            case fullStmt:
                switch (hd (ts)) {
                case Token.SemiColon:
                    // print ("semicolon found");
                    var ts1 = tl (ts);
                    break;
                case Token.EOS:
                case Token.RightBrace:
                    var ts1 = ts;
                    break;
                default:
                    if (newline (ts)) { 
                        var ts1=ts; 
                        //print ("inserting semicolon") 
                    }
                    else { 
                        throw "** error: expecting semicolon" 
                    }
                    break;
                }
                break;
            case abbrevStmt:  // Abbrev, ShortIf
                //print("abbrevStmt");
                switch (hd (ts)) {
                case Token.SemiColon:
                    var ts1 = tl (ts);
                    break;
                default:
                    var ts1 = ts;
                    break;
                }
                break;
            default:
                throw "unhandled statement mode";
            }

            Debug.exit("Parser::semicolon ", ts1);
            return ts1;
        }

        function expressionStatement (ts: TokenStream)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::expressionStatement ", ts);

            var tmp = listExpression (ts,allowIn);
            var ts1=tmp[0], nd1=tmp[1];

            Debug.exit("Parser::expressionStatement ", ts1);
            return [ts1, new ExprStmt (nd1)];
        }

        function returnStatement (ts: TokenStream)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::returnStatement ", ts);

            ts = eat (ts, Token.Return);

            switch (hd (ts)) {
            case Token.SemiColon:
            case Token.RightBrace:
                var ts1=ts,nd1=null;
                break;
            default:
                if (newline(ts)) {
                    var ts1=ts,nd1=null;
                }
                else {
                    var tmp = listExpression (ts,allowIn);
	                var ts1=tmp[0], nd1=tmp[1];
                }
                break;
            }

            Debug.exit("Parser::returnStatement ", ts1);
            return [ts1, new ReturnStmt (nd1)];
        }

        function breakStatement (ts: TokenStream)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::breakStatement ", ts);

            ts = eat (ts, Token.Break);
            switch (hd (ts)) {
            case Token.SemiColon:
                var ts1=tl (ts),nd1=null;
                break;
            case Token.RightBrace:
                var ts1=ts,nd1=null;
                break;
            default:
                if (newline(ts)) {
                    var ts1=ts,nd1=null;
                }
                else {
                    var tmp = identifier (ts);
	                var ts1=tmp[0], nd1=tmp[1];
                } 
                break;
            }

            Debug.exit("Parser::breakStatement ", ts1);
            return [ts1, new BreakStmt (nd1)];
        }

        function continueStatement (ts: TokenStream)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::continueStatement ", ts);

            ts = eat (ts, Token.Continue);
            switch (hd (ts)) {
            case Token.SemiColon:
                var ts1=tl (ts),nd1=null;
                break;
            case Token.RightBrace:
                var ts1=ts,nd1=null;
                break;
            default:
                if (newline(ts)) {
                    var ts1=ts,nd1=null;
                }
                else {
                    var tmp = identifier (ts);
	                var ts1=tmp[0], nd1=tmp[1];
                } 
                break;
            }

            Debug.exit("Parser::continueStatement ", ts1);
            return [ts1, new ContinueStmt (nd1)];
        }

        function ifStatement (ts: TokenStream, omega)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::ifStatement ", ts);

            ts = eat (ts,Token.If);
            var tmp = parenListExpression (ts);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = substatement (ts1, omega);
            var ts2=tmp[0], nd2=tmp[1];
            switch (hd (ts2)) {
            case Token.Else:
                var tmp = substatement (tl (ts2), omega);
                var ts3=tmp[0], nd3=tmp[1];
                break;
            default:
                var ts3=ts2,nd3=null;
                break;
            }

            Debug.exit("Parser::ifStatement ", ts3);
            return [ts3, new IfStmt (nd1,nd2,nd3)];
        }

        /*

        WhileStatement(omega)
            while ParenListExpression Substatement(omega)

        */

        function whileStatement (ts: TokenStream, omega)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::whileStatement ", ts);

            ts = eat (ts,Token.While);
            var tmp = parenListExpression (ts);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = substatement (ts1, omega); 
            var ts2=tmp[0], nd2=tmp[1];
            var labels = [];
 
            Debug.exit("Parser::whileStatement ", ts2);
            return [ts2, new WhileStmt (nd1,nd2,labels)];
        }

        /*

            ForStatement(omega)
                for  (  ForInitialiser  ;  OptionalExpression  ;  OptionalExpression  )  Substatement(omega)
                for  (  ForInBinding  in  ListExpression(allowColon, allowIn)  )  Substatement(omega)
                for  each  ( ForInBinding  in  ListExpression(allowColon, allowIn)  )  Substatement(omega)
            
        */

        function forStatement (ts: TokenStream, omega: IOmega)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::forStatement ", ts);

            cx.enterLetBlock ();

			var stmt:IAstStmt;

            ts = eat (ts,Token.For);
            if (hd(ts)==Token.Each) {
            	throw "For each loops not supported yet";
            } else {
	            ts = eat (ts,Token.LeftParen);
	            var tmp = forInitialiser (ts);
	            var ts1=tmp[0], nd1=tmp[1];
	            if (hd(ts1)==Token.In) {
	            	ts1 = eat(ts1,Token.In);
	            	var tmp = listExpression(ts1, allowIn);
	            	var ts2=tmp[0], nd2=tmp[1];
		            ts2 = eat (ts2,Token.RightParen);
		            var tmp = substatement (ts2, omega); 
		            var ts4=tmp[0], nd4=tmp[1];
		            var labels = [];

		            var head = cx.exitLetBlock ();
		            
	            	stmt = new ForInStmt(head, nd1, nd2, nd4,labels);
		        } else {
		            ts1 = eat (ts1,Token.SemiColon);
		            var tmp = optionalExpression (ts1);
		            var ts2=tmp[0], nd2=tmp[1];
		            ts2 = eat (ts2,Token.SemiColon);
		            var tmp = optionalExpression (ts2);
		            var ts3=tmp[0], nd3=tmp[1];
		            ts3 = eat (ts3,Token.RightParen);
		            var tmp = substatement (ts3, omega); 
		            var ts4=tmp[0], nd4=tmp[1];
		            var labels = [];
		
		            var head = cx.exitLetBlock ();
		            
		            stmt = new ForStmt (head,nd1,nd2,nd3,nd4,labels) 
		        }
	        }
 
            Debug.exit("Parser::forStatement ", ts4);
            return [ts4, stmt];
        }

        /*

            ForInitialiser
                empty
                ListExpression(allowColon, noIn)
                VariableDefinition(noIn)
                
            ForInBinding
                Pattern(allowColon, noIn, allowExpr)
                VariableDefinitionKind VariableBinding(noIn)
            
        */

        function forInitialiser (ts: TokenStream)
            : Array //[TokenStream, IAstExpr?]
        {
            Debug.enter("Parser::forInitialiser ", ts);

            switch (hd (ts)) {
            case Token.SemiColon:
                var ts1=ts,nd1=null;
                break;
            case Token.Const:
            case Token.Let:
            case Token.Var:
                var tmp = variableDefinition (ts,allowIn,localBlk,cx.pragmas.defaultNamespace,false,false); // XXX was noIn
                var ts1=tmp[0], nd1=tmp[1];
                //assert (nd1.length==1);
                if (nd1[0] is ExprStmt) {
                	var nd = nd1[0] as ExprStmt;
					nd1 = nd.expr;
                } else {
                	throw "error forInitialiser " + nd;
                }
                break;
            default:
                var tmp = listExpression (ts,noIn);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            }
            //print ("nd1=",nd1);
 
            Debug.exit("Parser::forInitialiser ", ts1);
            return [ts1,nd1];
        }
        
		/*
		*/

		function forInBinding (ts: TokenStream): Array {
			Debug.enter("Parser::forInBinding ", ts);
			
			// no really doing what the grammar chunk above is calling for. XXX 
			switch (hd(ts)) {
				case Token.Const:
				case Token.Let:
				case Token.Var:
					var tmp = variableDefinition(ts, noIn, localBlk,cx.pragmas.defaultNamespace, false, false);
					var ts1=tmp[0], nd1=tmp[1];
					if (nd1[0] is ExprStmt) {
						var nd = nd1[0] as ExprStmt;
						nd1 = nd.expr;
					} else {
						throw "error forInBinding "+ nd;
					}
					break;
				default:
					var tmp = listExpression (ts, noIn);
					var ts1=tmp[0], nd1=tmp[1];
					break;
			}
			
			Debug.exit("Parser::forInBinding ", ts1);
			return [ts1,nd1];
		}

        /*

        OptionalExpression
            empty
            ListExpression(allowColon, allowIn)

        */

        function optionalExpression (ts: TokenStream)
            : Array //[TokenStream, IAstExpr?]
        {
            Debug.enter("Parser::optionalExpression ", ts);

            switch (hd (ts)) {
            case Token.SemiColon:
            case Token.RightBrace:
                var ts1=ts,nd1=null
                break;
            default:
                var tmp = listExpression (ts,noIn);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            }
 
            Debug.exit("Parser::optionalExpression ", ts1);
            return [ts1,nd1];
        }

        /*

        SwitchStatement
            switch  ParenListExpression  {  CaseElements  }

        CaseElements
            empty
            CaseLabel
            CaseLabel  CaseElementsPrefix  CaseLabel
            CaseLabel  CaseElementsPrefix  Directives(abbrev)

        CaseElementsPrefix
            empty
            CaseElementsPrefix  CaseLabel
            CaseElementsPrefix  Directives(full)

        right recursive:

        CaseElementsPrefix
            empty
            CaseLabel  CaseElementsPrefix
            Directives(full)  CaseElementsPrefix

        */

        function switchStatement (ts: TokenStream)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::switchStatement ", ts);

            ts = eat (ts,Token.Switch);
            var tmp = parenListExpression (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.LeftBrace);
            switch (hd (ts1)) {
            case Token.Case:
            case Token.Default:
                var tmp = caseElementsPrefix (ts1);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            default:
                // do nothing
                break;
            }
            ts2 = eat (ts2,Token.RightBrace);

            var nd3 = []; // FIXME labels

            Debug.exit("Parser::switchStatement ", ts2);
            return [ts2, new SwitchStmt (nd1,nd2,nd3)];
        }

        function caseElementsPrefix (ts: TokenStream)
            : Array //[TokenStream, CASES]
        {
            Debug.enter("Parser::caseElements ", ts);

            var ts1 = ts;
            var nd1 = [];
            while (hd (ts1) !== Token.RightBrace) {
                switch (hd (ts1)) {
                case Token.Case:
                case Token.Default:
                    var tmp = caseLabel (ts1);
                    var ts1=tmp[0], ndx=tmp[1];
                    nd1.push (new Case (ndx,[]));
                    break;
                default:
                    var tmp = directive (ts1,localBlk,fullStmt);  // 'abbrev' is handled by RightBrace check in head
                    var ts1=tmp[0], ndx=tmp[1];
                    for (var i=0; i<ndx.length; ++i) nd1[nd1.length-1].stmts.push (ndx[i]);
                    break;
                }
            }

            Debug.exit("Parser::caseElementsPrefix ", ts1);
            return [ts1,nd1];
        }

        /*

        CaseLabel
            case  ListExpression(allowColon,allowIn)
            default  :

        */

        function caseLabel (ts: TokenStream)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::caseLabel ", ts);
            countLn ();
            printLn (ts);

            switch (hd (ts)) {
            case Token.Case:
                var tmp = listExpression (tl (ts),allowIn);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.Default:
                var ts1=tl (ts),nd1=null;
                break;
            default:
                throw "error caseLabel expecting case";
            }

            ts1 = eat (ts1,Token.Colon);

            Debug.exit("Parser::caseLabel ", ts1);
            return [ts1,nd1];
        }

        function throwStatement (ts: TokenStream)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::throwStatement ", ts);

            ts = eat (ts, Token.Throw);
            var tmp = listExpression (ts,allowIn);
            var ts1=tmp[0], nd1=tmp[1];

            Debug.exit("Parser::throwStatement ", ts1);
            return [ts1, new ThrowStmt (nd1)];
        }

        function tryStatement (ts: TokenStream)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::tryStatement ", ts);

            ts = eat (ts, Token.Try);

            var tmp = block (ts,localBlk);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = catches (ts1);
            var ts2=tmp[0], nd2=tmp[1];
            switch (hd (ts2)) {
            case Token.Finally:
                var tmp = block (tl (ts2),localBlk);
                var ts3=tmp[0], nd3=tmp[1];
                break;
            default:
                var ts3=ts2,nd3=null;
                break;
            }

            Debug.exit("Parser::tryStatement ", ts3);
            return [ts3, new TryStmt (nd1,nd2,nd3)];
        }

        function catches (ts: TokenStream)
            : Array //[TokenStream,CATCHES]
        {
            Debug.enter("Parser::catches ", ts);

            var ts1 = ts;
            var nd1 = [];
            while (hd (ts1)===Token.Catch) {
                var tmp = catchClause (tl (ts1));
                var ts1=tmp[0], ndx=tmp[1];
                nd1.push (ndx);
            }

            Debug.exit("Parser::catches ", ts1);
            return [ts1,nd1];
        }

        function catchClause (ts: TokenStream)
            : Array //[TokenStream,CATCH]
        {
            Debug.enter("Parser::catchClause ", ts);
            countLn ();
            printLn (ts);

            ts = eat (ts,Token.LeftParen);
            var tmp = parameter (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.RightParen);
            var tmp = block (ts1,localBlk);
            var ts2=tmp[0], nd2=tmp[1];

            //var [k,[p,t]] = nd1;
            var k=nd1[0], p=nd1[1][0], t=nd1[1][1];
            var tmp = desugarBindingPattern (p, t, new GetParam (0), Ast.noNS, Ast.varInit, false);
            var f=tmp[0], i=tmp[1];
            var head = new Head (f,[i]);

            Debug.exit("Parser::catchClause ", ts2);
            return [ts2,new Catch (head,nd2)];
        }

        /*

        SwitchTypeStatement
            switch  type  TypedExpression {  TypeCaseElements }
        
        TypeCaseElements
            TypeCaseElement
            TypeCaseElements  TypeCaseElement
            
        TypeCaseElement
            case  (  TypedPattern(allowColon, allowIn)  )  Blocklocal

        */

        function switchTypeStatement (ts: TokenStream)
            : Array //[TokenStream, STMT]
        {
            Debug.enter("Parser::switchTypeStatement ", ts);

            ts = eat (ts,Token.Switch);
            ts = eat (ts,Token.Type);
            var tmp = typedExpression (ts);
            var ts1=tmp[0], nd1=tmp[1];
            var e=nd1[0],t=nd1[1];
            ts1 = eat (ts1,Token.LeftBrace);
            var tmp = typeCases (ts1);
            var ts2=tmp[0], nd2=tmp[1];
            ts2 = eat (ts2,Token.RightBrace);

            Debug.exit("Parser::switchTypeStatement ", ts2);
            return [ts2, new SwitchTypeStmt (e,t,nd2)];
        }

        /*

        TypedExpression
            ParenListExpression
            ParenListExpression  :  NullableTypeExpression

        */

        function typedExpression (ts: TokenStream)
            : Array //[TokenStream,[IAstExpr,IAstTypeExpr]]
        {
            Debug.enter("Parser::typedExpression ", ts);

            var tmp = parenListExpression (ts);
            var ts1=tmp[0], nd1=tmp[1];
            switch (hd (ts1)) {
            case Token.Colon:
                var tmp = nullableTypeExpression (tl (ts1));
                var ts2=tmp[0], nd2=tmp[1];
                break;
            default:
                var ts2=ts1,nd2=Ast.anyType;
                break;
            }

            Debug.exit("Parser::typedExpression ", ts2);
            return [ts2,[nd1,nd2]];
        }

        function typeCases (ts: TokenStream)
            : Array //[TokenStream,CATCHES]
        {
            Debug.enter("Parser::typeCases ", ts);
            countLn ();
            printLn (ts);

            var ts1 = ts;
            var nd1 = [];
            while (hd (ts1)==Token.Case) {
                var tmp = catchClause (tl (ts1));
                var ts1=tmp[0], ndx=tmp[1];
                nd1.push (ndx);
            }

            Debug.exit("Parser::typeCases ", ts1);
            return [ts1,nd1];
        }

        // DEFINITIONS

        /*

        VariableDefinition(beta)
            VariableDefinitionKind  VariableBindingList(beta)


        returns a statement, a list of block fixtures and var fixtures. if the caller
        is a class then it checks the static attribute to know if the var fixtures are
        class fixtures or instance fixtures

        */

        function variableDefinition (ts: TokenStream, beta: IBeta, tau: ITau, ns, isPrototype, isStatic)
            : Array //[TokenStream, STMTS]
        {
            Debug.enter("Parser::variableDefinition ", ts);

            var tmp = variableDefinitionKind (ts);
            var ts1=tmp[0], nd1=tmp[1];

            switch (nd1) {
            case Ast.letConstTag:
                var it = Ast.letInit;
                var ro = true;
                break;
            case Ast.letVarTag:
                var it = Ast.letInit;
                var ro = false;
                break;
            case Ast.constTag:
                var it = Ast.varInit;
                var ro = true;
                break;
            case Ast.varTag:
                var it = Ast.varInit;
                var ro = false;
                break;
            default:
                throw "error variableDefinition kind " + nd1;
            }

            var tmp = variableBindingList (ts1, beta, ns, it, ro);
            var ts2=tmp[0], nd2=tmp[1];
            var fxtrs=nd2[0], exprs=nd2[1];
            

            switch (nd1) {
            case Ast.letConstTag:
            case Ast.letVarTag:
                cx.addLetFixtures (fxtrs);
                var stmts = [new ExprStmt (new ListExpr(exprs))];
                break;
            default:
                switch (tau) {
                case classBlk:
                    cx.addVarFixtures (fxtrs, isStatic);
                    cx.addVarInits (exprs, isStatic);  // FIXME these aren't inits, they are a kind of settings
                    var stmts = [];
                    break;
                default:
                    cx.addVarFixtures (fxtrs);
                    var stmts = [new ExprStmt (new ListExpr(exprs))];
                    (stmts[0].expr.exprs[0].head.fixtures as Array).concat(fxtrs); // XXX gross hack.
                    break;
                }
            }

            Debug.exit("Parser::variableDefinition ", ts2);
            return [ts2,stmts];
        }

        /*

        VariableDefinitionKind
            const
            let
            var const
            var

        */

        function variableDefinitionKind (ts: TokenStream)
            : Array //[TokenStream, VAR_DEFN_TAG]
        {
            Debug.enter("Parser::variableDefinitionKind ", ts);

            switch (hd (ts)) {
            case Token.Const:
                var tsx=tl (ts),ndx= Ast.constTag;
                break;
            case Token.Var:
                var tsx=tl (ts),ndx= Ast.varTag;
                break;
            case Token.Let:
                switch (hd2 (ts)) {
                case Token.Const:
                    var tsx=tl (tl (ts)),ndx= Ast.letConstTag;
                    break;
                case Token.Function:
                    throw "internal error: variableDefinitionKind after let";
                    break;
                default:
                    var tsx=tl (ts),ndx= Ast.letVarTag;
                    break;
                }
                break;
            default:
                throw "internal error: variableDefinitionKind";
                break;
            }

            Debug.exit("Parser::variableDefinitionKind ", hd(tsx));
            return [tsx,ndx];
        }

        /*

        VariableBindingList(beta)
            VariableBinding(beta)
            VariableBindingList(beta)  ,  VariableBinding(beta)

        VariableBinding(beta)
            TypedIdentifier
            TypedPattern(noIn)  VariableInitialisation(beta)

        VariableInitialisation(beta)
            =  AssignmentExpression(beta)

        */

        function variableBindingList (ts: TokenStream, beta: IBeta, ns: IAstNamespace, 
                                      it: IAstInitTarget , ro: Boolean )
            : Array //[TokenStream, [FIXTURES, Array]]
        {
            Debug.enter("Parser::variableBindingList ", ts);

            var tmp = variableBinding (ts, beta);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = variableBindingListPrime (ts1);
            var ts2=tmp[0], nd2=tmp[1];

            var f1=nd1[0],i1=nd1[1];  // FIXME: fold into patterns above when it works in the RI
            var f2=nd2[0],i2=nd2[1];

            for (var i=0; i<f2.length; ++i) f1.push (f2[i]);  // FIXME: use concat when it works in the RI
            for (var i=0; i<i2.length; ++i) i1.push (i2[i]);

            Debug.exit("Parser::variableBindingList ", ts2);
            return [ts2,[f1,i1]];

            function variableBindingListPrime (ts: TokenStream)
                : Array //[TokenStream, [FIXTURES, Array]]
            {
                Debug.enter("Parser::variableBindingListPrime ", ts);
        
                switch (hd (ts)) {
                case Token.Comma:
                    var tmp = variableBinding (tl (ts), beta);
	                var ts1=tmp[0], nd1=tmp[1];
                    var tmp = variableBindingListPrime (ts1);
                    var ts2=tmp[0], nd2=tmp[1];

                    var f1=nd1[0],i1=nd1[1];  // FIXME: fold into patterns above when it works in the RI
                    var f2=nd2[0],i2=nd2[1];

                    for (var i=0; i<f2.length; ++i) f1.push (f2[i]);  // FIXME: use concat when it works in the RI
                    for (var i=0; i<i2.length; ++i) i1.push (i2[i]);
                    break;
                default:
                	var ts2=ts, nd2=[[],[]], f1=[], i1=[];
                    break;
                }

                Debug.exit("Parser::variableBindingListPrime ", ts2);
                return [ts2,[f1,i1]];
            }

            function variableBinding (ts: TokenStream, beta: IBeta)
                : Array //[TokenStream, [FIXTURES, IAstExpr]]
            {
                Debug.enter("Parser::variableBinding ", ts);
                    
                var tmp = typedPattern (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                var p=nd1[0],t=nd1[1];
                switch (hd (ts1)) {
                case Token.Assign:
                    var tmp = assignmentExpression (tl (ts1), beta);
                    var ts2=tmp[0], nd2=tmp[1];
                    switch (hd (ts2)) {
                    case Token.In:
                        if (beta === noIn) {
                            // in a binding form
                            break;
                        } // else fall through
                    default:
                        var tsx=ts2,tmp=desugarBindingPattern (p,t,nd2,ns,it,ro);
                        var f=tmp[0],i=tmp[1];
                        break;
                    }
                    break;
                default:
                    switch (hd (ts1)) {
                    case Token.In:
                        if (beta === noIn) {
                            // in a binding form
                            break;
                        } // else fall through
                    default:
                    	if (p is IdentifierPattern) {
                            var tsx=ts1, tmp=desugarBindingPattern (p,t,null,ns,it,ro);
	                        var f=tmp[0],i=tmp[1];
                        } else {
                            throw "destructuring pattern without initializer";
                        }
                        break;
                    }
                }
                Debug.exit("Parser::variableBinding ", tsx);
                return [tsx,[f,[i]]];
            }
        }

        /*
        function variableBinding (ts: TokenStream, beta: IBeta, ns: IAstNamespace, it: IAstInitTarget )
            : Array //[TokenStream, [FIXTURES, Array]]
        {
            Debug.enter("Parser::variableBinding ", ts);

            let [ts1,nd1] = typedPattern (ts,beta);
            let [p,t] = nd1;
            switch (hd (ts1)) {
            case Token.Assign:
                let [ts2,nd2] = assignmentExpression (tl (ts1), beta);
                switch (hd (ts2)) {
                case Token.In:
                    if (beta === noIn) {
                        // in a binding form
                        break;
                    } // else fall through
                default:
                    var [tsx,ndx] = [ts2,desugarBindingPattern (p,t,nd2,ns,it,ro)];
                    break;
                }
                break;
            default:
                switch (hd (ts1)) {
                case Token.In:
                    if (beta === noIn) {
                        // in a binding form
                        break;
                    } // else fall through
                default:
                    switch type (p) {
                    case (p: IdentifierPattern) {
                        var [tsx,ndx] = [ts1,desugarPattern (p,t,null,ns,it)];
                    }
                    case (x : *) {
                        throw "destructuring pattern without initializer";
                    }
                    }
                break;
                }
            }
            Debug.exit("Parser::variableBinding ", tsx);
            return [tsx,ndx];
        }
        */

        /*

        FunctionDefinition(class)
            function  ClassName  ConstructorSignature  FunctionBody(allowIn)
            function  FunctionName  FunctionSignature  FunctionBody(allowIn)
            
        FunctionDefinition(tau)
            function  FunctionName  FunctionSignature  FunctionBody(allowIn)
            let  function  FunctionName  FunctionSignature  FunctionBody(allowIn)
            const  function  FunctionName  FunctionSignature  FunctionBody(allowIn)

        */

        function functionDefinition (ts: TokenStream, tau: ITau, omega: IOmega, kind, ns, isFinal, isOverride, isPrototype, isStatic, isAbstract)
            : Array //[TokenStream, STMTS]
        {
            Debug.enter("Parser::functionDefinition ", ts);

            ts = eat (ts, Token.Function);

            var tmp = functionName (ts);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = functionSignature (ts1);
            var ts2=tmp[0], nd2=tmp[1];

            cx.enterVarBlock ();
            var tmp = functionBody (ts2, allowIn, omega);
            var ts3=tmp[0], nd3=tmp[1];
            var vars = cx.exitVarBlock ();

            //var {params:params,defaults:defaults,resultType:resultType,thisType:thisType,hasRest:hasRest} = nd2;
            var params=nd2.params, defaults=nd2.defaults, resultType=nd2.resultType, thisType=nd2.thisType, hasRest=nd2.hasRest;
            var func = new Func (nd1,false,nd3,params,vars,defaults,resultType);

            var name = new PropName ({ns:ns,id:nd1.ident});
            var fxtr = new MethodFixture (func,Ast.anyType,true,isOverride,isFinal);
            switch (tau) {
            case classBlk:
                cx.addVarFixtures ([[name,fxtr]], isStatic);
                break;
            default:
                cx.addVarFixtures ([[name,fxtr]]);
                break;
            }

            Debug.exit("Parser::functionDefinition ", ts3);
            return [ts3, []];
        }

        /*

        ConstructorDefinition
            function  ClassName  ConstructorSignature  FunctionBody(allowIn)

        */

        function constructorDefinition (ts: TokenStream, omega, ns)
            : Array //[TokenStream, STMTS]
        {
            Debug.enter("Parser::constructorDefinition ", ts);

            ts = eat (ts, Token.Function);

            var tmp = identifier (ts);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = constructorSignature (ts1);
            var ts2=tmp[0], nd2=tmp[1];

            cx.enterVarBlock ();
            var tmp = functionBody (ts2, allowIn, omega);
            var ts3=tmp[0], nd3=tmp[1];
            var vars = cx.exitVarBlock ();

            //var {params:params,defaults:defaults,hasRest:hasRest,settings:settings,superArgs:superArgs} = nd2;
            var params=nd2.params, defaults=nd2.defaults, hasRest=nd2.hasRest, settings=nd2.settings, superArgs=nd2.superArgs;

            // print ("superArgs=",superArgs);
            // print ("settings=",settings);
            var func = new Func ({kind:new Ordinary,ident:nd1},false,nd3,params,vars,defaults,Ast.voidType);
            var ctor = new Constructor (settings,superArgs,func);

            if (cx.ctor !== null) {
                throw "constructor already defined";
            }

            cx.ctor = ctor;

            Debug.exit("Parser::constructorDefinition ", ts3);

            return [ts3, []];
        }

        /*

        ConstructorSignature
            TypeParameters  (  Parameters  )  ConstructorInitialiser
        
        */
/*
        type CTOR_SIG = 
          { typeParams : [IDENT]
          , params : HEAD
          , paramTypes : [IAstTypeExpr]
          , defaults : [IAstExpr]
          , hasRest: Boolean
          , settings : [IAstExpr]
          , superArgs: [IAstExpr] }

        type FUNC_SIG = 
          { typeParams : [IDENT]
          , params : HEAD
          , paramTypes : [IAstTypeExpr]
          , defaults : [IAstExpr]
          , returnType : IAstTypeExpr
          , thisType : IAstTypeExpr?
          , hasRest : Boolean }
*/

        function constructorSignature (ts: TokenStream)
            : Array //[TokenStream, CTOR_SIG]
        {
            Debug.enter("Parser::constructorSignature ", ts);

            var tmp = typeParameters (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1, Token.LeftParen);
            var tmp = parameters (ts1);
            var ts2=tmp[0], nd2=tmp[1], hasRest=tmp[2];
            ts2 = eat (ts2, Token.RightParen);
            var tmp = constructorInitialiser (ts2);
            var ts3=tmp[0],settings=tmp[1],superArgs=tmp[2];

            // Translate bindings and init steps into fixtures and inits (HEAD)
            //var [[f,i],e,t] = nd2;
            var f=nd2[0][0], i=nd2[0][1], e=nd2[1], t=nd2[2];

            var ndx = { typeParams: []
                      , params: new Head (f,i)
                      , paramTypes: t
                      , defaults: e
                      , hasRest: hasRest
                      , settings: settings
                      , superArgs: superArgs };

            Debug.exit("Parser::constructorSignature ", ts3);

            return [ts3,ndx]
        }

        /*

        ConstructorInitialiser
            empty
            : SettingList
            : SettingList  ,  SuperInitialiser
            : SuperInitialiser
        
        SuperInitialiser
            super  Arguments

        constructor initializers are represented by two lists. the first
        list represents the initializers and will consist of set exprs or
        let exprs (if there are temps for destructuring). the second list
        represents the arguments to the call the the super constructor

        */

        function constructorInitialiser (ts: TokenStream)
            : Array //[TokenStream, [IAstExpr], [IAstExpr]]
        {
            Debug.enter("Parser::constructorInitialiser ", ts);

            switch (hd (ts)) {
            case Token.Colon:
                switch (hd2 (ts)) {
                case Token.Super:
                    var ts1=tl (tl (ts)),nd1=[]; // no settings
                    var tmp = this.arguments (ts1);
                    var ts2=tmp[0], nd2=tmp[1];
                    break;
                default:
                    var tmp = settingList (tl (ts));
	                var ts1=tmp[0], nd1=tmp[1];
                    switch (hd (ts1)) {
                    case Token.Super:
                        var tmp = this.arguments (tl (ts1));
                        var ts2=tmp[0], nd2=tmp[1];
                        break;
                    default:
                        var ts2=ts1,nd2=[];
                        break;
                    }
                    break;
                }
                break;
            default:
                var ts2 = ts;
                var nd1 = [];
                var nd2 = [];
                break;
            }

            Debug.exit("Parser::constructorInitialiser ", ts2);
            return [ts2,nd1,nd2];
        }


        /*

        SettingList
            Setting
            SettingList  ,  Setting
        
        Setting
            Pattern(noIn, noExpr)  VariableInitialisation(allowIn)
        
        */

        function settingList (ts: TokenStream)
            : Array //[TokenStream, [IAstExpr]]
        {
            Debug.enter("Parser::settingList ", ts);

            function settingListPrime (ts: TokenStream )
                : Array //[TokenStream,[IAstExpr]]
            {
                Debug.enter("Parser::settingListPrime ", ts);
        
                switch (hd (ts)) {
                case Token.Comma:
                    switch (hd2 (ts)) {
                    case Token.Super:
                        var ts2=tl (ts),nd2= [];  // eat the comma
                        break;
                    default:
                        var tmp = setting (tl (ts));
		                var ts1=tmp[0], nd1=tmp[1];
                        var tmp = settingListPrime (ts1);
                        var ts2=tmp[0], nd2=tmp[1];
                        nd2.unshift (nd1);
                        break;
                    }
                    break;
                default:
                    var ts2=ts,nd2=[];
                    break;
                }

                Debug.exit("Parser::settingListPrime ", ts2);
                return [ts2,nd2];
            }

            var tmp = setting (ts);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = settingListPrime (ts1);
            var ts2=tmp[0], nd2=tmp[1];

            nd2.unshift (nd1);

            Debug.exit("Parser::settingList ", ts2);
            return [ts2,nd2];
        }

        /*

        Setting
            Pattern(noIn, allowExpr)  VariableInitialisation(allowIn)


            function A (a) : [q::x,r::y] = a { }


            let ($t0 = a) q::x = $t0[0], r::y = $t0[1]

            let ($t0 = a)
                init (This,q,[x,$t0[0]),
                init (This,r,[y,$t0[1])


        */

        function setting (ts: TokenStream)
            : Array //[TokenStream, IAstExpr]
        {
            Debug.enter("Parser::setting ", ts);

            var tmp = pattern (ts,allowIn,allowExpr);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1,Token.Assign);
            var tmp = assignmentExpression (ts1,allowIn);
            var ts2=tmp[0], nd2=tmp[1];

            var tsx=ts2, tmp=desugarBindingPattern (nd1, Ast.anyType, nd2, null, Ast.instanceInit, false);
            var fxtrs=tmp[0], ndx=tmp[1];
            // assert fxtrs is empty

            Debug.exit("Parser::setting ", tsx);
            return [tsx,ndx];
        }

        /*

        FunctionName
            Identifier
            OverloadedOperator
            get  Identifier
            set  Identifier

        */

        function functionName (ts: TokenStream)
            : Array //[TokenStream, FUNC_NAME]
        {
            Debug.enter("Parser::functionName ", ts);

            switch (hd (ts)) {
            case Token.Get:
                var tmp = identifier (tl (ts));
                var ts1=tmp[0], nd1=tmp[1];
                var tsx = ts1;
                var ndx = {kind: new Get, ident: nd1};
                break;
            case Token.Set:
                var tmp = identifier (tl (ts));
                var ts1=tmp[0], nd1=tmp[1];
                var tsx = ts1;
                var ndx = {kind: new Set, ident: nd1};
                break;
            case Token.Plus:
            case Token.Minus:
                // FIXME add other operators here
                break;
            default:
                var tmp = identifier (ts);
                var ts1=tmp[0], nd1=tmp[1];
                var tsx = ts1;
                var ndx = {kind: new Ordinary, ident: nd1};
                break;
            }

            Debug.exit("Parser::functionName ", ts1);

            return [tsx,ndx]
        }

        /*

        FunctionSignature
            TypeParameters  (  Parameters  )  ResultType
            TypeParameters  (  this  :  PrimaryIdentifier  )  ResultType
            TypeParameters  (  this  :  PrimaryIdentifier  ,  NonemptyParameters  )  ResultType

        there are two differences between a BINDING_IDENT and a FIXTURE_NAME: the namespace on
        properties, and the offset on parameter indicies.

        */

        function functionSignature (ts: TokenStream)
            : Array //[TokenStream, FUNC_SIG]
        {
            Debug.enter("Parser::functionSignature ", ts);

            var tmp = typeParameters (ts);
            var ts1=tmp[0], nd1=tmp[1];
            ts1 = eat (ts1, Token.LeftParen);
            switch (hd (ts1)) {
            case Token.This:
                // FIXME
                break;
            default:
                var tmp = parameters (ts1);
                var ts2=tmp[0], nd2=tmp[1], hasRest=tmp[2];
                break;
            }
            ts2 = eat (ts2, Token.RightParen);
            var tmp = resultType (ts2);
            var ts3=tmp[0], nd3=tmp[1];

            // Translate bindings and init steps into fixtures and inits (HEAD)
            //var [[f,i],e,t] = nd2;
			var f=nd2[0][0], i=nd2[0][1], e=nd2[1], t=nd2[2];

            var ndx = { typeParams: []
                      , params: new Head (f,i)
                      , paramTypes: t
                      , defaults: e
                      , ctorInits: null
                      , resultType: nd3
                      , thisType: null
                      , hasRest: hasRest };

            Debug.exit("Parser::functionSignature ", ts3);

            return [ts3,ndx]
        }

        /*

        TypeParameters
            empty
            .<  TypeParameterList  >

        */

        function typeParameters (ts: TokenStream)
            : Array //[TokenStream, [IDENT]]
        {
            Debug.enter("Parser::typeParameters ", ts);

            switch (hd (ts)) {
            case Token.LeftDotAngle:
                ts = eat (ts, Token.LeftDotAngle);
                var tmp = typeParameterList (ts);
                var ts1=tmp[0], nd1=tmp[1];
                ts1 = eat (ts1, Token.GreaterThan);
                break;
            default:
                var ts1=ts,nd1=[];
                break;
            }

            Debug.exit("Parser::typeParameters ", ts1);
            return [ts1,nd1];
        }

        /*

        TypeParameterList
            Identifier
            Identifier  ,  TypeParameterList

        */

        function typeParameterList (ts: TokenStream)
            : Array //[TokenStream, [IDENT]]
        {
            Debug.enter("Parser::typeParameterList ", ts);

            function typeParameterListPrime (ts)
                : Array //[TokenStream, [IDENT]] 
			{
                switch (hd (ts)) {
                case Token.Comma:
                    ts = eat (ts, Token.Comma);
                    var tmp = identifier (ts);
	                var ts1=tmp[0], nd1=tmp[1];
                    var tmp = typeParameterListPrime (ts1);
                    var ts2=tmp[0], nd2=tmp[1];
                    break;
                default:
                    var ts2=ts,nd2=[];
                    break;
                }
                return [ts2,nd2];
            }

            var tmp = identifier (ts);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = typeParameterListPrime (ts1);
            var ts2=tmp[0], nd2=tmp[1];

            nd2.unshift (nd1);

            Debug.exit("Parser::typeParameterList ", ts2);
            return [ts2,nd2];
        }

        /*

        Parameters
            empty
            NonemptyParameters

        */

        function parameters (ts: TokenStream)
            : Array //[TokenStream, [[FIXTURES, Array], [IAstExpr], [IAstTypeExpr]], Boolean]
        {
            Debug.enter("Parser::parameters ", ts);

            switch (hd (ts)) {
            case Token.RightParen:
                var b1 = [];
                var i1 = [];
                var e1 = [];
                var t1 = [];
                //var [ts1,nd1,hasRest] = [ts,[[[],[]],e1,t1],false];
                var ts1=ts, nd1=[[[],[]],e1,t1], hasRest=false;
                break;
            default:
                var tmp = nonemptyParameters (ts,0,false);
                var ts1=tmp[0], nd1=tmp[1], hasRest=tmp[2];
                break;
            }

            Debug.exit("Parser::parameters ", ts1);
            return [ts1,nd1,hasRest];
        }

        /*

        NonemptyParameters
            ParameterInit
            ParameterInit  ,  NonemptyParameters
            RestParameter

        */

        function nonemptyParameters (ts: TokenStream, n:int, initRequired)
            : Array //[TokenStream, [[FIXTURES,Array], Array, TYPE_EXPRS], Boolean]
        {
            Debug.enter("Parser::nonemptyParameters ", ts);

            switch (hd (ts)) {
            case Token.TripleDot:
                var tmp = restParameter (ts,n);
                var ts1=tmp[0], nd1=tmp[1];
                /* var */ hasRest = true;
                break;
            default:
                var tmp = parameterInit (ts,n,initRequired);
                var ts1=tmp[0], nd1=tmp[1];
                switch (hd (ts1)) {
                case Token.Comma:
                    ts1 = eat (ts1, Token.Comma);
                    //var [[f1,i1],e1,t1] = nd1;
                    var f1=nd1[0][0], i1=nd1[0][1], e1=nd1[1], t1=nd1[2];
                    var tmp = nonemptyParameters (ts1, n+1, e1.length!=0);
                    var ts2=tmp[0], nd2=tmp[1], hasRest=tmp[2];
                    //var [[f2,i2],e2,t2] = nd2;
                    var f2=nd2[0][0], i2=nd2[0][1], e2=nd2[1], t2=nd2[2];
                    // FIXME when Array.concat works
                    for (var i=0; i<f2.length; ++i) f1.push(f2[i]);
                    for (var i=0; i<i2.length; ++i) i1.push(i2[i]);
                    for (var i=0; i<e2.length; ++i) e1.push(e2[i]);
                    for (var i=0; i<t2.length; ++i) t1.push(t2[i]);
                    var tmp = [ts2,[[f1,i1],e1,t1],hasRest];
                    var ts1=tmp[0], nd1=tmp[1], hasRest=tmp[2];
                    break;
                case Token.RightParen:
                    // nothing to do
                    break;
                default:
                    throw "unexpected token in nonemptyParameters";
                }
                break;
            }

            Debug.exit("Parser::nonemptyParameters ", ts1);
            return [ts1,nd1,hasRest];
        }

        /*

        ParameterInit
            Parameter
            Parameter = NonAssignmentExpression(AllowIn)

        */

        function parameterInit (ts: TokenStream, n: int, initRequired)
            : Array //[TokenStream,[[FIXTURES,Array], Array, TYPE_EXPRS]]
        {
            Debug.enter("Parser::parameterInit ", ts);

            var tmp = parameter (ts);
            var ts1=tmp[0], nd1=tmp[1];
            switch (hd (ts1)) {
            case Token.Assign:
                ts1 = eat (ts1, Token.Assign);
                var tmp = nonAssignmentExpression(ts1,allowIn);
                var ts2=tmp[0], nd2=tmp[1];
                nd2 = [nd2];
                break;
            default:
                if (initRequired) {
                    throw "expecting default value expression";
                }
                var ts2=ts1,nd2=[];
                break;
            }

            //var [k,[p,t]] = nd1;
            var k=nd1[0], p=nd1[1][0], t=nd1[1][1];
            var tmp = desugarBindingPattern (p, t, new GetParam (n), Ast.noNS, Ast.letInit, false);
            var f=tmp[0], i=tmp[1];
            f.push ([new TempName (n), new ValFixture (t,false)]); // temp for desugaring
            Debug.exit("Parser::parameterInit ", ts2);
            return [ts2,[[f,[i]],nd2,[t]]];
        }

        /*

        Parameter
            ParameterKind  TypedIdentifier(AllowIn)
            ParameterKind  TypedPattern

        */

        function parameter (ts: TokenStream)
            : Array //[TokenStream, [VAR_DEFN_TAG, [IParserPattern, IAstTypeExpr]]]
        {
            Debug.enter("Parser::parameter ", ts);

            var tmp = parameterKind (ts);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = typedPattern (ts1,allowIn);
            var ts2=tmp[0], nd2=tmp[1];

            Debug.exit("Parser::parameter ", ts2);
            return [ts2,[nd1,nd2]];
        }

        /*

        ParameterKind
            empty
            const

        */

        function parameterKind (ts: TokenStream)
            : Array //[TokenStream, VAR_DEFN_TAG]
        {
            Debug.enter("Parser::parameterKind ", ts);

            switch (hd (ts)) {
            case Token.Const:
                ts = eat (ts, Token.Const);
                var ts1=ts,nd1= new Const;
                break;
            default:
                var ts1=ts,nd1= new Var;
                break;
            }

            Debug.exit("Parser::parameterKind ", ts1);
            return [ts1,nd1];
        }

        /*

        ResultType
            empty
            :  void
            :  NullableTypeExpression

        */

        function resultType (ts: TokenStream)
            : Array //[TokenStream, [IDENT]]
        {
            Debug.enter("Parser::resultType ", ts);

            switch (hd (ts)) {
            case Token.Colon:
                ts = eat (ts, Token.Colon);
                switch (hd (ts)) {
                case Token.Void:
                    ts = eat (ts, Token.Void);
                    var ts1=ts,nd1=new SpecialType (new VoidType);
                    break;
                default:
                    var tmp = nullableTypeExpression (ts);
	                var ts1=tmp[0], nd1=tmp[1];
                    break;
                }
                break;
            default:
                var ts1=ts,nd1=Ast.anyType;
                break;
            }

            Debug.exit("Parser::resultType ", ts1);
            return [ts1,nd1];
        }

        /*

            FunctionBody(beta)
                Block(local)
                AssignmentExpression(beta)

        */

        function functionBody (ts: TokenStream, beta: IBeta, omega)
            : Array //[TokenStream, BLOCK]
        {
            Debug.enter("Parser::functionBody ", ts);

            switch (hd (ts)) {
            case Token.LeftBrace:
                var tmp = block (ts,localBlk);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            default:
                var tmp = assignmentExpression (ts,beta);
                var ts1=tmp[0], nd1=tmp[1];
                ts1 = semicolon (ts1,omega);
                var nd1 = new Block (new Head ([],[]),[new ReturnStmt (nd1)]);
                break;
            }

            Debug.exit("Parser::functionBody ", ts1);
            return [ts1,nd1];
        }

        function classDefinition (ts: TokenStream, ns: IAstNamespace, isDynamic)
            : Array //[TokenStream, STMTS]
        {
            Debug.enter("Parser::classDefinition ", ts);

            ts = eat (ts, Token.Class);

            var tmp = identifier (ts);
            var ts1=tmp[0], nd1=tmp[1];
            // print ("class ",nd1);
            var tmp = typeSignature (ts1);
            var ts2=tmp[0], nd2=tmp[1];
            var tmp = classInheritance (ts2);
            var ts3=tmp[0], nd3=tmp[1];
            currentClassName = nd1;
            cx.enterVarBlock(); // Class
            cx.enterVarBlock (); // Instance
            var tmp = classBody (ts3);
            var ts4=tmp[0], blck=tmp[1];
            var ihead = cx.exitVarBlock (); // Instance
            var chead = cx.exitVarBlock (); // Class
            currentClassName = "";

            var name = {ns:ns,id:nd1};

            var ctor = cx.ctor;
            if (ctor===null)
            {
                var isNative = false;
                var blck2 = new Block (new Head([],[]),[]);
                var params = new Head([],[]);
                var vars = new Head([],[]);
                var defaults = [];
                var ty = Ast.anyType;
                var func = new Func ({kind:new Ordinary,ident:nd1},isNative,blck2,params,vars,defaults,ty);
                var ctor = new Constructor ([],[],func);
            }
            
            // var [i,j] = o
            // var $t = o
            // var i = $t[0]
            // var j = $t[1]

            // let ($t=o) init

			if (nd3 is UnresolvedPath) {
            	var nd = nd3 as UnresolvedPath;
                nd3 = {ns: new PublicNamespace(nd.path.join(".")), id:nd.ident.ident};
   			} else if (nd3 is Identifier) {
   				// how do I know which nss to use? :(
   				// XXX lame, but use the first one for now.
   				// the proper fix would be to compile against intrinsic classes. more work.
   				nd3 = {ns: nd3.nss[0][0], id: nd3.ident }; 
            } else {
            	nd3 = null;
            }
            var baseName = nd3 || {ns: new PublicNamespace (""), id: "Object"};

            var interfaceNames = [];
            //var chead = new Head ([],[]);
            var ctype = Ast.anyType;
            var itype = Ast.anyType;
            var cls = new Cls (name,baseName,interfaceNames,ctor,chead,ihead,ctype,itype);

            var fxtrs = [[new PropName(name),new ClassFixture (cls)]];
            cx.addVarFixtures (fxtrs);
            cx.ctor = null;

            var ss4 = [new ClassBlock (name,blck)];

            Debug.exit("Parser::classDefinition ", ts4);

            return [ts4, ss4];
        }

		

        /*

        Typesignature
            TypeParameters
            TypeParameters  !

        */

        function typeSignature (ts: TokenStream)
            : Array //[TokenStream, [IDENT], Boolean]
        {
            Debug.enter("Parser::className ", ts);

            var tmp = typeParameters (ts);
            var ts1=tmp[0], nd1=tmp[1];

            switch (hd (ts1)) {
            case Token.Not:
                var ts2=tl (ts1),nd2= true;
                break;
            default:
                var ts2=ts1,nd2= false;
                break;
            }

            Debug.exit("Parser::typeSignature ", ts2);

            return [ts2,nd1,nd2];
        }

        function classInheritance (ts: TokenStream)
            : Array //[TokenStream, [IAstIdentExpr]]
        {
            Debug.enter("Parser::classInheritance ", ts);

            switch (hd (ts)) {
            case Token.Extends:
                var tmp = primaryName (tl (ts));
                var ts1=tmp[0], nd1=tmp[1];
                switch (hd (ts)) {
                case Token.Implements:
                    var tmp = primaryNameList (tl (ts));
                    var ts2=tmp[0], nd2=tmp[1];
                    break;
                default:
                    var ts2=ts1,nd2=nd1;
                    break;
                }
                break;
            case Token.Implements:
                var ts1=ts,nd1=[];
                var tmp = primaryNameList (tl (ts1));
                var ts2=tmp[0], nd2=tmp[1];
                break;
            default:
                var ts1=ts,nd1=[];
                var ts2=ts1,nd2=[];
                break;
            }

            Debug.exit("Parser::classInheritance ", ts2);

            return [ts2,nd2];
        }

        function classBody (ts: TokenStream)
            : Array //[TokenStream, BLOCK]
        {
            Debug.enter("Parser::classBody ", ts);

            var tmp = block (ts,classBlk);
            var ts1=tmp[0], blck=tmp[1];

            Debug.exit("Parser::classBody ", ts1);

            return [ts1,blck];
        }

        /*

        NamespaceDefinition(omega)
            namespace  Identifier  NamespaceInitialisation  Semicolon(omega)

        NamespaceInitialisation
            empty
            =  StringLiteral
            =  PrimaryName

        */

        function namespaceDefinition (ts: TokenStream, omega: IOmega, ns: IAstNamespace )
            : Array //[TokenStream, STMTS]
        {
            Debug.enter("Parser::namespaceDefinition ", ts);

            function getAnonymousName (seedStr) {
                return seedStr;  // FIXME
            }

            ts = eat (ts,Token.Namespace);
            var tmp = identifier (ts);
            var ts1=tmp[0], nd1=tmp[1];
            var tmp = namespaceInitialisation (ts1);
            var ts2=tmp[0], nd2=tmp[1];
            ts2 = semicolon (ts2,omega);

            if (nd2 === null) 
            {
                var nsVal = new AnonymousNamespace (getAnonymousName(nd1));
            }
            else 
            {
                var nsVal = new UserNamespace (nd2);
            }

            var name = new PropName ({ns:ns, id:nd1});
            var fxtr = new NamespaceFixture (nsVal);
            cx.addVarFixtures ([[name,fxtr]]);

            Debug.exit("Parser::namespaceDefinition ", ts2);
            return [ts2,[]];
        }

        function namespaceInitialisation (ts: TokenStream)
            : Array //[TokenStream, IDENT]
        {
            Debug.enter("Parser::namespaceInitialisation ", ts);

            switch (hd (ts)) {
            case Token.Assign:
                switch (hd2 (ts)) {
                case Token.StringLiteral:
                    var tx = Token.tokenText (tl (ts).head());
                    var ts1=tl (ts),nd1= tx;
                    break;
                default:
                    var tmp = primaryName (tl (ts));
	                var ts1=tmp[0], nd1=tmp[1];
	                // XXX grab a later revision to fix this.
                    //nd1 = cx.resolveNamespaceFromIdentExpr (nd1);  // FIXME not implemented
                    break;
                }
                break;
            default:
                var ts1=ts,nd1=null;
                break;
            }

            Debug.exit("Parser::namespaceInitialisation ", ts1);
            return [ts1,nd1];
        }


        /*

        TypeDefinition(omega)
            type  Identifier  TypeInitialisation  Semicolon(omega)

        TypeInitialisation
            =  NullableTypeExpression

        */

        function typeDefinition (ts: TokenStream, omega: IOmega, ns: IAstNamespace)
            : Array //[TokenStream, STMTS]
        {
            Debug.enter("Parser::typeDefinition ", ts);

            ts = eat (ts,Token.Type);
            var tmp = identifier (ts);
            var ts1=tmp[0], nd1=tmp[1];
            // print ("type ",nd1);

            ts1 = eat (ts1,Token.Assign);
            var tmp = nullableTypeExpression (ts1);
            var ts2=tmp[0], nd2=tmp[1];
            ts2 = semicolon (ts2, omega);

            var name = new PropName ({ns:ns, id:nd1});
            var fxtr = new TypeFixture (nd2);
            cx.addVarFixtures ([[name,fxtr]]);

            Debug.exit("Parser::typeDefinition ", ts2);
            return [ts2,[]];
        }

        // DIRECTIVES

        /*
          Directives(tau)
              empty
              DirectivesPrefix(tau) Directives(tau,full)

        */

        function directives (ts: TokenStream, tau: ITau)
            : Array //[TokenStream, PRAGMAS, STMTS]
        {
            Debug.enter("Parser::directives ", ts);

            switch (hd (ts)) {
            case Token.RightBrace:
            case Token.EOS:
                //var [ts1,nd1] = [ts,[],[]];
                var ts1=ts, nd1=[]; // XXX leftover unassigned []. I guess es4 drops it.
                break;
            default:
                var tmp = directivesPrefix (ts,tau);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            }

            Debug.exit("Parser::directives ", ts1);
            return [ts1,nd1];
        }

        /*

          DirectivesPrefix (tau)
              empty
              Pragmas
              DirectivesPrefix(tau) Directive(tau,full)

          right recursive:

          DirectivesPrefix(tau)
              empty
              Pragmas DirectivePrefix'(tau)

          DirectivesPrefix'(tau)
              empty
              Directive(tau,full) DirectivesPrefix'(tau)

          add var fixtures to the vhead and let fixtures to the bhead. the
          context provides a reference to the current vhead and bhead, as
          well as the whole environment, for convenient name addition and
          lookup.


        */

        function directivesPrefix (ts: TokenStream, tau: ITau)
            : Array //[TokenStream, PRAGMAS, STMTS]
        {
            Debug.enter("Parser::directivesPrefix ", ts);

            switch (hd (ts)) {
            case Token.Use:
            case Token.Import:
                var tmp = pragmas (ts);
                var ts1=tmp[0]; 
                var tmp = directivesPrefixPrime (ts1,tau);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            default:
                var tmp = directivesPrefixPrime (ts,tau);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            }

            Debug.exit("Parser::directivesPrefix ", ts2);
            return [ts2,nd2];
        }

        function directivesPrefixPrime (ts: TokenStream, tau: ITau)
            : Array //[TokenStream, STMTS]
        {
            Debug.enter("Parser::directivesPrefixPrime ", ts);

            var nd1 = [];
            var ts1 = ts;

            while (hd (ts1) !== Token.RightBrace &&
                   hd (ts1) !== Token.EOS ) 
            {
                var tmp = directive (ts1,tau,fullStmt);
                var ts1=tmp[0], ndx=tmp[1];
                for (var i=0; i<ndx.length; ++i) nd1.push (ndx[i]);
            }

            Debug.exit("Parser::directivesPrefixPrime ", ts1);
            return [ts1,nd1];
        }

        function isCurrentClassName (tk) 
            : Boolean {
            var text = Token.tokenText (tk);
            //print ("tk",tk);
            //print ("text",text);
            //print ("currentClassName",currentClassName);

            if (text == currentClassName) 
            {
                return true;
            }
            else 
            {
                return false;
            }
        }

        /*

        Directive(t, w)
            EmptyStatement
            Statement(w)
            AnnotatableDirective(t, w)
            Attributes(t)  [no line break]  AnnotatableDirective(t, w)

        */

        function directive (ts: TokenStream, tau: ITau, omega: IOmega)
            : Array //[TokenStream, STMTS]
        {
            Debug.enter("Parser::directive ", ts);

            countLn ();
            printLn (ts);

            switch (hd(ts)) {
            case Token.SemiColon:
                var ts1=tl (ts),nd1= [new EmptyStmt];
                break;
            case Token.Let: // FIXME might be function
            case Token.Var:
            case Token.Const:
                var tmp
                    = variableDefinition (ts, allowIn, tau
                                  , cx.pragmas.defaultNamespace
                                  , false, false);
                var ts1=tmp[0], nd1=tmp[1];

                ts1 = semicolon (ts1,omega);
                break;
            case Token.Function:
                if (isCurrentClassName (ts.head2())) 
                {
                    var tmp = constructorDefinition (ts, omega, cx.pragmas.defaultNamespace);
	                var ts1=tmp[0], nd1=tmp[1];
                }
                else 
                {
                    var tmp = functionDefinition (ts, tau, omega, new Var
                                  , cx.pragmas.defaultNamespace
                                  , false, false, false, false, false);
	                var ts1=tmp[0], nd1=tmp[1];
                }
                //ts1 = semicolon (ts1,omega);
                break;
            case Token.Class:
                var isDynamic = false;
                var tmp = classDefinition (ts, cx.pragmas.defaultNamespace, isDynamic);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.Namespace:
                var tmp = namespaceDefinition (ts, omega, cx.pragmas.defaultNamespace);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.Type:
                var tmp = typeDefinition (ts, omega, cx.pragmas.defaultNamespace);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            case Token.LeftBrace:
            case Token.Break:
            case Token.Continue:
            case Token.Default:
            case Token.Do:
            case Token.For:
            case Token.If:
            case Token.Let:
            case Token.Return:
            case Token.Switch:
            case Token.Throw:
            case Token.Try:
            case Token.While:
            case Token.With:
                var tmp = statement (ts,tau,omega);
                var ts1=tmp[0], nd1=tmp[1];
                nd1 = [nd1];
                break;
            case Token.Dynamic:
            case Token.Final:
            case Token.Native:
            case Token.Override:
            case Token.Prototype:
            case Token.Static:
            case Token.Public:
            case Token.Private:
            case Token.Protected:
            case Token.Internal:
            case Token.Intrinsic:
                var tmp = attribute (ts,tau,defaultAttrs());
                var ts1=tmp[0], nd1=tmp[1];
                var tmp = annotatableDirective (ts1,tau,omega,nd1);
                var ts1=tmp[0], nd1=tmp[1];
                break;
            default:  // label, attribute, or expr statement
                var tmp = listExpression (ts,allowIn);
                var ts1=tmp[0], nd1=tmp[1];
                switch (hd (ts1)) {
                case Token.Colon:  // label
                    //print ("label=",Encode::encodeExpr (nd1));
                    // FIXME check label
                    break;
                case Token.SemiColon:
                    var tmp = [tl (ts1), [new ExprStmt (nd1)]];
	                var ts1=tmp[0], nd1=tmp[1];
                    break;
                case Token.RightBrace:
                case Token.EOS:
                    var nd1 = [new ExprStmt (nd1)];
                    break;
                default:
                    if (newline (ts1)) 
                    { // stmt
                        var nd1 = [new ExprStmt (nd1)];
                    }
                    else 
                    {
                        switch (hd (ts1)) {
                        case Token.Dynamic:
                        case Token.Final:
                        case Token.Native:
                        case Token.Override:
                        case Token.Prototype:
                        case Token.Static:
                        case Token.Let:
                        case Token.Var:
                        case Token.Const:
                        case Token.Function:
                        case Token.Class:
                        case Token.Namespace:
                        case Token.Type:
                            // FIXME check ns attr
                            var ie = nd1.exprs[0].ident;  
                            var attrs = defaultAttrs ();
                            attrs.ns = cx.evalIdentExprToNamespace (ie);
                            var tmp = annotatableDirective (ts1,tau,omega,attrs);
			                var ts1=tmp[0], nd1=tmp[1];
                            break;
                        default:
                            throw "directive should never get here " + ts1;
                            var nd1 = [new ExprStmt (nd1)];
                            break;
                        }
                    }
                }
            }

            Debug.exit("Parser::directive ", ts1);
            return [ts1,nd1];
        }

        function annotatableDirective (ts: TokenStream, tau: ITau, omega: IOmega, attrs)
            : Array //[TokenStream, STMTS]
        {
            Debug.enter("Parser::annotatableDirective ", ts);

            switch (hd(ts)) {
            case Token.Let: // FIXME might be function
            case Token.Var:
            case Token.Const:
                var tmp
                    = variableDefinition (ts, allowIn, tau
                                          , attrs.ns
                                          , attrs.prototype
                                          , attrs.static);
				var ts2=tmp[0], nd2=tmp[1];

                var ts2 = semicolon (ts2,omega);
                break;
            case Token.Function:
                if (isCurrentClassName (ts.head2())) 
                {
                    var tmp = constructorDefinition (ts, omega, attrs.ns);
                    var ts2=tmp[0], nd2=tmp[1];
                }
                else 
                {
                    var tmp = functionDefinition (ts, tau, omega, new Var
                                                           , attrs.ns, attrs.final, attrs.override
                                                           , attrs.prototype, attrs.static, attrs.abstract);
					var ts2=tmp[0], nd2=tmp[1];
                }
                //ts2 = semicolon (ts2,omega);
                break;
            case Token.Class:
                var tmp = classDefinition (ts, attrs.ns, attrs.dynamic);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            case Token.Namespace:
                //print ("found namespace");
                var tmp = namespaceDefinition (ts, omega, attrs.ns);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            case Token.Type:
                var tmp = typeDefinition (ts, omega, attrs.ns);
                var ts2=tmp[0], nd2=tmp[1];
                break;
            default:  // label, attribute, or expr statement
                var tmp = attribute (ts,tau,defaultAttrs());
                var ts1=tmp[0], nd1=tmp[1];
                if (newline (ts1)) throw "error unexpected newline before "+Token.tokenText (hd (ts));
                var tmp = annotatableDirective (ts1,tau,omega,nd1);
                var ts2=tmp[0], nd2=tmp[1];
            }

            Debug.exit("Parser::annotatableDirective ", ts2);
            return [ts2,nd2];
        }

//        /*
//
//        Attributes
//            Attribute
//            Attribute [no line break] Attributes
//
//        Attribute
//            SimpleTypeIdentifier
//            ReservedNamespace
//            dynamic
//            final
//            native
//            override
//            prototype
//            static
//            [  AssignmentExpressionallowIn  ]
//
//        */
//

        //type Object = Object;  // FIXME object type

        function defaultAttrs ()
            : Object {
            return { ns: cx.pragmas.defaultNamespace
                   , 'true': false
                   , 'false': false
                   , dynamic: false
                   , final: false
                   , native: false
                   , override: false
                   , prototype: false
                   , static: false }
        }

        function attribute (ts: TokenStream, tau: ITau, nd: Object)
            : Array //[TokenStream, *]
        {
            Debug.enter("Parser::attribute tau="+tau+" ", ts);

            switch (tau) {
            case classBlk:
                switch (hd (ts)) {
                case Token.Final:
                    nd.final = true;
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.Native:
                    nd.native = true;
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.Override:
                    nd.override = true;
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.Prototype:
                    nd.prototype = true;
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.Static:
                    nd.static = true;
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.Public:
                case Token.Private:
                case Token.Protected:
                case Token.Internal:
                case Token.Intrinsic:
                    var tmp = reservedNamespace (ts);
	                var ts1=tmp[0], nd1=tmp[1];
                    nd.ns = nd1;
                    var ts1=ts1,nd1= nd;
                    break;
                default:
                    var tmp = primaryName (ts);
	                var ts1=tmp[0], nd1=tmp[1];
                    nd.ns = cx.evalIdentExprToNamespace (nd1);
                    var ts1=ts1,nd1=nd;
                    break;
                }
                break;
            case globalBlk:
                switch (hd (ts)) {
                case Token.True:
                    nd['true'] = true;  // FIXME RI bug
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.False:
                    nd['false'] = false;
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.Dynamic:
                    nd.dynamic = true;
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.Final:
                    nd.final = true;
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.Native:
                    nd.native = true;
                    var ts1=tl (ts),nd1= nd;
                    break;
                case Token.Public:
                case Token.Internal:
                case Token.Intrinsic:
                    var tmp = reservedNamespace (ts);
	                var ts1=tmp[0], nd1=tmp[1];
                    nd.ns = nd1;
                    var ts1=ts1,nd1= nd;
                    break;
                default:
                    var tmp = primaryName (ts);
	                var ts1=tmp[0], nd1=tmp[1];
                    nd.ns = cx.evalIdentExprToNamespace (nd1);
                    var ts1=ts1,nd1= nd;
                    break;
                }
                break;
            case localBlk:
                var ts1=ts,nd1=nd;
                break;
            default:
                throw "error attribute tau " + tau;
            }

            Debug.exit("Parser::attribute ", ts1);
            return [ts1,nd1];
        }


        // PRAGMAS

        function pragmas (ts: TokenStream)
            : Array //[TokenStream]
        {
            Debug.enter("Parser::pragmas ", ts);

            while (hd (ts)===Token.Use || hd (ts)===Token.Import) {
                //[ts] = pragma (ts);
                ts = pragma (ts) [0];
                ts = semicolon (ts,fullStmt);
            }

            var ts1 = ts;

            Debug.exit("Parser::pragmas ", ts1);
            return [ts1];
        }

        function pragma (ts: TokenStream)
            : Array //[TokenStream]
        {
            Debug.enter("Parser::pragma ", ts);

            countLn();
            printLn(ts);

            switch (hd (ts)) {
            case Token.Use:
                var tmp = pragmaItems (tl (ts));
                var ts1=tmp[0];
                break;
            case Token.Import:
                var tmp = importName (tl (ts));
                var ts1=tmp[0];
                break;
            }

            Debug.exit("Parser::pragma ", ts1);
            return [ts1];
        }

        function pragmaItems (ts: TokenStream)
            : Array //[TokenStream]
        {
            Debug.enter("Parser::pragmaItems ", ts);

            var ts1 = ts;

            while (true) {
            switch (hd (ts1)) {
            case Token.Decimal:
                break;
            case Token.Namespace:
                var tmp = primaryName (tl (ts1));
                var ts1=tmp[0], nd1=tmp[1];
                cx.openNamespace (nd1);
                break;
            case Token.Double:
                break;
            case Token.Int:
                break;
            case Token.Default:
                switch (hd2 (ts1)) {
                case Token.Namespace:
                    var tmp = primaryName (tl (tl (ts1)));
	                var ts1=tmp[0], nd1=tmp[1];
                    cx.defaultNamespace (nd1);
                    cx.openNamespace (nd1);
                    break;
                default:
                    throw "unexpected token after 'use default'";
                }
                break;
                //            case Token.Number
                //                break;
            case Token.Precision:
                break;
            case Token.Rounding:
                break;
            case Token.Standard:
                break;
            case Token.Strict:
                break;
            case Token.UInt:
                break;
            case Token.Unit:
                break;
            default:
                throw "unknown token in PragmaItem";
            }

            if (hd (ts1) !== Token.Comma) {
                break;
            }

            ts1 = eat (ts1,Token.Comma);
            }

            Debug.exit("Parser::pragmaItems ", ts1);
            return [ts1];
        }

        /*

        ImportName
            PackageName  .  *
            PackageName  .  Identifier

        */

        function importName (ts: TokenStream)
            : Array //[TokenStream]
        {
            Debug.enter("Parser::importName ", ts);

            var tmp = identifier (ts);
            var ts1=tmp[0], nd1=tmp[1];
            nd1 = [nd1];
            while (hd (ts1)===Token.Dot) {
                nd1.push(Token.tokenText(tl (ts1).head()));
                ts1 = tl (ts1);
            }

            var ns = namespaceFromPath (nd1);
            cx.openNamespace (ns);

            Debug.exit("Parser::importName ", ts1);
            return [ts1];

            function namespaceFromPath (path) 
            {
                var str = "";
                for (var i=0; i<path.length-1; ++i) { // -1 to skip last ident
                    if (i!=0) 
                        str = str + ".";
                    str = str + path[i];
                }

                return new ReservedNamespace (new PublicNamespace (str));  // FIXME ReservedNamespace is a misnomer
            }

        }

        // BLOCKS and PROGRAMS

        function block (ts:TokenStream, tau: ITau)
            : Array //[TokenStream, BLOCK]
        {
            Debug.enter("Parser::block ",ts);

            ts = eat (ts, Token.LeftBrace);
            cx.enterLetBlock ();
            var tmp = directives (ts, tau);
            var ts1=tmp[0], nd1=tmp[1];
            var head = cx.exitLetBlock ();
            ts1 = eat (ts1, Token.RightBrace);

            Debug.exit("Parser::block ", ts1);
            return [ts1, new Block (head,nd1)];
        }

        public function program ()
            : Array //[TokenStream, PROGRAM]
        {
            Debug.enter("Parser::program ","");

            var tmp = scan.tokenList (scan.start);
            var ts=tmp[0], cs=tmp[1];
            coordList = cs;
            ts = new TokenStream (ts);

            cx.enterVarBlock ();
            var publicNamespace = new ReservedNamespace (new PublicNamespace (""));
            cx.openNamespace (publicNamespace);
            cx.defaultNamespace (publicNamespace);

            if (hd (ts) == Token.Internal || 
                hd (ts) == Token.Package)
            {
                var tmp = packages (ts);
                var ts1=tmp[0], nd1=tmp[1];
            }
            else
            {
                var ts1=ts, nd1= [];
            }

            currentPackageName = "";
            currentClassName = "";

            cx.enterLetBlock ();
            var tmp = directives (ts1, globalBlk);
            var ts2=tmp[0], nd2=tmp[1];
            var bhead = cx.exitLetBlock ();
            var vhead = cx.exitVarBlock ();

            switch (hd (ts2)) {
            case Token.EOS:
                break;
            default:
                throw "extra tokens after end of program: " + ts2;
            }

            Debug.exit("Parser::program ", ts2);
            return [ts2, new Program (nd1,new Block (bhead,nd2),vhead)];
        }

    function test ()
    {
        var programs =
            [ "print('hi')"
              // , readFile ("./tests/self/t.es")
              /*
            , "x<y"
            , "x==y"
            , "m-n;n+m"
            , "10"
            , "p.q.r.x"
            , "q::id"
            , "f() ()"
            , "new A()"
            , "(new Fib(n-1)).val + (new Fib(n-2)).val"
            , "var x = 10, y = 20"
            , "var x = 10; var y"
            , "if (x) y; else z"
            , "new new x (1) (2) . x"
            , "var x : int = 10; var y: string = 'hi'"
            , "function f(x,y,z) { return 10 }"
            , "new new y"
            , "z (1) (2)"
            , "new new x (1) (2)"
            , "new new x (1) (2) . x"
            , "let x = 10"
            , "let const x"
            , "const x"
            , "x.y.z"
            , "while (x) { print(x); x-- }"
            , "function f (x=10) { return x }"
            , "function f (x) { return x }"
              , "x = y"
            , readFile ("./tests/self/prime.es")
              */
              /*
            , "class A { function A() {} }"
            , "class Fib { function Fib (n) { } }"
            , readFile ("./tests/self/hello.es")
            "a .< t .< u .< v > , w .< x > > > >",
            "q::[expr]",
            "(expr)::id",
            "(expr)::[expr]",
            "@a",
            "@q::id",
            "@q::[expr]",
            "@(expr)::id",
            "@(expr)::[expr]",
            "@[expr]",
            "/abcdefg/g",
            "/abcdefg/",
            "/abcdefg/i",
            "/abcdefg/x",
            "true",
            "false",
            "null",
            "(a)::x",
            "(function(a,b,c){})",
            "{x:a,y:b,z:c}",
            "[a,b,c]",
            "{(x):y}",
            "(function(){})",
            "(function f(a:A,b:B){})",
            "(function f.<T,U,V>(a:T,b:U,c:V){})",

            // type expressions

            "T",
            "?T",
            "T!",
            "T~",
            "T.<U>",
            "T.<U.<V>>",
            "T.<{a:A,t:{i:I,s:S}}>",
            "T.<{x:[A,B,C]}>",
            "T.<{x:(A,B,C)}>",
            "T.<U.<V.<W.<[,,,]>>>>",
            "T.<U>!",
            "?T.<U>",

            // Postfixx expressions

            "x.y",
            "new x",
            "new x()",
            "x()",
            "x.y()",
            "x++",
            "x--",
            "x.y++",
            "x.y()++",
            "new x.y++",
            */
        ]

        var n = 0;
            //        for each ( var p in programs )
        for (;n<programs.length;n++)
        {
//            var p = programs[n];
//            try {
//                var parser = new Parser(p,{});
//                var tmp = parser.program ();
//                var ts1=tmp[0], nd1=tmp[1];
//
//                //                dumpABCFile(cogen.cg(nd1), "hello-test.es");
//
//                var tx1 = Encode::program (nd1);
//                print(n, "-1> ", p, tx1);
//                var nd2 = Decode::program (eval("("+tx1+")"));
//                var tx2 = Encode::program (nd2);
//                print(n, "-2> ", p, tx2);
//
//                print("tx1.length=",tx1.length);
//                print("tx2.length=",tx2.length);
//                for (var i = 0; i < tx1.length; ++i) {
//                    if (tx1[i] != tx2[i]) throw "error at pos "+i+" "+tx1[i]+ " != "+tx2[i]+" prefix: "+tx1.slice(i,tx1.length);
//                }
//                print("txt==tx2");
//            }
//            catch(x)
//            {
//                print(x)
//            }
        }
    } // function
  }// class
} // package

	import com.hurlant.eval.ast.*;
	import com.hurlant.eval.parse.Token;
	import com.hurlant.eval.Debug;
	import com.hurlant.eval.Util;
	
	interface IParserPattern	{}

    class FieldPattern {
//        use default namespace public;
        public var ident: IAstIdentExpr;
        public var ptrn: IParserPattern;
        function FieldPattern (ident,ptrn) {
        	this.ident = ident;
        	this.ptrn = ptrn;
        }
    }

    class ObjectPattern implements IParserPattern {
        var ptrns //: Array;
        function ObjectPattern (ptrns) {
        	this.ptrns = ptrns;
        }
    }

    class ArrayPattern implements IParserPattern { 
        var ptrns //: PATTERNS;
        function ArrayPattern (ptrns) {
        	this.ptrns = ptrns;
        }
    }

    class SimplePattern implements IParserPattern 
    {
        var expr : IAstExpr;
        function SimplePattern (expr) {
        	this.expr = expr;
        }
    }

    class IdentifierPattern implements IParserPattern 
    {
        var ident : String;
        function IdentifierPattern (ident) {
        	this.ident = ident;
        }
    }

	interface IAlpha {}
	class NoColon implements IAlpha {}
    class AllowColon implements IAlpha {}
    interface IBeta {}
    class NoIn implements IBeta {}
    class AllowIn implements IBeta {}
    interface IGamma {}
    class NoExpr implements IGamma {}
    class AllowExpr implements IGamma {}
    interface ITau {}
    class GlobalBlk implements ITau {}
    class ClassBlk implements ITau {}
    class InterfaceBlk implements ITau {}
    class LocalBlk implements ITau {}
    interface IOmega {}
    class FullStmt implements IOmega {}
    class AbbrevStmt implements IOmega {}

    class Context
    {
        //use default namespace public;
        public var env: Array; //ENV;
        public var varHeads  //: [HEAD];
        public var letHeads  //: [HEAD];
        public var ctor: Constructor;
        public var pragmas: Pragmas;
        public var pragmaEnv: Array; //PRAGMA_ENV; // push one PRAGMAS for each scope

        function Context (topFixtures) {
        	env = [topFixtures];
        	varHeads = [];
        	letHeads = [];
        	ctor = null;
        	pragmas = null;
        	pragmaEnv = [];
            //print ("topFixtures.length=",topFixtures.length);
            //            print ("env[0].length=",env[0].length);
        }

        function enterVarBlock () 
        {
            //use namespace Ast;
            Debug.enter("enterVarBlock");
            var varHead = new Head ([],[]);
            this.varHeads.push(varHead);
            this.env.push (varHead.fixtures);
            this.pragmas = new Pragmas (this.pragmas);
            this.pragmaEnv.push (this.pragmas);
            Debug.exit("exitVarBlock");
        }

        function exitVarBlock () 
        {
            Debug.enter("exitVarBlock");
            var varHead = this.varHeads.pop ();
            this.env.pop ();
            this.pragmaEnv.pop ();
            if (this.pragmaEnv.length === 0) {
                this.pragmas = null;
            }
            else {
                this.pragmas = this.pragmaEnv[this.pragmaEnv.length-1];
            }
            Debug.exit("exitVarBlock");
            return varHead;
        }

        function hasFixture (fxtrs,fb) {
            //use namespace Ast;
            //var [fn,f1] = fb;
            var fn = fb[0], f1 = fb[1];
            
            var x = fn;
            if (x is PropName) {
                if (hasName (fxtrs,fn.name.id,fn.name.ns)) {
                    //print("hasName ",ns,"::",id);
                    var f2 = getFixture (fxtrs,fn.name.id,fn.name.ns);
                    if (f1 is ValFixture && f2 is ValFixture) {
                        if (f1.type==Ast.anyType) return true;
                        else if (f2.type==Ast.anyType) return true;
                        // other positive cases here
                    }
                    throw "incompatible fixture redef "+fn.id;
                }
            } else if (x is TempName) {
                return false;  // for now
            }
        }

        function addVarFixtures (fxtrs, isStatic=false) 
        {
            var varHead = this.varHeads[this.varHeads.length-(isStatic?2:1)];
            for (var n = 0, len = fxtrs.length; n < len; ++n)  // until array conact works
            {
                var fb = fxtrs[n];
                /// if (!hasFixture (varHead.fixtures,fb)) {
                    varHead.fixtures.push (fxtrs[n]);
                /// }
            }
        }

        function addVarInits (inits, isStatic=false) 
        {
            var varHead = this.varHeads[this.varHeads.length-(isStatic?2:1)];
            for (var n = 0, len = inits.length; n < len; ++n)  // until array conact works
                varHead.exprs.push (inits[n]);
        }

        function enterLetBlock () 
        {
            Debug.enter("enterLetBlock");
            var letHead = new Head ([],[]);
            this.letHeads.push(letHead);
            this.env.push (letHead.fixtures);
            this.pragmas = new Pragmas (this.pragmas);
            this.pragmaEnv.push (this.pragmas);
            Debug.exit("enterLetBlock");
        }

        function exitLetBlock () 
        {
            Debug.enter("exitLetBlock");
            var letHead = this.letHeads.pop ();
            this.env.pop ();
            this.pragmaEnv.pop ();
            this.pragmas = this.pragmaEnv[this.pragmaEnv.length-1];
            Debug.exit("exitLetBlock");
            return letHead;
        }

        function addLetFixtures (fxtrs) 
        {
            var letHead = this.letHeads[this.letHeads.length-1];
            for (var n = 0, len = fxtrs.length; n < len; ++n)  // until array conact works
                letHead.fixtures.push (fxtrs[n]);
        }

        function addLetInits (inits) 
        {
            var letHead = this.letHeads[this.letHeads.length-1];
            for (var n = 0, len = inits.length; n < len; ++n)  // until array conact works
                letHead.exprs.push (inits[n]);
        }

        function openNamespace (nd: IAstIdentExpr) {
            Debug.enter("openNamespace");
            var ns = evalIdentExprToNamespace (nd);
            //print("this.pragmas=",this.pragmas);
            var opennss = this.pragmas.openNamespaces;
            //print ("opennss=",opennss);
            //print ("opennss.length=",opennss.length);
            //print ("adding ns ",ns);
            opennss[opennss.length-1].push (ns);
            Debug.exit("openNamespace");
        }

        function defaultNamespace (nd: IAstIdentExpr) {
            Debug.enter("defaultNamespace");
            var ns = evalIdentExprToNamespace (nd);
            this.pragmas.defaultNamespace = ns;
            Debug.exit("defaultNamespace");
        }

        function hasName (fxtrs,id,ns) 
        {

            Debug.enter("hasName ",id);
            if (fxtrs.length==0)
            {
                Debug.exit("hasName false");
                return false;
            }

            var pn = fxtrs[0][0];
            //print ("pn",pn," is PropName",pn is PropName);
            //print ("pn.name",pn.name);
            //print ("pn..id=",pn.name.id," id=",id);
            //print ("pn..ns=",pn.name.ns.hash()," ns=",ns.hash());
            if (pn.name.id==id && pn.name.ns.hash()==ns.hash())  // FIXME: need ns compare
            {
                Debug.exit("hasName true");
                return true;
            }
            else 
            {
                Debug.exit("hasName looking");
                return hasName (fxtrs.slice (1,fxtrs.length),id,ns);
            }
        }

        function getFixture (fxtrs,id,ns) 
        {

            Debug.enter("getFixture ");
            if (fxtrs.length===0) 
            {
                throw "name not found " + ns + "::" + id;
            }

            var pn = fxtrs[0][0];
            if (pn.name.id==id && pn.name.ns.toString()==ns.toString()) 
            {
                Debug.exit("getFixture");
                return fxtrs[0];
            }
            else 
            {
                Debug.exit("getFixture");
                return getFixture (fxtrs.slice (1,fxtrs.length),id,ns);
            }
        }

        /*

        two dimensional search

        repeat for each shadowed name
            each name in each head
                dup is error

        for each namespace set
            find all names in the inner most head

        */

        function findFixtureWithNames (id,nss, it: IAstInitTarget ?) {
            Debug.enter("findFixtureWithNames");

            var env = this.env;

            switch (it) {
            case Ast.instanceInit:
                var start = env.length-2;
                var stop = start;
                break;
            case null:
                var start = env.length-1;
                var stop = 0;
                break;
            default:
                throw "error findFixtureWithName: unimplemented target";
            }

            //print ("env.length=",env.length);
            for (var i=start; i>=stop; --i)   // for each head
            {
                var ns = null;
                var fxtrs = env[i];
                //print ("nss.length=",nss.length);
                for (var j=nss.length-1; j>=0; --j) {
                    //print ("nss[",j,"]=",nss[j]);
                    if (hasName (fxtrs,id,nss[j])) {
                        if (ns !== null) {
                            throw "ambiguous reference to " + id;
                        }
                        ns = nss[j];
                    }
                }
                if (ns!==null) {
                    Debug.exit("findFixtureWithNames");
                    return getFixture (fxtrs,id,ns);
                }
            }

            Debug.exit("findFixtureWithNames");
            return null;
        }

        function findFixtureWithIdentifier (id: String, it: IAstInitTarget ?)
        {
            Debug.enter("findFixtureWithIdentifier ", id);
            //print ("this.pragmas=",this.pragmas);
            var nsss = this.pragmas.openNamespaces;
            //print ("nsss.length=",nsss.length);
            for (var i=nsss.length-1; i>=0; --i) 
            {
                //print ("nsss[",i,"]=",nsss[i]);
                var fx = findFixtureWithNames (id,nsss[i],it);
                if (fx !== null) 
                {
                    Debug.exit("findFixtureWithIdentifier");
                    return fx;
                }
            }
            throw "fixture not found: " + id;
        }

        function evalIdentExprToNamespace (nd: IAstIdentExpr)
            : IAstNamespace
        {

            Debug.enter("evalIdentExprToNamespace");

            var fxtr = null;
            var val = null;

			var x = nd;
			if (x is Identifier) {
                var fxtr = findFixtureWithIdentifier ((nd as Identifier).ident,null);
                var x2 = fxtr[1];
                if (x2 is NamespaceFixture) {
                    var val = fxtr.ns;
                    return fxtr.ns;
                } else {
                    throw "fixture with unknown value " + fxtr;
                }
            } else if (x is ReservedNamespace) {
                var val = (nd as ReservedNamespace).ns;
                return val;
            } else {
                throw "evalIdentExprToNamespace: case not implemented " + nd;
            }
            Debug.exit("evalIdentExprToNamespace ", val);
            return val;
        }

        function resolveIdentExpr (nd: IAstIdentExpr, it: IAstInitTarget )
            : IAstFixtureName
        {
            Debug.enter("resolveIdentExpr");
            
            var x = nd;
            if (x is Identifier) {
                var fxtr = findFixtureWithIdentifier ((nd as Identifier).ident, it);
            } else {
                throw "resolveIdentExpr: case not implemented " + nd;
            }
            Debug.exit("resolveIdentExpr ", fxtr);
            return fxtr[0];
        }
    }

    //type TOKENS = TokenStream;  // [int];

    class TokenStream {
        import flash.utils.*;
        var ts: ByteArray
        var n: int;
        var current_tok;
        function TokenStream (ts) {
        	this.ts = ts;
        	n = 0;
            ts.position = n;
        }
        
        function head () : int {
            //print("head ts.position ",ts.position," n ",n);
            if (ts.position == n) {
                current_tok = ts.readInt ();
                //print ("current_tok ",current_tok);
            }
            Util.assert (ts.position == n+4);
            return current_tok;
        }
        
        function head2 () : int {
            //print("head2 ts.position ",ts.position," n ",n);
            if (ts.position == n) {
                current_tok = ts.readInt ();
                //print ("current_tok ",current_tok);
            }
            Util.assert (ts.position == n+4);
            var pos = ts.position;
            var tk = ts.readInt ();
            ts.position = pos;
            return tk;
        }
        
        function next () : void {
            n = n + 4;
            head ();
            //print ("next n",n);
        }

        public function toString () { return Token.tokenText(this.head()) }
    }

    class Pragmas 
    {
        //use default namespace public;
        public var openNamespaces //: [[IAstNamespace]];
        public var defaultNamespace: IAstNamespace;
        function Pragmas (pragmas) 
        {
            Debug.enter("Pragma ",pragmas);
            if (pragmas==null)
            {
                this.openNamespaces = [[]];
                this.defaultNamespace = new PublicNamespace ("");
            }
            else
            {
                this.openNamespaces = Util.copyArray (pragmas.openNamespaces);
                this.defaultNamespace = pragmas.defaultNamespace;
            }

            if (this.openNamespaces[this.openNamespaces.length-1].length !== 0) { 
                this.openNamespaces.push ([]);  // otherwise reuse the last one pushed
            }
            Debug.exit("Pragma");
        }
    }


// more stubs for functions that are mysteriously missing.
// [HOW THE FARK IS THIS STUFF EVER SUPPOSED TO COMPILE?? ]
function brackets(ts:TokenStream):Array {
	throw new Error("not implemented.");
	return [ts,null];
}
function expressionQualifiedIdentifier(ts:TokenStream):Array {
	throw new Error("not implemented.");
	return [ts,null];
}
function functionType(ts:TokenStream):Array {
	throw new Error("not implemented.");
	return [ts,null];
}
function letExpression(ts:TokenStream, beta:IBeta):Array {
	throw new Error("not implemented.");
	return [ts,null];
}
// http://wiki.ecmascript.org/doku.php?id=proposals:local_packages
function packages(ts:TokenStream):Array {
	throw new Error("not implemented.");
	return [ts,null];
}
function primaryNameList(ts:TokenStream):Array {
	throw new Error("not implemented.");
	return [ts,null];
}
function restParameter(ts:TokenStream, n:int):Array {
	throw new Error("not implemented.");
	return [ts,null];
}
function superExpression(ts:TokenStream):Array {
	throw new Error("not implemented.");
	return [ts,null];
}
function yieldExpression(ts:TokenStream, beta:IBeta):Array {
	throw new Error("not implemented.");
	return [ts,null];
}