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
        (class "bg-gruv-gray-12" :: attributes)
        children


header : PagePath Pages.PathKey -> Html msg
header currentPath =
    nav [ class "flex flex-row w-full bg-gruv-gray-12" ]
        [ a
            [ class "flex-grow flex flex-col"
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
                [ class "font-body italic text-base m-auto" ]
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
                [ class "font-body italic text-base m-auto" ]
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
    ul (class "flex flex-col" :: attributes) children


postLinked : PagePath Pages.PathKey -> List (Html msg) -> Html msg
postLinked postPath =
    a [ href (PagePath.toString postPath) ]


postPreview : ( PagePath Pages.PathKey, Metadata.ArticleMetadata ) -> Html msg
postPreview ( postPath, post ) =
    li [ class "mx-auto mt-12" ]
        [ h2 [ class "font-title text-4xl text-gruv-gray-4 text-center" ]
            [ postLinked postPath [ text post.title ] ]
        , articleMetadata post
        , p [ class "description" ] [ postLinked postPath [ text post.description ] ]
        , p [ class "read-more" ] [ postLinked postPath [ text "Read More" ] ]
        ]


articleMetadata : Metadata.ArticleMetadata -> Html msg
articleMetadata { published } =
    time [] [ text (Date.format "MMMM ddd, yyyy" published) ]



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
