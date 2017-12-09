import uuid
from django.db import models


class Todo(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    description = models.CharField(max_length=255)
    is_done = models.BooleanField(default=False)
