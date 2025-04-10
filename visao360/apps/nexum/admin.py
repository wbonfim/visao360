from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.forms import UserChangeForm, UserCreationForm, AdminPasswordChangeForm
from django.core.exceptions import ValidationError
from .models import CustomUser
from .validators import StrongPasswordValidator

class CustomUserChangeForm(UserChangeForm):
    def clean_password2(self):
        password1 = self.cleaned_data.get("password1")
        password2 = self.cleaned_data.get("password2")
        if password1 and password2:
            validator = StrongPasswordValidator()
            validator.validate(password2)
        return super().clean_password2()

class CustomUserCreationForm(UserCreationForm):
    def clean_password2(self):
        password1 = self.cleaned_data.get("password1")
        password2 = self.cleaned_data.get("password2")
        if password1 and password2:
            validator = StrongPasswordValidator()
            validator.validate(password2)
        return super().clean_password2()

class CustomUserAdmin(UserAdmin):
    model = CustomUser
    form = CustomUserChangeForm
    add_form = CustomUserCreationForm
    list_display = ('email', 'first_name', 'last_name', 'is_staff')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'groups')
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('email',)
    filter_horizontal = ('groups', 'user_permissions',)
    
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name')}),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
        }),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2'),
        }),
    )
    
    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        if obj:  # Editing an existing user
            form.base_fields['password'].help_text = (
                "Raw passwords are not stored, so there is no way to see this "
                "user's password, but you can change the password using "
                "<a href=\"../password/\">this form</a>."
            )
        return form

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path(
                '<id>/password/',
                self.admin_site.admin_view(self.user_change_password),
                name='auth_user_password_change',
            ),
        ]
        return custom_urls + urls

    def user_change_password(self, request, id, form_url=''):
        from django.contrib.auth.forms import AdminPasswordChangeForm
        from django.contrib.auth import get_user_model
        user = get_user_model().objects.get(pk=id)
        if request.method == 'POST':
            form = AdminPasswordChangeForm(user, request.POST)
            if form.is_valid():
                form.save()
                from django.contrib import messages
                messages.success(request, 'Senha alterada com sucesso')
                from django.urls import reverse
                from django.shortcuts import redirect
                return redirect(reverse('admin:%s_%s_change' % (
                    user._meta.app_label,
                    user._meta.model_name
                ), args=(user.id,)))
        else:
            form = AdminPasswordChangeForm(user)
        
        context = {
            'title': 'Alterar senha',
            'form': form,
            'form_url': form_url,
            'original': user,  # Changed from 'user' to 'original' to match template expectations
            'opts': self.model._meta,
            'is_popup': False,
        }
        from django.template.response import TemplateResponse
        return TemplateResponse(request, 'admin/auth/user/change_password.html', context)

admin.site.register(CustomUser, CustomUserAdmin)
