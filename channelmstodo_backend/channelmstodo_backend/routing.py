from django.core import serializers
from channels import route_class
from channels.binding.websockets import WebsocketBinding
from channels.generic.websockets import (
     WebsocketDemultiplexer,
     JsonWebsocketConsumer
)

from todo.models import Todo


class TodoBinding(WebsocketBinding):
    model = Todo
    stream = "todo"
    fields = ["description", "is_done"]

    @classmethod
    def group_names(cls, instance):
        return ["todo"]

    def has_permission(self, user, action, pk):
        return True


class InitialDataConsumer(JsonWebsocketConsumer):
    def connect(self, message, multiplexer, **kwargs):
        todos = Todo.objects.all()
        serialized_todos = serializers.serialize(
            'python', todos
        )
        for todo in serialized_todos:
            todo['data'] = todo.pop('fields')
        multiplexer.send(serialized_todos)


class Demultiplexer(WebsocketDemultiplexer):
    consumers = {
        "initial": InitialDataConsumer,
        "todo": TodoBinding.consumer
    }

    def connection_groups(self):
        return ["todo"]


channel_routing = [
    route_class(Demultiplexer, path=r"^/")
]
