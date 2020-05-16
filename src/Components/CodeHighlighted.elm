module Components.CodeHighlighted exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class)
import Parser
import SyntaxHighlight


type alias Flags =
    { language : Maybe String
    , code : String
    }


type Model
    = Highlighted (List (Html Msg))
    | NoHighlighting String


type alias Msg =
    Never



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( trySyntaxHighlight flags
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
        [ code [] <|
            case model of
                Highlighted lines ->
                    lines

                NoHighlighting content ->
                    [ text content ]
        ]



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
