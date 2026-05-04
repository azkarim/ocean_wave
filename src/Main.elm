module Main exposing (main)

import Browser
import Browser.Dom
import Browser.Events exposing (onAnimationFrameDelta, onKeyDown, onResize)
import Html exposing (Html, button, div, h1, p, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Random
import Svg exposing (path, svg)
import Svg.Attributes exposing (d, fill, height, viewBox, width)
import Task
import Time


type alias Model =
    { waterHeight : Float
    , time : Float
    , state : GameState
    , eventMessage : String
    , windowWidth : Int
    , windowHeight : Int
    }


type GameState
    = Playing
    | Paused
    | GameOver


type Event
    = Up
    | Down


type Msg
    = Tick Float
    | EventTick Time.Posix
    | RandomEvent Event
    | Restart
    | GotViewport Browser.Dom.Viewport
    | WindowResized Int Int
    | KeyPressed String


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { waterHeight = 20
      , time = 0
      , state = Playing
      , eventMessage = "Waiting for waves..."
      , windowWidth = 800
      , windowHeight = 600
      }
    , Task.perform GotViewport Browser.Dom.getViewport
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        resizeSub =
            onResize WindowResized

        keySub =
            onKeyDown (Decode.map KeyPressed (Decode.field "key" Decode.string))
    in
    case model.state of
        Playing ->
            Sub.batch
                [ onAnimationFrameDelta Tick
                , Time.every 2000 EventTick
                , resizeSub
                , keySub
                ]

        Paused ->
            Sub.batch
                [ resizeSub
                , keySub
                ]

        GameOver ->
            Sub.batch
                [ resizeSub
                , keySub
                ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick delta ->
            ( { model | time = model.time + (delta / 500) }, Cmd.none )

        EventTick _ ->
            ( model
            , Random.generate RandomEvent (Random.uniform Up [ Down ])
            )

        RandomEvent event ->
            if model.state == Playing then
                let
                    ( dh, msgStr ) =
                        case event of
                            Up ->
                                ( 10, "UP! Water level increased." )

                            Down ->
                                ( -10, "DOWN! Water level decreased." )

                    newHeight =
                        model.waterHeight + dh

                    newState =
                        if newHeight <= 0 then
                            GameOver

                        else
                            Playing
                in
                ( { model
                    | waterHeight = newHeight
                    , state = newState
                    , eventMessage = msgStr
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Restart ->
            ( { model | waterHeight = 20, time = 0, state = Playing, eventMessage = "Waiting for waves..." }, Cmd.none )

        GotViewport vp ->
            ( { model | windowWidth = round vp.viewport.width, windowHeight = round vp.viewport.height }, Cmd.none )

        WindowResized w h ->
            ( { model | windowWidth = w, windowHeight = h }, Cmd.none )

        KeyPressed key ->
            if key == " " then
                case model.state of
                    Playing ->
                        ( { model | state = Paused, eventMessage = "GAME PAUSED" }, Cmd.none )

                    Paused ->
                        ( { model | state = Playing, eventMessage = "Resuming..." }, Cmd.none )

                    GameOver ->
                        ( model, Cmd.none )

            else
                ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div
        [ style "width" "100vw"
        , style "height" "100vh"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "background-color" "#222"
        , style "font-family" "sans-serif"
        , style "margin" "0"
        ]
        [ div
            [ style "width" "100%"
            , style "height" "100%"
            , style "background-color" "#e0f7fa"
            , style "position" "relative"
            , style "overflow" "hidden"
            ]
            [ -- UI Overlay
              div
                [ style "position" "absolute"
                , style "top" "20px"
                , style "left" "0"
                , style "width" "100%"
                , style "text-align" "center"
                , style "z-index" "10"
                ]
                [ h1 [ style "margin" "0 0 10px 0", style "color" "#006064" ] [ text "Ocean Waves" ]
                , p [ style "margin" "5px 0", style "font-size" "18px", style "font-weight" "bold", style "color" "#00838f" ]
                    [ text ("Height: " ++ String.fromFloat model.waterHeight ++ "px") ]
                , p [ style "margin" "5px 0", style "color" "#d32f2f", style "font-weight" "bold" ]
                    [ text model.eventMessage ]
                , case model.state of
                    GameOver ->
                        div [ style "margin-top" "30px" ]
                            [ h1 [ style "color" "#c62828", style "font-size" "36px" ] [ text "GAME OVER" ]
                            , button
                                [ onClick Restart
                                , style "margin-top" "10px"
                                , style "padding" "10px 20px"
                                , style "font-size" "16px"
                                , style "cursor" "pointer"
                                , style "background-color" "#00838f"
                                , style "color" "white"
                                , style "border" "none"
                                , style "border-radius" "4px"
                                , style "font-weight" "bold"
                                ]
                                [ text "Play Again" ]
                            ]

                    Paused ->
                        div [ style "margin-top" "30px" ]
                            [ h1 [ style "color" "#00838f", style "font-size" "36px" ] [ text "PAUSED" ]
                            , p [ style "color" "#006064" ] [ text "Press Space to Resume" ]
                            ]

                    Playing ->
                        p [ style "color" "#006064", style "font-size" "12px", style "margin-top" "20px" ] [ text "Press Space to Pause" ]
                ]

            -- Water SVG
            , viewWave model
            ]
        ]


viewWave : Model -> Html Msg
viewWave model =
    let
        w =
            model.windowWidth

        h =
            model.windowHeight

        amplitude =
            if model.waterHeight > 0 then
                min 8.0 (model.waterHeight * 0.4)

            else
                0

        frequency =
            0.03

        speed =
            1.5

        points =
            List.range 0 (w // 10 + 1)
                |> List.map (\i -> toFloat (i * 10))
                |> List.map
                    (\x ->
                        let
                            yOffset =
                                amplitude * sin (frequency * x - speed * model.time)

                            waveY =
                                toFloat h - model.waterHeight + yOffset
                        in
                        ( x, waveY )
                    )

        pathD =
            case points of
                ( firstX, firstY ) :: rest ->
                    let
                        lineCmds =
                            rest
                                |> List.map (\( x, y ) -> "L " ++ String.fromFloat x ++ " " ++ String.fromFloat y)
                                |> String.join " "
                    in
                    "M "
                        ++ String.fromFloat firstX
                        ++ " "
                        ++ String.fromFloat firstY
                        ++ " "
                        ++ lineCmds
                        ++ " L "
                        ++ String.fromInt w
                        ++ " "
                        ++ String.fromInt h
                        ++ " L 0 "
                        ++ String.fromInt h
                        ++ " Z"

                [] ->
                    ""
    in
    svg
        [ viewBox ("0 0 " ++ String.fromInt w ++ " " ++ String.fromInt h)
        , width "100%"
        , height "100%"
        , style "position" "absolute"
        , style "bottom" "0"
        , style "left" "0"
        ]
        [ path
            [ d pathD
            , fill "rgba(28, 163, 236, 0.8)"
            ]
            []
        ]
