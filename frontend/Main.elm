module Main exposing (..)

import DjangoChannels
    exposing
        ( StreamHandler
        , streamDemultiplexer
        , handleStream
        , defaultCreate
        , defaultUpdate
        , defaultDelete
        )
import Json.Decode exposing (Decoder, string, bool)
import Json.Decode.Pipeline exposing (decode, required)
import Html exposing (Html, div)
import WebSocket


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { todos : List ( String, Todo )
    }


type alias Todo =
    { description : String
    , isDone : Bool
    }


init : ( Model, Cmd Msg )
init =
    { todos = [] } ! []


view : Model -> Html Msg
view model =
    div [] []


type Msg
    = NoOp
    | HandleWebSocket String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        HandleWebSocket data ->
            case streamDemultiplexer data of
                "todo" ->
                    let
                        todos =
                            handleStream todoStreamHandler data model.todos
                    in
                        { model | todos = todos } ! []

                "nothing" ->
                    model ! []

                _ ->
                    model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen "ws://localhost:8000" HandleWebSocket



-- Decoders


todoDecoder : Decoder Todo
todoDecoder =
    decode Todo
        |> required "description" string
        |> required "is_done" bool



-- StreamHandlers


todoStreamHandler : StreamHandler Todo String
todoStreamHandler =
    StreamHandler
        "todo"
        todoDecoder
        string
        defaultCreate
        defaultUpdate
        defaultDelete
