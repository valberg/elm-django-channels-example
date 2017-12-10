module Main exposing (..)

import DjangoChannels exposing (streamDemultiplexer)
import DjangoChannels.Binding as DCB
import DjangoChannels.Initial as DCI
import Json.Decode exposing (Decoder, string, bool)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode
import Html exposing (Html, div, text, ul, li, hr, input, button, span)
import Html.Attributes exposing (value)
import Html.Events exposing (onInput, onClick)
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
    , todoInput : String
    }


type alias Todo =
    { description : String
    , isDone : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { todos = [], todoInput = "" }
    , Cmd.none
    )


todoView : ( String, Todo ) -> Html Msg
todoView ( pk, todo ) =
    li []
        [ span []
            [ text todo.description
            , button [ onClick (ToggleDone pk todo) ]
                [ text <|
                    case todo.isDone of
                        True ->
                            "Not Done"

                        False ->
                            "Done"
                ]
            , button [ onClick (DeleteTodo pk) ] [ text "Delete" ]
            ]
        ]


view : Model -> Html Msg
view model =
    div []
        [ ul []
            (List.map
                todoView
                model.todos
            )
        , hr [] []
        , input [ onInput TodoInput, value model.todoInput ] []
        , button [ onClick CreateTodo ] [ text "New todo" ]
        ]


type Msg
    = NoOp
    | HandleWebSocket String
    | TodoInput String
    | CreateTodo
    | DeleteTodo String
    | ToggleDone String Todo


type Stream
    = TodoStream
    | InitialStream
    | NotFoundStream


stringToStream : String -> Stream
stringToStream str =
    case str of
        "todo" ->
            TodoStream

        "initial" ->
            InitialStream

        _ ->
            NotFoundStream


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        HandleWebSocket data ->
            case streamDemultiplexer data stringToStream NotFoundStream of
                TodoStream ->
                    let
                        todos =
                            DCB.handleBindingStream todoStreamHandler data model.todos
                    in
                        ( { model | todos = todos }
                        , Cmd.none
                        )

                InitialStream ->
                    let
                        todos =
                            DCI.handleInitialStream initialTodoStreamHandler data
                    in
                        ( { model | todos = todos }
                        , Cmd.none
                        )

                NotFoundStream ->
                    ( model
                    , Cmd.none
                    )

        TodoInput input ->
            ( { model | todoInput = input }
            , Cmd.none
            )

        CreateTodo ->
            let
                newTodo =
                    Todo model.todoInput False
            in
                ( { model | todoInput = "" }, DCB.createInstance todoStreamHandler newTodo )

        ToggleDone pk todo ->
            let
                newTodo =
                    { todo | isDone = not todo.isDone }
            in
                ( model, DCB.updateInstance todoStreamHandler pk newTodo )

        DeleteTodo pk ->
            ( model, DCB.deleteInstance todoStreamHandler pk )


websocketServer : String
websocketServer =
    "ws://localhost:8000"


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen websocketServer HandleWebSocket



-- Decoders


todoDecoder : Decoder Todo
todoDecoder =
    decode Todo
        |> required "description" string
        |> required "is_done" bool



-- Encoders


todoEncoder : Todo -> Json.Encode.Value
todoEncoder instance =
    Json.Encode.object
        [ ( "description", Json.Encode.string instance.description )
        , ( "is_done", Json.Encode.bool instance.isDone )
        ]



-- StreamHandlers


todoStreamHandler : DCB.BindingStreamHandler String Todo
todoStreamHandler =
    DCB.BindingStreamHandler
        websocketServer
        "todo"
        todoDecoder
        todoEncoder
        string
        Json.Encode.string
        DCB.defaultCreate
        DCB.defaultUpdate
        DCB.defaultDelete


initialTodoStreamHandler : DCI.InitialStreamHandler String Todo
initialTodoStreamHandler =
    DCI.InitialStreamHandler
        todoDecoder
        string
