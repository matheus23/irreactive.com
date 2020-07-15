module Components.CodeHighlighted exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Lazy
import Parser
import SyntaxHighlight



-- VIEW


classes : List String -> Attribute msg
classes list =
    class (String.join " " list)


view : { language : Maybe String, body : String } -> Html msg
view =
    Html.Lazy.lazy
        (\model ->
            pre
                [ classes
                    [ "mt-4 py-6 px-8"
                    , "overflow-y-auto"
                    , "font-code text-base-sm code-shadow text-gruv-gray-12 bg-gruv-gray-0"
                    ]
                ]
                [ trySyntaxHighlight model
                    |> Maybe.withDefault [ text model.body ]
                    |> code []
                ]
        )


trySyntaxHighlight : { language : Maybe String, body : String } -> Maybe (List (Html msg))
trySyntaxHighlight { language, body } =
    case language |> Maybe.andThen findHighlighter of
        Just syntaxHighlight ->
            case syntaxHighlight body of
                Ok highlightedCode ->
                    Just <|
                        SyntaxHighlight.toCustom highlightingStyles highlightedCode

                Err _ ->
                    Nothing

        _ ->
            Nothing


type alias Highlighter =
    String -> Result (List Parser.DeadEnd) SyntaxHighlight.HCode


findHighlighter : String -> Maybe Highlighter
findHighlighter string =
    case string of
        "elm" ->
            Just SyntaxHighlight.elm

        "js" ->
            Just SyntaxHighlight.javascript

        "html" ->
            Just SyntaxHighlight.xml

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
