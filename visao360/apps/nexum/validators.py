from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _
import re

class StrongPasswordValidator:
    def validate(self, password, user=None):
        if len(password) < 8:
            raise ValidationError(
                _('A senha deve ter no mínimo 8 caracteres.'),
                code='password_too_short'
            )
        if not re.search(r'[A-Za-z]', password):
            raise ValidationError(
                _('A senha deve conter letras.'),
                code='password_no_letters'
            )
        if not re.search(r'[0-9]', password):
            raise ValidationError(
                _('A senha deve conter números.'),
                code='password_no_numbers'
            )
        if not re.search(r'[^A-Za-z0-9]', password):
            raise ValidationError(
                _('A senha deve conter pelo menos 1 caractere especial.'),
                code='password_no_special_chars'
            )

    def get_help_text(self):
        return _(
            "Sua senha deve conter no mínimo 8 caracteres, "
            "incluindo letras, números e pelo menos 1 caractere especial."
        )
