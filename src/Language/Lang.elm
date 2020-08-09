module Language.Lang exposing (..)

import Html exposing (pre, span, text)
import Html.Attributes exposing (style)
import Language.Common as Common


type Indent
    = SameLine
    | Indent Int


type Indented a
    = IndentedF { indent : Indent, expr : a }


type ExprF a
    = Superimposed a
    | ListOf (List a)
    | Moved { x : Int, y : Int } a
    | Filled { color : Common.Color } a
    | Outlined { color : Common.Color } a
    | Circle { radius : Int }
    | Rectangle { width : Int, height : Int }
    | Paren a


type Expr
    = Expr (ExprF (Indented Expr))



--


example : Expr
example =
    superimposed
        { indent = Indent 1
        , expr =
            listOfUnindented
                [ moved
                    { x = 200
                    , y = 100
                    }
                    { indent = Indent 1
                    , expr =
                        paren
                            { indent = SameLine
                            , expr =
                                filled
                                    { color = Common.Blue }
                                    { indent = SameLine
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
                    }
                    { indent = Indent 1
                    , expr =
                        paren
                            { indent = SameLine
                            , expr =
                                outlined
                                    { color = Common.Red }
                                    { indent = SameLine
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


toSpansAlg : ExprF (Indented (Int -> List String)) -> Int -> List String
toSpansAlg e indentLevel =
    case e of
        Superimposed (IndentedF { indent, expr }) ->
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
                    (\index (IndentedF info) ->
                        let
                            renderExpr =
                                info.expr

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

        Moved { x, y } (IndentedF { indent, expr }) ->
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

        Filled { color } (IndentedF { indent, expr }) ->
            List.concat
                [ [ "filled"
                  , " "
                  , "\"" ++ Common.colorName color ++ "\""
                  , indentSpan " " indent indentLevel
                  ]
                , expr (indentLevel + addIndent indent)
                ]

        Outlined { color } (IndentedF { indent, expr }) ->
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

        Paren (IndentedF { indent, expr }) ->
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


mapE : (a -> b) -> ExprF a -> ExprF b
mapE f constructor =
    case constructor of
        Superimposed expr ->
            Superimposed (f expr)

        ListOf exprs ->
            ListOf (List.map f exprs)

        Moved info expr ->
            Moved info (f expr)

        Filled info expr ->
            Filled info (f expr)

        Outlined info expr ->
            Outlined info (f expr)

        Paren expr ->
            Paren (f expr)

        Circle info ->
            Circle info

        Rectangle info ->
            Rectangle info


mapI : (a -> b) -> Indented a -> Indented b
mapI f (IndentedF { indent, expr }) =
    IndentedF
        { indent = indent
        , expr = f expr
        }


cata : (ExprF (Indented a) -> a) -> Expr -> a
cata algebra (Expr expr) =
    expr
        |> mapE (mapI (cata algebra))
        |> algebra



--


superimposed : { indent : Indent, expr : Expr } -> Expr
superimposed info =
    Expr (Superimposed (IndentedF info))


listOf : List (Indented Expr) -> Expr
listOf exprs =
    Expr (ListOf exprs)


listOfUnindented : List Expr -> Expr
listOfUnindented exprs =
    Expr (ListOf (List.map (\e -> IndentedF { indent = SameLine, expr = e }) exprs))


moved : { x : Int, y : Int } -> { indent : Indent, expr : Expr } -> Expr
moved info expr =
    Expr (Moved info (IndentedF expr))


filled : { color : Common.Color } -> { indent : Indent, expr : Expr } -> Expr
filled info expr =
    Expr (Filled info (IndentedF expr))


outlined : { color : Common.Color } -> { indent : Indent, expr : Expr } -> Expr
outlined info expr =
    Expr (Outlined info (IndentedF expr))


circle : { radius : Int } -> Expr
circle info =
    Expr (Circle info)


rectangle : { width : Int, height : Int } -> Expr
rectangle info =
    Expr (Rectangle info)


paren : { indent : Indent, expr : Expr } -> Expr
paren info =
    Expr (Paren (IndentedF info))



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
