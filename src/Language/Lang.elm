module Language.Lang exposing (..)

import Html exposing (pre, span, text)
import Html.Attributes exposing (style)
import Language.Common as Common
import List.Extra as List
import Parser.Advanced exposing (..)
import Result.Extra as Result


type Indent
    = SameLine
    | Indent Int


type Indented a
    = Indented { indent : Indent, expr : a }


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
        Superimposed (Indented { indent, expr }) ->
            List.concat
                [ [ "superimposed"
                  , indentSpan " " indent indentLevel
                  ]
                , expr (indentLevel + addIndent indent)
                ]

        ListOf [] ->
            [ "[]" ]

        ListOf exprs ->
            let
                indent =
                    Indent 0
            in
            List.concat
                [ indexedConcatMap
                    (\index (Indented info) ->
                        let
                            renderExpr =
                                info.expr
                        in
                        List.concat
                            [ if index == 0 then
                                if indent == SameLine then
                                    [ "[" ]

                                else
                                    [ "[ " ]

                              else
                                [ indentSpan "" indent indentLevel
                                , ", "
                                ]
                            , renderExpr (indentLevel + addIndent indent)
                            ]
                    )
                    exprs
                , [ indentSpan " " indent indentLevel
                  , "]"
                  ]
                ]

        Moved { x, y } (Indented { indent, expr }) ->
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

        Filled { color } (Indented { indent, expr }) ->
            List.concat
                [ [ "filled"
                  , " "
                  , "\"" ++ Common.colorName color ++ "\""
                  , indentSpan " " indent indentLevel
                  ]
                , expr (indentLevel + addIndent indent)
                ]

        Outlined { color } (Indented { indent, expr }) ->
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

        Paren (Indented { indent, expr }) ->
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
mapI f (Indented { indent, expr }) =
    Indented
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
    Expr (Superimposed (Indented info))


listOf : List (Indented Expr) -> Expr
listOf exprs =
    Expr (ListOf exprs)


listOfUnindented : List Expr -> Expr
listOfUnindented exprs =
    Expr (ListOf (List.map (\e -> Indented { indent = SameLine, expr = e }) exprs))


moved : { x : Int, y : Int } -> { indent : Indent, expr : Expr } -> Expr
moved info expr =
    Expr (Moved info (Indented expr))


filled : { color : Common.Color } -> { indent : Indent, expr : Expr } -> Expr
filled info expr =
    Expr (Filled info (Indented expr))


outlined : { color : Common.Color } -> { indent : Indent, expr : Expr } -> Expr
outlined info expr =
    Expr (Outlined info (Indented expr))


circle : { radius : Int } -> Expr
circle info =
    Expr (Circle info)


rectangle : { width : Int, height : Int } -> Expr
rectangle info =
    Expr (Rectangle info)


paren : { indent : Indent, expr : Expr } -> Expr
paren info =
    Expr (Paren (Indented info))



--


main =
    exampleParsed
        |> cata toSpansAlg
        |> (|>) 0
        |> List.map
            (\sp ->
                span [ style "box-shadow" "inset 0 0 0 1px lightgray" ] [ text sp ]
            )
        |> pre []



-- PARSING


exampleCode =
    """superimposed
    [ moved 200 100
        (filled "blue"
            (rectangle 50 30))
    , moved 100 100
        (outlined "red" (circle 20))
    , moved 300 100
        (outlined "red" (
            circle 20
        ))
    ]"""


exampleParsed =
    case
        exampleCode
            |> run (parseExpr |. end "Expecting end of input")
            |> Result.mapError (Common.explainErrors exampleCode)
    of
        Ok result ->
            result

        Err str ->
            Debug.todo str


parseExpr : Common.Parser Expr
parseExpr =
    lazy <|
        \_ ->
            Common.usingPosition
                (\position ->
                    oneOf
                        [ succeed Superimposed
                            |. Common.tokens.superimposed
                            |= parseIndented position parseExpr
                            |> map Expr
                            |> inContext "in a 'superimposed' expression"
                        , parseListOf
                        , succeed (\x y -> Moved { x = x, y = y })
                            |. Common.tokens.moved
                            |. whitespace
                            |= Common.parseInt
                            |. whitespace
                            |= Common.parseInt
                            |= parseIndented position parseExpr
                            |> map Expr
                            |> inContext "in a 'moved' expression"
                        , succeed (\color -> Filled { color = color })
                            |. Common.tokens.filled
                            |. whitespace
                            |= Common.parseColor
                            |= parseIndented position parseExpr
                            |> map Expr
                            |> inContext "in a 'filled' expression"
                        , succeed (\color -> Outlined { color = color })
                            |. Common.tokens.outlined
                            |. whitespace
                            |= Common.parseColor
                            |= parseIndented position parseExpr
                            |> map Expr
                            |> inContext "in a 'outlined' expression"
                        , succeed (\width height -> Rectangle { width = width, height = height })
                            |. Common.tokens.rectangle
                            |. whitespace
                            |= Common.parseInt
                            |. whitespace
                            |= Common.parseInt
                            |> map Expr
                            |> inContext "in a 'rectangle' expression"
                        , succeed (\radius -> Circle { radius = radius })
                            |. Common.tokens.circle
                            |. whitespace
                            |= Common.parseInt
                            |> map Expr
                            |> inContext "in a 'circle' expression"
                        , succeed Paren
                            |. token (Token "(" "Expected an open parenthesis")
                            |= parseIndented position parseExpr
                            |. whitespace
                            |. token (Token ")" "Expected closing parenthesis")
                            |> map Expr
                        ]
                )


parseIndented : ( Int, Int ) -> Common.Parser a -> Common.Parser (Indented a)
parseIndented ( rowBefore, _ ) parseInner =
    succeed identity
        |. whitespace
        |= Common.usingPosition
            (\( rowAfter, _ ) ->
                parseInner
                    |> map
                        (\expr ->
                            Indented
                                { indent =
                                    if rowBefore == rowAfter then
                                        SameLine

                                    else
                                        Indent 1
                                , expr = expr
                                }
                        )
            )



-- PARSE LISTS


parseListOf : Common.Parser Expr
parseListOf =
    loop { revElements = [], index = 1 } parseElementsHelp
        |> inContext "a list"


type alias ListState =
    { revElements : List (Indented Expr)
    , index : Int
    }


parseElementsHelp : ListState -> Common.Parser (Step ListState Expr)
parseElementsHelp { revElements, index } =
    oneOf
        [ backtrackable
            (parseElement index
                |> map
                    (\elem ->
                        { revElements = elem :: revElements
                        , index = index + 1
                        }
                            |> Loop
                    )
            )
        , succeed (Expr (ListOf (List.reverse revElements)) |> Done)
            |. token (Token "]" "Expected end of list ']'")
            |. whitespace
        ]


parseElement : Int -> Common.Parser (Indented Expr)
parseElement index =
    succeed (\expr -> Indented { indent = SameLine, expr = expr })
        |. (if index == 1 then
                token (Token "[" "Expected start of list ']'")

            else
                token (Token "," "Expected list separator ','")
           )
        |. whitespace
        |= parseExpr
        |. whitespace
        |> inContext ("the " ++ String.fromInt index ++ ". list element")



-- PARSE HELPER


whitespace : Common.Parser String
whitespace =
    chompWhile (\c -> c == ' ' || c == '\n')
        |> getChompedString
