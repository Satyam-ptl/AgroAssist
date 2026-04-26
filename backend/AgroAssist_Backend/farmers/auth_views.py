from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth import authenticate

from .auth_serializers import FarmerRegistrationSerializer, LoginSerializer
from .models import Farmer
from .stateless_token_auth import issue_auth_token


class FarmerRegisterView(APIView):
    permission_classes = []

    def post(self, request):
        serializer = FarmerRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = serializer.save()
        return Response(payload, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = []

    def post(self, request):
        username = (request.data.get('username') or '').strip()
        password = request.data.get('password') or ''

        if not username:
            return Response(
                {'error': 'Username is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not password:
            return Response(
                {'error': 'Password is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = authenticate(username=username, password=password)
        if user is None:
            return Response(
                {'error': 'Incorrect username or password'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        if not user.is_active:
            return Response(
                {'error': 'Your account has been deactivated. Contact admin.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        token, _ = Token.objects.get_or_create(user=user)
        farmer = Farmer.objects.filter(email__iexact=user.email).first()
        role = 'admin' if (user.is_staff or user.is_superuser) else 'farmer'

        return Response(
            {
                'token': token.key,
                'user_id': user.id,
                'username': user.username,
                'email': user.email,
                'role': role,
                'is_admin': bool(user.is_staff or user.is_superuser),
                'farmer_id': farmer.id if farmer else None,
                'full_name': (f'{user.first_name} {user.last_name}'.strip() or user.username),
                'is_staff': user.is_staff,
                'is_superuser': user.is_superuser,
            },
            status=status.HTTP_200_OK,
        )


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Token.objects.filter(user=request.user).delete()
        return Response({"detail": "Logged out successfully."}, status=status.HTTP_200_OK)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        farmer = Farmer.objects.filter(email__iexact=user.email).first()
        role = "admin" if (user.is_staff or user.is_superuser) else "farmer"

        payload = {
            "token": issue_auth_token(user),
            "id": user.id,
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
            "role": role,
            "farmer_id": farmer.id if farmer else None,
            "is_admin": bool(user.is_staff or user.is_superuser),
            "is_staff": user.is_staff,
            "is_superuser": user.is_superuser,
            "full_name": (f"{user.first_name} {user.last_name}".strip() or user.username),
        }
        return Response(payload, status=status.HTTP_200_OK)
