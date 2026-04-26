import os
import re

from django.contrib.auth import get_user_model
from django.core import signing
from rest_framework import authentication
from rest_framework.exceptions import AuthenticationFailed

_TOKEN_SALT = 'agroassist.auth.token.v1'
_TOKEN_MAX_AGE_SECONDS = int(os.getenv('AUTH_TOKEN_MAX_AGE_SECONDS', '2592000'))


def issue_auth_token(user):
    return signing.dumps({'uid': user.id}, salt=_TOKEN_SALT)


def _resolve_user_from_token(token):
    try:
        data = signing.loads(token, salt=_TOKEN_SALT, max_age=_TOKEN_MAX_AGE_SECONDS)
    except signing.SignatureExpired as exc:
        raise AuthenticationFailed('Token has expired.') from exc
    except signing.BadSignature as exc:
        raise AuthenticationFailed('Invalid token.') from exc

    user_id = data.get('uid')
    if not user_id:
        raise AuthenticationFailed('Invalid token payload.')

    User = get_user_model()
    user = User.objects.filter(id=user_id, is_active=True).first()
    if not user:
        raise AuthenticationFailed('User not found or inactive.')

    return user


class StatelessTokenAuthentication(authentication.BaseAuthentication):
    keyword = b'token'

    def authenticate(self, request):
        auth = authentication.get_authorization_header(request).split()
        if not auth:
            return None

        if auth[0].lower() != self.keyword:
            return None

        if len(auth) == 1:
            raise AuthenticationFailed('Invalid token header. No credentials provided.')
        if len(auth) > 2:
            raise AuthenticationFailed('Invalid token header. Token string should not contain spaces.')

        try:
            token = auth[1].decode('utf-8')
        except UnicodeError as exc:
            raise AuthenticationFailed('Invalid token header. Token string should not contain invalid characters.') from exc

        # Let DRF TokenAuthentication handle legacy 40-char hex token keys.
        if re.fullmatch(r'[0-9a-fA-F]{40}', token):
            return None

        user = _resolve_user_from_token(token)
        return (user, token)
