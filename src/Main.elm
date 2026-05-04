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
    , upStreak : Int
    , streakAnimTimer : Float
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
      , upStreak = 0
      , streakAnimTimer = 0
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
            let
                newTimer =
                    if model.streakAnimTimer > 0 then
                        max 0 (model.streakAnimTimer - (delta / 1000))

                    else
                        0
            in
            ( { model | time = model.time + (delta / 500), streakAnimTimer = newTimer }, Cmd.none )

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

                    newStreak =
                        case event of
                            Up ->
                                model.upStreak + 1

                            Down ->
                                0

                    newAnimTimer =
                        if newStreak >= 3 then
                            2.0

                        else
                            model.streakAnimTimer

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
                    , upStreak = newStreak
                    , streakAnimTimer = newAnimTimer
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Restart ->
            ( { model | waterHeight = 20, time = 0, state = Playing, eventMessage = "Waiting for waves...", upStreak = 0, streakAnimTimer = 0 }, Cmd.none )

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
                        update Restart model

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
            [ -- Streak Animation Overlay
              if model.streakAnimTimer > 0 then
                div
                    [ style "position" "absolute"
                    , style "top" "0"
                    , style "left" "0"
                    , style "width" "100%"
                    , style "height" "100%"
                    , style "display" "flex"
                    , style "flex-direction" "column"
                    , style "align-items" "center"
                    , style "justify-content" "center"
                    , style "z-index" "20"
                    , style "pointer-events" "none"
                    , style "background-color" ("rgba(255, 215, 0, " ++ String.fromFloat (min 0.3 (model.streakAnimTimer * 0.5)) ++ ")")
                    ]
                    [ div
                        [ style "transform" ("scale(" ++ String.fromFloat (1.0 + sin (model.streakAnimTimer * 10.0) * 0.1) ++ ")")
                        , style "color" "#fbc02d"
                        , style "text-shadow" "0 0 20px rgba(255, 255, 255, 0.8)"
                        ]
                        [ h1 [ style "font-size" "64px", style "margin" "0" ] [ text "STREAK!" ]
                        , p [ style "font-size" "24px", style "font-weight" "bold", style "text-align" "center" ] [ text (String.fromInt model.upStreak ++ " UPS IN A ROW!") ]
                        ]
                    ]

              else
                text ""

            -- UI Overlay
            , div
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
                            , p [ style "color" "#c62828" ] [ text "Press Space to Restart" ]
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

            -- Ruler Scale
            , viewRuler model
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
        , style "pointer-events" "none"
        ]
        [ path
            [ d pathD
            , fill "rgba(28, 163, 236, 0.8)"
            ]
            []
        ]


viewRuler : Model -> Html Msg
viewRuler model =
    let
        rulerWidth =
            60

        maxTicks =
            model.windowHeight // 10

        ticks =
            List.range 0 maxTicks

        renderTick i =
            let
                yPos =
                    model.windowHeight - (i * 10)

                isMajor =
                    remainderBy 5 i == 0

                tickWidth =
                    if isMajor then
                        20

                    else
                        10
            in
            if yPos < 0 then
                []

            else
                [ Svg.line
                    [ Svg.Attributes.x1 (String.fromInt (rulerWidth - tickWidth))
                    , Svg.Attributes.y1 (String.fromInt yPos)
                    , Svg.Attributes.x2 (String.fromInt rulerWidth)
                    , Svg.Attributes.y2 (String.fromInt yPos)
                    , Svg.Attributes.stroke "#006064"
                    , Svg.Attributes.strokeWidth
                        (if isMajor then
                            "2"

                         else
                            "1"
                        )
                    ]
                    []
                , if isMajor then
                    Svg.text_
                        [ Svg.Attributes.x (String.fromInt (rulerWidth - 25))
                        , Svg.Attributes.y (String.fromInt (yPos + 4))
                        , Svg.Attributes.fill "#006064"
                        , Svg.Attributes.fontSize "10px"
                        , Svg.Attributes.textAnchor "end"
                        , Svg.Attributes.fontWeight "bold"
                        ]
                        [ Svg.text (String.fromInt (i * 10)) ]

                  else
                    Svg.text ""
                ]
    in
    div
        [ style "position" "absolute"
        , style "right" "0"
        , style "top" "0"
        , style "height" "100%"
        , style "width" (String.fromInt rulerWidth ++ "px")
        , style "background-color" "rgba(255, 255, 255, 0.3)"
        , style "border-left" "1px solid #006064"
        , style "z-index" "5"
        ]
        [ svg
            [ width "100%"
            , height "100%"
            , viewBox ("0 0 " ++ String.fromInt rulerWidth ++ " " ++ String.fromInt model.windowHeight)
            ]
            (List.concatMap renderTick ticks)
        ]
