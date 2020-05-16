module Components.Code exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class)
import Maybe.Extra as Maybe
import Parser
import SyntaxHighlight


type alias Flags =
    { language : Maybe String
    , code : String
    }


type Model
    = Highlighted (List (Html Msg))
    | NoHighlighting String
    | InteractiveJs (List { enabled : Bool, statement : Statement })


type alias Msg =
    Never


type Statement
    = Stroke
    | Fill
    | MoveTo Int Int
    | SetFillStyle Color
    | Circle Int
    | Rectangle Int Int


type Color
    = Red
    | Green
    | Blue
    | Purple
    | Yellow
    | Aqua
    | Orange
    | Magic



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( trySyntaxHighlight flags
        |> Maybe.orElse (tryInteractive flags)
        |> Maybe.withDefault (NoHighlighting flags.code)
    , Cmd.none
    )


trySyntaxHighlight : Flags -> Maybe Model
trySyntaxHighlight { language, code } =
    case language |> Maybe.andThen findHighlighter of
        Just syntaxHighlight ->
            case syntaxHighlight code of
                Ok highlightedCode ->
                    Just <|
                        Highlighted <|
                            SyntaxHighlight.toCustom highlightingStyles highlightedCode

                Err _ ->
                    Nothing

        _ ->
            Nothing


tryInteractive : Flags -> Maybe Model
tryInteractive { language, code } =
    case language of
        Just "js interactive" ->
            Just <|
                InteractiveJs
                    [ { enabled = True, statement = MoveTo 100 100 }
                    , { enabled = True, statement = SetFillStyle Red }
                    , { enabled = True, statement = Circle 20 }
                    , { enabled = False, statement = Stroke }
                    , { enabled = True, statement = MoveTo 200 100 }
                    , { enabled = False, statement = SetFillStyle Blue }
                    , { enabled = False, statement = Rectangle 50 30 }
                    , { enabled = True, statement = Fill }
                    ]

        _ ->
            Nothing


highlightingStyles =
    let
        styled clss content =
            span [ class clss ] [ text content ]
    in
    { noOperation = div []
    , highlight = div []
    , addition = div []
    , deletion = div []
    , default = text
    , comment = styled "text-gruv-gray-8 italic"

    -- numbers
    , style1 = styled "text-gruv-blue-l"

    -- Literal string, attribute value
    , style2 = styled "text-gruv-green-l"

    -- Keyword, tag, operator symbols
    , style3 = styled "text-gruv-red-l"

    -- Keyword 2, group symbols, type signature
    , style4 = styled "text-gruv-gray-12"

    -- Function, attribute name
    , style5 = styled "text-gruv-yellow-l"

    -- Literal keyword, capitalized types
    , style6 = styled "text-gruv-green-l"

    -- argument, parameter
    , style7 = styled "text-gruv-gray-12"
    }


type alias Highlighter =
    String -> Result (List Parser.DeadEnd) SyntaxHighlight.HCode


findHighlighter : String -> Maybe Highlighter
findHighlighter string =
    case string of
        "elm" ->
            Just SyntaxHighlight.elm

        "js" ->
            Just SyntaxHighlight.javascript

        _ ->
            Nothing



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update void _ =
    never void



-- VIEW


classes : List String -> Attribute msg
classes list =
    class (String.join " " list)


view : Model -> Html Msg
view model =
    pre
        [ classes
            [ "mt-4 py-6 px-8"
            , "overflow-y-auto"
            , "font-code text-base-sm code-shadow text-gruv-gray-12 bg-gruv-gray-0"
            ]
        ]
        [ code []
            (case model of
                Highlighted lines ->
                    lines

                NoHighlighting code ->
                    [ text code ]

                InteractiveJs statements ->
                    List.indexedMap viewStatement statements
            )
        ]


viewStatement : Int -> { enabled : Bool, statement : Statement } -> Html Msg
viewStatement index { enabled, statement } =
    case statement of
        Stroke ->
            viewFunction enabled "stroke" []

        Fill ->
            viewFunction enabled "fill" []

        MoveTo x y ->
            viewFunction enabled "moveTo" [ viewInt enabled x, viewInt enabled y ]

        SetFillStyle col ->
            viewFunction enabled "setFillStyle" [ viewColor enabled col ]

        Circle r ->
            viewFunction enabled "circle" [ viewInt enabled r ]

        Rectangle w h ->
            viewFunction enabled "rectangle" [ viewInt enabled w, viewInt enabled h ]


viewFunction : Bool -> String -> List (Html Msg) -> Html Msg
viewFunction enabled name attributes =
    [ [ text name
      , text "("
      ]
    , List.intersperse (text ", ") attributes
    , [ text ");"
      ]
    ]
        |> List.concat
        |> div (ifEnabledColor enabled "text-gruv-gray-12")


viewInt : Bool -> Int -> Html Msg
viewInt enabled i =
    span (ifEnabledColor enabled "text-gruv-blue-l") [ text (String.fromInt i) ]


viewColor : Bool -> Color -> Html Msg
viewColor enabled color =
    let
        name =
            case color of
                Red ->
                    "red"

                Green ->
                    "green"

                Blue ->
                    "blue"

                Purple ->
                    "purple"

                Yellow ->
                    "yellow"

                Aqua ->
                    "aqua"

                Orange ->
                    "orange"

                Magic ->
                    "magic"
    in
    span
        (ifEnabledColor enabled "text-gruv-green-l")
        [ text "\""
        , text name
        , text "\""
        ]


ifEnabledColor : Bool -> String -> List (Attribute msg)
ifEnabledColor enabled color =
    if enabled then
        [ class color ]

    else
        [ class "text-gruv-gray-6" ]



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
