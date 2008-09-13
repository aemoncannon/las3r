/* -*- mode: java; mode: font-lock; tab-width: 4; insert-tabs-mode: nil; indent-tabs-mode: nil -*- */
import com.hurlant.eval.ast.Block;
import com.hurlant.eval.ast.Head;
import com.hurlant.eval.ast.IAstBinOp;
import com.hurlant.eval.ast.IAstBindingIdent;
import com.hurlant.eval.ast.IAstExpr;
import com.hurlant.eval.ast.IAstFixture;
import com.hurlant.eval.ast.IAstFuncNameKind;
import com.hurlant.eval.ast.IAstIdentExpr;
import com.hurlant.eval.ast.IAstInitTarget;
import com.hurlant.eval.ast.IAstPragma;
import com.hurlant.eval.ast.IAstTypeExpr;
import com.hurlant.eval.ast.IAstUnaryOp;

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

/* ast.es */

public namespace Ast

{
    use default namespace Ast;
    //    use namespace intrinsic;

    // Pos

    type Pos =
       { file: String
       , span: int //StreamPos.span
       , sm: int // StreamPos.sourcemap
       , post_newline: Boolean }

    // BASIC TYPES

    type String = String;   // unicode string
    type IDENTS = [String];

    //type HEAD = Head;
    // use ast.Head


    type IAstFixtureName  =
       ( TempName
       , PropName )

    type FIXTURE_BINDING = [IAstFixtureName ,IAstFixture ];
    type FIXTURES = [FIXTURE_BINDING];

    type INIT_BINDING = [IAstFixtureName ,IAstExpr]
    type INITS = [INIT_BINDING];

    type NAMES = [NAME];
    type NAME =
       { ns: IAstNamespace
       , id: String }

    type MULTINAME =
       { nss: [[IAstNamespace]]
       , id: String }

    // IAstNamespace
/*
    type NAMESPACES = [IAstNamespace];

    type IAstNamespace =
       ( IntrinsicNamespace
       , PrivateNamespace
       , ProtectedNamespace
       , PublicNamespace
       , InternalNamespace
       , UserNamespace
       , AnonymousNamespace
       , ImportNamespace );

    type RESERVED_NAMESPACE =
       ( IntrinsicNamespace
       , PrivateNamespace
       , ProtectedNamespace
       , PublicNamespace
       , InternalNamespace );
*/

    // NUMBERS

    type NUMERIC_MODE =
       { numberType : IAstNumberType
       , roundingMode: IAstRoundingMode
       , precision: int }

    type IAstRoundingMode =
       ( Ceiling
       , Floor
       , Up
       , Down
       , HalfUp
       , HalfDown
       , HalfEven )

    // OPERATORS

    // Binary type operators

    type IAstBinTypeOp =
       ( CastOp
       , IsOp
       , ToOp )

    // Binary operators

    type IAstBinOp =
       ( Plus
       , Minus
       , Times
       , Divide
       , Remainder
       , LeftShift
       , RightShift
       , RightShiftUnsigned
       , BitwiseAnd
       , BitwiseOr
       , BitwiseXor
       , LogicalAnd
       , LogicalOr
       , InstanceOf
       , In
       , Equal
       , NotEqual
       , StrictEqual
       , StrictNotEqual
       , Less
       , LessOrEqual
       , Greater
       , GreaterOrEqual )

    /*
        ASSIGNOP
    */

    type IAstAssignOp =
       ( Assign
       , AssignPlus
       , AssignMinus
       , AssignTimes
       , AssignDivide
       , AssignRemainder
       , AssignLeftShift
       , AssignRightShift
       , AssignRightShiftUnsigned
       , AssignBitwiseAnd
       , AssignBitwiseOr
       , AssignBitwiseXor
       , AssignLogicalAnd
       , AssignLogicalOr )

    // IAstUnaryOp

    type IAstUnaryOp =
       ( Delete
       , Void
       , Typeof
       , PreIncr
       , PreDecr
       , PostIncr
       , PostDecr
       , UnaryPlus
       , UnaryMinus
       , BitwiseNot
       , LogicalNot
       , Type )

    // IAstExpr

    type Array = [IAstExpr];

    type IAstExpr =
       ( TernaryExpr
       , BinaryExpr
       , BinaryTypeExpr
       , UnaryExpr
       , TypeExpr
       , ThisExpr
       , YieldExpr
       , SuperExpr
       , LiteralExpr
       , CallExpr
       , ApplyTypeExpr
       , LetExpr
       , NewExpr
       , ObjectRef
       , LexicalRef
       , SetExpr
       , ListExpr
       , InitExpr
       , SliceExpr
       , GetTemp
       , GetParam )


    /*
    public class BinaryNumberExpr extends BinaryExpr {
        var mode : NUMERIC_MODE;
        function BinaryNumberExpr (op,e1,e2,mode)
            : mode = mode, super (op,e1,e2) {}
    }
    */

    /*
    public class UnaryNumberExpr extends UnaryExpr {
        var mode : NUMERIC_MODE;
        function UnaryNumberExpr (op,ex,mode)
            : mode = mode, super (op,ex) {}
    }
    */

    /*
    public class SetNumberExpr extends SetExpr {
        var mode : NUMERIC_MODE;
        function SetNumberExpr (op,le,re,mode)
            : mode=mode, super (op,le,re) {}
    }
    */

    type IAstInitTarget  =
       ( VarInit
       , LetInit
       , PrototypeInit
       , InstanceInit )

    // IAstIdentExpr

    type IAstIdentExpr =
       ( Identifier
       , QualifiedExpression
       , AttributeIdentifier
       , ExpressionIdentifier
       , QualifiedIdentifier
       , TypeIdentifier
       , UnresolvedPath
       , WildcardIdentifier
       , ReservedNamespace )










    // IAstLiteral

    type IAstLiteral = (
        LiteralNull,
        LiteralUndefined,
        LiteralContextDecimal,
        LiteralContextDecimalInteger,
        LiteralContextHexInteger,
        LiteralDouble,
        LiteralDecimal,
        LiteralInt,
        LiteralUInt,
        LiteralBoolean,
        LiteralString,
        LiteralArray,
        LiteralXML,
        LiteralNamespace,
        LiteralObject,
        LiteralFunction,
        LiteralRegExp
    )
    
    type LITERAL_FIELD = LiteralField;
    type Array = [LiteralField];


    type FIELD_TYPE = FieldType;
    type FIELD_TYPES = [FIELD_TYPE];

    type IAstVarDefnTag  =
        ( Const
        , Var
        , LetVar
        , LetConst )

    // CLS

    type CLS = Cls;

    // FUNC
    // use ast.Function
    
    type FUNC = Func;

    type FUNC_NAME =
       { kind : IAstFuncNameKind
       , ident : String }

    type IAstFuncNameKind =
       ( Ordinary
       , Operator
       , Get
       , Set )

    // CTOR
	// use ast.Constructor
	
    // BINDING_INIT

    type BINDING_INITS = [[BINDING],[IAstInitStep ]];

    type BINDING = Binding;

    type IAstBindingIdent =
       ( TempIdent
       , ParamIdent
       , PropIdent )

    type IAstInitStep  =
       ( InitStep
       , AssignStep )

    // IAstFixture 

    type IAstFixture  = (
        NamespaceFixture,
        ClassFixture,
        InterfaceFixture,
        TypeVarFixture,
        TypeFixture,
        MethodFixture,
        ValFixture,
        VirtualValFixture)

    // IAstTypeExpr

    type Array = [IAstTypeExpr];
    type IAstTypeExpr = (
        SpecialType,
        UnionType,
        ArrayType,
        TypeName,
        ElementTypeRef,
        FieldTypeRef,
        FunctionType,
        ObjectType,
        AppType,
        NullableType,
        InstanceType,
        NominalType
    )

    type IAstSpecialTypeKind =
        ( AnyType
        , NullType
        , UndefinedType
        , VoidType )







    type FUNC_TYPE = {
        typeParams : [String],
        params: [IAstTypeExpr],
        result: IAstTypeExpr,
        thisType: IAstTypeExpr?,
        hasRest: Boolean,
        minArgs: int
    }







    // STMTs

    type STMTS = [IAstStmt];

    type IAstStmt =
       ( EmptyStmt
       , ExprStmt
       , ClassBlock
       , ForInStmt
       , ThrowStmt
       , ReturnStmt
       , BreakStmt
       , ContinueStmt
       , BlockStmt
       , LabeledStmt
       , LetStmt
       , WhileStmt
       , DoWhileStmt
       , ForStmt
       , IfStmt
       , WithStmt
       , TryStmt
       , SwitchStmt
       , SwitchTypeStmt
       , DXNStmt )

















    type CASE = Case;
    type CASES = [CASE];





    type CATCH = Catch;
    type CATCHES = [CATCH];



    /*
        BLOCK
    */
	// use ast.Block

    type PRAGMAS = [IAstPragma];

    type IAstPragma =
        ( UseNamespace
        , UseDefaultNamespace
        , UseNumber
        , UseRounding
        , UsePrecision
        , UseStrict
        , UseStandard
        , Import )


    /*
        PACKAGE
    */


    type PACKAGE = Package;
    type PACKAGES = [PACKAGE];


    /*
        PROGRAM
    */

    type DIRECTIVES =
        { pragmas: [IAstPragma]
        , stmts: STMTS }

    type PROGRAM = Program


    function test () {
        print ("testing ast.es");
        print (new EmptyStmt);
    }

    //test();
}
