module Language.Lang exposing (..)

import Html exposing (pre, span, text)
import Html.Attributes exposing (style)
import Language.Common as Common


type Indent
    = SameLine
    | Indent Int


type ExprF a
    = Superimposed { indent : Indent, expr : a }
    | ListOf (List a)
    | Moved { x : Int, y : Int, indent : Indent, expr : a }
    | Filled { color : Common.Color, indent : Indent, expr : a }
    | Outlined { color : Common.Color, indent : Indent, expr : a }
    | Circle { radius : Int }
    | Rectangle { width : Int, height : Int }
    | Paren { indent : Indent, expr : a }


type Expr
    = Expr (ExprF Expr)



--


example : Expr
example =
    superimposed
        { indent = Indent 1
        , expr =
            listOf
                [ moved
                    { x = 200
                    , y = 100
                    , indent = Indent 1
                    , expr =
                        paren
                            { indent = SameLine
                            , expr =
                                filled
                                    { color = Common.Blue
                                    , indent = SameLine
                                    , expr =
                                        paren
                                            { indent = SameLine
                                            , expr = rectangle { width = 50, height = 30 }
                                            }
                                    }
                            }
                    }
                , moved
                    { x = 100
                    , y = 100
                    , indent = Indent 1
                    , expr =
                        paren
                            { indent = SameLine
                            , expr =
                                outlined
                                    { indent = SameLine
                                    , color = Common.Red
                                    , expr =
                                        paren
                                            { indent = SameLine
                                            , expr = circle { radius = 20 }
                                            }
                                    }
                            }
                    }
                ]
        }


indentSpan : String -> Indent -> Int -> String
indentSpan sameLineCase indent indentLevel =
    case indent of
        SameLine ->
            sameLineCase

        Indent n ->
            "\n" ++ String.repeat (indentLevel + n) "    "


indexedConcatMap : (Int -> a -> List b) -> List a -> List b
indexedConcatMap f =
    List.indexedMap f >> List.concat


addIndent : Indent -> Int
addIndent indent =
    case indent of
        SameLine ->
            0

        Indent n ->
            n


toSpansAlg : ExprF (Int -> List String) -> Int -> List String
toSpansAlg e indentLevel =
    case e of
        Superimposed { indent, expr } ->
            List.concat
                [ [ "superimposed" ]
                , expr (indentLevel + addIndent indent)
                ]

        ListOf exprs ->
            let
                indent =
                    Indent 0
            in
            List.concat
                [ indexedConcatMap
                    (\index renderExpr ->
                        let
                            prefix =
                                if index == 0 then
                                    if indent == SameLine then
                                        "["

                                    else
                                        "[ "

                                else
                                    ", "
                        in
                        indentSpan "" indent indentLevel
                            :: prefix
                            :: renderExpr (indentLevel + addIndent indent)
                    )
                    exprs
                , [ indentSpan " " indent indentLevel
                  , "]"
                  ]
                ]

        Moved { indent, x, y, expr } ->
            List.concat
                [ [ "moved"
                  , " "
                  , String.fromInt x
                  , " "
                  , String.fromInt y
                  , indentSpan " " indent indentLevel
                  ]
                , expr (indentLevel + addIndent indent)
                ]

        Filled { indent, color, expr } ->
            List.concat
                [ [ "filled"
                  , " "
                  , "\"" ++ Common.colorName color ++ "\""
                  , indentSpan " " indent indentLevel
                  ]
                , expr (indentLevel + addIndent indent)
                ]

        Outlined { indent, color, expr } ->
            List.concat
                [ [ "outlined"
                  , " "
                  , "\"" ++ Common.colorName color ++ "\""
                  , indentSpan " " indent indentLevel
                  ]
                , expr (indentLevel + addIndent indent)
                ]

        Circle { radius } ->
            [ "circle", " ", String.fromInt radius ]

        Rectangle { width, height } ->
            [ "rectangle", " ", String.fromInt width, " ", String.fromInt height ]

        Paren { indent, expr } ->
            List.concat
                [ [ "("
                  , indentSpan "" indent indentLevel
                  ]
                , expr (indentLevel + addIndent indent)
                , [ indentSpan ""
                        (case indent of
                            SameLine ->
                                SameLine

                            Indent _ ->
                                Indent 0
                        )
                        indentLevel
                  , ")"
                  ]
                ]



--


map : (a -> b) -> ExprF a -> ExprF b
map f constructor =
    case constructor of
        Superimposed info ->
            Superimposed
                { indent = info.indent
                , expr = f info.expr
                }

        ListOf exprs ->
            ListOf (List.map f exprs)

        Moved info ->
            Moved
                { indent = info.indent
                , x = info.x
                , y = info.y
                , expr = f info.expr
                }

        Filled info ->
            Filled
                { indent = info.indent
                , color = info.color
                , expr = f info.expr
                }

        Outlined info ->
            Outlined
                { indent = info.indent
                , color = info.color
                , expr = f info.expr
                }

        Paren info ->
            Paren
                { indent = info.indent
                , expr = f info.expr
                }

        Circle info ->
            Circle info

        Rectangle info ->
            Rectangle info


cata : (ExprF a -> a) -> Expr -> a
cata algebra (Expr expr) =
    expr
        |> map (cata algebra)
        |> algebra



--


superimposed : { indent : Indent, expr : Expr } -> Expr
superimposed info =
    Expr (Superimposed info)


listOf : List Expr -> Expr
listOf exprs =
    Expr (ListOf exprs)


moved : { indent : Indent, x : Int, y : Int, expr : Expr } -> Expr
moved info =
    Expr (Moved info)


filled : { indent : Indent, color : Common.Color, expr : Expr } -> Expr
filled info =
    Expr (Filled info)


outlined : { indent : Indent, color : Common.Color, expr : Expr } -> Expr
outlined info =
    Expr (Outlined info)


circle : { radius : Int } -> Expr
circle info =
    Expr (Circle info)


rectangle : { width : Int, height : Int } -> Expr
rectangle info =
    Expr (Rectangle info)


paren : { indent : Indent, expr : Expr } -> Expr
paren info =
    Expr (Paren info)



--


main =
    example
        |> cata toSpansAlg
        |> (|>) 0
        |> List.map
            (\sp ->
                span [ style "box-shadow" "inset 0 0 0 1px lightgray" ] [ text sp ]
            )
        |> pre []
