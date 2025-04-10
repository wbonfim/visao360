from django.urls import path
from . import views

app_name = 'nexum'

urlpatterns = [
    path('', views.home, name='home'),
]
