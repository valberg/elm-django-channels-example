from channels import route_class
from channels.generic.websockets import WebsocketDemultiplexer

from todo.bindings import TodoBinding


class Demultiplexer(WebsocketDemultiplexer):

    consumers = {
        "todo": TodoBinding.consumer
    }

    def connection_groups(self):
        return ["todo"]


channel_routing = [
    route_class(Demultiplexer, path=r"^/")
]
