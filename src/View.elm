module View exposing (..)

import Date
import Html exposing (..)
import Html.Attributes exposing (class, href, id, style)
import Metadata exposing (Metadata)
import Pages exposing (pages)
import Pages.PagePath as PagePath exposing (PagePath)


body : List (Attribute msg) -> List (Html msg) -> Html msg
body attributes children =
    div
        (class "text-base bg-gruv-gray-12" :: attributes)
        children


header : PagePath Pages.PathKey -> Html msg
header currentPath =
    nav [ class "flex flex-row w-full bg-gruv-gray-12" ]
        [ a
            [ class "flex flex-col"
            , href (PagePath.toString pages.index)
            ]
            [ span
                [ classes
                    [ "font-title font-semibold text-3xl text-gruv-orange-d"
                    , "px-3 mx-auto"
                    ]
                ]
                [ text "Irreactive" ]
            , div [ class "h-1 mr-1 bg-gruv-gray-10" ] []
            ]
        , a
            [ class "flex-grow flex flex-col"
            , href (PagePath.toString pages.index)
            ]
            [ span
                [ class "font-body italic text-base m-auto text-gruv-gray-4" ]
                [ text "Posts" ]
            , div
                [ classes
                    [ "h-1 mx-1"
                    , if currentPath == pages.index then
                        "bg-gruv-orange-m"

                      else
                        "bg-gruv-gray-10"
                    ]
                ]
                []
            ]
        , a
            [ class "flex-grow flex flex-col"
            , href (PagePath.toString pages.about)
            ]
            [ span
                [ class "font-body italic text-base m-auto text-gruv-gray-4" ]
                [ text "About" ]
            , div
                [ classes
                    [ "h-1 ml-1"
                    , if currentPath == pages.about then
                        "bg-gruv-orange-m"

                      else
                        "bg-gruv-gray-10"
                    ]
                ]
                []
            ]
        ]


articleList : List (Attribute msg) -> List (Html msg) -> Html msg
articleList attributes children =
    ul (class "flex flex-col mx-6 mb-12" :: attributes) children


postLinked : PagePath Pages.PathKey -> List (Html msg) -> Html msg
postLinked postPath =
    a [ href (PagePath.toString postPath) ]


postPreview : ( PagePath Pages.PathKey, Metadata.ArticleMetadata ) -> Html msg
postPreview ( postPath, post ) =
    li [ class "w-full mx-auto mt-12" ]
        [ articleMetadata post
        , h2 [ class "font-title text-4xl text-gruv-gray-4 text-center leading-tight" ]
            [ postLinked postPath [ text post.title ] ]
        , p [ class "text-gruv-gray-4 text-justify mt-2" ] [ postLinked postPath [ text post.description ] ]
        , p [ class "font-title text-xl text-gruv-blue-d block text-center mt-2" ] [ postLinked postPath [ text "Read More ..." ] ]
        , hr [ style "height" "2px", class "max-w-xs bg-gruv-gray-9 mx-auto mt-12" ] []
        ]


articleMetadata : Metadata.ArticleMetadata -> Html msg
articleMetadata { published } =
    time [ class "text-gruv-gray-4 italic text-base-sm text-center block" ]
        [ text (Date.format "MMMM ddd, yyyy" published) ]



-- UTILITIES


classes : List String -> Attribute msg
classes list =
    class (String.join " " list)


when : Bool -> String -> String
when condition classNames =
    if condition then
        classNames

    else
        ""


unless : Bool -> String -> String
unless condition =
    when (not condition)
