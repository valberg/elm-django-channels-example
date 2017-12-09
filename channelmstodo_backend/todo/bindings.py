from channels.binding.websockets import WebsocketBinding

from . import models


class TodoBinding(WebsocketBinding):
    model = models.Todo
    stream = "todo"
    fields = ["id", "description", "is_done"]

    @classmethod
    def group_names(cls, instance):
        return ["todo"]

    def has_permission(self, user, action, pk):
        return True
